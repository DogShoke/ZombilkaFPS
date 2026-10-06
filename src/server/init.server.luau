local Players = game:GetService("Players")
-- Navigation validation can take several seconds. Spawn only after a safe floor exists.
Players.CharacterAutoLoads = false
-- Publish the state container before navigation validation delays client startup.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runState = Instance.new("Folder"); runState.Name = "RunState"; runState.Parent = ReplicatedStorage
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
map.Current.Spawn.Enabled = true
for _,player in Players:GetPlayers()do player.RespawnLocation=map.Current.Spawn end
Players.CharacterAutoLoads = true
for _,player in Players:GetPlayers()do
 if not player.Character then task.spawn(function()if player.Parent==Players and not player.Character then player:LoadCharacterAsync()end end)end
end
