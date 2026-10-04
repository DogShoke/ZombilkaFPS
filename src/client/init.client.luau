local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Audio = require(ReplicatedStorage.Shared.Audio)
local Spring = require(ReplicatedStorage.Shared.Spring)
local ViewmodelController = require(script.ViewmodelController)
local CombatHud = require(script.CombatHud)
local SlideController = require(script.SlideController)
local JumpController = require(script.JumpController)
local ZombieVisuals = require(script.ZombieVisuals)
local GuiService = game:GetService("GuiService")
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
local slide = SlideController.new()
local jump = JumpController.new()
ZombieVisuals.Start()
local runState = ReplicatedStorage:WaitForChild("RunState")
hud:SetRun(runState)
runState.AttributeChanged:Connect(function() hud:SetRun(runState) end)
local lastReloadSerial = 0
local function blocked()
	return GuiService.MenuIsOpen or player:GetAttribute("InElevatorTravel") == true
end
slide.GetExitSpeed = function()
	if blocked() or UserInputService:GetFocusedTextBox() or not humanoid or humanoid.Health <= 0 then return 0 end
	local heldSprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	return heldSprint and not wantsAds and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed
end

local function playSound(key) Audio.Play(key) end

local function impactSound(material)
	if material == "Metal" or material == "DiamondPlate" or material == "CorrodedMetal" then return "WorldMetal" end
	if material == "Wood" or material == "WoodPlanks" then return "WorldWood" end
	if material == "Concrete" or material == "Brick" or material == "Rock" or material == "Slate" then return "WorldConcrete" end
	return "WorldGeneric"
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
	hud:SetHealth(newHumanoid.Health, newHumanoid.MaxHealth)
	cameraKick.Position, cameraKick.Velocity, cameraKick.Target = Vector3.zero, Vector3.zero, Vector3.zero
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseDeltaSensitivity = Config.Camera.MouseSensitivity
	slide:Bind(newCharacter)
	jump:Bind(newCharacter)
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
		if currentHealth < previousHealth then
			hud:Damage()
			cameraKick:Impulse(Vector3.new(math.rad(0.38), rng:NextNumber(-0.035, 0.035), rng:NextNumber(-0.025, 0.025)))
			playSound("PlayerHurt")
		end
		hud:SetHealth(currentHealth, humanoid.MaxHealth)
		previousHealth = currentHealth
	end)
end

local function shoot()
	if blocked() or not humanoid or humanoid.Health <= 0 or not viewmodel or reloading then return end
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
	if blocked() or not humanoid or humanoid.Health <= 0 or reloading or ammo >= Config.Pistol.MagazineSize then return end

	reloadRemote:FireServer()
end

local slideKeys = { Enum.KeyCode.C, Enum.KeyCode.LeftControl }
local heldSlideKeys = {}
local function requestSlide()
	if not UserInputService:GetFocusedTextBox() and not blocked() then slide:Request(wantsAds) end
end

-- Consume the action and also poll key state: processed input can skip action events.
ContextActionService:BindActionAtPriority("ZombilkaSlide", function(_, state)
	if UserInputService:GetFocusedTextBox() or blocked() then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then requestSlide() end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 10, table.unpack(slideKeys))

RunService.PreSimulation:Connect(function()
	for _, key in ipairs(slideKeys) do
		local down = UserInputService:IsKeyDown(key)
		if down and not heldSlideKeys[key] then requestSlide() end
		heldSlideKeys[key] = down
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if table.find(slideKeys, input.KeyCode) then requestSlide() end
	if processed or blocked() or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.R then requestReload()
	elseif input.KeyCode == Enum.KeyCode.Space then slide:Cancel()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then slide:Cancel() wantsAds = true
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then shoot() end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then wantsAds = false end
end)

feedbackRemote.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "ReloadStarted" then
		if c ~= character or b <= lastReloadSerial then return end
		lastReloadSerial = b
		reloading = true
		hud:SetAmmo(ammo, true)
		if viewmodel then viewmodel:Reload(a) end
		playSound("Reload")
	elseif kind == "Ammo" then
		ammo, reloading = a, b
		hud:SetAmmo(ammo, reloading)
	elseif kind == "Shot" then
		if a == "Body" or a == "Headshot" then
			hud:Hit(a == "Headshot")
			playSound(a == "Headshot" and "Headshot" or "BodyHit")
		elseif a == "World" and c then
			playSound(impactSound(c.material))
		end
		if viewmodel and b and (a ~= "World" or (b - workspace.CurrentCamera.CFrame.Position).Magnitude < Config.Pistol.Range - 1) then
			viewmodel:Impact(b, a, c)
		end
	elseif kind == "Empty" then
		playSound("EmptyClick")
	end
end)

-- Apply after camera/default controls, even while the character/viewmodel is being rebuilt.
RunService:BindToRenderStep("ZombilkaFPSCursor", Enum.RenderPriority.Last.Value + 1, function()
	local menuOpen = GuiService.MenuIsOpen
	UserInputService.MouseBehavior = menuOpen and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = menuOpen
end)

RunService:BindToRenderStep("ZombilkaFPSPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	local slideBlend = slide:Present(dt)
	if not camera or not humanoid or not root or not viewmodel then return end
	local inputBlocked = blocked() or UserInputService:GetFocusedTextBox() ~= nil or humanoid.Health <= 0
	-- Read held keys every frame so slide completion never loses sprint intent.
	wantsSprint = not inputBlocked and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
	if inputBlocked then wantsSprint, wantsAds = false, false slide:Cancel() end
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local sprinting = wantsSprint and moving and not wantsAds
	sprinting = sprinting and not slide.Active and not inputBlocked
	local ads = wantsAds and not inputBlocked
	if not slide.Active then humanoid.WalkSpeed = inputBlocked and 0 or sprinting and jump:GetSprintSpeed() or Config.Movement.WalkSpeed end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not inputBlocked)
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local strafe = humanoid.MoveDirection:Dot(camera.CFrame.RightVector)
	local kick = cameraKick:Step(dt)
	camera.CFrame *= CFrame.Angles(kick.X, kick.Y, kick.Z)
	if player:GetAttribute("InElevatorTravel") then
		camera.CFrame *= CFrame.new(0, math.sin(os.clock() * Config.Camera.ElevatorShakeFrequency) * Config.Camera.ElevatorShake, 0)
	end
	local adsBlend = viewmodel:Update(dt, camera, UserInputService:GetMouseDelta(), horizontalSpeed, strafe, ads, sprinting, slideBlend)
	local targetFov = sprinting and Config.Camera.SprintFov or Config.Camera.HipFov
	targetFov += (Config.Movement.SlideFov - targetFov) * slideBlend
	targetFov += (Config.Camera.AdsFov - targetFov) * adsBlend
	camera.FieldOfView += (targetFov - camera.FieldOfView) * (1 - math.exp(-Config.Camera.FovResponse * dt))
	localShotKick = math.max(0, localShotKick - dt * 4)
	hud:Update(dt, moving, adsBlend, localShotKick)
	for _, line in ipairs(hud.Crosshair) do line.Visible = not inputBlocked end
end)

player.CharacterAdded:Connect(setCharacter)
if player.Character then setCharacter(player.Character) end
