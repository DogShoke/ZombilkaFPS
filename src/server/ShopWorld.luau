-- Safe transition prop only. Never changes floor generation or hostile spawners.
local ShopWorld={}
function ShopWorld.Attach(floor,onOpen,merchant)
	local model=Instance.new("Model");model.Name="SafeVending";model.Parent=floor.Model.ElevatorLobby
	local function part(name,size,offset,color)
		local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=floor.Cabin*CFrame.new(offset)
		p.Anchored=true;p.CanTouch=false;p.Color=color;p.Material=Enum.Material.Metal;p.Parent=model;return p
	end
	local body=part("MedicalSupplies",Vector3.new(3,6,2),Vector3.new(-5,0,5.8),Color3.fromRGB(183,216,222))
	local display=part("ShopButton",Vector3.new(2.6,3,.12),Vector3.new(-5,.6,4.72),Color3.fromRGB(23,57,69))
	display.CanCollide=false
	local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.LightInfluence=0;gui.CanvasSize=Vector2.new(420,480);gui.Parent=display
	local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(.9,.9);text.Position=UDim2.fromScale(.05,.05)
	text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(174,246,223);text.TextScaled=true;text.TextWrapped=true
	text.Font=Enum.Font.GothamBold;text.Text="NORTHLINE\nБЕЗОПАСНЫЙ\nАВТОМАТ\n\nЛЕЧЕНИЕ · ПЕРЕБРОС\nПОКУПКИ ЗА КРЕДИТЫ";text.Parent=gui
	local prompt=Instance.new("ProximityPrompt");prompt.Name="OpenShop";prompt.ActionText="Открыть автомат";prompt.ObjectText="Снабжение NORTHLINE"
	prompt.HoldDuration=.2;prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.Enabled=false;prompt.Parent=display
	prompt.Triggered:Connect(onOpen);floor.VendingPrompt=prompt
	if merchant then
		local crate=part("QuartermasterStock",Vector3.new(3,3,2),Vector3.new(5,-1.5,5.8),Color3.fromRGB(121,91,58))
		crate:SetAttribute("SafeShopProp",true)
	end
	body:SetAttribute("SafeShopProp",true)
	return prompt
end
function ShopWorld.Enable(floor,enabled)
	if floor.VendingPrompt then floor.VendingPrompt.Enabled=enabled end
end
return ShopWorld
