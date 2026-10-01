local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Shared.Config)
local Audio=require(ReplicatedStorage.Shared.Audio)
local Clock=require(script.Parent.RunClock)
local Zombies=require(script.Parent.ZombieService)
local Elevator=require(script.Parent.ElevatorService)
local FloorDirector={}
function FloorDirector.Start(floors)
	local state=Instance.new("Folder") state.Name="RunState" state.Parent=ReplicatedStorage
	local options=Instance.new("RemoteEvent") options.Name="Options" options.Parent=ReplicatedStorage.CombatRemotes
	local owner, floorIndex, floorNumber, wave, spawned, nextSpawn, deadline = nil,1,1,0,0,0,0
	local phase="WaitingForPlayer"
	local travelStage, travelRoot
	local function publish()
		state:SetAttribute("State",phase) state:SetAttribute("Floor",floorNumber) state:SetAttribute("LayoutIndex",floorIndex)
		state:SetAttribute("Wave",wave) state:SetAttribute("Waves",#Config.Run.Waves)
		state:SetAttribute("Alive",Zombies.Count()) state:SetAttribute("Remaining",math.max(0,(Config.Run.Waves[wave] or 0)-spawned)+Zombies.Count())
		state:SetAttribute("Spawned",spawned) state:SetAttribute("Paused",Clock.Paused)
	end
	local function setPhase(nextPhase,delay)
		phase=nextPhase deadline=Clock.Now()+(delay or 0) publish()
	end
	local function pause(value)
		Clock.Paused=value Zombies.SetPaused(value) publish()
	end
	local function reset(character)
		pause(false)
		owner:SetAttribute("OptionsOpen",false) owner:SetAttribute("InElevatorTravel",false)
		if travelRoot and travelRoot.Parent then travelRoot.Anchored=false end
		travelRoot=nil travelStage=nil Zombies.Clear()
		wave,spawned=0,0
		for _,f in floors do f.Spawn.Enabled=false Elevator.SetOpen(f,false) end
		local f=floors[floorIndex] f.Spawn.Enabled=true owner.RespawnLocation=f.Spawn
		local root=character:WaitForChild("HumanoidRootPart")
		if character~=owner.Character then return end
		root.Anchored=false character:PivotTo(CFrame.new(f.Origin+Vector3.new(0,3,49)))
		Zombies.Configure(f.Zones)
		setPhase("FloorIntro",Config.Run.IntroDuration)
	end
	local function join(player)
		if owner then return end
		owner=player
		player.CharacterAdded:Connect(reset)
		if player.Character then task.spawn(reset,player.Character) end
	end
	options.OnServerEvent:Connect(function(player,open)
		if player~=owner or typeof(open)~="boolean" then return end
		player:SetAttribute("OptionsOpen",open)
		pause(open)
	end)
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		if player~=owner then return end
		Zombies.Clear() owner=nil pause(false) floorIndex,floorNumber,wave,spawned=1,1,0,0 setPhase("WaitingForPlayer")
	end)
	for _,p in Players:GetPlayers() do join(p) end
	for index,f in ipairs(floors) do
		f.Prompt.Triggered:Connect(function(player)
			local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart") local h=character and character:FindFirstChildOfClass("Humanoid")
			if player~=owner or phase~="ElevatorAvailable" or index~=floorIndex or Clock.Paused or not root or not h or h.Health<=0 or not Elevator.Inside(f,root.Position) then return end
			if Zombies.Count()~=0 or wave~=#Config.Run.Waves or spawned~=Config.Run.Waves[wave] then return end
			-- Snapshot activation once, secure passenger inside cabin before closing.
			player:SetAttribute("InElevatorTravel",true) root.AssemblyLinearVelocity=Vector3.zero root.Anchored=true character:PivotTo(f.Cabin)
			travelRoot=root travelStage="Closing" Elevator.SetOpen(f,false)
			setPhase("ElevatorTravel",Config.Run.DoorDuration)
		end)
	end
	local accumulator=0
	RunService.Heartbeat:Connect(function(dt)
		Clock.Step(dt) accumulator+=dt if accumulator<Config.Run.Tick then return end accumulator=0
		if not owner then return end
		local character=owner.Character local h=character and character:FindFirstChildOfClass("Humanoid") local root=character and character:FindFirstChild("HumanoidRootPart")
		if not h or h.Health<=0 or not root then
			if phase~="WaitingForPlayer" then Zombies.Clear() pause(false) setPhase("WaitingForPlayer") end return
		end
		if Clock.Paused then return end
		local now=Clock.Now() local f=floors[floorIndex]
		if phase=="FloorIntro" or phase=="BetweenWaves" then
			if now>=deadline then wave+=1 spawned=0 nextSpawn=now setPhase("WaveActive") end
		elseif phase=="WaveActive" then
			if spawned<Config.Run.Waves[wave] and now>=nextSpawn then
				nextSpawn=now+Config.Run.SpawnInterval
				if Zombies.Spawn() then spawned+=1 end
			end
			if spawned==Config.Run.Waves[wave] and Zombies.Count()==0 then
				if wave<#Config.Run.Waves then setPhase("BetweenWaves",Config.Run.BetweenWaves)
				else setPhase("FloorCleared",1) Audio.Play("ElevatorArrival",f.Indicator) end
			end
		elseif phase=="FloorCleared" and now>=deadline then
			Elevator.SetOpen(f,true) setPhase("ElevatorAvailable") f.Prompt.Enabled=true
		elseif phase=="ElevatorTravel" and now>=deadline then
			if travelStage=="Closing" then
				travelStage="Moving" Audio.Play("ElevatorTravel",f.Indicator) deadline=now+Config.Run.TravelDuration
			elseif travelStage=="Moving" then
				floorIndex=floorIndex%#floors+1 floorNumber+=1
				local target=floors[floorIndex] target.Spawn.Enabled=true f.Spawn.Enabled=false owner.RespawnLocation=target.Spawn
				Elevator.SetLabel(target,floorNumber)
				character:PivotTo(target.Cabin) root.AssemblyLinearVelocity=Vector3.zero
				Zombies.Configure(target.Zones) wave,spawned=0,0
				Elevator.SetOpen(target,true) Audio.Play("ElevatorArrival",target.Indicator)
				setPhase("NextFloor",Config.Run.DoorDuration)
			end
		elseif phase=="NextFloor" and now>=deadline then
			if travelRoot then travelRoot.Anchored=false travelRoot=nil owner:SetAttribute("InElevatorTravel",false) end
			-- Wait for actual exit, so arrival never traps the player behind closed doors.
			if root.Position.Z-f.Origin.Z<55 then
				Elevator.SetOpen(f,false) setPhase("FloorIntro",Config.Run.IntroDuration)
			end
		end
		publish()
	end)
	publish()
end
return FloorDirector
