-- Blender V4 adapter. Static art/physics are filesystem assets; gameplay stays in existing services.
local Storage=game:GetService("ServerStorage")
local Layout=require(game.ReplicatedStorage.Shared.CampusLayout)
local Config=require(game.ReplicatedStorage.Shared.Config)
local Map={}
local function vector(v)return Vector3.new(v[1],v[2],v[3])end
local function folder(parent,name)
	local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
function Map.Build(options)
	options=options or {}
	local parent=options.Parent or workspace
	assert(not parent:FindFirstChild("CampusComplex"),"CampusComplex already exists")
	local assets=Storage:FindFirstChild("CampusAssets")
	assert(assets and assets:FindFirstChild("CampusCollisionTemplate"),"Campus collision asset missing: synchronize Rojo")
	local visual=assets:FindFirstChild("CampusVisualTemplate")
	assert(options.GeometryOnly or visual,"Campus visual asset missing: finish Studio FBX import and filesystem capture")
	local origin=options.Origin or Vector3.new(0,Config.Run.BaseHeight,0)
	local model=Instance.new("Model");model.Name="CampusComplex"
	model:SetAttribute("MapVersion",Layout.Version);model:SetAttribute("MapSource","BlenderCampusV4")
	model:SetAttribute("GeometryOnly",options.GeometryOnly==true)
	model.Parent=parent
	local ok,result=pcall(function()
		local physics=folder(model,"Collision")
		for _,source in assets.CampusCollisionTemplate:GetChildren() do
			local chunk=source:Clone()
			for _,p in chunk:GetDescendants() do if p:IsA("BasePart")then
				p.CFrame+=origin
				if options.GeometryOnly then p.Transparency=.4;p.Color=Color3.fromRGB(130,145,151)end
			end end
			chunk.Parent=physics;task.wait()
		end
		if visual then
			local art=folder(model,"Visual")
			for _,source in visual:GetChildren()do
				local chunk=source:Clone()
				if chunk:IsA("BasePart")then
					chunk.CFrame+=origin;chunk.Anchored=true;chunk.CanCollide=false;chunk.CanTouch=false;chunk.CanQuery=false
				end
				for _,p in chunk:GetDescendants()do if p:IsA("BasePart")then
					p.CFrame+=origin;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
				end end
				chunk.Parent=art;task.wait()
			end
		end
		-- Wire mesh is visual; continuous perimeter hulls keep players and NPCs inside the campus.
		for _,v in {{-770,0,7,1394},{770,0,7,1394},{0,-696.5,1540,7},
			{-343,696.5,854,7},{462,696.5,616,7},{119,735,70,7},{84,715.75,7,38.5},{154,715.75,7,38.5}}do
			local wall=Instance.new("Part");wall.Name="CampusBoundary";wall.Anchored=true
			wall.Size=Vector3.new(v[3],180,v[4]);wall.Position=origin+Vector3.new(v[1],90,v[2])
			wall.Transparency=1;wall.CanTouch=false;wall.CastShadow=false;wall.Parent=physics
		end
		local markers=folder(model,"ActivitySites")
		for _,site in Layout.Activities do
			local marker=Instance.new("Part");marker.Name=site.id;marker.Size=Vector3.one*.1
			local p=site.position_m;marker.Position=origin+Vector3.new(p[1],p[3],-p[2])*Layout.Scale
			marker.Anchored=true;marker.Transparency=1;marker.CanCollide=false;marker.CanTouch=false;marker.CanQuery=false
			marker:SetAttribute("ActivityType",site.type);marker:SetAttribute("Building",site.building)
			marker:SetAttribute("Floor",site.floor);marker:SetAttribute("HandlerImplemented",false)
			marker:SetAttribute("Approach",origin+Vector3.new(site.recommended_approach_m[1],site.recommended_approach_m[3],-site.recommended_approach_m[2])*Layout.Scale)
			marker.Parent=markers
		end
		local spawn=Instance.new("SpawnLocation");spawn.Name="PlayerSpawn";spawn.Size=Vector3.new(5,.2,5)
		spawn.CFrame=CFrame.new(origin+vector(Layout.Spawn)+Vector3.new(0,.1,0));spawn.Anchored=true
		spawn.Transparency=1;spawn.CanCollide=false;spawn.CanQuery=false;spawn.CanTouch=false;spawn.Enabled=false;spawn.Duration=0;spawn.Parent=model
		local zones={}
		local floorRay=RaycastParams.new();floorRay.FilterType=Enum.RaycastFilterType.Include;floorRay.FilterDescendantsInstances={physics}
		for i,p in Layout.Zones do
			local expected=origin+vector(p)
			local hit=workspace:Raycast(expected+Vector3.new(0,1.25,0),Vector3.new(0,-3,0),floorRay)
			if hit and hit.Normal.Y>.65 and math.abs(hit.Position.Y-expected.Y)<=1.25 then
				table.insert(zones,{Id="Campus_"..i,Position=hit.Position,Radius=0,Weight=1,EntryKind="Ground"})
			end
		end
		local nodes={}
		for i,zone in zones do if i%8==1 then local p=zone.Position-origin;table.insert(nodes,{X=p.X,Y=p.Y,Z=p.Z})end end
		local function nearZones(position)
			local near={}
			for _,zone in zones do if (zone.Position-position).Magnitude<=140 then table.insert(near,zone)end end
			return near
		end
		local count=0;for _,p in model:GetDescendants()do if p:IsA("BasePart")then count+=1 end end
		model:SetAttribute("PartCount",count);model:SetAttribute("ActivityCount",#Layout.Activities)
		return {Model=model,Run=model,Origin=origin,Spawn=spawn,Entry=CFrame.new(origin+vector(Layout.Spawn)+Vector3.new(0,3,0)),
			Bounds={Origin=origin,HalfWidth=Layout.HalfWidth,HalfDepth=Layout.HalfDepth},Zones=zones,SpawnSources=zones,
			NavGraph={Nodes=nodes},Layout=Layout,GetSpawnZones=nearZones}
	end)
	if not ok then model:Destroy();error(result)end
	return result
end
return Map
