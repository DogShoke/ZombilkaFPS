local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Spring = require(ReplicatedStorage.Shared.Spring)

local ViewmodelController = {}
ViewmodelController.__index = ViewmodelController

local function invisibleAnchor(name, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	return part, attachment
end

local function loadTrack(model, animator, key, priority, looped)
	local animation = Instance.new("Animation")
	animation.Name = key
	animation.AnimationId = Config.Animations[key]
	animation.Parent = model
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	if not ok then
		warn("FpsGlock animation load failed", key, track)
		return nil
	end
	track.Priority = priority
	track.Looped = looped
	return track
end

function ViewmodelController.new(camera)
	local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("FpsGlock")
	local model = template:Clone()
	model.Name = "FpsGlockViewmodel"
	local root = model:FindFirstChild("RootPart") or model.PrimaryPart
	assert(root and root:IsA("BasePart"), "FpsGlock needs a RootPart")
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.CastShadow = false
			item.Massless = true
			item.Anchored = item == root
		end
	end
	model.Parent = camera
	local barrel = root:FindFirstChild("Barrel", true)
	local controller = model:FindFirstChildOfClass("AnimationController")
	assert(controller, "FpsGlock needs an AnimationController")
	local animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = controller
	local tracks = {
		Idle = loadTrack(model, animator, "Idle", Enum.AnimationPriority.Idle, true),
		Shoot = loadTrack(model, animator, "Shoot", Enum.AnimationPriority.Action, false),
		Reload = loadTrack(model, animator, "Reload", Enum.AnimationPriority.Action2, false),
	}
	if tracks.Idle then tracks.Idle:Play(0.15) end
	local muzzlePart, muzzleAttachment = invisibleAnchor("MuzzleCosmeticAnchor", model)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "MuzzleFlash"
	emitter.Enabled = false
	emitter.Lifetime = NumberRange.new(0.035, 0.065)
	emitter.Speed = NumberRange.new(0)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.27), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 139), Color3.fromRGB(255, 154, 58))
	emitter.LightEmission = 1
	emitter.Parent = muzzleAttachment
	local light = Instance.new("PointLight")
	light.Name = "ShotLight"
	light.Range = 8
	light.Brightness = 0
	light.Color = Color3.fromRGB(255, 202, 118)
	light.Parent = muzzlePart
	return setmetatable({
		Model = model, Root = root, Barrel = barrel, Tracks = tracks,
		MuzzlePart = muzzlePart, MuzzleAttachment = muzzleAttachment, MuzzleEmitter = emitter, Light = light,
		SwayPos = Spring.new(Vector3.zero, Config.Feel.SwayFrequency),
		SwayRot = Spring.new(Vector3.zero, Config.Feel.SwayFrequency),
		RecoilPos = Spring.new(Vector3.zero, Config.Feel.RecoilFrequency),
		RecoilRot = Spring.new(Vector3.zero, Config.Feel.RecoilFrequency),
		Land = Spring.new(0, 5), ads = 0, sprint = 0, strafe = 0, bobClock = 0,
		flashSerial = 0, sprintFireUntil = 0,
	}, ViewmodelController)
end

function ViewmodelController:Destroy()
	for _, track in pairs(self.Tracks) do track:Stop(0) end
	self.Model:Destroy()
end

function ViewmodelController:Fire(ads, sprinting)
	local feel = Config.Feel
	local multiplier = 1 - ads * (1 - feel.AdsRecoilMultiplier)
	self.RecoilPos.Position += feel.ViewmodelKick * multiplier * 0.7
	self.RecoilRot.Position += feel.ViewmodelRotate * multiplier * 0.65
	self.RecoilPos:Impulse(feel.ViewmodelKick * multiplier * 4)
	self.RecoilRot:Impulse(feel.ViewmodelRotate * multiplier * 4)
	if sprinting then self.sprintFireUntil = os.clock() + feel.SprintFireHold end
	local shoot = self.Tracks.Shoot
	if shoot then
		if shoot.IsPlaying then shoot:Stop(0) end
		shoot:Play(0.02)
	end
	self.flashSerial += 1
	local serial = self.flashSerial
	self.MuzzleEmitter:Emit(3)
	self.Light.Brightness = 2.2
	task.delay(Config.Vfx.MuzzleDuration, function()
		if self.flashSerial == serial and self.Light.Parent then self.Light.Brightness = 0 end
	end)
end

function ViewmodelController:Reload()
	local reload = self.Tracks.Reload
	if reload then reload:Play(0.08) end
end

function ViewmodelController:LandImpulse()
	self.Land:Impulse(Config.Feel.LandingKick * 12)
end

function ViewmodelController:Tracer(hitPosition)
	local startPosition = self.MuzzleAttachment.WorldPosition
	local delta = hitPosition - startPosition
	if delta.Magnitude < 0.1 then return end
	local endPosition = startPosition + delta.Unit * math.min(delta.Magnitude, Config.Vfx.TracerMaxLength)
	local endPart, endAttachment = invisibleAnchor("TracerEndpoint", workspace)
	endPart.Position = endPosition
	local beam = Instance.new("Beam")
	beam.Name = "ShotStreak"
	beam.Attachment0 = self.MuzzleAttachment
	beam.Attachment1 = endAttachment
	beam.FaceCamera = true
	beam.Width0 = 0.035
	beam.Width1 = 0.008
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 231, 174))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0.82) })
	beam.Parent = self.MuzzlePart
	Debris:AddItem(beam, Config.Vfx.TracerDuration)
	Debris:AddItem(endPart, Config.Vfx.TracerDuration)
end

function ViewmodelController:Impact(position, kind)
	local anchor, attachment = invisibleAnchor("ShotImpact", workspace)
	anchor.Position = position
	local biological = kind == "Body" or kind == "Headshot"
	local headshot = kind == "Headshot"
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.08, headshot and 0.24 or 0.16)
	emitter.Speed = NumberRange.new(1, headshot and 6 or 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 6
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, headshot and 0.14 or 0.08), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(biological and Color3.fromRGB(146, 40, 31) or Color3.fromRGB(231, 193, 121))
	emitter.LightEmission = biological and 0 or 0.7
	emitter.Parent = attachment
	emitter:Emit(headshot and 11 or biological and 6 or 4)
	local duration = headshot and Config.Vfx.HeadImpactDuration or biological and Config.Vfx.BodyImpactDuration or Config.Vfx.WorldImpactDuration
	Debris:AddItem(anchor, duration + 0.12)
end

function ViewmodelController:Update(dt, camera, mouseDelta, horizontalSpeed, strafe, wantsAds, wantsSprint)
	local feel = Config.Feel
	local effectiveSprint = wantsSprint and os.clock() >= self.sprintFireUntil
	self.ads += ((wantsAds and 1 or 0) - self.ads) * (1 - math.exp(-feel.AdsResponse * dt))
	local sprintResponse = effectiveSprint and feel.SprintResponse or feel.SprintFireTransitionSpeed
	self.sprint += ((effectiveSprint and 1 or 0) - self.sprint) * (1 - math.exp(-sprintResponse * dt))
	self.strafe += (strafe - self.strafe) * (1 - math.exp(-feel.StrafeResponse * dt))
	local swayMultiplier = 1 - self.ads * (1 - feel.SwayAdsMultiplier)
	local delta = Vector2.new(math.clamp(mouseDelta.X, -35, 35), math.clamp(mouseDelta.Y, -35, 35))
	self.SwayPos.Target = Vector3.new(-delta.X * feel.SwayPosition.X, delta.Y * feel.SwayPosition.Y, 0) * swayMultiplier
	self.SwayRot.Target = Vector3.new(-delta.Y * feel.SwayRotation.X, -delta.X * feel.SwayRotation.Y, -delta.X * feel.SwayRotation.Z) * swayMultiplier
	local swayPos = self.SwayPos:Step(dt)
	local swayRot = self.SwayRot:Step(dt)
	local recoilPos = self.RecoilPos:Step(dt)
	local recoilRot = self.RecoilRot:Step(dt)
	local landing = self.Land:Step(dt)
	local movement = math.clamp(horizontalSpeed / Config.Movement.WalkSpeed, 0, 1.5)
	local bobAmount = (feel.BobHip + (feel.BobSprint - feel.BobHip) * self.sprint) * movement * (1 - self.ads * (1 - feel.BobAdsMultiplier))
	self.bobClock += dt * (feel.BobWalkFrequency + (feel.BobSprintFrequency - feel.BobWalkFrequency) * self.sprint) * movement
	local bob = Vector3.new(math.cos(self.bobClock) * bobAmount * 0.55, math.abs(math.sin(self.bobClock)) * bobAmount, 0)
	-- Camera -> base/ADS/sprint pose -> translational effects -> rotational effects. Bones are animation-owned.
	local pose = feel.HipPose:Lerp(feel.SprintPose, self.sprint):Lerp(feel.AdsPose, self.ads)
	local motion = CFrame.new(swayPos + recoilPos + bob + Vector3.new(-self.strafe * feel.StrafeShift * (1 - self.ads * 0.7), -landing, 0))
		* CFrame.Angles(swayRot.X + recoilRot.X, swayRot.Y + recoilRot.Y, swayRot.Z + recoilRot.Z + self.strafe * feel.StrafeRoll * (1 - self.ads * 0.7))
	self.Root.CFrame = camera.CFrame * pose * motion
	local muzzlePosition = self.Barrel and self.Barrel.WorldPosition or (self.Root.CFrame * CFrame.new(-1.25, 0.45, -1)).Position
	self.MuzzlePart.CFrame = CFrame.lookAt(muzzlePosition + camera.CFrame.LookVector * 0.25, muzzlePosition + camera.CFrame.LookVector * 1.25)
	if self.Model.Parent ~= camera then self.Model.Parent = camera end
	return self.ads
end

return ViewmodelController
