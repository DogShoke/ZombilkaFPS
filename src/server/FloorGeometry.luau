local Config = require(game.ReplicatedStorage.Shared.Config)
local Pathfinding = game:GetService("PathfindingService")
local G = Config.Run.Generation
local Geometry = {}
local function inRect(x,z,r)
	return math.abs(x-r.X)<=r.Width/2+.01 and math.abs(z-r.Z)<=r.Depth/2+.01
end
function Geometry.Regions(plan)
	local regions={}
	for _,n in plan.Nodes do table.insert(regions,{X=n.X,Z=n.Z,Width=n.Width,Depth=n.Depth}) end
	for _,edge in plan.Edges do
		for i=2,#edge.Points do
			local a,b=edge.Points[i-1],edge.Points[i]
			table.insert(regions,{X=(a.X+b.X)/2,Z=(a.Z+b.Z)/2,Width=math.abs(a.X-b.X)+edge.Width,Depth=math.abs(a.Z-b.Z)+edge.Width})
		end
	end
	-- Door and cabin remain in their original location.
	table.insert(regions,{X=0,Z=G.HalfDepth-11,Width=18,Depth=20})
	return regions
end
function Geometry.BuildWalls(plan,origin,parent,makePart,color)
	local regions=Geometry.Regions(plan)
	local runs,open={},{}
	local nx,nz=math.floor(G.HalfWidth*2/G.Grid),math.floor(G.HalfDepth*2/G.Grid)
	for iz=1,nz do
		local z=-G.HalfDepth+(iz-.5)*G.Grid
		local row={}; local start
		for ix=1,nx+1 do
			local blocked=ix<=nx
			if blocked then local x=-G.HalfWidth+(ix-.5)*G.Grid; for _,r in regions do if inRect(x,z,r) then blocked=false break end end end
			if blocked and not start then start=ix end
			if not blocked and start then
				local key=start..":"..(ix-1); local run=open[key]
				if run and run.LastRow==iz-1 then run.LastRow=iz else run={Start=start,End=ix-1,FirstRow=iz,LastRow=iz}; table.insert(runs,run) end
				row[key]=run; start=nil
			end
		end
		open=row
	end
	for _,r in runs do
		local width=(r.End-r.Start+1)*G.Grid; local depth=(r.LastRow-r.FirstRow+1)*G.Grid
		local x=-G.HalfWidth+(r.Start-1)*G.Grid+width/2; local z=-G.HalfDepth+(r.FirstRow-1)*G.Grid+depth/2
		makePart(parent,"LayoutWall",Vector3.new(width,G.CeilingHeight,depth),origin+Vector3.new(x,G.CeilingHeight/2,z),color)
	end
	return #runs
end
function Geometry.Validate(floor,full)
	local start=os.clock(); local count=0
	local function check(a,b,label)
		if os.clock()-start>G.MaxValidationSeconds then return false,"Navigation timeout" end
		local path=Pathfinding:CreatePath({AgentRadius=G.AgentRadius,AgentHeight=G.AgentHeight,AgentCanJump=true})
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
	if full then
		for _,e in floor.Layout.Edges do for i=2,#e.Points do
			local ok,reason=check(floor.Origin+e.Points[i-1],floor.Origin+e.Points[i],e.Id.." segment "..i)
			if not ok then return false,reason,count,os.clock()-start end
		end end
	end
	return true,nil,count,os.clock()-start
end
return Geometry
