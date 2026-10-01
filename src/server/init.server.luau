local Players = game:GetService("Players")
-- The avatar body is hidden; avoid loading catalog faces/moods into the FPS camera rig.
local function prepareAvatar(player) player.CanLoadCharacterAppearance = false end
Players.PlayerAdded:Connect(prepareAvatar)
for _, player in ipairs(Players:GetPlayers()) do prepareAvatar(player) end

local OfficeMap = require(script.OfficeMap)
local ZombieService = require(script.ZombieService)
local WeaponService = require(script.WeaponService)
local FloorDirector = require(script.FloorDirector)
local floors = OfficeMap.Build()
ZombieService.Start(floors[1].Zones)
WeaponService.Start()
FloorDirector.Start(floors)
