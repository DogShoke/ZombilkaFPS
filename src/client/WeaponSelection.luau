local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Weapons = require(game.ReplicatedStorage.Shared.Weapons)
local WeaponSelection = {}
WeaponSelection.__index = WeaponSelection
local function selectionHint()
	return Players.LocalPlayer:GetAttribute("ResearchBusy")==true and "ЗАГРУЗКА ИССЛЕДОВАНИЙ…"or "НАЖМИ НА КАРТОЧКУ ИЛИ 1 / 2 / 3"
end
local function text(parent, name, value, size, position, dimensions, color)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.TextSize = name, value, size
	label.Font, label.BackgroundTransparency = Enum.Font.GothamMedium, 1
	label.TextColor3 = color or Color3.fromRGB(237,240,232)
	label.Position, label.Size, label.TextWrapped = position, dimensions, true
	label.TextXAlignment = Enum.TextXAlignment.Left label.Parent = parent return label
end
function WeaponSelection.new(remote)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "WeaponSelection", true, false, 40
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local backdrop = Instance.new("Frame")
	backdrop.Size, backdrop.BackgroundColor3, backdrop.BorderSizePixel = UDim2.fromScale(1,1), Color3.fromRGB(13,20,25), 0
	backdrop.BackgroundTransparency = 0.07 backdrop.Parent = gui
	local panel = Instance.new("Frame") panel.Name = "Panel"
	panel.AnchorPoint, panel.Position, panel.Size = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5), UDim2.fromOffset(1020,510)
	panel.BackgroundTransparency, panel.Parent = 1, backdrop
	local scale = Instance.new("UIScale") scale.Parent = panel
	local function resize() local v=workspace.CurrentCamera.ViewportSize scale.Scale=math.min(1,(v.X-48)/1020,(v.Y-56)/510) end
	resize() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	text(panel,"Eyebrow","NORTHLINE / ОПЕРАЦИИ",13,UDim2.fromOffset(0,0),UDim2.fromOffset(1020,24),Color3.fromRGB(160,185,175))
	text(panel,"Title","ВЫБЕРИ ОРУЖИЕ",36,UDim2.fromOffset(0,34),UDim2.fromOffset(1020,48))
	text(panel,"Subtitle","Выбор на этот забег. Зачистка начнётся, когда будешь готов.",15,UDim2.fromOffset(0,86),UDim2.fromOffset(1020,28),Color3.fromRGB(158,170,176))
	local self=setmetatable({Gui=gui,Active=true,Pending=false,Remote=remote,Buttons={}},WeaponSelection)
	local researchButton=Instance.new("TextButton")
	researchButton.Name="ResearchButton";researchButton.Text="ИССЛЕДОВАНИЯ";researchButton.Font=Enum.Font.GothamBold
	researchButton.TextSize=16;researchButton.TextColor3=Color3.fromRGB(180,224,209)
	researchButton.BackgroundColor3=Color3.fromRGB(28,38,44);researchButton.BorderSizePixel=0
	researchButton.AnchorPoint=Vector2.new(.5,0);researchButton.Position=UDim2.new(.5,0,0,16)
	researchButton.Size=UDim2.fromOffset(220,40);researchButton.Parent=backdrop
	self.ResearchButton=researchButton
	for index,id in ipairs(Weapons.Order) do
		local weapon=Weapons[id]
		local card=Instance.new("TextButton") card.Name=id card.Text="" card.AutoButtonColor=false
		card.BackgroundColor3=Color3.fromRGB(28,38,44) card.BorderSizePixel=0
		card.Position,card.Size=UDim2.fromOffset((index-1)*346,140),UDim2.fromOffset(328,344) card.Parent=panel
		local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=card
		local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(58,76,78) stroke.Thickness=1 stroke.Parent=card
		text(card,"Number","0"..index,13,UDim2.fromOffset(20,16),UDim2.fromOffset(38,22),Color3.fromRGB(165,200,173))
		text(card,"Type",weapon.Type,11,UDim2.fromOffset(62,16),UDim2.fromOffset(246,22),Color3.fromRGB(148,164,168))
		local picture=Instance.new("ImageLabel") picture.Name="WeaponImage" picture.BackgroundTransparency=1
		picture.Image=weapon.CardImage picture.ScaleType=Enum.ScaleType.Fit
		picture.Position,picture.Size=UDim2.fromOffset(10,38),UDim2.fromOffset(308,148) picture.Parent=card
		text(card,"WeaponName",weapon.Name,id=="Mossberg" and 23 or 28,UDim2.fromOffset(20,185),UDim2.fromOffset(288,34))
		text(card,"Description",weapon.Description,13,UDim2.fromOffset(20,227),UDim2.fromOffset(288,48),Color3.fromRGB(175,188,191))
		local damage=weapon.Pellets>1 and string.format("%d × %d УРОНА",weapon.Pellets,weapon.Damage) or weapon.Damage.." УРОНА"
		text(card,"Stats",damage.."   /   "..weapon.MagazineSize.." ПАТРОНОВ",12,UDim2.fromOffset(20,291),UDim2.fromOffset(288,26),Color3.fromRGB(176,213,181))
		card.MouseEnter:Connect(function() TweenService:Create(stroke,TweenInfo.new(0.12),{Color=Color3.fromRGB(155,207,167),Thickness=2}):Play() end)
		card.MouseLeave:Connect(function() TweenService:Create(stroke,TweenInfo.new(0.12),{Color=Color3.fromRGB(58,76,78),Thickness=1}):Play() end)
		card.Activated:Connect(function() self:Choose(id) end)
		self.Buttons[id]=card
	end
	self.Status=text(panel,"Status",selectionHint(),12,UDim2.fromOffset(0,491),UDim2.fromOffset(1020,20),Color3.fromRGB(127,148,150))
	Players.LocalPlayer:GetAttributeChangedSignal("ResearchBusy"):Connect(function()
		if self.Active and not self.Pending then self.Status.Text=selectionHint()end
	end)
	UserInputService.InputBegan:Connect(function(input,processed)
		if processed or not self.Active or game:GetService("GuiService").MenuIsOpen then return end
		local index=table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three},input.KeyCode)
		if index then self:Choose(Weapons.Order[index]) end
	end)
	return self
end
function WeaponSelection:Choose(id)
	if game.Players.LocalPlayer:GetAttribute("RunCharacterReady")~=true then return end
	if not self.Active or self.Pending then return end
	if Players.LocalPlayer:GetAttribute("ResearchBusy")==true then self.Status.Text=selectionHint() return end
	self.Pending=true self.Status.Text="ВЫБРАНО: "..Weapons[id].Name
	self.ResearchButton.Active=false
	self.RequestSerial=(self.RequestSerial or 0)+1
	local serial=self.RequestSerial
	self.Remote:FireServer(id)
	task.delay(3,function() if self.Active and self.RequestSerial==serial then self.Pending=false self.ResearchButton.Active=true self.Status.Text=selectionHint() end end)
end
function WeaponSelection:Show(value)
	self.Active=value self.Gui.Enabled=value self.Pending=false
	self.ResearchButton.Active=value
	self.RequestSerial=(self.RequestSerial or 0)+1
	if value then self.Status.Text=selectionHint() end
end
return WeaponSelection
