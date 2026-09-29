local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Spring = require(ReplicatedStorage.Shared.Spring)
local ViewmodelController = require(script.ViewmodelController)
local CombatHud = require(script.CombatHud)
local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local fireRemote = remotes:WaitForChild("Fire")
local reloadRemote = remotes:WaitForChild("Reload")
local feedbackRemote = remotes:WaitForChild("Feedback")

local player = Players.LocalPlayer
local hud = CombatHud.new(player:WaitForChild("PlayerGui"))
local cameraKick = Spring.new(Vector3.zero, Config.Feel.CameraRecoilFrequency)
local rng = Random.new()
local character, humanoid, root, viewmodel, stateConnection, descendantConnection, healthConnection
local wantsSprint, wantsAds = false, false
local ammo, reloading = Config.Pistol.MagazineSize, false
local lastLocalShot = -math.huge
local localShotKick = 0

local function playSound(key, parent)
	local id = Config.Audio[key]
	if not id or id == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.8
	sound.Parent = parent or SoundService
	sound:Play()
	sound.Ended:Once(function() sound:Destroy() end)
	Debris:AddItem(sound, 8)
end

local function setCharacter(newCharacter)
	if stateConnection then stateConnection:Disconnect() end
	if descendantConnection then descendantConnection:Disconnect() end
	if healthConnection then healthConnection:Disconnect() end
	local oldViewmodel = viewmodel
	viewmodel, character, humanoid, root = nil, nil, nil, nil
	if oldViewmodel then oldViewmodel:Destroy() end
	local newHumanoid = newCharacter:WaitForChild("Humanoid")
	local newRoot = newCharacter:WaitForChild("HumanoidRootPart")
	character, humanoid, root = newCharacter, newHumanoid, newRoot
	wantsSprint, wantsAds = false, false
	ammo, reloading = Config.Pistol.MagazineSize, false
	hud:SetAmmo(ammo, reloading)
	cameraKick.Position, cameraKick.Velocity, cameraKick.Target = Vector3.zero, Vector3.zero, Vector3.zero
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseDeltaSensitivity = Config.Camera.MouseSensitivity
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	viewmodel = ViewmodelController.new(workspace.CurrentCamera)
	local function hide(part)
		if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
	end
	for _, part in ipairs(newCharacter:GetDescendants()) do hide(part) end
	descendantConnection = newCharacter.DescendantAdded:Connect(hide)
	stateConnection = humanoid.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Landed and viewmodel then viewmodel:LandImpulse() end
	end)
	local previousHealth = humanoid.Health
	healthConnection = humanoid.HealthChanged:Connect(function(currentHealth)
		if currentHealth < previousHealth then hud:Damage() end
		previousHealth = currentHealth
	end)
end

local function shoot()
	if not humanoid or humanoid.Health <= 0 or not viewmodel or reloading then return end
	if ammo <= 0 then
		playSound("EmptyClick")
		reloadRemote:FireServer()
		return
	end
	local now = os.clock()
	if now - lastLocalShot < Config.Pistol.FireInterval then return end
	lastLocalShot = now
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, viewmodel.Model }
	local result = workspace:Raycast(origin, direction * Config.Pistol.Range, params)
	local predictedEnd = result and result.Position or origin + direction * Config.Pistol.Range
	local sprinting = wantsSprint and humanoid.MoveDirection.Magnitude > 0.1 and not wantsAds
	viewmodel:Fire(viewmodel.ads, sprinting)
	viewmodel:Tracer(predictedEnd)
	local recoilMult = 1 - viewmodel.ads * (1 - Config.Feel.AdsRecoilMultiplier)
	local yaw = rng:NextNumber(-Config.Feel.CameraYaw, Config.Feel.CameraYaw)
	local recovery = Config.Feel.CameraRecoilRecoveryFraction
	camera.CFrame *= CFrame.Angles(Config.Feel.CameraKick * (1 - recovery) * recoilMult, yaw * (1 - recovery) * recoilMult, 0)
	cameraKick:Impulse(Vector3.new(Config.Feel.CameraKick, yaw, 0) * recoilMult * recovery * 12)
	localShotKick = 1
	ammo -= 1
	hud:SetAmmo(ammo, false)
	playSound("Gunshot")
	playSound("MechanicalShot")
	fireRemote:FireServer(origin, direction)
end

local function requestReload()
	if not humanoid or humanoid.Health <= 0 or reloading or ammo >= Config.Pistol.MagazineSize then return end
	reloading = true
	hud:SetAmmo(ammo, true)
	if viewmodel then viewmodel:Reload() end
	playSound("Reload")
	reloadRemote:FireServer()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then wantsSprint = true
	elseif input.KeyCode == Enum.KeyCode.R then requestReload()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then wantsAds = true
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then shoot() end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then wantsSprint = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then wantsAds = false end
end)

feedbackRemote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Ammo" then
		ammo, reloading = a, b
		hud:SetAmmo(ammo, reloading)
	elseif kind == "Shot" then
		if a == "Body" or a == "Headshot" then
			hud:Hit(a == "Headshot")
			playSound(a == "Headshot" and "Headshot" or "BodyHit")
		end
		if viewmodel and b and (a ~= "World" or (b - workspace.CurrentCamera.CFrame.Position).Magnitude < Config.Pistol.Range - 1) then
			viewmodel:Impact(b, a)
		end
	elseif kind == "Empty" then
		playSound("EmptyClick")
	end
end)

RunService:BindToRenderStep("ZombilkaFPSPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	if not camera or not humanoid or not root or humanoid.Health <= 0 or not viewmodel then return end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local sprinting = wantsSprint and moving and humanoid.FloorMaterial ~= Enum.Material.Air and not wantsAds
	local ads = wantsAds
	humanoid.WalkSpeed = sprinting and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local strafe = humanoid.MoveDirection:Dot(camera.CFrame.RightVector)
	local kick = cameraKick:Step(dt)
	camera.CFrame *= CFrame.Angles(kick.X, kick.Y, kick.Z)
	local adsBlend = viewmodel:Update(dt, camera, UserInputService:GetMouseDelta(), horizontalSpeed, strafe, ads, sprinting)
	local targetFov = sprinting and Config.Camera.SprintFov or Config.Camera.HipFov
	targetFov += (Config.Camera.AdsFov - targetFov) * adsBlend
	camera.FieldOfView += (targetFov - camera.FieldOfView) * (1 - math.exp(-Config.Camera.FovResponse * dt))
	localShotKick = math.max(0, localShotKick - dt * 4)
	hud:Update(dt, moving, adsBlend, localShotKick)
end)

player.CharacterAdded:Connect(setCharacter)
if player.Character then setCharacter(player.Character) end
