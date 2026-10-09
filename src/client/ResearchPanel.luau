local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Catalog = require(game.ReplicatedStorage.Shared:WaitForChild("ResearchCatalog"))

local ResearchPanel = {}
ResearchPanel.__index = ResearchPanel
local ACCENT = Color3.fromRGB(122, 208, 179)
local MUTED = Color3.fromRGB(166, 185, 190)

local function label(parent, name, text, size, height)
	local item = Instance.new("TextLabel")
	item.Name = name; item.Text = text; item.Font = Enum.Font.GothamMedium
	item.TextSize = size; item.TextColor3 = Color3.fromRGB(237, 240, 232)
	item.BackgroundTransparency = 1; item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left; item.TextYAlignment = Enum.TextYAlignment.Top
	item.Size = UDim2.new(1, 0, 0, height); item.Parent = parent
	return item
end

local function button(parent, name, text)
	local item = Instance.new("TextButton")
	item.Name = name; item.Text = text; item.Font = Enum.Font.GothamBold
	item.TextSize = 16; item.TextWrapped = true; item.AutoButtonColor = false
	item.BackgroundColor3 = ACCENT; item.TextColor3 = Color3.fromRGB(12, 26, 28)
	item.BorderSizePixel = 0; item.Size = UDim2.new(1, 0, 0, 44); item.Parent = parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = item
	return item
end

local function allowed(state)
	local phase = state:GetAttribute("State")
	return phase == "ChoosingWeapon" or phase == "RunEnded"
end

function ResearchPanel.new(state, buyRemote)
	local research = state:WaitForChild("Research")
	local gui = Instance.new("ScreenGui")
	gui.Name = "ResearchPanel"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60; gui.Enabled = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local back = Instance.new("Frame"); back.Name = "Backdrop"; back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(13, 20, 25); back.BorderSizePixel = 0; back.Active = true; back.Parent = gui
	local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.BackgroundTransparency = 1
	panel.Size = UDim2.new(1, -40, 1, -40); panel.AnchorPoint = Vector2.new(.5, .5)
	panel.Position = UDim2.fromScale(.5, .5); panel.Parent = back
	local bounds = Instance.new("UISizeConstraint"); bounds.MaxSize = Vector2.new(900, 780); bounds.Parent = panel
	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"; scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0; scroll.Size = UDim2.new(1, 0, 1, -190)
	scroll.CanvasSize = UDim2.new(); scroll.ScrollBarThickness = 5; scroll.ScrollBarImageColor3 = MUTED
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y; scroll.Parent = panel
	local padding = Instance.new("UIPadding"); padding.PaddingRight = UDim.new(0, 12); padding.PaddingBottom = UDim.new(0, 8); padding.Parent = scroll
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
	local function canvas() scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8) end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(canvas)
	local eyebrow = label(scroll, "Eyebrow", "NORTHLINE / ИССЛЕДОВАНИЯ", 13, 24); eyebrow.TextColor3 = ACCENT; eyebrow.LayoutOrder = 1
	local title = label(scroll, "Title", "ПОСТОЯННЫЕ УЛУЧШЕНИЯ", 28, 68); title.LayoutOrder = 2
	local balance = label(scroll, "Balance", "", 19, 30); balance.TextColor3 = ACCENT; balance.LayoutOrder = 3
	local notice = label(scroll, "Notice", "", 14, 60); notice.TextColor3 = MUTED; notice.LayoutOrder = 4
	notice.AutomaticSize = Enum.AutomaticSize.Y
	local self = setmetatable({ Gui = gui, Active = false, ReportedActive = false, State = state,
		Research = research, Remote = buyRemote, Rows = {}, Balance = balance, Notice = notice,
		Pending = false, Serial = 0, Selected = nil }, ResearchPanel)
	for index, id in ipairs(Catalog.Order) do
		local definition = Catalog.Definitions[id]
		local row = button(scroll, id, ""); row.LayoutOrder = index + 4
		row.BackgroundColor3 = Color3.fromRGB(28, 38, 44)
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(58, 76, 78); stroke.Parent = row
		local name = label(row, "Name", definition.NameRu, 20, 52)
		name.Font = Enum.Font.GothamBold; name.Position = UDim2.fromOffset(18, 14); name.Size = UDim2.new(1, -36, 0, 52)
		local description = label(row, "Description", definition.DescriptionRu, 15, 70)
		description.TextColor3 = MUTED; description.Position = UDim2.fromOffset(18, 74); description.Size = UDim2.new(1, -36, 0, 70)
		local rank = label(row, "Rank", "", 14, 44); rank.TextColor3 = ACCENT; rank.Size = UDim2.new(1, -36, 0, 44)
		self.Rows[id] = { Button = row, Name = name, Description = description, Rank = rank, Stroke = stroke }
		row.Activated:Connect(function()
			if not self.Active or self.Pending then return end
			self.Selected = id; self:Refresh()
		end)
	end
	local archive = label(scroll, "Archive", "", 14, 80); archive.LayoutOrder = #Catalog.Order + 5; archive.TextColor3 = MUTED
	archive.AutomaticSize = Enum.AutomaticSize.Y
	self.Archive = archive
	local confirmText = label(panel, "Confirmation", "Выбери исследование. Покупка требует подтверждения.", 14, 70)
	confirmText.Position = UDim2.new(0, 0, 1, -182); confirmText.TextColor3 = MUTED
	local confirm = button(panel, "Confirm", "ПОДТВЕРДИТЬ ПОКУПКУ"); confirm.Position = UDim2.new(0, 0, 1, -104)
	local close = button(panel, "Close", "НАЗАД"); close.Position = UDim2.new(0, 0, 1, -48)
	close.BackgroundColor3 = Color3.fromRGB(42, 54, 60); close.TextColor3 = Color3.fromRGB(237, 240, 232)
	self.Confirmation = confirmText; self.ConfirmButton = confirm; self.CloseButton = close
	close.Activated:Connect(function() self:Show(false) end)
	confirm.Activated:Connect(function() self:Confirm() end)
	local function resize()
		local width = math.max(80, scroll.AbsoluteSize.X - 50)
		for _, row in pairs(self.Rows) do
			local nameHeight = math.max(28, TextService:GetTextSize(row.Name.Text, 20, Enum.Font.GothamBold, Vector2.new(width, 10000)).Y + 6)
			local descriptionHeight = math.max(36, TextService:GetTextSize(row.Description.Text, 15, Enum.Font.GothamMedium, Vector2.new(width, 10000)).Y + 6)
			row.Name.Size = UDim2.new(1, -36, 0, nameHeight)
			row.Description.Position = UDim2.fromOffset(18, 14 + nameHeight + 8)
			row.Description.Size = UDim2.new(1, -36, 0, descriptionHeight)
			row.Rank.Position = UDim2.fromOffset(18, 14 + nameHeight + 8 + descriptionHeight + 8)
			row.Button.Size = UDim2.new(1, 0, 0, 14 + nameHeight + 8 + descriptionHeight + 8 + 44 + 12)
		end
	end
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	research.AttributeChanged:Connect(function(attribute)
		if attribute == "Revision" then self.Pending = false; self.Serial += 1; self.Selected = nil end
		self:Refresh()
	end)
	resize(); self:Refresh(); canvas()
	return self
end

function ResearchPanel:Show(value)
	self.Active = value == true and allowed(self.State)
	self.Gui.Enabled = self.Active
	if not self.Active then self.Selected = nil end
	self:Refresh()
end

function ResearchPanel:Update()
	if self.Active and not allowed(self.State) then self:Show(false) end
	local changed = self.ReportedActive ~= self.Active
	self.ReportedActive = self.Active
	return changed
end

function ResearchPanel:Refresh()
	local folder = self.Research
	local ready = folder:GetAttribute("Status") == "Ready"
	local busy = folder:GetAttribute("Busy") == true or self.Pending
	local balance = tonumber(folder:GetAttribute("Balance")) or 0
	self.Balance.Text = string.format("ДАННЫЕ ИССЛЕДОВАНИЙ: %d", balance)
	local status = folder:GetAttribute("Status")
	local notice = status == "Loading" and "Загружаем исследования. Покупки скоро станут доступны."
		or not ready and "Исследования недоступны. Покупки отключены; забег можно начать."
		or busy and "Сохраняем покупку. Дождись подтверждения."
		or folder:GetAttribute("Error") and folder:GetAttribute("Error") ~= "" and "Сохранение не подтверждено. Баланс обновится после успешного ответа."
		or "Улучшения действуют в следующих забегах. Выбери исследование и подтверди покупку."
	local mode = folder:GetAttribute("Mode")
	if mode == "Studio" then
		notice ..= "\nИзолированный прогресс Studio."
		if status == "Unavailable" and game.PlaceId == 0 then notice ..= "\nДля сохранения нужна опубликованная тестовая игра." end
	elseif mode == "Mock" then notice ..= "\nТестовое хранилище: прогресс не сохраняется между сессиями." end
	self.Notice.Text = notice
	for id, row in pairs(self.Rows) do
		local rank = tonumber(folder:GetAttribute(id)) or 0
		local definition = Catalog.Definitions[id]
		local cost = definition.Costs[rank + 1]
		row.Rank.Text = string.format("РАНГ %d / %d · %s", rank, #definition.Costs,
			cost and ("СЛЕДУЮЩИЙ: " .. cost .. " ДАННЫХ") or "МАКСИМАЛЬНЫЙ РАНГ")
		row.Button.Active = self.Active and ready and not busy
		row.Button.Selectable = row.Button.Active
		row.Stroke.Color = self.Selected == id and ACCENT or Color3.fromRGB(58, 76, 78)
		row.Stroke.Thickness = self.Selected == id and 2 or 1
	end
	local archiveRank = tonumber(folder:GetAttribute("research_archive")) or 0
	local pages = {}
	for index = 1, math.min(archiveRank, #Catalog.Archive) do
		local page = Catalog.Archive[index]
		table.insert(pages, page.Title .. "\n" .. page.Text)
	end
	self.Archive.Text = #pages > 0 and table.concat(pages, "\n\n")
		or "Архив открывает справочные материалы о покровителях и записи забегов."
	if archiveRank >= 2 then self.Archive.Text ..= "\nЛИЧНЫЙ РЕКОРД: ЭТАЖ " .. tostring(folder:GetAttribute("BestFloor") or 1) end
	local id = self.Selected
	local definition = id and Catalog.Definitions[id]
	local rank = id and (tonumber(folder:GetAttribute(id)) or 0) or 0
	local cost = definition and definition.Costs[rank + 1]
	local reason = not ready and "Покупки недоступны." or busy and "Ожидаем подтверждение."
		or not definition and "Выбери исследование. Покупка требует подтверждения."
		or not cost and "Максимальный ранг уже получен." or cost > balance and "Недостаточно данных исследований." or nil
	self.CanConfirm = self.Active and reason == nil
	self.Confirmation.Text = reason or string.format("%s → ранг %d. Списать %d данных исследований?", definition.NameRu, rank + 1, cost)
	self.ConfirmButton.Active = self.CanConfirm; self.ConfirmButton.Selectable = self.CanConfirm
	self.ConfirmButton.BackgroundColor3 = self.CanConfirm and ACCENT or Color3.fromRGB(42, 54, 60)
	self.ConfirmButton.TextColor3 = self.CanConfirm and Color3.fromRGB(12, 26, 28) or MUTED
end

function ResearchPanel:Confirm()
	self:Refresh()
	if not self.CanConfirm or not allowed(self.State) then return end
	local id = self.Selected
	local rank = self.Research:GetAttribute(id) or 0
	local revision = self.Research:GetAttribute("Revision")
	if type(revision) ~= "number" then return end
	self.Pending = true; self.Serial += 1
	local serial = self.Serial
	self:Refresh()
	self.Remote:FireServer(self.State:GetAttribute("RunEpoch"), id, rank, revision)
	task.delay(6, function()
		if self.Serial == serial and self.Gui.Parent then self.Pending = false; self:Refresh() end
	end)
end

return ResearchPanel
