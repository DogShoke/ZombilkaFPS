-- Temporary Studio LocalScript paired with RuntimeBoonEffects.luau.
assert(game:GetService("RunService"):IsStudio(),"Studio QA only")
local R=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local C=require(R.Shared.Config)
local Catalog=require(R.Shared.BoonCatalog)
local bridge=R:WaitForChild("BoonEffectsQA",15)
assert(bridge,"Missing server QA bridge")
local ammo,reloading,weapon,shots=0,false,nil,0
local connection=R.CombatRemotes.Feedback.OnClientEvent:Connect(function(kind,a,b,c)
	if kind=="Ammo"then ammo,reloading,weapon=a,b,c end
	if kind=="Equipped"then weapon,ammo,reloading=a,b,false end
	if kind=="Shot"then shots+=1 end
end)
local report={Cases={}}
local testRarity,testLevel
local function stage(s)script:SetAttribute("Stage",s)end
local function snapshot()
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
	return {State=R.RunState:GetAttribute("State"),RunActive=R.RunState:GetAttribute("RunActive"),Epoch=R.RunState:GetAttribute("RunEpoch"),
		SelectedWeapon=p:GetAttribute("SelectedWeapon"),Character=c and c:GetFullName()or "nil",CharacterParent=c and c.Parent and c.Parent:GetFullName()or "nil",
		Head=c and c:FindFirstChild("Head")~=nil,Root=c and c:FindFirstChild("HumanoidRootPart")~=nil,Health=h and h.Health or -1,Weapon=weapon,Ammo=ammo,Reloading=reloading,Shots=shots}
end
local function waitFor(check,seconds,message)
	local limit=os.clock()+seconds
	repeat if check()then return end;task.wait(.025)until os.clock()>limit
	error((message or "Client QA timeout").."; snapshot="..game.HttpService:JSONEncode(snapshot()))
end
local function request(action,data)
	local reply=bridge:InvokeServer(action,data)
	assert(reply and reply.Ok,reply and reply.Error or "No QA response")
	return reply.Result
end
local function fire(target)
	task.wait(C.Weapons[weapon].FireInterval+.04)
	local beforeAmmo,beforeShots=ammo,shots
	local origin=p.Character.Head.Position
	local direction=target and(target.Position-origin).Unit or Vector3.yAxis
	R.CombatRemotes.Fire:FireServer(origin,direction,shots+1)
	waitFor(function()return shots==beforeShots+1 and ammo==beforeAmmo-1 end,3,"Actual remote shot/ammo feedback missing")
end
local function reload(capacity)
	R.CombatRemotes.Reload:FireServer()
	waitFor(function()return ammo==capacity and not reloading end,10,"Genuine reload did not finish")
end
local ok,err=pcall(function()
	waitFor(function()return bridge:GetAttribute("Ready")==true and bridge:GetAttribute("TestRarity")~=nil and bridge:GetAttribute("TestLevel")~=nil end,5,"QA parameter replication missing")
	testRarity=bridge:GetAttribute("TestRarity");testLevel=bridge:GetAttribute("TestLevel")
	report.TestRarity=testRarity;report.TestLevel=testLevel
	script:SetAttribute("TestRarity",testRarity);script:SetAttribute("TestLevel",testLevel)
	for _,gun in C.Weapons.Order do
		stage("Reset "..gun);weapon=nil
		local reset=request("Reset")
		script:SetAttribute("ResetSnapshot",game.HttpService:JSONEncode(reset))
		waitFor(function()
			local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
			return R.RunState:GetAttribute("State")=="ChoosingWeapon"and R.RunState:GetAttribute("RunEpoch")==reset.Epoch and c and c.Parent==workspace and c:FindFirstChild("Head")and c:FindFirstChild("HumanoidRootPart")and h and h.Health>0
		end,12,"ChoosingWeapon/new character replication readiness failed after server-confirmed Reset")
		stage("Select "..gun)
		R.CombatRemotes.SelectWeapon:FireServer(gun)
		waitFor(function()return weapon==gun and ammo==C.Weapons[gun].MagazineSize end,5,"Real weapon selection failed")
		-- Run the healing kill last so every previous case has the full native target set.
		local order={}
		for _,id in Catalog.Order do if id~="weiss_coagulation"then table.insert(order,id)end end
		table.insert(order,"weiss_coagulation")
		for _,id in order do
			stage(gun.." / "..id)
			local prepared=request("Prepare",id)
			assert(prepared.TestRarity==testRarity and prepared.TestLevel==testLevel,"Prepared case parameters differ from published QA config")
			local v=Catalog.Values(id,testLevel,testRarity)
			waitFor(function()return ammo==C.Weapons[gun].MagazineSize and not reloading end,3,"Baseline refill feedback missing")
			if id=="bravo_belt_feed"then reload(prepared.Capacity)
			elseif id=="bravo_first_salvo"then
				-- Three shell inserts must reset charges to three, never add nine.
				for _=1,v.Shots do fire(nil)end
				reload(prepared.Capacity)
				for _=1,v.Shots+1 do fire(prepared.Target)end
			elseif id=="volta_high_voltage"then fire(prepared.Target);fire(prepared.Target)
			elseif id~="weiss_field_protocol"then fire(prepared.Target)end
			if id=="volta_static_shock"then task.wait(math.max(.29,v.Duration-.04))end
			local result=request("Check",{Ammo=ammo,Reloading=reloading})
			table.insert(report.Cases,result)
			script:SetAttribute("Report",game.HttpService:JSONEncode(report))
		end
	end
end)
if not ok then
	script:SetAttribute("FailureSnapshot",game.HttpService:JSONEncode(snapshot()))
	local snapshotOk,serverSnapshot=pcall(function()return request("Snapshot")end)
	if snapshotOk then script:SetAttribute("ServerFailureSnapshot",game.HttpService:JSONEncode(serverSnapshot))end
end
local cleanupOk,cleanupError=pcall(function()request("Cleanup")end)
connection:Disconnect()
if not cleanupOk and ok then ok=false;err="QA Cleanup: "..tostring(cleanupError)end
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
