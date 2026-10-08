-- Real production select/fire/reload remotes; no replacement combat implementation.
local R=game.ReplicatedStorage
local C=require(R.Shared.Config)
local p=game.Players.LocalPlayer
local bridge=R:WaitForChild("WeaponLifecycleQA")
local ammo,reloading,weapon
local reply,serial=0,0
local connection=R.CombatRemotes.Feedback.OnClientEvent:Connect(function(kind,a,b,c)
	if kind=="Ammo"then ammo,reloading,weapon=a,b,c end
	if kind=="Equipped"then weapon,ammo,reloading=a,b,false end
end)
local response=bridge.OnClientEvent:Connect(function(n,ok,err)reply=n;assert(ok,err)end)
local function waitFor(check,seconds)
	local limit=os.clock()+seconds
	repeat if check()then return end;task.wait(.025)until os.clock()>limit
	error("Weapon client timeout")
end
local function request(action)
	serial+=1;bridge:FireServer(action,serial);waitFor(function()return reply==serial end,30)
end
local function fire()
	script:SetAttribute("Stage","Fire")
	local before=ammo
	R.CombatRemotes.Fire:FireServer(p.Character.Head.Position,Vector3.yAxis,1)
	waitFor(function()return ammo==before-1 end,3)
end
local report={Weapons={}}
local ok,err=pcall(function()
	for i,id in C.Weapons.Order do
		request("Reset")
		script:SetAttribute("Stage","Select "..id)
		waitFor(function()return R.RunState:GetAttribute("State")=="ChoosingWeapon"and p.Character and p.Character:FindFirstChild("Humanoid")and p.Character.Humanoid.Health>0 end,5)
		R.CombatRemotes.SelectWeapon:FireServer(id)
		local w=C.Weapons[id]
		waitFor(function()return weapon==id and ammo==w.MagazineSize end,5)
		fire();script:SetAttribute("Stage","Cancel reload "..id);R.CombatRemotes.Reload:FireServer();waitFor(function()return reloading end,3)
		request("Cancel");task.wait(w.ReloadDuration+.25)
		assert(ammo==w.MagazineSize-1 and not reloading,"Canceled reload inserted ammo: "..id)
		R.CombatRemotes.Reload:FireServer();waitFor(function()return ammo==w.MagazineSize and not reloading end,5)
		task.wait(w.FireInterval);fire();R.CombatRemotes.Reload:FireServer();waitFor(function()return reloading end,3)
		request("Death")
		script:SetAttribute("Stage","After death select "..id)
		waitFor(function()return R.RunState:GetAttribute("State")=="ChoosingWeapon"and p.Character and p.Character:FindFirstChild("Humanoid")and p.Character.Humanoid.Health>0 end,5)
		R.CombatRemotes.SelectWeapon:FireServer(id);waitFor(function()return weapon==id and ammo==w.MagazineSize end,5)
		fire();task.wait(w.ReloadDuration+.25)
		assert(ammo==w.MagazineSize-1 and not reloading,"Old reload modified new character: "..id)
		table.insert(report.Weapons,{Id=id,Cancel=true,NormalReload=true,DeathReloadInvalidated=true,Ammo=ammo})
		script:SetAttribute("Report",game.HttpService:JSONEncode(report))
	end
	request("Reset")
end)
connection:Disconnect();response:Disconnect()
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
