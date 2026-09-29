local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local ZombieService = {}
local active = {}
local zones = {}
local rng = Random.new()

local function makePart(model, name, size, color, collidable)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Color = color
	item.Material = Enum.Material.SmoothPlastic
	item.CanCollide = collidable
	item.CollisionGroup = "Zombies"
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = model
	return item
end

local function joint(parent, name, a, b, offset)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = a
	motor.Part1 = b
	motor.C0 = CFrame.new(offset)
	motor.Parent = parent
	return motor
end

local function playSound(key, parent)
	local id = Config.Audio[key]
	if not id or id == "" or not parent then return end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.8
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 6)
end

local function makeZombie(position)
	local model = Instance.new("Model")
	model.Name = "Zombie"
	model:SetAttribute("IsZombie", true)
	local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1), false)
	root.Transparency = 1
	local torso = makePart(model, "Torso", Vector3.new(2, 2, 1), Color3.fromRGB(79, 99, 77), false)
	local head = makePart(model, "Head", Vector3.new(1.5, 1.3, 1.3), Color3.fromRGB(110, 145, 101), false)
	local leftArm = makePart(model, "Left Arm", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(101, 132, 91), false)
	local rightArm = makePart(model, "Right Arm", Vector3.new(0.8, 2, 0.8), Color3.fromRGB(101, 132, 91), false)
	local leftLeg = makePart(model, "Left Leg", Vector3.new(0.9, 2, 0.9), Color3.fromRGB(46, 55, 55), true)
	local rightLeg = makePart(model, "Right Leg", Vector3.new(0.9, 2, 0.9), Color3.fromRGB(46, 55, 55), true)
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.Zombies.Health
	humanoid.Health = Config.Zombies.Health
	humanoid.WalkSpeed = Config.Zombies.WalkSpeed
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	joint(root, "RootJoint", root, torso, Vector3.zero)
	joint(torso, "Neck", torso, head, Vector3.new(0, 1.65, 0))
	joint(torso, "Left Shoulder", torso, leftArm, Vector3.new(-1.4, 0, 0))
	joint(torso, "Right Shoulder", torso, rightArm, Vector3.new(1.4, 0, 0))
	joint(torso, "Left Hip", torso, leftLeg, Vector3.new(-0.52, -2, 0))
	joint(torso, "Right Hip", torso, rightLeg, Vector3.new(0.52, -2, 0))
	model.PrimaryPart = root
	model.Parent = workspace
	model:PivotTo(CFrame.new(position + Vector3.new(0, 2.1, 0)))
	root:SetNetworkOwner(nil)
	return model, humanoid, root
end

local function nearestTarget(position)
	local best, bestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < Config.Zombies.AggroRange and (not bestDistance or distance < bestDistance) then
				best, bestDistance = { humanoid = humanoid, root = root }, distance
			end
		end
	end
	return best, bestDistance
end

local function crowdSeparation(model, root, approachAngle)
	local separation = Vector3.zero
	for other in pairs(active) do
		if other ~= model and other.Parent then
			local otherRoot = other:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local delta = root.Position - otherRoot.Position
				local horizontal = Vector3.new(delta.X, 0, delta.Z)
				local distance = horizontal.Magnitude
				if distance < Config.Zombies.SeparationRadius then
					local direction = distance > 0.05 and horizontal.Unit or Vector3.new(math.cos(approachAngle), 0, math.sin(approachAngle))
					separation += direction * (Config.Zombies.SeparationRadius - distance) / Config.Zombies.SeparationRadius
				end
			end
		end
	end
	return separation.Magnitude > 1 and separation.Unit or separation
end

local function insideArena(position)
	local half = Config.Zombies.NavigationHalfExtent
	return Vector3.new(math.clamp(position.X, -half, half), position.Y, math.clamp(position.Z, -half, half))
end

local function runAI(model, humanoid, root)
	local nextAttack = 0
	local nextPath = 0
	local waypointPosition
	local approachAngle = model:GetAttribute("ApproachAngle") or 0
	while model.Parent and humanoid.Health > 0 do
		local target, distance = nearestTarget(root.Position)
		if target then
			local separation = crowdSeparation(model, root, approachAngle)
			if distance <= Config.Zombies.AttackRange then
				local away = Vector3.new(root.Position.X - target.root.Position.X, 0, root.Position.Z - target.root.Position.Z)
				local retreat = Vector3.zero
				if away.Magnitude < Config.Zombies.PreferredMinDistance then
					local direction = away.Magnitude > 0.05 and away.Unit or Vector3.new(math.cos(approachAngle), 0, math.sin(approachAngle))
					retreat = direction * (Config.Zombies.PreferredMinDistance - away.Magnitude)
				end
				humanoid:MoveTo(insideArena(root.Position + retreat + separation * Config.Zombies.SeparationStrength))
				if os.clock() >= nextAttack then
					nextAttack = os.clock() + Config.Zombies.AttackCooldown
					model:SetAttribute("Attacking", true)
					local arm = model:FindFirstChild("Right Shoulder", true)
					if arm then arm.C0 = CFrame.new(1.4, 0, 0) * CFrame.Angles(math.rad(-65), 0, math.rad(-15)) end
					playSound("ZombieAttack", model:FindFirstChild("Torso"))
					task.wait(Config.Zombies.AttackWindup)
					model:SetAttribute("Attacking", false)
					if arm and arm.Parent then
						arm.C0 = CFrame.new(1.4, 0, 0) * CFrame.Angles(math.rad(35), 0, 0)
						task.delay(0.16, function() if arm.Parent then arm.C0 = CFrame.new(1.4, 0, 0) end end)
					end
					if humanoid.Health > 0 and target.humanoid.Health > 0 and (target.root.Position - root.Position).Magnitude <= Config.Zombies.AttackRange + 0.7 then
						target.humanoid:TakeDamage(Config.Zombies.AttackDamage)
					end
				end
			else
				local approach = Vector3.new(math.cos(approachAngle), 0, math.sin(approachAngle)) * Config.Zombies.ApproachSpacing
				local destination = insideArena(target.root.Position + approach + separation * Config.Zombies.SeparationStrength)
				if os.clock() >= nextPath then
					nextPath = os.clock() + Config.Zombies.PathInterval + rng:NextNumber(0, 0.3)
					local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
					local ok = pcall(function() path:ComputeAsync(root.Position, destination) end)
					if ok and path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints()
						local nextWaypoint = waypoints[math.min(2, #waypoints)]
						waypointPosition = nextWaypoint and nextWaypoint.Position or destination
						if nextWaypoint and nextWaypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
					else
						waypointPosition = destination
					end
				end
				humanoid:MoveTo(waypointPosition or destination)
			end
		end
		task.wait(Config.Zombies.ThinkInterval)
	end
end

local function onDeath(model, root)
	active[model] = nil
	model:SetAttribute("Dead", true)
	model:SetAttribute("Attacking", false)
	playSound("ZombieDeath", model:FindFirstChild("Torso"))
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then item.CanCollide = false end
	end
	root.Anchored = true
	local headshot = model:GetAttribute("FatalHeadshot") == true
	local tilt = CFrame.Angles(math.rad(headshot and 105 or 75), 0, math.rad(rng:NextInteger(-25, 25)))
	TweenService:Create(root, TweenInfo.new(headshot and 0.32 or 0.42, Enum.EasingStyle.Quad), { CFrame = root.CFrame * tilt }):Play()
	Debris:AddItem(model, Config.Zombies.CorpseLifetime)
end

function ZombieService.React(model, headshot)
	if not active[model] then return end
	local torso = model:FindFirstChild("Torso")
	local head = model:FindFirstChild("Head")
	local part = headshot and head or torso
	if not part then return end
	local serial = (model:GetAttribute("ReactionSerial") or 0) + 1
	model:SetAttribute("ReactionSerial", serial)
	playSound("ZombieHurt", torso)
	local original = part:GetAttribute("BaseColor") or part.Color
	part:SetAttribute("BaseColor", original)
	part.Color = headshot and Color3.fromRGB(255, 227, 165) or Color3.fromRGB(174, 89, 83)
	task.delay(headshot and 0.22 or 0.13, function()
		if part.Parent and not model:GetAttribute("Dead") and model:GetAttribute("ReactionSerial") == serial then part.Color = original end
	end)
	local rootJoint = model:FindFirstChild("RootJoint", true)
	local neck = model:FindFirstChild("Neck", true)
	if rootJoint then rootJoint.C0 = CFrame.Angles(math.rad(headshot and -13 or -6), 0, math.rad(headshot and 8 or 4)) end
	if headshot and neck then neck.C0 = CFrame.new(0, 1.65, 0) * CFrame.Angles(math.rad(-22), math.rad(10), 0) end
	task.delay(headshot and 0.25 or 0.16, function()
		if model:GetAttribute("ReactionSerial") ~= serial or model:GetAttribute("Dead") then return end
		if rootJoint and rootJoint.Parent then rootJoint.C0 = CFrame.identity end
		if neck and neck.Parent then neck.C0 = CFrame.new(0, 1.65, 0) end
	end)
end

function ZombieService.Start(spawnZones)
	zones = spawnZones
	for _, name in ipairs({ "Zombies", "Players" }) do
		if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
	end
	PhysicsService:CollisionGroupSetCollidable("Zombies", "Zombies", false)
	PhysicsService:CollisionGroupSetCollidable("Zombies", "Players", false)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local function assign(item)
				if item:IsA("BasePart") then item.CollisionGroup = "Players" end
			end
			for _, item in ipairs(character:GetDescendants()) do assign(item) end
			character.DescendantAdded:Connect(assign)
		end)
	end)
	task.spawn(function()
		while true do
			local count = 0
			for _ in pairs(active) do count += 1 end
			if count < Config.Zombies.MaxAlive and #Players:GetPlayers() > 0 then
				local candidates = {}
				for _, zone in ipairs(zones) do
					local near = false
					for _, player in ipairs(Players:GetPlayers()) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and (root.Position - zone).Magnitude < Config.Zombies.MinSpawnDistance then near = true end
					end
					if not near then table.insert(candidates, zone) end
				end
				if #candidates > 0 then
					local zone = candidates[rng:NextInteger(1, #candidates)]
					local point = zone + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
					local model, humanoid, root = makeZombie(point)
					model:SetAttribute("ApproachAngle", rng:NextNumber(-math.pi, math.pi))
					active[model] = true
					humanoid.Died:Connect(function() onDeath(model, root) end)
					task.spawn(runAI, model, humanoid, root)
				end
			end
			task.wait(Config.Zombies.SpawnInterval)
		end
	end)
end

return ZombieService
