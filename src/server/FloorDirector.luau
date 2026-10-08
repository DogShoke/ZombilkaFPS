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
local RunSession=require(script.Parent.RunSession)
local Weapons=require(script.Parent.WeaponService)
local Effects=require(script.Parent.BoonEffects)
local RewardService=require(script.Parent.RewardService)
local ShopService=require(script.Parent.ShopService)
local ShopWorld=require(script.Parent.ShopWorld)
local Economy=require(ReplicatedStorage.Shared.ShopCatalog).Economy
local Director={}
function Director.Start(map)
 local state=ReplicatedStorage:FindFirstChild("RunState")or Instance.new("Folder");state.Name="RunState";state.Parent=ReplicatedStorage
 local owner,current=nil,map.Current
 local number,phase,generation,deadline=1,"WaitingForPlayer",0,0
 local progress,travelRoot,travelStage
 local nextSpawn,spawnBusy,rebuilding=0,false,false
 local subscriptions,bursts={},{}
 local lastBurst=-math.huge
 local session=RunSession.new()
 local connectFloor,reset,endRun,rebuildFirst
 local resetReady=true
 local boundCharacter,deathConnection
 local runRemotes=Instance.new("Folder");runRemotes.Name="RunRemotes";runRemotes.Parent=ReplicatedStorage
 local startRemote=Instance.new("RemoteEvent");startRemote.Name="StartRun";startRemote.Parent=runRemotes
 local results=Instance.new("Folder");results.Name="RunResults";results.Parent=state
 local rewards=RewardService.new(session,state)
 local shop=ShopService.new(session,state,rewards)
 local claimRemote=Instance.new("RemoteEvent");claimRemote.Name="ClaimBoon";claimRemote.Parent=runRemotes
 local rerollRemote=Instance.new("RemoteEvent");rerollRemote.Name="RerollBoon";rerollRemote.Parent=runRemotes
 local buyRemote=Instance.new("RemoteEvent");buyRemote.Name="BuyShopItem";buyRemote.Parent=runRemotes
 local closeShopRemote=Instance.new("RemoteEvent");closeShopRemote.Name="CloseShop";closeShopRemote.Parent=runRemotes
 local function goalReady()
  return progress and progress.Complete and (progress.Mode~="SpawnerHunt"or Clock.Now()-lastBurst>=Config.Run.Encounters.SourceShieldSeconds)
 end
 local function publish()
  local target=Horde.Target(number,progress and progress.Elapsed or 0);local d=Zombies.Diagnostics()
  for k,v in {State=phase,Floor=number,LayoutIndex=current.Slot,Theme=current.Layout.Label,Macro=current.Layout.Macro,MacroLabel=current.Layout.MacroLabel,GenerationVersion=current.Layout.GenerationVersion,Seed=current.Layout.Seed,RunSeed=map.Seed,Levels=current.Layout.Upper and 2 or 1,Alive=Zombies.Count(),Pending=Zombies.Pending(),Defeated=progress and progress.Defeated or 0,Spawned=progress and progress.Issued or 0,EncounterMode=current.Layout.Encounter.Mode,ObjectiveElapsed=progress and progress.Elapsed or 0,ObjectiveDuration=current.Layout.Encounter.Duration,KillQuota=current.Layout.Encounter.Quota,DesiredAlive=target.DesiredAlive,AliveCap=target.AliveCap,SpawnRate=target.SpawnRate,Pressure=target.Pressure,Section=progress and progress.Section or 1,Sections=#current.Layout.Sections,SectionKills=progress and progress.SectionKills or 0,SectionQuota=progress and current.Layout.Sections[progress.Section]and current.Layout.Sections[progress.Section].Quota or 0,SourcesTotal=#current.Layout.Sources,SourcesDestroyed=progress and progress.DestroyedSources or 0,SpawnFailures=d.Failures,CombatBlocked=d.Blocked,Paused=Clock.Paused}do state:SetAttribute(k,v)end
  state:SetAttribute("FloorComplete",goalReady()==true)
  state:SetAttribute("ElevatorLockReason",goalReady()and ""or "ВЫПОЛНИТЕ БОЕВУЮ ЦЕЛЬ")
  state:SetAttribute("RunId",session.Id)
  state:SetAttribute("RunEpoch",session.Epoch)
  state:SetAttribute("RunActive",session.Active)
  state:SetAttribute("Credits",session.Credits or 0)
  state:SetAttribute("Rerolls",session.Rerolls or 0)
  state:SetAttribute("RunKills",session.Active and session.Kills or 0)
  local count=0;for _ in session.Boons or {}do count+=1 end
  state:SetAttribute("BoonCount",session.Active and count or 0)
  state:SetAttribute("ResearchStatus","Unavailable")
 end
 local function setPhase(value,delay)phase=value;deadline=Clock.Now()+(delay or 0);publish()end
 local function clearNext()if map.Next then map.Next.Model:Destroy();map.Next=nil end end
 local function configureFloor()Zombies.Configure(current.Zones,current.Bounds,number,current.Layout.Nodes)end
 local function cancel()
  generation+=1;spawnBusy=false;progress=nil;bursts={};lastBurst=-math.huge
  Sources.Clear();Zombies.Clear();clearNext();Clock.Paused=false
  rewards:Clear();shop:Clear();ShopWorld.Enable(current,false);Effects.Clear()
  if owner then owner:SetAttribute("InSafeInterlude",false)end
  if travelRoot and travelRoot.Parent then travelRoot.Anchored=false end
  travelRoot=nil;travelStage=nil
  Map.SetSection(current,math.huge)
 end
 reset=function(character)
  local player=owner;if not player then return end
  if boundCharacter and boundCharacter~=character and session.Active then endRun("Respawn") end
  boundCharacter=character
  if deathConnection then deathConnection:Disconnect() end
  local h=character:WaitForChild("Humanoid",10)
  if not h or player~=owner or character~=player.Character then return end
  deathConnection=h.Died:Connect(function()if owner==player and character==player.Character then endRun("Death")end end)
  while rebuilding and owner==player and character==player.Character do task.wait(.05)end
  local token=generation;local root=character:WaitForChild("HumanoidRootPart",10)
  if not root or owner~=player or character~=player.Character or token~=generation then return end
  player:SetAttribute("InElevatorTravel",false);Elevator.SetOpen(current,false);current.Spawn.Enabled=true;player.RespawnLocation=current.Spawn
  root.Anchored=false;character:PivotTo(current.Entry);configureFloor()
  setPhase(not resetReady and "RunRecoveryFailed"or session.Active and "ChoosingWeapon"or "RunEnded")
 end
 rebuildFirst=function(player)
  number=1;resetReady=false;rebuilding=true;Elevator.SetOpen(current,false);setPhase("ResettingRun")
  local token,old=generation,current
  local seed=Random.new():NextInteger(1,2000000000)
  task.spawn(function()
   local ok,f=pcall(Map.CreateFloor,{Run=map.Run,Seed=seed},1,old.Slot%2+1)
   if token~=generation or owner~=player then if ok then f.Model:Destroy()end;return end
   rebuilding=false
   if not ok then warn(f);setPhase("RunRecoveryFailed");return end
   current=f;map.Current=f;map.Seed=seed;connectFloor(f)
   resetReady=true
   f.Spawn.Enabled=true;player.RespawnLocation=f.Spawn
   local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
   if h and h.Health>0 then c:PivotTo(f.Entry)end
   old.Model:Destroy();configureFloor();setPhase("RunEnded")
  end)
 end
 endRun=function(reason)
  local snapshot=session:Finish(Clock.Now(),reason)
  if not snapshot then return false end
  local player=owner
  -- Commit the result before cleanup; a duplicate death cannot replace or pay it twice.
  for k,v in snapshot do if type(v)~="table"then results:SetAttribute(k,v)end end
  results:SetAttribute("BoonsJson",game:GetService("HttpService"):JSONEncode(snapshot.Boons))
  results:SetAttribute("PatronsJson",game:GetService("HttpService"):JSONEncode(snapshot.Patrons))
  cancel();Weapons.ResetPlayer(player);player:SetAttribute("InElevatorTravel",false)
  rebuildFirst(player);return true
 end
 Director.EndRun=function(player,reason)if player~=owner then return false end;return endRun(reason or "Death")end
 Director.StartRun=function(player,epoch)
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
  if player~=owner or rebuilding or epoch~=session.Epoch or not h or h.Health<=0 then return false end
  if phase=="RunRecoveryFailed"then rebuildFirst(player);return true end
  if phase~="RunEnded"or not resetReady then return false end
  Weapons.ResetPlayer(player);session:Begin(Clock.Now());Effects.Bind(session,player);setPhase("ChoosingWeapon");return true
 end
 startRemote.OnServerEvent:Connect(function(player,epoch)Director.StartRun(player,epoch)end)
 connectFloor=function(f)
  for _,bay in f.Bays do bay.Prompt.Triggered:Connect(function(player)Director.TryTravel(player,f,bay.Route and bay.Route.Id)end)end
 end
 Director.TryTravel=function(player,f,routeId)
  f=f or current
  if player~=owner or f~=current or phase~="ElevatorAvailable"or Clock.Paused or not goalReady()or not map.Next then return false end
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not h or h.Health<=0 then return false end
  local chosen
  for _,bay in f.Bays do
   if bay.Route and bay.Route.Id==routeId and Elevator.Inside(bay,root.Position)and (root.Position-bay.Prompt.Parent.Position).Magnitude<=bay.Prompt.MaxActivationDistance then chosen=bay;break end
  end
  if not chosen or not rewards:Select(routeId,session.Epoch,number)then return false end
  Weapons.CancelActions(player);player:SetAttribute("InElevatorTravel",true);root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=true;c:PivotTo(f.Cabin)
  Effects.ClearFloor();travelRoot=root;travelStage="Closing";Elevator.SetOpen(f,false);Elevator.SetRewards(f,nil,routeId);setPhase("ElevatorTravel",Config.Run.DoorDuration);return true
 end
 local function canUseReward(player)
  if player~=owner or phase~="RewardInterlude"then return false end
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not root or not Elevator.Inside(current,root.Position)then return false end
  return true
 end
 Director.ClaimBoon=function(player,epoch,token,id,revision)
  if not canUseReward(player)or not rewards:Claim(player,epoch,token,id,revision)then return false end
  player:SetAttribute("InSafeInterlude",false);Elevator.SetOpen(current,true);ShopWorld.Enable(current,true);setPhase("NextFloor",Config.Run.DoorDuration);return true
 end
 Director.RerollBoon=function(player,epoch,token,revision)
  if not canUseReward(player)or not rewards:Reroll(player,epoch,token,revision)then return false end
  publish();return true
 end
 claimRemote.OnServerEvent:Connect(Director.ClaimBoon)
 rerollRemote.OnServerEvent:Connect(Director.RerollBoon)
 Director.OpenVending=function(player)
  if player~=owner or phase~="NextFloor"then return false end
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
  local prompt=current.VendingPrompt
  if not h or h.Health<=0 or not root or not prompt or not prompt.Enabled or not Elevator.Inside(current,root.Position)
   or (root.Position-prompt.Parent.Position).Magnitude>prompt.MaxActivationDistance then return false end
  if not shop:Open(player,"Vending",number,map.Seed)then return false end
  Weapons.CancelActions(player);root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=true;travelRoot=root
  player:SetAttribute("InSafeInterlude",true);ShopWorld.Enable(current,false);Elevator.SetOpen(current,false);setPhase("ShopInterlude");return true
 end
 local function canUseShop(player)
  if player~=owner or phase~="ShopInterlude"then return false end
  local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
  return h and h.Health>0 and root and Elevator.Inside(current,root.Position)
 end
 Director.BuyShopItem=function(player,epoch,token,id,revision)
  if not canUseShop(player)or not shop:Buy(player,epoch,token,id,revision)then return false end
  publish();return true
 end
 Director.CloseShop=function(player,epoch,token,revision)
  if not canUseShop(player)or not shop:Current(player,epoch,token,revision)then return false end
  shop:Close();player:SetAttribute("InSafeInterlude",false);ShopWorld.Enable(current,true);Elevator.SetOpen(current,true)
  setPhase("NextFloor",Config.Run.DoorDuration);return true
 end
 buyRemote.OnServerEvent:Connect(Director.BuyShopItem)
 closeShopRemote.OnServerEvent:Connect(Director.CloseShop)
 connectFloor(current)
 local function join(player)
  if owner or rebuilding then return end
  owner=player;state:SetAttribute("OwnerUserId",player.UserId)
  session:Begin(Clock.Now())
  Effects.Bind(session,player)
  table.insert(subscriptions,player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function()
   if owner==player and phase=="ChoosingWeapon"and Config.Weapons[player:GetAttribute("SelectedWeapon")]then setPhase("FloorIntro",Config.Run.IntroDuration)end
  end))
  table.insert(subscriptions,player.CharacterAdded:Connect(reset))
  if player.Character then task.spawn(reset,player.Character)end
 end
 Players.PlayerAdded:Connect(join)
 Players.PlayerRemoving:Connect(function(player)
  if player~=owner then return end
  session:Finish(Clock.Now(),"Disconnect");cancel();if deathConnection then deathConnection:Disconnect();deathConnection=nil end
  boundCharacter=nil;for _,c in subscriptions do c:Disconnect()end;subscriptions={};owner=nil;number=1;rebuilding=true
  local old=current;setPhase("WaitingForPlayer");local token=generation
  task.spawn(function()
   local ok,f=pcall(Map.CreateFloor,map,1,1)
   if token~=generation then if ok then f.Model:Destroy()end;return end
   if not ok then warn(f);rebuilding=false;setPhase("GenerationFailed");return end
   old.Model:Destroy();current=f;map.Current=f;connectFloor(f);resetReady=true;state:SetAttribute("OwnerUserId",nil);rebuilding=false;publish()
   for _,p in Players:GetPlayers()do join(p)end
  end)
 end)
 for _,p in Players:GetPlayers()do join(p)end
 local function begin()
  progress=Progress.New(current.Layout.Encounter);bursts={};lastBurst=-math.huge
  local epoch=session.Epoch
  session:SetFloor(epoch,number,current.Layout.Encounter.Quota>0 and current.Layout.Encounter.Quota or Economy.NoQuotaKillBudget)
  Effects.OnFloorStart()
  progress.OnKill=function()session:RecordKill(epoch)end
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
  session:CompleteFloor(session.Epoch,number)
  Zombies.StopSpawning();Sources.Stop();bursts={}
  setPhase("PreparingFloor");local token,source,destination=generation,current,number+1
  local spec={Run=map.Run,Seed=map.Seed}
  task.spawn(function()
   local ok,f=pcall(Map.CreateFloor,spec,destination,source.Slot%2+1)
   if token~=generation or source~=current then if ok then f.Model:Destroy()end;return end
   if not ok then warn(f);setPhase("GenerationFailed");return end
   map.Next=f;connectFloor(f);Elevator.SetOpen(source,true);Elevator.SetRewards(source,rewards:RoutesFor(map.Seed,number));Audio.Play("ElevatorArrival",source.Indicator);setPhase("ElevatorAvailable")
  end)
 end
 local accumulator=0
 RunService.Heartbeat:Connect(function(dt)
  Clock.Step(dt);accumulator+=dt;if accumulator<Config.Run.Tick then return end
  local step=accumulator;accumulator=0
  if not owner then return end
  local c=owner.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not root then if h and h.Health<=0 then endRun("Death")end;return end
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
    session.HighestFloor=math.max(session.HighestFloor,number)
    current.Spawn.Enabled=true;owner.RespawnLocation=current.Spawn;Elevator.SetLabel(current,number);c:PivotTo(current.Cabin);root.AssemblyLinearVelocity=Vector3.zero;f.Model:Destroy()
    progress=nil;spawnBusy=false;bursts={};configureFloor();Elevator.SetOpen(current,false)
    owner:SetAttribute("InSafeInterlude",true);owner:SetAttribute("InElevatorTravel",false)
    local merchant=rewards.Selected.Type=="MerchantShop"
    ShopWorld.Attach(current,function(player)Director.OpenVending(player)end,merchant)
    if merchant then assert(shop:Open(owner,"MerchantShop",number,map.Seed),"No valid merchant stock");setPhase("ShopInterlude")
    else assert(rewards:Open(owner),"No valid patron reward");setPhase("RewardInterlude")end
   end
  elseif phase=="NextFloor"and now>=deadline then
   if travelRoot then travelRoot.Anchored=false;travelRoot=nil;owner:SetAttribute("InElevatorTravel",false)end
   if root.Position.Z-current.Origin.Z<current.ExitZ then ShopWorld.Enable(current,false);shop:Close();Elevator.SetOpen(current,false);setPhase("FloorIntro",Config.Run.IntroDuration)end
  end
  publish()
 end)
 publish()
end
return Director
