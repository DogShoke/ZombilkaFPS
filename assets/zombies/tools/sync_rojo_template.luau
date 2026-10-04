-- DATA_JSON is a template subtree read from the Rojo server for the saved project.
local data = game:GetService("HttpService"):JSONDecode(DATA_JSON)
local objects, errors = {}, {}
for id, info in pairs(data) do
	local object
	if info.ClassName == "MeshPart" then
		object = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(info.Properties.MeshContent.Content.Uri))
	else object = Instance.new(info.ClassName) end
	object.Name = info.Name
	objects[id] = object
end
local function enumValue(name, number)
	for _, item in ipairs(Enum[name]:GetEnumItems()) do if item.Value == number then return item end end
	error("Unknown enum value: " .. name)
end
local function value(name, tagged)
	local kind, raw = next(tagged)
	if kind == "Ref" then return objects[raw]
	elseif kind == "CFrame" then
		local p, r = raw.position, raw.orientation
		return CFrame.new(p[1],p[2],p[3],r[1][1],r[1][2],r[1][3],r[2][1],r[2][2],r[2][3],r[3][1],r[3][2],r[3][3])
	elseif kind == "Vector3" then return Vector3.new(table.unpack(raw))
	elseif kind == "Color3" then return Color3.new(table.unpack(raw))
	elseif kind == "Enum" then return enumValue(name, raw)
	elseif kind == "Content" then return Content.fromUri(raw.Uri)
	else return raw end
end
local root
for id, info in pairs(data) do
	local object = objects[id]
	for name, tagged in pairs(info.Properties) do
		if name ~= "MeshContent" and name ~= "NeedsPivotMigration" then
			local ok, err = pcall(function() object[name] = value(name, tagged) end)
			if not ok then table.insert(errors, object.Name .. "." .. name .. ": " .. tostring(err)) end
		end
	end
	if objects[info.Parent] then object.Parent = objects[info.Parent] else root = object end
end
assert(#errors == 0, table.concat(errors, "\n"))
_G.RojoTemplateFolder = _G.RojoTemplateFolder or Instance.new("Folder")
_G.RojoTemplateFolder.Name = "Zombies"
root.Parent = _G.RojoTemplateFolder
return {name=root.Name,instances=#root:GetDescendants(),errors=errors}
