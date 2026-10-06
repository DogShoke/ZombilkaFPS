-- First milestone: fixed Office OpenArena topology, seeded whole-tile variants only.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Tiles=require(script.Parent.OfficeTiles)
local G,E=Config.Run.Generation,Config.Run.Encounters
local Layout={}
local roles={O="OPEN",C="COVER",H="HARD_COVER",E="ELEVATED",L="LANDMARK",S="START",Z="SPAWN_EDGE"}
local rows={"ZOOOZ","OCOCO","OOLOO","OCOEO","ZOSOZ"}
function Layout.Generate(runSeed,number,attempt,override)
 attempt=attempt or 1;override=override or {}
 local seed=(runSeed+number*104729+G.Version*1009+(attempt-1)*7919)%2147483647
 local rng=Random.new(seed);local size=G.CellSize;local half=G.GridSize*size/2
 local cells,covers,zones,nodes={},{},{},{{Id="Entry",X=0,Y=0,Z=half-34}}
 local landmark,elevated;local occupied=0;local ids={}
 for row,line in rows do for col=1,#line do
  local role=roles[line:sub(col,col)];local module=Tiles.Select(role,rng,override.Fixed)
  local c={Id=string.format("Tile_%d_%d",row,col),Row=row,Column=col,Role=role,Module=module.Id,
   X=(col-3)*size,Z=(row-3)*size,Y=0,Yaw=0,Width=module.Width,Depth=module.Depth,Purpose=module.Purpose}
  if module.Elevation then c.Y=module.Elevation.Height;elevated=c end
  table.insert(cells,c);table.insert(ids,module.Id)
  if #module.Slots>0 then table.insert(covers,c);occupied+=module.Width*module.Depth end
  if role=="LANDMARK"then landmark=c
  elseif role=="SPAWN_EDGE"then table.insert(zones,{Id=c.Id,Position=Vector3.new(c.X,0,c.Z),Radius=10,EntryKind="Ground",Weight=1,AttackDirection=row==1 and "North"or"South"})
  elseif role=="OPEN"then table.insert(nodes,{Id=c.Id,X=c.X,Y=0,Z=c.Z})end
 end end
 table.insert(nodes,{Id="Upper",X=elevated.X,Y=elevated.Y,Z=elevated.Z+2})
 local function edge(id,points)return {Id=id,Width=G.RouteWidth,Points=points}end
 local v=Vector3.new
 local edges={
  edge("Main",{v(0,0,half-34),v(0,0,18),v(18,0,0),v(0,0,-18),v(0,0,-72)}),
  edge("WestRotation",{v(0,0,half-34),v(-72,0,56),v(-72,0,-72),v(0,0,-72)}),
  edge("EastRotation",{v(0,0,half-34),v(72,0,56),v(72,0,-72),v(0,0,-72)}),
  edge("CrossNorth",{v(-72,0,-18),v(72,0,-18)}),edge("CrossSouth",{v(-72,0,18),v(72,0,18)}),
  edge("RaisedNorth",{v(36,0,18),v(36,6,38)}),edge("RaisedSouth",{v(36,0,54),v(36,6,38)})}
 return {GenerationVersion=G.Version,RunSeed=runSeed,Seed=seed,Number=number,Attempt=attempt,
  Theme="Office",Label="ОФИСЫ",Macro="OpenArena",MacroLabel="ОФИСНАЯ АРЕНА 5×5",HalfWidth=half,HalfDepth=half,
  CellSize=size,Cells=cells,Covers=covers,Nodes=nodes,Edges=edges,StartNode="Entry",SpawnZones=zones,
  Landmarks={{Id="Main",ClusterId=landmark.Id,Position=v(landmark.X,0,landmark.Z)}},
  ElevatedTile=elevated,Upper=true,Sections={},Sources={},
  DefenseZones={{Id="Entrance",Position=v(0,0,half-34),Width=24,Depth=24},{Id="Upper",Position=v(36,6,38),Width=16,Depth=10}},
  Encounter={Mode="KillQuota",Quota=E.KillQuota+math.min((number-1)*E.QuotaPerFloor,E.MaxQuotaExtra),Duration=0},
  AccentIndex=1,OpenSpaceFraction=1-occupied/(half*half*4),Variant=table.concat(ids,","),
  Signature=string.format("tiles%d:Office:OpenArena:%d:%d",G.Version,seed,attempt)}
end
function Layout.Validate(p)
 if p.Theme~="Office"or p.Macro~="OpenArena"or p.Encounter.Mode~="KillQuota"then return false,"Prototype scope changed"end
 if #p.Cells~=25 or #p.SpawnZones~=4 or #p.Covers~=5 then return false,"Wrong prototype cell count"end
 local seen={}
 for _,c in p.Cells do
  if c.Role~=roles[rows[c.Row]:sub(c.Column,c.Column)]or seen[c.Id]then return false,"Changed fixed cell role"end
  seen[c.Id]=true;local m=Tiles.Get(c.Role,c.Module)
  if c.Width>p.CellSize or c.Depth>p.CellSize then return false,"Tile exceeds cell"end
  if c.Role~="ELEVATED"and(c.Width>p.CellSize-12 or c.Depth>p.CellSize-12)then return false,"Missing cell edge lanes"end
  if c.X~=(c.Column-3)*p.CellSize or c.Z~=(c.Row-3)*p.CellSize or not m.Purpose then return false,"Invalid cell placement"end
 end
 if p.Encounter.Quota<1 or p.Encounter.Quota%1~=0 then return false,"Invalid quota"end
 return true
end
return Layout
