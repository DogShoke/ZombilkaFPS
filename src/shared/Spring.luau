-- Critically damped spring with an exact, time-based update. Works with numbers and Vector3s.
local Spring = {}
Spring.__index = Spring

function Spring.new(initial, frequency)
	return setmetatable({ Position = initial, Velocity = initial * 0, Target = initial, Frequency = frequency }, Spring)
end

function Spring:Impulse(velocity)
	self.Velocity += velocity
end

function Spring:Step(dt)
	dt = math.clamp(dt, 0, 0.1)
	local omega = 2 * math.pi * self.Frequency
	local displacement = self.Position - self.Target
	local decay = math.exp(-omega * dt)
	self.Position = self.Target + (displacement * (1 + omega * dt) + self.Velocity * dt) * decay
	self.Velocity = (self.Velocity * (1 - omega * dt) - displacement * (omega * omega * dt)) * decay
	return self.Position
end

return Spring
