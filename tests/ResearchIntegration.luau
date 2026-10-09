-- Temporary Play Script BEFORE combat. Isolated mock store, players, humanoids.
-- Effects.Bind targets only test characters. Stop/restart before live gameplay QA.
local Server=game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Research=require(Server.ResearchService)
local Profiles=require(Server.ProfileService)
local Schema=require(Server.ProfileSchema)
local RunSession=require(Server.RunSession)
local Effects=require(Server.BoonEffects)
local Shop=require(Server.ShopService)
local Rewards=require(Server.RewardService)
local Catalog=require(Shared.ResearchCatalog)
local Boons=require(Shared.BoonCatalog)
local HttpService=game:GetService("HttpService")
local report={Cases={},Failed={},Assertions=0,Mode="InjectedMock",RealDataStoreVerified=false}
local holders={}
local function check(condition,message)report.Assertions+=1;assert(condition,message)end
local function case(name,body)
	local ok,err=pcall(body);table.insert(report.Cases,{Name=name,Passed=ok})
	if not ok then table.insert(report.Failed,{Name=name,Error=tostring(err)})end
	Effects.Clear()
end
local function waitFor(predicate,message)
	local deadline=os.clock()+5
	while not predicate()and os.clock()<deadline do task.wait()end
	check(predicate(),message)
end
local function hold(instance)table.insert(holders,instance);return instance end
local function fakePlayer(id)
	local character=hold(Instance.new("Model"));character.Name="ResearchTestCharacter"
	local h=Instance.new("Humanoid");h.MaxHealth=100;h.Health=100;h.Parent=character
	local player={UserId=id or 601,Character=character,Attributes={}}
	function player:GetAttribute(key)return self.Attributes[key]end
	function player:SetAttribute(key,value)self.Attributes[key]=value end
	return player,h
end
local function store()
	local backend={Values={},Reads=0,Writes=0}
	function backend:GetAsync(key)self.Reads+=1;return Schema.Copy(self.Values[key])end
	function backend:UpdateAsync(key,transform)
		self.Writes+=1
		if self.BeforeUpdate then self:BeforeUpdate(key)end
		local nextValue=transform(Schema.Copy(self.Values[key]))
		if nextValue~=nil then self.Values[key]=Schema.Copy(nextValue)end
		return Schema.Copy(self.Values[key])
	end
	return backend
end
local function seeded(backend,id,balance,ranks)
	local profile=Schema.New();profile.ResearchData=balance or 10000
	for research,rank in ranks or {}do
		profile.ResearchRanks[research]=rank
		for level=1,rank do profile.Purchases[research][level]={OperationId="seed_"..research.."_"..level,Cost=Catalog.Definitions[research].Costs[level],Legacy=false}end
	end
	backend.Values["u_"..id]=profile
	return profile
end
local function fixture(ranks,profileOverride)
	local player,h=fakePlayer(601);local backend=store();seeded(backend,player.UserId,10000,ranks)
	local profiles=profileOverride or Profiles.new(backend,{Attempts=1,RetryDelay=0,IsStudio=true,Mode="Mock"})
	local run=RunSession.new();run:Begin(0)
	local state=hold(Instance.new("Folder"));state.Name="ResearchTestState";state:SetAttribute("OwnerUserId",player.UserId)
	local results=Instance.new("Folder");results.Name="RunResults";results.Parent=state
	local remotes=hold(Instance.new("Folder"));local context={Phase="ChoosingWeapon"}
	local research=Research.new(run,state,results,remotes,function()return context.Phase end,profiles)
	Effects.Bind(run,player)
	return {Player=player,H=h,Store=backend,Profiles=profiles,Run=run,State=state,Results=results,Research=research,Context=context}
end
local function load(f)
	f.Research:Load(f.Player)
	waitFor(function()return f.Research.Folder:GetAttribute("Status")=="Ready"end,"Mock profile becomes ready")
	check(f.Research.Folder:GetAttribute("Mode")=="Mock","Injected storage is visibly labelled Mock")
end
local function data(f)return f.Profiles:Get(f.Player.UserId).Profile end
local function purchase(f,id,rank,revision,epoch,player)
	f.Research.LastRequest[f.Player.UserId]=-math.huge
	return f.Research:Buy(player or f.Player,epoch or f.Run.Epoch,id,rank,revision or data(f).Revision)
end
local function snapshot(f,cleared,highest)
	return {RunId=f.Run.Id,RunStartedUnixMs=f.Run.RunStartedUnixMs,ClearedFloors=cleared,HighestFloor=highest or cleared+1}
end

local harnessOk,harnessError=pcall(function()
	case("Five research areas expose bounded actual benefits and readable archive unlocks",function()
		check(#Catalog.Order==5,"Exactly five permanent research areas")
		local ranks={}
		for _,id in Catalog.Order do
			local definition=Catalog.Definitions[id]
			check(type(definition.NameRu)=="string"and type(definition.DescriptionRu)=="string"and #definition.Costs>0,"Research definition has real display data and capped ranks")
			for _,cost in definition.Costs do check(type(cost)=="number"and cost>0 and cost%1==0,"All prices are positive integer server definitions")end
			ranks[id]=#definition.Costs
		end
		local benefits=Catalog.Benefits(ranks)
		check(benefits.MaxHealth==9 and benefits.StartingCredits==30 and benefits.StartingRerolls==2,"Maximum starter benefits match brief")
		check(benefits.Scanner==2 and benefits.Archive==2,"Scanner and archive have two functional unlock tiers")
		check(#Catalog.Archive==2,"Archive has two authored records")
		for _,entry in Catalog.Archive do check(type(entry.Title)=="string"and #entry.Title>0 and type(entry.Text)=="string"and #entry.Text>40,"Unlocked archive page has readable authored content")end
		local empty=Catalog.Benefits({})
		check(empty.MaxHealth==0 and empty.StartingCredits==0 and empty.StartingRerolls==0,"No purchased ranks invent starter benefits")
	end)

	case("Loaded benefits apply before weapon choice and temporary effects disappear on death",function()
		local f=fixture({body_fortification=3,starting_budget=3,protocol_analysis=2,elevator_scanner=2,research_archive=2});load(f)
		check(f.Run.Meta.MaxHealth==9 and f.Run.Credits==30 and f.Run.Rerolls==2,"Ready profile initializes run benefits")
		check(f.H.MaxHealth==109 and f.H.Health==109,"Fresh starter health fills to researched maximum")
		f.Run.Boons.weiss_field_protocol={Level=3,Rarity="Heroic"};f.Run.SupplyHealth=50;Effects.RefreshHealth()
		check(f.H.MaxHealth==160,"Meta, run health and boon health share the existing sixty-HP cap")
		local rewards=Rewards.new(f.Run,f.State);local shop=Shop.new(f.Run,f.State,rewards)
		check(shop:HealthRoom()==0,"Shop cannot sell useless health beyond combined cap")
		f.Run.SupplyHealth=0
		local field=Boons.Values("weiss_field_protocol",3,"Heroic").MaxHealth
		check(shop:HealthRoom()==60-field-9,"Shop budget includes permanent fortification")
		f.Player:SetAttribute("SelectedWeapon","Glock");f.Context.Phase="EncounterActive"
		f.Run.Credits=77;f.Run.Rerolls=1;f.H.Health=42;f.Research:ApplyStart(f.Player)
		check(f.Run.Credits==77 and f.Run.Rerolls==1 and f.H.Health==42,"Profile refresh never resets or heals active combat")
		local ranks=Schema.Copy(data(f).ResearchRanks);local old=f.Run:Finish(12,"Death");Effects.Clear()
		check(f.Run.Credits==0 and f.Run.Rerolls==0 and f.Run.Meta==nil and next(f.Run.Boons)==nil and f.Run.SupplyHealth==0,"Death removes every temporary and applied meta snapshot")
		check(data(f).ResearchRanks.body_fortification==ranks.body_fortification,"Permanent research remains in separate profile")
		f.Player:SetAttribute("SelectedWeapon",nil);f.Context.Phase="ChoosingWeapon"
		f.Run:Begin(13,f.Research:Benefits(f.Player));Effects.Bind(f.Run,f.Player);f.Research:ApplyStart(f.Player)
		check(f.Run.Credits==30 and f.Run.Rerolls==2 and f.H.MaxHealth==109 and f.H.Health==109,"Replacement run receives starter benefits again without previous build")
		check(f.Run:GetResults().RunId==old.RunId,"New starter setup preserves previous results")
	end)

	case("Research pending ledger uses genuine deduplicated floors rather than kills",function()
		local f=fixture();load(f);local epoch=f.Run.Epoch
		f.Run:SetFloor(epoch,1,3)
		for _=1,6 do f.Run:RecordKill(epoch)end
		check(f.Run.PendingResearch==0,"Kills alone never generate permanent research")
		check(f.Run:CompleteFloor(epoch,1)and f.Run.PendingResearch==Catalog.Rewards.PerFloor,"One genuine floor adds configured pending amount")
		check(not f.Run:CompleteFloor(epoch,1)and f.Run.PendingResearch==Catalog.Rewards.PerFloor,"Duplicate floor completion does not add research")
		check(f.Run:CompleteFloor(epoch,2),"Distinct floor can be completed")
		local result=f.Run:Finish(1,"Death")
		check(result.PendingResearch==2*Catalog.Rewards.PerFloor and f.Run.PendingResearch==0,"Finish snapshots pending research before clearing it")
		check(f.Run:Finish(2,"Duplicate")==nil and not f.Run:CompleteFloor(epoch,3),"Repeated death and stale floor cannot pay twice")
	end)

	case("Seeded scanner card previews do not consume pity or mutate offer ownership",function()
		local f=fixture({elevator_scanner=2});load(f)
		f.Run.Pity={CommonDrought=2,EpicDrought=3};f.Run.Rerolls=2
		local rewards=Rewards.new(f.Run,f.State)
		local route=rewards:RoutesFor(572,8)[1]
		local function signature(cards)
			local out={}
			for _,card in cards do table.insert(out,card.Id..":"..tostring(card.Level)..":"..tostring(card.Rarity))end
			return table.concat(out,"|")
		end
		local first=rewards:BuildCards(route,0,nil,"Glock")
		local second=rewards:BuildCards(route,0,nil,"Glock")
		check(#first==3 and signature(first)==signature(second),"Initial preview reproduces actual seeded first offer")
		check(f.Run.Pity.CommonDrought==2 and f.Run.Pity.EpicDrought==3 and f.Run.Rerolls==2,"Previewing cards never advances pity or consumes rerolls")
		check(rewards.Selected==nil and rewards.Offer==nil and next(f.Run.Patrons)==nil,"Preview generation cannot select a route or affiliate patron")
		for _,id in Boons.Order do f.Run.Boons[id]={Level=3,Rarity="Heroic"}end
		local exhausted=rewards:BuildCards(route,0,nil,"Glock")
		check(#exhausted==3,"Fully exhausted patron still previews safe three-card fallback")
		for _,card in exhausted do check(card.Rarity==nil and type(card.DescriptionRu)=="string","Supply preview is explicitly non-rarity reward with valid description")end
		check(f.Run.Pity.CommonDrought==2 and f.Run.Pity.EpicDrought==3,"Fallback preview preserves pity too")
	end)

	case("Cumulative checkpoints and final receipt survive save/reload without duplicate awards",function()
		local f=fixture();load(f);local balance=data(f).ResearchData
		local first=snapshot(f,1,2);f.Research:Checkpoint(f.Player,first,false)
		waitFor(function()return f.Profiles:Receipt(f.Player.UserId,first.RunId)~=nil end,"First checkpoint produces durable mock receipt")
		local paid=data(f).ResearchData
		check(paid==balance+Catalog.Rewards.PerFloor+Catalog.Rewards.RecordBonus,"First cleared floor and new record award configured totals")
		local final=snapshot(f,3,4);f.Results:SetAttribute("RunId",final.RunId)
		f.Research:Checkpoint(f.Player,final,true)
		waitFor(function()local receipt=f.Profiles:Receipt(f.Player.UserId,final.RunId);return receipt and receipt.PaidFloors==3 and f.Results:GetAttribute("ResearchStatus")=="Saved"end,"Final cumulative checkpoint updates existing run receipt")
		local total=3*Catalog.Rewards.PerFloor+Catalog.Rewards.RecordBonus
		check(data(f).ResearchData==balance+total and f.Results:GetAttribute("ResearchEarned")==total,"Results show cumulative earnings rather than final incremental delta")
		f.Research:Checkpoint(f.Player,first,false);f.Research:Checkpoint(f.Player,final,true);task.wait()
		check(data(f).ResearchData==balance+total,"Old partial and duplicate final checkpoint cannot mint research")
		local reloaded=Profiles.new(f.Store,{Attempts=1,RetryDelay=0,IsStudio=true,Mode="Mock"})
		check(reloaded:Load(f.Player.UserId),"Fresh profile service can reload mock saved data")
		check(reloaded:Get(f.Player.UserId).Profile.ResearchData==balance+total,"Research balance survives a fresh service over same injected backend")
		local ok=reloaded:AwardRun(f.Player.UserId,final)
		check(ok and reloaded:Get(f.Player.UserId).Profile.ResearchData==balance+total,"Reloaded durable receipt rejects duplicate payment")
		local stored=f.Store.Values["u_"..f.Player.UserId]
		check(stored.Boons==nil and stored.Credits==nil and stored.Floor==nil,"Persistent payload excludes temporary world/run data")
	end)

	case("Research checkout validates server owner, phase, epoch, revision and prerequisites",function()
		local f=fixture();load(f);local id="body_fortification";local revision=data(f).Revision;local balance=data(f).ResearchData
		check(not purchase(f,id,0,revision,f.Run.Epoch-1),"Stale run epoch cannot purchase")
		check(not purchase(f,id,0,revision,f.Run.Epoch,{}),"Foreign player cannot purchase")
		for _,phase in {"EncounterActive","ElevatorTravel","RewardInterlude","ShopInterlude","ResettingRun"}do
			f.Context.Phase=phase;check(not purchase(f,id,0,revision),"Unsafe phase rejects permanent purchase")
		end
		f.Context.Phase="ChoosingWeapon";f.Player:SetAttribute("SelectedWeapon","Glock")
		check(not purchase(f,id,0,revision),"Committed weapon selection blocks pre-run checkout")
		f.Player:SetAttribute("SelectedWeapon",nil)
		check(not purchase(f,id,0,revision+1)and not purchase(f,id,1,revision),"Wrong profile revision and expected rank rejected")
		check(not purchase(f,"fabricated",0,revision)and not purchase(f,id,0/0,revision),"Invalid research and malformed rank rejected")
		f.H.Health=0;check(not purchase(f,id,0,revision),"Dead character cannot purchase")
		local replacement=fakePlayer(f.Player.UserId);f.Player.Character=replacement.Character
		f.H=f.Player.Character:FindFirstChildOfClass("Humanoid");Effects.Bind(f.Run,f.Player)
		check(data(f).ResearchData==balance and data(f).ResearchRanks[id]==0,"Rejected requests leave balance and ranks intact")
		check(purchase(f,id,0,revision),"Live owner purchases eligible next rank")
		check(data(f).ResearchRanks[id]==1 and data(f).ResearchData==balance-Catalog.Definitions[id].Costs[1],"Server cost and next rank commit once")
		check(f.Run.Meta.MaxHealth==3 and f.H.MaxHealth==103,"Ready pre-run research immediately refreshes planned starter build")
		check(not purchase(f,id,0,revision),"Duplicate old rank/revision cannot buy another level")
	end)

	case("Rank caps, insufficient funds and rate limit never spend twice",function()
		local f=fixture();load(f);local id="body_fortification"
		check(purchase(f,id,0),"Initial purchase accepted")
		local balance=data(f).ResearchData;local revision=data(f).Revision
		check(not f.Research:Buy(f.Player,f.Run.Epoch,id,1,revision),"Immediate second checkout rate limited even at current revision")
		check(data(f).ResearchData==balance and data(f).ResearchRanks[id]==1,"Rate limit has no economy side effect")
		check(purchase(f,id,1)and purchase(f,id,2),"Remaining authored ranks can be purchased with fresh requests")
		balance=data(f).ResearchData
		check(not purchase(f,id,3)and data(f).ResearchData==balance,"Rank cap rejects fourth purchase without charging")
		local poor=fixture();poor.Store.Values["u_"..poor.Player.UserId].ResearchData=0;load(poor)
		check(not purchase(poor,"protocol_analysis",0)and data(poor).ResearchData==0,"Insufficient research cannot create negative balance")
	end)

	case("Yielding checkout locks concurrent requests and cannot alter replacement run",function()
		local f=fixture();load(f);local entered,released,done=false,false,false
		f.Store.BeforeUpdate=function()entered=true;while not released do task.wait()end end
		local epoch=f.Run.Epoch;local revision=data(f).Revision;local bought
		task.spawn(function()bought=purchase(f,"starting_budget",0,revision);done=true end)
		waitFor(function()return entered end,"Mock purchase reaches delayed store boundary")
		check(f.Player:GetAttribute("ResearchBusy")==true and f.Research.Folder:GetAttribute("Busy")==true,"Research busy gate is set before yielding store write")
		check(not purchase(f,"body_fortification",0,revision),"Concurrent purchase rejected while profile is busy")
		f.Run:Finish(1,"Death");f.Run:Begin(2);f.Run.Credits=7;f.Context.Phase="EncounterActive"
		released=true;waitFor(function()return done end,"Original checkout finishes after restart")
		check(bought and data(f).ResearchRanks.starting_budget==1,"Validated purchase remains durably owned")
		check(f.Run.Epoch~=epoch and f.Run.Credits==7 and f.Run.Meta.StartingCredits==0,"Old checkout cannot reset replacement combat resources")
		check(f.Player:GetAttribute("ResearchBusy")==false,"Completed operation releases input gate")
	end)

	case("Unavailable load never writes defaults or enables purchases",function()
		local f=fixture();local previous=Schema.Copy(f.Store.Values["u_"..f.Player.UserId])
		f.Store.GetAsync=function()error("Injected load failure")end
		f.Research:Load(f.Player)
		waitFor(function()local status=f.Research.Folder:GetAttribute("Status");return status=="Unavailable"or status=="Error"end,"Failed load is visible")
		check(not f.Research:Buy(f.Player,f.Run.Epoch,"body_fortification",0,0),"Unavailable profile cannot purchase")
		check(f.Store.Writes==0 and f.Store.Values["u_"..f.Player.UserId].ResearchData==previous.ResearchData,"Load failure does not overwrite saved profile")
		check(f.Run.Meta.MaxHealth==0 and f.Run.Credits==0,"Unavailable research cannot fabricate benefits")
	end)

	case("Version-zero migration preserves first reserved run payout and freezes identity after combat",function()
		local f=fixture();local initial=Schema.New();local cutoff=5000
		f.Store.Values["u_"..f.Player.UserId]={Version=0,ResearchData=50,ResearchRanks=initial.ResearchRanks,BestFloor=0}
		f.Profiles.UnixMs=function()return cutoff end
		f.Run.RunStartedUnixMs=cutoff-1
		local id,epoch=f.Run.Id,f.Run.Epoch
		load(f)
		local profile=data(f);local paymentTime=f.Run.RunStartedUnixMs
		check(profile.Version==1 and profile.EvictedBeforeUnixMs==cutoff,"Legacy profile migrates with explicit retired-event boundary")
		check(paymentTime>cutoff and f.Run.Id==id and f.Run.Epoch==epoch,"Reserved first run moves beyond migration boundary without resetting run or epoch")
		f.Player:SetAttribute("SelectedWeapon","Glock");f.Context.Phase="EncounterActive"
		f.Profiles.Entries[f.Player.UserId].Profile.EvictedBeforeUnixMs=paymentTime+1000
		f.Research:ApplyStart(f.Player)
		check(f.Run.RunStartedUnixMs==paymentTime,"Active combat cannot rewrite payment identity even if profile boundary advances")
		check(f.Run:CompleteFloor(epoch,1),"First genuine floor completes after profile migration")
		f.Player:SetAttribute("SelectedWeapon",nil);f.Context.Phase="ChoosingWeapon"
		f.Research:ApplyStart(f.Player)
		check(f.Run.RunStartedUnixMs==paymentTime,"A completed run ledger cannot rewrite timestamp through pre-run refresh")
		local final=f.Run:Finish(2,"Death")
		local ok,reason,receipt=f.Profiles:AwardRun(f.Player.UserId,final)
		check(ok and receipt and receipt.PaidFloors==1,"Real injected ProfileService accepts first run instead of ExpiredRun: "..tostring(reason))
		check(data(f).ResearchData==50+Catalog.Rewards.PerFloor+Catalog.Rewards.RecordBonus,"Migrated first floor pays exactly its configured research and new record bonus")
		local stored=f.Store.Values["u_"..f.Player.UserId]
		check(stored.Version==1 and stored.Claims[id].RunStartedUnixMs==paymentTime,"Successful payment stores migrated profile and stable receipt identity")
	end)

	case("Result callbacks require exact run identity and leave owner guards intact",function()
		local f=fixture();load(f);local old=snapshot(f,2,3)
		f.Results:SetAttribute("RunId","new_result");f.Results:SetAttribute("ResearchEarned",77)
		f.Research:UpdateResult(f.Player,old,true,{ResearchEarnedTotal=15,NewRecord=true})
		check(f.Results:GetAttribute("ResearchEarned")==77,"Late prior-run receipt cannot replace newer result")
		f.Results:SetAttribute("RunId",old.RunId)
		f.Research:UpdateResult(f.Player,old,false,nil)
		check(f.Results:GetAttribute("ResearchStatus")=="Pending"and f.Results:GetAttribute("PendingResearch")==2*Catalog.Rewards.PerFloor,"Failed save shows pending research without claiming success")
		f.Research:UpdateResult(f.Player,old,true,{ResearchEarnedTotal=15,NewRecord=true})
		check(f.Results:GetAttribute("ResearchEarned")==15 and f.Results:GetAttribute("NewRecord")==true,"Accepted receipt updates matching result")
		f.Research:Leave(f.Player);f.Research:UpdateResult(f.Player,old,true,{ResearchEarnedTotal=999})
		check(f.Results:GetAttribute("ResearchEarned")==15,"Leave invalidates result presentation callbacks")
	end)

	case("Delayed load cannot publish after leave or overwrite newer same-player continuation",function()
		local f=fixture({starting_budget=3});local original=f.Profiles;local entered,released,completed=false,false,false
		local calls=0;local delayed={}
		function delayed:Get(id)return original:Get(id)end
		function delayed:Load(id)
			calls+=1
			if calls==1 then entered=true;while not released do task.wait()end end
			local ok,reason=original:Load(id)
			if calls>=2 and released then completed=true end
			return ok,reason
		end
		f.Research.Profiles=delayed;f.Research:Load(f.Player)
		waitFor(function()return entered end,"First load is delayed before reading mock profile")
		f.Research:Leave(f.Player);f.Research:Load(f.Player)
		waitFor(function()return f.Research.Folder:GetAttribute("Status")=="Ready"end,"New same-player load completes independently")
		f.Research.Folder:SetAttribute("Balance",1234);f.Run.Credits=11;f.H.Health=50
		released=true;waitFor(function()return completed end,"Earlier delayed load eventually returns")
		check(f.Research.Folder:GetAttribute("Balance")==1234 and f.Run.Credits==11 and f.H.Health==50,"Load generation rejects earlier completion even for identical player object")
		f.Research:Leave(f.Player);local before=f.Research.Folder:GetAttribute("Balance")
		f.Research:Publish(f.Player)
		check(f.Research.Owner==nil and f.Research.Folder:GetAttribute("Balance")==before,"Detached owner cannot republish profile")
	end)
end)
Effects.Clear()
for _,holder in holders do holder:Destroy()end
if not harnessOk then table.insert(report.Failed,{Name="Harness",Error=tostring(harnessError)})end
script:SetAttribute("Success",#report.Failed==0)
script:SetAttribute("Error",#report.Failed==0 and ""or HttpService:JSONEncode(report.Failed))
script:SetAttribute("Report",HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
