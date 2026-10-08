-- Temporary Studio server Script. Independent ledgers/unparented folders only.
-- The synchronous test body never yields; shared effect hooks are always restored.
local Server=game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rewards=require(Server.RewardService)
local RunSession=require(Server.RunSession)
local Catalog=require(Shared.BoonCatalog)
local Patrons=require(Shared.Patrons)
local Merchant=require(Shared.ShopCatalog).Merchant
local merchantChance=Merchant.Chance
local Effects=require(Server.BoonEffects)
local Weapons=require(Server.WeaponService)
local HttpService=game:GetService("HttpService")
local report={Cases={},Failed={},Assertions=0,RouteSamples=0}
local holders={}
local hooks={RefreshHealth=Effects.RefreshHealth,RefreshStats=Weapons.RefreshStats,Refill=Weapons.Refill}
local calls={Health=0,Stats=0,Refill=0}
Merchant.Chance=0 -- Patron-only regression suite; merchant routes have their own QA.

local function check(condition,message)
	report.Assertions+=1;assert(condition,message)
end
local function case(name,run)
	local ok,err=pcall(run)
	table.insert(report.Cases,{Name=name,Passed=ok})
	if not ok then table.insert(report.Failed,{Name=name,Error=tostring(err)})end
end
local function fixture()
	local run=RunSession.new();run:Begin(0)
	local state=Instance.new("Folder");table.insert(holders,state)
	local h={Health=90,MaxHealth=100}
	local player={Weapon="Glock",Character={}}
	function player:GetAttribute(key)if key=="SelectedWeapon"then return self.Weapon end end
	function player.Character:FindFirstChildOfClass(kind)if kind=="Humanoid"then return h end end
	local reward=Rewards.new(run,state);reward.TestPlayer=player
	return run,reward,player,h
end
local function claim(reward,player,epoch,token,id,revision)
	return reward:Claim(player,epoch,token,id,revision or reward.Offer and reward.Offer.Revision)
end
local function open(reward,run,patron,floor)
	floor=floor or 1
	local routes=reward:RoutesFor(123456,floor)
	for _,route in routes do
		if route.Patron==patron then
			check(reward:Select(route.Id,run.Epoch,floor)==route,"Advertised patron route must select")
			check(reward:Open(reward.TestPlayer),"Selected patron offer must open");return reward.Offer
		end
	end
	error("Missing active patron route: "..patron)
end
local function boonCount(run)
	local count=0;for _ in run.Boons do count+=1 end;return count
end

local ok,err=pcall(function()
	Effects.RefreshHealth=function()calls.Health+=1 end
	Weapons.RefreshStats=function()calls.Stats+=1 end
	Weapons.Refill=function()calls.Refill+=1 end

	case("Nine catalog entries have compatible finite scalars and numeric descriptions",function()
		check(#Catalog.Order==9,"Current enabled catalog must contain nine boons")
		local seen={};local perPatron={}
		for _,id in Catalog.Order do
			local def=Catalog[id]
			check(def and def.Id==id and not seen[id],"Catalog IDs must be unique and resolve")
			seen[id]=true;perPatron[def.Patron]=(perPatron[def.Patron]or 0)+1
			check(table.find(Patrons.Active,def.Patron)~=nil,"Enabled boon must belong to an active patron")
			check(def.MaxLevel==3 and def.RarityEligible[1]=="Common","First slice uses Common levels one to three")
			check(def.Compatibility.Glock and def.Compatibility.AKM and def.Compatibility.Mossberg,"Each core boon supports all three existing guns")
			for level=1,3 do
				local values=Catalog.Values(id,level)
				check(next(values)~=nil,"Boon level must provide numeric values")
				for key,value in values do
					check(type(value)=="number"and value==value and math.abs(value)<math.huge and value>=0,"Finite nonnegative scalar: "..id.."/"..key)
					local source=def.Scalars[key]
					check(value==(type(source)=="table"and source[level]or source),"Resolved level must match authored scalar")
				end
				local description=def.Describe(values)
				check(type(description)=="string"and #description>0 and description:find("%d")~=nil,"Description must expose numeric gameplay values")
			end
		end
		for _,id in Patrons.Active do check(perPatron[id]==3,"Each enabled patron must have three implemented boons")end
	end)

	case("Seeded routes contain three distinct active patrons and fresh opaque IDs",function()
		local run,reward=fixture()
		for floor=1,100 do
			local first=reward:RoutesFor(987654,floor)
			local again=reward:RoutesFor(987654,floor)
			check(#first==3 and #again==3,"Each combat floor must offer three routes")
			local ids,patrons={},{ }
			for i,route in first do
				check(route.Type=="PatronBoon"and route.Epoch==run.Epoch and route.Floor==floor,"Route metadata must match run and floor")
				check(type(route.Id)=="string"and #route.Id>0 and not ids[route.Id],"Route IDs must be distinct")
				check(table.find(Patrons.Active,route.Patron)~=nil and not Patrons[route.Patron].Disabled and not patrons[route.Patron],"Routes must contain distinct enabled patrons")
				check(route.Patron==again[i].Patron,"Identical seed/floor/epoch must reproduce patron ordering")
				check(route.Id~=again[i].Id,"Regenerated route IDs must invalidate older selections")
				ids[route.Id]=true;patrons[route.Patron]=true
			end
			report.RouteSamples+=1
		end
		for _,id in {"Radke","Grid","Nord","Vector","Sigma"}do
			check(Patrons[id].Disabled==true and table.find(Patrons.Active,id)==nil,"Unimplemented patron must remain disabled")
		end
	end)

	case("Route selection rejects stale epoch, wrong floor, unknown and duplicate IDs",function()
		local run,reward=fixture()
		local routes=reward:RoutesFor(10,2);local route=routes[1]
		check(reward:Select(route.Id,run.Epoch-1,2)==nil,"Stale epoch route rejected")
		check(reward:Select(route.Id,run.Epoch,1)==nil,"Wrong floor route rejected")
		check(reward:Select("unknown",run.Epoch,2)==nil and reward.Selected==nil,"Unknown route must not consume choice")
		check(reward:Select(route.Id,run.Epoch,2)==route,"Valid route accepted")
		check(reward:Select(routes[2].Id,run.Epoch,2)==nil and reward.Selected==route,"Second route cannot replace committed choice")
		local fresh=reward:RoutesFor(10,3)
		check(reward:Select(route.Id,run.Epoch,3)==nil,"Previous-floor route ID rejected")
		check(reward:Select(fresh[1].Id,run.Epoch,3)~=nil,"Fresh route remains selectable")
	end)

	case("Open preserves advertised patron and publishes three eligible distinct cards",function()
		for _,patron in Patrons.Active do
			local run,reward=fixture();local offer=open(reward,run,patron)
			check(offer.Active and offer.Patron==patron and run.Patrons[patron],"Interlude must encounter selected patron")
			check(#offer.Cards==3 and #reward.Folder:GetChildren()==3,"Offer and replicated model must contain three cards")
			check(reward.Folder:GetAttribute("Active")==true and reward.Folder:GetAttribute("Token")==offer.Token and reward.Folder:GetAttribute("RunEpoch")==run.Epoch,"Replicated token must match authoritative offer")
			local seen={}
			for _,card in offer.Cards do
				local def=Catalog[card.Id]
				check(def and def.Patron==patron and not seen[card.Id],"Cards must be distinct and from advertised patron")
				check(card.Level==1 and card.DescriptionRu==def.Describe(Catalog.Values(card.Id,1,card.Rarity)),"Card must show actual next-level numeric description")
				seen[card.Id]=true
			end
		end
	end)

	case("Invalid claims preserve offer; valid claim grants exactly one boon",function()
		local run,reward,player=fixture();local offer=open(reward,run,"Volta")
		local id=offer.Cards[1].Id;local health,stats=calls.Health,calls.Stats
		check(not claim(reward,player,run.Epoch-1,offer.Token,id),"Stale claim epoch rejected")
		check(not claim(reward,player,run.Epoch,"wrong-token",id),"Wrong offer token rejected")
		check(not claim(reward,player,run.Epoch,offer.Token,"unknown"),"Unknown boon rejected")
		check(not claim(reward,player,run.Epoch,offer.Token,string.rep("x",81)),"Oversized ID rejected")
		player.Weapon="InvalidWeapon"
		check(not claim(reward,player,run.Epoch,offer.Token,id),"Incompatible weapon rejected")
		player.Weapon="Glock"
		check(offer.Active and boonCount(run)==0 and calls.Health==health and calls.Stats==stats,"Rejected claims must not consume or apply anything")
		check(claim(reward,player,run.Epoch,offer.Token,id),"Offered boon claim accepted")
		check(boonCount(run)==1 and run.Boons[id].Level==1 and run.Boons[id].Rarity==offer.Cards[1].Rarity,"Claim grants one level-one boon at advertised rarity")
		check(not offer.Active and reward.Folder:GetAttribute("Active")==false,"Successful claim consumes menu before effects")
		check(calls.Health==health+1 and calls.Stats==stats+1,"Valid grant refreshes health and weapon exactly once")
		check(not claim(reward,player,run.Epoch,offer.Token,id)and run.Boons[id].Level==1,"Duplicate claim cannot upgrade granted boon")
		check(not claim(reward,player,run.Epoch,offer.Token,offer.Cards[2].Id)and boonCount(run)==1,"Same offer cannot grant a different second boon")
		check(#reward.Build:GetChildren()==1 and reward.Build[id]:GetAttribute("Level")==1,"Read-only build reflects exactly one accepted grant")
	end)

	case("Replacement offers and replacement runs invalidate old claims",function()
		local run,reward,player=fixture();local old=open(reward,run,"Bravo")
		local current=open(reward,run,"Bravo",2)
		check(old.Token~=current.Token and not claim(reward,player,run.Epoch,old.Token,old.Cards[1].Id),"Old offer token cannot claim replacement menu")
		local epoch=run.Epoch;run:Finish(1,"Test");run:Begin(2)
		check(not claim(reward,player,epoch,current.Token,current.Cards[1].Id),"Old run epoch cannot claim after restart")
		check(not claim(reward,player,run.Epoch,current.Token,current.Cards[1].Id)and boonCount(run)==0,"Old offer cannot be reused with new epoch")
	end)

	case("Repeated patron encounters upgrade to three and replace maxed cards",function()
		for _,patron in Patrons.Active do
			local run,reward,player=fixture();local floor=0
			for _,id in Catalog.Order do
				if Catalog[id].Patron~=patron then continue end
				for level=1,3 do
					floor+=1;local offer=open(reward,run,patron,floor);local found
					check(#offer.Cards==3,"Partly exhausted patron pool must remain a three-card offer")
					for _,card in offer.Cards do
						if card.Id==id then found=card end
						local owned=run.Boons[card.Id]
						check(not owned or owned.Level<Catalog[card.Id].MaxLevel,"Max-level boon must be removed from offer")
					end
					check(found and found.Level==level,"Offer must advertise the next legal level")
					check(claim(reward,player,run.Epoch,offer.Token,id)and run.Boons[id].Level==level,"Repeat grant upgrades existing entry")
					check(not claim(reward,player,run.Epoch,offer.Token,id)and run.Boons[id].Level==level,"Replayed grant cannot skip levels")
				end
			end
			check(boonCount(run)==3,"Repeated upgrades must not duplicate inventory entries")
			local fallback=open(reward,run,patron,floor+1);local seen={}
			check(#fallback.Cards==3,"Fully exhausted pool must still offer three useful fallback cards")
			for _,card in fallback.Cards do
				check(not Catalog[card.Id]and not seen[card.Id]and #card.DescriptionRu>0,"Fallback cards must be distinct supplies, never empty or maxed boon")
				seen[card.Id]=true
			end
			check(seen.supply_heal and seen.supply_health and seen.supply_ammo,"Exhausted patron offers all three supported supplies")
		end
	end)

	case("Fallback supply claims clamp healing and health and consume once",function()
		local run,reward,player,h=fixture()
		for _,id in Catalog.Order do if Catalog[id].Patron=="Weiss"then run.Boons[id]={Id=id,Patron="Weiss",Level=3,Rarity="Common"}end end
		local offer=open(reward,run,"Weiss");h.Health=90
		check(claim(reward,player,run.Epoch,offer.Token,"supply_heal")and h.Health==100,"Supply heal clamps to missing HP")
		check(not claim(reward,player,run.Epoch,offer.Token,"supply_health")and run.SupplyHealth==0,"Consumed supply menu cannot grant a second item")
		offer=open(reward,run,"Weiss",2);run.SupplyHealth=Catalog.Limits.MaxHealthBonus-1;h.Health=99
		check(claim(reward,player,run.Epoch,offer.Token,"supply_health")and run.SupplyHealth==Catalog.Limits.MaxHealthBonus and h.Health==100,"Health supply respects bonus and healing caps")
		offer=open(reward,run,"Weiss",3);local before=calls.Refill
		check(claim(reward,player,run.Epoch,offer.Token,"supply_ammo")and calls.Refill==before+1,"Ammo supply invokes server refill once")
		check(not claim(reward,player,run.Epoch,offer.Token,"supply_ammo")and calls.Refill==before+1,"Ammo supply replay does not refill twice")
	end)

	case("Clear invalidates selection and offer and removes replicated build",function()
		local run,reward,player=fixture();local offer=open(reward,run,"Volta")
		reward:Clear()
		check(reward.Offer==nil and reward.Routes==nil and reward.Selected==nil,"Clear invalidates all reward transactions")
		check(not reward.Folder:GetAttribute("Active")and #reward.Folder:GetChildren()==0 and #reward.Build:GetChildren()==0,"Clear empties replicated reward/build state")
		check(not claim(reward,player,run.Epoch,offer.Token,offer.Cards[1].Id),"Cleared offer cannot be claimed")
	end)
end)

-- Restore before publishing or raising any test failure. Never leave live game stubs.
Effects.RefreshHealth=hooks.RefreshHealth
Merchant.Chance=merchantChance
Weapons.RefreshStats=hooks.RefreshStats
Weapons.Refill=hooks.Refill
for _,holder in holders do holder:Destroy()end
if not ok then table.insert(report.Failed,{Name="Harness",Error=tostring(err)})end
report.HookCalls=calls
script:SetAttribute("Success",#report.Failed==0)
script:SetAttribute("Error",#report.Failed==0 and ""or HttpService:JSONEncode(report.Failed))
script:SetAttribute("Report",HttpService:JSONEncode(report))
script:SetAttribute("Complete",true)
