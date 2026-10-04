local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local ZombieVisuals = {}
local active = {}

local function role(name)
	if name:find("Nub", 1, true) then return end
	for _, key in ipairs({ "UpperArm", "Forearm", "Thigh", "Calf", "Neck", "Head", "Pelvis" }) do
		if name:find(" " .. key, 1, true) or name:find(" L " .. key, 1, true) or name:find(" R " .. key, 1, true) then return key end
	end
end

local function attach(model)
	if not model:IsA("Model") or not model:GetAttribute("SkinnedZombie") or active[model] then return end
	local root = model:WaitForChild("HumanoidRootPart", 10)
	if not root or not model.Parent then return end
	local entry = { root = root, bones = {}, phase = 0, state = "Spawn", stateTime = 0 }
	active[model] = entry
	local function add(item)
		if not item:IsA("Bone") then return end
		local key = role(item.Name)
		if key then
			entry.bones[item] = { role = key, right = item.Name:find(" R ", 1, true) ~= nil,
				basis = root.CFrame:ToObjectSpace(item.WorldCFrame).Rotation }
		end
	end
	for _, item in ipairs(model:GetDescendants()) do add(item) end
	entry.connection = model.DescendantAdded:Connect(add)
end

function ZombieVisuals.Start()
	workspace.ChildAdded:Connect(function(model) task.defer(attach, model) end)
	for _, model in ipairs(workspace:GetChildren()) do task.defer(attach, model) end
	RunService.PreSimulation:Connect(function(dt)
		for model, entry in pairs(active) do
			if not model.Parent then entry.connection:Disconnect() active[model] = nil continue end
			if entry.root.Anchored and not model:GetAttribute("Dead") then continue end
			local state = model:GetAttribute("State")
			if state ~= entry.state then entry.state, entry.stateTime = state, 0 end
			entry.stateTime += dt
			local speed = (entry.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
			local moving = state == "Chase" and math.clamp(speed / Config.Zombies.WalkSpeed, 0, 1) or 0
			entry.phase += dt * (moving > 0.05 and 8 * math.max(moving, 0.3) or 1.8)
			local swing = math.sin(entry.phase) * moving
			local attack = state == "AttackWindup" and math.clamp(entry.stateTime / Config.Zombies.AttackWindup, 0, 1)
				or state == "AttackRecover" and 1 - math.clamp(entry.stateTime / Config.Zombies.AttackRecover, 0, 1) or 0
			local hurt = state == "HitReact" and math.exp(-entry.stateTime * 14) or 0
			for bone, info in pairs(entry.bones) do
				if not bone.Parent then entry.bones[bone] = nil continue end
				local side = info.right and 1 or -1
				local rotation, translation = CFrame.identity, Vector3.zero
				if info.role == "UpperArm" then
					rotation = CFrame.Angles(math.rad(28 + attack * 55) - swing * side * 0.12, 0, math.rad(-side * 65))
				elseif info.role == "Forearm" then rotation = CFrame.Angles(math.rad(12 + attack * 18), 0, 0)
				elseif info.role == "Thigh" then rotation = CFrame.Angles(swing * side * 0.45, 0, 0)
				elseif info.role == "Calf" then rotation = CFrame.Angles(-math.max(0, -swing * side) * 0.6, 0, 0)
				elseif info.role == "Neck" then rotation = CFrame.Angles(math.rad(6) + hurt * 0.2, math.sin(entry.phase * 0.5) * 0.03, 0)
				elseif info.role == "Pelvis" then
					translation = Vector3.new(0, math.abs(math.sin(entry.phase)) * moving * 0.04, 0)
					rotation = CFrame.Angles(hurt * -0.18, 0, swing * 0.02)
				end
				bone.Transform = CFrame.new(info.basis:VectorToObjectSpace(translation)) * info.basis:Inverse() * rotation * info.basis
			end
		end
	end)
end

return ZombieVisuals
