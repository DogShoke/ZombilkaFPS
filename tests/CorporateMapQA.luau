-- QA-only ModuleScript: return require(module)(map, options). Never shipped by Rojo.
-- Run in native Play after the map is parented to Workspace. All evidence is JSON-safe.
-- Optional ActorModel must be a QA-owned live Humanoid rig; this module never moves
-- a user character. Its original position, speed and jump settings are restored.
local Pathfinding = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

return function(map, options)
	options = options or {}
	assert(map.Model and map.Model:IsDescendantOf(Workspace), "Map must be in Workspace")
	local report = {Name="CorporateMapQA", Mode="NativeStudio", Passed=true, Checks={}, Paths={},
		ActorWalk={Status="NOT TESTED", Reason="Pass a dedicated QA ActorModel to exercise native movement"},
		FunAssessment="REQUIRES USER PLAYTEST: navigation is not evidence of enjoyable level design"}
	local started = os.clock()
	local function xyz(v) return {X=v.X,Y=v.Y,Z=v.Z} end
	local function check(name, passed, detail)
		table.insert(report.Checks,{Name=name,Passed=passed,Detail=detail})
		if not passed then report.Passed=false end
	end
	local parts, colliders, hulls, meshes, badHulls = 0,0,0,0,{}
	for _,item in map.Model:GetDescendants() do
		if item:IsA("BasePart") then
			parts+=1
			if item.CanCollide then colliders+=1 end
			if item:IsA("MeshPart") then meshes+=1 end
			if item.Name=="CoverCollision" then
				hulls+=1
				if not item.Anchored or not item.CanCollide or not item.CanQuery then table.insert(badHulls,item:GetFullName()) end
			end
		end
	end
	report.Counts={Parts=parts,Colliders=colliders,CoverHulls=hulls,Meshes=meshes}
	check("Bounded authored footprint", map.Bounds.HalfWidth>=145 and map.Bounds.HalfWidth<=200
		and map.Bounds.HalfDepth>=145 and map.Bounds.HalfDepth<=200, xyz(map.Origin))
	check("Three connected zone definitions", #map.Layout.ZoneRegions==3, #map.Layout.ZoneRegions)
	check("PartCount matches actual world", parts==map.Model:GetAttribute("PartCount"), parts)
	check("Initial part budget", parts<=1500, "1500 is a QA investigation threshold, not a measured performance guarantee")
	check("Meaningful cover has combat hulls", hulls>=25 and #badHulls==0, {Count=hulls,Invalid=badHulls})
	local nodeById={}
	for _,node in map.NavGraph.Nodes do nodeById[node.Id]=map.Origin+Vector3.new(node.X,node.Y+3,node.Z) end
	local function path(label, from, to)
		local p=Pathfinding:CreatePath({AgentRadius=2.5,AgentHeight=6,AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=6})
		local ok,err=pcall(function()p:ComputeAsync(from,to)end)
		local points=ok and p.Status==Enum.PathStatus.Success and p:GetWaypoints() or {}
		local jumps=0;local length=0
		for i,point in points do
			if point.Action==Enum.PathWaypointAction.Jump then jumps+=1 end
			if i>1 then length+=(point.Position-points[i-1].Position).Magnitude end
		end
		local success=ok and p.Status==Enum.PathStatus.Success and #points>0 and jumps==0
		table.insert(report.Paths,{Name=label,Passed=success,From=xyz(from),To=xyz(to),
			Status=ok and p.Status.Name or "Error",Error=not ok and tostring(err) or nil,Waypoints=#points,Jumps=jumps,Length=length})
		if not success then report.Passed=false end
		return success,points
	end
	-- One path request at a time; no mass parallel nav workload.
	for _,zone in map.Zones do path("LaneToSpawn:"..zone.Id,zone.Position+Vector3.new(0,3,0),map.Entry.Position) end
	for _,region in map.Layout.ZoneRegions do
		local destination=map.Origin+Vector3.new(region.X,3,0)
		path("SpawnToZone:"..region.Id,map.Entry.Position,destination)
	end
	local narrow={}
	for _,edge in map.NavGraph.Edges do
		if edge.Width<12 then table.insert(narrow,edge.From.."/"..edge.To) end
		local a,b=nodeById[edge.From],nodeById[edge.To]
		if a and b then path("AuthoredRoute:"..edge.From.."/"..edge.To,a,b)
		else check("Valid navigation edge",false,edge.From.."/"..edge.To) end
	end
	check("Declared routes at least 12 studs", #narrow==0, narrow)
	-- Test intended route width physically, not only the declaration. At 12-stud
	-- intervals sample a 12x5 corridor centered 3 studs above the support surface.
	local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances={map.Model};overlap.RespectCanCollide=true
	local obstructions={}
	for _,edge in map.NavGraph.Edges do
		local a,b=nodeById[edge.From],nodeById[edge.To]
		if not a or not b then continue end
		local delta=b-a;local count=math.max(1,math.ceil(delta.Magnitude/12))
		for i=0,count do
			local point=a+delta*(i/count)
			local cf=CFrame.lookAt(point,point+delta.Unit)
			for _,hit in Workspace:GetPartBoundsInBox(cf,Vector3.new(12,5,2),overlap) do
				if hit.Name~="Floor" then
					table.insert(obstructions,{Edge=edge.From.."/"..edge.To,Part=hit:GetFullName(),At=xyz(point)})
				end
			end
		end
	end
	check("Authored route physical width",#obstructions==0,obstructions)
	for _,deck in map.Layout.MaintenanceDecks or {} do
		local probe
		for _,candidate in map.DeckProbes or {} do if candidate.Id==deck.Id then probe=candidate;break end end
		if not probe then check("Maintenance deck probe",false,deck.Id);continue end
		for _,side in {-1,1} do
			local approach=map.Origin+Vector3.new(deck.X,3,deck.Z+side*(deck.Depth/2+deck.RampLength+5))
			path("DeckApproach:"..deck.Id..":"..side,approach,probe.Position+Vector3.new(0,3,0))
		end
	end
	local actor=options.ActorModel
	local h=actor and actor:FindFirstChildOfClass("Humanoid")
	local root=actor and actor:FindFirstChild("HumanoidRootPart")
	if h and root and h.Health>0 and actor:IsDescendantOf(Workspace) then
		assert(not game.Players:GetPlayerFromCharacter(actor),"ActorModel must not be a user character")
		local original=actor:GetPivot();local speed,jumpPower,jumpHeight=h.WalkSpeed,h.JumpPower,h.JumpHeight
		local canJump=h:GetStateEnabled(Enum.HumanoidStateType.Jumping)
		local samples={};local passed=true
		local ok,err=pcall(function()
			h.WalkSpeed=16;h.JumpPower=0;h.JumpHeight=0;h:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
			-- Paths flank the actual car bank and technical rack island.
			for _,route in {{"CarBank",-140,-92,-56,0},{"RackBank",140,-92,56,0}} do
				local from=map.Origin+Vector3.new(route[2],3,route[3]);local to=map.Origin+Vector3.new(route[4],3,route[5])
				actor:PivotTo(CFrame.new(from));root.AssemblyLinearVelocity=Vector3.zero
				local success,points=path("ActorRoute:"..route[1],from,to)
				local timedOut=false;local walkingStart=os.clock()
				if success then
					for _,point in points do
						h:MoveTo(point.Position)
						local deadline=math.min(walkingStart+35,os.clock()+5)
						repeat task.wait(.05) until not actor.Parent or h.Health<=0
							or Vector3.new(root.Position.X-point.Position.X,0,root.Position.Z-point.Position.Z).Magnitude<3 or os.clock()>=deadline
						if not actor.Parent or h.Health<=0 or os.clock()>=deadline then timedOut=true;break end
					end
				end
				local flat=Vector3.new(root.Position.X-to.X,0,root.Position.Z-to.Z).Magnitude
				local walked=success and not timedOut and flat<5
				passed=passed and walked
				table.insert(samples,{Name=route[1],Passed=walked,Seconds=os.clock()-walkingStart,DistanceRemaining=flat})
			end
		end)
		if actor.Parent then actor:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero
			h.WalkSpeed=speed;h.JumpPower=jumpPower;h.JumpHeight=jumpHeight;h:SetStateEnabled(Enum.HumanoidStateType.Jumping,canJump) end
		report.ActorWalk={Status=ok and passed and "PASSED" or "FAILED",Samples=samples,Error=not ok and tostring(err) or nil}
		if not ok or not passed then report.Passed=false end
	end
	report.Seconds=os.clock()-started
	report.CollisionLimitation="Hull flags and route clearance tested; actual player walking into each prop, weapon-ray behavior and slide need separate native Play checks"
	return report
end
