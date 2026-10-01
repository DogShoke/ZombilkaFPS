-- Short authored pose clips fill the source model's missing reactions/death.
-- Registered as Animator clips in Studio. Publish these sequences and fill Config.ZombieAnimations
-- for live servers; the same finite keyframes have a deterministic joint fallback.
local Clips = {}
local function pose(parent,name,cf)
	local p=Instance.new("Pose") p.Name=name p.CFrame=cf or CFrame.identity p.Parent=parent return p
end
local function frame(sequence,time,torso,head,left,right)
	local k=Instance.new("Keyframe") k.Time=time k.Parent=sequence
	local root=pose(k,"HumanoidRootPart") local body=pose(root,"Torso",torso)
	pose(body,"Head",head) pose(body,"Left Arm",left) pose(body,"Right Arm",right)
	pose(body,"Left Leg") pose(body,"Right Leg")
end
function Clips.Create(name)
	local s=Instance.new("KeyframeSequence") s.Name=name s.Loop=false s.Priority=Enum.AnimationPriority.Action2
	frame(s,0)
	if name=="BodyHit" then
		frame(s,0.07,CFrame.Angles(math.rad(-13),0,math.rad(5)),CFrame.Angles(math.rad(8),0,0)) frame(s,0.3)
	elseif name=="HeadHit" then
		frame(s,0.06,CFrame.Angles(math.rad(-9),0,0),CFrame.Angles(math.rad(-30),math.rad(14),0)) frame(s,0.38)
	else
		s.Priority=Enum.AnimationPriority.Action4
		frame(s,0.22,CFrame.new(0,-0.25,0)*CFrame.Angles(math.rad(-18),0,0),CFrame.Angles(math.rad(-25),0,0))
		frame(s,0.75,CFrame.new(0,0,-2.5)*CFrame.Angles(math.rad(88),0,math.rad(10)),CFrame.Angles(math.rad(14),0,0),CFrame.Angles(0,0,math.rad(-30)),CFrame.Angles(0,0,math.rad(30)))
		frame(s,3.5,CFrame.new(0,0,-2.5)*CFrame.Angles(math.rad(88),0,math.rad(10)),CFrame.Angles(math.rad(14),0,0),CFrame.Angles(0,0,math.rad(-30)),CFrame.Angles(0,0,math.rad(30)))
	end
	return s
end
return Clips
