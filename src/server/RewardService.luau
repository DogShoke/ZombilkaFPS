local HttpService=game:GetService("HttpService")
local Catalog=require(game.ReplicatedStorage.Shared.BoonCatalog)
local Patrons=require(game.ReplicatedStorage.Shared.Patrons)
local Config=require(game.ReplicatedStorage.Shared.ProgressionConfig)
local Merchant=require(game.ReplicatedStorage.Shared.ShopCatalog).Merchant
local Policy=require(script.Parent.RewardPolicy)
local Effects=require(script.Parent.BoonEffects)
local Weapons=require(script.Parent.WeaponService)
local Rewards={}
Rewards.__index=Rewards
local supplies={
	{Id="supply_heal",NameRu="Медицинский запас",DescriptionRu="Восстановить до 25 HP. Таланты этого покровителя исчерпаны: доступна безопасная замена."},
	{Id="supply_health",NameRu="Запас прочности",DescriptionRu="До +3 максимального HP и лечение до 3 HP на этот забег. Общий бонус здоровья ограничен 60 HP."},
	{Id="supply_ammo",NameRu="Полный магазин",DescriptionRu="Заполнить текущий магазин до его серверной вместимости."},
}
local supplyIds={supply_heal=true,supply_health=true,supply_ammo=true}
local function shuffle(list,rng)
	for i=#list,2,-1 do local j=rng:NextInteger(1,i);list[i],list[j]=list[j],list[i]end
end
function Rewards.new(run,state)
	local folder=Instance.new("Folder");folder.Name="RewardOffer";folder.Parent=state
	local build=Instance.new("Folder");build.Name="Build";build.Parent=state
	return setmetatable({Run=run,State=state,Folder=folder,Build=build,Revision=0},Rewards)
end
function Rewards:Clear()
	self.Offer=nil;self.Routes=nil;self.Selected=nil
	self.Folder:SetAttribute("Active",false);self.Folder:SetAttribute("CanReroll",false);self.Folder:ClearAllChildren()
	self.Build:ClearAllChildren()
end
function Rewards:RoutesFor(seed,floor)
	local active={}
	for _,id in Patrons.Active do if Patrons[id]and not Patrons[id].Disabled then table.insert(active,id)end end
	local rng=Random.new(Policy.Seed(seed,floor,self.Run.Epoch,1))
	local order=Policy.PickPatrons(rng,active,self.Run.PatronOrder,self.Run.Patrons,Config.Patrons.RouteCount)
	local routes={}
	for i,id in order do
		routes[i]={Id=HttpService:GenerateGUID(false),Type="PatronBoon",Patron=id,Epoch=self.Run.Epoch,Floor=floor,
			Seed=Policy.Seed(seed,floor,self.Run.Epoch,2,i)}
	end
	if floor>=Merchant.FromFloor and #routes>=2 and Random.new(Policy.Seed(seed,floor,self.Run.Epoch,4)):NextNumber()<Merchant.Chance then
		local route=routes[#routes];route.Type="MerchantShop";route.Patron=nil
	end
	self.Routes=routes;self.Selected=nil;return routes
end
function Rewards:Select(id,epoch,floor)
	if self.Selected or not self.Run:IsCurrent(epoch)or type(id)~="string"then return nil end
	for _,route in self.Routes or {}do
		if route.Id==id and route.Epoch==epoch and route.Floor==floor then self.Selected=route;return route end
	end
	return nil
end
function Rewards:PublishBuild()
	self.Build:ClearAllChildren()
	for id,b in self.Run.Boons do
		local def=Catalog[id];local rarity=Config.Rarities[b.Rarity];local f=Instance.new("Folder");f.Name=id
		for key,value in {Id=id,NameRu=def.NameRu,Patron=def.Patron,Rarity=b.Rarity,RarityRu=rarity.NameRu,Level=b.Level,
			DescriptionRu=def.Describe(Catalog.Values(id,b.Level,b.Rarity))}do f:SetAttribute(key,value)end
		f.Parent=self.Build
	end
end
function Rewards:Eligible(patron,weapon)
	local result={}
	for _,id in Catalog.Order do
		local def=Catalog[id];local owned=self.Run.Boons[id]
		if not def.Disabled and def.Patron==patron and def.Compatibility[weapon]
			and (not owned or owned.Level<def.MaxLevel)then table.insert(result,id)end
	end
	return result
end
function Rewards:BuildCards(route,used,previous,weapon)
	local rng=Random.new(Policy.Seed(route.Seed,route.Floor,route.Epoch,3,used))
	local candidates=self:Eligible(route.Patron,weapon);shuffle(candidates,rng)
	local fresh,seen={},{}
	for _,card in previous or {}do seen[card.Id]=true end
	for _,id in candidates do if not seen[id]then table.insert(fresh,id)end end
	for _,id in candidates do if seen[id]then table.insert(fresh,id)end end
	local cards,roles={},{}
	for pass=1,2 do
		for _,id in fresh do
			if #cards>=3 then break end
			local def=Catalog[id]
			if pass==1 and roles[def.SlotOrCategory]or table.find(roles,id)then continue end
			local owned=self.Run.Boons[id];local level=owned and owned.Level+1 or 1
			local rarity=Policy.RollRarity(rng,route.Floor,self.Run.Pity,def.RarityEligible)
			rarity=Policy.BetterRarity(owned and owned.Rarity,rarity)
			table.insert(cards,{Id=id,NameRu=def.NameRu,Level=level,Rarity=rarity})
			roles[def.SlotOrCategory]=true;table.insert(roles,id)
		end
	end
	local hadRare=false
	for _,card in cards do if Config.Rarities[card.Rarity].Rank>=2 then hadRare=true end end
	if not hadRare and #cards>0 and route.Floor>=Config.Pity.RareFromFloor
		and self.Run.Pity.CommonDrought>=Config.Pity.CommonDrought then
		local card=cards[rng:NextInteger(1,#cards)]
		card.Rarity=Policy.RollRarity(rng,route.Floor,self.Run.Pity,Catalog[card.Id].RarityEligible,2)or card.Rarity
	end
	for _,card in cards do
		local rarity=Config.Rarities[card.Rarity]
		card.DescriptionRu=Catalog[card.Id].Describe(Catalog.Values(card.Id,card.Level,card.Rarity))
		card.RarityRu=rarity.NameRu;card.RarityColor=rarity.Color;card.Color=Patrons[route.Patron].Color
	end
	for _,supply in supplies do
		if #cards>=3 then break end
		local card=table.clone(supply);card.Level=1;card.RarityRu="ПРИПАСЫ";card.Color=Color3.fromRGB(151,190,174);table.insert(cards,card)
	end
	return cards
end
function Rewards:ValidCards(cards,weapon)
	if type(cards)~="table"or #cards~=3 then return false end
	local seen={}
	for _,card in cards do
		if type(card)~="table"or type(card.Id)~="string"or seen[card.Id]
			or type(card.NameRu)~="string"or type(card.DescriptionRu)~="string"then return false end
		seen[card.Id]=true
		local def=Catalog[card.Id];local owned=self.Run.Boons[card.Id]
		if def then
			if def.Disabled or not def.Compatibility[weapon]or not Config.Rarities[card.Rarity]or not table.find(def.RarityEligible,card.Rarity)
				or card.Level~=(owned and owned.Level+1 or 1)or card.Level>def.MaxLevel then return false end
		elseif not supplyIds[card.Id]then return false end
	end
	return true
end
function Rewards:ObserveCards(offer,cards)
	for _,card in cards do
		if card.Rarity then
			offer.NormalCount+=1
			local rank=Config.Rarities[card.Rarity].Rank
			offer.HadRare=offer.HadRare or rank>=2;offer.HadEpic=offer.HadEpic or rank>=3
		end
	end
end
function Rewards:PublishOffer()
	local offer=self.Offer;local patron=Patrons[offer.Patron]
	self.Folder:SetAttribute("Active",false);self.Folder:ClearAllChildren()
	for i,card in offer.Cards do
		local f=Instance.new("Folder");f.Name=string.format("%02d",i)
		for k,v in card do f:SetAttribute(k,v)end
		f.Parent=self.Folder
	end
	self.Revision+=1;offer.Revision=self.Revision
	for k,v in {Token=offer.Token,RunEpoch=offer.Epoch,PatronName=patron.NameRu,Greeting=patron.Greeting,Color=patron.Color,
		RerollsUsed=offer.Used,RerollsLimit=Config.Rerolls.PerOffer,CanReroll=offer.NormalCount>0}do self.Folder:SetAttribute(k,v)end
	self.State:SetAttribute("Rerolls",self.Run.Rerolls)
	self.Folder:SetAttribute("Revision",self.Revision);self.Folder:SetAttribute("Active",true)
end
function Rewards:Open(player)
	local route=self.Selected
	if not route or route.Opened or not self.Run:IsCurrent(route.Epoch)then return false end
	local weapon=player:GetAttribute("SelectedWeapon")
	local cards=self:BuildCards(route,0,nil,weapon)
	if not self:ValidCards(cards,weapon)then return false end
	if not self.Run.Patrons[route.Patron]and #self.Run.PatronOrder<Config.Patrons.PrimaryCap then table.insert(self.Run.PatronOrder,route.Patron)end
	self.Run.Patrons[route.Patron]=true;route.Opened=true
	self.Offer={Token=HttpService:GenerateGUID(false),Epoch=self.Run.Epoch,Cards=cards,Active=true,
		Patron=route.Patron,Player=player,Used=0,HadRare=false,HadEpic=false,NormalCount=0,LastReroll=-math.huge}
	self:ObserveCards(self.Offer,cards);self:PublishOffer();return true
end
function Rewards:Current(player,epoch,token,revision)
	local offer=self.Offer
	return offer and offer.Active and self.Run:IsCurrent(epoch)and offer.Player==player and offer.Epoch==epoch
		and token==offer.Token and revision==offer.Revision
end
function Rewards:Reroll(player,epoch,token,revision)
	if not self:Current(player,epoch,token,revision)then return false end
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not h or h.Health<=0 then return false end
	local offer=self.Offer;local now=os.clock()
	if offer.Used>=Config.Rerolls.PerOffer or not(self.Run.Rerolls>=1)or offer.NormalCount==0 or now-offer.LastReroll<Config.Rerolls.Cooldown then return false end
	offer.LastReroll=now
	local weapon=player:GetAttribute("SelectedWeapon")
	local ok,cards=pcall(self.BuildCards,self,self.Selected,offer.Used+1,offer.Cards,weapon)
	if not ok or not self:ValidCards(cards,weapon)then return false end
	-- Entire generation and commit are synchronous. Stable token + revision is the request key.
	self.Run.Rerolls-=1;offer.Used+=1;offer.Cards=cards
	self:ObserveCards(offer,cards);self:PublishOffer();return true
end
function Rewards:Claim(player,epoch,token,id,revision)
	if not self:Current(player,epoch,token,revision)or type(id)~="string"or #id>80 then return false end
	local offer=self.Offer;local selected
	for _,card in offer.Cards do if card.Id==id then selected=card;break end end
	if not selected then return false end
	local def=Catalog[id];local owned=self.Run.Boons[id]
	if def and (selected.Level~=(owned and owned.Level+1 or 1)or selected.Level>def.MaxLevel or not def.Compatibility[player:GetAttribute("SelectedWeapon")])then return false end
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not h or h.Health<=0 then return false end
	offer.Active=false;self.Folder:SetAttribute("Active",false);self.Folder:SetAttribute("CanReroll",false)
	Policy.CommitPity(self.Run.Pity,offer.HadRare,offer.HadEpic,offer.NormalCount)
	if def then self.Run.Boons[id]={Id=id,Patron=def.Patron,Rarity=selected.Rarity,Level=selected.Level}
	elseif id=="supply_health"then self.Run.SupplyHealth=math.min(Catalog.Limits.MaxHealthBonus,self.Run.SupplyHealth+3)
	elseif id=="supply_ammo"then Weapons.Refill(player)end
	Effects.RefreshHealth()
	if id=="supply_heal"or id=="supply_health"then h.Health=math.min(h.MaxHealth,h.Health+(id=="supply_heal"and 25 or 3))end
	Weapons.RefreshStats(player);self:PublishBuild();return true
end
return Rewards
