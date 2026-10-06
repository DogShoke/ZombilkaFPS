local Config = require(game.ReplicatedStorage.Shared.Config)
local Pathfinding = game:GetService("PathfindingService")
local G = Config.Run.Generation
local Geometry = {}
-- Exact union of axis-aligned projected hull rectangles, including stacked cargo once.
local function footprint(rectangles)
 local xs={};for _,r in rectangles do table.insert(xs,r[1]);table.insert(xs,r[2])end;table.sort(xs)
 local area=0
 for i=2,#xs do
  local a,b=xs[i-1],xs[i]
  if b>a then
   local intervals={};for _,r in rectangles do if r[1]<b and r[2]>a then table.insert(intervals,{r[3],r[4]})end end
   table.sort(intervals,function(x,y)return x[1]<y[1]end)
   local length,low,high=0,nil,nil
   for _,r in intervals do if not low then low,high=r[1],r[2]elseif r[1]<=high then high=math.max(high,r[2])else length+=high-low;low,high=r[1],r[2]end end
   if low then length+=high-low end;area+=(b-a)*length
  end
 end
 return area
end
local function composition(floor)
 local rects,hulls,obstacles={},0,0
 -- Check actual visual bounds too: a tile must fit, even if its data envelope does.
 for _,cell in floor.Layout.Cells do
  local group=floor.Model.Props[cell.Id]
  local margin=cell.Role=="ELEVATED"and 2 or 6
  for _,p in group:GetDescendants()do if p:IsA("BasePart")and p.Name~="Wayfinding"then
   local rx=(math.abs(p.CFrame.RightVector.X)*p.Size.X+math.abs(p.CFrame.LookVector.X)*p.Size.Z)/2
   local rz=(math.abs(p.CFrame.RightVector.Z)*p.Size.X+math.abs(p.CFrame.LookVector.Z)*p.Size.Z)/2
   if math.abs(p.Position.X-floor.Origin.X-cell.X)+rx>floor.Layout.CellSize/2-margin+.1
    or math.abs(p.Position.Z-floor.Origin.Z-cell.Z)+rz>floor.Layout.CellSize/2-margin+.1 then return false,"Tile footprint exceeded "..cell.Id.."/"..p.Parent.Name end
  end end
 end
 local elevated=floor.Layout.ElevatedTile
 for _,p in floor.Model.Geometry:GetChildren()do if p:IsA("BasePart")and p:GetAttribute("TileId")==elevated.Id then
  local cf,s=p.CFrame,p.Size
  local rx=(math.abs(cf.RightVector.X)*s.X+math.abs(cf.UpVector.X)*s.Y+math.abs(cf.LookVector.X)*s.Z)/2
  local rz=(math.abs(cf.RightVector.Z)*s.X+math.abs(cf.UpVector.Z)*s.Y+math.abs(cf.LookVector.Z)*s.Z)/2
  if math.abs(p.Position.X-floor.Origin.X-elevated.X)+rx>floor.Layout.CellSize/2-2
   or math.abs(p.Position.Z-floor.Origin.Z-elevated.Z)+rz>floor.Layout.CellSize/2-2 then return false,"Elevated structure outside tile"end
 end end
 for _,m in floor.Model.Props:GetDescendants()do
  if m:IsA("Model")and m:GetAttribute("GameplayObstacle")then
   obstacles+=1;local h=m:FindFirstChild("CoverCollision")
   if not h or not h.CanCollide or not h.CanQuery then return false,"Missing obstacle collision "..m.Name end
  elseif m:IsA("BasePart")and m.Name=="CoverCollision"then
   hulls+=1
   local x,z=m.Position.X,m.Position.Z
   local rx=(math.abs(m.CFrame.RightVector.X)*m.Size.X+math.abs(m.CFrame.LookVector.X)*m.Size.Z)/2
   local rz=(math.abs(m.CFrame.RightVector.Z)*m.Size.X+math.abs(m.CFrame.LookVector.Z)*m.Size.Z)/2
   table.insert(rects,{x-rx,x+rx,z-rz,z+rz})
  end
 end
 if hulls~=obstacles or hulls<#floor.Layout.Covers then return false,"Invalid collision count"end
 local fraction=footprint(rects)/(floor.Layout.HalfWidth*floor.Layout.HalfDepth*4)
 floor.Model:SetAttribute("HullFootprintFraction",fraction)
 -- An elevated platform/ramp is a meaningful structure, even where its ground is open.
 for _,p in floor.Model.Geometry:GetChildren()do if p:IsA("BasePart")and(p.Name=="StairRamp"or p.Name=="Floor"and p.Position.Y>floor.Origin.Y+1)then
  local x,z=p.Position.X,p.Position.Z;local rx=p.Size.X/2;local rz=math.abs(p.CFrame.LookVector.Z)*p.Size.Z/2
  table.insert(rects,{x-rx,x+rx,z-rz,z+rz})
 end end
 local structured=footprint(rects)/(floor.Layout.HalfWidth*floor.Layout.HalfDepth*4)
 floor.Model:SetAttribute("CombatStructureFraction",structured)
 if structured<G.MinHullFraction or structured>G.MaxHullFraction then return false,"Actual obstacle density "..structured end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={floor.Model.Geometry,floor.Model.Props}
 local eye=floor.Entry.Position+Vector3.new(0,2.5,0);local visible=0
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={floor.Model}
 for _,p in workspace:GetPartBoundsInBox(floor.Entry,Vector3.new(6,5,6),overlap)do if p.CanCollide and p.Name~="Floor"then return false,"Blocked entrance "..p.Name end end
 for _,n in floor.Layout.Nodes do if n.Id~="Entry"then
  local to=floor.Origin+Vector3.new(n.X,n.Y+5.5,n.Z);local hit=workspace:Raycast(eye,to-eye,params)
  if not hit then visible+=1 end
 end end
 floor.Model:SetAttribute("VisibleCombatPoints",visible)
 if visible<2 then return false,"Entrance has no readable combat view"end
 local landmark=floor.Model.Props:FindFirstChild(floor.Layout.Landmarks[1].ClusterId)
 local seen=false
 for _,m in landmark:GetChildren()do if m:IsA("Model")and m.PrimaryPart then
  local hit=workspace:Raycast(eye,m.PrimaryPart.Position-eye,params)
  if not hit or hit.Instance:IsDescendantOf(landmark)then seen=true;break end
 end end
 if not seen then return false,"Landmark hidden from entrance"end
 return true
end
function Geometry.Validate(floor,full)
	local start=os.clock(); local count=0
	local good,reason=composition(floor);if not good then return false,reason,0,os.clock()-start end
	local function check(a,b,label,radius)
		if (a-b).Magnitude<1 then return true end
		if os.clock()-start>G.MaxValidationSeconds then return false,"Navigation timeout" end
		local path=Pathfinding:CreatePath({AgentRadius=radius or G.AgentRadius,AgentHeight=G.AgentHeight,AgentCanJump=true})
		local ok=pcall(function() path:ComputeAsync(a+Vector3.new(0,3,0),b+Vector3.new(0,3,0)) end)
		count+=1
		if not ok or path.Status~=Enum.PathStatus.Success then return false,"Unreachable "..label end
		return true
	end
	task.wait(G.NavigationSettle)
	for _,n in floor.Layout.Nodes do
		local ok,reason=check(floor.Entry.Position-Vector3.new(0,3,0),floor.Origin+Vector3.new(n.X,n.Y,n.Z),n.Id)
		if not ok then return false,reason,count,os.clock()-start end
	end
	-- Each spawn source is checked against a defense, including both gallery approaches.
	for _,s in floor.Zones do
		for i,d in floor.DefenseZones do
			if full or i==1 or floor.Layout.Upper then
				local ok,reason=check(s.Position,d.Position,s.Id.." -> "..d.Id)
				if not ok then return false,reason,count,os.clock()-start end
			end
		end
	end
	-- Wide-agent queries prove rotations are more than single-NPC passages.
	for _,e in floor.Layout.Edges do if full or e.Id=="Main"or e.Id=="WestRotation"or e.Id=="EastRotation"then for i=2,#e.Points do
			local ok,reason=check(floor.Origin+e.Points[i-1],floor.Origin+e.Points[i],e.Id.." segment "..i,G.WideRouteRadius)
			if not ok then return false,reason,count,os.clock()-start end
		end end
	end
	for _,s in floor.Layout.Sources do local ok,r=check(floor.Entry.Position-Vector3.new(0,3,0),floor.Origin+s.Approach,s.Id.." approach");if not ok then return false,r,count,os.clock()-start end end
	return true,nil,count,os.clock()-start
end
return Geometry
