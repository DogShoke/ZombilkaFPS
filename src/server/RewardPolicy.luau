-- Pure seeded policy; no Instances, remotes, inventory grants or global RNG.
local Config=require(game.ReplicatedStorage.Shared.ProgressionConfig)
local Policy={}
function Policy.Seed(seed,floor,epoch,stream,index)
	return (seed+floor*7919+epoch*104729+stream*15485863+(index or 0)*1009)%2147483647
end
function Policy.RarityWeights(floor,pity)
	local weights
	for _,band in Config.RarityBands do if floor>=band.FromFloor then weights=table.clone(band.Weights)end end
	weights=weights or table.clone(Config.RarityBands[1].Weights)
	local drought=pity and pity.EpicDrought or 0
	if floor>=Config.Pity.EpicFromFloor and drought>=Config.Pity.EpicDrought then
		local bonus=math.min(Config.Pity.EpicBonusCap,(drought-Config.Pity.EpicDrought+1)*Config.Pity.EpicStep,weights[1])
		weights[1]-=bonus;weights[3]+=bonus
	end
	return weights
end
function Policy.RollRarity(rng,floor,pity,eligible,minimum)
	local weights=Policy.RarityWeights(floor,pity)
	local total=0
	for i,id in Config.RarityOrder do
		if (eligible and not table.find(eligible,id))or i<(minimum or 1)then weights[i]=0 end
		total+=weights[i]
	end
	if total<=0 then return nil end
	local value=rng:NextNumber()*total
	for i,weight in weights do value-=weight;if weight>0 and value<0 then return Config.RarityOrder[i]end end
	return nil
end
function Policy.BetterRarity(a,b)
	return Config.Rarities[a or "Common"].Rank>=Config.Rarities[b or "Common"].Rank and (a or "Common")or (b or "Common")
end
function Policy.PatronWeights(active,primary,encountered)
	local weights={};local primarySet={};for _,id in primary do primarySet[id]=true end
	local known,outside=0,0
	for _,id in active do if primarySet[id]then known+=1 else outside+=1 end end
	for _,id in active do
		if #primary<Config.Patrons.PrimaryCap or known==0 or outside==0 then
			weights[id]=encountered[id]and Config.Patrons.KnownWeight or Config.Patrons.NewWeight
		else weights[id]=primarySet[id]and Config.Patrons.PrimaryMass/known or Config.Patrons.OtherMass/outside end
	end
	return weights
end
function Policy.PickPatrons(rng,active,primary,encountered,count)
	local pool=table.clone(active);local weights=Policy.PatronWeights(active,primary,encountered);local result={}
	for _=1,math.min(count,#pool)do
		local total=0;for _,id in pool do total+=weights[id]end
		local value=rng:NextNumber()*total;local selected=#pool
		for i,id in pool do value-=weights[id];if value<0 then selected=i;break end end
		table.insert(result,table.remove(pool,selected))
	end
	return result
end
function Policy.CommitPity(pity,hadRare,hadEpic,normalCards)
	-- One accepted patron encounter, regardless of how many revisions it had.
	if normalCards==0 then return end
	pity.CommonDrought=hadRare and 0 or pity.CommonDrought+1
	pity.EpicDrought=hadEpic and 0 or pity.EpicDrought+1
end
return Policy
