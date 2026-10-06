local Office=require(game.ServerScriptService.Server.OfficeMap)
local Rig=require(game.ServerScriptService.Server.ZombieRig)
local Pathfinding=game:GetService("PathfindingService")
local player=game.Players:GetPlayers()[1];local character=player.Character
local root=character:WaitForChild("HumanoidRootPart");local human=character:WaitForChild("Humanoid")
local originalHealth,originalMax=human.Health,human.MaxHealth;human.MaxHealth=100000;human.Health=100000
local original=character:GetPivot();local holder=Instance.new("Folder");holder.Name="PhysicalClusterQA";holder.Parent=workspace
local report={};local rigs={}
local function walk(rig,start,destination,jump)
 rig.model:PivotTo(CFrame.new(start+Vector3.new(0,3,0)))
 local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=jump})
 path:ComputeAsync(rig.root.Position,destination+Vector3.new(0,3,0));assert(path.Status==Enum.PathStatus.Success,"No physical test path")
 local started=os.clock()
 for _,p in path:GetWaypoints()do
  if p.Action==Enum.PathWaypointAction.Jump then rig.humanoid.Jump=true end
  rig.humanoid:MoveTo(p.Position)
  local limit=os.clock()+5
  repeat task.wait(.05)until(Vector3.new(rig.root.Position.X-p.Position.X,0,rig.root.Position.Z-p.Position.Z).Magnitude<2.5 and math.abs(rig.root.Position.Y-p.Position.Y)<4)or os.clock()>limit
  assert(os.clock()<=limit,"NPC stopped at waypoint")
 end
 assert(Vector3.new(rig.root.Position.X-destination.X,0,rig.root.Position.Z-destination.Z).Magnitude<4,"NPC did not reach target")
 return {Seconds=os.clock()-started,RootY=rig.root.Position.Y,Waypoints=#path:GetWaypoints()}
end
local ok,err=pcall(function()
 local f=Office.CreateFloor({Run=holder,Seed=123456},8,6,{SkipValidation=true,Override={Theme="Parking",Macro="Parking",Mode="KillQuota"}})
 local car
 for _,m in f.Model.Props:GetDescendants()do if m:IsA("Model")and(m.Name=="SedanWhite"or m.Name=="HatchbackBlue")then car=m;break end end
 assert(car,"No car in parking composition")
 local hull=car.CoverCollision;local from=hull.CFrame:PointToWorldSpace(Vector3.new(-hull.Size.X/2-7,0,0))
 local to=hull.CFrame:PointToWorldSpace(Vector3.new(hull.Size.X/2+7,0,0))
 character:PivotTo(CFrame.new(from.X,f.Origin.Y+3,from.Z));root:SetNetworkOwnershipAuto();task.wait(.3)
 local atStart=-hull.CFrame:PointToObjectSpace(root.Position).X
 player:SetAttribute("PhysicalDrive",hull.CFrame.RightVector)
 task.wait(1.8);player:SetAttribute("PhysicalDrive",nil);task.wait(.1)
 local stopped=-hull.CFrame:PointToObjectSpace(root.Position).X
 assert(stopped>=hull.Size.X/2-.1,"Player passed through car")
 assert(atStart-stopped>2,"Player never approached car")
 report.PlayerCollision={Car=car.Name,StartDistance=atStart,StoppedDistance=stopped,Surface=hull.Size.X/2}
 local rig=Rig.Create(Vector3.new(from.X,f.Origin.Y,from.Z),1,{Health=100,Speed=11,Damage=12});table.insert(rigs,rig)
 local npcFrom=hull.CFrame:PointToWorldSpace(Vector3.new(0,0,hull.Size.Z/2+7))
 local npcTo=hull.CFrame:PointToWorldSpace(Vector3.new(0,0,-hull.Size.Z/2-7))
 report.NPCAroundCar=walk(rig,Vector3.new(npcFrom.X,f.Origin.Y,npcFrom.Z),Vector3.new(npcTo.X,f.Origin.Y,npcTo.Z),false)
 assert(report.NPCAroundCar.Waypoints>=3,"NPC path did not avoid the car")
 rig.model:Destroy();f.Model:Destroy()
 local raised=Office.CreateFloor({Run=holder,Seed=246813},8,6,{SkipValidation=true,Override={Theme="Office",Macro="SplitLevel",Mode="KillQuota"}})
 local x=raised.Layout.UpperSide*54;report.Ramps={}
 for _,side in {-1,1}do
  local r=Rig.Create(raised.Origin+Vector3.new(x,0,side*72),2,{Health=100,Speed=11,Damage=12});table.insert(rigs,r)
  local observation=walk(r,raised.Origin+Vector3.new(x,0,side*72),raised.Origin+Vector3.new(x,8,side*18),true)
  assert(observation.RootY>raised.Origin.Y+9,"NPC did not climb gallery");table.insert(report.Ramps,observation);r.model:Destroy()
 end
end)
for _,r in rigs do if r.model.Parent then r.model:Destroy()end end
holder:Destroy();player:SetAttribute("PhysicalDrive",nil);human.MaxHealth=originalMax;human.Health=math.min(originalHealth,originalMax);if character.Parent then character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero;root:SetNetworkOwnershipAuto()end
script:SetAttribute("Success",ok);script:SetAttribute("Error",err or "");script:SetAttribute("Report",game:GetService("HttpService"):JSONEncode(report));script:SetAttribute("Complete",true)
