-- Authoring helper: run after Import 3D. Never run as game code.
local keys = {"Office","Medic","Firefighter","Builder","Courier","Security","Mechanic","Chef","Biker","Punk"}
local texture = "rbxassetid://101832083458462"
local AssetService=game:GetService("AssetService")
local function boneWorld(bone)
    local parent=bone.Parent
    return (parent:IsA("Bone") and boneWorld(parent) or parent.CFrame)*bone.CFrame
end
local heights = {Office=5.904,Medic=5.984,Firefighter=6.208,Builder=6.208,Courier=5.904,Security=6.208,Mechanic=5.904,Chef=6.528,Biker=6.112,Punk=5.904}
local function meshesIn(model)
    local meshes={}
    for _, item in ipairs(model:GetDescendants()) do if item:IsA("MeshPart") then table.insert(meshes,item) end end
    return meshes
end
local function bounds(model)
    local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
    for _, mesh in ipairs(meshesIn(model)) do
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local p=mesh.CFrame:PointToWorldSpace(mesh.Size*Vector3.new(x,y,z)/2)
            low=Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
            high=Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
        end end end
    end
    return low,high
end
local sources={}
local imported=assert(workspace:FindFirstChild("CityZombies_Roblox") or game.ServerStorage:FindFirstChild("CityZombies_Roblox"), "Import the corrected CityZombies_Roblox.fbx first")
for _, key in ipairs(keys) do
    for _, item in ipairs(imported:GetDescendants()) do
        if item:IsA("MeshPart") and item.Name=="Zombie_"..key then
            local model=item:FindFirstAncestorOfClass("Model")
            assert(model, "Missing imported model: "..key)
            sources[key]={Mesh=item}; break
        end
    end
    assert(sources[key], "Missing imported zombie: "..key)
end
local target=Instance.new("Folder"); target.Name="CityZombies_Prepared"; target.Parent=game.ServerStorage
local results={}
for _, key in ipairs(keys) do
    local source=sources[key]
    local model=Instance.new("Model"); model.Name="Zombie_"..key; model.Parent=target
    local root=Instance.new("Part"); root.Name="RootPart"; root.CFrame=source.Mesh.CFrame; root.Parent=model
    local mesh=source.Mesh:Clone(); mesh.Parent=model
    -- The combined import's shared scene root can offset bones from their meshes.
    -- Reconstruct each hierarchy from the uploaded mesh's own bind data, read-only.
    local bind=AssetService:CreateEditableMeshAsync(mesh.MeshContent)
    local byId,frames={},{}
    for _,id in ipairs(bind:GetBones()) do
        local bone=Instance.new("Bone"); bone.Name=bind:GetBoneName(id); byId[id]=bone; frames[id]=bind:GetBoneCFrame(id)
    end
    for id,bone in pairs(byId) do
        local parentId=bind:GetBoneParent(id)
        bone.Parent=byId[parentId] or mesh
        bone.CFrame=frames[parentId] and frames[parentId]:ToObjectSpace(frames[id]) or frames[id]
    end
    bind:Destroy()
    local motor=Instance.new("Motor6D"); motor.Name="VisualMesh"; motor.Part0=root; motor.Part1=mesh
    motor.C0=root.CFrame:ToObjectSpace(mesh.CFrame); motor.Parent=mesh
    assert(root and root:IsA("BasePart"), "Missing imported root: "..key)
    model.PrimaryPart=root
    local bones={}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("Bone") then bones[item.Name:gsub("^"..key.." ","")]=item; item.Transform=CFrame.identity end
    end
    for _, name in ipairs({"bip Head","bip Pelvis","bip L UpperArm","bip R UpperArm","bip L Foot","bip R Foot"}) do assert(bones[name], "Missing bone "..name) end
    local up=(boneWorld(bones["bip Head"]).Position-(boneWorld(bones["bip L Foot"]).Position+boneWorld(bones["bip R Foot"]).Position)/2).Unit
    local across=boneWorld(bones["bip L UpperArm"]).Position-boneWorld(bones["bip R UpperArm"]).Position
    local right=(across-up*across:Dot(up)).Unit
    local basis=CFrame.fromMatrix(Vector3.zero,right,up,right:Cross(up))
    local pivot=model:GetPivot()
    model:PivotTo(basis:Inverse()*pivot.Rotation)
    local low,high=bounds(model)
    model:ScaleTo(model:GetScale()*heights[key]/(high.Y-low.Y))
    low,high=bounds(model)
    model:PivotTo(model:GetPivot()+Vector3.new(-(low.X+high.X)/2,-low.Y,-(low.Z+high.Z)/2))
    -- Localize the shared import root without moving the mesh or its bind pose.
    root.CFrame=CFrame.new(0,3,0); root.Size=Vector3.new(.3,.3,.3)
    motor.C0=root.CFrame:ToObjectSpace(mesh.CFrame)
    local headPosition=boneWorld(bones["bip Head"]).Position
    assert(math.abs(headPosition.X)<.05 and math.abs(headPosition.Z)<.4 and headPosition.Y>4.5 and headPosition.Y<5, "Head bind position incorrect: "..key.." "..tostring(headPosition))
    local count=0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("LuaSourceContainer") then item:Destroy()
        elseif item:IsA("Bone") then count+=1
        elseif item:IsA("BasePart") then
            item.Anchored=true; item.CanCollide=false; item.CanTouch=false; item.CanQuery=false
            if item==root then item.Transparency=1 end
            if item:IsA("MeshPart") then
                item.Color=Color3.new(1,1,1); item.TextureID=texture
                local appearance=item:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
                appearance.ColorMap=texture; appearance.Parent=item
            end
        end
    end
    assert(count==16, "Incorrect bone count: "..key)
    table.insert(results,{name=model.Name,bones=count,height=heights[key],root=root.Name})
end
return results
