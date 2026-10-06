local Arena=require(game.ServerScriptService.Server.ArenaAssets)
local holder=Instance.new("Folder");holder.Name="OrientationQA";holder.Parent=workspace
local report={Assets=0,Cases=0,FlatMeshes={}}
for _,source in game.ReplicatedStorage.Assets.EnvironmentKit:GetChildren()do
 report.Assets+=1
 if source.PrimaryPart.Size.Y<.05 then table.insert(report.FlatMeshes,source.Name)end
 for _,yaw in {0,math.pi/2,math.pi}do
  local m=Arena.Place(source.Name,holder,CFrame.new(0,450,0)*CFrame.Angles(0,yaw,0),nil,false,3.5)
  local cf,size=m:GetBoundingBox();local expected=source.PrimaryPart.Size*3.5
  assert(cf.UpVector.Y>.999,source.Name.." upside down")
  assert(math.abs(cf.Position.Y-size.Y/2-450)<.01,source.Name.." incorrect ground")
  -- Roblox clamps very thin MeshParts to its minimum thickness when scaled.
  assert(math.abs(size.X-expected.X)<.02 and math.abs(size.Z-expected.Z)<.02 and math.abs(size.Y-expected.Y)<.055,source.Name.." incorrect scale")
  assert(m.PrimaryPart.TextureID=="rbxassetid://87744524834349",source.Name.." missing palette")
  report.Cases+=1;m:Destroy()
 end
end
for _,n in {"CoffeeSpawner","GroundCracks","GroundDebris"}do
 local source=game.ReplicatedStorage.Assets.ArenaKit:FindFirstChild(n)
 if source then local m=Arena.Place(n,holder,CFrame.new(0,450,0),n=="CoffeeSpawner"and 8 or .35,false);local cf=m:GetBoundingBox();assert(cf.UpVector.Y>.999,n.." inverted");m:Destroy()end
end
holder:Destroy()
return report
