local Config=require(game.ReplicatedStorage.Shared.Config)
local Clock=require(script.Parent.RunClock)
local Arena=require(script.Parent.ArenaAssets)
local FX=require(script.Parent.GroundSpawnFX)
local E=Config.Run.Encounters
local Sources={}
local active,progress,burst,enabled={},nil,nil,false
local function update(data)
 local m=data.Model
 m:SetAttribute("Layers",data.Layers);m:SetAttribute("LayerHealth",data.Health);m:SetAttribute("ShieldUntil",data.ShieldUntil);m:SetAttribute("Destroyed",data.Layers==0)
 data.Label.Text=data.Layers==0 and "ИСТОЧНИК РАЗРУШЕН"or string.format("ЗАРАЖЁННЫЙ КОФЕ\nЗАЩИТА %d / %d",data.Layers,E.SourceLayers)
 for i,b in data.Bars do
  b.BackgroundColor3=i<=data.Layers and Color3.fromRGB(111,232,164)or Color3.fromRGB(64,68,73)
  b.Size=UDim2.new(.28*(i==data.Layers and data.Health/E.SourceLayerHealth or 1),0,.1,0)
 end
 data.Light.Enabled=data.Layers>0
end
function Sources.Clear()
 enabled=false;for m in active do m:Destroy()end;active={};progress=nil;burst=nil
end
function Sources.Configure(floor,p,onBurst)
 Sources.Clear();progress=p;burst=onBurst;enabled=true
 for _,s in floor.Layout.Sources do
  local root=Instance.new("Model");root.Name=s.Id;root:SetAttribute("IsSpawnSource",true);root:SetAttribute("Active",true);root.Parent=floor.Model
  local pos=floor.Origin+s.Position
  local visual=Arena.Place("CoffeeSpawner",root,CFrame.new(pos),8,false)
  local cf,size=visual:GetBoundingBox()
  local hit=Instance.new("Part");hit.Name="SourceBody";hit.Size=size;hit.CFrame=cf;hit.Anchored=true;hit.Transparency=1;hit.CanTouch=false;hit.Parent=root;root.PrimaryPart=hit
  local lamp=Instance.new("PointLight");lamp.Color=Color3.fromRGB(115,255,170);lamp.Range=22;lamp.Brightness=2.5;lamp.Parent=hit
  FX.Particles(visual.PrimaryPart,Color3.fromRGB(92,184,130),7)
  local gui=Instance.new("BillboardGui");gui.Name="SourceStatus";gui.Size=UDim2.fromOffset(210,72);gui.StudsOffset=Vector3.new(0,5,0);gui.AlwaysOnTop=false;gui.MaxDistance=220;gui.Parent=hit
  local text=Instance.new("TextLabel");text.Size=UDim2.new(1,0,.7,0);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(224,238,218);text.TextStrokeTransparency=.35;text.TextSize=16;text.Font=Enum.Font.GothamBold;text.Parent=gui
  local bars={}
  for i=1,E.SourceLayers do local b=Instance.new("Frame");b.Size=UDim2.new(.28,0,.1,0);b.Position=UDim2.new(.055+(i-1)*.305,0,.82,0);b.BorderSizePixel=0;b.Parent=gui;table.insert(bars,b)end
  local data={Model=root,Position=pos,Layers=E.SourceLayers,Health=E.SourceLayerHealth,ShieldUntil=0,Label=text,Bars=bars,Light=lamp}
  active[root]=data;update(data)
 end
end
function Sources.Target(part)
 local p=part
 while p and p~=workspace do if active[p]then return p end;p=p.Parent end
end
function Sources.Damage(model,player,amount)
 local d=active[model];local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not enabled or not d or d.Layers<=0 or not h or h.Health<=0 or not root then return "Inactive"end
 if (root.Position-d.Position).Magnitude>E.SourceDamageRange then return "Range"end
 if Clock.Now()<d.ShieldUntil then return "Shield"end
 d.Health=math.max(0,d.Health-amount);model:SetAttribute("HitTime",workspace:GetServerTimeNow())
 if d.Health==0 then
  d.Layers-=1;d.Health=E.SourceLayerHealth;d.ShieldUntil=Clock.Now()+E.SourceShieldSeconds
  model:SetAttribute("BurstTime",workspace:GetServerTimeNow())
  if d.Layers==0 then progress.DestroyedSources+=1 end
  burst(d.Position,E.SourceBurstCount)
  if d.Layers>0 then
   local field=Instance.new("Part");field.Name="SourceShield";field.Shape=Enum.PartType.Ball;field.Size=Vector3.new(9,10,9);field.CFrame=model.PrimaryPart.CFrame;field.Anchored=true;field.CanCollide=false;field.CanQuery=false;field.CanTouch=false;field.Material=Enum.Material.ForceField;field.Color=Color3.fromRGB(85,184,255);field.Transparency=.65;field.Parent=model
   game:GetService("Debris"):AddItem(field,E.SourceShieldSeconds)
  else
   for _,x in model:GetDescendants()do if x:IsA("MeshPart")then x.Color=Color3.fromRGB(75,81,77)end end
  end
  update(d);return d.Layers==0 and "Destroyed"or "Broken"
 end
 update(d);return "Hit"
end
function Sources.Zones()
 local zones={}
 for _,d in active do if d.Layers>0 then table.insert(zones,{Id=d.Model.Name,Position=d.Position,Radius=38,EntryKind="Source",Weight=1})end end
 return zones
end
function Sources.Stop()enabled=false;for m in active do m:SetAttribute("Active",false)end end
return Sources
