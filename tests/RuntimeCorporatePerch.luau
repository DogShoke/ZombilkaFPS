-- QA ONLY: native temporary Server Script in Play; Stop afterwards even on error.
-- Run Chase before Perch; uses QA_ChaseWorld and never writes persistent data.
local H=game:GetService('HttpService')
local ok,report=xpcall(function()
 local player=game.Players:GetPlayers()[1];local c=player.Character;local root=c.HumanoidRootPart;local h=c.Humanoid
 local original=c:GetPivot();local oldAnchor=root.Anchored
 local world=workspace.QA_ChaseWorld.CorporateComplex
 local origin=Vector3.new(450,400,0);local layout=require(game.ReplicatedStorage.Shared.CorporateLayout)
 local zones={};for _,lane in layout.SpawnLanes do table.insert(zones,{Id=lane[1],Position=origin+Vector3.new(lane[2],0,lane[3]),Radius=6,Weight=1,EntryKind='Ground'})end
 local z=require(game.ServerScriptService.Server.ZombieService);local report={Cases={},Passed=true,Scope='Already-emerged native AI versus stationary player on top of cover, no weapon/damage tuning'}
 for _,case in {{'Car','ParkingNorth','ArenaCar'},{'Rack','ServiceNorth','ServerRackTwin'},{'Container','Loading','ArenaContainer'}}do
  z.Clear();local hull=world.Props[case[2]]:FindFirstChild(case[3]).CoverCollision
  local ground=Vector3.new(hull.Position.X,origin.Y+3,hull.Position.Z+25)
  c:PivotTo(CFrame.new(ground));root.Anchored=true;h.Health=h.MaxHealth
  z.Configure(zones,{Origin=origin,HalfWidth=157,HalfDepth=157},1,layout.NavGraph.Nodes,world)
  local p={Alive=0,Issued=0,Defeated=0,SectionKills=0,Requeued=0};z.BeginEncounter(p)
  local scheduled=z.Spawn();local deadline=os.clock()+10;local emerged=false
  repeat task.wait(.1);for _,m in workspace:GetChildren()do if m:GetAttribute('IsZombie') and m:GetAttribute('State')=='Chase' then emerged=true end end until emerged or os.clock()>deadline
  c:PivotTo(CFrame.new(hull.Position+Vector3.new(0,hull.Size.Y/2+3,0)));root.AssemblyLinearVelocity=Vector3.zero
  local start=os.clock();local best=math.huge;local peak=origin.Y
  repeat task.wait(.1);for _,m in workspace:GetChildren()do if m:GetAttribute('IsZombie') and not m:GetAttribute('Dead') then
   best=math.min(best,(m.HumanoidRootPart.Position-root.Position).Magnitude);peak=math.max(peak,m.HumanoidRootPart.Position.Y)
  end end until h.Health<h.MaxHealth or os.clock()-start>30
  local pass=scheduled and emerged and h.Health<h.MaxHealth;report.Passed=report.Passed and pass
  table.insert(report.Cases,{Name=case[1],Passed=pass,HP=h.Health,Seconds=os.clock()-start,BestDistance=best,NPCPeakY=peak,PlayerY=root.Position.Y,HullHeight=hull.Size.Y})
 end
 z.Clear();root.Anchored=oldAnchor;c:PivotTo(original);h.Health=h.MaxHealth;return report
end,debug.traceback)
script:SetAttribute('Success',ok and report.Passed==true);script:SetAttribute('Report',H:JSONEncode(ok and report or {Error=tostring(report)}));script:SetAttribute('Complete',true)
