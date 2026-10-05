local assets=game.ReplicatedStorage.Assets
local result={}
for _,spec in ipairs({
	{"FpsAKM_Roblox","FpsAKM","AKM_model","rbxassetid://72576583417054","rbxassetid://118206410395088","Root",0.14952},
	{"FpsMossberg_Roblox","FpsMossberg","Mossberg590A1","rbxassetid://85431004415279","rbxassetid://139285841259514","ShotgunRoot",0.2644},
}) do
	local imported=workspace:FindFirstChild(spec[1]) or game.ServerStorage.WeaponsSourceImport:FindFirstChild(spec[1]) assert(imported,"Missing imported "..spec[1])
	local model=imported:Clone() model.Name=spec[2]
	local root=model.PrimaryPart or model:FindFirstChild("RootPart") assert(root)
	local trigger=model:FindFirstChild("Trigger",true) assert(trigger and trigger:IsA("Bone"))
	local normalizer=CFrame.Angles(0,0,math.pi)*CFrame.Angles(math.pi/2,0,0)*CFrame.new(-trigger.WorldPosition)
	local transforms={}
	for _,o in ipairs(model:GetDescendants()) do
		if o:IsA("BasePart") then transforms[o]=normalizer*o.CFrame end
	end
	-- Move the whole imported assembly; bone bind frames and motor offsets stay intact.
	for p,cf in pairs(transforms) do p.CFrame=cf end
	root.Size=Vector3.new(0.1,0.1,0.1) root.Transparency=1
	local gun=model:FindFirstChild(spec[3],true)
	local minZ,maxY=math.huge,-math.huge
	for _,o in ipairs(model:GetDescendants()) do
		if o:IsA("MeshPart") then
			local texture=o.Name=="ArmModel" and spec[5] or spec[4]
			o.Color=Color3.new(1,1,1) o.TextureID=texture
			for _,child in ipairs(o:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
			local sa=Instance.new("SurfaceAppearance") sa.ColorMap=texture sa.Parent=o
		elseif o:IsA("LuaSourceContainer") or o.Name=="InitialPoses" then o:Destroy() end
		if o:IsA("BasePart") then o.Anchored=true o.CanCollide=false o.CanQuery=false o.CanTouch=false o.CastShadow=false end
	end
	for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
		local p=gun.CFrame:PointToWorldSpace(gun.Size*Vector3.new(x,y,z)/2)
		minZ=math.min(minZ,p.Z) maxY=math.max(maxY,p.Y)
	end end end
	local bone=model:FindFirstChild(spec[6],true) or root
	local muzzle=Instance.new("Attachment") muzzle.Name="Barrel"
	muzzle.CFrame=bone.WorldCFrame:ToObjectSpace(CFrame.new(0,spec[7],minZ)) muzzle.Parent=bone
	model.PrimaryPart=root
	local old=assets:FindFirstChild(model.Name) if old then old:Destroy() end model.Parent=assets
	table.insert(result,{name=model.Name,bones=(function() local n=0 for _,o in ipairs(model:GetDescendants()) do if o:IsA("Bone") then n+=1 end end return n end)(),muzzle=tostring(muzzle.WorldPosition)})
end
return result
