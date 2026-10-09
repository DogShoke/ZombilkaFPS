-- Temporary QA bridge only; never shipped by Rojo. Pair with the client test.
local D=require(game.ServerScriptService.Server.FloorDirector)
local W=require(game.ServerScriptService.Server.WeaponService)
local S=game.ReplicatedStorage.RunState
local bridge=Instance.new("RemoteEvent");bridge.Name="WeaponLifecycleQA";bridge.Parent=game.ReplicatedStorage
local busy=false
local function waitFor(check)
	local limit=os.clock()+25
	repeat if check()then return end;task.wait(.05)until os.clock()>limit
	error("Weapon lifecycle reset timeout")
end
bridge.OnServerEvent:Connect(function(player,action,serial)
	if busy then return end
	busy=true
	local ok,err=pcall(function()
		if action=="Cancel"then W.CancelActions(player)
		elseif action=="Death"or action=="Reset"then
			if action=="Death"then player.Character.Humanoid.Health=0 elseif S:GetAttribute("RunActive")then assert(D.EndRun(player,"QAWeapon"))end
			waitFor(function()return S:GetAttribute("State")=="RunEnded"end)
			if player.Character.Humanoid.Health<=0 then player:LoadCharacterAsync()end
			waitFor(function()return player.Character and player.Character:FindFirstChildOfClass("Humanoid")and player.Character.Humanoid.Health>0 and player:GetAttribute("RunCharacterReady")==true end)
			assert(D.StartRun(player,S:GetAttribute("RunEpoch")))
			player.Character.Humanoid.MaxHealth=100000;player.Character.Humanoid.Health=100000
		end
	end)
	bridge:FireClient(player,serial,ok,tostring(err or ""));busy=false
end)
