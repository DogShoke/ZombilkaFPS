-- Temporary Studio Script. Native deaths/travel plus actual prompt/GUI purchases.
assert(game:GetService("RunService"):IsStudio())
local R=game.ReplicatedStorage;local S=R:WaitForChild("RunState")
local C=require(R.Shared.Config);local SC=require(R.Shared.ShopCatalog)
local D=require(game.ServerScriptService.Server.FloorDirector)
local Shop=require(game.ServerScriptService.Server.ShopService)
local p=game.Players:GetPlayers()[1];local changes={};local report={}
local merchant=script:GetAttribute("Merchant")==true
local originalBuy=Shop.Buy
Shop.Buy=function(self,player,epoch,token,id,revision)
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local before=h and h.Health;local maximum=h and h.MaxHealth
	local accepted=originalBuy(self,player,epoch,token,id,revision)
	if accepted and player==p and id=="heal"then
		report.HealBefore=before;report.HealAfter=h.Health
		report.HealExpected=math.min(maximum,before+maximum*SC.Products.heal.HealFraction)
	end
	return accepted
end
local function tune(t,k,v)table.insert(changes,{t,k,t[k]});t[k]=v end
local function stage(value)script:SetAttribute("Stage",value)end
local function waitFor(check,seconds,message)
	local deadline=os.clock()+seconds
	repeat if check()then return end;task.wait(.05)until os.clock()>deadline
	error(message or "Shop flow timeout")
end
local function floor()return workspace.OfficeRun:FindFirstChild(string.format("Floor%03d",S:GetAttribute("Floor")))end
local function clearCombat()
	waitFor(function()
		if S:GetAttribute("State")=="EncounterActive"then
			for _,m in workspace:GetChildren()do if m:GetAttribute("IsZombie")and not m:GetAttribute("Dead")then m.Humanoid:TakeDamage(10000)end end
		end
		return S:GetAttribute("State")=="ElevatorAvailable"
	end,90,"Native combat did not clear")
end
local function travel(wantMerchant)
	local chosen
	local patronChoices=0
	for _,v in floor().ElevatorLobby:GetDescendants()do
		if v:IsA("ProximityPrompt")and v.Name=="NextFloor"and v.ObjectText~="Завхоз"then patronChoices+=1 end
		if v:IsA("ProximityPrompt")and(wantMerchant and v.ObjectText=="Завхоз"or not wantMerchant and v.ObjectText=="Профессор Вольта")then chosen=v;break end
	end
	assert(chosen,"Advertised requested route absent")
	if wantMerchant then
		patronChoices=0
		for _,v in floor().ElevatorLobby:GetDescendants()do if v:IsA("ProximityPrompt")and v.Name=="NextFloor"and v.ObjectText~="Завхоз"then patronChoices+=1 end end
		assert(patronChoices==2,"Merchant must retain two patron choices");report.PatronChoices=patronChoices
	end
	p.Character:PivotTo(CFrame.new(chosen.Parent.Parent.CabinFloor.Position+Vector3.new(0,3,0)))
	assert(D.TryTravel(p,nil,chosen:GetAttribute("RouteId")))
	waitFor(function()return S:GetAttribute("State")== (wantMerchant and "ShopInterlude"or "RewardInterlude")end,30,"Arrival menu")
end
local function atVending()
	local button=floor().ElevatorLobby.SafeVending.ShopButton
	-- In front of the genuine prompt, within cabin; primary faces it and holds E.
	p.Character:PivotTo(CFrame.lookAt(button.Position+Vector3.new(0,-.6,-3),button.Position))
	return button
end
local function closeWait()
	waitFor(function()return S:GetAttribute("State")=="NextFloor"end,120,"Click native Continue")
end
local ok,err=pcall(function()
	waitFor(function()return D.EndRun and S:GetAttribute("State")=="ChoosingWeapon"end,60,"Director initialization")
	tune(C.Run,"IntroDuration",.1);tune(C.Run,"DoorDuration",.15);tune(C.Run,"TravelDuration",.2)
	tune(C.Run.Horde,"BaseSpawnRate",3);tune(C.Run.Horde,"MaxSpawnRate",3)
	tune(C.Run.Encounters,"KillQuota",3);tune(C.Run.Encounters,"QuotaPerFloor",0)
	tune(SC.Merchant,"Chance",merchant and 1 or 0);tune(SC.Merchant,"FromFloor",1)
	report.Coverage="Native Director ledger; accelerated actual NPC deaths; real GUI and vending prompt. Not normal balance."
	report.Merchant=merchant
	stage("Select Glock")
	waitFor(function()return p:GetAttribute("SelectedWeapon")=="Glock"end,120,"Click Glock")
	p.Character.Humanoid.MaxHealth=100000;p.Character.Humanoid.Health=100000
	clearCombat();assert(S:GetAttribute("Credits")==90,"Floor1 quota30 + completion60 credits")
	report.FirstCredits=S:GetAttribute("Credits")
	travel(merchant)
	if merchant then
		local offer=S.ShopOffer;assert(offer:GetAttribute("Kind")=="MerchantShop"and #offer:GetChildren()>=3)
		local patrons=0;for _,v in floor().ElevatorLobby:GetDescendants()do if v:IsA("ProximityPrompt")and v.ObjectText~="Завхоз"and v.Name=="NextFloor"then patrons+=1 end end
		report.Stock={};for _,v in offer:GetChildren()do table.insert(report.Stock,v:GetAttributes())end
		stage("Merchant zero-purchase Continue");closeWait()
		assert(S:GetAttribute("Credits")==90 and S:GetAttribute("BoonCount")==0)
		report.ZeroPurchaseExit=true
	else
		stage("Click boon")
		waitFor(function()return S:GetAttribute("State")=="NextFloor"end,120,"Click actual boon card")
		assert(S:GetAttribute("BoonCount")==1)
		atVending();stage("Open vending prompt")
		waitFor(function()return S:GetAttribute("State")=="ShopInterlude"end,120,"Hold E at vending")
		local offer=S.ShopOffer;local token,revision=offer:GetAttribute("Token"),offer:GetAttribute("Revision")
		assert(#offer:GetChildren()==3 and S:GetAttribute("Credits")==90)
		assert(not D.BuyShopItem(p,S:GetAttribute("RunEpoch"),"wrong","reroll",revision))
		stage("Buy reroll")
		waitFor(function()return S:GetAttribute("Rerolls")==1 end,120,"Actual reroll purchase")
		assert(S:GetAttribute("Credits")==30 and offer:GetAttribute("Revision")>revision)
		assert(not D.BuyShopItem(p,S:GetAttribute("RunEpoch"),token,"reroll",revision),"Purchase replay")
		assert(not D.BuyShopItem(p,S:GetAttribute("RunEpoch"),token,"reroll",offer:GetAttribute("Revision")),"Sold stock bought twice")
		report.PurchasedReroll=true;stage("Continue vending");closeWait()
		atVending();stage("Reopen vending prompt")
		waitFor(function()return S:GetAttribute("State")=="ShopInterlude"end,120,"Reopen genuine prompt")
		local sold=false;for _,v in offer:GetChildren()do if v:GetAttribute("Id")=="reroll"then sold=v:GetAttribute("Sold")==true end end
		assert(sold and offer:GetAttribute("Token")~=token and S:GetAttribute("Credits")==30)
		report.ReopenPreservesStock=true;stage("Continue reopened vending");closeWait()
	end
	p.Character:PivotTo(floor().PlayerSpawn.CFrame*CFrame.new(0,3,-12))
	waitFor(function()return S:GetAttribute("State")=="EncounterActive"end,15,"Next combat after shop")
	if not merchant then
		clearCombat();assert(S:GetAttribute("Credits")==99,"Floor2 credit award69")
		travel(false)
		local o=S.RewardOffer;local card=o:GetChildren()[1]
		assert(D.ClaimBoon(p,S:GetAttribute("RunEpoch"),o:GetAttribute("Token"),card:GetAttribute("Id"),o:GetAttribute("Revision")))
		p.Character.Humanoid.Health=50;atVending();stage("Open second vending prompt")
		waitFor(function()return S:GetAttribute("State")=="ShopInterlude"end,120,"Second floor vending")
		stage("Buy heal")
		waitFor(function()return S:GetAttribute("Credits")==34 end,120,"Actual heal purchase")
		assert(report.HealAfter==report.HealExpected,"35 percent heal at the actual checkout health")
		report.HealedHealth=p.Character.Humanoid.Health
	end
	p.Character.Humanoid.Health=0
	waitFor(function()return S:GetAttribute("State")=="RunEnded"end,30,"Shop death reset")
	assert(S:GetAttribute("Credits")==0 and S:GetAttribute("Rerolls")==0 and S:GetAttribute("BoonCount")==0)
	assert(not S.ShopOffer:GetAttribute("Active")and S:GetAttribute("Floor")==1)
	report.Result=S.RunResults:GetAttributes();report.DeathReset=true;report.NextCombat=true
end)
for _,change in changes do change[1][change[2]]=change[3]end
Shop.Buy=originalBuy
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
stage(ok and "Complete"or "Failed")
