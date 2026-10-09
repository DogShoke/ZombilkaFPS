-- Server operations merge the latest durable value. Never save a cached profile.
local DataStores=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Catalog=require(game.ReplicatedStorage.Shared.ResearchCatalog)
local Schema=require(script.Parent.ProfileSchema)
local Profiles={}
Profiles.__index=Profiles
local function integer(value)return type(value)=="number"and value==value and math.abs(value)<=9007199254740991 and value%1==0 end
local function errorText(value)return tostring(value):sub(1,512)end
function Profiles.new(storeOverride,options)
	options=options or {}
	local studio=RunService:IsStudio()
	if storeOverride and options.IsStudio~=nil then studio=options.IsStudio end
	local mode=storeOverride and "Mock"or studio and "Studio"or "Live"
	local store,unavailable=storeOverride,nil
	if not store then
		if studio and (game.PlaceId==0 or game.GameId==0)then unavailable="UnpublishedStudio: real DataStore persistence is unavailable"
		else
			local ok,value=pcall(function()return DataStores:GetDataStore(studio and Catalog.Stores.Studio or Catalog.Stores.Live)end)
			if ok then store=value else unavailable=errorText(value)end
		end
	end
	local getOptions
	if not storeOverride then getOptions=Instance.new("DataStoreGetOptions");getOptions.UseCache=false end
	return setmetatable({Store=store,Mode=mode,Unavailable=unavailable,Studio=studio,Entries={},GetOptions=getOptions,
		Attempts=math.clamp(options.Attempts or 3,1,5),RetryDelay=math.clamp(options.RetryDelay or .4,0,4),
		LockTimeout=math.clamp(options.LockTimeout or 10,0,25),Wait=options.Wait or task.wait,
		UnixMs=options.UnixMs or function()return DateTime.now().UnixTimestampMillis end,OnChanged=options.OnChanged},Profiles)
end
function Profiles:ValidUser(userId)return integer(userId)and userId~=0 and (userId>0 or self.Studio)end
function Profiles:Entry(userId)
	local entry=self.Entries[userId]
	if not entry then entry={Status=self.Unavailable and "Unavailable"or "Loading",Error=self.Unavailable,Busy=false,Loaded=false,PendingAwards={}};self.Entries[userId]=entry end
	return entry
end
function Profiles:Get(userId)
	if not self:ValidUser(userId)then return {Status="Unavailable",Error="InvalidUserId",Busy=false,Mode=self.Mode}end
	local entry=self.Entries[userId]
	if not entry then return {Status=self.Unavailable and "Unavailable"or "Loading",Error=self.Unavailable,Busy=false,Mode=self.Mode,PendingAwards={}}end
	return Schema.Copy({Status=entry.Status,Profile=entry.Profile,Error=entry.Error,Busy=entry.Busy,Mode=self.Mode,
		PendingAwards=entry.PendingAwards,PendingPurchase=entry.PendingPurchase,LastReceipt=entry.LastReceipt,LastRejected=entry.LastRejected})
end
function Profiles:Receipt(userId,runId)
	local entry=self.Entries[userId]
	return entry and entry.Profile and Schema.Copy(entry.Profile.Claims[runId])or nil
end
function Profiles:Expired()return self.Deadline and os.clock()>=self.Deadline end
function Profiles:Notify(userId)
	if self.OnChanged then pcall(self.OnChanged,userId)end
end
function Profiles:Exclusive(userId,operation)
	if not self:ValidUser(userId)then return false,"InvalidUserId"end
	local entry=self:Entry(userId);local limit=os.clock()+self.LockTimeout
	while entry.Busy do
		if os.clock()>=limit or self:Expired()then return false,"Busy"end
		self.Wait(.025)
	end
	if self:Expired()then return false,"Deadline"end
	entry.Busy=true;self:Notify(userId)
	local result=table.pack(pcall(operation,entry))
	entry.Busy=false
	if not result[1]then entry.Status="Error";entry.Error=errorText(result[2])end
	self:Notify(userId)
	if not result[1]then return false,"InternalError"end
	return table.unpack(result,2,result.n)
end
function Profiles:Call(callback)
	local last
	for attempt=1,self.Attempts do
		if self:Expired()then return false,"Deadline"end
		local ok,value=pcall(callback)
		if ok then return true,value end
		last=errorText(value)
		if attempt<self.Attempts then
			local delay=self.RetryDelay*2^(attempt-1)
			if self.Deadline then delay=math.min(delay,math.max(0,self.Deadline-os.clock()))end
			if delay>0 then self.Wait(delay)end
		end
	end
	return false,last
end
function Profiles:Read(userId,migrationCutoff)
	if not self.Store then return nil,"Unavailable",self.Unavailable end
	local ok,raw=self:Call(function()return self.Store:GetAsync("u_"..userId,self.GetOptions)end)
	if not ok then return nil,"Error",raw end
	local cutoff=migrationCutoff or self.UnixMs()
	local profile,reason=Schema.Decode(raw,cutoff)
	if not profile then return nil,reason,reason end
	return profile,nil,nil,type(raw)=="table"and raw.Version==0 and cutoff or nil
end
function Profiles:LoadEntry(userId,entry)
	entry.Status="Loading"
	local profile,status,message,cutoff=self:Read(userId,entry.MigrationCutoff)
	if not profile then entry.Status=status;entry.Error=message;entry.Loaded=false;return false,status end
	entry.Profile=profile;entry.Status="Ready";entry.Error=nil;entry.Loaded=true
	entry.MigrationCutoff=entry.MigrationCutoff or cutoff
	-- Pending operations survive a reread; only confirmed operation receipts clear them.
	return true
end
function Profiles:Load(userId)
	if self.Closing then return false,"Closing"end
	return self:Exclusive(userId,function(entry)return self:LoadEntry(userId,entry)end)
end
function Profiles:Update(userId,entry,transform)
	local decision="Pending"
	local ok,raw=self:Call(function()
		return self.Store:UpdateAsync("u_"..userId,function(current)
			if self:Expired()then decision="Deadline";return nil end
			local profile,reason=Schema.Decode(current,entry.MigrationCutoff or self.UnixMs())
			if not profile then decision=reason;return nil end
			local updated;updated,decision=transform(profile)
			return updated
		end)
	end)
	if not ok then entry.Status="Error";entry.Error=errorText(raw);return false,"Pending"end
	if decision=="Corrupt"or decision=="NewerSchema"then entry.Status=decision;entry.Error=decision;entry.Loaded=false;return false,decision end
	local profile,status,message,cutoff
	if raw==nil then
		-- UpdateAsync cancellation returns nil: bypass GetAsync cache to confirm the
		-- durable receipt after an ambiguous earlier commit or a logical rejection.
		profile,status,message,cutoff=self:Read(userId,entry.MigrationCutoff)
	else profile,status=Schema.Decode(raw,self.UnixMs());message=status end
	if not profile then entry.Status=status or "Error";entry.Error=message;return false,"Pending"end
	entry.Profile=profile;entry.Status="Ready";entry.Error=nil;entry.Loaded=true
	entry.MigrationCutoff=entry.MigrationCutoff or cutoff
	return true,decision
end
local function trimClaims(profile)
	local sorted={};for _,claim in profile.Claims do table.insert(sorted,claim)end
	table.sort(sorted,function(a,b)return a.RunStartedUnixMs==b.RunStartedUnixMs and a.RunId<b.RunId or a.RunStartedUnixMs<b.RunStartedUnixMs end)
	for i=1,#sorted-Catalog.Limits.Claims do
		local claim=sorted[i];profile.Claims[claim.RunId]=nil
		profile.EvictedBeforeUnixMs=math.max(profile.EvictedBeforeUnixMs,claim.RunStartedUnixMs)
	end
end
function Profiles:AwardEntry(userId,entry,snapshot)
	if not entry.Loaded or entry.Status~="Ready"then return false,"ProfileNotReady"end
	local ok,reason=self:Update(userId,entry,function(profile)
		local claim=profile.Claims[snapshot.RunId]
		if claim and claim.RunStartedUnixMs~=snapshot.RunStartedUnixMs then return nil,"InvalidRunIdentity"end
		if not claim and snapshot.RunStartedUnixMs<=profile.EvictedBeforeUnixMs then return nil,"ExpiredRun"end
		if not claim then
			local count,oldest=0,math.huge
			for _,existing in profile.Claims do count+=1;oldest=math.min(oldest,existing.RunStartedUnixMs)end
			-- An older new receipt would immediately evict itself and could not be
			-- acknowledged/deduplicated safely. Refuse before granting any data.
			if count>=Catalog.Limits.Claims and snapshot.RunStartedUnixMs<=oldest then return nil,"ExpiredRun"end
		end
		if claim and snapshot.ClearedFloors<=claim.PaidFloors then return nil,"AlreadySaved"end
		claim=claim or {RunId=snapshot.RunId,RunStartedUnixMs=snapshot.RunStartedUnixMs,PaidFloors=0,ResearchEarnedTotal=0,ResearchEarned=0,NewRecord=false,RecordBonusPaid=false}
		local completed=math.min(snapshot.ClearedFloors,snapshot.HighestFloor)
		local newRecord=completed>profile.BestFloor
		local bonus=newRecord and not claim.RecordBonusPaid and Catalog.Rewards.RecordBonus or 0
		local earned=math.min(Catalog.Limits.ResearchData-profile.ResearchData,(snapshot.ClearedFloors-claim.PaidFloors)*Catalog.Rewards.PerFloor+bonus)
		profile.ResearchData+=earned;profile.BestFloor=math.max(profile.BestFloor,completed)
		claim.PaidFloors=snapshot.ClearedFloors;claim.ResearchEarnedTotal+=earned;claim.ResearchEarned=claim.ResearchEarnedTotal
		claim.NewRecord=claim.NewRecord or newRecord;claim.RecordBonusPaid=claim.RecordBonusPaid or bonus>0
		profile.Claims[snapshot.RunId]=claim;trimClaims(profile);profile.Revision=math.min(9007199254740991,profile.Revision+1)
		return profile,"Saved"
	end)
	if not ok then return false,reason end
	if reason~="Saved"and reason~="AlreadySaved"then
		if reason=="ExpiredRun"or reason=="InvalidRunIdentity"then
			entry.PendingAwards[snapshot.RunId]=nil;entry.LastRejected={RunId=snapshot.RunId,Reason=reason}
		end
		return false,reason
	end
	local receipt=entry.Profile.Claims[snapshot.RunId]
	if not receipt or receipt.PaidFloors<snapshot.ClearedFloors then return false,reason end
	entry.LastReceipt=Schema.Copy(receipt)
	local pending=entry.PendingAwards[snapshot.RunId]
	if pending and pending.ClearedFloors<=receipt.PaidFloors then entry.PendingAwards[snapshot.RunId]=nil end
	return true,reason,Schema.Copy(receipt)
end
function Profiles:EnqueueRun(userId,snapshot)
	if self.Closing then return false,"Closing"end
	if not self:ValidUser(userId)then return false,"InvalidUserId"end
	local valid,reason=Schema.Snapshot(snapshot);if not valid then return false,reason end
	local entry=self:Entry(userId);local old=entry.PendingAwards[valid.RunId]
	if old and old.RunStartedUnixMs~=valid.RunStartedUnixMs then return false,"InvalidRunIdentity"end
	if not old then
		local count=0;for _ in entry.PendingAwards do count+=1 end
		if count>=Catalog.Limits.Claims then return false,"PendingLimit"end
	end
	if not old or old.ClearedFloors<valid.ClearedFloors then entry.PendingAwards[valid.RunId]=valid end
	return true
end
function Profiles:AwardRun(userId,snapshot)
	local queued,reason=self:EnqueueRun(userId,snapshot);if not queued then return false,reason end
	local entry=self:Entry(userId);local valid=entry.PendingAwards[snapshot.RunId]
	return self:Exclusive(userId,function(locked)return self:AwardEntry(userId,locked,locked.PendingAwards[valid.RunId]or valid)end)
end
function Profiles:PendingUsers()
	local users={}
	for userId,entry in self.Entries do if entry.PendingPurchase or next(entry.PendingAwards)then table.insert(users,userId)end end
	table.sort(users);return users
end
function Profiles:PurchaseEntry(userId,entry,operation)
	local ok,reason=self:Update(userId,entry,function(profile)
		local id,rank=operation.Id,operation.ExpectedRank
		local existing=profile.Purchases[id][rank+1]
		if existing and existing.OperationId==operation.OperationId then return nil,"AlreadySaved"end
		if profile.ResearchRanks[id]~=rank then return nil,"StaleRank"end
		local cost=Catalog.Definitions[id].Costs[rank+1]
		if not cost then return nil,"MaxRank"end
		if profile.ResearchData<cost then return nil,"InsufficientResearch"end
		profile.ResearchData-=cost;profile.ResearchRanks[id]=rank+1
		profile.Purchases[id][rank+1]={OperationId=operation.OperationId,Cost=cost,Legacy=false};profile.Revision=math.min(9007199254740991,profile.Revision+1)
		return profile,"Saved"
	end)
	if not ok then return false,"PurchasePending"end
	local receipt=entry.Profile.Purchases[operation.Id][operation.ExpectedRank+1]
	if receipt and receipt.OperationId==operation.OperationId then entry.PendingPurchase=nil;return true,reason end
	entry.PendingPurchase=nil
	return false,reason
end
function Profiles:Purchase(userId,id,expectedRank)
	if self.Closing then return false,"Closing"end
	if type(id)~="string"or not Catalog.Definitions[id]or not integer(expectedRank)or expectedRank<0 then return false,"InvalidPurchase"end
	return self:Exclusive(userId,function(entry)
		if not entry.Loaded or entry.Status~="Ready"then return false,"ProfileNotReady"end
		if entry.PendingPurchase then return false,"PurchasePending"end
		if entry.Profile.ResearchRanks[id]~=expectedRank then return false,"StaleRank"end
		local cost=Catalog.Definitions[id].Costs[expectedRank+1]
		if not cost then return false,"MaxRank"end
		if entry.Profile.ResearchData<cost then return false,"InsufficientResearch"end
		local operation={Id=id,ExpectedRank=expectedRank,OperationId=HttpService:GenerateGUID(false)}
		entry.PendingPurchase=operation
		return self:PurchaseEntry(userId,entry,operation)
	end)
end
function Profiles:Retry(userId)
	return self:Exclusive(userId,function(entry)
		if not entry.Loaded or entry.Status~="Ready"then local ok,reason=self:LoadEntry(userId,entry);if not ok then return false,reason end end
		if entry.PendingPurchase then local ok,reason=self:PurchaseEntry(userId,entry,entry.PendingPurchase);if not ok and entry.PendingPurchase then return false,reason end end
		local pending={};for _,snapshot in entry.PendingAwards do table.insert(pending,snapshot)end
		table.sort(pending,function(a,b)return a.RunStartedUnixMs<b.RunStartedUnixMs end)
		for _,snapshot in pending do local ok,reason=self:AwardEntry(userId,entry,snapshot);if not ok then return false,reason end end
		return true
	end)
end
function Profiles:Close(timeout)
	self.Closing=true;self.Deadline=os.clock()+math.clamp(timeout or 20,0,25)
	if not self.Store then
		for _,entry in self.Entries do if entry.Busy or entry.PendingPurchase or next(entry.PendingAwards)then return false end end
		return true
	end
	for userId,entry in self.Entries do
		if entry.Busy or entry.PendingPurchase or next(entry.PendingAwards)then task.spawn(function()self:Retry(userId)end)end
	end
	repeat
		local pending=false
		for _,entry in self.Entries do if entry.Busy or entry.PendingPurchase or next(entry.PendingAwards)then pending=true;break end end
		if not pending then return true end
		local remaining=self.Deadline-os.clock();if remaining<=0 then return false end
		task.wait(math.min(.05,remaining))
	until false
end
return Profiles
