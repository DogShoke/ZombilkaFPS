-- Install ONLY in temporary Studio Play QA. Never include this bridge in Rojo.
assert(game:GetService("RunService"):IsStudio(), "Studio QA only")
local R=game.ReplicatedStorage
local Server=game.ServerScriptService.Server
local D=require(Server.FloorDirector)
local W=require(Server.WeaponService)
local E=require(Server.BoonEffects)
local Z=require(Server.ZombieService)
local Session=require(Server.RunSession)
local C=require(R.Shared.Config)
local Catalog=require(R.Shared.BoonCatalog)
local testRarity=script:GetAttribute("TestRarity")or "Common"
local testLevel=script:GetAttribute("TestLevel")or 1
assert(table.find({"Common","Rare","Epic","Heroic"},testRarity),"Invalid QA TestRarity")
assert(type(testLevel)=="number"and testLevel%1==0 and testLevel>=1 and testLevel<=3,"Invalid QA TestLevel")
script:SetAttribute("TestRarity",testRarity);script:SetAttribute("TestLevel",testLevel)
local bridge=Instance.new("RemoteFunction")
bridge.Name="BoonEffectsQA"
bridge:SetAttribute("TestRarity",testRarity);bridge:SetAttribute("TestLevel",testLevel);bridge:SetAttribute("Ready",true)
bridge.Parent=R
local saved={Intro=C.Run.IntroDuration,Rate=C.Run.Horde.BaseSpawnRate,MaxRate=C.Run.Horde.MaxSpawnRate,
	Recover=C.Run.Encounters.StuckRecoverAfter,Approach=C.Run.Encounters.ApproachTimeout}
C.Run.IntroDuration=.1;C.Run.Horde.BaseSpawnRate=3;C.Run.Horde.MaxSpawnRate=3
C.Run.Encounters.StuckRecoverAfter=300;C.Run.Encounters.ApproachTimeout=300
local original={DirectDamage=E.DirectDamage,AfterDirectHit=E.AfterDirectHit,OnKill=E.OnKill}
local owner,run,case,targets,trace
local report={TestRarity=testRarity,TestLevel=testLevel,Cases={},Resets={},Coverage="Real WeaponService select/fire/reload remotes; native ZombieService spawned models. QA anchors targets and accelerates spawn only."}
local function stage(s)script:SetAttribute("Stage",s)end
local function waitFor(check,seconds,message)
	local limit=os.clock()+seconds
	repeat if check()then return end;task.wait(.025)until os.clock()>limit
	error(message or "Server QA timeout")
end
local function humanoid(model)return model and model:FindFirstChildOfClass("Humanoid")end
local function playerHealth()return humanoid(owner.Character)end
local history={}
local function snapshot()
	local c=owner and owner.Character;local h=humanoid(c)
	return {State=R.RunState:GetAttribute("State"),RunActive=R.RunState:GetAttribute("RunActive"),Epoch=R.RunState:GetAttribute("RunEpoch"),
		SelectedWeapon=owner and owner:GetAttribute("SelectedWeapon"),Character=c and c:GetFullName()or "nil",CharacterParent=c and c.Parent and c.Parent:GetFullName()or "nil",
		Head=c and c:FindFirstChild("Head")~=nil,Root=c and c:FindFirstChild("HumanoidRootPart")~=nil,Health=h and h.Health or -1,History=table.clone(history)}
end
local stateConnection=R.RunState:GetAttributeChangedSignal("State"):Connect(function()
	table.insert(history,{Time=os.clock(),State=R.RunState:GetAttribute("State")})
	if #history>40 then table.remove(history,1)end
end)
local function native()
	local found={}
	for _,m in workspace:GetChildren()do
		local h=humanoid(m)
		if m:GetAttribute("IsZombie")and m:GetAttribute("State")~="Spawn"and h and h.Health>0 and m:FindFirstChild("HumanoidRootPart")then table.insert(found,m)end
	end
	return found
end
E.DirectDamage=function(player,model,base,context)
	-- Release the native target only after the real WeaponService raycast hit.
	-- This avoids network latency making a falling/moving target miss before QA
	-- can observe the production push; damage and effect results remain original.
	if trace and player==owner and case=="bravo_large_caliber"and model==targets[1]and not trace.Released then
		local root=model.HumanoidRootPart
		root.Anchored=false;root:SetNetworkOwner(nil)
		trace.Released=true
	end
	local modified=original.DirectDamage(player,model,base,context)
	if trace and player==owner then table.insert(trace.Damage,{Base=base,Modified=modified,Ratio=modified/base,Model=model.Name})end
	return modified
end
E.AfterDirectHit=function(player,model,headshot,direction,context)
	local beforeRoot=model:FindFirstChild("HumanoidRootPart")
	local beforeY=beforeRoot and beforeRoot.AssemblyLinearVelocity.Y or 0
	original.AfterDirectHit(player,model,headshot,direction,context)
	if trace and player==owner then
		local root=model:FindFirstChild("HumanoidRootPart")
		local v=root and root.AssemblyLinearVelocity or Vector3.zero
		table.insert(trace.Hits,{Headshot=headshot,State=model:GetAttribute("State"),HorizontalVelocity=Vector3.new(v.X,0,v.Z).Magnitude,YVelocity=v.Y,BeforeYVelocity=beforeY,
			Arc=context.Procs.Arc==true,Shock=context.Procs.Shock==true,Push=context.Procs.Push==true})
		if case=="volta_static_shock"and headshot then
			local snapshot=trace
			task.delay(.26,function()snapshot.StunAfterOrdinaryReact=model.Parent~=nil and model:GetAttribute("State")=="HitReact"end)
			local nearEnd=math.max(.26,Catalog.Values(case,testLevel,testRarity).Duration-.08)
			task.delay(nearEnd,function()snapshot.StunNearExpectedEnd=model.Parent~=nil and model:GetAttribute("State")=="HitReact"end)
		end
	end
end
E.OnKill=function(player)
	if trace and player==owner then trace.Kills+=1 end
	return original.OnKill(player)
end
local cleaned=false
local function cleanup()
	if cleaned then return end;cleaned=true
	trace=nil
	stateConnection:Disconnect()
	E.DirectDamage=original.DirectDamage;E.AfterDirectHit=original.AfterDirectHit;E.OnKill=original.OnKill
	C.Run.IntroDuration=saved.Intro;C.Run.Horde.BaseSpawnRate=saved.Rate;C.Run.Horde.MaxSpawnRate=saved.MaxRate
	C.Run.Encounters.StuckRecoverAfter=saved.Recover;C.Run.Encounters.ApproachTimeout=saved.Approach
	if owner then
		W.CancelActions(owner)
		if owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")then owner.Character.HumanoidRootPart.Anchored=false end
		if R.RunState:GetAttribute("RunActive")then D.EndRun(owner,"BoonEffectsQA")else E.Clear()end
	end
	script:SetAttribute("Report",game.HttpService:JSONEncode(report))
	script:SetAttribute("Cleaned",true)
	if #report.Cases==27 then script:SetAttribute("Success",true);script:SetAttribute("Complete",true)end
end
local function close(a,b,message)assert(math.abs(a-b)<.001,(message or "Unexpected value")..": "..tostring(a).." != "..tostring(b))end
local function reset(player)
	stage("Reset")
	trace=nil;case=nil
	if R.RunState:GetAttribute("RunActive")then assert(D.EndRun(player,"BoonEffectsQA"))end
	waitFor(function()return R.RunState:GetAttribute("State")=="RunEnded"end,30,"Reset to validated Floor1 failed")
	local previous=player.Character
	local added
	local addedConnection=player.CharacterAdded:Connect(function(c)added=c end)
	player:LoadCharacterAsync()
	local characterOk,characterError=pcall(function()
		waitFor(function()
			local c=player.Character;local h=humanoid(c)
			return c and added==c and c~=previous and c.Parent==workspace and h and h.Health>0 and c:FindFirstChild("Head")and c:FindFirstChild("HumanoidRootPart")
		end,10,"New CharacterAdded/head/root readiness failed")
	end)
	addedConnection:Disconnect();assert(characterOk,characterError)
	-- CharacterAdded reset can resume after LoadCharacterAsync; require the final phase.
	waitFor(function()return R.RunState:GetAttribute("State")=="RunEnded"end,5)
	task.wait(.3)
	assert(R.RunState:GetAttribute("State")=="RunEnded","Character reset changed ended phase")
	assert(D.StartRun(player,R.RunState:GetAttribute("RunEpoch")),"StartRun rejected")
	task.wait(.3)
	local ready=snapshot();table.insert(report.Resets,ready)
	script:SetAttribute("ResetSnapshot",game.HttpService:JSONEncode(ready))
	assert(player.Character==added and ready.State=="ChoosingWeapon"and ready.RunActive,"StartRun did not remain ChoosingWeapon: "..game.HttpService:JSONEncode(ready))
	run=Session.new();run:Begin(os.clock())
	return ready
end
local function prepare(id)
	stage("Prepare "..id)
	assert(Catalog[id],"Unknown QA boon")
	waitFor(function()return R.RunState:GetAttribute("State")=="EncounterActive"end,8,"Encounter did not start")
	waitFor(function()return #native()>=4 end,15,"Need four naturally spawned, emerged zombies")
	Z.StopSpawning()
	local models=native();targets={models[1],models[2],models[3]}
	local c=owner.Character;local root=c.HumanoidRootPart
	root.Anchored=true;root.AssemblyLinearVelocity=Vector3.zero
	local y=root.Position.Y
	c:PivotTo(CFrame.lookAt(Vector3.new(0,y,-60),Vector3.new(0,y,-45)))
	for i,m in models do
		local r=m.HumanoidRootPart;r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero
		local position=i==1 and Vector3.new(0,y,-45)or i==2 and Vector3.new(-5,y,-44)or i==3 and Vector3.new(5,y,-44)or Vector3.new(70,y,60+i)
		m:PivotTo(CFrame.new(position));humanoid(m).MaxHealth=1000;humanoid(m).Health=1000;humanoid(m).WalkSpeed=0
	end
	-- Refill with no boon first: capacity awards must not create free ammunition.
	run.Boons={};E.Bind(run,owner);E.RefreshHealth();W.Refill(owner)
	run.Boons[id]={Id=id,Level=testLevel,Rarity=testRarity};E.Bind(run,owner);E.RefreshHealth();W.RefreshStats(owner)
	playerHealth().Health=id=="weiss_adrenaline"and 25 or id=="weiss_coagulation"and 50 or 100
	if id=="weiss_coagulation"then humanoid(targets[1]).Health=1 end
	case=id;trace={Damage={},Hits={},Kills=0,HealthBefore=playerHealth().Health,CollateralBefore={humanoid(targets[2]).Health,humanoid(targets[3]).Health}}
	local target=id=="volta_static_shock"and targets[1].Head or targets[1].Torso
	local params=RaycastParams.new();params.FilterDescendantsInstances={c}
	local ray=workspace:Raycast(c.Head.Position,(target.Position-c.Head.Position),params)
	assert(ray and ray.Instance:IsDescendantOf(targets[1]),"QA firing lane obstructed")
	return {Target=target,Capacity=owner:GetAttribute("MagazineCapacity"),Health=playerHealth().Health,MaxHealth=playerHealth().MaxHealth,TestRarity=testRarity,TestLevel=testLevel}
end
local function check(data)
	stage("Check "..case)
	assert(trace,"No prepared QA case")
	local v=Catalog.Values(case,testLevel,testRarity)
	local t=trace;local result={Weapon=owner:GetAttribute("SelectedWeapon"),Boon=case,Rarity=testRarity,Level=testLevel,Expected=v,Damage=t.Damage,Hits=t.Hits,Kills=t.Kills}
	local function damage(count)
		assert(#t.Damage==count,"Expected "..count.." direct target records; observed "..#t.Damage)
		assert(#t.Hits==count,"AfterDirectHit count differs")
	end
	if case=="volta_arc_discharge"then
		damage(1);assert(t.Hits[1].Arc,"No arc proc")
		result.Collateral={t.CollateralBefore[1]-humanoid(targets[2]).Health,t.CollateralBefore[2]-humanoid(targets[3]).Health}
		close(result.Collateral[1],v.Damage);close(result.Collateral[2],v.Damage);assert(t.Kills==0,"Unexpected recursive kill")
	elseif case=="volta_static_shock"then
		damage(1);assert(t.Hits[1].Headshot and t.Hits[1].Shock,"Actual headshot did not stun")
		assert(t.Hits[1].State=="HitReact"and t.StunAfterOrdinaryReact,"Stun did not outlive ordinary head reaction")
		assert(t.StunNearExpectedEnd,"Stun did not persist near authored duration")
		result.StunAfterOrdinaryReact=t.StunAfterOrdinaryReact
		result.StunNearExpectedEnd=t.StunNearExpectedEnd;result.StunObservedAt=math.max(.26,v.Duration-.08)
	elseif case=="volta_high_voltage"then damage(2);close(t.Damage[1].Ratio,1);close(t.Damage[2].Ratio,1+v.PerStack)
	elseif case=="bravo_belt_feed"then
		local expected=math.ceil(C.Weapons[result.Weapon].MagazineSize*(1+v.Fraction))
		assert(owner:GetAttribute("MagazineCapacity")==expected,"Server capacity mismatch")
		assert(data.Ammo==expected and data.Reloading==false,"Genuine reload did not fill capacity")
		result.Capacity=expected;result.ReloadedAmmo=data.Ammo
	elseif case=="bravo_first_salvo"then
		damage(v.Shots+1);for i=1,v.Shots do close(t.Damage[i].Ratio,1+v.Bonus)end;close(t.Damage[v.Shots+1].Ratio,1)
	elseif case=="bravo_large_caliber"then
		damage(1);assert(t.Released,"Native target was not released after actual ray hit");assert(t.Hits[1].Push,"Push was not applied")
		close(t.Hits[1].HorizontalVelocity,v.Speed,"Push velocity does not match authored speed")
		close(t.Hits[1].YVelocity,math.clamp(t.Hits[1].BeforeYVelocity,-10,10),"Push added vertical force")
		result.Coverage="Native target released synchronously after actual ray hit; production AfterDirectHit push and velocity preserved"
	elseif case=="weiss_coagulation"then
		damage(1);assert(t.Kills==1 and humanoid(targets[1]).Health<=0,"Kill must be genuine and attributed once")
		close(playerHealth().Health,math.min(playerHealth().MaxHealth,t.HealthBefore+v.Heal),"Kill healing incorrect")
		result.Health=playerHealth().Health
		-- Bounded scalar edge case is labelled separately from the real kill above.
		task.wait(v.Cooldown+.05);playerHealth().Health=playerHealth().MaxHealth-1;original.OnKill(owner);close(playerHealth().Health,playerHealth().MaxHealth,"Heal exceeds max")
		result.BoundedHealScalar=true
	elseif case=="weiss_adrenaline"then damage(1);close(t.Damage[1].Ratio,1+v.Bonus*.75);result.Health=playerHealth().Health
	elseif case=="weiss_field_protocol"then
		local expectedMax=Catalog.Limits.BaseHealth+math.clamp(v.MaxHealth,0,Catalog.Limits.MaxHealthBonus)
		close(playerHealth().MaxHealth,expectedMax)
		playerHealth().Health=50;E.OnFloorStart();close(playerHealth().Health,math.min(expectedMax,50+v.Heal))
		playerHealth().Health=expectedMax-1;E.OnFloorStart();close(playerHealth().Health,expectedMax)
		result.MaxHealth=expectedMax;result.FloorStartHeal=v.Heal;result.Coverage="Actual Humanoid/production OnFloorStart hook; no additional physical floor transition in this case"
	end
	result.Success=true;table.insert(report.Cases,result)
	script:SetAttribute("Report",game.HttpService:JSONEncode(report))
	return result
end
local busy=false
bridge.OnServerInvoke=function(player,action,data)
	if cleaned then return {Ok=false,Error="QA bridge already cleaned"}end
	if owner and owner~=player or busy then return {Ok=false,Error="QA owner/busy"}end
	owner=player;busy=true
	local ok,result=pcall(function()
		if action=="Reset"then return reset(player)
		elseif action=="Prepare"then return prepare(data)
		elseif action=="Check"then return check(data or {})
		elseif action=="Snapshot"then return snapshot()
		elseif action=="Cleanup"then cleanup();return true end
		error("Unknown QA action")
	end)
	busy=false
	if not ok then
		script:SetAttribute("FailureSnapshot",game.HttpService:JSONEncode(snapshot()))
		script:SetAttribute("Error",tostring(result));script:SetAttribute("Success",false);script:SetAttribute("Complete",true)
		cleanup()
	end
	return {Ok=ok,Result=ok and result or nil,Error=not ok and tostring(result)or nil}
end
-- A crashed/disabled client must not leave replaced methods or tuning indefinitely.
task.delay(300,function()if not cleaned then script:SetAttribute("Error","Client QA watchdog expired");script:SetAttribute("Success",false);script:SetAttribute("Complete",true);cleanup()end end)
