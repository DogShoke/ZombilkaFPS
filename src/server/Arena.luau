local Arena = {}
local Lighting = game:GetService("Lighting")

local function part(parent, name, size, position, color, material)
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Size = size
	item.Position = position
	item.Color = color
	item.Material = material or Enum.Material.Concrete
	item.Parent = parent
	return item
end

function Arena.Build()
	Lighting.ClockTime = 17.2
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(92, 98, 103)
	Lighting.OutdoorAmbient = Color3.fromRGB(112, 119, 121)
	Lighting.ExposureCompensation = 0.05
	Lighting.FogColor = Color3.fromRGB(93, 105, 108)
	Lighting.FogEnd = 235
	local grade = Lighting:FindFirstChild("CombatGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "CombatGrade"
	grade.TintColor = Color3.fromRGB(224, 231, 224)
	grade.Contrast = 0.08
	grade.Saturation = -0.12
	grade.Parent = Lighting
	local previous = workspace:FindFirstChild("CombatArena")
	if previous then previous:Destroy() end
	local arena = Instance.new("Folder")
	arena.Name = "CombatArena"
	arena.Parent = workspace
	local floorColor = Color3.fromRGB(69, 74, 78)
	local wallColor = Color3.fromRGB(45, 54, 60)
	local coverColor = Color3.fromRGB(104, 105, 92)
	part(arena, "Floor", Vector3.new(124, 1, 124), Vector3.new(0, 0.05, 0), floorColor)
	part(arena, "NorthWall", Vector3.new(124, 17, 2), Vector3.new(0, 8.5, -62), wallColor)
	part(arena, "SouthWall", Vector3.new(124, 17, 2), Vector3.new(0, 8.5, 62), wallColor)
	part(arena, "WestWall", Vector3.new(2, 17, 124), Vector3.new(-62, 8.5, 0), wallColor)
	part(arena, "EastWall", Vector3.new(2, 17, 124), Vector3.new(62, 8.5, 0), wallColor)
	for offset = -50, 50, 20 do
		for _, data in ipairs({ { Vector3.new(offset, 0.558, 0), Vector3.new(0.06, 0.015, 118) }, { Vector3.new(0, 0.558, offset), Vector3.new(118, 0.015, 0.06) } }) do
			local line = part(arena, "FloorSeam", data[2], data[1], Color3.fromRGB(48, 53, 56), Enum.Material.SmoothPlastic)
			line.CanCollide = false
			line.CanQuery = false
		end
	end
	for _, corner in ipairs({ Vector3.new(-55, 9, -55), Vector3.new(55, 9, -55), Vector3.new(-55, 9, 55), Vector3.new(55, 9, 55) }) do
		local lamp = part(arena, "WallLamp", Vector3.new(3.5, 0.24, 0.35), corner, Color3.fromRGB(177, 193, 177), Enum.Material.Neon)
		lamp.CanCollide = false
		lamp.CanQuery = false
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(215, 226, 206)
		light.Brightness = 0.65
		light.Range = 23
		light.Parent = lamp
	end
	for _, data in ipairs({
		{ -22, -13, 10, 4, 4 }, { 21, 13, 11, 4, 4 }, { -22, 19, 7, 5, 5 },
		{ 24, -20, 8, 5, 5 }, { 0, -29, 13, 3.5, 4 }, { 0, 30, 13, 3.5, 4 },
		{ -42, 0, 6, 7, 6 }, { 43, 0, 6, 7, 6 },
	}) do
		local index = math.abs(data[1] + data[2])
		local isMetal = index % 2 == 0
		local block = part(arena, "Cover", Vector3.new(data[3], data[4], data[5]), Vector3.new(data[1], data[4] / 2 + 0.55, data[2]),
			isMetal and Color3.fromRGB(82, 91, 91) or coverColor, isMetal and Enum.Material.Metal or Enum.Material.Concrete)
		local trim = part(arena, "CoverTop", Vector3.new(data[3] + 0.18, 0.18, data[5] + 0.18), block.Position + Vector3.new(0, data[4] / 2 + 0.09, 0),
			Color3.fromRGB(53, 62, 63), Enum.Material.Metal)
		trim.CanCollide = false
		trim.CanQuery = false
	end
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.Position = Vector3.new(0, 1.1, 0)
		spawn.Size = Vector3.new(7, 1, 7)
		spawn.Neutral = true
		spawn.Anchored = true
		spawn.Material = Enum.Material.Metal
		spawn.Color = Color3.fromRGB(74, 91, 89)
	end
	return {
		Vector3.new(-48, 1, -48), Vector3.new(48, 1, -48),
		Vector3.new(-48, 1, 48), Vector3.new(48, 1, 48),
		Vector3.new(0, 1, -49), Vector3.new(0, 1, 49),
		Vector3.new(-49, 1, 0), Vector3.new(49, 1, 0),
	}
end

return Arena
