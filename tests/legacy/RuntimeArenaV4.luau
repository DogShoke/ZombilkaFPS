-- Temporary native Script in Play. Stop removes all changes; never shipped by Rojo.
local C=require(game.ReplicatedStorage.Shared.Config)
local L=require(game.ServerScriptService.Server.FloorLayout)
local D=require(game.ServerScriptService.Server.FloorDirector)
local Sources=require(game.ServerScriptService.Server.SpawnSources)
local p=game.Players:GetPlayers()[1]
local state=game.ReplicatedStorage.RunState
local original=L.Generate
local changes={}
local function tune(t,k,v)table.insert(changes,{t,k,t[k]});t[k]=v end
tune(C.Run,'IntroDuration',.1);tune(C.Run,'DoorDuration',.05);tune(C.Run,'TravelDuration',.1)
tune(C.Run.Horde,'BaseSpawnRate',3);tune(C.Run.Horde,'MaxSpawnRate',3)
tune(C.Run.Encounters,'KillQuota',3);tune(C.Run.Encounters,'QuotaPerFloor',0)
tune(C.Run.Encounters,'SurvivalSeconds',.4);tune(C.Run.Encounters,'SurvivalKills',3)
L.Generate=function(seed,n,attempt,override)
 if n==2 then override={Macro='SpawnerHunt',Mode='SpawnerHunt'}elseif n==3 then override={Macro='WideGauntlet',Mode='WideGauntlet'}elseif n==4 then override={Macro='OpenArena',Mode='Survival'}end
 local plan=original(seed,n,attempt,override)
 if n==2 then while #plan.Sources>2 do table.remove(plan.Sources)end end
 return plan
end
local report={Transitions={},AliveCompletion=false,RemainingDanger=false,Gauntlet=false,Survival=false,Cap=0,BurstEnemies=0}
local spawned=workspace.ChildAdded:Connect(function(m)
 task.defer(function()if m:GetAttribute('IsZombie')and m:GetAttribute('SpawnZone')=='Burst'then report.BurstEnemies+=1 end end)
end)
local ok,err=pcall(function()
 p.Character.Humanoid.MaxHealth=100000;p.Character.Humanoid.Health=100000
 local limit=os.clock()+240;local survivalObserved=false
 while state:GetAttribute('Floor')<6 do
  assert(os.clock()<limit,'Runtime sequence timeout')
  local phase,mode=state:GetAttribute('State'),state:GetAttribute('EncounterMode')
  local alive=state:GetAttribute('Alive')or 0;report.Cap=math.max(report.Cap,alive+(state:GetAttribute('Pending')or 0));assert(report.Cap<=C.Run.Horde.AliveCap)
  if phase=='EncounterActive'then
   assert(not D.TryTravel(p))
   if mode=='SpawnerHunt'then
    local floor=workspace.OfficeRun:FindFirstChild(string.format('Floor%03d',state:GetAttribute('Floor')))
    for _,m in floor:GetChildren()do if m:GetAttribute('IsSpawnSource')and not m:GetAttribute('Destroyed')then
     local at=m.PrimaryPart.Position;p.Character:PivotTo(CFrame.new(at+Vector3.new(0,-1,12)));Sources.Damage(m,p,10000)
    end end
   elseif mode=='WideGauntlet'then
    report.Gauntlet=true
    local floor=workspace.OfficeRun:FindFirstChild(string.format('Floor%03d',state:GetAttribute('Floor')))
    local half=floor.Geometry.Floor.Size.Z/2
    local z=({half-64,0,-half+64})[state:GetAttribute('Section')]
    p.Character:PivotTo(CFrame.new(0,floor.Geometry.Floor.Position.Y+3,z))
   elseif mode=='Survival'and not survivalObserved and state:GetAttribute('ObjectiveElapsed')>=state:GetAttribute('ObjectiveDuration')and state:GetAttribute('Defeated')<state:GetAttribute('KillQuota')then
    assert(not state:GetAttribute('FloorComplete'));report.Survival=true;survivalObserved=true
   end
   local kill=mode~='Survival'or survivalObserved
   local preserve=mode=='SpawnerHunt'and 4 or 1
   if kill then for _,m in workspace:GetChildren()do if m:GetAttribute('IsZombie')and not m:GetAttribute('Dead')and alive>preserve then m.Humanoid:TakeDamage(10000);alive-=1 end end end
  elseif phase=='ElevatorAvailable'then
   assert(state:GetAttribute('FloorComplete'));assert(not D.TryTravel(p),'Outside cabin')
   if alive>0 then report.AliveCompletion=true end
   task.wait(1.5) -- A retained enemy may still be completing its ground emergence.
   local hp=p.Character.Humanoid.Health
   local damaged=false;local observation=p.Character.Humanoid.HealthChanged:Connect(function(value)if value<hp then damaged=true end;hp=value end)
   for _,m in workspace:GetChildren()do if m:GetAttribute('IsZombie')and not m:GetAttribute('Dead')and m:GetAttribute('State')~='Spawn'then
    local at=m.HumanoidRootPart.Position;local y=C.Run.BaseHeight+(state:GetAttribute('LayoutIndex')-1)*C.Run.FloorHeight
    p.Character:PivotTo(CFrame.new(at.X+2.8,y+3,at.Z));task.wait(4);break
   end end
   observation:Disconnect();report.RemainingDanger=report.RemainingDanger or damaged
   local y=C.Run.BaseHeight+(state:GetAttribute('LayoutIndex')-1)*C.Run.FloorHeight
   local current=workspace.OfficeRun:FindFirstChild(string.format('Floor%03d',state:GetAttribute('Floor')))
   p.Character:PivotTo(CFrame.new(0,y+3,current.Geometry.Floor.Size.Z/2-11));assert(D.TryTravel(p))
   table.insert(report.Transitions,{Floor=state:GetAttribute('Floor'),Mode=mode,Alive=state:GetAttribute('Alive')})
  elseif phase=='NextFloor'then
   local y=C.Run.BaseHeight+(state:GetAttribute('LayoutIndex')-1)*C.Run.FloorHeight
   local current=workspace.OfficeRun:FindFirstChild(string.format('Floor%03d',state:GetAttribute('Floor')))
   p.Character:PivotTo(CFrame.new(0,y+3,current.Geometry.Floor.Size.Z/2-40))
  end
  task.wait(.1)
 end
 assert(#report.Transitions==5 and report.AliveCompletion and report.RemainingDanger and report.Gauntlet and report.Survival and report.BurstEnemies>0)
 local floor,seed=state:GetAttribute('Floor'),state:GetAttribute('Seed');p.Character.Humanoid.Health=0
 task.wait(.5);p:LoadCharacter();local untilTime=os.clock()+20
 repeat task.wait(.1)until state:GetAttribute('State')=='ChoosingWeapon'or os.clock()>untilTime
 assert(state:GetAttribute('State')=='ChoosingWeapon'and state:GetAttribute('Floor')==floor and state:GetAttribute('Seed')==seed)
 assert(state:GetAttribute('Alive')==0 and state:GetAttribute('Pending')==0);report.DeathReset=true
end)
spawned:Disconnect();L.Generate=original;for _,x in changes do x[1][x[2]]=x[3]end
script:SetAttribute('Status',ok and 'Passed'or 'Failed');script:SetAttribute('Error',err or '');script:SetAttribute('Report',game:GetService('HttpService'):JSONEncode(report))
