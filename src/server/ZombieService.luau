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

local function runAI(model, humanoid, root)
	local nextAttack = 0
	local nextPath = 0
	local waypointPosition
	while model.Parent and humanoid.Health > 0 do
		local target, distance = nearestTarget(root.Position)
		if target then
			if distance <= Config.Zombies.AttackRange then
				humanoid:MoveTo(root.Position)
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
				if os.clock() >= nextPath then
					nextPath = os.clock() + Config.Zombies.PathInterval + rng:NextNumber(0, 0.3)
					local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
					local ok = pcall(function() path:ComputeAsync(root.Position, target.root.Position) end)
					if ok and path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints()
						local nextWaypoint = waypoints[math.min(2, #waypoints)]
						waypointPosition = nextWaypoint and nextWaypoint.Position or target.root.Position
						if nextWaypoint and nextWaypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
					else
						waypointPosition = target.root.Position
					end
				end
				humanoid:MoveTo(waypointPosition or target.root.Position)
			end
		end
		task.wait(Config.Zombies.ThinkInterval)
	end
end

local function onDeath(model, root)
	active[model] = nil
	model:SetAttribute("Dead", true)
	playSound("ZombieDeath", model:FindFirstChild("Torso"))
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then item.CanCollide = false end
	end
	root.Anchored = true
	local tilt = CFrame.Angles(math.rad(75), 0, math.rad(rng:NextInteger(-25, 25)))
	TweenService:Create(root, TweenInfo.new(0.42, Enum.EasingStyle.Quad), { CFrame = root.CFrame * tilt }):Play()
	Debris:AddItem(model, Config.Zombies.CorpseLifetime)
end

function ZombieService.React(model, headshot)
	if not active[model] then return end
	local torso = model:FindFirstChild("Torso")
	local head = model:FindFirstChild("Head")
	local part = headshot and head or torso
	if not part then return end
	playSound("ZombieHurt", torso)
	local original = part.Color
	part.Color = headshot and Color3.fromRGB(255, 227, 165) or Color3.fromRGB(174, 89, 83)
	task.delay(headshot and 0.22 or 0.13, function()
		if part.Parent and not model:GetAttribute("Dead") then part.Color = original end
	end)
	local shoulder = model:FindFirstChild("Right Shoulder", true)
	if shoulder and shoulder:IsA("Motor6D") then
		shoulder.C0 = CFrame.new(1.4, 0, 0) * CFrame.Angles(math.rad(headshot and -38 or -18), 0, 0)
		task.delay(0.23, function() if shoulder.Parent then shoulder.C0 = CFrame.new(1.4, 0, 0) end end)
	end
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
