local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local LegacyAsset = require(script.Parent.ZombieAsset)
local ZombieVariants = {}

local function weld(a, b)
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1 = a, b
	joint.Parent = b
end

function ZombieVariants.Create(index)
	local folder = ReplicatedStorage.Assets:FindFirstChild(Config.Zombies.VariantFolder or "Zombies")
		or ReplicatedStorage.Assets:FindFirstChild("Zombies")
	local templates = {}
	if folder then
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Model") and item.Name:match("^Zombie_") then table.insert(templates, item) end
		end
	end
	table.sort(templates, function(a, b) return a.Name < b.Name end)
	if #templates == 0 then return LegacyAsset() end
	local template = templates[(index - 1) % #templates + 1]
	local model = template:Clone()
	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local visualRoot = model.PrimaryPart or model:FindFirstChild("RootPart", true)
	assert(visualRoot and visualRoot:IsA("BasePart"), "Zombie template needs its imported rig root")
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("MeshPart") then
			for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
				local p = item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
				low = Vector3.new(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
				high = Vector3.new(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
			end end end
		elseif item:IsA("AnimationController") or item:IsA("Humanoid") or item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local center = Vector3.new((low.X + high.X) / 2, low.Y + 3, (low.Z + high.Z) / 2)
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency = "HumanoidRootPart", Vector3.new(2, 2, 1), 1
	root.CFrame = CFrame.new(center)
	root.Parent = model
	visualRoot.Name = "VisualRoot"
	visualRoot.Transparency = 1
	weld(root, visualRoot)
	local torso = Instance.new("Part")
	torso.Name, torso.Size, torso.Transparency = "Torso", Vector3.new(1.8, 2.4, 1), 1
	torso.CFrame = root.CFrame
	torso.Parent = model
	weld(root, torso)
	local headBone
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("Bone") and item.Name:find(" Head", 1, true) and not item.Name:find("Nub", 1, true) then headBone = item break end
	end
	local head = Instance.new("Part")
	head.Name, head.Size, head.Transparency = "Head", Vector3.new(0.9, 1, 0.9), 1
	head.CFrame = CFrame.new(headBone and headBone.WorldPosition + Vector3.new(0, 0.35, 0) or Vector3.new(center.X, high.Y - 0.5, center.Z))
	head.Parent = model
	weld(root, head)
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			item.Massless = item ~= root
			item.CanCollide = item == torso
			item.CanQuery = item == torso or item == head
			item.CanTouch = false
			item:SetAttribute("VisualTransparency", item.Transparency)
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = root
	model:SetAttribute("SkinnedZombie", true)
	model:SetAttribute("ZombieVariant", template.Name)
	return model
end

return ZombieVariants
