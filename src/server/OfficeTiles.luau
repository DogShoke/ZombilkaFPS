-- Authored 36-stud combat tiles. Slots are fixed; randomness selects whole variants.
local Tiles={}
Tiles.Variants={
 OPEN={{Id="Clear",Width=24,Depth=24,Purpose="Open movement and firing lane",Class="Open",Slots={}},
       {Id="Carpet",Width=24,Depth=24,Purpose="Open circulation with floor finish",Class="Open",FloorPatch=true,Slots={}}},
 COVER={
  {Id="DeskIsland",Width=24,Depth=24,Purpose="Cubicle island with four exterior rotations",Class="Medium",Slots={
   {"WorkstationBank4",0,-4,0,true},{"WorkstationBank2",0,5,180,true},
   {"PartitionWide",0,0,0,true},{"FilingCabinet",-9,-3,0,true},{"LowCabinet",9,3,0,true},
   {"TaskChairTeal",-3,-8,0,false},{"TaskChairTeal",3,-8,0,false},
   {"OfficeChair",-3,9,180,false},{"OfficeChair",3,9,180,false},{"SmallPlant",-9,8,0,false}}},
  {Id="Reception",Width=24,Depth=24,Purpose="Counter protection with two open flanks",Class="Medium",Slots={
   {"ReceptionWide",0,-4,0,true},{"LowCabinet",-5,5,0,true},{"LowCabinet",5,5,0,true},
   {"PartitionWide",-9,1,90,true},{"OfficeChair",0,1,0,false},{"LargePlant",9,7,0,false}}},
  {Id="ServerStation",Width=24,Depth=24,Purpose="Technical sight blocker with wide outside paths",Class="Hard",Slots={
   {"ServerRackTwin",-3,-5,0,true},{"ServerRackTwin",3,-5,0,true},
   {"ServerRackCompact",-7,3,90,true},{"SecurityDesk",2,5,180,true},
   {"OfficeChair",2,1,0,false},{"UPSUnit",-3,5,0,true},{"SmallPlant",9,6,0,false}}},
  {Id="BreakArea",Width=24,Depth=24,Purpose="Lounge and office service position",Class="Low",Slots={
   {"TwoSeatSofa",-5,3,90,true},{"TwoSeatSofa",5,3,-90,true},{"CoffeeTable",0,3,0,true},
   {"DrinkVending",-5,-7,0,true},{"KitchenCounterWide",3,-7,0,true},{"LargePlant",9,7,0,false}}}},
 HARD_COVER={
  {Id="ArchiveBlock",Width=24,Depth=24,Purpose="Office archive that breaks sight while exterior lanes remain open",Class="Hard",Slots={
   {"ArchiveCabinetBank",0,-4,0,true},{"ArchiveCabinetBank",0,4,180,true},
   {"FilingCabinet",-8,0,0,true},{"FilingCabinet",8,0,0,true}}},
  {Id="ServerBlock",Width=24,Depth=24,Purpose="Large technical blocker with four exterior approaches",Class="Hard",Slots={
   {"ServerRackTwin",-3,-4,0,true},{"ServerRackTwin",3,-4,0,true},
   {"ServerRackTwin",-3,4,180,true},{"ServerRackTwin",3,4,180,true}}}},
 LANDMARK={
  {Id="OfficeReception",Width=24,Depth=24,Purpose="Visible reception landmark with open side approaches",Class="Medium",Sign="ZOMBILKA  /  RECEPTION",Slots={
   {"ReceptionWide",0,-3,0,true},{"ReceptionCompact",-8,4,90,true},{"ReceptionCompact",8,4,-90,true},
   {"OfficeChair",0,2,0,false},{"LargePlant",-9,-8,0,false},{"LargePlant",9,-8,0,false}}},
  {Id="ReceptionLounge",Width=24,Depth=24,Purpose="Reception and meeting point visible from the entrance",Class="Medium",Sign="ZOMBILKA  /  RECEPTION",Slots={
   {"ReceptionWide",0,-4,0,true},{"TwoSeatSofa",-6,5,90,true},{"TwoSeatSofa",6,5,-90,true},
   {"CoffeeTable",0,5,0,true},{"LargePlant",-9,-8,0,false},{"LargePlant",9,-8,0,false}}}},
 ELEVATED={{Id="RaisedWorkstation",Width=16,Depth=30,Purpose="Small height advantage with two broad ramps",Class="Low",Elevation={Width=16,Depth=10,Height=6,RampWidth=16,RampLength=10},Slots={
  {"OfficeDesk",0,-2,0,true},{"SmallPlant",-6,0,0,false},{"SmallPlant",6,0,0,false}}}},
 START={{Id="ElevatorLanding",Width=24,Depth=24,Purpose="Clear entrance and view into the arena",Class="Open",Slots={}}},
 SPAWN_EDGE={{Id="EdgeLane",Width=24,Depth=24,Purpose="Clear telegraphed corner approach",Class="Open",Slots={}},
             {Id="CrackedEdge",Width=24,Depth=24,Purpose="Infected edge with an unobstructed approach",Class="Open",Cracks=true,Slots={}}},
}
function Tiles.Get(role,id)
 for _,variant in Tiles.Variants[role]or{}do if variant.Id==id then return variant end end
 error("Unknown authored tile "..tostring(role).."/"..tostring(id))
end
function Tiles.Select(role,rng,fixed)
 local list=Tiles.Variants[role];return list[fixed and 1 or rng:NextInteger(1,#list)]
end
return Tiles
