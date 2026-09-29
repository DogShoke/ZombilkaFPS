local Arena = require(script.Arena)
local ZombieService = require(script.ZombieService)
local WeaponService = require(script.WeaponService)

local spawnZones = Arena.Build()
ZombieService.Start(spawnZones)
WeaponService.Start()
