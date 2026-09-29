local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)

local WeaponService = {}
local states = {}

local remotes = Instance.new("Folder")
remotes.Name = "CombatRemotes"
remotes.Parent = ReplicatedStorage
local fireRemote = Instance.new("RemoteEvent")
fireRemote.Name = "Fire"
fireRemote.Parent = remotes
local reloadRemote = Instance.new("RemoteEvent")
reloadRemote.Name = "Reload"
reloadRemote.Parent = remotes
local feedbackRemote = Instance.new("RemoteEvent")
feedbackRemote.Name = "Feedback"
feedbackRemote.Parent = remotes

local function sendAmmo(player)
	local state = states[player]
	if state then feedbackRemote:FireClient(player, "Ammo", state.ammo, state.reloading) end
end

local function validVector(value)
	return typeof(value) == "Vector3" and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 100000 and math.abs(value.Y) < 100000 and math.abs(value.Z) < 100000
end

local function fire(player, origin, direction)
	local state = states[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not state or not humanoid or humanoid.Health <= 0 or not head then return end
	if not validVector(origin) or not validVector(direction) then return end
	if (origin - head.Position).Magnitude > 4.5 then return end
	local magnitude = direction.Magnitude
	if magnitude < 0.98 or magnitude > 1.02 then return end
	if state.reloading then return end
	if state.ammo <= 0 then
		feedbackRemote:FireClient(player, "Empty")
		return
	end
	local now = os.clock()
	if now - state.lastShot < Config.Pistol.FireInterval then return end
	state.lastShot = now
	state.ammo -= 1
	sendAmmo(player)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.IgnoreWater = true
	local result = workspace:Raycast(origin, direction * Config.Pistol.Range, rayParams)
	local hitPosition = result and result.Position or origin + direction * Config.Pistol.Range
	local hitKind = "World"
	local hitInfo = result and { material = result.Material.Name, normal = result.Normal, direction = direction } or nil
	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local targetHumanoid = model and model:FindFirstChildOfClass("Humanoid")
		if model and model:GetAttribute("IsZombie") and targetHumanoid and targetHumanoid.Health > 0 then
			local headshot = result.Instance.Name == "Head"
			local damage = Config.Pistol.Damage * (headshot and Config.Pistol.HeadshotMultiplier or 1)
			if damage >= targetHumanoid.Health then model:SetAttribute("FatalHeadshot", headshot) end
			ZombieService.React(model, headshot, direction)
			targetHumanoid:TakeDamage(damage)
			hitKind = headshot and "Headshot" or "Body"
		end
	end
	feedbackRemote:FireClient(player, "Shot", hitKind, hitPosition, hitInfo)
end

local function reload(player)
	local state = states[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not humanoid or humanoid.Health <= 0 then return end
	if state.reloading or state.ammo >= Config.Pistol.MagazineSize then return end
	state.reloading = true
	sendAmmo(player)
	task.delay(Config.Pistol.ReloadDuration, function()
		if states[player] ~= state then return end
		state.reloading = false
		if humanoid.Health > 0 then state.ammo = Config.Pistol.MagazineSize end
		sendAmmo(player)
	end)
end

function WeaponService.Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			states[player] = { ammo = Config.Pistol.MagazineSize, reloading = false, lastShot = -math.huge }
			sendAmmo(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
	fireRemote.OnServerEvent:Connect(fire)
	reloadRemote.OnServerEvent:Connect(reload)
end

return WeaponService
