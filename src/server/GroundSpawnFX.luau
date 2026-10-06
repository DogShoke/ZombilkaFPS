local Assets=require(script.Parent.ArenaAssets)
local FX={}
function FX.Particles(part,color,rate)
 local a=Instance.new("Attachment");a.Parent=part
 local p=Instance.new("ParticleEmitter");p.Name="InfectedSteam";p.Texture="rbxasset://textures/particles/smoke_main.dds"
 p.Color=ColorSequence.new(color);p.Lifetime=NumberRange.new(.6,1.2);p.Speed=NumberRange.new(2,5);p.SpreadAngle=Vector2.new(35,35);p.Rate=rate
 p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(.5,1.2),NumberSequenceKeypoint.new(1,0)})
 p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)});p.Parent=a
 return p
end
function FX.Warning(point,parent,duration)
 local m=Assets.Place("GroundCracks",parent,CFrame.new(point+Vector3.new(0,.025,0)),.35,false)
 m.Name="GroundWarning";m:SetAttribute("GroundWarning",true);m:SetAttribute("WarningStart",workspace:GetServerTimeNow());m:SetAttribute("WarningDuration",duration)
 local light=Instance.new("PointLight");light.Color=Color3.fromRGB(113,243,167);light.Range=10;light.Brightness=2;light.Parent=m.PrimaryPart
 FX.Particles(m.PrimaryPart,Color3.fromRGB(156,163,150),22)
 return m
end
return FX
