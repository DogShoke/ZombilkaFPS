-- QA ONLY: native temporary Server Script in Play; Stop afterwards even on error.
-- Run Chase before Perch; uses QA_ChaseWorld and never writes persistent data.
local H=game:GetService('HttpService')
local ok,report=xpcall(function()
 local player=game.Players:GetPlayers()[1]
 while not player.Character or not player.Character:FindFirstChild('HumanoidRootPart')do task.wait(.1)end
 local c=player.Character;local root=c.HumanoidRootPart;local h=c.Humanoid
 local original=c:GetPivot();local oldAnchor=root.Anchored
 local folder=Instance.new('Folder');folder.Name='QA_ChaseWorld';folder.Parent=workspace
 local map=require(game.ServerScriptService.Server.CorporateMap).Build({Parent=folder,Origin=Vector3.new(450,400,0)})
 local z=require(game.ServerScriptService.Server.ZombieService)
 local report={Cases={},Passed=true,NormalTiming=true,Scope='Real emerged native ZombieService chase and attack; test player anchored for reproducibility'}
 for _,zone in map.Layout.ZoneRegions do
  z.Clear();c:PivotTo(CFrame.new(map.Origin+Vector3.new(zone.X,3,0)));root.Anchored=true;h.Health=h.MaxHealth
  z.Configure(map.Zones,map.Bounds,1,map.NavGraph.Nodes,map.Model)
  local p={Alive=0,Issued=0,Defeated=0,SectionKills=0,Requeued=0}
  z.BeginEncounter(p)
  local start=os.clock();local scheduled=z.Spawn()
  local best=math.huge;local firstPosition;local firstDistance
  repeat task.wait(.15)
   for _,m in workspace:GetChildren()do if m:GetAttribute('IsZombie') and not m:GetAttribute('Dead')then
    local r=m:FindFirstChild('HumanoidRootPart');if r then
     local distance=(r.Position-root.Position).Magnitude
     if m:GetAttribute('State')~='Spawn' then firstPosition=firstPosition or tostring(r.Position);firstDistance=firstDistance or distance end
     best=math.min(best,distance)
    end
   end end
  until h.Health<h.MaxHealth or os.clock()-start>30
  local success=scheduled and h.Health<h.MaxHealth
  table.insert(report.Cases,{Zone=zone.Id,Passed=success,Issued=p.Issued,BestDistance=best,InitialEmergedDistance=firstDistance,InitialPosition=firstPosition,HP=h.Health,Seconds=os.clock()-start,Diagnostics=z.Diagnostics()})
  report.Passed=report.Passed and success
 end
 z.Clear();root.Anchored=oldAnchor;c:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero;h.Health=h.MaxHealth
 return report
end,debug.traceback)
script:SetAttribute('Success',ok and report.Passed==true)
script:SetAttribute('Report',H:JSONEncode(ok and report or {Error=tostring(report)}))
script:SetAttribute('Complete',true)
