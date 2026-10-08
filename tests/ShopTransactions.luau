-- Temporary native server Script. Isolated ledgers/fake players/unparented folders.
-- Test body is synchronous; shared stat hooks are always restored before reporting.
local Server=game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RunSession=require(Server.RunSession)
local Rewards=require(Server.RewardService)
local Shop=require(Server.ShopService)
local Catalog=require(Shared.BoonCatalog)
local ShopCatalog=require(Shared.ShopCatalog)
local Progression=require(Shared.ProgressionConfig)
local Effects=require(Server.BoonEffects)
local Weapons=require(Server.WeaponService)
local HttpService=game:GetService("HttpService")
local report={Cases={},Failed={},Assertions=0,PremiumSeeds={}}
local holders={}
local hooks={Health=Effects.RefreshHealth,Stats=Weapons.RefreshStats,Refill=Weapons.Refill}
local merchantTuning={Chance=ShopCatalog.Merchant.Chance,FromFloor=ShopCatalog.Merchant.FromFloor}
local calls={Health=0,Stats=0,Refill=0}
local function check(condition,message)report.Assertions+=1;assert(condition,message)end
local function case(name,run)
	local ok,err=pcall(run);table.insert(report.Cases,{Name=name,Passed=ok})
	if not ok then table.insert(report.Failed,{Name=name,Error=tostring(err)})end
end
local function fixture(funds)
	local run=RunSession.new();run:Begin(0)
	if funds and funds>0 then check(run:AddCredits(run.Epoch,funds),"Fixture receives real ledger funds")end
	local state=Instance.new("Folder");state:SetAttribute("OwnerUserId",123);table.insert(holders,state)
	local h={Health=90,MaxHealth=100};local player={UserId=123,Weapon="Glock",Character={}}
	function player:GetAttribute(key)if key=="SelectedWeapon"then return self.Weapon end end
	function player.Character:FindFirstChildOfClass(kind)if kind=="Humanoid"then return h end end
	local rewards=Rewards.new(run,state)
	return {Run=run,State=state,Player=player,Humanoid=h,Rewards=rewards,Shop=Shop.new(run,state,rewards)}
end
local function open(f,kind,floor,seed)
	check(f.Shop:Open(f.Player,kind or "Vending",floor or 2,seed or 123456),"Shop session opens")
	check(f.Shop.Offer and f.Shop.Offer.Active,"Open produces an active transaction session")
	return f.Shop.Offer
end
local function item(f,id)
	for _,row in f.Shop.Offer.Items do if row.Id==id then return row end end
end
local function rowView(f,id)
	local folder=f.State:FindFirstChild("ShopOffer")
	if not folder then return nil end
	for _,child in folder:GetChildren()do if child:GetAttribute("Id")==id then return child end end
end
local function buy(f,id,revision,epoch,token,player)
	local offer=f.Shop.Offer
	return f.Shop:Buy(player or f.Player,epoch or f.Run.Epoch,token or offer.Token,id,revision or offer.Revision)
end
local function own(f,id,level,rarity)
	local def=Catalog[id];f.Run.Boons[id]={Id=id,Patron=def.Patron,Level=level,Rarity=rarity}
end
local function premium(id,setup)
	for seed=1,60 do
		local f=fixture(1000);setup(f);open(f,"MerchantShop",5,seed)
		if item(f,id)then report.PremiumSeeds[id]=seed;return f,item(f,id)end
	end
	error("No eligible merchant "..id.." found in sixty deterministic stock seeds")
end

local harnessOk,harnessError=pcall(function()
	Effects.RefreshHealth=function()calls.Health+=1 end
	Weapons.RefreshStats=function()calls.Stats+=1 end
	Weapons.Refill=function()calls.Refill+=1 end

	case("Vending exposes three priced finite items with authoritative display state",function()
		local f=fixture(1000);local offer=open(f)
		check(offer.Kind=="Vending"and offer.Epoch==f.Run.Epoch and offer.Player==f.Player and #offer.Items==3,"Vending ownership and size match contract")
		local prices={heal=65,reroll=60,health=110}
		for id,price in prices do
			local row=item(f,id);local view=rowView(f,id)
			check(row and row.Price==price and not row.Sold,"Vending server price and unsold stock match brief")
			check(view and view:GetAttribute("Price")==price and view:GetAttribute("Sold")==false,"Replicated item price/stock matches server")
			check(type(view:GetAttribute("NameRu"))=="string"and type(view:GetAttribute("DescriptionRu"))=="string","Shop exposes localized product text")
			check(view:GetAttribute("Available")==true,"Affordable eligible product is available")
		end
	end)

	case("Current identity rejects wrong owner, epoch, token and revision",function()
		local f=fixture(1000);local offer=open(f);local balance=f.Run.Credits
		check(f.Shop:Current(f.Player,f.Run.Epoch,offer.Token,offer.Revision),"Current transaction identity accepted")
		check(not f.Shop:Buy({},f.Run.Epoch,offer.Token,"reroll",offer.Revision),"Foreign player cannot buy")
		check(not f.Shop:Buy(f.Player,f.Run.Epoch-1,offer.Token,"reroll",offer.Revision),"Stale run epoch rejected")
		check(not f.Shop:Buy(f.Player,f.Run.Epoch,"wrong-token","reroll",offer.Revision),"Wrong session token rejected")
		check(not f.Shop:Buy(f.Player,f.Run.Epoch,offer.Token,"reroll",offer.Revision-1),"Stale revision rejected")
		check(not f.Shop:Buy(f.Player,f.Run.Epoch,offer.Token,"reroll",nil),"Missing revision rejected")
		check(not buy(f,"unknown")and not buy(f,string.rep("x",100)),"Unknown and oversized product IDs rejected")
		check(f.Run.Credits==balance and f.Run.CreditsSpent==0 and f.Run.Rerolls==0 and not item(f,"reroll").Sold,"Invalid requests do not spend or change stock")
	end)

	case("Opening rejects invalid kinds, floor data and foreign owner",function()
		local f=fixture(1000)
		local other={UserId=124,Weapon="Glock",Character=f.Player.Character,GetAttribute=f.Player.GetAttribute}
		check(not f.Shop:Open(other,"Vending",2,123),"Foreign owner cannot create a shop session")
		check(not f.Shop:Open(f.Player,"CoffeeSpawner",2,123),"Hostile source is not a supported shop kind")
		check(not f.Shop:Open(f.Player,"Vending",0,123)and not f.Shop:Open(f.Player,"Vending",1.5,123),"Invalid floor metadata rejected")
		check(not f.Shop:Open(f.Player,"Vending",2,math.huge),"Nonfinite seed rejected")
		check(f.Shop.Offer==nil and next(f.Shop.Stock)==nil and f.Run.Credits==1000,"Rejected opens do not create stock or spend currency")
		open(f)
	end)

	case("Dead or missing characters cannot purchase or consume stock",function()
		local f=fixture(1000);open(f);f.Humanoid.Health=0
		check(not buy(f,"reroll"),"Dead buyer rejected")
		f.Humanoid.Health=90;local character=f.Player.Character;f.Player.Character=nil
		check(not buy(f,"reroll"),"Missing character rejected")
		f.Player.Character=character
		check(f.Run.Credits==1000 and f.Run.CreditsSpent==0 and not item(f,"reroll").Sold,"Character failures leave transaction intact")
		check(buy(f,"reroll")and f.Run.Rerolls==1,"Restored live buyer can purchase")
	end)

	case("Insufficient balance and full-health healing are rejected without charge",function()
		local f=fixture(59);open(f)
		check(not buy(f,"reroll")and f.Run.Credits==59 and f.Run.Rerolls==0,"Cannot spend sixty with fifty-nine credits")
		local view=rowView(f,"reroll")
		check(view and view:GetAttribute("Available")==false and type(view:GetAttribute("Reason"))=="string","Unavailable purchase has a displayed reason")
		check(f.Run:AddCredits(f.Run.Epoch,100),"Buyer can later earn sufficient currency")
		f.Humanoid.Health=f.Humanoid.MaxHealth
		check(not buy(f,"heal")and f.Run.Credits==159 and f.Run.CreditsSpent==0,"Full-health healing cannot burn credits")
		f.Humanoid.Health=10
		check(buy(f,"heal")and f.Humanoid.Health==45,"Healing restores thirty-five percent of maximum health")
		check(f.Run.Credits==94 and f.Run.CreditsSpent==65 and item(f,"heal").Sold,"Healing spends exactly sixty-five once")
	end)

	case("Healing clamps missing HP and duplicate/stale purchases spend once",function()
		local f=fixture(1000);local offer=open(f);local revision=offer.Revision
		f.Humanoid.Health=90
		check(buy(f,"heal",revision)and f.Humanoid.Health==100,"Heal clamps to missing HP")
		check(f.Run.Credits==935 and f.Run.CreditsSpent==65 and offer.Revision>revision,"Successful purchase advances revision and charges once")
		check(not buy(f,"heal",revision)and not buy(f,"reroll",revision),"Replay and simultaneous second product with old revision rejected")
		check(not buy(f,"heal")and f.Run.Credits==935,"Sold-out item cannot be purchased at new revision")
		check(buy(f,"reroll")and f.Run.Credits==875 and f.Run.Rerolls==1,"Fresh revision permits a different valid product")
		check(rowView(f,"heal"):GetAttribute("Sold")==true,"Replicated sold state is authoritative")
	end)

	case("Reroll carry cap and total health cap reject useless purchases",function()
		local f=fixture(1000);open(f);f.Run.Rerolls=Progression.Rerolls.CarryCap
		check(not buy(f,"reroll")and not item(f,"reroll").Sold and f.Run.Credits==1000,"Full reroll inventory rejects purchase without spending")
		f.Run.Rerolls=Progression.Rerolls.CarryCap-1
		check(buy(f,"reroll")and f.Run.Rerolls==Progression.Rerolls.CarryCap,"Reroll purchase fills only one remaining charge")
		f.Run.SupplyHealth=Catalog.Limits.MaxHealthBonus
		local balance=f.Run.Credits
		check(not buy(f,"health")and not item(f,"health").Sold and f.Run.Credits==balance,"Maximum run health cannot be purchased again")
	end)

	case("Run-only max-health supply grants once and combined bonus never exceeds cap",function()
		local f=fixture(1000);open(f)
		check(buy(f,"health")and f.Run.SupplyHealth==10 and f.Run.Credits==890,"Health purchase grants ten run-only bonus for one hundred ten credits")
		check(not buy(f,"health")and f.Run.SupplyHealth==10,"Duplicate stock cannot stack health")
		local combined=fixture(1000);own(combined,"weiss_field_protocol",3,"Heroic")
		combined.Run.SupplyHealth=Catalog.Limits.MaxHealthBonus-Catalog.Values("weiss_field_protocol",3,"Heroic").MaxHealth
		open(combined)
		check(not buy(combined,"health")and combined.Run.Credits==1000,"Existing protocol counts toward total health cap")
		local result=f.Run:Finish(1,"Death");f.Shop:Clear()
		check(f.Run.SupplyHealth==0 and f.Run.Credits==0 and result.CreditsSpent==110,"Death removes purchased health and currency while retaining expense report")
	end)

	case("Closing is free; reopening retains stock and invalidates prior session packets",function()
		local f=fixture(1000);local offer=open(f);local token,revision=offer.Token,offer.Revision
		f.Shop:Close()
		check(f.Run.Credits==1000 and f.Run.CreditsSpent==0,"Continue with no purchases is free")
		check(not f.Shop:Current(f.Player,f.Run.Epoch,token,revision)and not f.Shop:Buy(f.Player,f.Run.Epoch,token,"reroll",revision),"Closed session cannot transact")
		offer=open(f);check(offer.Token~=token,"Reopening receives a fresh session identity")
		check(buy(f,"reroll"),"Stock can be purchased in reopened session")
		local soldBalance=f.Run.Credits;f.Shop:Close();offer=open(f)
		check(item(f,"reroll").Sold and not buy(f,"reroll")and f.Run.Credits==soldBalance,"Closing and reopening cannot restock or duplicate purchases")
		f.Shop:Close();open(f,"Vending",3)
		check(not item(f,"reroll").Sold,"A genuinely distinct floor receives fresh bounded stock")
	end)

	case("Clear and run replacement invalidate every old session",function()
		local f=fixture(1000);local offer=open(f);local epoch,token,revision=f.Run.Epoch,offer.Token,offer.Revision
		f.Shop:Clear()
		check(not f.Shop:Current(f.Player,epoch,token,revision)and not f.Shop:Buy(f.Player,epoch,token,"heal",revision),"Clear invalidates active transaction")
		check(next(f.Shop.Stock)==nil and f.State.ShopOffer:GetAttribute("Active")==false,"Clear removes cached inventory and closes replicated panel")
		f.Run:Finish(1,"Death");f.Run:Begin(2);f.Run:AddCredits(f.Run.Epoch,1000);open(f)
		check(not f.Shop:Buy(f.Player,epoch,token,"heal",revision),"Prior epoch cannot buy replacement-run stock")
		check(not f.Shop:Buy(f.Player,f.Run.Epoch,token,"heal",revision),"Old token cannot be paired with replacement epoch")
		check(f.Run.Credits==1000 and f.Run.CreditsSpent==0,"Stale packets preserve new-run balances")
	end)

	case("Merchant has bounded inventory and a finite free supply even without funds",function()
		local f=fixture(0);local offer=open(f,"MerchantShop",4,100)
		check(#offer.Items>=3 and #offer.Items<=5,"Merchant assortment stays within three to five items")
		local free=item(f,"free_supply")
		check(free and free.Price==0 and not free.Sold,"Zero-money merchant has an explicit free supply")
		local view=rowView(f,"free_supply");check(view and view:GetAttribute("Available")==true,"Free supply is actually affordable")
		local refills=calls.Refill
		check(buy(f,"free_supply")and f.Humanoid.Health==100 and calls.Refill==refills+1 and f.Run.CreditsSpent==0,"Free supply heals missing HP and requests one server refill without charging")
		local balance=f.Run.Credits
		check(balance==0 and not buy(f,"free_supply")and calls.Refill==refills+1,"Free supply cannot be claimed twice or mint currency")
		f.Shop:Close();open(f,"MerchantShop",4,100)
		check(item(f,"free_supply").Sold and not buy(f,"free_supply")and f.Run.Credits==balance,"Reopening cannot farm free merchant supply")
	end)

	case("Merchant stock is seeded, compatible and stable across reopening",function()
		local function signature(offer)
			local values={}
			for _,row in offer.Items do table.insert(values,row.Id..":"..tostring(row.BoonId)..":"..tostring(row.Rarity)..":"..row.Price)end
			return table.concat(values,"|")
		end
		local first,second=fixture(1000),fixture(1000)
		local a,b=open(first,"MerchantShop",5,42),open(second,"MerchantShop",5,42)
		check(signature(a)==signature(b)and a.Token~=b.Token,"Identical stock seed/epoch reproduces items with independent transaction tokens")
		local original=signature(a);first.Shop:Close();a=open(first,"MerchantShop",5,99999)
		check(signature(a)==original,"Reopening same floor/kind with a different seed cannot reroll premium targets")
		for _,gun in {"Glock","AKM","Mossberg"}do
			local f=fixture(1000);f.Player.Weapon=gun;local offer=open(f,"MerchantShop",6,81)
			local seen={}
			for _,row in offer.Items do
				check(not seen[row.Id],"Merchant cannot list duplicate product transactions")
				seen[row.Id]=true
				if row.BoonId then check(Catalog[row.BoonId]and Catalog[row.BoonId].Compatibility[gun],"Premium is a live compatible catalog item for "..gun)end
			end
		end
	end)

	case("Merchant routes begin at configured floor and replace exactly one patron choice",function()
		ShopCatalog.Merchant.Chance=1;ShopCatalog.Merchant.FromFloor=4
		for _,floor in {1,3,4,8,12}do
			local first,second=fixture(0),fixture(0)
			local routes=first.Rewards:RoutesFor(8192,floor)
			local replay=second.Rewards:RoutesFor(8192,floor)
			check(#routes==3 and #replay==3,"Merchant replacement preserves three route choices")
			local patrons,merchant,chosen={},0,nil
			for index,route in routes do
				local same=replay[index]
				check(route.Type==same.Type and route.Patron==same.Patron and route.Seed==same.Seed,"Seed reproduces route category, patron order and reward seed")
				check(route.Id~=same.Id,"Reproduced layout has independent selection identities")
				if route.Type=="MerchantShop"then
					merchant+=1;chosen=route
					check(route.Patron==nil,"Merchant category never carries a patron affiliation")
				else
					check(route.Type=="PatronBoon"and type(route.Patron)=="string"and not patrons[route.Patron],"Remaining patron routes stay distinct")
					patrons[route.Patron]=true
				end
			end
			check(merchant==(floor>=4 and 1 or 0),"Forced merchant chance still respects starting floor")
			chosen=chosen or routes[1]
			check(first.Rewards:Select(chosen.Id,first.Run.Epoch,floor)==chosen,"Current route can be selected once")
			check(first.Rewards:Select(routes[1].Id,first.Run.Epoch,floor)==nil,"Second selection cannot replace accepted route")
		end
		ShopCatalog.Merchant.Chance=merchantTuning.Chance;ShopCatalog.Merchant.FromFloor=merchantTuning.FromFloor
	end)

	case("Owned-level merchant upgrade preserves rarity and rejects stale target state",function()
		local id="volta_arc_discharge"
		local f,row=premium("upgrade",function(sample)own(sample,id,1,"Heroic")end)
		check(row.BoonId==id and row.Price==140,"Only eligible owned boon is selected at authored price")
		check(buy(f,"upgrade")and f.Run.Boons[id].Level==2 and f.Run.Boons[id].Rarity=="Heroic","Level purchase preserves existing rarity")
		check(f.Run.Credits==860 and not buy(f,"upgrade"),"Level stock charges once")
		check(f.Rewards.Build[id]:GetAttribute("Level")==2,"Shop updates read-only build")
		check(rowView(f,"upgrade"):GetAttribute("Level")==2,"Sold product keeps the purchased level rather than displaying a subsequent upgrade")
		local stale,target=premium("upgrade",function(sample)own(sample,id,1,"Rare")end)
		stale.Run.Boons[target.BoonId].Level=3
		check(not buy(stale,"upgrade")and stale.Run.Credits==1000 and not target.Sold,"Target becoming max level invalidates purchase without charge")
	end)

	case("Random merchant boon is compatible Rare/Epic and never downgrades owned rarity",function()
		local target="bravo_belt_feed"
		local f,row=premium("rareboon",function(sample)
			for _,id in Catalog.Order do if id~=target then own(sample,id,3,"Heroic")end end
		end)
		check(row.BoonId==target and row.Price>=190 and row.Price<=270,"Only eligible useful boon selected within brief price range")
		check(row.Rarity=="Rare"or row.Rarity=="Epic","Merchant random boon has authored Rare/Epic rarity")
		check(Catalog[target].Compatibility[f.Player.Weapon],"Merchant boon matches selected weapon")
		check(buy(f,"rareboon")and f.Run.Boons[target].Level==1 and f.Run.Boons[target].Rarity==row.Rarity,"Random boon purchase grants advertised build entry")
		check(not buy(f,"rareboon"),"Random boon stock cannot be bought twice")
		local maxed,old=premium("rareboon",function(sample)
			for _,id in Catalog.Order do if id~=target then own(sample,id,3,"Heroic")end end
		end)
		own(maxed,old.BoonId,1,"Heroic")
		check(not buy(maxed,"rareboon")and maxed.Run.Credits==1000 and maxed.Run.Boons[old.BoonId].Rarity=="Heroic","New-boon item becoming owned rejects instead of downgrading or charging")
	end)

	case("Rarity merchant upgrade raises one tier and preserves level",function()
		local id="weiss_field_protocol"
		local f,row=premium("rarity",function(sample)own(sample,id,2,"Rare")end)
		check(row.BoonId==id and row.Price>=220 and row.Price<=350,"Rarity stock targets eligible owned boon within price range")
		check(buy(f,"rarity")and f.Run.Boons[id].Rarity=="Epic"and f.Run.Boons[id].Level==2,"Rarity purchase upgrades one tier without changing level")
		check(f.Rewards.Build[id]:GetAttribute("Rarity")=="Epic","Build summary receives rarity change")
		local stale,target=premium("rarity",function(sample)own(sample,id,2,"Rare")end)
		stale.Run.Boons[target.BoonId].Rarity="Heroic"
		check(not buy(stale,"rarity")and stale.Run.Credits==1000 and not target.Sold,"Already Heroic target cannot charge or downgrade")
	end)
end)

Effects.RefreshHealth=hooks.Health;Weapons.RefreshStats=hooks.Stats;Weapons.Refill=hooks.Refill
ShopCatalog.Merchant.Chance=merchantTuning.Chance;ShopCatalog.Merchant.FromFloor=merchantTuning.FromFloor
for _,holder in holders do holder:Destroy()end
if not harnessOk then table.insert(report.Failed,{Name="Harness",Error=tostring(harnessError)})end
report.HookCalls=calls
script:SetAttribute("Success",#report.Failed==0)
script:SetAttribute("Error",#report.Failed==0 and ""or HttpService:JSONEncode(report.Failed))
script:SetAttribute("Report",HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
