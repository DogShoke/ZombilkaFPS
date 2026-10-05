local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Audio = require(game.ReplicatedStorage.Shared.Audio)
local ElevatorService = {}
function ElevatorService.SetOpen(floor, open)
	floor.Prompt.Enabled = false
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
function ElevatorService.Inside(floor, position)
	local p=floor.Cabin:PointToObjectSpace(position)
	return math.abs(p.X)<7.8 and math.abs(p.Z)<7.8 and p.Y>-3 and p.Y<9
end
function ElevatorService.SetLabel(floor, number)
	floor.Title.SurfaceGui.TextLabel.Text = "↑  ЭТАЖ "..string.format("%02d",number)
end
return ElevatorService
