-- Temporary Studio Script. Explicit injected fault store; no real DataStore proof.
local Server=game.ServerScriptService:WaitForChild("Server")
local Profiles=require(Server.ProfileService)
local Schema=require(Server.ProfileSchema)
local Catalog=require(game.ReplicatedStorage.Shared.ResearchCatalog)
local report={Cases={},Failed={},Assertions=0,Mode="Mock",RealDataStoreVerified=false}
local function check(condition,message)report.Assertions+=1;assert(condition,message)end
local function case(name,body)
	local ok,err=pcall(body);table.insert(report.Cases,{Name=name,Passed=ok})
	if not ok then table.insert(report.Failed,{Name=name,Error=tostring(err)})end
end
local function faultStore()
	local backend={Values={},Reads=0,Calls=0,Commits=0,FailReads=0,FailUpdates=0,LostAcks=0}
	function backend:GetAsync(key)
		self.Reads+=1
		if self.FailReads>0 then self.FailReads-=1;error("Injected read failure")end
		return Schema.Copy(self.Values[key])
	end
	function backend:UpdateAsync(key,transform)
		self.Calls+=1
		while self.Lock do task.wait(.001)end
		self.Lock=true
		local outcome=table.pack(pcall(function()
			if self.FailUpdates>0 then self.FailUpdates-=1;error("Injected precommit failure")end
			if self.BeforeUpdate then self:BeforeUpdate(key)end
			local nextValue=transform(Schema.Copy(self.Values[key]))
			if self.Conflict then
				self:Conflict(key);self.Conflict=nil
				nextValue=transform(Schema.Copy(self.Values[key]))
			end
			if nextValue==nil then return nil end -- Real cancellation returns nil.
			self.Values[key]=Schema.Copy(nextValue);self.Commits+=1
			if self.LostAcks>0 then self.LostAcks-=1;error("Injected commit-then-error")end
			return Schema.Copy(nextValue)
		end))
		self.Lock=false
		if not outcome[1]then error(outcome[2])end
		return outcome[2]
	end
	return backend
end
local function service(backend,attempts,clock)
	return Profiles.new(backend,{Attempts=attempts or 1,RetryDelay=0,LockTimeout=2,IsStudio=true,UnixMs=clock or function()return 1000 end})
end
local function seed(backend,balance)
	local profile=Schema.New();profile.ResearchData=balance or 0;backend.Values.u_101=profile;return profile
end
local function snapshot(id,clears,started,highest)
	return {RunId=id,RunStartedUnixMs=started or 1100,ClearedFloors=clears,HighestFloor=highest or math.max(1,clears+1)}
end
local function finish(tasks)
	local limit=os.clock()+5
	while os.clock()<limit do local done=true;for _,value in tasks do done=done and value.Complete end;if done then break end;task.wait(.005)end
	for _,value in tasks do check(value.Complete and value.Ok,"Concurrent operation finishes without exception")end
end
local function spawn(body)
	local result={Complete=false};task.spawn(function()local values=table.pack(pcall(body));result.Ok=values[1];result.Values=values;result.Complete=true end);return result
end
case("Catalog has five bounded research areas and exact starter benefits",function()
	check(#Catalog.Order==5,"Five research areas")
	local ranks={};for _,id in Catalog.Order do ranks[id]=#Catalog.Definitions[id].Costs end
	local b=Catalog.Benefits(ranks)
	check(b.MaxHealth==9 and b.StartingCredits==30 and b.StartingRerolls==2 and b.Scanner==2 and b.Archive==2,"Benefits remain modest and capped")
	check(#Catalog.Archive==2 and Catalog.Rewards.PerFloor==6 and Catalog.Rewards.RecordBonus==3,"Real lore and bounded payout definitions")
end)
case("Successful missing-key read creates defaults only in memory; Get is detached",function()
	local backend=faultStore();local p=service(backend)
	check(p:Load(101),"New profile loads")
	check(backend.Commits==0 and backend.Calls==0,"Load never writes defaults")
	local data=p:Get(101);check(data.Status=="Ready"and data.Mode=="Mock"and data.Profile.ResearchData==0,"Explicit mock profile ready")
	data.Profile.ResearchData=999;data.Profile.ResearchRanks.body_fortification=3
	check(p:Get(101).Profile.ResearchData==0 and p:Get(101).Profile.ResearchRanks.body_fortification==0,"Read copies cannot mutate cached profile")
end)
case("Cumulative checkpoints pay deltas; uncompleted high floor gives no record",function()
	local backend=faultStore();local p=service(backend);check(p:Load(101),"Load")
	local ok,_,receipt=p:AwardRun(101,snapshot("cumulative",1,1100,4))
	check(ok and receipt.ResearchEarnedTotal==9 and receipt.NewRecord,"First clear pays six plus once-per-run record three")
	check(p:Get(101).Profile.BestFloor==1,"Highest reached floor four is not a completed record")
	ok,_,receipt=p:AwardRun(101,snapshot("cumulative",2,1100,5))
	check(ok and receipt.PaidFloors==2 and receipt.ResearchEarnedTotal==15 and receipt.ResearchEarned==15,"Second clear pays only six")
	local commits=backend.Commits
	check(p:AwardRun(101,snapshot("cumulative",1,1100)),"Lower checkpoint is a confirmed duplicate")
	check(p:AwardRun(101,snapshot("cumulative",2,1100)),"Final death duplicates checkpoint safely")
	check(backend.Commits==commits and p:Get(101).Profile.ResearchData==15,"No repeated payout or record bonus")
	local copy=p:Receipt(101,"cumulative");copy.PaidFloors=99;check(p:Receipt(101,"cumulative").PaidFloors==2,"Receipt is detached")
end)
case("New-run record bonus applies once when that run first beats durable best",function()
	local backend=faultStore();local p=service(backend);p:Load(101)
	check(p:AwardRun(101,snapshot("first",2,1100)),"First run")
	local ok,_,receipt=p:AwardRun(101,snapshot("second",1,1200))
	check(ok and receipt.ResearchEarnedTotal==6 and not receipt.NewRecord,"Below best earns only floor data")
	ok,_,receipt=p:AwardRun(101,snapshot("second",3,1200))
	check(ok and receipt.ResearchEarnedTotal==21 and receipt.NewRecord,"First new record earns one three-data bonus")
	p:AwardRun(101,snapshot("second",4,1200))
	check(p:Receipt(101,"second").ResearchEarnedTotal==27 and p:Get(101).Profile.BestFloor==4,"Further record floors do not repeat bonus")
end)
case("Failed load blocks writes and retains visible pending award",function()
	local backend=faultStore();seed(backend,123);backend.FailReads=100
	local p=service(backend);check(not p:Load(101),"Load failure visible")
	check(not p:AwardRun(101,snapshot("unloaded",1)),"No payout write after failed load")
	check(not p:Purchase(101,"body_fortification",0),"No research purchase after failed load")
	check(backend.Calls==0 and backend.Commits==0 and backend.Values.u_101.ResearchData==123,"Existing data never overwritten")
	check(p:Get(101).PendingAwards.unloaded~=nil and p:Get(101).Status=="Error","Pending data is labelled unsaved")
	check(not p:Close(0),"Zero shutdown budget reports unresolved pending honestly")
end)
case("Corrupt and future schemas fail closed without writes",function()
	for _,raw in {"broken",{}, {Version=9}, {Version=1,ResearchData=-1}}do
		local backend=faultStore();backend.Values.u_101=raw;local p=service(backend)
		check(not p:Load(101),"Invalid schema refuses load")
		check(not p:AwardRun(101,snapshot("bad_schema",1)),"Invalid profile refuses write")
		check(backend.Calls==0 and backend.Commits==0,"Corrupt/future data remains untouched")
	end
	local valid=Schema.New();valid.FutureField=true;check(Schema.Decode(valid,1000)==nil,"Unknown durable fields are not silently discarded")
end)
case("Known v0 migration preserves balances/ranks and freezes cutoff at successful load",function()
	local backend=faultStore();local old={Version=0,ResearchData=30,ResearchRanks=Schema.New().ResearchRanks,BestFloor=3}
	old.ResearchRanks.body_fortification=1;backend.Values.u_101=old
	local now=1000;local p=service(backend,1,function()return now end)
	check(p:Load(101)and backend.Commits==0,"Migration is read-only until a real operation")
	check(p:Get(101).Profile.ResearchRanks.body_fortification==1,"Rank preserved")
	check(not p:AwardRun(101,snapshot("legacy_replay",1,900)),"Pre-migration history cannot be repaid")
	now=1200
	check(p:AwardRun(101,snapshot("post_load",1,1100)),"Post-load run survives later write clock")
	check(backend.Values.u_101.Version==1 and backend.Values.u_101.ResearchData==36 and backend.Values.u_101.EvictedBeforeUnixMs==1000,"Migration persisted atomically with validated new operation")
end)
case("Commit-then-error award resolves cancelled retry with durable read",function()
	local backend=faultStore();local p=service(backend,3);p:Load(101);backend.LostAcks=1
	local ok,_,receipt=p:AwardRun(101,snapshot("lost_ack",1))
	check(ok and receipt.ResearchEarnedTotal==9,"Durable receipt confirms uncertain acknowledgement")
	check(backend.Commits==1 and backend.Calls==2 and backend.Reads>=2,"Retry cancels duplicate then rereads latest store")
	check(p:Get(101).Profile.ResearchData==9 and next(p:Get(101).PendingAwards)==nil,"No duplicate award; no fake pending after confirmation")
end)
case("Failed checkpoint remains retryable and survives another service reload",function()
	local backend=faultStore();local p=service(backend);p:Load(101);backend.FailUpdates=1
	check(not p:AwardRun(101,snapshot("retry_award",2)),"Write failure returns unsaved")
	check(p:Get(101).PendingAwards.retry_award~=nil and p:Get(101).Profile.ResearchData==0,"Confirmed cache never claims failed write")
	check(p:Retry(101)and p:Get(101).PendingAwards.retry_award==nil,"Retry flushes queued checkpoint")
	local rejoin=service(backend);check(rejoin:Load(101)and rejoin:Get(101).Profile.ResearchData==15,"Explicit mock save/reload retains data")
end)
case("Purchase commit-then-error uses stable operation receipt, not a second debit",function()
	local backend=faultStore();seed(backend,100);local p=service(backend,3);p:Load(101);backend.LostAcks=1
	check(p:Purchase(101,"body_fortification",0),"Retry confirms purchased rank")
	check(backend.Commits==1 and backend.Values.u_101.ResearchData==82 and backend.Values.u_101.ResearchRanks.body_fortification==1,"Exactly one eighteen-data debit")
	check(not p:Purchase(101,"body_fortification",0)and backend.Commits==1,"A distinct stale purchase rejects")
end)
case("Ambiguous purchase stays visible, blocks another checkout and retries after reread",function()
	local backend=faultStore();seed(backend,100);local p=service(backend);p:Load(101);backend.LostAcks=1
	check(not p:Purchase(101,"body_fortification",0),"Unacknowledged purchase not declared saved")
	check(p:Get(101).PendingPurchase~=nil and p:Get(101).Status=="Error"and p:Get(101).Profile.ResearchRanks.body_fortification==0,"Pending purchase visible beside last confirmed profile")
	check(not p:Purchase(101,"starting_budget",0),"Another purchase blocked until resolution")
	check(p:Load(101)and p:Get(101).PendingPurchase~=nil,"Reread cannot discard pending operation")
	check(p:Retry(101)and p:Get(101).PendingPurchase==nil,"Stable receipt resolves pending")
	check(backend.Commits==1 and p:Get(101).Profile.ResearchData==82,"No second debit during reconciliation")
end)
case("Research prices, caps, insufficient funds and strict UserIds",function()
	local backend=faultStore();seed(backend,1000);local p=service(backend);p:Load(101)
	for rank=0,2 do check(p:Purchase(101,"body_fortification",rank),"Rank purchased")end
	check(p:Get(101).Profile.ResearchData==886,"Centralized costs18/36/60 spent exactly")
	check(not p:Purchase(101,"body_fortification",3),"Rank cap rejects")
	check(not p:Purchase(101,"unknown",0)and not p:Purchase(101,"starting_budget",0/0),"Malformed research request rejects")
	local poor=service(faultStore());poor:Load(101);check(not poor:Purchase(101,"starting_budget",0),"Insufficient funds reject")
	for _,id in {0,math.huge,0/0,1.5,"101"}do check(not p:Load(id),"Invalid user identifier rejects")end
	check(p:Load(-1)and p:Load(1),"Negative Studio IDs are supported independently")
	check(p:AwardRun(-1,snapshot("negative",1))and backend.Values["u_-1"].ResearchData==9 and backend.Values["u_1"]==nil,"Signed keys remain distinct")
	local liveRules=Profiles.new(backend,{Attempts=1,RetryDelay=0,IsStudio=false});check(not liveRules:Load(-1),"Negative IDs forbidden by live rules")
end)
case("Concurrent expected-rank purchases serialize once",function()
	local backend=faultStore();seed(backend,100);local p=service(backend);p:Load(101)
	backend.BeforeUpdate=function()task.wait(.03)end
	local a=spawn(function()return p:Purchase(101,"body_fortification",0)end)
	check(p:Get(101).Busy,"First yielding checkout holds user lock")
	local b=spawn(function()return p:Purchase(101,"body_fortification",0)end)
	finish({a,b})
	check(a.Values[2]and not b.Values[2]and backend.Commits==1,"Only one same-rank purchase succeeds")
	check(backend.Values.u_101.ResearchData==82,"One debit under concurrency")
end)
case("Concurrent services merge award and purchase without writing stale snapshots",function()
	local backend=faultStore();seed(backend,100)
	local a,b=service(backend),service(backend);a:Load(101);b:Load(101)
	backend.BeforeUpdate=function()task.wait(.01)end
	local first=spawn(function()return a:AwardRun(101,snapshot("parallel",1))end)
	local second=spawn(function()return b:Purchase(101,"body_fortification",0)end)
	finish({first,second});check(first.Values[2]and second.Values[2],"Both distinct operations commit")
	check(backend.Values.u_101.ResearchData==91 and backend.Values.u_101.ResearchRanks.body_fortification==1 and backend.Values.u_101.Claims.parallel~=nil,"Fresh atomic merge retains both changes")
end)
case("Concurrent cumulative snapshots retain later checkpoint queued during an API yield",function()
	local backend=faultStore();local p=service(backend);p:Load(101)
	backend.BeforeUpdate=function()task.wait(.02)end
	local first=spawn(function()return p:AwardRun(101,snapshot("overlap",1))end)
	local second=spawn(function()return p:AwardRun(101,snapshot("overlap",3))end)
	finish({first,second});check(first.Values[2]and second.Values[2],"Both checkpoints confirmed")
	check(backend.Values.u_101.Claims.overlap.PaidFloors==3 and backend.Values.u_101.ResearchData==21,"Later queued delta cannot be removed by earlier completion")
	check(next(p:Get(101).PendingAwards)==nil,"All cumulative pending checkpoints reconciled")
end)
case("Balance cap does not corrupt a cumulative receipt after research spending",function()
	local backend=faultStore();local p=service(backend);p:Load(101)
	check(p:AwardRun(101,snapshot("large_run",166667)),"Large authorized snapshot reaches balance cap")
	check(p:Get(101).Profile.ResearchData==Catalog.Limits.ResearchData,"Durable balance capped")
	check(p:Purchase(101,"body_fortification",0),"Spending frees eighteen data capacity")
	check(p:AwardRun(101,snapshot("large_run",166670)),"Later cumulative payout fills released capacity")
	check(p:Receipt(101,"large_run").ResearchEarnedTotal==Catalog.Limits.ResearchData+18,"Cumulative receipt can exceed current balance cap")
	check(Schema.Decode(backend.Values.u_101,1000)~=nil,"Persisted capped profile remains valid")
end)
case("UpdateAsync callback reexecution derives result from latest durable input",function()
	local backend=faultStore();seed(backend,100);local p=service(backend);p:Load(101)
	backend.Conflict=function(self,key)self.Values[key].ResearchData+=7 end
	check(p:AwardRun(101,snapshot("reexecuted",1)),"Reexecuted transform saves")
	check(backend.Values.u_101.ResearchData==116 and backend.Commits==1,"One payout adds onto external seven-data update")
end)
case("Sixty-four claim bound rejects evicted/old/tied replay before granting",function()
	local backend=faultStore();local p=service(backend);p:Load(101)
	for i=1,65 do check(p:AwardRun(101,snapshot("bounded_"..i,1,1000+i)),"Bounded claim commits")end
	local profile=backend.Values.u_101;local count=0;for _ in profile.Claims do count+=1 end
	check(count==64 and profile.EvictedBeforeUnixMs==1001 and profile.Claims.bounded_1==nil,"Oldest durable marker evicted with timestamp watermark")
	local funds,commits=profile.ResearchData,backend.Commits
	check(not p:AwardRun(101,snapshot("bounded_1",1,1001)),"Evicted ID cannot pay twice")
	check(not p:AwardRun(101,snapshot("tied_late",1,1001)),"Watermark tie rejects conservatively")
	check(not p:AwardRun(101,snapshot("would_evict_self",1,1002)),"Older new receipt cannot grant then immediately evict itself")
	check(backend.Commits==commits and backend.Values.u_101.ResearchData==funds and next(p:Get(101).PendingAwards)==nil,"Terminal late rejects do not pay or block shutdown forever")
end)
case("Shutdown enqueue is synchronous; retry includes disconnected pending users",function()
	local backend=faultStore();local p=service(backend);p:Load(101);local reads,calls=backend.Reads,backend.Calls
	check(p:EnqueueRun(101,snapshot("shutdown",1)),"Shutdown event queued")
	check(backend.Reads==reads and backend.Calls==calls and p:PendingUsers()[1]==101,"Enqueue performs no API call; pending users enumerated")
	check(p:Close(1),"Bounded shutdown flush completes")
	check(backend.Values.u_101.ResearchData==9 and p:Receipt(101,"shutdown")~=nil,"Shutdown writes an actual confirmed receipt")
end)
case("Unpublished Studio is visibly unavailable and never silently selects mock",function()
	if game:GetService("RunService"):IsStudio()and (game.PlaceId==0 or game.GameId==0)then
		local p=Profiles.new();check(not p:Load(101),"Unpublished place cannot use real persistence")
		check(p:Get(101).Status=="Unavailable"and p:Get(101).Mode=="Studio"and p.Store==nil,"No mock or production fallback")
	else check(true,"Unpublished check skipped for published runtime")end
end)
script:SetAttribute("Report",game.HttpService:JSONEncode(report))
script:SetAttribute("Success",#report.Failed==0);script:SetAttribute("Complete",true)
