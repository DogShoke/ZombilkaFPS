local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local S = Config.Movement
local SlideController = {}
SlideController.__index = SlideController

function SlideController.new()
	local self = setmetatable({ Active = false, Blend = 0, nextStart = 0 }, SlideController)
	RunService.PreSimulation:Connect(function(dt) self:Step(dt) end)
	return self
end
function SlideController:Bind(character)
	self:Cancel()
	self.humanoid = character:WaitForChild("Humanoid")
	self.root = character:WaitForChild("HumanoidRootPart")
	self.character, self.nextStart, self.Blend = character, 0, 0
	self.params = RaycastParams.new()
	self.params.FilterType = Enum.RaycastFilterType.Exclude
	self.params.FilterDescendantsInstances = { character }
	self.params.RespectCanCollide = true
	self.params.CollisionGroup = "Players"
	self.humanoid.Died:Once(function() self:Cancel() end)
end
-- Keep a quick C press through the initial movement acceleration.
function SlideController:Request(blocked)
	local h = self.humanoid
	if blocked or self.Active or not h or h.Health <= 0 or os.clock() < self.nextStart then return end
	self.pendingUntil = os.clock() + S.SlideInputBuffer
	self:Start(false)
end
function SlideController:Start(blocked)
	local h, r = self.humanoid, self.root
	if blocked or self.Active or not h or h.Health <= 0 or h.FloorMaterial == Enum.Material.Air or os.clock() < self.nextStart then return end
	local v = r.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if v.Magnitude < S.SlideMinSpeed or h.MoveDirection.Magnitude < 0.1 then return end
	self.pendingUntil = nil
	self.Active, self.started, self.direction = true, os.clock(), v.Unit
	self.character:SetAttribute("Sliding", true)
end
function SlideController:Cancel()
	self.pendingUntil = nil
	if self.Active then
		self.nextStart = os.clock() + S.SlideCooldown
		-- Restore held sprint before the next physics step, not the next render frame.
		if self.humanoid and self.humanoid.Parent then
			self.humanoid.WalkSpeed = self.GetExitSpeed and self.GetExitSpeed() or S.WalkSpeed
		end
		if self.root and self.root.Parent then
			local v = self.root.AssemblyLinearVelocity
			local flat = v * Vector3.new(1, 0, 1)
			if flat.Magnitude > S.SlideExitSpeed then self.root.AssemblyLinearVelocity = flat.Unit * S.SlideExitSpeed + Vector3.new(0, v.Y, 0) end
		end
	end
	self.Active = false
	if self.character then self.character:SetAttribute("Sliding", false) end
end
function SlideController:Step(dt)
	if self.pendingUntil then
		if os.clock() > self.pendingUntil then self.pendingUntil = nil
		else self:Start(false) end
	end
	if not self.Active then return end
	local h, r = self.humanoid, self.root
	local age = os.clock() - self.started
	if not r.Parent or h.Health <= 0 or h.Jump or h.FloorMaterial == Enum.Material.Air or age >= S.SlideDuration then self:Cancel() return end
	local flat = r.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if age > 0.12 and flat.Magnitude < S.SlideStopSpeed then self:Cancel() return end
	local desired = h.MoveDirection
	if desired.Magnitude > 0.1 then
		local steered = self.direction:Lerp(desired, math.min(dt * S.SlideSteering, 0.08))
		if steered.Magnitude > 0.1 then self.direction = steered.Unit end
	end
	local speed = S.SlideInitialSpeed + (S.SlideEndSpeed - S.SlideInitialSpeed) * math.clamp(age / S.SlideDuration, 0, 1)
	-- Sweep a body-sized box before applying bounded horizontal velocity; retain gravity.
	local hit = workspace:Blockcast(r.CFrame, Vector3.new(2, 2, 2), self.direction * (speed * dt + 1), self.params)
	if hit and hit.Instance.CanCollide then self:Cancel() return end
	h.WalkSpeed = speed
	h:Move(self.direction, false)
	r.AssemblyLinearVelocity = self.direction * speed + Vector3.new(0, math.min(r.AssemblyLinearVelocity.Y, 0), 0)
end
function SlideController:Present(dt)
	self.Blend += ((self.Active and 1 or 0) - self.Blend) * (1 - math.exp(-S.SlideResponse * dt))
	if self.humanoid and self.humanoid.Parent then self.humanoid.CameraOffset = Vector3.new(0, -S.SlideCameraDrop * self.Blend, 0) end
	return self.Blend
end
return SlideController
