local RunService=game:GetService("RunService")
local Effects={}
function Effects.Start()
 local tracked={}
 local function attach(x)
  if x:IsA("Model")and (x:GetAttribute("IsSpawnSource")or x:GetAttribute("GroundWarning"))then tracked[x]={Burst=0}end
 end
 for _,x in workspace:GetDescendants()do attach(x)end
 workspace.DescendantAdded:Connect(function(x)task.defer(attach,x)end)
 RunService.RenderStepped:Connect(function()
  local now=workspace:GetServerTimeNow()
  for m,data in tracked do
   if not m.Parent then tracked[m]=nil;continue end
   local light=m:FindFirstChildWhichIsA("PointLight",true)
   if m:GetAttribute("GroundWarning")then
    if not m.PrimaryPart then continue end
    data.Pivot=data.Pivot or m:GetPivot()
    local t=now-(m:GetAttribute("WarningStart")or now);m:PivotTo(data.Pivot*CFrame.new(math.sin(t*42)*.04,math.sin(t*28)*.025,math.cos(t*39)*.04))
    if light then light.Brightness=2+math.sin(t*18)*1.2 end
   elseif not m:GetAttribute("Destroyed")then
    if light then light.Brightness=now-(m:GetAttribute("HitTime")or 0)<.15 and 7 or 2.4+math.sin(now*4)*.65 end
   end
   local burst=m:GetAttribute("BurstTime")or 0
   if burst>data.Burst then data.Burst=burst;local p=m:FindFirstChildWhichIsA("ParticleEmitter",true);if p then p:Emit(45)end end
  end
 end)
end
return Effects
