local Players = game:GetService("Players")
require(script.ArenaEffects).Start()
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
local WeaponSelection = require(script.WeaponSelection)
local RunResults = require(script.RunResults)
local RewardSelection = require(script.RewardSelection)
local ShopSelection = require(script.ShopSelection)
local GuiService = game:GetService("GuiService")
local remotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local fireRemote = remotes:WaitForChild("Fire")
local reloadRemote = remotes:WaitForChild("Reload")
local feedbackRemote = remotes:WaitForChild("Feedback")
local selectRemote = remotes:WaitForChild("SelectWeapon")

local player = Players.LocalPlayer
local hud = CombatHud.new(player:WaitForChild("PlayerGui"))
local selection = WeaponSelection.new(selectRemote)
local weaponId, weapon, triggerHeld
local cameraKick = Spring.new(Vector3.zero, Config.Feel.CameraRecoilFrequency)
local rng = Random.new()
local character, humanoid, root, viewmodel, stateConnection, descendantConnection, healthConnection
local wantsSprint, wantsAds = false, false
local ammo, reloading = 0, false
local lastLocalShot = -math.huge
local shotSerial, pendingPelletMuzzles = 0, {}
local localShotKick = 0
local slide = SlideController.new()
local jump = JumpController.new()
ZombieVisuals.Start()
local runState = ReplicatedStorage:WaitForChild("RunState")
local runRemotes=ReplicatedStorage:WaitForChild("RunRemotes",60)
assert(runRemotes,"Run remotes did not initialize")
local results = RunResults.new(runState,runRemotes:WaitForChild("StartRun"))
local rewardSelection=RewardSelection.new(runState,runRemotes:WaitForChild("ClaimBoon"),runRemotes:WaitForChild("RerollBoon"))
local shopSelection=ShopSelection.new(runState,runRemotes:WaitForChild("BuyShopItem"),runRemotes:WaitForChild("CloseShop"))
local function refreshSelection()
	selection:Show(runState:GetAttribute("State")=="ChoosingWeapon"and not weapon)
	hud.Gui.Enabled=weapon~=nil and not results.Active and not rewardSelection.Active and not shopSelection.Active
end
runState:GetAttributeChangedSignal("State"):Connect(refreshSelection)
refreshSelection()
hud:SetRun(runState)
runState.AttributeChanged:Connect(function() hud:SetRun(runState) end)
local lastReloadSerial = 0
local function blocked()
	return not weapon or selection.Active or results.Active or rewardSelection.Active or shopSelection.Active or GuiService.MenuIsOpen or player:GetAttribute("InElevatorTravel") == true or player:GetAttribute("InSafeInterlude")==true
end
local function equip(id)
	if id==weaponId and viewmodel then return end
	if viewmodel then viewmodel:Destroy() viewmodel=nil end
	weaponId, weapon, triggerHeld = id, id and Config.Weapons[id], false
	reloading=false lastLocalShot=-math.huge pendingPelletMuzzles={}
	refreshSelection()
	if weapon and character and humanoid and humanoid.Health>0 then
		ammo=weapon.MagazineSize hud:SetAmmo(ammo,false)
		viewmodel=ViewmodelController.new(workspace.CurrentCamera,id)
	end
end
player:GetAttributeChangedSignal("SelectedWeapon"):Connect(function() equip(player:GetAttribute("SelectedWeapon")) end)
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
	ammo, reloading = 0, false
	hud:SetAmmo(ammo, reloading)
	hud:SetHealth(newHumanoid.Health, newHumanoid.MaxHealth)
	cameraKick.Position, cameraKick.Velocity, cameraKick.Target = Vector3.zero, Vector3.zero, Vector3.zero
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseDeltaSensitivity = Config.Camera.MouseSensitivity
	slide:Bind(newCharacter)
	jump:Bind(newCharacter)
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	equip(nil)
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
	if blocked() or not humanoid or humanoid.Health <= 0 or not viewmodel then return end
	if reloading and (weapon.ReloadMode ~= "Shell" or ammo <= 0) then return end
	if ammo <= 0 then
		playSound("EmptyClick")
		reloadRemote:FireServer()
		return
	end
	local now = os.clock()
	if now - lastLocalShot < weapon.FireInterval then return end
	if reloading then reloading=false viewmodel:CancelReload() end
	lastLocalShot = now
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, viewmodel.Model }
	local result = workspace:Raycast(origin, direction * weapon.Range, params)
	local predictedEnd = result and result.Position or origin + direction * weapon.Range
	local sprinting = wantsSprint and humanoid.MoveDirection.Magnitude > 0.1 and not wantsAds
	shotSerial += 1
	local serial = shotSerial
	if weapon.Pellets > 1 then
		pendingPelletMuzzles[serial] = viewmodel:GetMuzzleCFrame().Position
		task.delay(2, function() pendingPelletMuzzles[serial] = nil end)
	else viewmodel:Tracer(predictedEnd) end
	viewmodel:Fire(viewmodel.ads, sprinting)
	local recoilMult = (1 - viewmodel.ads * (1 - Config.Feel.AdsRecoilMultiplier)) * weapon.RecoilMultiplier
	local yaw = rng:NextNumber(-Config.Feel.CameraYaw, Config.Feel.CameraYaw)
	local recovery = Config.Feel.CameraRecoilRecoveryFraction
	camera.CFrame *= CFrame.Angles(Config.Feel.CameraKick * (1 - recovery) * recoilMult, yaw * (1 - recovery) * recoilMult, 0)
	cameraKick:Impulse(Vector3.new(Config.Feel.CameraKick, yaw, 0) * recoilMult * recovery * 12)
	localShotKick = 1
	ammo -= 1
	hud:SetAmmo(ammo, false)
	playSound("Gunshot")
	playSound("MechanicalShot")
	fireRemote:FireServer(origin, direction, serial)
end

local function requestReload()
	if blocked() or not humanoid or humanoid.Health <= 0 or reloading or ammo >= (player:GetAttribute("MagazineCapacity")or weapon.MagazineSize) then return end

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
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then triggerHeld=true shoot() end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then wantsAds = false end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then triggerHeld = false end
end)

RunService.Heartbeat:Connect(function()
	if blocked() or UserInputService:GetFocusedTextBox() then triggerHeld=false return end
	if triggerHeld and weapon.Automatic then shoot() end
end)

feedbackRemote.OnClientEvent:Connect(function(kind, a, b, c, d)
	if kind=="BoonArc"then
		for i=2,math.min(#a,3)do
			local from,to=a[1],a[i];local bolt=Instance.new("Part")
			bolt.Name="BoonArc";bolt.Anchored=true;bolt.CanCollide=false;bolt.CanQuery=false;bolt.CanTouch=false
			bolt.Material=Enum.Material.Neon;bolt.Color=Color3.fromRGB(100,192,255)
			bolt.Size=Vector3.new(.09,.09,(to-from).Magnitude);bolt.CFrame=CFrame.lookAt((from+to)/2,to)
			bolt.Parent=workspace;game:GetService("Debris"):AddItem(bolt,.12)
		end
		return
	end
	if kind=="SourceHit"then hud:SourceHit(a);return end
	if kind == "Equipped" then
		if c~=character then return end
		equip(a) ammo=b hud:SetAmmo(ammo,false)
	elseif kind == "SelectionRejected" then selection:Show(true)
	elseif kind == "ReloadStarted" then
		if c ~= character or d~=weaponId or b <= lastReloadSerial then return end
		lastReloadSerial = b
		reloading = true
		hud:SetAmmo(ammo, true)
		if viewmodel then viewmodel:Reload(a) end
		playSound("Reload")
	elseif kind == "Ammo" then
		if c~=weaponId then return end
		if reloading and not b and viewmodel then viewmodel:CancelReload() end
		ammo, reloading = a, b
		hud:SetAmmo(ammo, reloading)
	elseif kind == "Shot" then
		if a == "Body" or a == "Headshot" then
			hud:Hit(a == "Headshot")
			playSound(a == "Headshot" and "Headshot" or "BodyHit")
		elseif a == "World" and c then
			playSound(impactSound(c.material))
		end
		if viewmodel and weapon.Pellets==1 and b and (a ~= "World" or (b - workspace.CurrentCamera.CFrame.Position).Magnitude < weapon.Range - 1) then
			viewmodel:Impact(b, a, c)
		end
	elseif kind == "PelletImpacts" and viewmodel then
		if d~=weaponId then return end
		local muzzle = pendingPelletMuzzles[c] or viewmodel:GetMuzzleCFrame().Position
		if c then pendingPelletMuzzles[c] = nil end
		for _,endpoint in ipairs(b) do viewmodel:Tracer(endpoint,muzzle) end
		for _,hit in ipairs(a) do viewmodel:Impact(hit.position,hit.kind,hit.info) end
	elseif kind == "Empty" then
		playSound("EmptyClick")
	end
end)

-- Apply after camera/default controls, even while the character/viewmodel is being rebuilt.
RunService:BindToRenderStep("ZombilkaFPSCursor", Enum.RenderPriority.Last.Value + 1, function()
	local menuOpen = GuiService.MenuIsOpen or selection.Active or results.Active or rewardSelection.Active or shopSelection.Active
	UserInputService.MouseBehavior = menuOpen and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = menuOpen
end)

RunService:BindToRenderStep("ZombilkaFPSPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	local slideBlend = slide:Present(dt)
	if not camera or not humanoid or not root then return end
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
	if not viewmodel then return end
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
