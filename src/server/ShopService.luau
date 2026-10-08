-- Finite run stock and synchronous checkout. FloorDirector owns safe phase/cabin checks.
local HttpService=game:GetService("HttpService")
local R=game.ReplicatedStorage
local Catalog=require(R.Shared.ShopCatalog)
local Boons=require(R.Shared.BoonCatalog)
local Progression=require(R.Shared.ProgressionConfig)
local Patrons=require(R.Shared.Patrons)
local Policy=require(script.Parent.RewardPolicy)
local Effects=require(script.Parent.BoonEffects)
local Weapons=require(script.Parent.WeaponService)
local Shop={}
Shop.__index=Shop
local function integer(value)
	return type(value)=="number"and value==value and math.abs(value)<math.huge and value%1==0
end
local function alive(player)
	local c=player and player.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and h
end
local function number(value)return (string.format("%.2f",value):gsub("0+$",""):gsub("%.$",""))end
local function shuffle(list,rng)
	for i=#list,2,-1 do local j=rng:NextInteger(1,i);list[i],list[j]=list[j],list[i]end
end
local function compatible(id,weapon)
	local def=Boons[id];local patron=def and Patrons[def.Patron]
	return def and not def.Disabled and patron and not patron.Disabled and table.find(Patrons.Active,def.Patron)~=nil and def.Compatibility[weapon]
end
local function row(product,boonId,rarity)
	return {Id=product,Product=product,Price=Catalog.Products[product].Price,Sold=false,BoonId=boonId,Rarity=rarity}
end
function Shop.new(run,state,rewards)
	local folder=Instance.new("Folder");folder.Name="ShopOffer";folder:SetAttribute("Active",false);folder.Parent=state
	return setmetatable({Run=run,State=state,Rewards=rewards,Folder=folder,Stock={},Revision=0},Shop)
end
function Shop:HealthRoom()
	local field=self.Run.Boons.weiss_field_protocol
	local bonus=field and Boons.Values("weiss_field_protocol",field.Level,field.Rarity).MaxHealth or 0
	return math.max(0,Boons.Limits.MaxHealthBonus-bonus-(self.Run.SupplyHealth or 0))
end
-- Produces read-only display data and a fully validated server grant plan.
function Shop:Inspect(item,player)
	if item.Sold and item.Purchased then
		local purchased=table.clone(item.Purchased)
		purchased.Sold=true;purchased.Available=false;purchased.Reason="ПРОДАНО"
		return purchased,{}
	end
	local product=Catalog.Products[item.Product]
	local card={Id=item.Id,NameRu=product.NameRu,DescriptionRu=product.DescriptionRu,Price=item.Price,Sold=item.Sold,Kind=product.Kind}
	local h=alive(player);local reason;local grant={Kind=product.Kind}
	if not h then reason="ПЕРСОНАЖ НЕДОСТУПЕН"
	elseif product.Kind=="Heal"then
		grant.Amount=math.min(h.MaxHealth-h.Health,h.MaxHealth*product.HealFraction)
		card.DescriptionRu="Восстановить до "..number(grant.Amount).." HP ("..number(product.HealFraction*100).."% максимального здоровья)."
		if grant.Amount<=0 then reason="ЗДОРОВЬЕ ПОЛНОЕ"end
	elseif product.Kind=="Reroll"then
		grant.Amount=product.Amount
		if self.Run.Rerolls+grant.Amount>Progression.Rerolls.CarryCap then reason="ЛИМИТ ПЕРЕБРОСОВ: "..Progression.Rerolls.CarryCap end
	elseif product.Kind=="Health"then
		grant.Amount=math.min(product.Amount,self:HealthRoom())
		card.DescriptionRu="Максимальное здоровье +"..number(grant.Amount).." на этот забег. Общий бонус ограничен "..Boons.Limits.MaxHealthBonus.." HP."
		if grant.Amount<=0 then reason="ЛИМИТ МАКСИМАЛЬНОГО HP"end
	elseif product.Kind=="Supply"then
		grant.Amount=math.min(product.Heal,h.MaxHealth-h.Health)
	elseif product.Kind=="Upgrade"or product.Kind=="Rarity"or product.Kind=="RareBoon"then
		local def=Boons[item.BoonId];local owned=self.Run.Boons[item.BoonId]
		card.BoonId=item.BoonId
		if def then card.NameRu=product.NameRu..": "..def.NameRu end
		if not compatible(item.BoonId,player:GetAttribute("SelectedWeapon"))then reason="ТАЛАНТ НЕДОСТУПЕН ДЛЯ ОРУЖИЯ"
		elseif product.Kind=="RareBoon"then
			if owned then reason="ТАЛАНТ УЖЕ ПОЛУЧЕН"
			elseif not table.find(def.RarityEligible,item.Rarity)then reason="РЕДКОСТЬ НЕДОСТУПНА"
			else grant.Level=1;grant.Rarity=item.Rarity end
		elseif not owned then reason="НУЖЕН УКАЗАННЫЙ ТАЛАНТ"
		elseif product.Kind=="Upgrade"then
			if owned.Level>=def.MaxLevel then reason="МАКСИМАЛЬНЫЙ УРОВЕНЬ"
			else grant.Level=owned.Level+1;grant.Rarity=owned.Rarity end
		else
			local rarity=Progression.Rarities[owned.Rarity]
			local nextRarity=rarity and Progression.RarityOrder[rarity.Rank+1]
			if not nextRarity or not table.find(def.RarityEligible,nextRarity)then reason="МАКСИМАЛЬНАЯ РЕДКОСТЬ"
			else grant.Level=owned.Level;grant.Rarity=nextRarity end
		end
		if not reason then
			grant.BoonId=item.BoonId
			card.Level=grant.Level;card.Rarity=grant.Rarity
			card.NameRu=product.NameRu..": "..def.NameRu
			card.DescriptionRu=Progression.Rarities[grant.Rarity].NameRu.." · УРОВЕНЬ "..grant.Level.."\n"..def.Describe(Boons.Values(item.BoonId,grant.Level,grant.Rarity))
		end
	end
	if item.Sold then reason="ПРОДАНО"end
	if not reason and self.Run.Credits<item.Price then reason="НЕДОСТАТОЧНО КРЕДИТОВ"end
	card.Available=reason==nil;card.Reason=reason or ""
	return card,grant
end
function Shop:CreateStock(player,kind,floor,seed)
	local items={}
	if kind=="Vending"then
		for _,id in Catalog.Vending.Products do table.insert(items,row(id))end
	else
		local rng=Random.new(Policy.Seed(seed,floor,self.Run.Epoch,5))
		local weapon=player:GetAttribute("SelectedWeapon")
		local unowned,levels,rarities={},{},{}
		for _,id in Boons.Order do
			local def=Boons[id];local owned=self.Run.Boons[id]
			if not compatible(id,weapon)then continue end
			if not owned then
				if table.find(def.RarityEligible,"Rare")or table.find(def.RarityEligible,"Epic")then table.insert(unowned,id)end
			else
				if owned.Level<def.MaxLevel then table.insert(levels,id)end
				local rarity=Progression.Rarities[owned.Rarity];local nextRarity=rarity and Progression.RarityOrder[rarity.Rank+1]
				if nextRarity and table.find(def.RarityEligible,nextRarity)then table.insert(rarities,id)end
			end
		end
		local premiums={}
		if #unowned>0 then
			local id=unowned[rng:NextInteger(1,#unowned)];local eligible=Boons[id].RarityEligible
			local rarity=rng:NextNumber()<Catalog.Merchant.EpicChance and "Epic"or "Rare"
			if not table.find(eligible,rarity)then rarity=rarity=="Epic"and "Rare"or "Epic"end
			table.insert(premiums,row("rareboon",id,rarity))
		end
		if #levels>0 then table.insert(premiums,row("upgrade",levels[rng:NextInteger(1,#levels)]))end
		if #rarities>0 then table.insert(premiums,row("rarity",rarities[rng:NextInteger(1,#rarities)]))end
		shuffle(premiums,rng)
		table.insert(items,row("free_supply"))
		for i=1,math.min(Catalog.Merchant.PremiumSlots,#premiums)do table.insert(items,premiums[i])end
		local useful,unavailable={},{ }
		local utilities=table.clone(Catalog.Vending.Products);shuffle(utilities,rng)
		for _,id in utilities do
			local item=row(id);local card=self:Inspect(item,player)
			table.insert(card.Available and useful or unavailable,item)
		end
		for _,list in {useful,unavailable}do
			for _,item in list do if #items<Catalog.Merchant.MaxItems then table.insert(items,item)end end
		end
	end
	return {Items=items,Kind=kind,Floor=floor}
end
function Shop:Publish()
	self.State:SetAttribute("Credits",self.Run.Credits or 0);self.State:SetAttribute("Rerolls",self.Run.Rerolls or 0)
	local offer=self.Offer
	if not offer or not offer.Active or not self.Run:IsCurrent(offer.Epoch)or offer.RunId~=self.Run.Id then self.Folder:SetAttribute("Active",false);return end
	self.Folder:ClearAllChildren()
	for i,item in offer.Items do
		local card=self:Inspect(item,offer.Player)
		local folder=Instance.new("Folder");folder.Name=string.format("%02d",i)
		for key,value in card do folder:SetAttribute(key,value)end
		folder.Parent=self.Folder
	end
	local h=alive(offer.Player)
	for key,value in {Token=offer.Token,RunEpoch=offer.Epoch,RunId=offer.RunId,Revision=offer.Revision,Kind=offer.Kind,Floor=offer.Floor,
		Title=offer.Kind=="Vending"and Catalog.Vending.Title or Catalog.Merchant.Title,Health=h and h.Health or 0,MaxHealth=h and h.MaxHealth or 0}do self.Folder:SetAttribute(key,value)end
	self.Folder:SetAttribute("Active",true)
end
function Shop:Open(player,kind,floor,seed)
	if kind~="Vending"and kind~="MerchantShop"or not self.Run.Active or not alive(player)
		or not integer(floor)or floor<1 or not integer(seed)then return false end
	local userId=self.State:GetAttribute("OwnerUserId")
	if userId and userId~=player.UserId then return false end
	if self.RunId~=self.Run.Id then self:Clear();self.RunId=self.Run.Id end
	if self.Player and self.Player~=player then return false end
	self.Player=player
	local key=tostring(floor)..":"..kind
	local stock=self.Stock[key]
	if not stock then stock=self:CreateStock(player,kind,floor,seed);self.Stock[key]=stock end
	self:Close();self.Revision+=1
	self.Offer={Player=player,RunId=self.Run.Id,Epoch=self.Run.Epoch,Token=HttpService:GenerateGUID(false),Revision=self.Revision,
		Kind=kind,Floor=floor,Items=stock.Items,Active=true}
	self:Publish();return true
end
function Shop:Current(player,epoch,token,revision)
	local offer=self.Offer
	return offer~=nil and offer.Active and self.Run:IsCurrent(epoch)and offer.RunId==self.Run.Id and offer.Player==player
		and offer.Epoch==epoch and offer.Token==token and offer.Revision==revision
end
function Shop:Buy(player,epoch,token,itemId,revision)
	if not self:Current(player,epoch,token,revision)or type(itemId)~="string"or #itemId>80 then return false end
	local offer=self.Offer;local item
	for _,candidate in offer.Items do if candidate.Id==itemId then item=candidate;break end end
	if not item then return false end
	local card,grant=self:Inspect(item,player)
	if not card.Available then return false end
	-- No yields from validation through debit/grant/sold/revision commit.
	if not self.Run:SpendCredits(epoch,item.Price)then return false end
	item.Purchased=card;item.Sold=true;self.Revision+=1;offer.Revision=self.Revision
	local h=alive(player)
	if grant.Kind=="Heal"or grant.Kind=="Supply"then h.Health=math.min(h.MaxHealth,h.Health+grant.Amount)
	elseif grant.Kind=="Reroll"then self.Run.Rerolls+=grant.Amount
	elseif grant.Kind=="Health"then self.Run.SupplyHealth+=grant.Amount
	else
		local def=Boons[grant.BoonId]
		self.Run.Boons[grant.BoonId]={Id=grant.BoonId,Patron=def.Patron,Level=grant.Level,Rarity=grant.Rarity}
		if not self.Run.Patrons[def.Patron]and #self.Run.PatronOrder<Progression.Patrons.PrimaryCap then table.insert(self.Run.PatronOrder,def.Patron)end
		self.Run.Patrons[def.Patron]=true
	end
	if grant.Kind=="Supply"then Weapons.Refill(player)end
	Effects.RefreshHealth();Weapons.RefreshStats(player);self.Rewards:PublishBuild()
	self:Publish();return true
end
function Shop:Close()
	if self.Offer then self.Offer.Active=false end
	self.Offer=nil;self.Folder:SetAttribute("Active",false)
end
function Shop:Clear()
	self:Close();self.Stock={};self.RunId=nil;self.Player=nil
	self.Folder:ClearAllChildren();self.Folder:SetAttribute("Token",nil);self.Folder:SetAttribute("RunEpoch",nil)
end
return Shop
