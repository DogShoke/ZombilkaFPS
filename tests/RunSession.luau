-- Execute as a temporary server Script in Studio. No world/player mutations.
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local RunSession = require(Server.RunSession)
local Progress = require(Server.EncounterProgress)
local Economy = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").ShopCatalog).Economy
local HttpService = game:GetService("HttpService")
local report = {Cases={}, Failed={}, Assertions=0}

local function check(condition, message)
	report.Assertions += 1
	assert(condition, message)
end

local function case(name, run)
	local ok, err = pcall(run)
	table.insert(report.Cases, {Name=name, Passed=ok})
	if not ok then table.insert(report.Failed, {Name=name, Error=tostring(err)}) end
end

case("Begin initializes a run and rejects an active restart", function()
	local session = RunSession.new()
	check(not session.Active and session.Epoch == 0, "Initial session is inactive")
	check(session:GetResults() == nil, "Fresh session has no results")
	local epoch = session:Begin(100)
	local id = session.Id
	check(epoch == 1 and session:IsCurrent(epoch), "Begin returns the active epoch")
	check(type(id) == "string" and #id > 0, "Run has an opaque ID")
	check(session.StartedAt == 100 and session.HighestFloor == 1, "Run starts at floor one")
	check(session.Kills == 0 and session.ClearedFloors == 0, "Run counters start empty")
	check(session.Credits == 0 and session.Rerolls == 0 and session.PendingResearch == 0, "Temporary balances start empty")
	check(next(session.Boons) == nil and next(session.Modifiers) == nil and next(session.Patrons) == nil, "Temporary inventories start empty")
	local ok = pcall(function() session:Begin(101) end)
	check(not ok, "Active run cannot be restarted without Finish")
	check(session.Epoch == epoch and session.Id == id and session.StartedAt == 100, "Rejected Begin preserves run identity")
end)

case("Finish invalidates callbacks and produces results exactly once", function()
	local session = RunSession.new()
	local epoch = session:Begin(100)
	check(session:RecordKill(epoch), "Current kill accepted")
	session.HighestFloor = 3
	local result = session:Finish(142, "Death")
	check(result ~= nil and result.Kills == 1 and result.HighestFloor == 3, "Finish snapshots run counters")
	check(result.Duration == 42 and result.Reason == "Death", "Finish snapshots time and reason")
	check(result.ResearchEarned == 0 and result.ResearchStatus == "Pending", "Run ledger does not claim an unacknowledged save")
	check(not session.Active and session.Epoch == epoch + 1, "Finish immediately invalidates epoch")
	check(not session:IsCurrent(epoch) and not session:RecordKill(epoch), "Ended-run callback rejected")
	check(session:Finish(200, "Duplicate") == nil, "Second Finish returns no grantable result")
	check(session.Epoch == epoch + 1, "Duplicate Finish does not advance epoch")
	check(session:GetResults().Reason == "Death" and session:GetResults().Duration == 42, "Duplicate Finish preserves original result")
	local nextEpoch = session:Begin(250)
	check(nextEpoch > epoch and session:IsCurrent(nextEpoch), "Replacement run receives a fresh epoch")
	check(not session:RecordKill(epoch) and session.Kills == 0, "Old callback cannot credit replacement run")
	check(session:RecordKill(nextEpoch) and session.Kills == 1, "Replacement run still accepts genuine kills")
end)

case("Result snapshots are deep copies at every boundary", function()
	local session = RunSession.new()
	session:Begin(0)
	session.Boons = {volta_arc_discharge={Level=2, Rarity="Rare", Scalars={Damage=8}}}
	session.Patrons = {Volta={Visits=2}}
	local originalBoons, originalPatrons = session.Boons, session.Patrons
	local returned = session:Finish(10, "Death")
	originalBoons.volta_arc_discharge.Scalars.Damage = 999
	originalPatrons.Volta.Visits = 999
	check(returned.Boons.volta_arc_discharge.Scalars.Damage == 8 and returned.Patrons.Volta.Visits == 2, "Finish snapshot detaches original nested tables")
	returned.Boons.volta_arc_discharge.Level = 99
	returned.Patrons.Volta.Visits = 99
	local first = session:GetResults()
	check(first.Boons.volta_arc_discharge.Level == 2 and first.Patrons.Volta.Visits == 2, "Caller cannot mutate stored results through Finish return")
	first.Boons.volta_arc_discharge.Scalars.Damage = 77
	first.Patrons.Volta.Visits = 77
	local second = session:GetResults()
	check(second.Boons.volta_arc_discharge.Scalars.Damage == 8 and second.Patrons.Volta.Visits == 2, "GetResults returns detached nested tables")
	check(second ~= first and second.Boons ~= first.Boons, "Each results read has independent table identity")
end)

case("Temporary state resets while end results remain available", function()
	local session = RunSession.new()
	local epoch = session:Begin(0)
	local oldId = session.Id
	session.Rerolls, session.PendingResearch = 3, 12
	session.SupplyHealth=12
	session.Boons, session.Modifiers, session.Patrons = {test={Level=1}}, {Damage=2}, {Bravo=true}
	session.HighestFloor = 5
	session:RecordKill(epoch)
	session:CompleteFloor(epoch, 1)
	check(session:AddCredits(epoch,80) and session:SpendCredits(epoch,70),"Ledger supports real earned/spent setup")
	local result = session:Finish(50, "Death")
	check(session.Credits == 0 and session.Rerolls == 0 and session.PendingResearch == 0, "Finish clears temporary balances")
	check(session.SupplyHealth==0,"Finish removes supply max-health bonuses")
	check(next(session.Boons) == nil and next(session.Modifiers) == nil and next(session.Patrons) == nil, "Finish clears build and modifiers")
	check(result.CreditsEarned == 140 and result.CreditsSpent == 70 and result.Boons.test.Level == 1, "End snapshot preserves earned/spent totals and build")
	local nextEpoch = session:Begin(60)
	check(session.Id ~= oldId and nextEpoch > epoch, "New run has new identity")
	check(session.HighestFloor == 1 and session.Kills == 0 and session.ClearedFloors == 0, "Begin clears progression counters")
	check(session.CreditsEarned == 0 and session.CreditsSpent == 0 and next(session.Completed) == nil, "Begin clears economy totals and floor dedupe")
	check(session.Credits == 0 and session.Rerolls == 0 and next(session.Boons) == nil and next(session.Modifiers) == nil, "Begin starts with no temporary effects")
	check(session:GetResults().RunId == oldId, "Previous results remain readable during replacement run")
	check(session:CompleteFloor(nextEpoch, 1), "New run may clear floor one independently")
end)

case("Floor completion is deduplicated and scoped to epoch", function()
	local session = RunSession.new()
	local epoch = session:Begin(0)
	check(not session:CompleteFloor(epoch - 1, 1), "Wrong epoch cannot clear a floor")
	check(session:CompleteFloor(epoch, 1), "First genuine floor completion accepted")
	check(not session:CompleteFloor(epoch, 1) and session.ClearedFloors == 1, "Same floor cannot be completed twice")
	check(session:CompleteFloor(epoch, 2) and session.ClearedFloors == 2, "Distinct floor completes once")
	local result = session:Finish(1, "Death")
	check(not session:CompleteFloor(epoch, 3), "Finished run rejects completion")
	check(result.ClearedFloors == 2, "End result contains deduplicated completions")
	session:Begin(2)
	check(not session:CompleteFloor(epoch, 1) and session.ClearedFloors == 0, "Stale completion cannot affect a new run")
end)

case("Real defeats credit kills; technical requeues and stale callbacks do not", function()
	local session = RunSession.new()
	local epoch = session:Begin(10)
	local encounter = Progress.New({Mode="KillQuota", Quota=2})
	encounter.OnKill = function() session:RecordKill(epoch) end
	Progress.Spawned(encounter)
	Progress.Requeue(encounter)
	check(encounter.Alive == 0 and encounter.Requeued == 1 and encounter.Defeated == 0, "Recovery removes pressure without a defeat")
	check(session.Kills == 0, "Requeue does not invoke kill credit")
	Progress.Spawned(encounter)
	Progress.Defeated(encounter)
	check(encounter.Issued == 2 and encounter.Defeated == 1 and encounter.SectionKills == 1, "Replacement issuance and actual defeat remain distinct")
	check(session.Kills == 1 and encounter.Alive == 0, "Genuine defeat records exactly one run kill")
	check(not Progress.Step(encounter, 1, true, {}, 0), "Requeue cannot satisfy kill quota")
	Progress.Spawned(encounter)
	Progress.Defeated(encounter)
	check(Progress.Step(encounter, 1, true, {}, 0) and session.Kills == 2, "Genuine second defeat satisfies kill quota")
	local result = session:Finish(20, "Death")
	encounter.OnKill()
	check(session.Kills == 2 and session:GetResults().Kills == 2, "Late callback cannot mutate ended result")
	local newEpoch = session:Begin(30)
	Progress.Defeated(encounter)
	check(session.Kills == 0 and session:GetResults().Kills == result.Kills, "Stale encounter callback cannot credit replacement run")
	local fresh = Progress.New({Mode="KillQuota", Quota=1})
	fresh.OnKill = function() session:RecordKill(newEpoch) end
	Progress.Spawned(fresh)
	Progress.Defeated(fresh)
	check(session.Kills == 1, "Current encounter callback works after stale callbacks")
end)

case("Run duration cannot become negative", function()
	local session = RunSession.new()
	session:Begin(100)
	check(session:Finish(90, "ClockTest").Duration == 0, "Negative elapsed time clamps to zero")
end)

case("Genuine kill credits are capped by floor budget and never paid for requeues", function()
	local session=RunSession.new();local epoch=session:Begin(0)
	check(session:SetFloor(epoch,1,2),"Floor one kill-credit budget initializes")
	local encounter=Progress.New({Mode="KillQuota",Quota=2})
	encounter.OnKill=function()session:RecordKill(epoch)end
	Progress.Spawned(encounter);Progress.Requeue(encounter)
	check(session.Kills==0 and session.Credits==0,"Technical recovery earns neither kill nor credit")
	for _=1,5 do Progress.Spawned(encounter);Progress.Defeated(encounter)end
	check(session.Kills==5 and session.Credits==2 and session.CreditsEarned==2,"Extra genuine kills remain in results but cannot exceed floor credit budget")
	check(session:SetFloor(epoch,1,2),"Rebinding same floor is harmless")
	session:RecordKill(epoch)
	check(session.Kills==6 and session.Credits==2,"Rebinding floor cannot replenish exhausted kill-credit budget")
	check(session:CompleteFloor(epoch,1)and session.Credits==62,"Floor-one completion awards sixty once")
	check(not session:CompleteFloor(epoch,1)and session.Credits==62,"Repeated completion cannot mint credits")
	check(session:SetFloor(epoch,2,1)and session:RecordKill(epoch)and session.Credits==63,"Distinct floor receives its own kill budget")
	check(session:CompleteFloor(epoch,2)and session.Credits==129,"Floor-two completion awards sixty-six")
	check(session.CreditsEarned==129 and session.CreditsSpent==0,"Earned and spent totals reflect actual ledger changes")
	check(session:SetFloor(epoch,3,0)and session:RecordKill(epoch)and session.Credits==129,"Zero-budget encounter records kills without farming currency")
	check(session:SetFloor(epoch,3,5)and session:CompleteFloor(epoch,3),"Completion closes even a partly unused credit budget")
	local completedBalance=session.Credits;session:RecordKill(epoch)
	check(session.Credits==completedBalance,"Post-completion zombie kills cannot farm unused credit budget")
end)

case("Credit operations reject malformed values and insufficient funds atomically",function()
	local session=RunSession.new();local epoch=session:Begin(0)
	check(session:AddCredits(epoch,100),"Valid integer grant succeeds")
	check(session:AddCredits(epoch,0)and session:SpendCredits(epoch,0),"Zero-value operations are accepted no-ops")
	for _,amount in {-1,.5,math.huge,-math.huge,0/0,"100",false}do
		check(not session:AddCredits(epoch,amount),"Malformed credit grant rejected")
		check(not session:SpendCredits(epoch,amount),"Malformed spending rejected")
	end
	check(not session:AddCredits(epoch,nil)and not session:SpendCredits(epoch,nil),"Missing amounts rejected")
	check(not session:SpendCredits(epoch,101),"Insufficient balance cannot become negative")
	check(session.Credits==100 and session.CreditsEarned==100 and session.CreditsSpent==0,"Rejected amounts leave all counters unchanged")
	check(session:SpendCredits(epoch,65)and session.Credits==35 and session.CreditsSpent==65,"Successful spend debits exactly once")
	check(not session:SpendCredits(epoch,36)and session.Credits==35 and session.CreditsSpent==65,"Failed second debit has no side effects")
	check(not session:AddCredits(epoch-1,10)and not session:SpendCredits(epoch-1,10),"Stale epoch cannot change currency")
	local result=session:Finish(1,"Death")
	check(result.CreditsEarned==100 and result.CreditsSpent==65 and session.Credits==0,"Final results preserve earned/spent while balance resets")
	check(not session:AddCredits(epoch,10)and not session:SpendCredits(epoch,0),"Finished ledger rejects credit operations")
	local fresh=session:Begin(2)
	check(session.Credits==0 and session.CreditsEarned==0 and session.CreditsSpent==0,"Replacement run starts with fresh counters")
	check(not session:AddCredits(epoch,10)and session:AddCredits(fresh,1)and session.Credits==1,"Only replacement epoch can receive new credits")
end)

case("Floor budgets reject invalid inputs and stale callbacks",function()
	local session=RunSession.new();local epoch=session:Begin(0)
	check(not session:SetFloor(epoch-1,1,3),"Stale epoch cannot configure kill credits")
	for _,floor in {0,-1,1.5,math.huge,0/0,"1"}do
		check(not session:SetFloor(epoch,floor,3),"Malformed floor rejected")
		check(not session:CompleteFloor(epoch,floor),"Malformed completion floor rejected")
	end
	for _,budget in {-1,.5,math.huge,0/0,"3"}do check(not session:SetFloor(epoch,1,budget),"Malformed budget rejected")end
	check(session.Credits==0 and session.ClearedFloors==0,"Invalid floor requests do not award anything")
	check(session:SetFloor(epoch,1,1),"Valid budget can still initialize after rejections")
	session:RecordKill(epoch);local result=session:Finish(1,"Death")
	local fresh=session:Begin(2)
	check(not session:SetFloor(epoch,2,10)and not session:RecordKill(epoch),"Stale budget/kill cannot affect replacement run")
	check(session:SetFloor(fresh,1,1)and session:RecordKill(fresh)and session.Credits==1,"New run floor budget starts fresh")
	check(session:GetResults().CreditsEarned==result.CreditsEarned,"Old result remains immutable across replacement credits")
end)

case("Credit carry cap clips actual earnings and cannot reopen completed rewards",function()
	local session=RunSession.new();local epoch=session:Begin(0)
	local cap=Economy.CreditCap
	check(cap==1000000 and Economy.KillBudgetCap==1000,"Economy exposes bounded shared credit and kill-budget limits")
	check(session:SetFloor(epoch,1,Economy.KillBudgetCap+1)and session.KillBudget==Economy.KillBudgetCap,"Excess finite kill budget clamps to shared limit")
	check(session:AddCredits(epoch,cap-1)and session:AddCredits(epoch,10),"Near-cap grants remain valid")
	check(session.Credits==cap and session.CreditsEarned==cap,"Only actual capped amount is counted as earned")
	check(not session:AddCredits(epoch,cap+1)and not session:SpendCredits(epoch,cap+1),"Unbounded single grant and spending rejected")
	check(session:CompleteFloor(epoch,1)and session.Credits==cap,"Completion commits even when its payout is capped")
	check(session:SpendCredits(epoch,1)and not session:CompleteFloor(epoch,1)and session.Credits==cap-1,"Making room after capped payout cannot replay completion")
	check(session:AddCredits(epoch,10)and session.Credits==cap and session.CreditsEarned==cap+1,"Newly available room earns only the actual inserted credit")
	session:SetFloor(epoch,2,1);session:RecordKill(epoch)
	check(session.Credits==cap and session.CreditsEarned==cap+1,"At-cap kill cannot inflate earnings totals")
	local result=session:Finish(2,"Death")
	check(result.CreditsEarned==cap+1 and result.CreditsSpent==1,"Results retain actual earned/spent under carry cap")
	check(session.Floor==1 and session.KillBudget==0 and next(session.FloorKills)==nil,"Finish clears floor credit accounting")
end)

script:SetAttribute("Success", #report.Failed == 0)
script:SetAttribute("Error", #report.Failed == 0 and "" or HttpService:JSONEncode(report.Failed))
script:SetAttribute("Report", HttpService:JSONEncode(report))
script:SetAttribute("Complete", true)
