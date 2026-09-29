local Arena = {}

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
	for _, data in ipairs({
		{ -22, -13, 10, 4, 4 }, { 21, 13, 11, 4, 4 }, { -22, 19, 7, 5, 5 },
		{ 24, -20, 8, 5, 5 }, { 0, -29, 13, 3.5, 4 }, { 0, 30, 13, 3.5, 4 },
		{ -42, 0, 6, 7, 6 }, { 43, 0, 6, 7, 6 },
	}) do
		part(arena, "Cover", Vector3.new(data[3], data[4], data[5]), Vector3.new(data[1], data[4] / 2 + 0.55, data[2]), coverColor)
	end
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.Position = Vector3.new(0, 1.1, 0)
		spawn.Size = Vector3.new(7, 1, 7)
		spawn.Neutral = true
		spawn.Anchored = true
	end
	return {
		Vector3.new(-48, 1, -48), Vector3.new(48, 1, -48),
		Vector3.new(-48, 1, 48), Vector3.new(48, 1, 48),
		Vector3.new(0, 1, -49), Vector3.new(0, 1, 49),
		Vector3.new(-49, 1, 0), Vector3.new(49, 1, 0),
	}
end

return Arena
