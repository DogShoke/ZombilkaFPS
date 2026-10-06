local Office=require(game.ServerScriptService.Server.OfficeMap)
local Rig=require(game.ServerScriptService.Server.ZombieRig)
local PF=game:GetService("PathfindingService")
local p=game.Players:GetPlayers()[1];local ch=p.Character;local h=ch.Humanoid;local root=ch.HumanoidRootPart
local saved=ch:GetPivot();local report={Ramps={}};local holder=Instance.new("Folder");holder.Name="TilePhysicalQA";holder.Parent=workspace
local rigs={}
local function walk(rig,start,to)
 rig.model:PivotTo(CFrame.new(start+Vector3.new(0,3,0)))
 local path=PF:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false})
 path:ComputeAsync(rig.root.Position,to+Vector3.new(0,3,0));assert(path.Status==Enum.PathStatus.Success,"No no-jump path")
 local started=os.clock()
 for _,w in path:GetWaypoints()do
  rig.humanoid:MoveTo(w.Position);local deadline=os.clock()+5
  repeat task.wait(.05)until(Vector3.new(rig.root.Position.X-w.Position.X,0,rig.root.Position.Z-w.Position.Z).Magnitude<2.2 and math.abs(rig.root.Position.Y-w.Position.Y)<4)or os.clock()>deadline
  assert(os.clock()<=deadline,"NPC waypoint timeout")
 end
 assert((rig.root.Position-to-Vector3.new(0,3,0)).Magnitude<5,"NPC did not arrive")
 return {Seconds=os.clock()-started,Waypoints=#path:GetWaypoints(),RootY=rig.root.Position.Y}
end
local function drive(to)
 p:SetAttribute("TileWalkTarget",to);local deadline=os.clock()+8
 repeat task.wait(.05)until(Vector3.new(root.Position.X-to.X,0,root.Position.Z-to.Z).Magnitude<2)or os.clock()>deadline
 p:SetAttribute("TileWalkTarget",nil);assert(os.clock()<=deadline,"Player movement timeout")
end
local ok,err=pcall(function()
 local f=Office.CreateFloor({Run=holder,Seed=123456},1,6,{SkipValidation=true})
 local hull=f.Model.Props.Tile_3_3.ReceptionWide.CoverCollision
 local from=hull.Position-hull.CFrame.RightVector*(hull.Size.X/2+7)
 ch:PivotTo(CFrame.new(from.X,f.Origin.Y+3,from.Z));root:SetNetworkOwnershipAuto();task.wait(.3)
 local at=math.abs(hull.CFrame:PointToObjectSpace(root.Position).X)
 p:SetAttribute("TileDrive",hull.CFrame.RightVector);task.wait(1.8);p:SetAttribute("TileDrive",nil)
 local stopped=math.abs(hull.CFrame:PointToObjectSpace(root.Position).X)
 assert(stopped>=hull.Size.X/2-.1 and at-stopped>2,"Player collision failed")
 report.Collision={Start=at,Stopped=stopped,Surface=hull.Size.X/2,Prop="ReceptionWide"}
 ch:PivotTo(CFrame.new(f.Origin+Vector3.new(-18,3,18)));root:SetNetworkOwnershipAuto()
 for _,at in {Vector3.new(-18,0,-18),Vector3.new(18,0,-18),Vector3.new(18,0,18),Vector3.new(-18,0,18)}do drive(f.Origin+at)end
 report.PlayerRotation=true
 local r=Rig.Create(f.Origin+Vector3.new(-18,0,18),1,{Health=100,Speed=11,Damage=12});table.insert(rigs,r)
 report.AroundLandmark=walk(r,f.Origin+Vector3.new(0,0,18),f.Origin+Vector3.new(0,0,-18));r.model:Destroy()
 for _,side in {-1,1}do
  local npc=Rig.Create(f.Origin+Vector3.new(36,0,36+side*18),2,{Health=100,Speed=11,Damage=12});table.insert(rigs,npc)
  local observed=walk(npc,f.Origin+Vector3.new(36,0,36+side*18),f.Origin+Vector3.new(36,6,38))
  assert(observed.RootY>f.Origin.Y+7);table.insert(report.Ramps,observed);npc.model:Destroy()
 end
end)
p:SetAttribute("TileDrive",nil);p:SetAttribute("TileWalkTarget",nil);for _,r in rigs do if r.model.Parent then r.model:Destroy()end end
holder:Destroy();if ch.Parent then ch:PivotTo(saved);root.AssemblyLinearVelocity=Vector3.zero;root:SetNetworkOwnershipAuto()end
script:SetAttribute("Success",ok);script:SetAttribute("Error",err or "");script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
