local Config = require(game.ReplicatedStorage.Shared.Config)
local ChairAsset = require(script.Parent.OfficeChairAsset)
local OfficeMap = {}
local C = { floor=Color3.fromRGB(49,59,66), wall=Color3.fromRGB(188,196,191), dark=Color3.fromRGB(25,35,43), wood=Color3.fromRGB(137,106,72), teal=Color3.fromRGB(48,157,156), red=Color3.fromRGB(218,81,61) }
local function folder(parent,name)
	local f=Instance.new("Folder") f.Name=name f.Parent=parent return f
end
local function part(parent,name,size,pos,color,material,cosmetic)
	local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos p.Anchored=true p.Material=material or Enum.Material.SmoothPlastic p.Color=color
	p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.CanTouch=false p.CanCollide=not cosmetic p.CanQuery=not cosmetic p.Parent=parent return p
end
local function sign(parent,pos,text,width,color)
	local p=part(parent,"Wayfinding",Vector3.new(width or 16,3,0.2),pos,C.dark,nil,true)
	p.CFrame *= CFrame.Angles(0, math.pi, 0)
local g=Instance.new("SurfaceGui") g.LightInfluence=0 g.Face=Enum.NormalId.Front g.CanvasSize=Vector2.new(800,150) g.Parent=p
	local t=Instance.new("TextLabel") t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.Text=text t.Font=Enum.Font.GothamMedium t.TextScaled=true t.TextColor3=color or Color3.fromRGB(213,232,225) t.Parent=g
	return p
end
local function desk(parent,o,x,z,angle)
	local cf=CFrame.new(o+Vector3.new(x,0,z))*CFrame.Angles(0,angle or 0,0)
	local function p(n,size,v,c,mat,cosmetic) local a=part(parent,n,size,Vector3.zero,c,mat,cosmetic) a.CFrame=cf*CFrame.new(v) return a end
	p("Desk",Vector3.new(8,0.35,4),Vector3.new(0,2.9,0),C.wood,Enum.Material.Wood)
	for _,dx in {-3.4,3.4} do p("DeskLeg",Vector3.new(0.4,2.8,3),Vector3.new(dx,1.4,0),C.dark,Enum.Material.Metal,true) end
	p("Monitor",Vector3.new(2.6,1.65,0.2),Vector3.new(0,4,-0.9),C.dark,nil,true)
	p("Screen",Vector3.new(2.3,1.3,0.04),Vector3.new(0,4,-0.77),Color3.fromRGB(47,91,105),Enum.Material.Neon,true)
	p("Keyboard",Vector3.new(2,0.12,0.7),Vector3.new(0,3.15,0.6),C.dark,nil,true)
	local chair=ChairAsset() chair.Name="OfficeChair" chair.Parent=parent
	local box,size=chair:GetBoundingBox()
	chair:ScaleTo(0.8)
	box,size=chair:GetBoundingBox()
	chair:PivotTo(cf*CFrame.new(0,size.Y/2,3.4)*(chair:GetPivot():ToObjectSpace(box)):Inverse())
	for _,a in chair:GetDescendants() do if a:IsA("BasePart") then a.Anchored=true a.CanCollide=false a.CanQuery=false a.CanTouch=false end end
end
local function plant(parent,o,x,z)
	part(parent,"Planter",Vector3.new(3,2.2,3),o+Vector3.new(x,1.1,z),C.dark)
	part(parent,"Stem",Vector3.new(0.25,3,0.25),o+Vector3.new(x,3,z),C.wood,nil,true)
	for i=1,3 do local p=part(parent,"Leaves",Vector3.new(2.4,2,2.4),o+Vector3.new(x+math.sin(i*2)*0.6,3.5+i*0.6,z),Color3.fromRGB(60,94,69),nil,true) p.Shape=Enum.PartType.Ball end
end
local function buildFloor(run,index)
	local model=Instance.new("Model") model.Name=string.format("Floor%02d",index) model:SetAttribute("Layout",index==1 and "OpenOffice" or "Executive") model.Parent=run
	local geo,props,spawns,lobby=folder(model,"Geometry"),folder(model,"Props"),folder(model,"ZombieSpawns"),folder(model,"ElevatorLobby")
	local o=Vector3.new(0,Config.Run.BaseHeight+(index-1)*Config.Run.FloorHeight,0)
	part(geo,"Floor",Vector3.new(156,1,156),o-Vector3.new(0,0.5,0),C.floor,Enum.Material.Carpet)
	part(geo,"Ceiling",Vector3.new(156,1,156),o+Vector3.new(0,16,0),Color3.fromRGB(109,121,126))
	for _,x in {-78,78} do
		local glass=part(geo,"WindowWall",Vector3.new(0.6,15,156),o+Vector3.new(x,7.5,0),Color3.fromRGB(95,140,158),Enum.Material.Glass) glass.Transparency=0.65
		for z=-72,72,18 do part(geo,"WindowMullion",Vector3.new(0.9,16,0.6),o+Vector3.new(x,8,z),C.dark,Enum.Material.Metal) end
	end
	local glass=part(geo,"WindowWall",Vector3.new(156,15,0.6),o+Vector3.new(0,7.5,-78),Color3.fromRGB(95,140,158),Enum.Material.Glass) glass.Transparency=0.65
	part(geo,"SouthWall",Vector3.new(156,16,1),o+Vector3.new(0,8,78),C.wall)
	for x=-72,72,18 do part(geo,"WindowMullion",Vector3.new(0.6,16,0.9),o+Vector3.new(x,8,-78),C.dark,Enum.Material.Metal) end
	for _,x in {-54,-18,18,54} do for _,z in {-54,-18,18,54} do
		local p=part(geo,"CeilingLight",Vector3.new(9,0.15,1.2),o+Vector3.new(x,15.3,z),Color3.fromRGB(211,231,228),Enum.Material.Neon,true)
		local light=Instance.new("SurfaceLight") light.Face=Enum.NormalId.Bottom light.Range=24 light.Angle=140 light.Brightness=1.8 light.Color=p.Color light.Shadows=false light.Parent=p
	end end
	for _,x in {-38,38} do for _,z in {-34,30} do part(geo,"Column",Vector3.new(3,16,3),o+Vector3.new(x,8,z),C.wall,Enum.Material.Concrete) end end
	-- Wide central spine, perimeter loop and cross lanes remain free of furniture.
	part(props,"LobbyRunner",Vector3.new(26,0.04,30),o+Vector3.new(0,0.02,42),C.teal,nil,true)
	part(props,"ReceptionDesk",Vector3.new(19,3.5,4),o+Vector3.new(0,1.75,23),C.wood,Enum.Material.Wood)
	sign(props,o+Vector3.new(0,12,25.1),"NORTHLINE  /  "..(index==1 and "ОПЕРАЦИИ" or "ДИРЕКЦИЯ"),22)
	sign(props,o+Vector3.new(-49,9,45),"← КУХНЯ  /  ОФИС →",22)
	if index==1 then
		for _,x in {-53,-26,26,53} do for _,z in {-52,-23,6} do
			desk(props,o,x,z,0)
			part(props,"CubiclePartition",Vector3.new(10,4.1,0.3),o+Vector3.new(x,2.05,z-3),Color3.fromRGB(82,105,114))
		end end
	else
		for _,x in {-46,46} do
			part(props,"ConferenceTable",Vector3.new(16,0.5,26),o+Vector3.new(x,3,-28),C.wood,Enum.Material.Wood)
			for _,z in {-36,-24,-12} do desk(props,o,x+(x<0 and -15 or 15),z,math.pi/2) end
			-- Glass room boundaries leave two 14+ stud entrances per room.
			for _,z in {-55,0} do local p=part(geo,"MeetingGlass",Vector3.new(27,10,0.3),o+Vector3.new(x,5,z),Color3.fromRGB(115,150,160),Enum.Material.Glass) p.Transparency=0.55 end
			sign(props,o+Vector3.new(x,11,-54.7),x<0 and "ПЕРЕГОВОРНАЯ A" or "ПЕРЕГОВОРНАЯ B",22)
		end
		for _,x in {-48,48} do desk(props,o,x,25,0) part(props,"OfficeDivider",Vector3.new(19,4.5,0.4),o+Vector3.new(x,2.25,19),C.teal) end
	end
	-- Kitchen and copy/storage occupy opposite rear corners, with two approach routes.
	for _,x in {-63,-55,-47} do part(props,"KitchenCabinet",Vector3.new(7.5,3,4),o+Vector3.new(x,1.5,69),C.wall) end
	part(props,"KitchenCounter",Vector3.new(25,0.3,5),o+Vector3.new(-55,3.2,69),C.wood,Enum.Material.Wood)
	part(props,"VendingMachine",Vector3.new(5,8,4),o+Vector3.new(-70,4,59),C.teal,Enum.Material.Metal)
	part(props,"VendingDisplay",Vector3.new(3.6,4.6,0.1),o+Vector3.new(-70,4.5,56.9),Color3.fromRGB(144,193,194),Enum.Material.Neon,true)
	sign(props,o+Vector3.new(-52,10,76.8),"ПЕРЕРЫВ",20)
	for _,x in {47,56,65} do part(props,"StorageCabinet",Vector3.new(6,6,3),o+Vector3.new(x,3,69),Color3.fromRGB(114,130,133),Enum.Material.Metal) end
	part(props,"Copier",Vector3.new(5,4,4),o+Vector3.new(65,2,54),C.wall)
	sign(props,o+Vector3.new(55,10,76.8),"АРХИВ / ПЕЧАТЬ",23)
	for _,v in {Vector2.new(-19,45),Vector2.new(19,45),Vector2.new(-70,-66),Vector2.new(70,-66)} do plant(props,o,v.X,v.Y) end
	for i=1,12 do local p=part(props,"DiscardedPaper",Vector3.new(1.1,0.015,1.5),o+Vector3.new(-62+(i*17)%124,0.05,-62+(i*31)%124),Color3.fromRGB(190,198,182),nil,true) p.Orientation=Vector3.new(0,i*43,0) end
	-- Accent bands and emergency beacons make the two end zones readable in combat.
	for _,x in {-76.8,76.8} do
		part(props,"EmergencyStrip",Vector3.new(0.16,0.3,26),o+Vector3.new(x,5.5,49),C.red,Enum.Material.Neon,true)
	end
	for _,x in {-54,54} do
		part(geo,"UtilityPartition",Vector3.new(22,9,0.4),o+Vector3.new(x,4.5,45),C.wall)
		part(props,"UtilityAccent",Vector3.new(22,0.5,0.1),o+Vector3.new(x,6.6,44.7),index==1 and C.teal or C.wood,nil,true)
	end
	for x=-72,72,12 do part(props,"CeilingSeam",Vector3.new(0.06,0.03,154),o+Vector3.new(x,15.47,0),Color3.fromRGB(82,97,106),nil,true) end
	for z=-72,72,12 do part(props,"CeilingSeam",Vector3.new(154,0.03,0.06),o+Vector3.new(0,15.47,z),Color3.fromRGB(82,97,106),nil,true) end
	local spawn=Instance.new("SpawnLocation") spawn.Name="PlayerSpawn" spawn.Size=Vector3.new(5,0.2,5) spawn.CFrame=CFrame.new(o+Vector3.new(0,0.1,49)) spawn.Anchored=true spawn.Transparency=1 spawn.CanCollide=false spawn.CanQuery=false spawn.Duration=0 spawn.Enabled=index==1 spawn.Parent=model
	local points={Vector3.new(-65,0,-65),Vector3.new(0,0,-65),Vector3.new(65,0,-65),Vector3.new(-68,0,30),Vector3.new(68,0,30),Vector3.new(-30,0,62),Vector3.new(30,0,62),Vector3.new(0,0,-20)}
	local zones={} for i,v in points do local p=part(spawns,"Zone"..i,Vector3.new(6,0.1,6),o+v,C.red,nil,true) p.Transparency=1 p:SetAttribute("SpawnZone",true) table.insert(zones,o+v) end
	-- Cabin rear + side walls; aperture faces north into the lobby.
	part(lobby,"CabinFloor",Vector3.new(18,0.12,18),o+Vector3.new(0,0.06,67),C.dark,Enum.Material.Metal)
	part(lobby,"CabinBack",Vector3.new(18,14,0.6),o+Vector3.new(0,7,76),C.dark,Enum.Material.Metal)
	for _,x in {-9,9} do part(lobby,"CabinSide",Vector3.new(0.6,14,18),o+Vector3.new(x,7,67),C.dark,Enum.Material.Metal) end
	local doors={}
	for i,x in {-4.5,4.5} do local p=part(lobby,"Door"..i,Vector3.new(8.9,13,0.6),o+Vector3.new(x,6.5,58),Color3.fromRGB(113,128,135),Enum.Material.Metal) doors[i]={Part=p,Closed=p.CFrame,Open=p.CFrame*CFrame.new(i==1 and -8.7 or 8.7,0,0)} end
	local indicator=part(lobby,"StatusLight",Vector3.new(15,0.35,0.3),o+Vector3.new(0,14,57.5),C.red,Enum.Material.Neon,true)
	local title=sign(lobby,o+Vector3.new(0,11,75.6),"↑  ЭТАЖ "..index,12)
	local button=part(lobby,"ElevatorButton",Vector3.new(1,1.6,0.25),o+Vector3.new(6,4,75.5),C.teal,Enum.Material.Neon,true)
	local prompt=Instance.new("ProximityPrompt") prompt.Name="NextFloor" prompt.ActionText="На следующий этаж" prompt.ObjectText="ЛИФТ" prompt.HoldDuration=0.25 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Enabled=false prompt.Parent=button
	sign(lobby,o+Vector3.new(0,15,57.5),"ЛИФТ  ↑",14)
	return {Model=model,Origin=o,Zones=zones,Spawn=spawn,Doors=doors,Indicator=indicator,Prompt=prompt,Title=title,Cabin=CFrame.new(o+Vector3.new(0,3,68))*CFrame.Angles(0,0,0)}
end
function OfficeMap.Build()
	local old=workspace:FindFirstChild("OfficeRun") if old then old:Destroy() end
	for _,n in {"Baseplate","SpawnLocation","CombatArena"} do local x=workspace:FindFirstChild(n) if x then x:Destroy() end end
	local run=folder(workspace,"OfficeRun")
	local floors={buildFloor(run,1),buildFloor(run,2)}
	local skyline=folder(run,"Skyline")
	for i=1,22 do
		local angle=i*math.pi*2/22 local distance=260+(i%3)*70 local height=100+(i*37)%145
		local p=part(skyline,"DistantTower",Vector3.new(35+(i%4)*9,height,36),Vector3.new(math.cos(angle)*distance,height/2,math.sin(angle)*distance),Color3.fromRGB(34,48,64),Enum.Material.Concrete)
		for y=25,height-8,28 do part(skyline,"LitStorey",Vector3.new(p.Size.X+0.1,0.6,36.1),Vector3.new(p.Position.X,y,p.Position.Z),Color3.fromRGB(112,144,153),Enum.Material.Neon,true) end
	end
	local lighting=game:GetService("Lighting") lighting.ClockTime=19.2 lighting.Brightness=3 lighting.Ambient=Color3.fromRGB(158,164,177) lighting.OutdoorAmbient=Color3.fromRGB(96,117,143) lighting.FogColor=Color3.fromRGB(39,58,78) lighting.FogStart=220 lighting.FogEnd=700
	return floors
end
return OfficeMap
