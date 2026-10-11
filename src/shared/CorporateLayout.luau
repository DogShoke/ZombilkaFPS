-- Fixed authored coordinates, not a generator. Ground Y is always zero locally.
local Layout = {
	Version = 2, HalfWidth = 160, HalfDepth = 160,
	Spawn = { X = 0, Z = 20 },
	ZoneRegions = {
		{ Id = "Parking", Label = "ПАРКОВКА", X = -106, Z = 0, Width = 104, Depth = 320 },
		{ Id = "Office", Label = "NORTHLINE / РЕСЕПШЕН", X = 0, Z = 0, Width = 108, Depth = 320 },
		{ Id = "Service", Label = "ТЕХНИЧЕСКИЙ БЛОК", X = 106, Z = 0, Width = 104, Depth = 320 },
	},
	Clusters = {
		{ Id="Reception", X=0, Z=-28, Purpose="Visible counter landmark with two open flanks", Slots={
			{"ReceptionWide",0,0,0,true},{"ReceptionCompact",-12,4,90,true},{"ReceptionCompact",12,4,-90,true},
			{"OfficeChair",0,5,0,false},{"LargePlant",-18,-5,0,false},{"LargePlant",18,-5,0,false} } },
		{ Id="CubiclesWest", X=-28, Z=-62, Purpose="Office bank with broad outer circulation", Slots={
			{"WorkstationBank4",0,0,90,true},{"WorkstationBank2",0,12,90,true},{"PartitionWide",6,0,90,true},
			{"TaskChairTeal",-5,0,90,false},{"TaskChairTeal",-5,12,90,false} } },
		{ Id="CubiclesEast", X=28, Z=-62, Purpose="Office bank with broad outer circulation", Slots={
			{"WorkstationBank4",0,0,-90,true},{"WorkstationBank2",0,12,-90,true},{"PartitionWide",-6,0,90,true},
			{"TaskChairTeal",5,0,-90,false},{"TaskChairTeal",5,12,-90,false} } },
		{ Id="Lounge", X=0, Z=60, Purpose="Low cover island with left and right rotations", Slots={
			{"TwoSeatSofa",-10,0,90,true},{"TwoSeatSofa",10,0,-90,true},{"CoffeeTable",0,0,0,true},
			{"LargePlant",-16,8,0,false},{"LargePlant",16,8,0,false} } },
		{ Id="ArchiveWest", X=-28, Z=122, Purpose="South office hard-cover landmark", Slots={
			{"ArchiveCabinetBank",0,0,0,true},{"FilingCabinet",-10,0,0,true} } },
		{ Id="ArchiveEast", X=28, Z=122, Purpose="South office hard-cover landmark", Slots={
			{"ArchiveCabinetBank",0,0,0,true},{"FilingCabinet",10,0,0,true} } },
		{ Id="ParkingNorth", X=-104, Z=-44, Purpose="Four parked cars; parallel drive-through aisles", Slots={
			{"ArenaCar",-12,-13,0,true},{"ArenaCar",12,-13,180,true},
			{"ArenaCar",-12,13,0,true},{"ArenaCar",12,13,180,true},
			{"ParkingColumn",-28,0,0,true},{"ParkingColumn",28,0,0,true} } },
		{ Id="ParkingSouth", X=-104, Z=44, Purpose="Second car bank defines a parking rotation loop", Slots={
			{"ArenaCar",-12,-13,0,true},{"ArenaCar",12,-13,180,true},
			{"ArenaCar",-12,13,0,true},{"ArenaCar",12,13,180,true},
			{"ParkingColumn",-28,0,0,true},{"ParkingColumn",28,0,0,true} } },
		{ Id="ParkingSecurity", X=-104, Z=-126, Purpose="Arrival booth and vehicle entry landmark", Slots={
			{"SecurityBooth",0,0,0,true},{"ParkingPaymentKiosk",13,0,0,true},
			{"ConcreteBarrierLong",-18,0,0,true},{"ParkingSign",22,0,0,false} } },
		{ Id="ParkingExit", X=-104, Z=126, Purpose="Low barrier bay; north/south routes stay open", Slots={
			{"JerseyBarrierLong",-12,0,0,true},{"JerseyBarrierLong",12,0,0,true} } },
		{ Id="ServiceNorth", X=104, Z=-44, Purpose="Server bank with wide routes outside and between rows", Slots={
			{"ServerRackTwin",-12,-8,0,true},{"ServerRackTwin",12,-8,0,true},
			{"ServerRackTwin",-12,8,180,true},{"ServerRackTwin",12,8,180,true},
			{"UPSUnit",-22,0,0,true},{"SecurityDesk",22,0,90,true} } },
		{ Id="ServiceSouth", X=104, Z=44, Purpose="Technical equipment station with exterior flanks", Slots={
			{"ArenaRack",-14,0,0,true},{"ArenaLabBank",12,0,180,true},
			{"ServerRackCompact",-14,13,180,true},{"ServiceFlatbedCart",12,13,90,true} } },
		{ Id="Loading", X=104, Z=-126, Purpose="Hard loading landmark without a dead-end room", Slots={
			{"ArenaContainer",0,0,90,true},{"ArenaBarrier",24,0,0,true} } },
		{ Id="Utility", X=104, Z=126, Purpose="Service counter marks southern route", Slots={
			{"KitchenCounterWide",-8,0,0,true},{"ServerRackTwin",8,0,0,true} } },
	},
	-- All lane disks lie in broad open circulation, never on prop islands.
	SpawnLanes = {
		{"NW",-140,-140,"North"},{"NOffice",0,-140,"North"},{"NE",140,-140,"North"},
		{"WestNorth",-140,-92,"West"},{"NorthWestCross",-56,-92,"North"},
		{"NorthEastCross",56,-92,"North"},{"EastNorth",140,-92,"East"},
		{"West",-140,0,"West"},{"WestCross",-56,0,"West"},
		{"EastCross",56,0,"East"},{"East",140,0,"East"},
		{"WestSouth",-140,92,"West"},{"SouthWestCross",-56,92,"South"},
		{"SouthEastCross",56,92,"South"},{"EastSouth",140,92,"East"},
		{"SW",-140,140,"South"},{"SOffice",0,140,"South"},{"SE",140,140,"South"},
	},
	ShopSites = { {Id="LobbyVending", X=38, Z=30}, {Id="ServiceVending", X=130, Z=112} },
	-- Visible maintenance surfaces make the narrow imported rack roofs accessible
	-- to ordinary NPCs. Both ends have broad, shallow no-jump approaches.
	MaintenanceDecks = {
		{Id="ServerMaintenance", Cluster="ServiceNorth", Asset="ServerRackTwin", X=104, Z=-44, Width=36, Depth=24, RampWidth=12, RampLength=22},
		{Id="LoadingAccess", Cluster="Loading", Asset="ArenaContainer", X=104, Z=-126, Width=18, Depth=12, RampWidth=12, RampLength=20},
	},
}

-- Explicit navigation line network: coordinates remain reproducible across runs.
local nodes, edges = {}, {}
for row, z in {-92,0,92} do
	for column, x in {-140,-56,0,56,140} do
		local id=string.format("Route%d_%d",row,column)
		table.insert(nodes,{Id=id,X=x,Y=0,Z=z})
		if column>1 then table.insert(edges,{From=string.format("Route%d_%d",row,column-1),To=id,Width=20}) end
		-- The centre has reception/lounge islands; longitudinal rotation uses
		-- their broad exterior flanks, never a fictitious path through a counter.
		if row>1 and column~=3 then table.insert(edges,{From=string.format("Route%d_%d",row-1,column),To=id,Width=20}) end
	end
end
table.insert(nodes,{Id="Entry",X=0,Y=0,Z=20})
table.insert(edges,{From="Route2_3",To="Entry",Width=20})
Layout.NavGraph={Nodes=nodes,Edges=edges}
return Layout
