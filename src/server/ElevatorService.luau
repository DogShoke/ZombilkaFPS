local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Audio = require(game.ReplicatedStorage.Shared.Audio)
local ElevatorService = {}
function ElevatorService.SetOpen(floor, open)
	floor.Prompt.Enabled = false
	for _,bay in floor.Bays or {}do bay.Prompt.Enabled=false end
	floor.Indicator.Color = open and Color3.fromRGB(89,220,166) or Color3.fromRGB(218,81,61)
	Audio.Play(open and "ElevatorOpen" or "ElevatorClose", floor.Indicator)
	for _,door in ipairs(floor.Doors) do
		if door.Tween then door.Tween:Cancel() end
		-- Opening/closing panels cannot push a player. Collision returns after closure.
		door.Part.CanCollide = false
		door.Tween = TweenService:Create(door.Part,TweenInfo.new(Config.Run.DoorDuration,Enum.EasingStyle.Sine),{CFrame=open and door.Open or door.Closed})
		door.Tween:Play()
		local tween=door.Tween
		task.delay(Config.Run.DoorDuration,function()
			if door.Tween==tween and door.Part.Parent then door.Part.CanCollide=not open end
		end)
	end
end
function ElevatorService.SetRewards(floor,routes,selectedId)
	local Patrons=require(game.ReplicatedStorage.Shared.Patrons)
	for i,bay in floor.Bays do
		local route=routes and routes[i]
		local previous=bay.Route
		bay.Route=route
		bay.Prompt:SetAttribute("RouteId",route and route.Id)
		bay.Prompt:SetAttribute("RunEpoch",route and route.Epoch)
		bay.Prompt.Enabled=route~=nil
		if route then
			local patron=route.Type=="MerchantShop"and {NameRu="Завхоз",Symbol="₵",Color=Color3.fromRGB(233,188,107)}or Patrons[route.Patron]
			bay.Sign.SurfaceGui.TextLabel.Size=UDim2.fromScale(.88,.86)
			bay.Sign.SurfaceGui.TextLabel.Position=UDim2.fromScale(.06,.07)
			bay.Prompt.ObjectText=patron.NameRu
			bay.Sign.SurfaceGui.TextLabel.Text=patron.Symbol.."  "..patron.NameRu..(route.Type=="MerchantShop"and "\nМАГАЗИН / ПОКУПКИ ЗА КРЕДИТЫ"or "\nТАЛАНТ / ВЫБОР ИЗ 3")
			bay.Sign.SurfaceGui.TextLabel.TextColor3=patron.Color
			bay.Indicator.Color=patron.Color
		else bay.Sign.SurfaceGui.TextLabel.Text=previous and previous.Id==selectedId and "ВЫБРАНО / "..(previous.Type=="MerchantShop"and "Завхоз"or Patrons[previous.Patron].NameRu)or "ВЫБОР ЗАКРЫТ"end
	end
end
function ElevatorService.Inside(floor, position)
	local p=floor.Cabin:PointToObjectSpace(position)
	return math.abs(p.X)<7.8 and math.abs(p.Z)<7.8 and p.Y>-3 and p.Y<9
end
function ElevatorService.SetLabel(floor, number)
	floor.Title.SurfaceGui.TextLabel.Text = "↑  ЭТАЖ "..string.format("%02d",number)
end
return ElevatorService
