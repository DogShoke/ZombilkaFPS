local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local RewardSelection = {}
RewardSelection.__index = RewardSelection

local FOREGROUND = Color3.fromRGB(237, 240, 232)
local MUTED = Color3.fromRGB(166, 185, 190)
local ACCENT = Color3.fromRGB(122, 208, 179)
local READY_TEXT = "ВЫБЕРИ ОДИН ТАЛАНТ · НАЖМИ НА КАРТОЧКУ ИЛИ 1 / 2 / 3"

local function label(parent, name, value, size, position, dimensions, color)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = value
	item.Font = Enum.Font.GothamMedium
	item.TextSize = size
	item.TextColor3 = color or FOREGROUND
	item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Top
	item.BackgroundTransparency = 1
	item.Position = position
	item.Size = dimensions
	item.Parent = parent
	return item
end

local function attributeColor(instance, name, fallback)
	local value = instance:GetAttribute(name)
	return typeof(value) == "Color3" and value or fallback
end

function RewardSelection.new(runState, claimRemote, rerollRemote)
	local offer = runState:WaitForChild("RewardOffer")
	local gui = Instance.new("ScreenGui")
	gui.Name = "RewardSelection"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 45
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(13, 20, 25)
	backdrop.BackgroundTransparency = 0.04
	backdrop.BorderSizePixel = 0
	backdrop.Active = true
	backdrop.Parent = gui
	local panel = Instance.new("ScrollingFrame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -48, 1, -48)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.ScrollBarThickness = 5
	panel.ScrollBarImageColor3 = MUTED
	panel.ScrollingDirection = Enum.ScrollingDirection.Y
	panel.AutomaticCanvasSize = Enum.AutomaticSize.None
	panel.CanvasSize = UDim2.new()
	panel.Parent = backdrop
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(1080, 800)
	bounds.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel
	local function resizeCanvas()
		panel.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+8)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
	resizeCanvas()
	local eyebrow = label(panel, "Eyebrow", "NORTHLINE / ПОДДЕРЖКА ЭКСПЕДИЦИИ", 13,
		UDim2.new(), UDim2.new(1, 0, 0, 24), ACCENT)
	eyebrow.LayoutOrder = 1
	local title = label(panel, "Patron", "", 32, UDim2.new(), UDim2.new(1, 0, 0, 48))
	title.LayoutOrder = 2
	local greeting = label(panel, "Greeting", "", 16, UDim2.new(), UDim2.new(1, 0, 0, 56), MUTED)
	greeting.LayoutOrder = 3
	local cards = Instance.new("Frame")
	cards.Name = "Cards"
	cards.BackgroundTransparency = 1
	cards.Size = UDim2.new(1, 0, 0, 340)
	cards.LayoutOrder = 4
	cards.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = cards
	local rerollPanel = Instance.new("Frame")
	rerollPanel.Name = "RerollControls"
	rerollPanel.BackgroundTransparency = 1
	rerollPanel.Size = UDim2.new(1, 0, 0, 116)
	rerollPanel.LayoutOrder = 5
	rerollPanel.Parent = panel
	local rerollCount = label(rerollPanel, "Count", "", 14,
		UDim2.new(), UDim2.new(1, 0, 0, 24), ACCENT)
	local rerollButton = Instance.new("TextButton")
	rerollButton.Name = "Reroll"
	rerollButton.Text = "ПЕРЕБРОСИТЬ ПРЕДЛОЖЕНИЕ"
	rerollButton.Font = Enum.Font.GothamBold
	rerollButton.TextSize = 15
	rerollButton.TextWrapped = true
	rerollButton.AutoButtonColor = false
	rerollButton.BorderSizePixel = 0
	rerollButton.Position = UDim2.fromOffset(0, 30)
	rerollButton.Size = UDim2.new(1, 0, 0, 44)
	rerollButton.Parent = rerollPanel
	local rerollCorner = Instance.new("UICorner")
	rerollCorner.CornerRadius = UDim.new(0, 8)
	rerollCorner.Parent = rerollButton
	local rerollReason = label(rerollPanel, "Reason", "", 13,
		UDim2.fromOffset(0, 82), UDim2.new(1, 0, 0, 52), MUTED)
	local status = label(panel, "Status", READY_TEXT, 13, UDim2.new(), UDim2.new(1, 0, 0, 40), MUTED)
	status.LayoutOrder = 6
	local buildSummary=label(panel,"BuildSummary","",13,UDim2.new(),UDim2.new(1,0,0,100),MUTED)
	buildSummary.LayoutOrder=7
	buildSummary.AutomaticSize=Enum.AutomaticSize.Y
	local build=runState:WaitForChild("Build")
	local function refreshBuild()
		local names={}
		for _,item in build:GetChildren()do
			local rarity=item:GetAttribute("RarityRu")or item:GetAttribute("Rarity")or ""
			table.insert(names,(item:GetAttribute("NameRu")or item.Name).." · "..rarity.." · ур. "..(item:GetAttribute("Level")or 1))
		end
		table.sort(names);buildSummary.Text="ТЕКУЩАЯ СБОРКА\n"..(#names>0 and table.concat(names," / ")or "Первый талант — начало твоей сборки.")
	end
	local buildConnections = {}
	local function watchBuildItem(item)
		buildConnections[item] = item.AttributeChanged:Connect(refreshBuild)
		refreshBuild()
	end
	for _, item in build:GetChildren() do watchBuildItem(item) end
	build.ChildAdded:Connect(watchBuildItem)
	build.ChildRemoved:Connect(function(item)
		if buildConnections[item] then buildConnections[item]:Disconnect(); buildConnections[item] = nil end
		refreshBuild()
	end)
	refreshBuild()
	local self = setmetatable({
		Gui = gui, Active = false, Pending = false, RunState = runState, Offer = offer,
		Remote = claimRemote, RerollRemote = rerollRemote, Cards = cards, Grid = grid, Status = status,
		RerollButton = rerollButton, RerollCount = rerollCount, RerollReason = rerollReason,
		Title = title, Greeting = greeting, Buttons = {}, CardIds = {}, RequestSerial = 0,
	}, RewardSelection)
	local function resize()
		local narrow = panel.AbsoluteSize.X < 720
		local columns = narrow and 1 or 3
		grid.FillDirectionMaxCells = columns
		-- Integer width avoids a one-pixel overflow wrapping the third desktop card.
		local width=cards.AbsoluteSize.X>0 and cards.AbsoluteSize.X or panel.AbsoluteSize.X-12
		grid.CellSize = UDim2.fromOffset(math.max(1,math.floor((width-(columns-1)*16)/columns)-1),340)
		local rows = math.max(1, math.ceil(#self.CardIds / columns))
		cards.Size = UDim2.new(1, 0, 0, rows * 340 + (rows - 1) * 16)
		title.TextSize = narrow and 26 or 32
		local countHeight = narrow and 48 or 24
		rerollCount.Size = UDim2.new(1, 0, 0, countHeight)
		rerollButton.Position = UDim2.fromOffset(0, countHeight + 6)
		rerollReason.Position = UDim2.fromOffset(0, countHeight + 58)
		rerollPanel.Size = UDim2.new(1, 0, 0, countHeight + 110)
	end
	self.Resize = resize
	rerollButton.Activated:Connect(function() self:Reroll() end)
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	cards:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	offer:GetAttributeChangedSignal("Revision"):Connect(function()
		self:ResetPending()
		self:Refresh()
	end)
	runState:GetAttributeChangedSignal("State"):Connect(function()
		self:ResetPending()
		self:Refresh()
	end)
	-- These also cover initial replication where the revision can arrive before children.
	local function refreshDeferred()
		task.defer(function() if gui.Parent then self:Refresh() end end)
	end
	offer.ChildAdded:Connect(refreshDeferred)
	offer.ChildRemoved:Connect(refreshDeferred)
	offer:GetAttributeChangedSignal("Active"):Connect(refreshDeferred)
	-- Balance updates can arrive before the new revision. Keep pending until revision/state changes.
	runState:GetAttributeChangedSignal("Rerolls"):Connect(function() self:UpdateControls() end)
	offer:GetAttributeChangedSignal("RerollsUsed"):Connect(function() self:UpdateControls() end)
	offer:GetAttributeChangedSignal("RerollsLimit"):Connect(function() self:UpdateControls() end)
	offer:GetAttributeChangedSignal("CanReroll"):Connect(function() self:UpdateControls() end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.Active or GuiService.MenuIsOpen then return end
		local index = table.find({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three }, input.KeyCode)
		if index then self:Choose(self.CardIds[index]) end
	end)
	self:Refresh()
	return self
end

function RewardSelection:ResetPending()
	self.Pending = false
	self.RequestSerial += 1
end

function RewardSelection:Refresh()
	self.Active = self.RunState:GetAttribute("State") == "RewardInterlude"
		and self.Offer:GetAttribute("Active") == true
	self.Gui.Enabled = self.Active
	self.Title.Text = tostring(self.Offer:GetAttribute("PatronName") or "ПОДДЕРЖКА ЭКСПЕДИЦИИ")
	self.Title.TextColor3 = attributeColor(self.Offer, "Color", ACCENT)
	self.Greeting.Text = tostring(self.Offer:GetAttribute("Greeting") or "Выбери один талант для этого забега.")
	for _, button in pairs(self.Buttons) do button:Destroy() end
	self.Buttons = {}
	self.CardIds = {}
	local entries = self.Offer:GetChildren()
	table.sort(entries, function(a, b) return a.Name < b.Name end)
	for _, entry in ipairs(entries) do
		local id = entry:GetAttribute("Id")
		if not entry:IsA("Folder") or type(id) ~= "string" or self.Buttons[id] then continue end
		local index = #self.CardIds + 1
		if index > 3 then break end
		table.insert(self.CardIds, id)
		local color = attributeColor(entry, "RarityColor", attributeColor(entry, "Color", ACCENT))
		local card = Instance.new("TextButton")
		card.Name = "Card" .. index
		card.Text = ""
		card.AutoButtonColor = false
		card.BackgroundColor3 = Color3.fromRGB(28, 38, 44)
		card.BorderSizePixel = 0
		card.LayoutOrder = index
		card.Active = not self.Pending
		card.Selectable = not self.Pending
		card.Parent = self.Cards
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 2
		stroke.Parent = card
		label(card, "Number", string.format("0%d", index), 13,
			UDim2.fromOffset(20, 18), UDim2.fromOffset(32, 24), MUTED)
		local rarity = tostring(entry:GetAttribute("RarityRu") or "")
		local level = tonumber(entry:GetAttribute("Level")) or 1
		label(card, "Rarity", rarity .. " · УР. " .. level, 13,
			UDim2.fromOffset(58, 18), UDim2.new(1, -78, 0, 32), color)
		local name = label(card, "TalentName", tostring(entry:GetAttribute("NameRu") or id), 24,
			UDim2.fromOffset(20, 64), UDim2.new(1, -40, 0, 64))
		name.Font = Enum.Font.GothamBold
		label(card, "Description", tostring(entry:GetAttribute("DescriptionRu") or ""), 17,
			UDim2.fromOffset(20, 140), UDim2.new(1, -40, 0, 128), MUTED)
		local action = label(card, "Action", "ВЫБРАТЬ ТАЛАНТ", 15,
			UDim2.fromOffset(20, 292), UDim2.new(1, -40, 0, 28), color)
		action.Font = Enum.Font.GothamBold
		card.MouseEnter:Connect(function() if not self.Pending then stroke.Thickness = 3 end end)
		card.MouseLeave:Connect(function() stroke.Thickness = 2 end)
		card.SelectionGained:Connect(function() stroke.Thickness = 3 end)
		card.SelectionLost:Connect(function() stroke.Thickness = 2 end)
		card.Activated:Connect(function() self:Choose(id) end)
		self.Buttons[id] = card
	end
	self.Status.Text = self.Pending and "ОЖИДАЕМ ПОДТВЕРЖДЕНИЕ…"
		or #self.CardIds < 3 and "ПОЛУЧАЕМ ПРЕДЛОЖЕНИЕ…" or READY_TEXT
	self:UpdateControls()
	self.Resize()
end

function RewardSelection:UpdateControls()
	local count = tonumber(self.RunState:GetAttribute("Rerolls")) or 0
	local used = tonumber(self.Offer:GetAttribute("RerollsUsed")) or 0
	local limit = tonumber(self.Offer:GetAttribute("RerollsLimit")) or 2
	self.RerollCount.Text = string.format("ПЕРЕБРОСЫ: %d   ·   В ЭТОМ ПРЕДЛОЖЕНИИ: %d / %d", count, used, limit)
	local reason = ""
	if not self.RerollRemote then reason = "Переброс пока недоступен."
	elseif self.Pending then reason = "Ожидаем ответ сервера."
	elseif not self.Active or #self.CardIds ~= 3 then reason = "Ожидаем актуальное предложение."
	elseif self.Offer:GetAttribute("CanReroll") == false then reason = "Таланты покровителя исчерпаны."
	elseif used >= limit then reason = "Достигнут лимит перебросов этого предложения."
	elseif count <= 0 then reason = "Нет перебросов. Выбери один из доступных талантов."
	end
	self.CanReroll = reason == ""
	self.RerollButton.Active = self.CanReroll
	self.RerollButton.Selectable = self.CanReroll
	self.RerollButton.BackgroundColor3 = self.CanReroll and ACCENT or Color3.fromRGB(42, 54, 60)
	self.RerollButton.TextColor3 = self.CanReroll and Color3.fromRGB(12, 26, 28) or MUTED
	self.RerollReason.Text = self.CanReroll and "Цена: 1 переброс. Редкость может измениться; улучшение не гарантировано." or reason
end

function RewardSelection:RequestContext()
	if not self.Active or self.Pending or #self.CardIds ~= 3 then return nil end
	local epoch = self.RunState:GetAttribute("RunEpoch")
	local token = self.Offer:GetAttribute("Token")
	local revision = self.Offer:GetAttribute("Revision")
	if self.Offer:GetAttribute("RunEpoch") ~= epoch or type(token) ~= "string" or token == ""
		or type(revision) ~= "number" then return nil end
	return epoch, token, revision
end

function RewardSelection:BeginRequest()
	self.Pending = true
	self.RequestSerial += 1
	local serial = self.RequestSerial
	self.Status.Text = "ОЖИДАЕМ ПОДТВЕРЖДЕНИЕ…"
	for _, button in pairs(self.Buttons) do button.Active = false; button.Selectable = false end
	self:UpdateControls()
	-- Retry the same authoritative offer if a rejected/lost request has no state update.
	task.delay(3, function()
		if self.Active and self.RequestSerial == serial and self.Gui.Parent then
			self:ResetPending()
			self:Refresh()
			self.Status.Text = "НЕТ ПОДТВЕРЖДЕНИЯ. ПОВТОРИ ДЕЙСТВИЕ."
		end
	end)
end

function RewardSelection:Choose(id)
	if not self.Buttons[id] then return end
	local epoch, token, revision = self:RequestContext()
	if not epoch then return end
	self:BeginRequest()
	self.Remote:FireServer(epoch, token, id, revision)
end

function RewardSelection:Reroll()
	self:UpdateControls()
	if not self.CanReroll then return end
	local epoch, token, revision = self:RequestContext()
	if not epoch then return end
	self:BeginRequest()
	self.RerollRemote:FireServer(epoch, token, revision)
end

return RewardSelection
