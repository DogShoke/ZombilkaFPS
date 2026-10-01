local UIS = game:GetService("UserInputService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local SettingsController = {}
SettingsController.__index = SettingsController
function SettingsController.new(player, onToggle)
	local self = setmetatable({ Open = false, Value = Config.Settings.Default, onToggle = onToggle }, SettingsController)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "SettingsGui", false, 20
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui
	local backdrop = Instance.new("TextButton")
	backdrop.Name, backdrop.Text, backdrop.Modal = "Backdrop", "", true
	backdrop.Size, backdrop.BackgroundColor3, backdrop.BackgroundTransparency = UDim2.fromScale(1, 1), Color3.fromRGB(8, 14, 19), 0.25
	backdrop.AutoButtonColor = false
	backdrop.Parent = gui
	local panel = Instance.new("Frame")
	panel.Name, panel.Size, panel.Position, panel.AnchorPoint = "Panel", UDim2.fromOffset(450, 220), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	panel.BackgroundColor3, panel.BorderSizePixel = Color3.fromRGB(22, 33, 42), 0
	panel.Parent = backdrop
	local function text(name, value, y, size)
		local l = Instance.new("TextLabel") l.Name=name l.Text=value l.Size=UDim2.new(1,-48,0,32) l.Position=UDim2.fromOffset(24,y)
		l.Font=Enum.Font.GothamMedium l.TextSize=size l.TextColor3=Color3.fromRGB(225,234,232) l.TextXAlignment=Enum.TextXAlignment.Left l.BackgroundTransparency=1 l.Parent=panel return l
	end
	text("Title", "НАСТРОЙКИ", 20, 23)
	self.Label = text("Sensitivity", "", 74, 15)
	text("Hint", "O — вернуться в игру", 169, 13)
	local bar = Instance.new("TextButton")
	bar.Name, bar.Text, bar.Size, bar.Position = "SensitivitySlider", "", UDim2.fromOffset(402, 26), UDim2.fromOffset(24, 120)
	bar.BackgroundColor3, bar.BorderSizePixel = Color3.fromRGB(48, 65, 73), 0
	bar.Parent = panel
	local fill = Instance.new("Frame") fill.Name="Fill" fill.BorderSizePixel=0 fill.BackgroundColor3=Color3.fromRGB(122,205,190) fill.Parent=bar self.Fill=fill
	local dragging = false
	local function drag(x) self:SetValue(Config.Settings.Min + math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)*(Config.Settings.Max-Config.Settings.Min)) end
	bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true drag(i.Position.X) end end)
	UIS.InputChanged:Connect(function(i) if dragging and self.Open and i.UserInputType==Enum.UserInputType.MouseMovement then drag(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
	UIS.InputBegan:Connect(function(i, processed) if not processed and i.KeyCode==Enum.KeyCode.O then self:SetOpen(not self.Open) end end)
	self:SetValue(self.Value)
	return self
end
function SettingsController:SetValue(value)
	self.Value = math.clamp(math.round(value * 100) / 100, Config.Settings.Min, Config.Settings.Max)
	-- Roblox camera already reads this multiplier; do not also multiply camera deltas.
	UIS.MouseDeltaSensitivity = self.Value
	self.Label.Text = string.format("ЧУВСТВИТЕЛЬНОСТЬ МЫШИ   %.2f", self.Value)
	self.Fill.Size = UDim2.fromScale((self.Value-Config.Settings.Min)/(Config.Settings.Max-Config.Settings.Min),1)
end
function SettingsController:SetOpen(open)
	self.Open, self.Gui.Enabled = open, open
	self.onToggle(open)
	UIS.MouseBehavior = open and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UIS.MouseIconEnabled = open
end
return SettingsController
