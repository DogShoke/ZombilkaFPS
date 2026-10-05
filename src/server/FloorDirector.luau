local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Shared.Config)
local Audio=require(ReplicatedStorage.Shared.Audio)
local Clock=require(script.Parent.RunClock)
local Zombies=require(script.Parent.ZombieService)
local Elevator=require(script.Parent.ElevatorService)
local OfficeMap=require(script.Parent.OfficeMap)
local FloorDirector={}
function FloorDirector.Start(map)
	local state=Instance.new("Folder"); state.Name="RunState"; state.Parent=ReplicatedStorage
	local owner, current = nil, map.Current
	local floorNumber,wave,spawned,nextSpawn,deadline=1,0,0,0,0
	local phase="WaitingForPlayer"
	local travelStage,travelRoot
	local connectFloor
	local function budget(index)
		return (Config.Run.Waves[index] or 0)+(index>0 and math.min((floorNumber-1)*Config.Run.Difficulty.ExtraPerWavePerFloor,Config.Run.Difficulty.MaxExtraPerWave) or 0)
	end
	local function publish()
		state:SetAttribute("State",phase); state:SetAttribute("Floor",floorNumber); state:SetAttribute("LayoutIndex",current.Slot)
		state:SetAttribute("Theme",current.Layout.Label); state:SetAttribute("Seed",current.Layout.Seed); state:SetAttribute("RunSeed",map.Seed); state:SetAttribute("Levels",current.Layout.Upper and 2 or 1)
		state:SetAttribute("Wave",wave); state:SetAttribute("Waves",#Config.Run.Waves); state:SetAttribute("WaveBudget",budget(wave))
		state:SetAttribute("Alive",Zombies.Count()); state:SetAttribute("Remaining",math.max(0,budget(wave)-spawned)+Zombies.Count())
		state:SetAttribute("Spawned",spawned); state:SetAttribute("Paused",Clock.Paused)
	end
	local function setPhase(nextPhase,delay)
		phase=nextPhase; deadline=Clock.Now()+(delay or 0); publish()
	end
	local function pause(value) Clock.Paused=value; Zombies.SetPaused(value); publish() end
	local function configureFloor() Zombies.Configure(current.Zones,current.Bounds,floorNumber) end
	local function clearNext()
		if map.Next then map.Next.Model:Destroy(); map.Next=nil end
	end
	local function reset(character)
		pause(false); owner:SetAttribute("InElevatorTravel",false)
		if travelRoot and travelRoot.Parent then travelRoot.Anchored=false end
		travelRoot=nil; travelStage=nil; Zombies.Clear(); clearNext(); wave,spawned=0,0
		Elevator.SetOpen(current,false); current.Spawn.Enabled=true; owner.RespawnLocation=current.Spawn
		local root=character:WaitForChild("HumanoidRootPart")
		if not owner or character~=owner.Character then return end
		root.Anchored=false; character:PivotTo(current.Entry); configureFloor()
		if Config.Weapons[owner:GetAttribute("SelectedWeapon")] then setPhase("FloorIntro",Config.Run.IntroDuration)
		else setPhase("ChoosingWeapon") end
	end
	connectFloor=function(f)
		f.Prompt.Triggered:Connect(function(player) FloorDirector.TryTravel(player,f) end)
	end
	-- Server-only entry point: prompts and other server interactions share all travel guards.
	FloorDirector.TryTravel=function(player,f)
		f=f or current
		if player~=owner or f~=current or phase~="ElevatorAvailable" or Clock.Paused then return false end
		local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local h=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not h or h.Health<=0 or not Elevator.Inside(f,root.Position) then return false end
		if not map.Next or Zombies.Count()~=0 or wave~=#Config.Run.Waves or spawned~=budget(wave) then return false end
		player:SetAttribute("InElevatorTravel",true); root.AssemblyLinearVelocity=Vector3.zero; root.Anchored=true; character:PivotTo(f.Cabin)
		travelRoot=root; travelStage="Closing"; Elevator.SetOpen(f,false); setPhase("ElevatorTravel",Config.Run.DoorDuration)
		return true
	end
	connectFloor(current)
	local function join(player)
		if owner then return end
		owner=player; state:SetAttribute("OwnerUserId",player.UserId)
		player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
			if owner==player and phase=="ChoosingWeapon" and Config.Weapons[player:GetAttribute("SelectedWeapon")] then setPhase("FloorIntro",Config.Run.IntroDuration) end
		end)
		player.CharacterAdded:Connect(reset)
		if player.Character then task.spawn(reset,player.Character) end
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		if player~=owner then return end
		Zombies.Clear(); clearNext(); owner=nil; pause(false); floorNumber,wave,spawned=1,0,0
		current.Model:Destroy(); current=OfficeMap.CreateFloor(map,1,1); map.Current=current; connectFloor(current)
		state:SetAttribute("OwnerUserId",nil); setPhase("WaitingForPlayer")
	end)
	for _,p in Players:GetPlayers() do join(p) end
	local accumulator=0
	RunService.Heartbeat:Connect(function(dt)
		Clock.Step(dt); accumulator+=dt; if accumulator<Config.Run.Tick then return end; accumulator=0
		if not owner then return end
		local character=owner.Character; local h=character and character:FindFirstChildOfClass("Humanoid"); local root=character and character:FindFirstChild("HumanoidRootPart")
		if not h or h.Health<=0 or not root then
			if phase~="WaitingForPlayer" then Zombies.Clear(); clearNext(); pause(false); setPhase("WaitingForPlayer") end
			return
		end
		if Clock.Paused then return end
		local now=Clock.Now(); local f=current
		if phase=="FloorIntro" or phase=="BetweenWaves" then
			if now>=deadline then wave+=1; spawned=0; nextSpawn=now; setPhase("WaveActive") end
		elseif phase=="WaveActive" then
			if spawned<budget(wave) and now>=nextSpawn then
				nextSpawn=now+Config.Run.SpawnInterval
				if Zombies.Spawn() then spawned+=1 end
			end
			if spawned==budget(wave) and Zombies.Count()==0 then
				if wave<#Config.Run.Waves then setPhase("BetweenWaves",Config.Run.BetweenWaves)
				else
					-- Only the current floor and a ready destination exist; distant floors are never accumulated.
					map.Next=OfficeMap.CreateFloor(map,floorNumber+1,f.Slot%2+1); connectFloor(map.Next)
					setPhase("FloorCleared",1); Audio.Play("ElevatorArrival",f.Indicator)
				end
			end
		elseif phase=="FloorCleared" and now>=deadline then
			Elevator.SetOpen(f,true); setPhase("ElevatorAvailable"); f.Prompt.Enabled=true
		elseif phase=="ElevatorTravel" and now>=deadline then
			if travelStage=="Closing" then
				travelStage="Moving"; Audio.Play("ElevatorTravel",f.Indicator); deadline=now+Config.Run.TravelDuration
			elseif travelStage=="Moving" then
				current=map.Next; map.Current=current; map.Next=nil; floorNumber+=1
				current.Spawn.Enabled=true; owner.RespawnLocation=current.Spawn; Elevator.SetLabel(current,floorNumber)
				character:PivotTo(current.Cabin); root.AssemblyLinearVelocity=Vector3.zero
				f.Model:Destroy(); configureFloor(); wave,spawned=0,0
				Elevator.SetOpen(current,true); Audio.Play("ElevatorArrival",current.Indicator); setPhase("NextFloor",Config.Run.DoorDuration)
			end
		elseif phase=="NextFloor" and now>=deadline then
			if travelRoot then travelRoot.Anchored=false; travelRoot=nil; owner:SetAttribute("InElevatorTravel",false) end
			if root.Position.Z-current.Origin.Z<current.ExitZ then Elevator.SetOpen(current,false); setPhase("FloorIntro",Config.Run.IntroDuration) end
		end
		publish()
	end)
	publish()
end
return FloorDirector
