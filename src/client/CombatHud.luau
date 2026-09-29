local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local CombatHud = {}
CombatHud.__index = CombatHud

local function label(parent, size, position, textSize)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Size = size
	item.Position = position
	item.TextColor3 = Color3.fromRGB(238, 240, 231)
	item.TextStrokeTransparency = 0.55
	item.TextSize = textSize
	item.Font = Enum.Font.GothamMedium
	item.Parent = parent
	return item
end

function CombatHud.new(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatHud"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	local self = setmetatable({ Gui = gui, ammo = Config.Pistol.MagazineSize, reloading = false, spread = 0, hitSerial = 0 }, CombatHud)
	local damageOverlay = Instance.new("Frame")
	damageOverlay.Name = "DamageOverlay"
	damageOverlay.Size = UDim2.fromScale(1, 1)
	damageOverlay.BackgroundColor3 = Color3.fromRGB(150, 26, 22)
	damageOverlay.BackgroundTransparency = 1
	damageOverlay.BorderSizePixel = 0
	damageOverlay.ZIndex = 0
	damageOverlay.Parent = gui
	self.DamageOverlay = damageOverlay
	self.AmmoLabel = label(gui, UDim2.fromOffset(150, 42), UDim2.new(1, -180, 1, -82), 26)
	self.AmmoLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.ReloadLabel = label(gui, UDim2.fromOffset(150, 24), UDim2.new(1, -180, 1, -105), 13)
	self.ReloadLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.Crosshair = {}
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Name = "Crosshair" .. i
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.fromRGB(236, 239, 232)
		line.Parent = gui
		self.Crosshair[i] = line
	end
	self.HitLines = {}
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Name = "Hitmarker" .. i
		line.BorderSizePixel = 0
		line.BackgroundTransparency = 1
		line.Size = UDim2.fromOffset(8, 2)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Rotation = i % 2 == 0 and -45 or 45
		line.Parent = gui
		self.HitLines[i] = line
	end
	self:SetAmmo(self.ammo, false)
	return self
end

function CombatHud:SetAmmo(ammo, reloading)
	self.ammo, self.reloading = ammo, reloading
	self.AmmoLabel.Text = string.format("%02d / ∞", ammo)
	self.ReloadLabel.Text = reloading and "RELOADING" or ""
end

function CombatHud:Hit(headshot)
	self.hitSerial += 1
	local serial = self.hitSerial
	local color = headshot and Color3.fromRGB(255, 199, 92) or Color3.fromRGB(245, 245, 245)
	for _, line in ipairs(self.HitLines) do
		line.BackgroundColor3 = color
		line.BackgroundTransparency = 0
		line.Size = UDim2.fromOffset(headshot and 11 or 8, headshot and 3 or 2)
		TweenService:Create(line, TweenInfo.new(headshot and 0.3 or 0.2), { BackgroundTransparency = 1 }):Play()
	end
	task.delay(0.31, function()
		if self.hitSerial == serial then
			for _, line in ipairs(self.HitLines) do line.BackgroundTransparency = 1 end
		end
	end)
end

function CombatHud:Damage()
	if self.damageTween then self.damageTween:Cancel() end
	self.DamageOverlay.BackgroundTransparency = 0.82
	self.damageTween = TweenService:Create(self.DamageOverlay, TweenInfo.new(Config.Vfx.DamageFlashDuration), { BackgroundTransparency = 1 })
	self.damageTween:Play()
end

function CombatHud:Update(dt, moving, ads, kick)
	local goal = (moving and 3 or 0) + kick * 2
	self.spread += (goal - self.spread) * (1 - math.exp(-dt * 15))
	local gap = (5 + self.spread) * (1 - ads * 0.45)
	local alpha = 0.12 + ads * 0.78
	for _, line in ipairs(self.Crosshair) do line.BackgroundTransparency = alpha end
	self.Crosshair[1].Size = UDim2.fromOffset(2, 6)
	self.Crosshair[1].Position = UDim2.new(0.5, -1, 0.5, -gap - 6)
	self.Crosshair[2].Size = UDim2.fromOffset(2, 6)
	self.Crosshair[2].Position = UDim2.new(0.5, -1, 0.5, gap)
	self.Crosshair[3].Size = UDim2.fromOffset(6, 2)
	self.Crosshair[3].Position = UDim2.new(0.5, -gap - 6, 0.5, -1)
	self.Crosshair[4].Size = UDim2.fromOffset(6, 2)
	self.Crosshair[4].Position = UDim2.new(0.5, gap, 0.5, -1)
	local offsets = { Vector2.new(-8, -8), Vector2.new(8, -8), Vector2.new(-8, 8), Vector2.new(8, 8) }
	for i, line in ipairs(self.HitLines) do
		line.Position = UDim2.new(0.5, offsets[i].X, 0.5, offsets[i].Y)
	end
end

return CombatHud
