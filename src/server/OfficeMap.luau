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
local Layout = require(script.Parent.FloorLayout)
local G = Config.Run.Generation
local accents = { C.teal, Color3.fromRGB(89,125,185), Color3.fromRGB(203,148,65), Color3.fromRGB(129,111,163) }
local roomLabels = { Workstations="РАБОЧАЯ ЗОНА", Meeting="ПЕРЕГОВОРНАЯ", BreakRoom="КОМНАТА ОТДЫХА", Archive="АРХИВ", Lab="ИССЛЕДОВАНИЯ", ServerRoom="СЕРВЕРНАЯ", Storage="ХРАНЕНИЕ", Workshop="ТЕХНИЧЕСКАЯ ЗОНА", ParkingBay="ПАРКОВКА" }
local function furnish(parent, origin, room, accent)
	local x,z,w,d=room.X,room.Z,room.Width,room.Depth
	local o=origin+Vector3.new(x,0,z)
	local function p(n,size,v,color,mat,cosmetic) return part(parent,n,size,o+v,color or C.dark,mat,cosmetic) end
	if room.Kind=="Workstations" then
		for _,dx in {-10,10} do desk(parent,o,dx,-d/2+9,0) end
		if d>50 then for _,dx in {-10,10} do desk(parent,o,dx,d/2-10,math.pi) end end
	elseif room.Kind=="Meeting" then
		-- Offset the table so the two crossing door lanes stay open.
		p("ConferenceTable",Vector3.new(8,.4,math.min(22,d-12)),Vector3.new(-10,2.8,0),C.wood,Enum.Material.Wood)
		p("PresentationScreen",Vector3.new(8,4,.2),Vector3.new(10,5,-d/2+2),C.dark,nil,true)
		p("PresentationGlow",Vector3.new(7.5,3.5,.04),Vector3.new(10,5,-d/2+2.13),accent,Enum.Material.Neon,true)
	elseif room.Kind=="BreakRoom" then
		p("KitchenCounter",Vector3.new(7,3,d-12),Vector3.new(-11,1.5,0),C.wall)
		p("CounterTop",Vector3.new(7.3,.25,d-11.5),Vector3.new(-11,3.1,0),C.wood,Enum.Material.Wood)
		p("VendingMachine",Vector3.new(5,7,4),Vector3.new(11,3.5,-d/2+5),accent,Enum.Material.Metal)
		p("VendingDisplay",Vector3.new(3.5,4,.1),Vector3.new(11,4,-d/2+2.9),Color3.fromRGB(160,212,212),Enum.Material.Neon,true)
		p("Bench",Vector3.new(5,2,10),Vector3.new(11,1,d/2-7),C.wood)
	elseif room.Kind=="Lab" then
		for _,dx in {-11,11} do
			p("LabBench",Vector3.new(6,3,d-12),Vector3.new(dx,1.5,0),C.wall,Enum.Material.Metal)
			p("LabWorktop",Vector3.new(6.4,.25,d-11.5),Vector3.new(dx,3.2,0),C.dark)
			for dz=-d/2+8,d/2-8,12 do
				p("SampleChamber",Vector3.new(2,2.5,2),Vector3.new(dx,4.6,dz),Color3.fromRGB(79,172,157),Enum.Material.Glass,true).Transparency=.3
				p("SampleGlow",Vector3.new(.8,1.2,.8),Vector3.new(dx,4.1,dz),accent,Enum.Material.Neon,true)
			end
		end
	elseif room.Kind=="ServerRoom" then
		for _,dx in {-11,11} do for dz=-d/2+7,d/2-7,10 do
			p("ServerRack",Vector3.new(5,6,5),Vector3.new(dx,3,dz),C.dark,Enum.Material.Metal)
			for y=2,5 do p("ServerLED",Vector3.new(3,.15,.1),Vector3.new(dx,y,dz+2.6),accent,Enum.Material.Neon,true) end
		end end
	elseif room.Kind=="ParkingBay" then
		for _,dx in {-10,10} do
			local cf=CFrame.new(o+Vector3.new(dx,0,0))*CFrame.Angles(0,room.Variant%2==0 and math.pi or 0,0)
			local function car(n,size,v,color,cosmetic) local a=p(n,size,Vector3.zero,color,Enum.Material.Metal,cosmetic); a.CFrame=cf*CFrame.new(v); return a end
			car("ParkedCar",Vector3.new(7,2.1,15),Vector3.new(0,1.8,0),room.Variant%2==0 and accent or Color3.fromRGB(92,100,104))
			car("CarCabin",Vector3.new(6,1.8,7),Vector3.new(0,3.6,.5),C.dark)
			car("Windshield",Vector3.new(5.6,1.3,.2),Vector3.new(0,3.5,-3.15),Color3.fromRGB(93,131,144),true)
			for _,sx in {-1,1} do for _,sz in {-1,1} do
				local wheel=car("Wheel",Vector3.new(.7,2.2,2.2),Vector3.new(sx*3.5,1.1,sz*4.8),Color3.fromRGB(20,24,27),true); wheel.Shape=Enum.PartType.Cylinder
				car("CarLight",Vector3.new(1.4,.45,.12),Vector3.new(sx*2.1,2,-7.6),Color3.fromRGB(193,202,163),true)
			end end
			p("ParkingLine",Vector3.new(.12,.02,d-3),Vector3.new(dx+4.5,.025,0),Color3.fromRGB(207,206,182),nil,true)
		end
	else
		for _,dx in {-11,11} do for dz=-d/2+7,d/2-7,12 do
			local h=room.Kind=="Archive" and 6 or room.Kind=="Workshop" and 3 or 3+room.Variant%3
			p(room.Kind=="Archive" and "ArchiveCabinet" or "StorageCrate",Vector3.new(6,h,6),Vector3.new(dx,h/2,dz),room.Kind=="Archive" and C.wall or C.wood,room.Kind=="Archive" and Enum.Material.Metal or Enum.Material.Wood)
			p("BayStripe",Vector3.new(6.05,.3,6.05),Vector3.new(dx,h-.5,dz),accent,nil,true)
		end end
	end
end
local function roomWalls(geo,props,o,r,accent)
	if not r.Enclosed then return end
	local height,door=G.RoomWallHeight,G.DoorWidth
	for _,axis in {"X","Z"} do
		local length=axis=="X" and r.Width or r.Depth
		local offset=axis=="X" and r.Depth/2 or r.Width/2
		local segment=(length-door)/2
		for _,side in {-1,1} do for _,endSide in {-1,1} do
			local along=endSide*(door/2+segment/2)
			local v=axis=="X" and Vector3.new(r.X+along,height/2,r.Z+side*offset) or Vector3.new(r.X+side*offset,height/2,r.Z+along)
			local size=axis=="X" and Vector3.new(segment,height,.5) or Vector3.new(.5,height,segment)
			local wall=part(geo,"RoomWall",size,o+v,r.Glass and Color3.fromRGB(111,156,171) or C.wall,r.Glass and Enum.Material.Glass or Enum.Material.SmoothPlastic)
			if r.Glass then wall.Transparency=.48 end
			part(props,"RoomAccent",Vector3.new(size.X,.22,size.Z),o+v+Vector3.new(0,2.8,0),accent,nil,true)
		end end
	end
end
local function gallery(geo,props,o,layout,accent,zones,probes)
	local x=layout.UpperSide*84
	part(geo,"Floor",Vector3.new(72,.7,64),o+Vector3.new(x,G.UpperHeight-.35,0),C.dark,Enum.Material.Metal)
	for _,dx in {-36,36} do
		part(geo,"GalleryRailing",Vector3.new(.35,3.1,64),o+Vector3.new(x+dx,G.UpperHeight+1.55,0),accent,Enum.Material.Metal)
	end
	for _,sz in {-1,1} do
		-- Two broad stairs, with one smooth collider for reliable NPC navigation.
		local run,rise=G.RampLength,G.UpperHeight
		local ramp=part(geo,"StairRamp",Vector3.new(G.RampWidth,.6,math.sqrt(run*run+rise*rise)),o+Vector3.new(x,rise/2,sz*(32+run/2)),C.dark,Enum.Material.Metal)
		ramp.CFrame*=CFrame.Angles(sz*math.atan(rise/run),0,0)
		for i=1,24 do
			local t=(i-.5)/24
			part(props,"StairTread",Vector3.new(G.RampWidth,rise/24,run/24),o+Vector3.new(x,rise*(1-t),sz*(32+run*t)),Color3.fromRGB(112,125,127),Enum.Material.Metal,true)
		end
		for _,dx in {-1,1} do
			local rail=part(geo,"StairRailing",Vector3.new(.3,2.8,math.sqrt(run*run+rise*rise)),o+Vector3.new(x+dx*(G.RampWidth/2+.4),rise/2+1.8,sz*(32+run/2)),accent,Enum.Material.Metal)
			rail.CFrame*=CFrame.Angles(sz*math.atan(rise/run),0,0)
		end
		for _,dx in {-1,1} do
			part(geo,"GalleryRailing",Vector3.new((72-G.RampWidth)/2,3.1,.35),o+Vector3.new(x+dx*(G.RampWidth/2+(72-G.RampWidth)/4),rise+1.55,sz*32),accent,Enum.Material.Metal)
		end
		table.insert(probes,o+Vector3.new(x,0,sz*(32+run+5)))
	end
	furnish(props,o+Vector3.new(0,G.UpperHeight,0),{X=x,Z=0,Width=72,Depth=44,Kind=layout.Theme=="Laboratory" and "Lab" or "Workshop",Variant=2},accent)
	for _,z in {-15,15} do table.insert(zones,o+Vector3.new(x,G.UpperHeight,z)) end
	table.insert(probes,o+Vector3.new(x,G.UpperHeight,0))
	sign(props,o+Vector3.new(x,G.UpperHeight+6,-31),"ГАЛЕРЕЯ  /  02",24,accent)
end
local function buildFloor(run,seed,number,slot)
	local layout=Layout.Generate(seed,number)
	local model=Instance.new("Model"); model.Name=string.format("Floor%03d",number); model.Parent=run
	for k,v in {FloorNumber=number,Seed=layout.Seed,Theme=layout.Theme,ThemeLabel=layout.Label,Levels=layout.Upper and 2 or 1,Signature=layout.Signature,RoomCount=#layout.Rooms} do model:SetAttribute(k,v) end
	local geo,props,spawns,lobby=folder(model,"Geometry"),folder(model,"Props"),folder(model,"ZombieSpawns"),folder(model,"ElevatorLobby")
	local o=Vector3.new(0,Config.Run.BaseHeight+(slot-1)*Config.Run.FloorHeight,0)
	local accent=accents[layout.AccentIndex]
	local floorMat=layout.Theme=="Office" and Enum.Material.Carpet or Enum.Material.Concrete
	part(geo,"Floor",Vector3.new(G.HalfWidth*2,1,G.HalfDepth*2),o-Vector3.new(0,.5,0),C.floor,floorMat)
	part(geo,"Ceiling",Vector3.new(G.HalfWidth*2,1,G.HalfDepth*2),o+Vector3.new(0,G.CeilingHeight+.5,0),Color3.fromRGB(105,118,126))
	for _,x in {-G.HalfWidth,G.HalfWidth} do
		local p=part(geo,"WindowWall",Vector3.new(1,G.CeilingHeight,G.HalfDepth*2),o+Vector3.new(x,G.CeilingHeight/2,0),Color3.fromRGB(83,120,143),layout.Theme=="Parking" and Enum.Material.Metal or Enum.Material.Glass)
		p.Transparency=layout.Theme=="Parking" and .15 or .6
		for z=-120,120,24 do part(geo,"WindowMullion",Vector3.new(1.3,G.CeilingHeight,1),o+Vector3.new(x,G.CeilingHeight/2,z),C.dark,Enum.Material.Metal) end
	end
	for _,z in {-G.HalfDepth,G.HalfDepth} do part(geo,"EndWall",Vector3.new(G.HalfWidth*2,G.CeilingHeight,1),o+Vector3.new(0,G.CeilingHeight/2,z),C.wall) end
	for x=-108,108,54 do for z=-108,108,54 do
		local lamp=part(props,"CeilingLight",Vector3.new(12,.15,2),o+Vector3.new(x,G.CeilingHeight-.3,z),Color3.fromRGB(213,229,232),Enum.Material.Neon,true)
		local light=Instance.new("SurfaceLight"); light.Face=Enum.NormalId.Bottom; light.Range=42; light.Angle=140; light.Brightness=1.5; light.Color=lamp.Color; light.Parent=lamp
	end end
	local zones,probes={},{}
	for _,r in layout.Rooms do
		roomWalls(geo,props,o,r,accent); furnish(props,o,r,accent)
		sign(props,o+Vector3.new(r.X,10,r.Z-r.Depth/2+.4),roomLabels[r.Kind],24,accent)
		table.insert(zones,o+Vector3.new(r.X,0,r.Z)); table.insert(probes,o+Vector3.new(r.X,0,r.Z))
	end
	-- Clear spine, crossing aisles and outer ring connect every room and both stairs.
	for _,x in {-20,20} do for _,z in {-72,24,96} do
		part(geo,"Column",Vector3.new(2.5,G.CeilingHeight,2.5),o+Vector3.new(x,G.CeilingHeight/2,z),C.wall,Enum.Material.Concrete)
	end end
	part(props,"SpineRunner",Vector3.new(20,.025,240),o+Vector3.new(0,.02,-12),accent:Lerp(C.floor,.75),nil,true)
	for _,x in {-10,10} do part(props,"RouteStripe",Vector3.new(.2,.03,240),o+Vector3.new(x,.04,-12),accent,nil,true) end
	if layout.Theme=="Office" then
		for _,z in {-96,0,96} do for _,x in {-24,24} do plant(props,o,x,z) end end
	end
	for z=-108,84,48 do sign(props,o+Vector3.new(0,16,z),layout.Label.."  /  ЛИФТ ↓",24,accent) end
	for _,z in {-120,-24,72} do table.insert(zones,o+Vector3.new(0,0,z)) end
	for _,x in {-120,120} do for _,z in {-120,-24,72} do table.insert(zones,o+Vector3.new(x,0,z)) end end
	if layout.Upper then gallery(geo,props,o,layout,accent,zones,probes) end
	for i,v in zones do local p=part(spawns,"Zone"..i,Vector3.new(6,.1,6),v,C.red,nil,true); p.Transparency=1; p:SetAttribute("SpawnZone",true) end
	local doorZ=G.HalfDepth-20; local cabinZ=G.HalfDepth-11
	part(lobby,"CabinFloor",Vector3.new(18,.12,18),o+Vector3.new(0,.06,cabinZ),C.dark,Enum.Material.Metal)
	part(lobby,"CabinBack",Vector3.new(18,14,.6),o+Vector3.new(0,7,cabinZ+9),C.dark,Enum.Material.Metal)
	part(lobby,"CabinCeiling",Vector3.new(18,.6,18),o+Vector3.new(0,14,cabinZ),C.dark,Enum.Material.Metal)
	for _,x in {-9,9} do part(lobby,"CabinSide",Vector3.new(.6,14,18),o+Vector3.new(x,7,cabinZ),C.dark,Enum.Material.Metal) end
	local doors={}
	for i,x in {-4.5,4.5} do
		local p=part(lobby,"Door"..i,Vector3.new(8.9,13,.6),o+Vector3.new(x,6.5,doorZ),Color3.fromRGB(113,128,135),Enum.Material.Metal)
		doors[i]={Part=p,Closed=p.CFrame,Open=p.CFrame*CFrame.new(i==1 and -8.7 or 8.7,0,0)}
	end
	local indicator=part(lobby,"StatusLight",Vector3.new(15,.35,.3),o+Vector3.new(0,14,doorZ-.5),C.red,Enum.Material.Neon,true)
	local title=sign(lobby,o+Vector3.new(0,11,cabinZ+8.6),"↑  ЭТАЖ "..number,12)
	local button=part(lobby,"ElevatorButton",Vector3.new(1,1.6,.25),o+Vector3.new(6,4,cabinZ+8.5),accent,Enum.Material.Neon,true)
	local prompt=Instance.new("ProximityPrompt"); prompt.Name="NextFloor"; prompt.ActionText="На следующий этаж"; prompt.ObjectText="ЛИФТ"; prompt.HoldDuration=.25; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.Enabled=false; prompt.Parent=button
	sign(lobby,o+Vector3.new(0,17,doorZ-.5),"ЛИФТ ↑  /  "..layout.Label,27,accent)
	local spawn=Instance.new("SpawnLocation"); spawn.Name="PlayerSpawn"; spawn.Size=Vector3.new(5,.2,5); spawn.CFrame=CFrame.new(o+Vector3.new(0,.1,doorZ-14)); spawn.Anchored=true; spawn.Transparency=1; spawn.CanCollide=false; spawn.CanQuery=false; spawn.Duration=0; spawn.Enabled=false; spawn.Parent=model
	return {Model=model,Origin=o,Zones=zones,Spawn=spawn,Doors=doors,Indicator=indicator,Prompt=prompt,Title=title,
		Cabin=CFrame.new(o+Vector3.new(0,3,cabinZ)),Entry=CFrame.new(o+Vector3.new(0,3,doorZ-14)),ExitZ=doorZ-3,
		Bounds={Origin=o,HalfWidth=G.HalfWidth-3,HalfDepth=G.HalfDepth-3},Probes=probes,Layout=layout,Slot=slot}
end
function OfficeMap.CreateFloor(map,number,slot)
	return buildFloor(map.Run,map.Seed,number,slot)
end
function OfficeMap.Build()
	local old=workspace:FindFirstChild("OfficeRun"); if old then old:Destroy() end
	for _,n in {"Baseplate","SpawnLocation","CombatArena"} do local x=workspace:FindFirstChild(n); if x then x:Destroy() end end
	local map={Run=folder(workspace,"OfficeRun"),Seed=Random.new():NextInteger(1,2000000000)}
	map.Current=OfficeMap.CreateFloor(map,1,1)
	local skyline=folder(map.Run,"Skyline")
	for i=1,18 do
		local angle=i*math.pi*2/18; local distance=360+(i%3)*70; local height=130+(i*37)%150
		local p=part(skyline,"DistantTower",Vector3.new(40+(i%4)*9,height,42),Vector3.new(math.cos(angle)*distance,height/2,math.sin(angle)*distance),Color3.fromRGB(34,48,64),Enum.Material.Concrete)
		for y=25,height-8,36 do part(skyline,"LitStorey",Vector3.new(p.Size.X+.1,.6,42.1),Vector3.new(p.Position.X,y,p.Position.Z),Color3.fromRGB(112,144,153),Enum.Material.Neon,true) end
	end
	local lighting=game:GetService("Lighting"); lighting.ClockTime=19.2; lighting.Brightness=3; lighting.Ambient=Color3.fromRGB(158,164,177); lighting.OutdoorAmbient=Color3.fromRGB(96,117,143); lighting.FogColor=Color3.fromRGB(39,58,78); lighting.FogStart=310; lighting.FogEnd=850
	return map
end
return OfficeMap
