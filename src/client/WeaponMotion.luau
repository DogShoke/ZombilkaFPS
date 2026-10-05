local WeaponMotion = {}
WeaponMotion.__index = WeaponMotion
local function frame(clip, position, boneName, parents)
	local first = math.clamp(math.floor(position) + 1,1,#clip.frames)
	local second = math.min(first+1,#clip.frames)
	local function value(index)
		local name=boneName
		local values=clip.frames[index][name]
		while not values and parents[name] do name=parents[name] values=clip.frames[index][name] end
		if not values then return CFrame.identity end
		return CFrame.new(table.unpack(values))
	end
	return value(first):Lerp(value(second),position%1)
end
function WeaponMotion.new(model,root,module,basis)
	local self=setmetatable({Root=root,Basis=basis or CFrame.identity,Clips=require(module),Bones={},Rest={},IdleTime=0,Time=0},WeaponMotion)
	for _,b in ipairs(model:GetDescendants()) do if b:IsA("Bone") then
		table.insert(self.Bones,b) self.Rest[b]=root.CFrame:ToObjectSpace(b.WorldCFrame)
	end end
	local function depth(b) local n=0 while b.Parent and b.Parent:IsA("Bone") do b=b.Parent n+=1 end return n end
	table.sort(self.Bones,function(a,b) return depth(a)<depth(b) end)
	return self
end
function WeaponMotion:Play(name,duration)
	if not self.Clips[name] then return end
	self.BlendFrom,self.BlendTime=self.LastDelta,0
	self.Name,self.Time,self.Duration=name,0,duration
end
function WeaponMotion:Stop(name)
	if self.Name~=name then return end
	self.BlendFrom,self.BlendTime=self.LastDelta,0
	self.Name=nil self.Time=0
end
function WeaponMotion:Update(dt)
	self.IdleTime+=dt self.Time+=dt
	local playing=self.Name and self.Time<self.Duration
	local clip=self.Clips[playing and self.Name or "Idle"]
	if not clip then return end
	local position=playing and self.Time/self.Duration*(#clip.frames-1) or self.IdleTime*clip.fps%math.max(1,#clip.frames-1)
	self.BlendTime=(self.BlendTime or 0)+dt
	local blend=math.clamp(self.BlendTime/0.1,0,1)
	local world,deltas={},{}
	for _,b in ipairs(self.Bones) do
		local sampled=frame(clip,position,b.Name,self.Clips.parents)
		if self.BlendFrom and self.BlendFrom[b.Name] and blend<1 then sampled=self.BlendFrom[b.Name]:Lerp(sampled,blend) end
		deltas[b.Name]=sampled
		local delta=self.Basis:Inverse()*sampled*self.Basis
		local desired=self.Root.CFrame*delta*self.Rest[b]
		local parent=b.Parent
		local parentFrame=world[parent] or (parent:IsA("BasePart") and parent.CFrame) or self.Root.CFrame
		b.Transform=b.CFrame:Inverse()*parentFrame:ToObjectSpace(desired)
		world[b]=desired
	end
	self.LastDelta=deltas
	if blend>=1 then self.BlendFrom=nil end
end
return WeaponMotion
