-- Temporary server Script: deterministic policy + isolated synchronous transactions.
-- No live player/world changes. Shared stat hooks are restored before reporting.
local Server=game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Policy=require(Server.RewardPolicy)
local Rewards=require(Server.RewardService)
local RunSession=require(Server.RunSession)
local Catalog=require(Shared.BoonCatalog)
local Config=require(Shared.ProgressionConfig)
local Merchant=require(Shared.ShopCatalog).Merchant
local merchantChance=Merchant.Chance
local WeaponsConfig=require(Shared.Weapons)
local Effects=require(Server.BoonEffects)
local Weapons=require(Server.WeaponService)
local HttpService=game:GetService("HttpService")
local report={Cases={},Failed={},Assertions=0,Bands={},PatronSamples={},ScalarCombinations=0}
local holders={}
local savedHooks={Health=Effects.RefreshHealth,Stats=Weapons.RefreshStats,Refill=Weapons.Refill}
Merchant.Chance=0 -- Isolated patron menus; production category selection tested separately.
local function check(condition,message)report.Assertions+=1;assert(condition,message)end
local function near(value,expected,tolerance,message)
	check(math.abs(value-expected)<=tolerance,message..string.format(" (got %.5f, expected %.5f)",value,expected))
end
local function case(name,run)
	local ok,err=pcall(run);table.insert(report.Cases,{Name=name,Passed=ok})
	if not ok then table.insert(report.Failed,{Name=name,Error=tostring(err)})end
end
local function fixture()
	local run=RunSession.new();run:Begin(0)
	local state=Instance.new("Folder");table.insert(holders,state)
	local health={Health=90,MaxHealth=100};local player={Weapon="Glock",Character={}}
	function player:GetAttribute(key)if key=="SelectedWeapon"then return self.Weapon end end
	function player.Character:FindFirstChildOfClass(kind)if kind=="Humanoid"then return health end end
	return run,Rewards.new(run,state),player,health
end
local function open(reward,run,player,patron,floor)
	floor=floor or 1
	for _,route in reward:RoutesFor(123456,floor)do
		if route.Patron==patron then
			check(reward:Select(route.Id,run.Epoch,floor)==route,"Requested route selects")
			check(reward:Open(player),"Requested offer opens");return reward.Offer
		end
	end
	error("Active patron absent")
end
local function claim(reward,run,player,offer,id,revision)
	return reward:Claim(player,run.Epoch,offer.Token,id or offer.Cards[1].Id,revision or offer.Revision)
end
local function cardsFor(reward,route,rarity)
	local cards={}
	for _,id in Catalog.Order do
		local def=Catalog[id];local owned=reward.Run.Boons[id]
		if def.Patron==route.Patron and(not owned or owned.Level<def.MaxLevel)then
			local level=owned and owned.Level+1 or 1;local info=Config.Rarities[rarity]
			table.insert(cards,{Id=id,NameRu=def.NameRu,Level=level,Rarity=rarity,
				DescriptionRu=def.Describe(Catalog.Values(id,level,rarity)),RarityRu=info.NameRu,
				RarityColor=info.Color,Color=Color3.fromRGB(100,150,200)})
		end
	end
	return cards
end

local harnessOk,harnessError=pcall(function()
	Effects.RefreshHealth=function()end;Weapons.RefreshStats=function()end;Weapons.Refill=function()end

	case("All four rarity bands match seeded frequency targets",function()
		local samples=20000
		for _,band in Config.RarityBands do
			local floor=band.FromFloor;local rng=Random.new(Policy.Seed(12345,floor,1,9))
			local counts={Common=0,Rare=0,Epic=0,Heroic=0}
			local weights=Policy.RarityWeights(floor,{EpicDrought=0})
			for i,value in weights do check(value==band.Weights[i],"No-pity weights match authored floor band")end
			for _=1,samples do
				local rarity=Policy.RollRarity(rng,floor,{EpicDrought=0},Config.RarityOrder)
				check(counts[rarity]~=nil,"Normal roll cannot generate special/unknown rarity")
				counts[rarity]+=1
			end
			for i,id in Config.RarityOrder do near(counts[id]/samples,band.Weights[i]/100,.015,"Rarity frequency "..id.." at floor "..floor)end
			if floor<3 then check(counts.Heroic==0,"Heroic is impossible in opening floor band")end
			table.insert(report.Bands,{Floor=floor,Samples=samples,Counts=counts,Tolerance=.015})
		end
		local rng=Random.new(3)
		for _=1,2000 do check(Policy.RollRarity(rng,2,nil,Config.RarityOrder)~="Heroic","Floor two also excludes Heroic")end
	end)

	case("Seed streams reproduce rolls and respect eligibility/minimum rarity",function()
		local seed=Policy.Seed(555,8,3,4,1);local a,b=Random.new(seed),Random.new(seed)
		check(seed==Policy.Seed(555,8,3,4,1),"Same inputs reproduce policy seed")
		check(seed~=Policy.Seed(555,8,3,5,1)and seed~=Policy.Seed(555,8,3,4,2),"Separate streams and revisions receive different seeds")
		for _=1,5000 do check(Policy.RollRarity(a,8,nil,Config.RarityOrder)==Policy.RollRarity(b,8,nil,Config.RarityOrder),"Seeded rarity sequence reproduces")end
		local rng=Random.new(11)
		for _=1,2000 do
			local rarity=Policy.RollRarity(rng,9,nil,{"Rare","Epic"},2)
			check(rarity=="Rare"or rarity=="Epic","Eligibility and Rare minimum are respected")
		end
		check(Policy.RollRarity(rng,1,nil,{"Heroic"})==nil,"Zero-weight eligible pool returns no normal result")
		check(Policy.RollRarity(rng,9,nil,{"Common"},2)==nil,"Unsatisfiable minimum returns no result")
		for _,left in Config.RarityOrder do for _,right in Config.RarityOrder do
			check(Config.Rarities[Policy.BetterRarity(left,right)].Rank==math.max(Config.Rarities[left].Rank,Config.Rarities[right].Rank),"Rarity merge never downgrades")
		end end
	end)

	case("Synthetic eight-patron pool preserves primary mass and outside support",function()
		local active={"A","B","C","D","E","F","G","H"}
		local primary={"A","B","C","D"};local known={A=true,B=true,C=true,D=true}
		local weights=Policy.PatronWeights(active,primary,known)
		for i,id in active do near(weights[id],i<=4 and .75/4 or .25/4,.000001,"Patron group mass is divided among available IDs")end
		local rng=Random.new(81001);local samples=30000;local primaryFirst=0;local firstCounts={}
		for _,id in active do firstCounts[id]=0 end
		for _=1,samples do
			local picks=Policy.PickPatrons(rng,active,primary,known,3)
			check(#picks==3 and picks[1]~=picks[2]and picks[1]~=picks[3]and picks[2]~=picks[3],"Weighted menu has three distinct IDs")
			firstCounts[picks[1]]+=1;if known[picks[1]]then primaryFirst+=1 end
		end
		near(primaryFirst/samples,.75,.015,"First-draw primary group probability")
		for _,id in active do check(firstCounts[id]>0,"Every primary and outside patron retains support")end
		table.insert(report.PatronSamples,{Mode="PrimaryFour",Samples=samples,FirstCounts=firstCounts,PrimaryFraction=primaryFirst/samples})
		local only=Policy.PickPatrons(Random.new(1),{"A","B","C"},primary,known,3)
		check(#only==3 and only[1]~=only[2]and only[2]~=only[3]and only[1]~=only[3],"No-outside pool remains usable")
		local unavailable=Policy.PickPatrons(Random.new(2),{"E","F","G"},primary,known,3)
		check(#unavailable==3,"No-available-primary pool safely renormalizes")
	end)

	case("Before four patrons, unseen IDs receive twice the individual weight",function()
		local active={"A","B","C","D","E","F","G","H"}
		local primary={"A","B"};local seen={A=true,B=true}
		local weights=Policy.PatronWeights(active,primary,seen)
		for i,id in active do check(weights[id]==(i<=2 and 1 or 2),"Pre-primary weights distinguish seen and unseen")end
		local rng=Random.new(90015);local fresh=0;local samples=20000
		for _=1,samples do local picked=Policy.PickPatrons(rng,active,primary,seen,3);if not seen[picked[1]]then fresh+=1 end end
		near(fresh/samples,12/14,.015,"First-draw unseen probability before primary cap")
		table.insert(report.PatronSamples,{Mode="BeforeFour",Samples=samples,NewFraction=fresh/samples})
		local a,b=Random.new(77),Random.new(77)
		for _=1,1000 do
			local x,y=Policy.PickPatrons(a,active,primary,seen,3),Policy.PickPatrons(b,active,primary,seen,3)
			check(table.concat(x,",")==table.concat(y,","),"Seeded route sequence reproduces")
		end
	end)

	case("Pity floors, guarantees, caps and supplies-only exclusion",function()
		local pity={CommonDrought=0,EpicDrought=0}
		Policy.CommitPity(pity,false,false,3);Policy.CommitPity(pity,false,false,9)
		check(pity.CommonDrought==2 and pity.EpicDrought==2,"Each accepted menu advances drought once regardless of revision card count")
		Policy.CommitPity(pity,true,false,3)
		check(pity.CommonDrought==0 and pity.EpicDrought==3,"Rare encounter resets only Common drought")
		Policy.CommitPity(pity,true,true,3)
		check(pity.CommonDrought==0 and pity.EpicDrought==0,"Epic encounter resets both droughts")
		pity={CommonDrought=7,EpicDrought=8};Policy.CommitPity(pity,false,false,0)
		check(pity.CommonDrought==7 and pity.EpicDrought==8,"All-supplies menu cannot modify rarity pity")
		local base=Policy.RarityWeights(7,{EpicDrought=99});local floor7=Config.RarityBands[3].Weights
		for i,w in base do check(w==floor7[i],"Epic boost cannot begin before floor eight")end
		local small=Policy.RarityWeights(8,{EpicDrought=3});local capped=Policy.RarityWeights(8,{EpicDrought=1000})
		check(small[3]==floor7[3]+Config.Pity.EpicStep,"First Epic drought boost uses one configured step")
		check(capped[3]==floor7[3]+Config.Pity.EpicBonusCap and capped[1]>=0,"Epic drought boost is capped and nonnegative")
		local total=0;for _,w in capped do total+=w end;check(total==100,"Pity redistributes rather than creates probability mass")
		local run,reward=fixture();run.Pity.CommonDrought=2
		for seed=1,100 do
			local cards=reward:BuildCards({Patron="Volta",Epoch=run.Epoch,Floor=4,Seed=seed},0,nil,"Glock")
			local rare=false;for _,card in cards do rare=rare or card.Rarity~=nil and Config.Rarities[card.Rarity].Rank>=2 end
			check(rare,"Floor-four overdue Common drought guarantees a Rare+ card")
		end
	end)

	case("Reroll rejects invalid transactions, failed generation and dead/foreign players",function()
		local run,reward,player,h=fixture();local offer=open(reward,run,player,"Volta")
		run.Rerolls=3;local token,revision=offer.Token,offer.Revision;local cards=offer.Cards
		check(not reward:Reroll({},run.Epoch,token,revision),"Foreign player cannot reroll another player's menu")
		check(not reward:Reroll(player,run.Epoch-1,token,revision),"Stale epoch rejected")
		check(not reward:Reroll(player,run.Epoch,"bad",revision),"Wrong token rejected")
		check(not reward:Reroll(player,run.Epoch,token,revision-1),"Wrong revision rejected")
		check(not reward:Reroll(player,run.Epoch,token,nil),"Missing revision rejected")
		h.Health=0;check(not reward:Reroll(player,run.Epoch,token,revision),"Dead player cannot reroll")
		h.Health=90;local character=player.Character;player.Character=nil
		check(not reward:Reroll(player,run.Epoch,token,revision),"Missing character cannot reroll");player.Character=character
		run.Rerolls=0;check(not reward:Reroll(player,run.Epoch,token,revision),"Zero balance cannot reroll")
		run.Rerolls=3;local original=reward.BuildCards
		reward.BuildCards=function()error("Expected test generation failure")end;offer.LastReroll=-math.huge
		check(not reward:Reroll(player,run.Epoch,token,revision),"Generator exception rejects reroll safely")
		reward.BuildCards=function()return {cards[1],cards[1],cards[1]}end;offer.LastReroll=-math.huge
		check(not reward:Reroll(player,run.Epoch,token,revision),"Duplicate-card generation rejects reroll")
		reward.BuildCards=function()return {}end;offer.LastReroll=-math.huge
		check(not reward:Reroll(player,run.Epoch,token,revision),"Empty generation rejects reroll")
		reward.BuildCards=original
		check(run.Rerolls==3 and offer.Used==0 and offer.Revision==revision and offer.Cards==cards and offer.Active,"All rejected rerolls leave balance, offer and revision intact")
		check(not claim(reward,run,{},offer)and not claim(reward,run,player,offer,nil,revision-1),"Foreign/stale claim cannot consume valid menu")
	end)

	case("Reroll commits one charge and revision, rejects replays and honors two-use cap",function()
		local run,reward,player=fixture();local offer=open(reward,run,player,"Bravo")
		check(run.Rerolls==0 and Config.Rerolls.CarryCap==3,"Starter balance and carry cap match approved baseline")
		run.Rerolls=Config.Rerolls.CarryCap;local token,revision=offer.Token,offer.Revision;local oldId=offer.Cards[1].Id
		check(reward:Reroll(player,run.Epoch,token,revision),"First funded reroll accepted")
		check(offer.Token==token and offer.Revision>revision and offer.Used==1 and run.Rerolls==2,"Successful reroll preserves session token and spends one charge")
		check(not reward:Reroll(player,run.Epoch,token,revision),"Duplicate expected-revision request rejected")
		check(not reward:Claim(player,run.Epoch,token,oldId,revision),"Pre-reroll click cannot claim replacement cards")
		check(not reward:Reroll(player,run.Epoch,token,offer.Revision),"Immediate second reroll is rate limited")
		offer.LastReroll=-math.huge;local nextRevision=offer.Revision
		check(reward:Reroll(player,run.Epoch,token,nextRevision),"Second reroll accepted after cooldown")
		check(offer.Used==2 and run.Rerolls==1 and offer.Revision>nextRevision,"Second reroll commits exactly once")
		offer.LastReroll=-math.huge
		check(not reward:Reroll(player,run.Epoch,token,offer.Revision)and run.Rerolls==1,"Per-offer limit rejects third reroll without spending")
		check(claim(reward,run,player,offer),"Current rerolled menu can still be claimed")
		check(not reward:Reroll(player,run.Epoch,token,offer.Revision),"Claimed menu cannot be rerolled")
	end)

	case("Pity observes all revisions but commits only once on accepted menu",function()
		local run,reward,player=fixture();local rolled="Common"
		reward.BuildCards=function(self,route)return cardsFor(self,route,rolled)end
		local offer=open(reward,run,player,"Volta");run.Rerolls=3
		for _=1,2 do offer.LastReroll=-math.huge;check(reward:Reroll(player,run.Epoch,offer.Token,offer.Revision),"Common test revision accepted")end
		check(run.Pity.CommonDrought==0 and run.Pity.EpicDrought==0,"Opening and rerolling do not farm drought counters")
		check(claim(reward,run,player,offer),"Common-only menu accepted")
		check(run.Pity.CommonDrought==1 and run.Pity.EpicDrought==1,"Three Common revisions count as one drought encounter")
		check(not claim(reward,run,player,offer)and run.Pity.CommonDrought==1,"Duplicate acceptance cannot farm drought")
		rolled="Rare";offer=open(reward,run,player,"Bravo",2);run.Rerolls=1;rolled="Common"
		check(reward:Reroll(player,run.Epoch,offer.Token,offer.Revision),"Rare menu can reroll to Common")
		check(offer.HadRare and not offer.HadEpic,"Earlier Rare exposure is retained in aggregate")
		check(claim(reward,run,player,offer)and run.Pity.CommonDrought==0 and run.Pity.EpicDrought==2,"Acceptance uses aggregate rarity exposure, not only final cards")
		rolled="Epic";offer=open(reward,run,player,"Weiss",3);run.Rerolls=1;rolled="Common"
		check(reward:Reroll(player,run.Epoch,offer.Token,offer.Revision),"Epic menu can reroll to Common")
		check(claim(reward,run,player,offer)and run.Pity.EpicDrought==0,"Initial Epic exposure resets Epic drought even after reroll")
	end)

	case("Exhausted supply menus never spend rerolls or change pity",function()
		local run,reward,player=fixture()
		for _,id in Catalog.Order do if Catalog[id].Patron=="Weiss"then run.Boons[id]={Id=id,Patron="Weiss",Level=3,Rarity="Heroic"}end end
		run.Pity={CommonDrought=5,EpicDrought=6};run.Rerolls=3
		local offer=open(reward,run,player,"Weiss",9)
		check(offer.NormalCount==0 and #offer.Cards==3 and not reward.Folder:GetAttribute("CanReroll"),"Exhausted pool publishes three supplies with reroll disabled")
		check(not reward:Reroll(player,run.Epoch,offer.Token,offer.Revision)and run.Rerolls==3,"Supply-only offer cannot burn charges")
		check(claim(reward,run,player,offer,"supply_heal"),"Fallback remains claimable")
		check(run.Pity.CommonDrought==5 and run.Pity.EpicDrought==6,"Supplies do not create or reset rarity drought")
	end)

	case("Owned rarity is preserved and maxed talents leave the pool",function()
		local run,reward,player=fixture();local id="volta_arc_discharge"
		run.Boons[id]={Id=id,Patron="Volta",Level=1,Rarity="Heroic"}
		local offer=open(reward,run,player,"Volta",1);local found
		for _,card in offer.Cards do if card.Id==id then found=card end end
		check(found and found.Level==2 and found.Rarity=="Heroic","Early Common/Rare/Epic roll cannot downgrade owned Heroic")
		check(claim(reward,run,player,offer,id)and run.Boons[id].Rarity=="Heroic","Accepted level upgrade preserves rarity")
		offer=open(reward,run,player,"Volta",2)
		check(claim(reward,run,player,offer,id)and run.Boons[id].Level==3,"Third level upgrade accepted")
		offer=open(reward,run,player,"Volta",3)
		for _,card in offer.Cards do check(card.Id~=id,"Maxed Heroic boon is excluded from subsequent menu")end
		check(#offer.Cards==3,"Max exclusion cannot leave empty cards")
		check(reward.Build[id]:GetAttribute("DescriptionRu")==Catalog[id].Describe(Catalog.Values(id,3,"Heroic")),"Build summary uses owned rarity's real numeric values")
	end)

	case("All 108 boon rarity/level combinations have finite values and bounded gun formulas",function()
		for _,id in Catalog.Order do
			local def=Catalog[id]
			for _,rarity in Config.RarityOrder do for level=1,3 do
				local values=Catalog.Values(id,level,rarity);local authored=def.RarityScalars[rarity]
				for key,value in values do
					check(type(value)=="number"and value==value and math.abs(value)<math.huge and value>=0,"Rarity scalar must be finite and nonnegative")
					check(value==(type(authored[key])=="table"and authored[key][level]or authored[key]),"Rarity scalar resolves authored table")
					if key=="Cooldown"or key=="Shots"or key=="Stacks"then check(value==Catalog.Values(id,level,"Common")[key],"Rarity must not multiply fixed proc budgets")end
				end
				check(def.Describe(values):find("%d")~=nil,"Every rarity-level description exposes numeric values")
				for _,gun in {"Glock","AKM","Mossberg"}do
					check(def.Compatibility[gun],"Catalog combination supports every shipped gun")
					local base=WeaponsConfig[gun].MagazineSize
					local feed=Catalog.Values("bravo_belt_feed",level,rarity).Fraction
					local capacity=math.clamp(math.ceil(base*(1+feed)),base,math.ceil(base*Catalog.Limits.MaxMagazineMultiplier))
					check(capacity>=base and capacity<=math.ceil(base*1.5)and capacity%1==0,"Magazine formula remains integer and capped for "..gun)
				end
				report.ScalarCombinations+=1
			end end
		end
		check(report.ScalarCombinations==108,"Nine boons times four rarities times three levels covered")
		local feed=Catalog.Values("bravo_belt_feed",3,"Heroic").Fraction
		check(math.ceil(WeaponsConfig.Glock.MagazineSize*(1+feed))==18 and math.ceil(WeaponsConfig.AKM.MagazineSize*(1+feed))==45 and math.ceil(WeaponsConfig.Mossberg.MagazineSize*(1+feed))==9,"Heroic maximum magazines match authored gun sizes")
		check(Catalog.Values("volta_static_shock",3,"Heroic").Duration<=.75,"Highest stun stays within ZombieService hard cap")
		check(Catalog.Limits.BaseHealth+Catalog.Values("weiss_field_protocol",3,"Heroic").MaxHealth<=Catalog.Limits.BaseHealth+Catalog.Limits.MaxHealthBonus,"Highest protocol fits health cap")
	end)
end)

Effects.RefreshHealth=savedHooks.Health;Weapons.RefreshStats=savedHooks.Stats;Weapons.Refill=savedHooks.Refill
Merchant.Chance=merchantChance
for _,holder in holders do holder:Destroy()end
if not harnessOk then table.insert(report.Failed,{Name="Harness",Error=tostring(harnessError)})end
script:SetAttribute("Success",#report.Failed==0)
script:SetAttribute("Error",#report.Failed==0 and ""or HttpService:JSONEncode(report.Failed))
script:SetAttribute("Report",HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
