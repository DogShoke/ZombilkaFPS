-- Playable map/combat preview only. No XP, rewards, economy or profile writes.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Settings=require(ReplicatedStorage.Shared.GameModeConfig).Prototype
local Clock=require(script.Parent.RunClock)
local Zombies=require(script.Parent.ZombieService)
local Weapons=require(script.Parent.WeaponService)
local Progress=require(script.Parent.EncounterProgress)
local Prototype={}

function Prototype.Start(map)
	local state=ReplicatedStorage.RunState
	assert(not state:GetAttribute("ActiveDirector"),"A run controller is already active")
	state:SetAttribute("ActiveDirector","EndlessPrototype")
	local remotes=Instance.new("Folder");remotes.Name="RunRemotes";remotes.Parent=ReplicatedStorage
	local function folder(name)
		local f=Instance.new("Folder");f.Name=name;f.Parent=state;return f
	end
	local results=folder("RunResults")
	local research=folder("Research")
	for k,v in {Status="Unavailable",Mode="Prototype",Balance=0,Revision=0,Busy=false,
		Error="Исследования отключены в прототипе карты; постоянные данные не изменяются."}do research:SetAttribute(k,v)end
	for _,name in {"RewardOffer","ShopOffer","Build"}do folder(name):SetAttribute("Active",false)end
	local startRemote
	-- Dormant panel compatibility only: these remotes cannot grant or buy anything.
	for _,name in {"StartRun","ClaimBoon","RerollBoon","BuyShopItem","CloseShop","BuyResearch"}do
		local event=Instance.new("RemoteEvent");event.Name=name;event.Parent=remotes
		if name=="StartRun"then startRemote=event end
	end
	local owner,character,deathConnection
	local phase,epoch,generation="WaitingForPlayer",0,0
	local elapsed,deadline,nextSpawn,lastRestart=0,0,0,-math.huge
	local progress,spawnBusy,runId
	local function publish()
		local diagnostics=Zombies.Diagnostics()
		for k,v in {State=phase,RunEpoch=epoch,RunId=runId or "",RunActive=phase=="FloorIntro"or phase=="EncounterActive",
			PrototypeElapsed=elapsed,RunKills=progress and progress.Defeated or 0,Alive=Zombies.Count(),Pending=Zombies.Pending(),
			DesiredAlive=Settings.DesiredAlive,Paused=false,ResearchStatus="Unavailable",Credits=0,Rerolls=0,BoonCount=0,
			EncounterMode="Prototype",Theme="КОРПОРАТИВНЫЙ КОМПЛЕКС",SpawnFailures=diagnostics.Failures,
			CombatBlocked=diagnostics.Blocked,FloorComplete=false,ElevatorLockReason="В ПРОТОТИПЕ НЕТ ЛИФТОВ"}do state:SetAttribute(k,v)end
	end
	local function clear(resetWeapon)
		generation+=1;spawnBusy=false;Clock.Paused=false;Zombies.Clear()
		if owner and resetWeapon~=false then Weapons.ResetPlayer(owner)end
	end
	local function endPreview(resetWeapon)
		if phase~="EncounterActive"and phase~="FloorIntro"then return end
		for k,v in {Kills=progress and progress.Defeated or 0,Duration=elapsed,BoonsJson="{}",
			ResearchStatus="Unavailable",PendingResearch=0,ResearchEarned=0}do results:SetAttribute(k,v)end
		phase="RunEnded";epoch+=1;clear(resetWeapon);publish()
	end
	local function prepare(c)
		local player=owner
		if not player or c~=player.Character then return end
		if character and character~=c then endPreview()end
		character=c;player:SetAttribute("RunCharacterReady",false)
		if deathConnection then deathConnection:Disconnect()end
		local h=c:WaitForChild("Humanoid",10);local root=c:WaitForChild("HumanoidRootPart",10)
		if not h or not root or owner~=player or player.Parent~=Players or c~=player.Character or h.Health<=0 then return end
		deathConnection=h.Died:Connect(function()if owner==player and c==character then endPreview()end end)
		player.RespawnLocation=map.Spawn
		player:SetAttribute("InElevatorTravel",false);player:SetAttribute("InSafeInterlude",false)
		root.Anchored=false;c:PivotTo(map.Entry);root.AssemblyLinearVelocity=Vector3.zero
		player:SetAttribute("RunCharacterReady",true);publish()
	end
	local function beginSelection()
		clear();epoch+=1;elapsed=0;progress=nil;runId=HttpService:GenerateGUID(false)
		phase="ChoosingWeapon";publish()
	end
	local function bind(player)
		player.RespawnLocation=map.Spawn
		if owner then return end -- Single-player prototype, as specified.
		owner=player;state:SetAttribute("OwnerUserId",player.UserId)
		player:SetAttribute("ResearchBusy",false);beginSelection()
		player.CharacterAdded:Connect(prepare)
		player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
			if player~=owner then return end
			local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
			if phase~="ChoosingWeapon"or not player:GetAttribute("SelectedWeapon")or not h or h.Health<=0
				or player:GetAttribute("RunCharacterReady")~=true then return end
			Zombies.Configure(map.Zones,map.Bounds,1,map.NavGraph.Nodes,map.Model)
			progress=Progress.New({Mode="Prototype",Quota=0}) -- Never Progress.Step / floor completion.
			phase="FloorIntro";deadline=Clock.Now()+Settings.IntroSeconds;publish()
		end)
		if player.Character then task.spawn(prepare,player.Character)end
	end
	startRemote.OnServerEvent:Connect(function(player,requestedEpoch)
		local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
		if player~=owner or phase~="RunEnded"or type(requestedEpoch)~="number"or requestedEpoch~=epoch
			or not h or h.Health<=0 or player:GetAttribute("RunCharacterReady")~=true or os.clock()-lastRestart<1 then return end
		lastRestart=os.clock();beginSelection()
	end)
	Players.PlayerAdded:Connect(bind)
	Players.PlayerRemoving:Connect(function(player)
		if player~=owner then return end
		endPreview(false);clear(false);owner=nil;character=nil;progress=nil;epoch+=1;phase="WaitingForPlayer"
		state:SetAttribute("OwnerUserId",nil)
		if deathConnection then deathConnection:Disconnect();deathConnection=nil end
		publish();for _,candidate in Players:GetPlayers()do if candidate~=player then bind(candidate);break end end
	end)
	for _,player in Players:GetPlayers()do bind(player)end
	map.Spawn.Enabled=true
	local lastPublish=0
	RunService.Heartbeat:Connect(function(dt)
		Clock.Step(dt)
		if phase=="FloorIntro"and Clock.Now()>=deadline then
			phase="EncounterActive";Zombies.BeginEncounter(progress);nextSpawn=Clock.Now()
		end
		if phase=="EncounterActive"then
			elapsed+=dt
			if not spawnBusy and Clock.Now()>=nextSpawn and Zombies.Count()+Zombies.Pending()<Settings.DesiredAlive then
				spawnBusy=true;local token=generation
				task.spawn(function()
					local ok,err=pcall(function()
						local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
						if map.GetSpawnZones and root then Zombies.SetZones(map.GetSpawnZones(root.Position))end
						return Zombies.Spawn()
					end)
					if token~=generation then return end
					spawnBusy=false;nextSpawn=Clock.Now()+Settings.SpawnInterval
					if not ok then warn("Prototype spawn failed: "..tostring(err))end
				end)
			end
		end
		if Clock.Now()-lastPublish>=.1 then lastPublish=Clock.Now();publish()end
	end)
	publish()
end
return Prototype
