-- Continuous pressure targets; the elevator director owns transitions.
local Config=require(game.ReplicatedStorage.Shared.Config)
local H=Config.Run.Horde
local Horde={}
function Horde.Target(number,elapsed)
 local pressure=math.floor(elapsed/H.PressureEvery)
 return {
  DesiredAlive=math.min(H.MaxDesired,math.floor(H.BaseDesired+(number-1)*H.DesiredPerFloor)+pressure*H.PressureStep),
  AliveCap=H.AliveCap,
  SpawnRate=math.min(H.MaxSpawnRate,H.BaseSpawnRate+(number-1)*H.SpawnRatePerFloor+pressure*H.SpawnRatePerPressure),
  Pressure=pressure,
 }
end
return Horde
