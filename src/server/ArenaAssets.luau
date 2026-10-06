local Assets=game.ReplicatedStorage:WaitForChild("Assets")
local Arena={}
function Arena.Place(name,parent,cf,height,collision,studsPerMeter)
 local kit=Assets:FindFirstChild("ArenaKit")
 local environment=Assets:FindFirstChild("EnvironmentKit")
 local source=(environment and environment:FindFirstChild(name))or(kit and kit:FindFirstChild(name))
 assert(source,"Missing imported arena asset: "..name)
 local model=source:Clone();model.Name=name;model.Parent=parent
 -- FBX import can leave a rotated/off-centre PivotOffset even when the mesh
 -- itself is already Y-up. Never treat that editor pivot as the asset's axes.
 for _,p in model:GetDescendants()do if p:IsA("BasePart")then p.PivotOffset=CFrame.identity end end
 local box,size=model:GetBoundingBox()
 if height then model:ScaleTo(model:GetScale()*height/size.Y)
 elseif studsPerMeter then model:ScaleTo(model:GetScale()*studsPerMeter)end
 box,size=model:GetBoundingBox()
 local ground=box*CFrame.new(0,-size.Y/2,0)
 model:PivotTo(cf*ground:ToObjectSpace(model:GetPivot()))
 for _,p in model:GetDescendants()do if p:IsA("BasePart")then p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false end end
 if collision then
  -- Convex practical hit/collision hull, sized to the actual mesh, never a visual substitute.
  local bounds,dimensions=model:GetBoundingBox()
  local hull=Instance.new("Part");hull.Name="CoverCollision";hull.Size=dimensions;hull.CFrame=bounds;hull.Anchored=true;hull.Transparency=1;hull.CanTouch=false;hull.Parent=model
 end
 return model
end
return Arena
