local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Config = require(script.Parent.Config)

local Audio = {}
local rng = Random.new()

function Audio.Play(key, parent)
	local entry = Config.Audio[key]
	if not entry or not entry.Id or entry.Id == "" then return nil end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = entry.Id
	sound.Volume = entry.Volume or 0.5
	sound.PlaybackSpeed = rng:NextNumber(entry.PitchMin or 1, entry.PitchMax or entry.PitchMin or 1)
	if entry.MaxDistance then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMaxDistance = entry.MaxDistance
	end
	sound.Parent = parent or SoundService
	if entry.StartTime then sound.TimePosition = entry.StartTime end
	sound:Play()
	Debris:AddItem(sound, entry.Duration or 8)
	return sound
end

return Audio
