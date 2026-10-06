-- One simulation clock: horde pressure, shield phases and zombie attacks advance together.
local Clock = { Time = 0, Paused = false }
function Clock.Now() return Clock.Time end
function Clock.Step(dt) if not Clock.Paused then Clock.Time += dt end end
return Clock
