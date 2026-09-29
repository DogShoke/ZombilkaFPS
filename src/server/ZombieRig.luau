local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local ZombieRig = {}
local skin = { Color3.fromRGB(116, 145, 105), Color3.fromRGB(130, 150, 112), Color3.fromRGB(101, 133, 107) }
local coats = { Color3.fromRGB(69, 79, 72), Color3.fromRGB(77, 71, 65), Color3.fromRGB(58, 76, 78) }

local function part(model, name, size, color, collidable, queryable)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Color = color
	item.Material = Enum.Material.SmoothPlastic
	item.CanCollide = collidable
	item.CanTouch = false
	item.CanQuery = queryable ~= false
	item.CollisionGroup = "Zombies"
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = model
	return item
end

local function motor(parent, name, a, b, offset)
	local item = Instance.new("Motor6D")
	item.Name = name
	item.Part0, item.Part1 = a, b
	item.C0 = CFrame.new(offset)
	item.Parent = parent
	return item
end

local function detail(model, host, name, size, offset, color)
	local item = part(model, name, size, color, false, false)
	item.CFrame = host.CFrame * offset
	item.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = host, item
	weld.Parent = item
	return item
end

function ZombieRig.Create(position, variant)
	local model = Instance.new("Model")
	model.Name = "Zombie"
	model:SetAttribute("IsZombie", true)
	model:SetAttribute("State", "Spawn")
	local skinColor = skin[(variant - 1) % #skin + 1]
	local coatColor = coats[(variant - 1) % #coats + 1]
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1), false, false)
	root.Transparency = 1
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), coatColor, false)
	local head = part(model, "Head", Vector3.new(1.5, 1.3, 1.3), skinColor, false)
	local leftArm = part(model, "Left Arm", Vector3.new(0.8, 2, 0.8), skinColor, false)
	local rightArm = part(model, "Right Arm", Vector3.new(0.8, 2, 0.8), skinColor, false)
	local legColor = Color3.fromRGB(45, 50, 52)
	local leftLeg = part(model, "Left Leg", Vector3.new(0.9, 2, 0.9), legColor, true)
	local rightLeg = part(model, "Right Leg", Vector3.new(0.9, 2, 0.9), legColor, true)
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.Zombies.MaxHealth
	humanoid.Health = Config.Zombies.MaxHealth
	humanoid.WalkSpeed = Config.Zombies.WalkSpeed
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	local joints = {
		Root = motor(root, "RootJoint", root, torso, Vector3.zero),
		Neck = motor(torso, "Neck", torso, head, Vector3.new(0, 1.65, 0)),
		LeftShoulder = motor(torso, "Left Shoulder", torso, leftArm, Vector3.new(-1.4, 0, 0)),
		RightShoulder = motor(torso, "Right Shoulder", torso, rightArm, Vector3.new(1.4, 0, 0)),
		LeftHip = motor(torso, "Left Hip", torso, leftLeg, Vector3.new(-0.52, -2, 0)),
		RightHip = motor(torso, "Right Hip", torso, rightLeg, Vector3.new(0.52, -2, 0)),
	}
	-- Small welded details give the untextured placeholder a readable face and torn jacket.
	for _, x in ipairs({ -0.29, 0.29 }) do
		detail(model, head, "CloudedEye", Vector3.new(0.18, 0.13, 0.025), CFrame.new(x, 0.16, -0.66), Color3.fromRGB(211, 205, 159))
		detail(model, head, "EyeSocket", Vector3.new(0.27, 0.25, 0.015), CFrame.new(x, 0.16, -0.65), Color3.fromRGB(66, 77, 60))
	end
	detail(model, head, "Mouth", Vector3.new(0.43, 0.09, 0.025), CFrame.new(0, -0.3, -0.67), Color3.fromRGB(53, 52, 48))
	detail(model, torso, "JacketFront", Vector3.new(1.8, 1.65, 0.08), CFrame.new(0, 0, -0.55), coatColor:Lerp(Color3.fromRGB(30, 35, 34), 0.28))
	detail(model, torso, "JacketTear", Vector3.new(0.34, 0.6, 0.025), CFrame.new(0.43, -0.38, -0.61) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(103, 56, 51))
	model.PrimaryPart = root
	model.Parent = workspace
	model:PivotTo(CFrame.new(position + Vector3.new(0, 2.1, 0)))
	root:SetNetworkOwner(nil)
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") and item ~= root then
			local target = item.Transparency
			item.Transparency = 1
			TweenService:Create(item, TweenInfo.new(Config.Zombies.SpawnFade), { Transparency = target }):Play()
		end
	end
	return { model = model, humanoid = humanoid, root = root, torso = torso, head = head, joints = joints }
end

function ZombieRig.Pose(rig, state, clock, react, hitDirection)
	local j = rig.joints
	local walking = state == "Chase" and rig.humanoid.MoveDirection.Magnitude > 0.05
	local stride = walking and math.sin(clock * 8.5) * 0.48 or 0
	local breathe = math.sin(clock * 2.1) * 0.035
	local attackWindup = state == "AttackWindup"
	local attackRecover = state == "AttackRecover"
	local impulse = react or 0
	local side = hitDirection or 0
	j.Root.C0 = CFrame.Angles(breathe - impulse * 0.13 + (attackWindup and -0.12 or attackRecover and 0.17 or 0), 0, side * impulse * 0.13)
	j.Neck.C0 = CFrame.new(0, 1.65, 0) * CFrame.Angles(-0.08 - impulse * 0.25, math.sin(clock * 1.1) * 0.045, side * impulse * 0.08)
	j.LeftHip.C0 = CFrame.new(-0.52, -2, 0) * CFrame.Angles(stride, 0, 0)
	j.RightHip.C0 = CFrame.new(0.52, -2, 0) * CFrame.Angles(-stride, 0, 0)
	j.LeftShoulder.C0 = CFrame.new(-1.4, 0, 0) * CFrame.Angles(-0.55 - stride * 0.5, 0, -0.12)
	j.RightShoulder.C0 = CFrame.new(1.4, 0, 0) * CFrame.Angles(attackWindup and -1.45 or attackRecover and 0.7 or -0.55 + stride * 0.5, 0, attackWindup and -0.25 or 0.1)
end

function ZombieRig.Die(rig, headshot, roll)
	local model, root = rig.model, rig.root
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			item.CanCollide = false
			item.CanQuery = false
		end
	end
	root.Anchored = true
	local tilt = CFrame.Angles(math.rad(headshot and 105 or 78), 0, math.rad(roll))
	TweenService:Create(root, TweenInfo.new(headshot and 0.3 or 0.43, Enum.EasingStyle.Quad), { CFrame = root.CFrame * tilt }):Play()
	task.delay(math.max(0, Config.Zombies.CorpseLifetime - 0.8), function()
		if not model.Parent then return end
		for _, item in ipairs(model:GetDescendants()) do
			if item:IsA("BasePart") and item ~= root then
				TweenService:Create(item, TweenInfo.new(0.7), { Transparency = 1 }):Play()
			end
		end
	end)
end

return ZombieRig
