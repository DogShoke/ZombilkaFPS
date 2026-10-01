-- Sanitized visual asset snapshot; no imported scripts.
return function()
local n = {}
n[1] = Instance.new("Model")
n[2] = Instance.new("Model")
n[3] = Instance.new("Part")
n[4] = Instance.new("SpecialMesh")
n[5] = Instance.new("Part")
n[1].Name = "OfficeChairImport"
n[2].Name = "Office Chair"
n[2].Parent = n[1]
n[3].Name = "Part"
n[3].Size = Vector3.new(2,0.20000000298023224,2)
n[3].CFrame = CFrame.new(21.864280700683594,1.9009100198745728,-26.99090003967285,-0.9993752837181091,-0.0006580261397175491,-0.035323403775691986,-0.000652462593279779,0.9999995231628418,-0.0001689677155809477,0.03532329201698303,-0.00014584464952349663,-0.9993759393692017)
n[3].Color = Color3.new(0.06666667014360428,0.06666667014360428,0.06666667014360428)
n[3].Material = Enum.Material.Plastic
n[3].Transparency = 0
n[3].Reflectance = 0
n[3].Anchored = true
n[3].CanCollide = false
n[3].TopSurface = Enum.SurfaceType.Smooth
n[3].BottomSurface = Enum.SurfaceType.Smooth
n[3].Parent = n[2]
n[4].Name = "Mesh"
n[4].Scale = Vector3.new(1.5,1.5,1.5)
n[4].Offset = Vector3.new(0,0,0)
n[4].VertexColor = Vector3.new(1,1,1)
n[4].MeshType = Enum.MeshType.FileMesh
n[4].MeshId = "http://www.roblox.com/asset/?id=96065544"
n[4].TextureId = "http://www.roblox.com/asset/?id=96065600"
n[4].Parent = n[3]
n[5].Name = "Seat"
n[5].Size = Vector3.new(2,1.8000000715255737,2)
n[5].CFrame = CFrame.new(21.8502140045166,0.9000002145767212,-27.390636444091797,-0.9993757605552673,1.5456996038665238e-07,-0.03532087802886963,1.5342769188464445e-07,1,3.505072498910522e-08,0.03532087802886963,2.9609687146603392e-08,-0.9993757605552673)
n[5].Color = Color3.new(0.10588235408067703,0.16470588743686676,0.2078431397676468)
n[5].Material = Enum.Material.Plastic
n[5].Transparency = 1
n[5].Reflectance = 0
n[5].Anchored = false
n[5].CanCollide = true
n[5].TopSurface = Enum.SurfaceType.Weld
n[5].BottomSurface = Enum.SurfaceType.Weld
n[5].Parent = n[2]
return n[1]
end
