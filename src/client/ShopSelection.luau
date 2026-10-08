local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local ShopSelection = {}
ShopSelection.__index = ShopSelection

local FOREGROUND = Color3.fromRGB(237, 240, 232)
local MUTED = Color3.fromRGB(166, 185, 190)
local ACCENT = Color3.fromRGB(122, 208, 179)
local DISABLED = Color3.fromRGB(46, 57, 63)

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

local function button(parent, name, value, position, dimensions)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Text = value
	item.Font = Enum.Font.GothamBold
	item.TextSize = 16
	item.TextWrapped = true
	item.AutoButtonColor = false
	item.BackgroundColor3 = ACCENT
	item.TextColor3 = Color3.fromRGB(12, 26, 28)
	item.BorderSizePixel = 0
	item.Position = position
	item.Size = dimensions
	item.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = item
	return item
end

function ShopSelection.new(runState, buyRemote, closeRemote)
	local offer = runState:WaitForChild("ShopOffer")
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopSelection"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 46
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(13, 20, 25)
	backdrop.BorderSizePixel = 0
	backdrop.Active = true
	backdrop.Parent = gui
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -48, 1, -48)
	panel.BackgroundTransparency = 1
	panel.Parent = backdrop
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(1160, 860)
	bounds.Parent = panel
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, 0, 1, -100)
	content.ScrollBarThickness = 5
	content.ScrollBarImageColor3 = MUTED
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.AutomaticCanvasSize = Enum.AutomaticSize.None
	content.CanvasSize = UDim2.new()
	content.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
	local function resizeCanvas()
		content.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
	local eyebrow = label(content, "Eyebrow", "NORTHLINE / СНАБЖЕНИЕ", 13,
		UDim2.new(), UDim2.new(1, 0, 0, 24), ACCENT)
	eyebrow.LayoutOrder = 1
	local title = label(content, "Title", "", 32, UDim2.new(), UDim2.new(1, 0, 0, 48))
	title.LayoutOrder = 2
	local balance = label(content, "Balance", "", 16, UDim2.new(), UDim2.new(1, 0, 0, 44), ACCENT)
	balance.LayoutOrder = 3
	local cards = Instance.new("Frame")
	cards.Name = "Items"
	cards.BackgroundTransparency = 1
	cards.Size = UDim2.new(1, 0, 0, 258)
	cards.LayoutOrder = 4
	cards.Parent = content
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = cards
	local notice = label(content, "Notice", "", 13, UDim2.new(), UDim2.new(1, 0, 0, 38), MUTED)
	notice.LayoutOrder = 5
	local continueButton = button(panel, "Continue", "ПРОДОЛЖИТЬ · БЕСПЛАТНО",
		UDim2.new(0, 0, 1, -92), UDim2.new(1, 0, 0, 44))
	local status = label(panel, "Status", "Покупки необязательны. Можно продолжить без них.", 13,
		UDim2.new(0, 0, 1, -40), UDim2.new(1, 0, 0, 40), MUTED)
	local self = setmetatable({
		Gui = gui, Active = false, Pending = false, RunState = runState, Offer = offer,
		BuyRemote = buyRemote, CloseRemote = closeRemote, Cards = cards, Grid = grid,
		Title = title, Balance = balance, Status = status, Notice = notice,
		ContinueButton = continueButton, Items = {}, RequestSerial = 0,
	}, ShopSelection)
	local function resize()
		local columns = panel.AbsoluteSize.X >= 1000 and 3 or panel.AbsoluteSize.X >= 700 and 2 or 1
		local width = cards.AbsoluteSize.X > 0 and cards.AbsoluteSize.X or panel.AbsoluteSize.X - 12
		if width <= 0 then width = 340 end
		grid.FillDirectionMaxCells = columns
		local cellWidth = math.max(1, math.floor((width - (columns - 1) * 16) / columns) - 1)
		local textWidth = math.max(1, cellWidth - 38)
		local nameHeight, descriptionHeight = 52, 56
		local count = 0
		for _, item in pairs(self.Items) do
			count += 1
			local nameSize = TextService:GetTextSize(item.Name.Text, 21, Enum.Font.GothamBold, Vector2.new(textWidth, 10000))
			local descriptionSize = TextService:GetTextSize(item.Description.Text, 16, Enum.Font.GothamMedium, Vector2.new(textWidth, 10000))
			nameHeight = math.max(nameHeight, math.ceil(nameSize.Y) + 6)
			descriptionHeight = math.max(descriptionHeight, math.ceil(descriptionSize.Y) + 6)
		end
		local descriptionY = 14 + nameHeight + 8
		local priceY = descriptionY + descriptionHeight + 8
		local buyY = priceY + 30
		local reasonY = buyY + 48
		local cellHeight = reasonY + 42
		for _, item in pairs(self.Items) do
			item.Name.Size = UDim2.new(1, -36, 0, nameHeight)
			item.Description.Position = UDim2.fromOffset(18, descriptionY)
			item.Description.Size = UDim2.new(1, -36, 0, descriptionHeight)
			item.Price.Position = UDim2.fromOffset(18, priceY)
			item.Button.Position = UDim2.fromOffset(18, buyY)
			item.Reason.Position = UDim2.fromOffset(18, reasonY)
		end
		grid.CellSize = UDim2.fromOffset(cellWidth, cellHeight)
		local rows = math.max(1, math.ceil(count / columns))
		cards.Size = UDim2.new(1, 0, 0, rows * cellHeight + (rows - 1) * 16)
		title.TextSize = columns == 1 and 26 or 32
	end
	self.Resize = resize
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	cards:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	continueButton.Activated:Connect(function() self:Continue() end)
	local function refreshAndReset()
		self:ResetPending()
		self:Refresh()
	end
	offer:GetAttributeChangedSignal("Revision"):Connect(refreshAndReset)
	offer:GetAttributeChangedSignal("Active"):Connect(refreshAndReset)
	runState:GetAttributeChangedSignal("State"):Connect(refreshAndReset)
	runState:GetAttributeChangedSignal("Credits"):Connect(function() self:UpdateControls() end)
	runState:GetAttributeChangedSignal("Rerolls"):Connect(function() self:UpdateControls() end)
	local function refreshDeferred()
		task.defer(function() if gui.Parent then self:Refresh() end end)
	end
	offer.ChildAdded:Connect(refreshDeferred)
	offer.ChildRemoved:Connect(refreshDeferred)
	self:Refresh()
	resizeCanvas()
	return self
end

function ShopSelection:ResetPending()
	self.Pending = false
	self.RequestSerial += 1
end

function ShopSelection:Refresh()
	self.Active = self.RunState:GetAttribute("State") == "ShopInterlude"
		and self.Offer:GetAttribute("Active") == true
	self.Gui.Enabled = self.Active
	self.Title.Text = tostring(self.Offer:GetAttribute("Title") or "СНАБЖЕНИЕ")
	for _, item in pairs(self.Items) do item.Card:Destroy() end
	self.Items = {}
	local entries = self.Offer:GetChildren()
	table.sort(entries, function(a, b) return a.Name < b.Name end)
	local count = 0
	for _, entry in entries do
		local id = entry:GetAttribute("Id")
		if not entry:IsA("Folder") or type(id) ~= "string" or self.Items[id] then continue end
		count += 1
		if count > 5 then break end
		local card = Instance.new("Frame")
		card.Name = "Item" .. count
		card.BackgroundColor3 = Color3.fromRGB(28, 38, 44)
		card.BorderSizePixel = 0
		card.LayoutOrder = count
		card.Parent = self.Cards
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(58, 76, 78)
		stroke.Parent = card
		local name = label(card, "ItemName", tostring(entry:GetAttribute("NameRu") or id), 21,
			UDim2.fromOffset(18, 14), UDim2.new(1, -36, 0, 52))
		name.Font = Enum.Font.GothamBold
		local description = label(card, "Description", tostring(entry:GetAttribute("DescriptionRu") or ""), 16,
			UDim2.fromOffset(18, 74), UDim2.new(1, -36, 0, 56), MUTED)
		local price = label(card, "Price", "", 15,
			UDim2.fromOffset(18, 138), UDim2.new(1, -36, 0, 24), ACCENT)
		local buy = button(card, "Buy", "КУПИТЬ", UDim2.fromOffset(18, 168), UDim2.new(1, -36, 0, 38))
		local reason = label(card, "Reason", "", 13,
			UDim2.fromOffset(18, 216), UDim2.new(1, -36, 0, 34), MUTED)
		buy.Activated:Connect(function() self:Buy(id) end)
		self.Items[id] = { Entry = entry, Card = card, Name = name, Description = description, Button = buy, Price = price, Reason = reason }
	end
	self.Notice.Text = count == 0 and "Получаем ассортимент… Продолжить можно без покупок."
		or "Ассортимент ограничен. Все покупки действуют только в текущем забеге."
	self:UpdateControls()
	self.Resize()
end

function ShopSelection:UpdateControls()
	local credits = tonumber(self.RunState:GetAttribute("Credits")) or 0
	local rerolls = tonumber(self.RunState:GetAttribute("Rerolls")) or 0
	self.Balance.Text = string.format("КРЕДИТЫ: %d   ·   ПЕРЕБРОСЫ: %d", credits, rerolls)
	for _, item in pairs(self.Items) do
		local entry = item.Entry
		local priceValue = entry:GetAttribute("Price")
		local price = tonumber(priceValue) or 0
		local sold = entry:GetAttribute("Sold") == true
		local reason = ""
		if self.Pending then reason = "Ожидаем ответ сервера."
		elseif sold then reason = "Товар куплен."
		elseif type(priceValue) ~= "number" then reason = "Получаем данные товара."
		elseif entry:GetAttribute("Available") ~= true then
			reason = tostring(entry:GetAttribute("Reason") or "")
			if reason == "" then reason = "Сейчас недоступно." end
		elseif credits < price then reason = "Недостаточно кредитов."
		elseif not self.Active then reason = "Магазин закрыт."
		end
		item.CanBuy = reason == ""
		item.Price.Text = price == 0 and "БЕСПЛАТНО" or string.format("%d КРЕДИТОВ", price)
		item.Button.Text = sold and "КУПЛЕНО" or "КУПИТЬ"
		item.Button.Active = item.CanBuy
		item.Button.Selectable = item.CanBuy
		item.Button.BackgroundColor3 = item.CanBuy and ACCENT or DISABLED
		item.Button.TextColor3 = item.CanBuy and Color3.fromRGB(12, 26, 28) or MUTED
		item.Reason.Text = reason
	end
	local canContinue = self.Active and not self.Pending
	self.ContinueButton.Active = canContinue
	self.ContinueButton.Selectable = canContinue
	self.ContinueButton.BackgroundColor3 = canContinue and ACCENT or DISABLED
	self.ContinueButton.TextColor3 = canContinue and Color3.fromRGB(12, 26, 28) or MUTED
	self.Status.Text = self.Pending and "Ожидаем подтверждение сервера…" or "Покупки необязательны. Можно продолжить без них."
end

function ShopSelection:RequestContext()
	if not self.Active or self.Pending then return nil end
	local epoch = self.RunState:GetAttribute("RunEpoch")
	local token = self.Offer:GetAttribute("Token")
	local revision = self.Offer:GetAttribute("Revision")
	if self.Offer:GetAttribute("RunEpoch") ~= epoch or type(token) ~= "string" or token == ""
		or type(revision) ~= "number" then return nil end
	return epoch, token, revision
end

function ShopSelection:BeginRequest()
	self.Pending = true
	self.RequestSerial += 1
	local serial = self.RequestSerial
	self:UpdateControls()
	task.delay(3, function()
		if self.Active and self.RequestSerial == serial and self.Gui.Parent then
			self:ResetPending()
			self:Refresh()
			self.Status.Text = "Нет подтверждения. Повтори действие."
		end
	end)
end

function ShopSelection:Buy(id)
	self:UpdateControls()
	local item = self.Items[id]
	if not item or not item.CanBuy then return end
	local epoch, token, revision = self:RequestContext()
	if not epoch then return end
	self:BeginRequest()
	self.BuyRemote:FireServer(epoch, token, id, revision)
end

function ShopSelection:Continue()
	local epoch, token, revision = self:RequestContext()
	if not epoch then return end
	self:BeginRequest()
	self.CloseRemote:FireServer(epoch, token, revision)
end

return ShopSelection
