local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Spring = require(game.ReplicatedStorage.Shared.Spring)

local ViewmodelController = {}
ViewmodelController.__index = ViewmodelController

local function createPart(model, name, size, color, material, offset)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = model
	return { Instance = part, Offset = offset }
end

function ViewmodelController.new(camera)
	local model = Instance.new("Model")
	model.Name = "PrototypePistolViewmodel"
	model.Parent = camera
	local black = Color3.fromRGB(33, 38, 41)
	local steel = Color3.fromRGB(78, 83, 84)
	local skin = Color3.fromRGB(153, 121, 98)
	local parts = {
		createPart(model, "Frame", Vector3.new(0.25, 0.25, 0.65), black, Enum.Material.Metal, CFrame.new(0, 0, 0)),
		createPart(model, "Slide", Vector3.new(0.29, 0.2, 0.72), steel, Enum.Material.Metal, CFrame.new(0, 0.14, -0.07)),
		createPart(model, "Grip", Vector3.new(0.19, 0.48, 0.2), black, Enum.Material.SmoothPlastic, CFrame.new(0, -0.32, 0.19) * CFrame.Angles(math.rad(-13), 0, 0)),
		createPart(model, "Barrel", Vector3.new(0.17, 0.17, 0.18), black, Enum.Material.Metal, CFrame.new(0, 0.09, -0.46)),
		createPart(model, "FrontSight", Vector3.new(0.08, 0.09, 0.07), Color3.fromRGB(207, 190, 134), Enum.Material.Metal, CFrame.new(0, 0.29, -0.36)),
		createPart(model, "RearSight", Vector3.new(0.16, 0.07, 0.06), black, Enum.Material.Metal, CFrame.new(0, 0.27, 0.22)),
		createPart(model, "RightHand", Vector3.new(0.25, 0.3, 0.3), skin, Enum.Material.SmoothPlastic, CFrame.new(0.07, -0.31, 0.28)),
		createPart(model, "RightForearm", Vector3.new(0.28, 0.3, 0.63), skin, Enum.Material.SmoothPlastic, CFrame.new(0.14, -0.47, 0.72) * CFrame.Angles(math.rad(-20), 0, 0)),
		createPart(model, "LeftHand", Vector3.new(0.24, 0.28, 0.3), skin, Enum.Material.SmoothPlastic, CFrame.new(-0.21, -0.15, -0.03)),
		createPart(model, "LeftForearm", Vector3.new(0.27, 0.29, 0.7), skin, Enum.Material.SmoothPlastic, CFrame.new(-0.34, -0.37, 0.43) * CFrame.Angles(math.rad(-28), math.rad(-18), 0)),
	}
	local flash = createPart(model, "MuzzleFlash", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(255, 212, 111), Enum.Material.Neon, CFrame.new(0, 0.1, -0.61))
	flash.Instance.Shape = Enum.PartType.Ball
	flash.Instance.Transparency = 1
	table.insert(parts, flash)
	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Range = 9
	light.Color = Color3.fromRGB(255, 209, 133)
	light.Parent = flash.Instance
	return setmetatable({
		Model = model, Parts = parts, Flash = flash.Instance, Light = light,
		SwayPos = Spring.new(Vector3.zero, Config.Feel.SwayFrequency),
		SwayRot = Spring.new(Vector3.zero, Config.Feel.SwayFrequency),
		RecoilPos = Spring.new(Vector3.zero, Config.Feel.RecoilFrequency),
		RecoilRot = Spring.new(Vector3.zero, Config.Feel.RecoilFrequency),
		Land = Spring.new(0, 5), ads = 0, sprint = 0, strafe = 0, bobClock = 0, flashSerial = 0,
	}, ViewmodelController)
end

function ViewmodelController:Destroy()
	self.Model:Destroy()
end

function ViewmodelController:Fire(ads)
	local mult = 1 - ads * (1 - Config.Feel.AdsRecoilMultiplier)
	self.RecoilPos:Impulse(Config.Feel.HipViewKick * mult * 12)
	self.RecoilRot:Impulse(Config.Feel.HipViewRotate * mult * 12)
	self.flashSerial += 1
	local serial = self.flashSerial
	self.Flash.Transparency = 0.18
	self.Light.Brightness = 2.4
	task.delay(0.055, function()
		if self.flashSerial == serial and self.Flash.Parent then
			self.Flash.Transparency = 1
			self.Light.Brightness = 0
		end
	end)
end

function ViewmodelController:LandImpulse()
	self.Land:Impulse(Config.Feel.LandingKick * 12)
end

function ViewmodelController:Tracer(hitPosition)
	local startPosition = self.Flash.Position
	local delta = hitPosition - startPosition
	if delta.Magnitude < 0.1 then return end
	local tracer = Instance.new("Part")
	tracer.Name = "ShotTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 225, 155)
	tracer.Transparency = 0.28
	tracer.Size = Vector3.new(0.025, 0.025, math.min(delta.Magnitude, 80))
	tracer.CFrame = CFrame.lookAt(startPosition + delta.Unit * (tracer.Size.Z / 2), hitPosition)
	tracer.Parent = workspace
	Debris:AddItem(tracer, 0.055)
end

function ViewmodelController:Impact(position, biological)
	local impact = Instance.new("Part")
	impact.Name = "ShotImpact"
	impact.Shape = Enum.PartType.Ball
	impact.Size = Vector3.new(biological and 0.3 or 0.15, biological and 0.3 or 0.15, biological and 0.3 or 0.15)
	impact.Anchored = true
	impact.CanCollide = false
	impact.CanTouch = false
	impact.CanQuery = false
	impact.Material = Enum.Material.Neon
	impact.Color = biological and Color3.fromRGB(155, 36, 28) or Color3.fromRGB(245, 200, 123)
	impact.Position = position
	impact.Parent = workspace
	Debris:AddItem(impact, biological and 0.18 or 0.1)
end

function ViewmodelController:Update(dt, camera, mouseDelta, horizontalSpeed, strafe, wantsAds, wantsSprint)
	local feel = Config.Feel
	self.ads += ((wantsAds and 1 or 0) - self.ads) * (1 - math.exp(-feel.AdsResponse * dt))
	self.sprint += ((wantsSprint and 1 or 0) - self.sprint) * (1 - math.exp(-feel.SprintResponse * dt))
	self.strafe += (strafe - self.strafe) * (1 - math.exp(-dt * 11))
	local swayMult = 1 - self.ads * (1 - feel.SwayAdsMultiplier)
	local delta = Vector2.new(math.clamp(mouseDelta.X, -35, 35), math.clamp(mouseDelta.Y, -35, 35))
	self.SwayPos.Target = Vector3.new(-delta.X * feel.SwayPosition.X, delta.Y * feel.SwayPosition.Y, 0) * swayMult
	self.SwayRot.Target = Vector3.new(-delta.Y * feel.SwayRotation.X, -delta.X * feel.SwayRotation.Y, -delta.X * feel.SwayRotation.Z) * swayMult
	local swayPos = self.SwayPos:Step(dt)
	local swayRot = self.SwayRot:Step(dt)
	local recoilPos = self.RecoilPos:Step(dt)
	local recoilRot = self.RecoilRot:Step(dt)
	local landing = self.Land:Step(dt)
	local movement = math.clamp(horizontalSpeed / Config.Movement.WalkSpeed, 0, 1.6)
	local bobAmount = (feel.BobHip + (feel.BobSprint - feel.BobHip) * self.sprint) * movement * (1 - self.ads * (1 - feel.BobAdsMultiplier))
	self.bobClock += dt * (feel.BobWalkFrequency + (feel.BobSprintFrequency - feel.BobWalkFrequency) * self.sprint) * movement
	local bob = Vector3.new(math.cos(self.bobClock) * bobAmount * 0.55, math.abs(math.sin(self.bobClock)) * bobAmount, 0)
	local pose = feel.HipPose:Lerp(feel.SprintPose, self.sprint):Lerp(feel.AdsPose, self.ads)
	local motion = CFrame.new(swayPos + recoilPos + bob + Vector3.new(-self.strafe * feel.StrafeShift * (1 - self.ads * 0.7), -landing, 0))
		* CFrame.Angles(swayRot.X + recoilRot.X, swayRot.Y + recoilRot.Y, swayRot.Z + recoilRot.Z + self.strafe * feel.StrafeRoll * (1 - self.ads * 0.7))
	local root = camera.CFrame * pose * motion
	for _, entry in ipairs(self.Parts) do entry.Instance.CFrame = root * entry.Offset end
	if self.Model.Parent ~= camera then self.Model.Parent = camera end
	return self.ads
end

return ViewmodelController
