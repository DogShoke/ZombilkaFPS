local Players = game:GetService("Players")
-- The avatar body is hidden; avoid loading catalog faces/moods into the FPS camera rig.
local Config = require(game.ReplicatedStorage.Shared.Config)
local function configureMovement(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.Movement.JumpPower
end
local function prepareAvatar(player)
	player.CanLoadCharacterAppearance = false
	player.CharacterAdded:Connect(configureMovement)
	if player.Character then task.spawn(configureMovement, player.Character) end
end
Players.PlayerAdded:Connect(prepareAvatar)
for _, player in ipairs(Players:GetPlayers()) do prepareAvatar(player) end

local OfficeMap = require(script.OfficeMap)
local ZombieService = require(script.ZombieService)
local WeaponService = require(script.WeaponService)
local FloorDirector = require(script.FloorDirector)
local map = OfficeMap.Build()
ZombieService.Start(map.Current.Zones)
WeaponService.Start()
FloorDirector.Start(map)
