local Config = require(game.ReplicatedStorage.Shared.Config)
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
local Layout=require(script.Parent.FloorLayout)
local Geometry=require(script.Parent.FloorGeometry)
local ArenaAssets=require(script.Parent.ArenaAssets)
local Tiles=require(script.Parent.OfficeTiles)
local G=Config.Run.Generation
local accents={C.teal,Color3.fromRGB(89,125,185),Color3.fromRGB(203,148,65),Color3.fromRGB(129,111,163)}
local function buildFloor(run,layout,slot,greybox)
 local started=os.clock();local number=layout.Number
 local model=Instance.new("Model");model.Name=string.format("Floor%03d",number);model.Parent=run
 for k,v in {FloorNumber=number,Seed=layout.Seed,RunSeed=layout.RunSeed,GenerationVersion=layout.GenerationVersion,Macro=layout.Macro,Theme=layout.Theme,ThemeLabel=layout.Label,Levels=layout.Upper and 2 or 1,Signature=layout.Signature,Attempt=layout.Attempt,OpenSpaceFraction=layout.OpenSpaceFraction}do model:SetAttribute(k,v)end
 local geo,props,spawns,lobby=folder(model,"Geometry"),folder(model,"Props"),folder(model,"ZombieSpawns"),folder(model,"ElevatorLobby")
 local o=Vector3.new(0,Config.Run.BaseHeight+(slot-1)*Config.Run.FloorHeight,0)
 local accent=accents[layout.AccentIndex]
 part(geo,"Floor",Vector3.new(layout.HalfWidth*2,1,layout.HalfDepth*2),o-Vector3.new(0,.5,0),C.floor,layout.Theme=="Office"and Enum.Material.Carpet or Enum.Material.Concrete)
 part(geo,"Ceiling",Vector3.new(layout.HalfWidth*2,1,layout.HalfDepth*2),o+Vector3.new(0,G.CeilingHeight+.5,0),Color3.fromRGB(105,118,126))
 -- Only the exterior enclosure: no graph-complement room walls.
 for _,x in {-layout.HalfWidth,layout.HalfWidth}do
  local wall=part(geo,"WindowWall",Vector3.new(1,G.CeilingHeight,layout.HalfDepth*2),o+Vector3.new(x,G.CeilingHeight/2,0),Color3.fromRGB(83,120,143),Enum.Material.Glass);wall.Transparency=.5
 end
 for _,z in {-layout.HalfDepth,layout.HalfDepth}do part(geo,"EndWall",Vector3.new(layout.HalfWidth*2,G.CeilingHeight,1),o+Vector3.new(0,G.CeilingHeight/2,z),C.wall)end
 for _,x in {-layout.HalfWidth*.65,0,layout.HalfWidth*.65}do for _,z in {-layout.HalfDepth*.72,-layout.HalfDepth*.24,layout.HalfDepth*.24,layout.HalfDepth*.72}do
  local lamp
  if greybox then lamp=part(props,"CeilingLight",Vector3.new(14,.15,2),o+Vector3.new(x,G.CeilingHeight-.3,z),Color3.fromRGB(213,229,232),Enum.Material.Neon,true)
  else
   local name=layout.Theme=="Parking"and "ParkingHangingLight"or "CeilingLampLong"
   local height=game.ReplicatedStorage.Assets.EnvironmentKit[name].PrimaryPart.Size.Y*G.StudsPerMeter
   local fixture=ArenaAssets.Place(name,props,CFrame.new(o+Vector3.new(x,G.CeilingHeight-height-.05,z)),nil,false,G.StudsPerMeter)
   lamp=fixture.PrimaryPart
  end
  local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Range=65;light.Angle=140;light.Brightness=1.8;light.Parent=lamp
 end end
 local zones,probes,defenses={},{},{}
 for _,n in layout.Nodes do table.insert(probes,o+Vector3.new(n.X,n.Y,n.Z))end
 for _,cell in layout.Cells do
  local module=Tiles.Get(cell.Role,cell.Module)
  local group=folder(props,cell.Id);local base=o+Vector3.new(cell.X,cell.Y,cell.Z)
  for k,v in {Module=cell.Module,Purpose=cell.Purpose,Role=cell.Role,Row=cell.Row,Column=cell.Column,CellX=cell.X,CellZ=cell.Z}do group:SetAttribute(k,v)end
  if module.Elevation then
   local e=module.Elevation;local center=o+Vector3.new(cell.X,0,cell.Z)
   local platform=part(geo,"Floor",Vector3.new(e.Width,.6,e.Depth),center+Vector3.new(0,e.Height-.3,0),C.dark,Enum.Material.Metal);platform:SetAttribute("TileId",cell.Id)
   for _,side in {-1,1}do
    local ramp=part(geo,"StairRamp",Vector3.new(e.RampWidth,.4,math.sqrt(e.RampLength^2+e.Height^2)),center+Vector3.new(0,e.Height/2,side*(e.Depth/2+e.RampLength/2)),C.dark,Enum.Material.Metal)
    ramp:SetAttribute("TileId",cell.Id)
    ramp.CFrame*=CFrame.Angles(side*math.atan(e.Height/e.RampLength),0,0)
   end
   for _,side in {-1,1}do local rail=part(geo,"GalleryRailing",Vector3.new(.25,2.8,e.Depth),center+Vector3.new(side*e.Width/2,e.Height+1.4,0),accent,Enum.Material.Metal);rail:SetAttribute("TileId",cell.Id)end
  end
  local transform=CFrame.new(base)
  for _,slot in module.Slots do
   local model=ArenaAssets.Place(slot[1],group,transform*CFrame.new(slot[2],slot[6]or 0,slot[3])*CFrame.Angles(0,math.rad(slot[4]),0),nil,slot[5],G.StudsPerMeter)
   model:SetAttribute("GameplayObstacle",slot[5])
  end
  if #module.Slots>0 or module.FloorPatch then part(group,"TileFloor",Vector3.new(cell.Width,.025,cell.Depth),base+Vector3.new(0,.015,0),Color3.fromRGB(62,72,77),Enum.Material.Carpet,true)end
  if module.Sign then sign(group,base+Vector3.new(0,11,-8),module.Sign,20,accent)end
  if module.Cracks then ArenaAssets.Place("GroundCracks",group,transform*CFrame.new(0,.025,0),.12,false)end
 end
 for _,d in layout.DefenseZones do local copy=table.clone(d);copy.Position=o+d.Position;table.insert(defenses,copy)end
 for _,s in layout.SpawnZones do local copy=table.clone(s);copy.Position=o+s.Position;table.insert(zones,copy)end
 local gates={}
 for _,s in layout.Sections do if s.GateZ then
  local gate=part(geo,"SectionGate"..s.Id,Vector3.new(layout.HalfWidth*2-2,G.CeilingHeight,.8),o+Vector3.new(0,G.CeilingHeight/2,s.GateZ),accent,Enum.Material.ForceField);gate.Transparency=.45;gate.CanCollide=false;gate.CanQuery=false
  table.insert(gates,{Part=gate,Id=s.Id})
  sign(props,o+Vector3.new(0,9,s.GateZ+1),"ПРОРЫВ  /  СЕКТОР "..(s.Id+1),30,accent)
 end end
 sign(props,o+Vector3.new(0,16,-16),layout.MacroLabel,30,accent)
	local doorZ=layout.HalfDepth-20; local cabinZ=layout.HalfDepth-11
	-- Three local entry bays share one destination and the existing two floor slots.
	local bays,doors={},{}
	for index,x in {-18,0,18}do
		local parent=index==2 and lobby or folder(lobby,"RewardBay"..index)
		part(parent,"CabinFloor",Vector3.new(18,.12,18),o+Vector3.new(x,.06,cabinZ),C.dark,Enum.Material.Metal)
		part(parent,"CabinBack",Vector3.new(18,14,.6),o+Vector3.new(x,7,cabinZ+9),C.dark,Enum.Material.Metal)
		part(parent,"CabinCeiling",Vector3.new(18,.6,18),o+Vector3.new(x,14,cabinZ),C.dark,Enum.Material.Metal)
		for _,side in {-9,9}do part(parent,"CabinSide",Vector3.new(.6,14,18),o+Vector3.new(x+side,7,cabinZ),C.dark,Enum.Material.Metal)end
		local bay={Cabin=CFrame.new(o+Vector3.new(x,3,cabinZ)),Doors={}}
		for i,offset in {-4.5,4.5}do
			local p=part(parent,"Door"..i,Vector3.new(8.9,13,.6),o+Vector3.new(x+offset,6.5,doorZ),Color3.fromRGB(113,128,135),Enum.Material.Metal)
			-- Vertical retraction keeps open panels out of neighboring entry bays.
			local door={Part=p,Closed=p.CFrame,Open=p.CFrame*CFrame.new(0,13.3,0)}
			table.insert(doors,door);table.insert(bay.Doors,door)
		end
		bay.Indicator=part(parent,"StatusLight",Vector3.new(15,.35,.3),o+Vector3.new(x,14,doorZ-.5),C.red,Enum.Material.Neon,true)
		bay.Sign=sign(parent,o+Vector3.new(x,16,doorZ-.7),"НАГРАДА / ПОСЛЕ ЗАЧИСТКИ",18,accent)
		bay.Sign.CFrame*=CFrame.Angles(0,math.pi,0)
		local button=part(parent,"ElevatorButton",Vector3.new(1,1.6,.25),o+Vector3.new(x+6,4,cabinZ+8.5),accent,Enum.Material.Neon,true)
		local prompt=Instance.new("ProximityPrompt");prompt.Name="NextFloor";prompt.ActionText="Выбрать награду";prompt.ObjectText="ЛИФТ";prompt.HoldDuration=.25;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Enabled=false;prompt.Parent=button
		bay.Prompt=prompt;bays[index]=bay
	end
	local indicator=bays[2].Indicator
	local title=sign(lobby,o+Vector3.new(0,11,cabinZ+8.6),"↑  ЭТАЖ "..number,12)
	local prompt=bays[2].Prompt
	local spawn=Instance.new("SpawnLocation"); spawn.Name="PlayerSpawn"; spawn.Size=Vector3.new(5,.2,5); spawn.CFrame=CFrame.new(o+Vector3.new(0,.1,doorZ-14)); spawn.Anchored=true; spawn.Transparency=1; spawn.CanCollide=false; spawn.CanQuery=false; spawn.Duration=0; spawn.Enabled=false; spawn.Parent=model

 local count=0;for _,p in model:GetDescendants()do if p:IsA("BasePart")then count+=1 end end
 model:SetAttribute("PartCount",count);model:SetAttribute("BuildSeconds",os.clock()-started)
 return {Model=model,Origin=o,Zones=zones,DefenseZones=defenses,Signals={},Gates=gates,Spawn=spawn,Doors=doors,Bays=bays,Indicator=indicator,Prompt=prompt,Title=title,Cabin=CFrame.new(o+Vector3.new(0,3,cabinZ)),Entry=CFrame.new(o+Vector3.new(0,3,doorZ-14)),ExitZ=doorZ-3,Bounds={Origin=o,HalfWidth=layout.HalfWidth-3,HalfDepth=layout.HalfDepth-3},Probes=probes,Layout=layout,Slot=slot}
end
function OfficeMap.SetSection(floor,section)
 for _,g in floor.Gates do local locked=g.Id>=section;g.Part.CanCollide=locked;g.Part.CanQuery=locked;g.Part.Transparency=locked and .45 or 1 end
end
function OfficeMap.CreateFloor(map,number,slot,options)
	options=options or {}
	local failures={}
	for attempt=1,G.MaxAttempts+1 do
		local fallback=attempt>G.MaxAttempts
		local override=options.Override
		if fallback then override={Macro="OpenArena",Fixed=true}; if options.Override then override.Theme=options.Override.Theme end end
		local plan=Layout.Generate(map.Seed,number,attempt,override)
		local valid,reason=Layout.Validate(plan)
		if valid then
			local staging=folder(map.Run,"PreparingFloor")
			local built,floor=pcall(buildFloor,staging,plan,slot,options.Greybox)
			if not built then
				staging:Destroy(); table.insert(failures,"Build failed: "..tostring(floor)); continue
			end
			floor.Model.Parent=map.Run; staging:Destroy()
			local checks,seconds
			if floor.Model:GetAttribute("PartCount")>G.MaxParts then valid,reason=false,"Part limit"
			elseif options.SkipValidation then valid=true
			else
				local checked,result,r,c,s=pcall(Geometry.Validate,floor,options.FullValidation)
				valid,reason,checks,seconds=checked and result,checked and r or tostring(result),c,s
			end
			if valid then
				floor.Model:SetAttribute("NavigationChecks",checks or 0); floor.Model:SetAttribute("ValidationSeconds",seconds or 0)
				floor.Model:SetAttribute("Validated",not options.SkipValidation); floor.Model:SetAttribute("Fallback",fallback)
				floor.Model:SetAttribute("FallbackReason",table.concat(failures,"; "))
				return floor
			end
			floor.Model:Destroy()
		end
		table.insert(failures,string.format("seed=%d floor=%d v=%d attempt=%d: %s",map.Seed,number,G.Version,attempt,tostring(reason)))
	end
	error("Floor validation failed: "..table.concat(failures,"; "))
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
