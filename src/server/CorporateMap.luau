-- Reproducible authored world; isolated from the legacy two-floor builder.
local Shared=game.ReplicatedStorage.Shared
local Layout=require(Shared.CorporateLayout)
local Config=require(Shared.Config)
local Assets=require(script.Parent.ArenaAssets)
local Map={}
local function folder(parent,name)
	local item=Instance.new("Folder");item.Name=name;item.Parent=parent;return item
end
local function part(parent,name,size,position,color,material,cosmetic)
	local item=Instance.new("Part");item.Name=name;item.Size=size;item.Position=position
	item.Anchored=true;item.CanCollide=not cosmetic;item.CanQuery=not cosmetic;item.CanTouch=false
	item.Color=color;item.Material=material or Enum.Material.Concrete
	item.TopSurface=Enum.SurfaceType.Smooth;item.BottomSurface=Enum.SurfaceType.Smooth;item.Parent=parent
	return item
end
local function sign(parent,position,text,color)
	local panel=part(parent,"ZoneSign",Vector3.new(32,5,.3),position,Color3.fromRGB(22,32,40),nil,true)
	panel.CFrame*=CFrame.Angles(0,math.pi,0) -- Face the playable court, not the outer wall.
	local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(900,150);gui.LightInfluence=0;gui.Parent=panel
	local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
	label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.Text=text;label.TextColor3=color;label.Parent=gui
	return panel
end
function Map.Build(options)
	options=options or {}
	local parent=options.Parent or workspace
	assert(not parent:FindFirstChild("CorporateComplex"),"CorporateComplex already exists; caller must explicitly clean up its owned map")
	local origin=options.Origin or Vector3.new(0,Config.Run.BaseHeight,0)
	local started=os.clock()
	-- Build detached; missing asset failures never leave a partial active world.
	local model=Instance.new("Model");model.Name="CorporateComplex"
	local ok,result=pcall(function()
		local geometry,props=folder(model,"Geometry"),folder(model,"Props")
		local colours={Parking=Color3.fromRGB(48,53,59),Office=Color3.fromRGB(66,76,79),Service=Color3.fromRGB(57,67,69)}
		local accents={Parking=Color3.fromRGB(224,180,77),Office=Color3.fromRGB(63,177,170),Service=Color3.fromRGB(106,160,211)}
		part(geometry,"Floor",Vector3.new(320,1,320),origin-Vector3.new(0,.5,0),colours.Parking)
		for _,region in Layout.ZoneRegions do
			part(geometry,"ZoneFinish",Vector3.new(region.Width,.03,region.Depth),origin+Vector3.new(region.X,.015,region.Z),colours[region.Id],region.Id=="Office" and Enum.Material.Carpet or Enum.Material.Concrete,true)
			sign(props,origin+Vector3.new(region.X,12,-153),region.Label,accents[region.Id])
		end
		for _,x in {-160,160} do part(geometry,"BoundaryWall",Vector3.new(2,30,320),origin+Vector3.new(x,15,0),Color3.fromRGB(98,113,120)) end
		for _,z in {-160,160} do part(geometry,"BoundaryWall",Vector3.new(320,30,2),origin+Vector3.new(0,15,z),Color3.fromRGB(98,113,120)) end
		-- Open overhead; any accessible elevated surface has authored NPC approaches.
		for _,z in {-92,0,92} do
			part(geometry,"CrossingStripe",Vector3.new(302,.02,.6),origin+Vector3.new(0,.035,z),Color3.fromRGB(122,139,142),nil,true)
		end
		for _,x in {-56,56} do
			part(geometry,"RouteStripe",Vector3.new(.6,.02,290),origin+Vector3.new(x,.035,0),Color3.fromRGB(122,139,142),nil,true)
		end
		for _,cluster in Layout.Clusters do
			local group=folder(props,cluster.Id);group:SetAttribute("Purpose",cluster.Purpose)
			group:SetAttribute("LayoutX",cluster.X);group:SetAttribute("LayoutZ",cluster.Z)
			for _,slot in cluster.Slots do
				local cf=CFrame.new(origin+Vector3.new(cluster.X+slot[2],0,cluster.Z+slot[3]))*CFrame.Angles(0,math.rad(slot[4]),0)
				local placed=Assets.Place(slot[1],group,cf,nil,slot[5],Config.Run.Generation.StudsPerMeter)
				placed:SetAttribute("GameplayObstacle",slot[5])
				if options.Greybox then
					for _,item in placed:GetDescendants() do if item:IsA("BasePart") then
						if item.Name=="CoverCollision" then item.Transparency=.15;item.Color=Color3.fromRGB(135,146,151)
						else item.Transparency=1 end
					end end
				end
			end
		end
		local deckProbes={}
		for _,deck in Layout.MaintenanceDecks do
			local hull=props[deck.Cluster]:FindFirstChild(deck.Asset).CoverCollision
			local height=hull.Position.Y+hull.Size.Y/2-origin.Y
			local centre=origin+Vector3.new(deck.X,0,deck.Z)
			local platform=part(geometry,deck.Id,Vector3.new(deck.Width,.4,deck.Depth),centre+Vector3.new(0,height-.2,0),Color3.fromRGB(100,119,126),Enum.Material.DiamondPlate)
			platform:SetAttribute("Purpose","Visible maintenance deck; both ends accessible by NPC ramp")
			local angle=math.atan(height/deck.RampLength)
			for _,side in {-1,1} do
				local ramp=part(geometry,deck.Id.."Ramp"..side,Vector3.new(deck.RampWidth,.4,math.sqrt(deck.RampLength^2+height^2)),
					centre+Vector3.new(0,height/2-.2*math.cos(angle),side*(deck.Depth/2+deck.RampLength/2)),Color3.fromRGB(111,131,137),Enum.Material.DiamondPlate)
				ramp.CFrame*=CFrame.Angles(side*angle,0,0)
				ramp:SetAttribute("Purpose","Broad no-jump approach to maintenance surface")
			end
			table.insert(deckProbes,{Id=deck.Id,Position=centre+Vector3.new(0,height,0),Height=height})
		end
		-- Painted bays belong to the car banks, not arbitrary decoration scatter.
		for _,z in {-57,-31,31,57} do for _,x in {-116,-92} do
			for _,side in {-5,5} do part(props,"ParkingBayStripe",Vector3.new(.2,.02,18),origin+Vector3.new(x+side,.045,z),Color3.fromRGB(183,182,151),nil,true) end
		end end
		local spawn=Instance.new("SpawnLocation");spawn.Name="PlayerSpawn";spawn.Size=Vector3.new(5,.2,5)
		spawn.CFrame=CFrame.new(origin+Vector3.new(Layout.Spawn.X,.1,Layout.Spawn.Z));spawn.Anchored=true
		spawn.Transparency=1;spawn.CanCollide=false;spawn.CanQuery=false;spawn.CanTouch=false;spawn.Enabled=false;spawn.Duration=0;spawn.Parent=model
		local zones={}
		for _,lane in Layout.SpawnLanes do table.insert(zones,{Id=lane[1],Position=origin+Vector3.new(lane[2],0,lane[3]),Radius=6,Weight=1,EntryKind="Ground",AttackDirection=lane[4]}) end
		local probes={}
		for _,node in Layout.NavGraph.Nodes do table.insert(probes,origin+Vector3.new(node.X,node.Y,node.Z)) end
		local shops={}
		for _,site in Layout.ShopSites do table.insert(shops,{Id=site.Id,Position=origin+Vector3.new(site.X,0,site.Z)}) end
		local count=0;for _,item in model:GetDescendants() do if item:IsA("BasePart") then count+=1 end end
		model:SetAttribute("LayoutVersion",Layout.Version);model:SetAttribute("Mode","Endless")
		model:SetAttribute("PartCount",count);model:SetAttribute("BuildSeconds",os.clock()-started)
		return {Model=model,Run=model,Origin=origin,Spawn=spawn,Entry=CFrame.new(origin+Vector3.new(Layout.Spawn.X,3,Layout.Spawn.Z)),
			Bounds={Origin=origin,HalfWidth=157,HalfDepth=157},Zones=zones,SpawnSources=zones,
			NavGraph=Layout.NavGraph,Layout=Layout,Probes=probes,DeckProbes=deckProbes,ShopSites=shops}
	end)
	if not ok then model:Destroy();error(result) end
	model.Parent=parent
	return result
end
return Map
