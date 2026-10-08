local Players=game:GetService("Players")
local Results={}
Results.__index=Results
local function label(parent,name,text,y,height,size,color)
	local item=Instance.new("TextLabel")
	item.Name=name;item.Text=text;item.Font=Enum.Font.GothamMedium
	item.TextColor3=color or Color3.fromRGB(232,239,232)
	item.TextSize=size;item.TextWrapped=true;item.TextXAlignment=Enum.TextXAlignment.Left
	item.BackgroundTransparency=1;item.Position=UDim2.fromOffset(32,y)
	item.Size=UDim2.new(1,-64,0,height);item.Parent=parent
	return item
end
function Results.new(state,remote)
	local gui=Instance.new("ScreenGui")
	gui.Name="RunResults";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=50
	gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
	local back=Instance.new("Frame");back.Size=UDim2.fromScale(1,1)
	back.BackgroundColor3=Color3.fromRGB(11,18,23);back.BorderSizePixel=0;back.Parent=gui
	local panel=Instance.new("Frame");panel.Name="Panel"
	panel.Size=UDim2.fromOffset(650,536);panel.AnchorPoint=Vector2.new(.5,.5)
	panel.Position=UDim2.fromScale(.5,.5);panel.BackgroundColor3=Color3.fromRGB(26,36,43);panel.Parent=back
	local scale=Instance.new("UIScale");scale.Parent=panel
	local function resize()local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,(v.X-40)/650,(v.Y-40)/536)end
	resize();workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	label(panel,"Eyebrow","NORTHLINE / ОТЧЁТ ЭКСПЕДИЦИИ",20,24,13,Color3.fromRGB(125,180,170))
	label(panel,"Title","ЗАБЕГ ЗАВЕРШЁН",62,48,32)
	local summary=label(panel,"Summary","",126,112,18)
	local build=label(panel,"Build","",236,90,13,Color3.fromRGB(174,200,190))
	label(panel,"ResetNotice","Временные таланты, кредиты и перебросы сброшены. Следующий забег начинается с первого этажа.",335,60,15,Color3.fromRGB(164,184,187))
	label(panel,"ResearchNotice","Исследования пока недоступны. Постоянные данные сейчас не записываются.",400,44,13,Color3.fromRGB(145,160,165))
	local button=Instance.new("TextButton");button.Name="NewRun";button.Font=Enum.Font.GothamBold;button.TextSize=18
	button.TextColor3=Color3.fromRGB(12,26,28);button.BackgroundColor3=Color3.fromRGB(122,208,179)
	button.Position=UDim2.fromOffset(32,462);button.Size=UDim2.new(1,-64,0,44);button.Parent=panel
	local self=setmetatable({Gui=gui,Active=false},Results)
	local pending=false
	button.Activated:Connect(function()
		local phase=state:GetAttribute("State")
		if pending or phase~="RunEnded"and phase~="RunRecoveryFailed"then return end
		pending=true;remote:FireServer(state:GetAttribute("RunEpoch"))
		task.delay(2,function()pending=false end)
	end)
	local data=state:WaitForChild("RunResults")
	local function refresh()
		local phase=state:GetAttribute("State")
		self.Active=phase=="RunEnded"or phase=="ResettingRun"or phase=="RunRecoveryFailed"
		gui.Enabled=self.Active
		local duration=math.floor(data:GetAttribute("Duration")or 0)
		local names={};local ok,boons=pcall(function()return game:GetService("HttpService"):JSONDecode(data:GetAttribute("BoonsJson")or "{}")end)
		if ok then
			local catalog=require(game.ReplicatedStorage.Shared.BoonCatalog)
			for id,boon in boons do table.insert(names,(catalog[id]and catalog[id].NameRu or id).." · "..boon.Level)end
		end
		table.sort(names);build.Text="СБОРКА: "..(#names>0 and table.concat(names," / ")or "без талантов")
		summary.Text=string.format("ДОСТИГНУТ ЭТАЖ %02d   /   ЗАЧИЩЕНО %d\nУБИЙСТВА %d   /   ВРЕМЯ %02d:%02d\nКРЕДИТЫ: ПОЛУЧЕНО %d · ПОТРАЧЕНО %d",data:GetAttribute("HighestFloor")or 1,data:GetAttribute("ClearedFloors")or 0,data:GetAttribute("Kills")or 0,math.floor(duration/60),duration%60,data:GetAttribute("CreditsEarned")or 0,data:GetAttribute("CreditsSpent")or 0)
		local c=Players.LocalPlayer.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
		button.Text=phase=="ResettingRun"and "ПОДГОТОВКА ПЕРВОГО ЭТАЖА…"or phase=="RunRecoveryFailed"and "ПОВТОРИТЬ ПОДГОТОВКУ ЭТАЖА"or h and h.Health>0 and "НОВЫЙ ЗАБЕГ"or "ОЖИДАНИЕ ВОЗРОЖДЕНИЯ…"
		button.Active=(phase=="RunEnded"or phase=="RunRecoveryFailed")and h~=nil and h.Health>0
	end
	state.AttributeChanged:Connect(refresh);data.AttributeChanged:Connect(refresh)
	Players.LocalPlayer.CharacterAdded:Connect(function(c)c:WaitForChild("Humanoid");refresh()end)
	refresh();return self
end
return Results
