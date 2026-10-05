-- Run in Studio Server while idle; this file is not mapped into the shipped game.
-- Returns reproducibility and navigation results. No gameplay configuration is changed.
local Layout=require(game.ServerScriptService.Server.FloorLayout)
local Office=require(game.ServerScriptService.Server.OfficeMap)
local Http=game:GetService("HttpService")
local Pathfinding=game:GetService("PathfindingService")
local signatures={}
for number=1,200 do
    local layout=Layout.Generate(123456,number)
    assert(not signatures[layout.Signature],"Repeated layout seed")
    signatures[layout.Signature]=true
    assert(Http:JSONEncode(layout)==Http:JSONEncode(Layout.Generate(123456,number)),"Seed is not reproducible")
    assert(#layout.Rooms>0,"No rooms")
end
local holder=Instance.new("Folder")
holder.Name="ProceduralFloorVerification"; holder.Parent=workspace
local report={}
local ok,message=pcall(function()
    for number=1,4 do
        local floor=Office.CreateFloor({Run=holder,Seed=123456},number,4)
        task.wait(.6) -- Allow the navigation mesh to include the new geometry.
        local passed=0
        for _,point in floor.Probes do
            local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
            path:ComputeAsync(floor.Entry.Position,point+Vector3.new(0,3,0))
            assert(path.Status==Enum.PathStatus.Success,"Unreachable probe on "..floor.Layout.Theme..": "..tostring(point))
            passed+=1
        end
        table.insert(report,{Theme=floor.Layout.Theme,Levels=floor.Layout.Upper and 2 or 1,Reachable=passed})
        floor.Model:Destroy()
    end
end)
holder:Destroy()
assert(ok,message)
return report