local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Audio = require(game.ReplicatedStorage.Shared.Audio)
local ZombieRig = require(script.Parent.ZombieRig)

local Clock = require(script.Parent.RunClock)
local Progress = require(script.Parent.EncounterProgress)
local E = Config.Run.Encounters
local ZombieService = {}
local active, zones = {}, {}
local nextPlayerWindup = setmetatable({}, { __mode = "k" })
local rng = Random.new()
local settings = Config.Zombies
local bounds = { Origin=Vector3.zero, HalfWidth=settings.NavigationHalfExtent, HalfDepth=settings.NavigationHalfExtent }
local floorTuning = { Health=settings.MaxHealth, Speed=settings.WalkSpeed, Damage=settings.AttackDamage, MaxAlive=settings.MaxAlive }
local epoch, phasePlan, phaseProgress, spawning = 0, nil, nil, false
local diagnostics = {Failures=0,Reason="",FallbackSector="",Blocked=false}
local fallbackSector, fallbackReady
local navigationNodes={}
local spawnSerial=0
local recover


local function setState(data, state, now)
	if data.state == "Dead" then return end
	data.state = state
	data.stateSince = now or Clock.Now()
	data.rig.model:SetAttribute("State", state)
	data.rig.model:SetAttribute("Attacking", state == "AttackWindup" or state == "AttackRecover")
end

local function nearestTarget(position)
	local best, bestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < settings.AggroRange and (not bestDistance or distance < bestDistance) then
				best, bestDistance = { humanoid = humanoid, root = root }, distance
			end
		end
	end
	return best, bestDistance
end

local function separationFor(data)
	local force = Vector3.zero
	for model, other in pairs(active) do
		if other ~= data and model.Parent then
			local delta = data.rig.root.Position - other.rig.root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local distance = flat.Magnitude
			if distance < settings.PersonalSpace then
				force += (distance > 0.05 and flat.Unit or data.approach) * (settings.PersonalSpace - distance) / settings.PersonalSpace
			end
		end
	end
	return (force.Magnitude > 1 and force.Unit or force) * settings.SeparationStrength
end

local function clampArena(position)
	local p=position-bounds.Origin
	return bounds.Origin+Vector3.new(math.clamp(p.X,-bounds.HalfWidth,bounds.HalfWidth),p.Y,math.clamp(p.Z,-bounds.HalfDepth,bounds.HalfDepth))
end

local function directSight(data, target, now)
	if now < data.nextSight and data.sightTarget == target.root then return data.hasSight end
	data.nextSight = now + settings.DirectSightInterval + rng:NextNumber(0, 0.15)
	data.sightTarget = target.root
	local excluded = {}
	for model in pairs(active) do table.insert(excluded, model) end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.IgnoreWater = true
	local origin = data.rig.root.Position + Vector3.new(0, 1, 0)
	local result = workspace:Raycast(origin, target.root.Position + Vector3.new(0, 1, 0) - origin, params)
	data.hasSight = not result or result.Instance:IsDescendantOf(target.root.Parent)
	return data.hasSight
end

local function navigate(data, destination, target, now)
	local rig = data.rig
	-- Seeing an upper gallery does not mean a straight walk can reach it.
	if (destination-target.root.Position).Magnitude<10 and math.abs(rig.root.Position.Y-destination.Y)<2.5 and directSight(data, target, now) then
		data.waypoints = nil
		rig.humanoid:MoveTo(destination)
		return
	end
	if now >= data.nextPath then
		data.nextPath = now + settings.RepathInterval + rng:NextNumber(0, 0.25)
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
		local ok = pcall(function() path:ComputeAsync(rig.root.Position, destination) end)
		if not rig.model.Parent or rig.humanoid.Health <= 0 or data.epoch~=epoch then return end
		if ok and path.Status == Enum.PathStatus.Success then
			data.waypoints = path:GetWaypoints()
			data.waypointIndex = math.min(2, #data.waypoints)
		else
			data.waypoints = nil
		end
	end
	local waypoint = data.waypoints and data.waypoints[data.waypointIndex]
	if waypoint and (waypoint.Position - rig.root.Position).Magnitude < 3 then
		data.waypointIndex += 1
		waypoint = data.waypoints[data.waypointIndex]
	end
	if waypoint and waypoint.Action == Enum.PathWaypointAction.Jump then rig.humanoid.Jump = true end
	rig.humanoid:MoveTo(waypoint and waypoint.Position or rig.root.Position)
end

local function interceptDestination(data,target,distance)
	if not data.intercept or distance<20 then return nil end
	local velocity=target.root.AssemblyLinearVelocity
	local flat=Vector3.new(velocity.X,0,velocity.Z)
	if flat.Magnitude<settings.InterceptMinSpeed then return nil end
	local predicted=target.root.Position+flat*settings.InterceptLookAhead
	local best,score
	for _,node in navigationNodes do
		local toward=node-target.root.Position
		if math.abs(toward.Y)<4 and toward.Magnitude>12 and toward:Dot(flat.Unit)>12 then
			local value=(node-predicted).Magnitude+.2*(node-data.rig.root.Position).Magnitude
			if not score or value<score then best,score=node,value end
		end
	end
	return best
end

local function attackStep(data, target, distance, now)
	local rig = data.rig
	if data.state == "AttackWindup" then
		rig.humanoid:MoveTo(rig.root.Position)
		if target then
			local toward = target.root.Position - rig.root.Position
			if Vector3.new(toward.X, 0, toward.Z).Magnitude > 0.1 then
				rig.root.CFrame = CFrame.lookAt(rig.root.Position, Vector3.new(target.root.Position.X, rig.root.Position.Y, target.root.Position.Z))
			end
		end
		if now - data.stateSince >= settings.AttackWindup then
			setState(data, "AttackRecover", now)
			if target and target.humanoid == data.attackTarget and target.humanoid.Health > 0 and distance <= settings.AttackRange + 0.65 and directSight(data, target, now) then
				target.humanoid:TakeDamage(data.attackDamage)
			end
		end
		return true
	elseif data.state == "AttackRecover" then
		if now - data.stateSince >= settings.AttackRecover then setState(data, "Chase", now) end
		return true
	end
	return false
end

local function runAI(data)
	local rig = data.rig
	while rig.model.Parent and rig.humanoid.Health > 0 and data.state ~= "Dead" do
		if Clock.Paused then task.wait(settings.ThinkInterval) continue end
		if data.epoch~=epoch then break end
		if rig.root.Position.Y<bounds.Origin.Y-10 then recover(data,"Fell below floor") break end
		local now = Clock.Now()
		local target, distance = nearestTarget(rig.root.Position)
		if data.state == "Spawn" and now - data.stateSince >= settings.SpawnFade then setState(data, "Idle", now) end
		if data.state == "HitReact" and now >= data.reactUntil then setState(data, "Chase", now) end
		if data.state ~= "Spawn" and data.state ~= "HitReact" then
			if not target then
				if data.state ~= "Idle" then setState(data, "Idle", now) end
				rig.humanoid:MoveTo(rig.root.Position)
			elseif not attackStep(data, target, distance, now) then
				if data.state ~= "Chase" then setState(data, "Chase", now) end
				local separation = separationFor(data)
				if distance <= settings.AttackRange and directSight(data,target,now) then
					local away = rig.root.Position - target.root.Position
					local flat = Vector3.new(away.X, 0, away.Z)
					local retreat = flat.Magnitude < settings.PreferredMinDistance
						and (flat.Magnitude > 0.05 and flat.Unit or data.approach) * (settings.PreferredMinDistance - flat.Magnitude) or Vector3.zero
					rig.humanoid:MoveTo(clampArena(rig.root.Position + retreat + separation))
					if now >= data.nextAttack and now >= (nextPlayerWindup[target.humanoid] or 0) then
						nextPlayerWindup[target.humanoid] = now + settings.AttackCoordinationInterval
						data.nextAttack = now + settings.AttackCooldown
						data.attackTarget = target.humanoid
						setState(data, "AttackWindup", now)
						Audio.Play("ZombieAttack", rig.torso)
					end
				else
					local offset=distance>settings.AttackRange and data.approach*settings.ApproachSpacing or Vector3.zero
					local interception=interceptDestination(data,target,distance)
					if data.rig.model:GetAttribute("Intercepting")~=(interception~=nil) then data.rig.model:SetAttribute("Intercepting",interception~=nil) end
					local destination = interception or clampArena(target.root.Position + offset + separation)
					navigate(data, destination, target, now)
				end
			end
		end
		if not rig.model.Parent or rig.humanoid.Health <= 0 then break end
		if now >= data.nextGroan then
			data.nextGroan = now + rng:NextNumber(settings.IdleGroanMin, settings.IdleGroanMax)
			Audio.Play("ZombieIdle", rig.torso)
		end
		if target and distance > settings.AttackRange + 2 then
			if (rig.root.Position - data.lastPosition).Magnitude < 0.35 and now - data.lastMovedAt > 1.5 then
				data.nextPath, data.nextSight = 0, 0
				rig.humanoid.Jump = true
				data.lastMovedAt = now
			elseif (rig.root.Position - data.lastPosition).Magnitude >= 0.35 then
				data.lastPosition, data.lastMovedAt = rig.root.Position, now
				data.stuckSince=now
			end
		else
			data.lastPosition, data.lastMovedAt = rig.root.Position, now
			data.stuckSince=now
		end
		if target and distance>settings.AttackRange+2 and now-data.stuckSince>E.StuckRecoverAfter then recover(data,"Navigation stalled") break end
		if target and now-data.stuckSince>E.StuckRepathAfter then data.nextPath=0 end
		ZombieRig.Pose(rig, data.state, now, math.clamp((data.reactUntil - now) / data.reactDuration, 0, 1), data.hitSide)
		task.wait(settings.ThinkInterval)
	end
end

local function onDeath(data)
	if data.state == "Dead" then return end
	local rig = data.rig
	active[rig.model] = nil
	if data.epoch==epoch and data.progress then Progress.Defeated(data.progress) end

	setState(data, "Dead")
	rig.model:SetAttribute("Dead", true)
	rig.model:SetAttribute("Attacking", false)
	for _, part in ipairs({ rig.head, rig.torso }) do
		local base = part:GetAttribute("BaseColor")
		if base then part.Color = base end
	end
	Audio.Play("ZombieDeath", rig.torso)
	ZombieRig.Die(rig, rig.model:GetAttribute("FatalHeadshot") == true, rng:NextInteger(-25, 25))
	Debris:AddItem(rig.model, settings.CorpseLifetime)
end

recover=function(data,reason)
	if data.state=="Dead" then return end
	active[data.rig.model]=nil
	setState(data,"Dead")
	if data.epoch==epoch and data.progress then
		Progress.Requeue(data.progress)
		diagnostics.Reason=reason; diagnostics.Recovered=(diagnostics.Recovered or 0)+1
		if data.progress.Requeued>=E.MaxRequeues then diagnostics.Blocked=true; warn("Zombie recovery limit: "..reason) end
	end
	data.rig.model:Destroy()
end

function ZombieService.React(model, headshot, shotDirection)
	local data = active[model]
	if not data then return end
	local now = Clock.Now()
	data.reactDuration = headshot and settings.HeadReactDuration or settings.HitReactDuration
	data.reactUntil = now + data.reactDuration
	data.hitSide = shotDirection and math.sign(data.rig.root.CFrame.RightVector:Dot(shotDirection)) or 1
	ZombieRig.React(data.rig, headshot)
	local part = headshot and data.rig.head or data.rig.torso
	local original = part:GetAttribute("BaseColor") or part.Color
	part:SetAttribute("BaseColor", original)
	part.Color = headshot and Color3.fromRGB(236, 196, 147) or Color3.fromRGB(159, 83, 76)
	data.reactionSerial += 1
	local serial = data.reactionSerial
	task.delay(data.reactDuration, function()
		if part.Parent and data.reactionSerial == serial and data.state ~= "Dead" then part.Color = original end
	end)
	if now >= data.nextHurtSound then
		data.nextHurtSound = now + settings.HurtSoundCooldown
		Audio.Play("ZombieHurt", data.rig.torso)
	end
	if headshot or (data.state ~= "AttackWindup" and data.state ~= "AttackRecover") then
		setState(data, "HitReact", now)
		data.rig.humanoid:MoveTo(data.rig.root.Position)
	end
end

local function validSpawn(point)
	local nearestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - point).Magnitude
			if distance < settings.MinSpawnDistance then return false end
			nearestDistance = math.min(nearestDistance or math.huge, distance)
		end
	end
	if not nearestDistance or nearestDistance > settings.MaxSpawnDistance then return false end
	local arena = workspace:FindFirstChild("OfficeRun")
	if arena then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { arena }
		for _, item in ipairs(workspace:GetPartBoundsInBox(CFrame.new(point + Vector3.new(0, 2.5, 0)), Vector3.new(3.3, 4, 3.3), params)) do
			if item.CanCollide and item.Name ~= "Floor" then return false end
		end
	end
	for _, data in pairs(active) do
		if (data.rig.root.Position - point).Magnitude < settings.SpawnSeparation then return false end
	end
	return true
end

local function visibleSpawn(point)
	local excluded={}
	for _,p in Players:GetPlayers() do if p.Character then table.insert(excluded,p.Character) end end
	for m in active do table.insert(excluded,m) end
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances=excluded
	for _,p in Players:GetPlayers() do
		local head=p.Character and p.Character:FindFirstChild("Head")
		if head then local toward=point+Vector3.new(0,3,0)-head.Position
			if toward.Magnitude>0 and head.CFrame.LookVector:Dot(toward.Unit)>.2 and not workspace:Raycast(head.Position,toward,params) then return true end
		end
	end
	return false
end
local function chooseSpawn(directions)
	local candidates={}
	for _, zone in ipairs(zones) do
		if phasePlan and (not table.find(directions,zone.AttackDirection) or not table.find(zone.AllowedPhases,phasePlan.Id)) then continue end
		for _ = 1, 3 do
			local point = zone.Position + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
			if validSpawn(point) and not visibleSpawn(point) then
				local score = rng:NextNumber(0, 1)*(zone.Weight or 1)
				for _, player in ipairs(Players:GetPlayers()) do
					local head = player.Character and player.Character:FindFirstChild("Head")
					if head then
						local toward = point - head.Position
						if toward.Magnitude > 0 then score -= math.max(0, head.CFrame.LookVector:Dot(toward.Unit)) * 1.2 end
					end
				end
				table.insert(candidates,{Point=point,Score=score,Zone=zone})
			end
		end
	end
	table.sort(candidates,function(a,b) return a.Score>b.Score end)
	local token=epoch
	for i=1,math.min(4,#candidates) do
		local c=candidates[i]; local target=nearestTarget(c.Point)
		if target then
			local path=PathfindingService:CreatePath({AgentRadius=Config.Run.Generation.AgentRadius,AgentHeight=Config.Run.Generation.AgentHeight,AgentCanJump=true})
			local ok=pcall(function() path:ComputeAsync(c.Point+Vector3.new(0,3,0),target.root.Position) end)
			if token~=epoch then return nil end
			if ok and path.Status==Enum.PathStatus.Success and validSpawn(c.Point) and not visibleSpawn(c.Point) then return c.Point,c.Zone end
		end
	end
	return nil
end

local function assignPlayerCollision(character)
	local function assign(item)
		if item:IsA("BasePart") then item.CollisionGroup = "Players" end
	end
	for _, item in ipairs(character:GetDescendants()) do assign(item) end
	character.DescendantAdded:Connect(assign)
end

function ZombieService.Start(spawnZones)
	zones = spawnZones
	for _, name in ipairs({ "Zombies", "Players" }) do
		if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
	end
	PhysicsService:CollisionGroupSetCollidable("Zombies", "Zombies", false)
	PhysicsService:CollisionGroupSetCollidable("Zombies", "Players", false)
	local function preparePlayer(player)
		player.CharacterAdded:Connect(assignPlayerCollision)
		if player.Character then assignPlayerCollision(player.Character) end
	end
	Players.PlayerAdded:Connect(preparePlayer)
	for _, player in ipairs(Players:GetPlayers()) do preparePlayer(player) end
end

function ZombieService.Configure(spawnZones, floorBounds, number, nodes)
	epoch+=1; spawning=false; phasePlan=nil; phaseProgress=nil
	zones = spawnZones
	if floorBounds then bounds=floorBounds end
	navigationNodes={}; spawnSerial=0
	for _,n in nodes or {} do table.insert(navigationNodes,bounds.Origin+Vector3.new(n.X,n.Y+3,n.Z)) end
	local d=Config.Run.Difficulty
	local extra=math.max(0,(number or 1)-1)
	floorTuning={
		Health=settings.MaxHealth*math.min(1+extra*d.HealthPerFloor/settings.MaxHealth,d.MaxHealthMultiplier),
		Speed=math.min(settings.WalkSpeed+extra*d.SpeedPerFloor,d.MaxSpeed),
		Damage=math.min(settings.AttackDamage+extra*d.DamagePerFloor,d.MaxDamage),
		MaxAlive=math.min(d.BaseAlive+math.floor(extra/d.ExtraAliveEvery),d.MaxAlive),
	}
end
function ZombieService.BeginPhase(plan,progress)
	phasePlan=table.clone(plan); phasePlan.Directions=table.clone(plan.Directions); phaseProgress=progress; fallbackSector=nil; fallbackReady=nil
	diagnostics={Failures=0,Reason="",FallbackSector="",Blocked=false}
end
function ZombieService.ActivateDirection(sector)
	if phasePlan and sector==phasePlan.ScheduledDirection and not table.find(phasePlan.Directions,sector) then table.insert(phasePlan.Directions,sector) end
end
function ZombieService.Diagnostics() return diagnostics end
function ZombieService.HasPressure(position)
	for _,data in active do if data.rig.humanoid.Health>0 and (data.rig.root.Position-position).Magnitude<90 then return true end end
	return false
end
function ZombieService.Count()
	local count = 0
	for model, data in pairs(active) do
		if model.Parent and data.rig.humanoid.Health > 0 then count += 1
		elseif not model.Parent then recover(data,"Model removed without a kill") end
	end
	return count
end
function ZombieService.Clear()
	epoch+=1; phasePlan=nil; phaseProgress=nil; spawning=false
	diagnostics={Failures=0,Reason="",FallbackSector="",Blocked=false}; fallbackSector=nil; fallbackReady=nil
	for model, data in pairs(active) do
		data.state = "Dead"
		model:Destroy()
	end
	table.clear(active)
	table.clear(nextPlayerWindup)
	for _,m in workspace:GetChildren() do if m:GetAttribute("IsZombie") then m:Destroy() end end
end
function ZombieService.SetPaused(paused)
	for _,data in pairs(active) do
		data.rig.root.Anchored = paused
		if not paused then data.rig.root:SetNetworkOwner(nil) end
		ZombieRig.Pause(data.rig, paused)
	end
end
function ZombieService.Spawn(preferredSector)
	if Clock.Paused or spawning or diagnostics.Blocked or not phaseProgress or phaseProgress.Pending<=0 or ZombieService.Count() >= floorTuning.MaxAlive then return false end
	spawning=true
	local token,progress=epoch,phaseProgress
	local directions=preferredSector and table.find(phasePlan.Directions,preferredSector) and {preferredSector} or table.clone(phasePlan.Directions)
	if fallbackSector and Clock.Now()>=(fallbackReady or math.huge) then table.insert(directions,fallbackSector) end
	local ok,point,zone=pcall(chooseSpawn,directions)
	if token~=epoch then return false end
	spawning=false
	if not ok or not point then
		diagnostics.Failures+=1; diagnostics.Reason=ok and "No safe reachable spawn" or tostring(point)
		diagnostics.Since=diagnostics.Since or Clock.Now()
		if diagnostics.Failures>=E.FallbackAfter and #phasePlan.FallbackDirections>0 and (not fallbackSector or Clock.Now()>(fallbackReady or 0)+E.SpawnWarningAfter) then
			diagnostics.FallbackIndex=((diagnostics.FallbackIndex or 0)%#phasePlan.FallbackDirections)+1
			fallbackSector=phasePlan.FallbackDirections[diagnostics.FallbackIndex]; fallbackReady=Clock.Now()+E.WarningDuration
			diagnostics.FallbackSector=fallbackSector; diagnostics.FallbackReady=fallbackReady
		end
		if diagnostics.Since and Clock.Now()-diagnostics.Since>E.SpawnWarningAfter and not diagnostics.Warned then
			diagnostics.Warned=true; warn("Spawn delayed; obligations retained: "..diagnostics.Reason)
		end
		return false
	end
	diagnostics.Since=nil; diagnostics.Reason=""; diagnostics.Failures=0
	local rig = ZombieRig.Create(point, rng:NextInteger(1,10),floorTuning)
	spawnSerial+=1
	Progress.Spawned(progress)
	rig.model:SetAttribute("SpawnZone",zone.Id); rig.model:SetAttribute("AttackDirection",zone.AttackDirection)
	local angle, now = rng:NextNumber(-math.pi, math.pi), Clock.Now()
	local data = {
		rig=rig, epoch=token, progress=progress, intercept=spawnSerial%3==0, stuckSince=now, attackDamage=floorTuning.Damage, state="Spawn", stateSince=now, approach=Vector3.new(math.cos(angle),0,math.sin(angle)),
		nextAttack=now+0.7, nextPath=0, nextSight=0, nextHurtSound=0,
		nextGroan=now+rng:NextNumber(settings.IdleGroanMin,settings.IdleGroanMax),
		reactUntil=0, reactDuration=1, hitSide=0, reactionSerial=0,
		lastPosition=rig.root.Position, lastMovedAt=now,
	}
	active[rig.model]=data
	rig.humanoid.Died:Connect(function() onDeath(data) end)
	task.spawn(runAI,data)
	return true
end
return ZombieService
