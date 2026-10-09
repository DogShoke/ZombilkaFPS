local Players = game:GetService("Players")
local Results = {}
Results.__index = Results
local function label(parent,name,text,size,height,color)
 local item=Instance.new("TextLabel")
 item.Name=name;item.Text=text;item.Font=Enum.Font.GothamMedium
 item.TextColor3=color or Color3.fromRGB(232,239,232);item.TextSize=size;item.TextWrapped=true
 item.TextXAlignment=Enum.TextXAlignment.Left;item.TextYAlignment=Enum.TextYAlignment.Top
 item.BackgroundTransparency=1;item.Size=UDim2.new(1,0,0,height)
 item.AutomaticSize=Enum.AutomaticSize.Y;item.Parent=parent;return item
end
local function button(parent,name,text,y)
 local item=Instance.new("TextButton")
 item.Name=name;item.Text=text;item.Font=Enum.Font.GothamBold;item.TextSize=17;item.TextWrapped=true
 item.TextColor3=Color3.fromRGB(12,26,28);item.BackgroundColor3=Color3.fromRGB(122,208,179);item.BorderSizePixel=0
 item.Position=UDim2.new(0,0,1,y);item.Size=UDim2.new(1,0,0,44);item.Parent=parent;return item
end
function Results.new(state,remote)
 local gui=Instance.new("ScreenGui")
 gui.Name="RunResults";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=50
 gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 local back=Instance.new("Frame");back.Size=UDim2.fromScale(1,1)
 back.BackgroundColor3=Color3.fromRGB(11,18,23);back.BorderSizePixel=0;back.Active=true;back.Parent=gui
 local panel=Instance.new("Frame");panel.Name="Panel";panel.BackgroundTransparency=1
 panel.Size=UDim2.new(1,-48,1,-48);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Parent=back
 local bounds=Instance.new("UISizeConstraint");bounds.MaxSize=Vector2.new(760,740);bounds.Parent=panel
 local content=Instance.new("ScrollingFrame");content.Name="Content";content.BackgroundTransparency=1;content.BorderSizePixel=0
 content.Size=UDim2.new(1,0,1,-120);content.CanvasSize=UDim2.new();content.ScrollBarThickness=5
 content.ScrollingDirection=Enum.ScrollingDirection.Y;content.Parent=panel
 local padding=Instance.new("UIPadding");padding.PaddingRight=UDim.new(0,12);padding.PaddingBottom=UDim.new(0,8);padding.Parent=content
 local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,12);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=content
 local function canvas()content.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+8)end
 layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(canvas)
 local eyebrow=label(content,"Eyebrow","NORTHLINE / ОТЧЁТ ЭКСПЕДИЦИИ",13,24,Color3.fromRGB(125,180,170));eyebrow.LayoutOrder=1
 local title=label(content,"Title","ЗАБЕГ ЗАВЕРШЁН",30,48);title.LayoutOrder=2
 local summary=label(content,"Summary","",18,110);summary.LayoutOrder=3
 local build=label(content,"Build","",13,70,Color3.fromRGB(174,200,190));build.LayoutOrder=4
 local reset=label(content,"ResetNotice","Временные таланты, кредиты и перебросы сброшены. Следующий забег начинается с первого этажа.",15,60,Color3.fromRGB(164,184,187));reset.LayoutOrder=5
 local researchNotice=label(content,"ResearchNotice","",14,75,Color3.fromRGB(145,180,165));researchNotice.LayoutOrder=6
 local newRun=button(panel,"NewRun","НОВЫЙ ЗАБЕГ",-112)
 local researchButton=button(panel,"ResearchButton","ИССЛЕДОВАНИЯ",-56)
 researchButton.BackgroundColor3=Color3.fromRGB(28,38,44);researchButton.TextColor3=Color3.fromRGB(180,224,209)
 local self=setmetatable({Gui=gui,Active=false,ResearchButton=researchButton,ResearchNotice=researchNotice},Results)
 local pending=false
 newRun.Activated:Connect(function()
  local phase=state:GetAttribute("State")
  if pending or phase~="RunEnded"and phase~="RunRecoveryFailed"then return end
  pending=true;remote:FireServer(state:GetAttribute("RunEpoch"));task.delay(2,function()pending=false end)
 end)
 local data=state:WaitForChild("RunResults")
 local research=state:WaitForChild("Research")
 local function refresh()
  local phase=state:GetAttribute("State")
  self.Active=phase=="RunEnded"or phase=="ResettingRun"or phase=="RunRecoveryFailed";gui.Enabled=self.Active
  local duration=math.floor(data:GetAttribute("Duration")or 0)
  local names={};local ok,boons=pcall(function()return game:GetService("HttpService"):JSONDecode(data:GetAttribute("BoonsJson")or "{}")end)
  if ok and type(boons)=="table"then
   local catalog=require(game.ReplicatedStorage.Shared.BoonCatalog)
   for id,boon in boons do table.insert(names,(catalog[id]and catalog[id].NameRu or id).." · ур. "..boon.Level)end
  end
  table.sort(names);build.Text="СБОРКА: "..(#names>0 and table.concat(names," / ")or "без талантов")
  summary.Text=string.format("ДОСТИГНУТ ЭТАЖ %02d   /   ЗАЧИЩЕНО %d\nУБИЙСТВА %d   /   ВРЕМЯ %02d:%02d\nКРЕДИТЫ: ПОЛУЧЕНО %d · ПОТРАЧЕНО %d",data:GetAttribute("HighestFloor")or 1,data:GetAttribute("ClearedFloors")or 0,data:GetAttribute("Kills")or 0,math.floor(duration/60),duration%60,data:GetAttribute("CreditsEarned")or 0,data:GetAttribute("CreditsSpent")or 0)
  local status=data:GetAttribute("ResearchStatus")
  local earned=tonumber(data:GetAttribute("ResearchEarned"))or 0
  local awaiting=tonumber(data:GetAttribute("PendingResearch"))or 0
  if status=="Saved"then researchNotice.Text=string.format("ДАННЫЕ ИССЛЕДОВАНИЙ: +%d · сохранены.\nБАЛАНС: %d",earned,research:GetAttribute("Balance")or 0)
  elseif status=="Pending"then researchNotice.Text=string.format("ДАННЫЕ ИССЛЕДОВАНИЙ: +%d ожидают сохранения.\nЭта награда ещё не включена в постоянный баланс.",awaiting)
  elseif status=="Unavailable"then researchNotice.Text=string.format("Исследования недоступны. Данные за забег: %d.\nСохранение награды не подтверждено.",awaiting)
  else researchNotice.Text="Завершаем отчёт исследований…"end
  local mode=research:GetAttribute("Mode")
  if mode=="Studio"then
   researchNotice.Text..="\nИзолированный прогресс Studio."
   if research:GetAttribute("Status")=="Unavailable"and game.PlaceId==0 then researchNotice.Text..="\nДля сохранения нужна опубликованная тестовая игра."end
  elseif mode=="Mock"then researchNotice.Text..="\nТестовое хранилище: прогресс не сохраняется между сессиями."end
  if data:GetAttribute("NewRecord")==true then researchNotice.Text..="\nНОВЫЙ ЛИЧНЫЙ РЕКОРД!"end
  local c=Players.LocalPlayer.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
  newRun.Text=phase=="ResettingRun"and "ПОДГОТОВКА ПЕРВОГО ЭТАЖА…"or phase=="RunRecoveryFailed"and "ПОВТОРИТЬ ПОДГОТОВКУ ЭТАЖА"or h and h.Health>0 and "НОВЫЙ ЗАБЕГ"or "ОЖИДАНИЕ ВОЗРОЖДЕНИЯ…"
  newRun.Active=(phase=="RunEnded"or phase=="RunRecoveryFailed")and h~=nil and h.Health>0 and (phase=="RunRecoveryFailed"or Players.LocalPlayer:GetAttribute("RunCharacterReady")==true)
  researchButton.Active=phase=="RunEnded";researchButton.Selectable=researchButton.Active
 end
 self.Refresh=refresh
 state.AttributeChanged:Connect(refresh);data.AttributeChanged:Connect(refresh);research.AttributeChanged:Connect(refresh)
 Players.LocalPlayer.CharacterAdded:Connect(function(c)c:WaitForChild("Humanoid");refresh()end)
 Players.LocalPlayer:GetAttributeChangedSignal("RunCharacterReady"):Connect(refresh)
 refresh();canvas();return self
end
return Results
