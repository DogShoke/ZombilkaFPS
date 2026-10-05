local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Shared.Config)
local Audio=require(ReplicatedStorage.Shared.Audio)
local Clock=require(script.Parent.RunClock)
local Zombies=require(script.Parent.ZombieService)
local Elevator=require(script.Parent.ElevatorService)
local OfficeMap=require(script.Parent.OfficeMap)
local Progress=require(script.Parent.EncounterProgress)
local E=Config.Run.Encounters
local Director={}
function Director.Start(map)
	local state=Instance.new("Folder"); state.Name="RunState"; state.Parent=ReplicatedStorage
	local owner,current=nil,map.Current
	local floorNumber,wave,nextSpawn,deadline=1,0,0,0
	local phase="WaitingForPlayer"
	local generation,completed,subscriptions=0,{},{}
	local progress,travelStage,travelRoot,spawnBusy,rebuilding,holding
	local fronts,phaseStarted,flankWarning,flankStarted,flankActive={},0,nil,false,false
	local flankIssued=0
	local connectFloor
	local function plan() return current.Layout.Encounter.Phases[wave] end
	local function allComplete()
		for i=1,#current.Layout.Encounter.Phases do if not completed[i] then return false end end
		return progress~=nil and progress.Complete and progress.Pending==0 and progress.Alive==0 and progress.Defeated==progress.Budget and Zombies.Count()==0
	end
	local function directionText(directions)
		local names={}; for _,d in directions or {} do table.insert(names,E.SectorLabels[d]) end
		return table.concat(names," + ")
	end
	local function publish()
		local p=plan(); local d=Zombies.Diagnostics()
		state:SetAttribute("State",phase); state:SetAttribute("Floor",floorNumber); state:SetAttribute("LayoutIndex",current.Slot)
		state:SetAttribute("Theme",current.Layout.Label); state:SetAttribute("Macro",current.Layout.Macro); state:SetAttribute("MacroLabel",current.Layout.MacroLabel)
		state:SetAttribute("GenerationVersion",current.Layout.GenerationVersion); state:SetAttribute("Seed",current.Layout.Seed); state:SetAttribute("RunSeed",map.Seed); state:SetAttribute("Levels",current.Layout.Upper and 2 or 1)
		state:SetAttribute("Wave",wave); state:SetAttribute("Waves",#current.Layout.Encounter.Phases)
		state:SetAttribute("WaveBudget",progress and progress.Budget or 0); state:SetAttribute("Alive",Zombies.Count())
		state:SetAttribute("Pending",progress and progress.Pending or 0); state:SetAttribute("Defeated",progress and progress.Defeated or 0)
		state:SetAttribute("Remaining",progress and progress.Pending+progress.Alive or 0); state:SetAttribute("Spawned",progress and progress.Issued or 0)
		state:SetAttribute("EncounterMode",p and p.Mode or current.Layout.Encounter.Mode)
		state:SetAttribute("ObjectiveElapsed",progress and progress.Elapsed or 0); state:SetAttribute("ObjectiveDuration",progress and progress.Duration or 0)
		state:SetAttribute("DefenseId",p and p.DefenseId or ""); state:SetAttribute("DefenseLabel",p and p.DefenseLabel or ""); state:SetAttribute("Holding",holding==true)
		state:SetAttribute("AttackDirections",directionText(fronts))
		state:SetAttribute("FlankWarning",flankWarning and p and directionText({p.ScheduledDirection}) or "")
		state:SetAttribute("FallbackDirection",d.FallbackSector~="" and directionText({d.FallbackSector}) or "")
		state:SetAttribute("SpawnDiagnostic",d.Reason); state:SetAttribute("SpawnFailures",d.Failures)
		state:SetAttribute("CombatBlocked",d.Blocked); state:SetAttribute("Paused",Clock.Paused)
		state:SetAttribute("FloorComplete",allComplete())
		local reason=allComplete() and "" or wave<#current.Layout.Encounter.Phases and "ЗАВЕРШИТЕ ВСЕ ВОЛНЫ" or progress and progress.Elapsed<progress.Duration and "ЗАВЕРШИТЕ БОЕВУЮ ЗАДАЧУ" or "УНИЧТОЖЬТЕ ОСТАВШИХСЯ ЗОМБИ"
		state:SetAttribute("ElevatorLockReason",reason)
	end
	local function setPhase(value,delay) phase=value; deadline=Clock.Now()+(delay or 0); publish() end
	local function configureFloor() Zombies.Configure(current.Zones,current.Bounds,floorNumber,current.Layout.Nodes) end
	local function clearNext() if map.Next then map.Next.Model:Destroy(); map.Next=nil end end
	local function cancelCombat()
		generation+=1; spawnBusy=false; progress=nil; completed={}; wave=0
		Zombies.Clear(); clearNext(); Clock.Paused=false
		if travelRoot and travelRoot.Parent then travelRoot.Anchored=false end
		travelRoot=nil; travelStage=nil
		OfficeMap.SetDirections(current,{}); OfficeMap.SetObjective(current,nil); holding=false
		fronts={}; flankWarning=nil; flankStarted=false; flankActive=false; flankIssued=0
	end
	local function reset(character)
		local player=owner
		if not player then return end
		cancelCombat(); player:SetAttribute("InElevatorTravel",false)
		Elevator.SetOpen(current,false); current.Spawn.Enabled=true; player.RespawnLocation=current.Spawn
		local token=generation; local root=character:WaitForChild("HumanoidRootPart",10)
		if not root or owner~=player or character~=player.Character or token~=generation then return end
		root.Anchored=false; character:PivotTo(current.Entry); configureFloor()
		-- CharacterAdded callback order is not guaranteed; WeaponService clears selection too.
		-- Always wait for a new accepted choice after a respawn.
		setPhase("ChoosingWeapon")
	end
	connectFloor=function(f)
		f.Prompt.Triggered:Connect(function(player) Director.TryTravel(player,f) end)
	end
	Director.TryTravel=function(player,f)
		f=f or current
		if player~=owner or f~=current or phase~="ElevatorAvailable" or Clock.Paused or not allComplete() then return false end
		local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local h=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not h or h.Health<=0 or not Elevator.Inside(f,root.Position) or not map.Next then return false end
		player:SetAttribute("InElevatorTravel",true); root.AssemblyLinearVelocity=Vector3.zero; root.Anchored=true; character:PivotTo(f.Cabin)
		travelRoot=root; travelStage="Closing"; Elevator.SetOpen(f,false); setPhase("ElevatorTravel",Config.Run.DoorDuration)
		return true
	end
	connectFloor(current)
	local function join(player)
		if owner or rebuilding then return end
		owner=player; state:SetAttribute("OwnerUserId",player.UserId)
		table.insert(subscriptions,player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
			if owner==player and phase=="ChoosingWeapon" and Config.Weapons[player:GetAttribute("SelectedWeapon")] then setPhase("FloorIntro",Config.Run.IntroDuration) end
		end))
		table.insert(subscriptions,player.CharacterAdded:Connect(reset))
		if player.Character then task.spawn(reset,player.Character) end
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		if player~=owner then return end
		cancelCombat(); for _,c in subscriptions do c:Disconnect() end; subscriptions={}; owner=nil; floorNumber=1; rebuilding=true
		current.Model:Destroy(); setPhase("WaitingForPlayer")
		local token=generation
		task.spawn(function()
			local f=OfficeMap.CreateFloor(map,1,1)
			if token~=generation then f.Model:Destroy() return end
			current=f; map.Current=f; connectFloor(f); state:SetAttribute("OwnerUserId",nil); rebuilding=false; publish()
			for _,p in Players:GetPlayers() do join(p) end
		end)
	end)
	for _,p in Players:GetPlayers() do join(p) end
	local function insideDefense(root,p)
		for _,d in current.DefenseZones do if d.Id==p.DefenseId then
			local v=root.Position-d.Position; return math.abs(v.X)<=d.Width/2 and math.abs(v.Z)<=d.Depth/2 and v.Y>-1 and v.Y<7
		end end
		return false
	end
	local function prepareNext()
		setPhase("PreparingFloor"); local token=generation; local source=current
		task.spawn(function()
			local ok,f=pcall(OfficeMap.CreateFloor,map,floorNumber+1,source.Slot%2+1)
			if token~=generation or source~=current then if ok then f.Model:Destroy() end return end
			if not ok then warn(f); setPhase("GenerationFailed") return end
			map.Next=f; connectFloor(f); setPhase("FloorCleared",1); Audio.Play("ElevatorArrival",source.Indicator)
		end)
	end
	local accumulator=0
	RunService.Heartbeat:Connect(function(dt)
		Clock.Step(dt); accumulator+=dt; if accumulator<Config.Run.Tick then return end
		local step=accumulator; accumulator=0
		if not owner then return end
		local character=owner.Character; local h=character and character:FindFirstChildOfClass("Humanoid"); local root=character and character:FindFirstChild("HumanoidRootPart")
		if not h or h.Health<=0 or not root then
			if phase~="WaitingForPlayer" then cancelCombat(); setPhase("WaitingForPlayer") end
			return
		end
		if Clock.Paused then return end
		local now=Clock.Now(); local f=current
		if (phase=="FloorIntro" or phase=="BetweenWaves") and now>=deadline then
			wave+=1; progress=Progress.New(plan()); fronts=table.clone(plan().Directions); flankWarning=nil; flankStarted=false; flankActive=false; flankIssued=0; OfficeMap.SetDirections(current,fronts)
			OfficeMap.SetObjective(current,plan().Mode=="Holdout" and plan().DefenseId or nil)
			Audio.Play("ElevatorArrival",f.Indicator); setPhase("WaveWarning",E.WarningDuration)
		elseif phase=="WaveWarning" and now>=deadline then
			Zombies.BeginPhase(plan(),progress); phaseStarted=now; nextSpawn=now; setPhase("WaveActive")
		elseif phase=="WaveActive" then
			if plan().ScheduledDirection and not flankStarted and now-phaseStarted>=E.FlankAfter then
				flankStarted=true; flankWarning=now+E.WarningDuration
				local signals=table.clone(fronts); table.insert(signals,plan().ScheduledDirection); OfficeMap.SetDirections(f,signals); Audio.Play("ElevatorArrival",f.Indicator)
			end
			if flankWarning and now>=flankWarning then
				flankWarning=nil; flankActive=true; table.insert(fronts,plan().ScheduledDirection); Zombies.ActivateDirection(plan().ScheduledDirection)
			end
			local d=Zombies.Diagnostics()
			Progress.EnsurePressure(progress,E.HoldReinforcements)
			local healthy=not d.Blocked and (not d.Since or now-d.Since<E.SpawnFailureGrace)
			holding=insideDefense(root,plan())
			Progress.Step(progress,step,now,holding,healthy,E.PressureGrace,Zombies.HasPressure(root.Position))
			local difficulty=Config.Run.Difficulty
			local maxAlive=math.min(difficulty.BaseAlive+math.floor((floorNumber-1)/difficulty.ExtraAliveEvery),difficulty.MaxAlive)
			local reserveLocked=plan().ScheduledDirection and not flankActive and (progress.Pending<=plan().Reserve or progress.Alive>=maxAlive-plan().Reserve)
			if progress.Pending>0 and not reserveLocked and now>=nextSpawn and not spawnBusy then
				nextSpawn=now+Config.Run.SpawnInterval; spawnBusy=true
				local token=generation
				local preferred=flankActive and flankIssued<plan().Reserve and plan().ScheduledDirection or nil
				task.spawn(function()
					local spawned=Zombies.Spawn(preferred)
					if generation==token then spawnBusy=false; if preferred and spawned then flankIssued+=1 end end
				end)
			end
			if d.FallbackSector~="" then local dirs=table.clone(fronts); table.insert(dirs,d.FallbackSector); if flankWarning then table.insert(dirs,plan().ScheduledDirection) end; OfficeMap.SetDirections(f,dirs) end
			if progress.Complete then
				completed[wave]=true; OfficeMap.SetDirections(f,{})
				if wave<#f.Layout.Encounter.Phases then setPhase("BetweenWaves",Config.Run.BetweenWaves) else prepareNext() end
			end
		elseif phase=="FloorCleared" and now>=deadline then
			if allComplete() then Elevator.SetOpen(f,true); setPhase("ElevatorAvailable"); f.Prompt.Enabled=true end
		elseif phase=="ElevatorTravel" and now>=deadline then
			if travelStage=="Closing" then travelStage="Moving"; Audio.Play("ElevatorTravel",f.Indicator); deadline=now+Config.Run.TravelDuration
			elseif travelStage=="Moving" then
				current=map.Next; map.Current=current; map.Next=nil; floorNumber+=1; generation+=1
				current.Spawn.Enabled=true; owner.RespawnLocation=current.Spawn; Elevator.SetLabel(current,floorNumber)
				character:PivotTo(current.Cabin); root.AssemblyLinearVelocity=Vector3.zero; f.Model:Destroy()
				progress=nil; completed={}; wave=0; spawnBusy=false; fronts={}; flankWarning=nil; configureFloor()
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
return Director
