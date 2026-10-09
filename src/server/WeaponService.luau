local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ZombieService = require(script.Parent.ZombieService)
local SpawnSources = require(script.Parent.SpawnSources)
local Effects = require(script.Parent.BoonEffects)
local WeaponService = {}
local states, reloadSerial, rng = {}, 0, Random.new()
local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "CombatRemotes", ReplicatedStorage
local function remote(name)
	local event = Instance.new("RemoteEvent") event.Name, event.Parent = name, remotes return event
end
local fireRemote, reloadRemote = remote("Fire"), remote("Reload")
local feedbackRemote, selectRemote = remote("Feedback"), remote("SelectWeapon")
local function combatAllowed(player)
	local run = ReplicatedStorage:FindFirstChild("RunState")
	if not run or run:GetAttribute("OwnerUserId") ~= player.UserId then return false end
	local phase = run:GetAttribute("State")
	return phase == "FloorIntro" or phase == "EncounterActive" or phase == "PreparingFloor" or phase == "ElevatorAvailable" or phase == "NextFloor"
end
local function sendAmmo(player)
	local state = states[player]
	if state then
		local weapon=state.weaponId and Config.Weapons[state.weaponId]
		player:SetAttribute("MagazineCapacity",weapon and Effects.Magazine(player,weapon.MagazineSize)or 0)
		feedbackRemote:FireClient(player, "Ammo", state.ammo, state.reloading, state.weaponId)
	end
end
local function validVector(value)
	return typeof(value) == "Vector3" and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 100000 and math.abs(value.Y) < 100000 and math.abs(value.Z) < 100000
end
local function selectWeapon(player, weaponId)
	local state, run = states[player], ReplicatedStorage:FindFirstChild("RunState")
	local weapon = typeof(weaponId) == "string" and table.find(Config.Weapons.Order, weaponId) and Config.Weapons[weaponId]
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not state or state.weaponId or not weapon or not h or h.Health <= 0 or not run
		or player:GetAttribute("ResearchBusy")==true
		or player:GetAttribute("RunCharacterReady")~=true
		or run:GetAttribute("State") ~= "ChoosingWeapon" or run:GetAttribute("OwnerUserId") ~= player.UserId then return end
	if not ReplicatedStorage.Assets:FindFirstChild(weapon.Template) then feedbackRemote:FireClient(player, "SelectionRejected") return end
	state.weaponId, state.ammo = weaponId, weapon.MagazineSize
	player:SetAttribute("SelectedWeapon", weaponId)
	feedbackRemote:FireClient(player, "Equipped", weaponId, state.ammo, player.Character)
end
local function spreadDirection(direction, degrees)
	if degrees == 0 then return direction end
	local basis = CFrame.lookAt(Vector3.zero, direction)
	local angle, radius = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber()) * math.tan(math.rad(degrees))
	return (direction + basis.RightVector * math.cos(angle) * radius + basis.UpVector * math.sin(angle) * radius).Unit
end
local function fire(player, origin, direction, shotId)
	local state, character = states[player], player.Character
	local weapon = state and state.weaponId and Config.Weapons[state.weaponId]
	local h, head = character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("Head")
	if not weapon or not h or h.Health <= 0 or not head or player:GetAttribute("InElevatorTravel") or not combatAllowed(player) then return end
	if not validVector(origin) or not validVector(direction) or (origin - head.Position).Magnitude > 4.5 then return end
	if direction.Magnitude < 0.98 or direction.Magnitude > 1.02 then return end
	if state.reloading and weapon.ReloadMode ~= "Shell" then return end
	if state.ammo <= 0 then feedbackRemote:FireClient(player, "Empty") return end
	local now = os.clock()
	if now - state.lastShot < weapon.FireInterval - 0.005 then return end
	if state.reloading then state.reloading = false state.reloadToken = nil end
	state.lastShot, state.ammo = now, state.ammo - 1 sendAmmo(player)
	local context=Effects.OnShotAccepted(player)
	local params = RaycastParams.new() params.FilterDescendantsInstances = {character} params.IgnoreWater = true
	local targets, sources, impacts, endpoints = {}, {}, {}, {}
	local shotKind, shotPosition, shotInfo = "World", origin + direction * weapon.Range, nil
	for pellet = 1, weapon.Pellets do
		local rayDirection = spreadDirection(direction, weapon.SpreadDegrees)
		local result = workspace:Raycast(origin, rayDirection * weapon.Range, params)
		table.insert(endpoints, result and result.Position or origin + rayDirection * weapon.Range)
		if not result then continue end
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		local kind = "World"
		local source=SpawnSources.Target(result.Instance)
		if source then
			sources[source]=(sources[source]or 0)+weapon.Damage
			kind="World"
		end
		if target and target.Health > 0 and model:GetAttribute("IsZombie") then
			local headshot = result.Instance.Name == "Head"
			local falloff = weapon.FalloffStart and 1 - math.clamp((result.Distance - weapon.FalloffStart) / (weapon.Range - weapon.FalloffStart), 0, 1) * (1 - weapon.MinDamageMultiplier) or 1
			local entry = targets[model] or {humanoid=target, damage=0, headshot=false}
			entry.damage += weapon.Damage * (headshot and weapon.HeadshotMultiplier or 1) * falloff
			entry.headshot = entry.headshot or headshot targets[model] = entry
			kind = headshot and "Headshot" or "Body"
		end
		local info = {material=result.Material.Name, normal=result.Normal, direction=rayDirection}
		table.insert(impacts, {kind=kind, position=result.Position, info=info})
		if pellet == 1 or kind == "Headshot" or (kind == "Body" and shotKind == "World") then shotKind, shotPosition, shotInfo = kind, result.Position, info end
	end
	for model, entry in pairs(targets) do
		-- A previous target's secondary arc can kill another pellet target first.
		local before=entry.humanoid.Health
		if before<=0 then continue end
		entry.damage=Effects.DirectDamage(player,model,entry.damage,context)
		if entry.damage >= entry.humanoid.Health then model:SetAttribute("FatalHeadshot", entry.headshot) end
		ZombieService.React(model, entry.headshot, direction)
		entry.humanoid:TakeDamage(entry.damage)
		if before>0 and entry.humanoid.Health<=0 then Effects.OnKill(player)end
		Effects.AfterDirectHit(player,model,entry.headshot,direction,context)
	end
	for model,damage in sources do
		feedbackRemote:FireClient(player,"SourceHit",SpawnSources.Damage(model,player,damage))
	end
	feedbackRemote:FireClient(player, "Shot", shotKind, shotPosition, shotInfo)
	if weapon.Pellets > 1 then
		local serial = typeof(shotId)=="number" and shotId>0 and shotId<1e12 and shotId%1==0 and shotId or nil
		feedbackRemote:FireClient(player, "PelletImpacts", impacts, endpoints, serial, state.weaponId)
	end
end
local function reload(player)
	local state = states[player]
	local weapon = state and state.weaponId and Config.Weapons[state.weaponId]
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	if not weapon or not h or h.Health <= 0 or player:GetAttribute("InElevatorTravel") or not combatAllowed(player) then return end
	local capacity=Effects.Magazine(player,weapon.MagazineSize)
	if state.reloading or state.ammo >= capacity then return end
	state.reloading = true
	local token = {} state.reloadToken = token
	if weapon.ReloadMode == "Shell" then
		task.spawn(function()
			while states[player] == state and state.reloadToken == token and state.ammo < capacity do
				if h.Health <= 0 or player.Character ~= character or player:GetAttribute("InElevatorTravel") then break end
				reloadSerial += 1
				feedbackRemote:FireClient(player, "ReloadStarted", weapon.ShellInsertDuration, reloadSerial, character, state.weaponId)
				sendAmmo(player)
				task.wait(weapon.ShellInsertDuration)
				if states[player] ~= state or state.reloadToken ~= token then return end
				if h.Health <= 0 or player.Character ~= character or player:GetAttribute("InElevatorTravel") then break end
				state.ammo += 1
				Effects.OnReloadComplete(player)
				sendAmmo(player)
			end
			if states[player] == state and state.reloadToken == token then
				state.reloadToken = nil state.reloading = false sendAmmo(player)
			end
		end)
		return
	end
	reloadSerial += 1
	feedbackRemote:FireClient(player, "ReloadStarted", weapon.ReloadDuration, reloadSerial, character, state.weaponId)
	sendAmmo(player)
	task.delay(weapon.ReloadDuration, function()
		if states[player] ~= state or state.reloadToken ~= token then return end
		state.reloading = false state.reloadToken = nil
		if h.Health > 0 and player.Character == character and not player:GetAttribute("InElevatorTravel") and combatAllowed(player) then
			state.ammo = capacity;Effects.OnReloadComplete(player)
		end
		sendAmmo(player)
	end)
end
function WeaponService.CancelActions(player)
	local state = states[player]
	if not state then return end
	state.reloadToken, state.reloading = nil, false
	sendAmmo(player)
end
function WeaponService.RefreshStats(player)sendAmmo(player)end
function WeaponService.Refill(player)
	local state=states[player];local weapon=state and state.weaponId and Config.Weapons[state.weaponId]
	if not weapon then return end
	WeaponService.CancelActions(player);state.ammo=Effects.Magazine(player,weapon.MagazineSize);sendAmmo(player)
end
function WeaponService.ResetPlayer(player)
	WeaponService.CancelActions(player)
	states[player] = {ammo=0, reloading=false, lastShot=-math.huge}
	player:SetAttribute("SelectedWeapon", nil)
	sendAmmo(player)
end
function WeaponService.Start()
	local function prepare(player)
		local function reset()
			WeaponService.ResetPlayer(player)
		end
		player.CharacterAdded:Connect(reset)
		if player.Character then reset() end
	end
	Players.PlayerAdded:Connect(prepare)
	for _, player in ipairs(Players:GetPlayers()) do prepare(player) end
	Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
	selectRemote.OnServerEvent:Connect(selectWeapon)
	fireRemote.OnServerEvent:Connect(fire)
	reloadRemote.OnServerEvent:Connect(reload)
end
return WeaponService
