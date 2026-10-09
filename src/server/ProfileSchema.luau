-- Strict, bounded plain-data schema. Unknown/corrupt/future data is never defaulted.
local Catalog=require(game.ReplicatedStorage.Shared.ResearchCatalog)
local Schema={Version=1}
local function integer(value,max)
	return type(value)=="number"and value==value and value>=0 and value<=max and value%1==0
end
local function identifier(value)return type(value)=="string"and #value>0 and #value<=80 and not value:find("[^%w_%-]")end
local function only(t,allowed)
	if type(t)~="table"then return false end
	for key in t do if not allowed[key]then return false end end
	return true
end
function Schema.Copy(value)
	if type(value)~="table"then return value end
	local result={};for key,item in value do result[key]=Schema.Copy(item)end;return result
end
function Schema.New()
	local ranks,purchases={},{}
	for _,id in Catalog.Order do ranks[id]=0;purchases[id]={}end
	return {Version=Schema.Version,ResearchData=0,ResearchRanks=ranks,BestFloor=0,Revision=0,Claims={},Purchases=purchases,EvictedBeforeUnixMs=0}
end
local function validRanks(ranks)
	if type(ranks)~="table"then return false end
	for id in ranks do if not Catalog.Definitions[id]then return false end end
	for _,id in Catalog.Order do if not integer(ranks[id],#Catalog.Definitions[id].Costs)then return false end end
	return true
end
function Schema.Decode(raw,migrationCutoff)
	if raw==nil then return Schema.New()end
	if type(raw)~="table"or not integer(raw.Version,1000000)then return nil,"Corrupt"end
	if raw.Version>Schema.Version then return nil,"NewerSchema"end
	if raw.Version==0 then
		if not only(raw,{Version=true,ResearchData=true,ResearchRanks=true,BestFloor=true})
			or not integer(raw.ResearchData,Catalog.Limits.ResearchData)or not integer(raw.BestFloor,Catalog.Limits.Floor)or not validRanks(raw.ResearchRanks)
			or not integer(migrationCutoff,9007199254740991)then return nil,"Corrupt"end
		local migrated=Schema.New();migrated.ResearchData=raw.ResearchData;migrated.ResearchRanks=Schema.Copy(raw.ResearchRanks);migrated.BestFloor=raw.BestFloor
		-- v0 has no payment history: reject older events rather than paying them twice.
		migrated.EvictedBeforeUnixMs=migrationCutoff
		for _,id in Catalog.Order do for rank=1,migrated.ResearchRanks[id]do
			migrated.Purchases[id][rank]={OperationId="legacy_"..id.."_"..rank,Cost=0,Legacy=true}
		end end
		return migrated
	end
	if not only(raw,{Version=true,ResearchData=true,ResearchRanks=true,BestFloor=true,Revision=true,Claims=true,Purchases=true,EvictedBeforeUnixMs=true})
		or not integer(raw.ResearchData,Catalog.Limits.ResearchData)or not integer(raw.BestFloor,Catalog.Limits.Floor)
		or not integer(raw.Revision,9007199254740991)or not integer(raw.EvictedBeforeUnixMs,9007199254740991)or not validRanks(raw.ResearchRanks)
		or type(raw.Claims)~="table"or type(raw.Purchases)~="table"then return nil,"Corrupt"end
	local count=0
	for runId,claim in raw.Claims do
		count+=1
		if count>Catalog.Limits.Claims or not identifier(runId)or not only(claim,{RunId=true,RunStartedUnixMs=true,PaidFloors=true,ResearchEarnedTotal=true,
			ResearchEarned=true,NewRecord=true,RecordBonusPaid=true})or claim.RunId~=runId
			or not integer(claim.RunStartedUnixMs,9007199254740991)or claim.RunStartedUnixMs<1
			or not integer(claim.PaidFloors,Catalog.Limits.Floor)or not integer(claim.ResearchEarnedTotal,Catalog.Limits.Floor*Catalog.Rewards.PerFloor+Catalog.Rewards.RecordBonus)
			or claim.ResearchEarned~=claim.ResearchEarnedTotal or type(claim.NewRecord)~="boolean"or type(claim.RecordBonusPaid)~="boolean"then return nil,"Corrupt"end
	end
	for id in raw.Purchases do if not Catalog.Definitions[id]then return nil,"Corrupt"end end
	for _,id in Catalog.Order do
		local receipts=raw.Purchases[id];local rank=raw.ResearchRanks[id]
		if type(receipts)~="table"then return nil,"Corrupt"end
		local entries=0
		for key,receipt in receipts do
			entries+=1
			if not integer(key,rank)or key<1 or not only(receipt,{OperationId=true,Cost=true,Legacy=true})or not identifier(receipt.OperationId)
				or not integer(receipt.Cost,Catalog.Limits.ResearchData)or type(receipt.Legacy)~="boolean"
				or receipt.Cost~=(receipt.Legacy and 0 or Catalog.Definitions[id].Costs[key])then return nil,"Corrupt"end
		end
		if entries~=rank then return nil,"Corrupt"end
	end
	return Schema.Copy(raw)
end
function Schema.Snapshot(snapshot)
	if type(snapshot)~="table"or not identifier(snapshot.RunId)or not integer(snapshot.RunStartedUnixMs,9007199254740991)or snapshot.RunStartedUnixMs<1
		or not integer(snapshot.ClearedFloors,Catalog.Limits.Floor)or not integer(snapshot.HighestFloor,Catalog.Limits.Floor)
		or snapshot.HighestFloor<1 or snapshot.ClearedFloors>snapshot.HighestFloor then return nil,"InvalidSnapshot"end
	return {RunId=snapshot.RunId,RunStartedUnixMs=snapshot.RunStartedUnixMs,ClearedFloors=snapshot.ClearedFloors,HighestFloor=snapshot.HighestFloor}
end
return Schema
