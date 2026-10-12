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

local ZombieService = require(script.ZombieService)
local WeaponService = require(script.WeaponService)
local modes=require(ReplicatedStorage.Shared.GameModeConfig)
local mode=game:GetService("RunService"):IsStudio()and modes.StudioMode or modes.LiveMode
assert(mode=="EndlessSurvivalPrototype"or mode=="LegacyFloors","Unknown game mode: "..tostring(mode))
runState:SetAttribute("GameMode",mode)
local storage=game:GetService("ServerStorage")
local function preserve(instance,folderName)
	if not instance then return end
	local archive=storage:FindFirstChild(folderName)
	if not archive then archive=Instance.new("Folder");archive.Name=folderName;archive.Parent=storage end
	instance.Parent=archive -- Preserve user/preview geometry; never delete it.
end
local preview=workspace:FindFirstChild("CorporateComplex")
if preview and preview:GetAttribute("EndlessPrototypePreview")==true then preserve(preview,"EndlessPreviewArchive")end
local campusPreview=workspace:FindFirstChild("CampusComplex")
if campusPreview and campusPreview:GetAttribute("EndlessPrototypePreview")==true then preserve(campusPreview,"EndlessPreviewArchive")end
preserve(workspace:FindFirstChild("OfficeRun"),"LegacyMapArchive")
local spawn
if mode=="EndlessSurvivalPrototype"then
	local selected=modes.Prototype.Map or "Corporate"
	assert(selected=="Corporate"or selected=="Campus","Unknown prototype map: "..tostring(selected))
	local map=require(selected=="Campus"and script.CampusMap or script.CorporateMap).Build()
	runState:SetAttribute("ActiveMap",selected)
	local lighting=selected=="Campus"and modes.Prototype.CampusLighting or modes.Prototype.Lighting
	for key,value in lighting do game:GetService("Lighting")[key]=value end
	if selected=="Campus"then
		local atmosphere=game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
		if atmosphere then for key,value in modes.Prototype.CampusAtmosphere do atmosphere[key]=value end end
	end
	ZombieService.Start(map.Zones);WeaponService.Start()
	require(script.EndlessPrototype).Start(map)
	spawn=map.Spawn
else
	local map=require(script.OfficeMap).Build()
	ZombieService.Start(map.Current.Zones);WeaponService.Start()
	runState:SetAttribute("ActiveDirector","FloorDirector")
	require(script.FloorDirector).Start(map)
	spawn=map.Current.Spawn;spawn.Enabled=true
end
for _,player in Players:GetPlayers()do player.RespawnLocation=spawn end
Players.CharacterAutoLoads = true
for _,player in Players:GetPlayers()do
 if not player.Character then task.spawn(function()if player.Parent==Players and not player.Character then player:LoadCharacterAsync()end end)end
end
