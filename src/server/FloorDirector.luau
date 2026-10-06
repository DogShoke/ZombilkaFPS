local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Shared.Config)
local Audio=require(ReplicatedStorage.Shared.Audio)
local Clock=require(script.Parent.RunClock)
local Zombies=require(script.Parent.ZombieService)
local Sources=require(script.Parent.SpawnSources)
local Horde=require(script.Parent.HordeDirector)
local Elevator=require(script.Parent.ElevatorService)
local Map=require(script.Parent.OfficeMap)
local Progress=require(script.Parent.EncounterProgress)
local Director={}
function Director.Start(map)
 local state=ReplicatedStorage:FindFirstChild("RunState")or Instance.new("Folder");state.Name="RunState";state.Parent=ReplicatedStorage
 local owner,current=nil,map.Current
 local number,phase,generation,deadline=1,"WaitingForPlayer",0,0
 local progress,travelRoot,travelStage
 local nextSpawn,spawnBusy,rebuilding=0,false,false
 local subscriptions,bursts={},{}
 local lastBurst=-math.huge
 local connectFloor
 local function goalReady()
  return progress and progress.Complete and (progress.Mode~="SpawnerHunt"or Clock.Now()-lastBurst>=Config.Run.Encounters.SourceShieldSeconds)
 end
 local function publish()
  local target=Horde.Target(number,progress and progress.Elapsed or 0);local d=Zombies.Diagnostics()
  for k,v in {State=phase,Floor=number,LayoutIndex=current.Slot,Theme=current.Layout.Label,Macro=current.Layout.Macro,MacroLabel=current.Layout.MacroLabel,GenerationVersion=current.Layout.GenerationVersion,Seed=current.Layout.Seed,RunSeed=map.Seed,Levels=current.Layout.Upper and 2 or 1,Alive=Zombies.Count(),Pending=Zombies.Pending(),Defeated=progress and progress.Defeated or 0,Spawned=progress and progress.Issued or 0,EncounterMode=current.Layout.Encounter.Mode,ObjectiveElapsed=progress and progress.Elapsed or 0,ObjectiveDuration=current.Layout.Encounter.Duration,KillQuota=current.Layout.Encounter.Quota,DesiredAlive=target.DesiredAlive,AliveCap=target.AliveCap,SpawnRate=target.SpawnRate,Pressure=target.Pressure,Section=progress and progress.Section or 1,Sections=#current.Layout.Sections,SectionKills=progress and progress.SectionKills or 0,SectionQuota=progress and current.Layout.Sections[progress.Section]and current.Layout.Sections[progress.Section].Quota or 0,SourcesTotal=#current.Layout.Sources,SourcesDestroyed=progress and progress.DestroyedSources or 0,SpawnFailures=d.Failures,CombatBlocked=d.Blocked,Paused=Clock.Paused}do state:SetAttribute(k,v)end
  state:SetAttribute("FloorComplete",goalReady()==true)
  state:SetAttribute("ElevatorLockReason",goalReady()and ""or "ВЫПОЛНИТЕ БОЕВУЮ ЦЕЛЬ")
 end
 local function setPhase(value,delay)phase=value;deadline=Clock.Now()+(delay or 0);publish()end
 local function clearNext()if map.Next then map.Next.Model:Destroy();map.Next=nil end end
 local function configureFloor()Zombies.Configure(current.Zones,current.Bounds,number,current.Layout.Nodes)end
 local function cancel()
  generation+=1;spawnBusy=false;progress=nil;bursts={};lastBurst=-math.huge
  Sources.Clear();Zombies.Clear();clearNext();Clock.Paused=false
  if travelRoot and travelRoot.Parent then travelRoot.Anchored=false end
  travelRoot=nil;travelStage=nil
  Map.SetSection(current,math.huge)
 end
 local function reset(character)
  local player=owner;if not player then return end
  cancel();player:SetAttribute("InElevatorTravel",false);Elevator.SetOpen(current,false);current.Spawn.Enabled=true;player.RespawnLocation=current.Spawn
  local token=generation;local root=character:WaitForChild("HumanoidRootPart",10)
  if not root or owner~=player or character~=player.Character or token~=generation then return end
  root.Anchored=false;character:PivotTo(current.Entry);configureFloor();setPhase("ChoosingWeapon")
 end
 connectFloor=function(f)f.Prompt.Triggered:Connect(function(player)Director.TryTravel(player,f)end)end
 Director.TryTravel=function(player,f)
  f=f or current
  if player~=owner or f~=current or phase~="ElevatorAvailable"or Clock.Paused or not goalReady()or not map.Next then return false end
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not h or h.Health<=0 or not Elevator.Inside(f,root.Position)then return false end
  player:SetAttribute("InElevatorTravel",true);root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=true;c:PivotTo(f.Cabin)
  travelRoot=root;travelStage="Closing";Elevator.SetOpen(f,false);setPhase("ElevatorTravel",Config.Run.DoorDuration);return true
 end
 connectFloor(current)
 local function join(player)
  if owner or rebuilding then return end
  owner=player;state:SetAttribute("OwnerUserId",player.UserId)
  table.insert(subscriptions,player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
   if owner==player and phase=="ChoosingWeapon"and Config.Weapons[player:GetAttribute("SelectedWeapon")]then setPhase("FloorIntro",Config.Run.IntroDuration)end
  end))
  table.insert(subscriptions,player.CharacterAdded:Connect(reset))
  if player.Character then task.spawn(reset,player.Character)end
 end
 Players.PlayerAdded:Connect(join)
 Players.PlayerRemoving:Connect(function(player)
  if player~=owner then return end
  cancel();for _,c in subscriptions do c:Disconnect()end;subscriptions={};owner=nil;number=1;rebuilding=true
  current.Model:Destroy();setPhase("WaitingForPlayer");local token=generation
  task.spawn(function()
   local ok,f=pcall(Map.CreateFloor,map,1,1)
   if token~=generation then if ok then f.Model:Destroy()end;return end
   if not ok then warn(f);rebuilding=false;setPhase("GenerationFailed");return end
   current=f;map.Current=f;connectFloor(f);state:SetAttribute("OwnerUserId",nil);rebuilding=false;publish()
   for _,p in Players:GetPlayers()do join(p)end
  end)
 end)
 for _,p in Players:GetPlayers()do join(p)end
 local function begin()
  progress=Progress.New(current.Layout.Encounter);bursts={};lastBurst=-math.huge
  Sources.Configure(current,progress,function(point,count)
   lastBurst=Clock.Now();for _=1,count do table.insert(bursts,point)end
  end)
  Map.SetSection(current,1);Zombies.BeginEncounter(progress);nextSpawn=Clock.Now();setPhase("EncounterActive")
 end
 local function spawnZones()
  if progress.Mode=="SpawnerHunt"then return Sources.Zones()end
  if progress.Mode~="WideGauntlet"then return current.Zones end
  local section=current.Layout.Sections[progress.Section];local zones={}
  for _,x in {-current.Layout.HalfWidth+10,current.Layout.HalfWidth-10}do table.insert(zones,{Id="Section"..progress.Section,Position=current.Origin+Vector3.new(x,0,section.Z),Radius=5,AttackDirection=x<0 and "West"or "East",EntryKind="Ground",Weight=1})end
  return zones
 end
 local function prepare()
  Zombies.StopSpawning();Sources.Stop();bursts={}
  setPhase("PreparingFloor");local token,source=generation,current
  task.spawn(function()
   local ok,f=pcall(Map.CreateFloor,map,number+1,source.Slot%2+1)
   if token~=generation or source~=current then if ok then f.Model:Destroy()end;return end
   if not ok then warn(f);setPhase("GenerationFailed");return end
   map.Next=f;connectFloor(f);Elevator.SetOpen(source,true);Audio.Play("ElevatorArrival",source.Indicator);setPhase("ElevatorAvailable");source.Prompt.Enabled=true
  end)
 end
 local accumulator=0
 RunService.Heartbeat:Connect(function(dt)
  Clock.Step(dt);accumulator+=dt;if accumulator<Config.Run.Tick then return end
  local step=accumulator;accumulator=0
  if not owner then return end
  local c=owner.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not root then if phase~="WaitingForPlayer"then cancel();setPhase("WaitingForPlayer")end;return end
  if Clock.Paused then return end
  local now,f=Clock.Now(),current
  if phase=="FloorIntro"and now>=deadline then begin()
  elseif phase=="EncounterActive"then
   local d=Zombies.Diagnostics()
   local healthy=not d.Since or now-d.Since<Config.Run.Encounters.SpawnFailureGrace
   local _,advanced=Progress.Step(progress,step,healthy,current.Layout.Sections,#current.Layout.Sources)
   if advanced then Map.SetSection(current,progress.Section)end
   Zombies.SetZones(spawnZones())
   local target=Horde.Target(number,progress.Elapsed)
   local count=Zombies.Count()+Zombies.Pending()
   if now>=nextSpawn and not spawnBusy and count<target.AliveCap and (#bursts>0 or not progress.Complete and count<target.DesiredAlive)then
    local token=generation;local origin=bursts[1];spawnBusy=true;nextSpawn=now+1/(origin and math.max(target.SpawnRate,Config.Run.Encounters.SourceBurstSpawnRate)or target.SpawnRate)
    task.spawn(function()
     local ok,scheduled=pcall(Zombies.Spawn,origin)
     if token~=generation then return end
     spawnBusy=false
     if not ok then warn(scheduled)
     elseif scheduled and origin then table.remove(bursts,1)end
    end)
   end
   if goalReady()then prepare()end
  elseif phase=="ElevatorTravel"and now>=deadline then
   if travelStage=="Closing"then travelStage="Moving";Audio.Play("ElevatorTravel",f.Indicator);deadline=now+Config.Run.TravelDuration
   elseif travelStage=="Moving"then
    Sources.Clear();Zombies.Clear();current=map.Next;map.Current=current;map.Next=nil;number+=1;generation+=1
    current.Spawn.Enabled=true;owner.RespawnLocation=current.Spawn;Elevator.SetLabel(current,number);c:PivotTo(current.Cabin);root.AssemblyLinearVelocity=Vector3.zero;f.Model:Destroy()
    progress=nil;spawnBusy=false;bursts={};configureFloor();Elevator.SetOpen(current,true);setPhase("NextFloor",Config.Run.DoorDuration)
   end
  elseif phase=="NextFloor"and now>=deadline then
   if travelRoot then travelRoot.Anchored=false;travelRoot=nil;owner:SetAttribute("InElevatorTravel",false)end
   if root.Position.Z-current.Origin.Z<current.ExitZ then Elevator.SetOpen(current,false);setPhase("FloorIntro",Config.Run.IntroDuration)end
  end
  publish()
 end)
 publish()
end
return Director
