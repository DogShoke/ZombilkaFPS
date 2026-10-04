-- Run in Studio Edit after preparing _G.ZombieTemplates.
local function escape(value)
	return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end
local function serialize(model)
	local refs, serial = {}, 0
	local function register(item)
		serial += 1 refs[item] = "RBX" .. serial
		for _, child in ipairs(item:GetChildren()) do register(child) end
	end
	register(model)
	local function property(name, value)
		local kind, body = typeof(value), nil
		if kind == "Instance" then kind, body = "Ref", refs[value] or "null"
		elseif kind == "nil" then kind, body = "Ref", "null"
		elseif kind == "string" then kind, body = "string", escape(value)
		elseif kind == "boolean" then kind, body = "bool", tostring(value)
		elseif kind == "number" then kind, body = "float", tostring(value)
		elseif kind == "EnumItem" then kind, body = "token", tostring(value.Value)
		elseif kind == "Vector3" then body = "<X>" .. value.X .. "</X><Y>" .. value.Y .. "</Y><Z>" .. value.Z .. "</Z>"
		elseif kind == "Color3" then body = "<R>" .. value.R .. "</R><G>" .. value.G .. "</G><B>" .. value.B .. "</B>"
		elseif kind == "CFrame" then
			kind = "CoordinateFrame" body = ""
			local values, keys = {value:GetComponents()}, {"X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"}
			for i, key in ipairs(keys) do body ..= "<" .. key .. ">" .. values[i] .. "</" .. key .. ">" end
		end
		assert(body, "Unsupported property " .. name .. ": " .. kind)
		if name == "MeshId" or name == "TextureID" or name == "ColorMap" then kind, body = "Content", "<url>" .. body .. "</url>" end
		return "<" .. kind .. ' name="' .. name .. '">' .. body .. "</" .. kind .. ">"
	end
	local function itemXml(item)
		local props = {property("Name", item.Name)}
		local function add(names) for _, name in ipairs(names) do table.insert(props, property(name, item[name])) end end
		if item:IsA("Model") then add({"PrimaryPart"})
		elseif item:IsA("BasePart") then
			add({"CFrame", "Size", "Color", "Transparency", "Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "Material", "CastShadow"})
			if item:IsA("MeshPart") then add({"MeshId", "TextureID", "DoubleSided", "RenderFidelity", "CollisionFidelity"}) end
		elseif item:IsA("Bone") then add({"CFrame", "Transform", "Visible"})
		elseif item:IsA("Motor6D") then add({"Part0", "Part1", "C0", "C1", "Enabled"})
		elseif item:IsA("SurfaceAppearance") then add({"ColorMap", "AlphaMode"})
		else error("Unsupported instance: " .. item.ClassName) end
		local children = ""
		for _, child in ipairs(item:GetChildren()) do children ..= itemXml(child) end
		return '<Item class="' .. item.ClassName .. '" referent="' .. refs[item] .. '"><Properties>' .. table.concat(props) .. '</Properties>' .. children .. '</Item>'
	end
	return '<roblox version="4"><External>null</External><External>nil</External>' .. itemXml(model) .. '</roblox>'
end
local result = {}
for _, model in ipairs(_G.ZombieTemplates:GetChildren()) do result[model.Name] = serialize(model) end
return result
