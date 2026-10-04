local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local JumpController = {}
JumpController.__index = JumpController

function JumpController.new()
	local self = setmetatable({}, JumpController)
	RunService.PreSimulation:Connect(function() self:Step() end)
	return self
end

function JumpController:Bind(character)
	if self.stateConnection then self.stateConnection:Disconnect() end
	if self.force then self.force:Destroy() end
	if self.attachment then self.attachment:Destroy() end
	self.humanoid = character:WaitForChild("Humanoid")
	self.root = character:WaitForChild("HumanoidRootPart")
	self.jumping = false
	local attachment = Instance.new("Attachment")
	attachment.Name = "JumpGravityAttachment"
	attachment.Parent = self.root
	local force = Instance.new("VectorForce")
	force.Name = "JumpGravity"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Force = Vector3.zero
	force.Parent = self.root
	self.attachment, self.force = attachment, force
	self.stateConnection = self.humanoid.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Jumping then self.jumping = true
		elseif state ~= Enum.HumanoidStateType.Freefall then
			self.jumping = false
			force.Force = Vector3.zero
		end
	end)
end

function JumpController:Step()
	local h, r, force = self.humanoid, self.root, self.force
	if not force or not force.Parent then return end
	local state = h:GetState()
	if not self.jumping or h.Health <= 0 or r.Anchored
		or (state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall) then
		force.Force = Vector3.zero
		return
	end
	-- Tune ascent and descent per character without changing global gravity.
	local multiplier = r.AssemblyLinearVelocity.Y > 0 and Config.Movement.JumpRiseGravity or Config.Movement.JumpFallGravity
	force.Force = Vector3.new(0, -r.AssemblyMass * workspace.Gravity * (multiplier - 1), 0)
end

function JumpController:GetSprintSpeed()
	return self.jumping and Config.Movement.SprintJumpSpeed or Config.Movement.SprintSpeed
end

return JumpController
