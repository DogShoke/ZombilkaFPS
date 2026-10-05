local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Variants=require(script.Parent.ZombieVariants)
local Clips=require(script.Parent.ZombieClips)
local ZombieRig={}
local clipIds={}
local function track(animator,key,priority,looped)
	local id=Config.ZombieAnimations[key]
	if (not id or id=="") and RunService:IsStudio() then
		if not clipIds[key] then
			local sequence=Clips.Create(key)
			local ok,result=pcall(function() return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(sequence) end)
			sequence:Destroy() if ok then clipIds[key]=result end
		end
		id=clipIds[key]
	end
	if not id or id=="" then return end
	local a=Instance.new("Animation") a.Name=key a.AnimationId=id a.Parent=animator
	local ok,t=pcall(function() return animator:LoadAnimation(a) end)
	if not ok then return end
	t.Priority=priority t.Looped=looped return t
end
function ZombieRig.Create(position,variant,tuning)
	local model=Variants.Create(variant or 1) model.Name="Zombie" model:SetAttribute("IsZombie",true) model:SetAttribute("State","Spawn")
	local root=model.HumanoidRootPart local h=model.Humanoid
	model.PrimaryPart=root
	h.MaxHealth=tuning and tuning.Health or Config.Zombies.MaxHealth h.Health=h.MaxHealth h.WalkSpeed=tuning and tuning.Speed or Config.Zombies.WalkSpeed h.BreakJointsOnDeath=false h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	local colors=model:FindFirstChildOfClass("BodyColors") if colors then colors:Destroy() end
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false p.CanTouch=false p.CanCollide=p.Name=="Torso" p.CanQuery=model:GetAttribute("SkinnedZombie") and (p.Name=="Head" or p.Name=="Torso") or not model:GetAttribute("SkinnedZombie") and p~=root p.CollisionGroup="Zombies" end end
	model.Parent=workspace model:PivotTo(CFrame.new(position+Vector3.new(0,3,0))) root:SetNetworkOwner(nil)
	local animator=Instance.new("Animator") animator.Parent=h
	local tracks={}
	if not model:GetAttribute("SkinnedZombie") then tracks={Idle=track(animator,"Idle",Enum.AnimationPriority.Idle,true),Run=track(animator,"Run",Enum.AnimationPriority.Movement,true),Attack=track(animator,"Attack",Enum.AnimationPriority.Action,false),BodyHit=track(animator,"BodyHit",Enum.AnimationPriority.Action2,false),HeadHit=track(animator,"HeadHit",Enum.AnimationPriority.Action3,false),Death=track(animator,"Death",Enum.AnimationPriority.Action4,false)} end
	if tracks.Idle then tracks.Idle:Play(0.15) end
	local rig={model=model,root=root,humanoid=h,head=model.Head,torso=model.Torso,tracks=tracks,lastState="Spawn",lastHit=0}
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p~=root then local visible=p:GetAttribute("VisualTransparency") or 0 p.Transparency=1 TweenService:Create(p,TweenInfo.new(Config.Zombies.SpawnFade),{Transparency=visible}):Play() end end
	return rig
end
function ZombieRig.Pose(rig,state)
	local t=rig.tracks
	local speed=(rig.root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
	if t.Run then
		if speed>0.7 and state~="AttackWindup" and state~="AttackRecover" then
			if not t.Run.IsPlaying then t.Run:Play(0.18) end
			t.Run:AdjustSpeed(math.clamp(speed/Config.ZombieAnimationTuning.RunSpeed,0.3,2))
		elseif t.Run.IsPlaying then t.Run:Stop(0.18) end
	end
	if state=="AttackWindup" and rig.lastState~=state and t.Attack then
		t.Attack:Play(0.06,1,t.Attack.Length>0 and t.Attack.Length/(Config.Zombies.AttackWindup+Config.Zombies.AttackRecover) or 1)
	end
	if state=="HitReact" and rig.lastState=="AttackWindup" and t.Attack then t.Attack:Stop(0.08) end
	rig.lastState=state
end
function ZombieRig.React(rig,headshot)
	local now=os.clock() if now-rig.lastHit<0.07 then return end rig.lastHit=now
	local t=rig.tracks[headshot and "HeadHit" or "BodyHit"]
	if t then t:Stop(0.02) t:Play(0.04) return end
	-- Finite authored pose fallback for an unpublished reaction clip.
	local joint=rig.torso:FindFirstChild(headshot and "Neck" or "Root Hip") or rig.root:FindFirstChildOfClass("Motor6D")
	if joint then
		if rig.hitTween then rig.hitTween:Cancel() end
		rig.baseC0=rig.baseC0 or {} rig.baseC0[joint]=rig.baseC0[joint] or joint.C0
		joint.C0=rig.baseC0[joint]*CFrame.Angles(math.rad(headshot and -25 or -10),0,0)
		rig.hitTween=TweenService:Create(joint,TweenInfo.new(headshot and 0.38 or 0.3),{C0=rig.baseC0[joint]}) rig.hitTween:Play()
	end
end
function ZombieRig.Pause(rig,paused)
	rig.pausedSpeeds = rig.pausedSpeeds or {}
	for _,t in pairs(rig.tracks) do
		if t.IsPlaying then
			if paused then
				if rig.pausedSpeeds[t] == nil then rig.pausedSpeeds[t] = t.Speed end
				t:AdjustSpeed(0)
			else
				t:AdjustSpeed(rig.pausedSpeeds[t] or 1)
			end
		end
	end
	if not paused then table.clear(rig.pausedSpeeds) end
end
function ZombieRig.Die(rig)
	for _,t in pairs(rig.tracks) do t:Stop(0.08) end
	for _,p in rig.model:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false p.CanQuery=false end end
	rig.root.Anchored=true
	if rig.tracks.Death then rig.tracks.Death:Play(0.08)
	else TweenService:Create(rig.root,TweenInfo.new(0.75),{CFrame=rig.root.CFrame*CFrame.new(0,-2.4,0)*CFrame.Angles(math.rad(88),0,0)}):Play() end
	task.delay(math.max(0,Config.Zombies.CorpseLifetime-0.8),function()
		if not rig.model.Parent then return end
		for _,p in rig.model:GetDescendants() do if p:IsA("BasePart") then TweenService:Create(p,TweenInfo.new(0.7),{Transparency=1}):Play() end end
	end)
end
return ZombieRig
