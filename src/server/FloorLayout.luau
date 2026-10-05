-- Versioned, pure combat plan. Coordinates are local to a physical floor slot.
local Config = require(game.ReplicatedStorage.Shared.Config)
local G, E = Config.Run.Generation, Config.Run.Encounters
local Layout = {}
local labels = { Office="ОФИСЫ", Laboratory="ЛАБОРАТОРИИ", Warehouse="СКЛАД", Parking="ПАРКИНГ" }
local macroLabels = { LoopDefense="ОБХОДНОЕ КОЛЬЦО", HubAndWings="ЗАЛ И КРЫЛЬЯ", TwoFronts="ДВА ФРОНТА", Crossfire="ПЕРЕКРЁСТОК", SplitLevel="ДВА УРОВНЯ", WarehouseLanes="ПОЛОСЫ ОБОРОНЫ" }
local function shuffled(list, seed)
	local result, rng = table.clone(list), Random.new(seed)
	for i=#result,2,-1 do local j=rng:NextInteger(1,i); result[i],result[j]=result[j],result[i] end
	return result
end
local function macroAt(seed, number)
	local early=shuffled(G.EarlyMacros,seed+G.Version*701)
	if number<=G.EarlyFloors then return early[(number-1)%#early+1] end
	local order=shuffled(G.Macros,seed+G.Version*1307)
	local offset=order[1]==early[(G.EarlyFloors-1)%#early+1] and 1 or 0
	return order[(number-G.EarlyFloors-1+offset)%#order+1]
end
function Layout.Generate(runSeed, number, attempt, override)
	attempt=attempt or 1
	local seed=(runSeed+number*104729+G.Version*1009+(attempt-1)*7919)%2147483647
	local macroRng, interiorRng, fightRng=Random.new(seed),Random.new((seed+73819)%2147483647),Random.new((seed+193939)%2147483647)
	local themes=shuffled(G.Themes,runSeed)
	local theme=override and override.Theme or themes[(number-1)%#themes+1]
	local macro=override and override.Macro or macroAt(runSeed,number)
	local mirror=override and override.Fixed and 1 or (macroRng:NextInteger(0,1)==0 and -1 or 1)
	local nodes,edges,byId={},{},{}
	local function node(id,x,z,w,d,tags,y)
		local n={Id=id,X=x*mirror,Z=z,Y=y or 0,Width=w,Depth=d,Tags=tags or {"Connector"}}
		byId[id]=n; table.insert(nodes,n); return n
	end
	local function edge(a,b,points,width)
		local p={Vector3.new(byId[a].X,byId[a].Y,byId[a].Z)}
		for _,v in points or {} do table.insert(p,Vector3.new(v[1]*mirror,v[3] or 0,v[2])) end
		table.insert(p,Vector3.new(byId[b].X,byId[b].Y,byId[b].Z))
		table.insert(edges,{Id=a.."_"..b,A=a,B=b,Width=width or G.CorridorWidth,Points=p,State="Open"})
	end
	node("Entry",0,108,48,36,{"Entry","RetreatRoute"})
	local defenseIds
	if macro=="LoopDefense" then
		node("A",-60,48,60,48,{"Combat","DefensePosition"}); node("B",60,-48,60,60,{"Combat","DefensePosition"})
		node("West",-96,-48,36,36,{"FlankRoute"}); node("North",0,-96,48,36,{"Combat","Connector"}); node("East",96,48,36,36,{"RetreatRoute"})
		edge("Entry","A",{{-60,108}}); edge("A","West",{{-96,48}},G.ChokeWidth)
		edge("West","North",{{-96,-96}}); edge("North","B",{{60,-96}})
		edge("B","East",{{96,-48}}); edge("East","Entry",{{96,108}})
		if not (override and override.Fixed) and macroRng:NextNumber()<.5 then edge("A","B",{{0,48},{0,-48}},G.ChokeWidth) end
		defenseIds={"A","B"}
	elseif macro=="HubAndWings" then
		node("Hub",0,24,72,60,{"Combat","DefensePosition"}); node("West",-84,24,48,48,{"Combat"}); node("East",84,24,48,48,{"Combat"})
		node("North",0,-84,60,48,{"Combat","DefensePosition"}); node("NW",-84,-84,36,36,{"FlankRoute"}); node("NE",84,-84,36,36,{"RetreatRoute"})
		edge("Entry","Hub"); edge("Hub","West",nil,G.ChokeWidth); edge("Hub","East"); edge("Hub","North",nil,G.ChokeWidth)
		edge("West","NW"); edge("NW","North"); edge("North","NE"); edge("NE","East")
		defenseIds={"Hub","North"}
	elseif macro=="TwoFronts" then
		node("A",-60,48,60,60,{"Combat","DefensePosition"}); node("B",60,-48,60,60,{"Combat","DefensePosition"})
		node("Back",-84,-84,48,36,{"FlankRoute"}); node("Side",84,48,36,48,{"RetreatRoute"})
		edge("Entry","A",{{-60,108}}); edge("A","B",{{0,48},{0,-48}})
		edge("A","Back",{{-84,48}},G.ChokeWidth); edge("Back","B",{{60,-84}})
		edge("B","Side",{{84,-48}},G.ChokeWidth); edge("Side","Entry",{{84,108}})
		defenseIds={"A","B"}
	elseif macro=="Crossfire" then
		local offset=macroRng:NextInteger(0,1)==0 and -12 or 12
		node("Cross",offset,0,60,60,{"Combat","DefensePosition"}); node("West",-96,0,36,48,{"Combat"}); node("East",84,0,48,48,{"Combat"})
		node("North",offset,-96,48,36,{"Combat"}); node("South",offset,72,48,36,{"RetreatRoute"}); node("Bypass",84,-96,36,36,{"FlankRoute","DefensePosition"})
		edge("Entry","South",{{offset,108}}); edge("South","Cross"); edge("Cross","West",nil,G.ChokeWidth)
		edge("Cross","East"); edge("Cross","North",nil,G.ChokeWidth); edge("North","Bypass"); edge("Bypass","East")
		defenseIds={"Cross","Bypass"}
	elseif macro=="SplitLevel" then
		node("Lower",-60,0,72,72,{"Combat","DefensePosition"}); node("Front",0,-96,60,36,{"Combat"})
		node("NorthRamp",84,-84,36,24,{"Connector"}); node("SouthRamp",84,84,36,24,{"Connector"})
		node("Retreat",-84,84,36,24,{"RetreatRoute"}); node("West",-84,-84,36,24,{"FlankRoute"})
		node("Upper",84,0,72,64,{"Combat","DefensePosition"},G.UpperHeight)
		node("Under",84,0,72,64,{"Connector","RetreatRoute"})
		edge("Entry","Retreat",{{-84,108}}); edge("Retreat","Lower",{{-84,0}})
		edge("Lower","West",{{-84,0}}); edge("West","Front",{{0,-84}})
		edge("Front","NorthRamp",{{84,-96}}); edge("SouthRamp","Entry",{{84,108}})
		edge("NorthRamp","Upper",{{84,-32,G.UpperHeight}}); edge("Upper","SouthRamp",{{84,32,G.UpperHeight}})
		edge("NorthRamp","Under",{{108,-84},{108,0}},G.ChokeWidth); edge("Under","SouthRamp",{{108,0},{108,84}},G.ChokeWidth)
		defenseIds={"Lower","Upper"}
	else -- WarehouseLanes
		node("South",0,72,72,36,{"Combat","DefensePosition"}); node("North",0,-84,72,48,{"Combat","DefensePosition"})
		node("West",-84,0,36,36,{"FlankRoute"}); node("East",84,0,36,36,{"RetreatRoute"}); node("Center",0,0,36,36,{"Combat"})
		edge("Entry","South"); edge("South","West",{{-84,72}}); edge("West","North",{{-84,-84}})
		edge("South","East",{{84,72}}); edge("East","North",{{84,-84}})
		edge("South","Center",nil,G.ChokeWidth); edge("Center","North",nil,G.ChokeWidth)
		if macroRng:NextNumber()<.5 then edge("West","Center"); edge("Center","East") end
		defenseIds={"South","North"}
	end
	local defenses={}
	for i,id in defenseIds do
		local n=byId[id]; table.insert(defenses,{Id="Defense_"..id,Label="ПОЗИЦИЯ "..i,NodeId=id,Position=Vector3.new(n.X,n.Y,n.Z),Width=math.min(n.Width-8,40),Depth=math.min(n.Depth-8,40)})
	end
	local spawnZones={}
	for _,n in nodes do
		if n.Id~="Entry" and n.Id~="Upper" then
			local direction=math.abs(n.X)>math.abs(n.Z) and (n.X<0 and "West" or "East") or (n.Z<0 and "North" or "South")
			for i,dx in {-6,6} do table.insert(spawnZones,{Id=n.Id.."_"..i,NodeId=n.Id,AttackDirection=direction,EntryKind=n.Id:find("Ramp") and "UpperApproach" or "SideRoom",Position=Vector3.new(n.X+dx,n.Y,n.Z),Weight=1,AllowedPhases={1,2,3}}) end
		end
	end
	local present={}; for _,s in spawnZones do present[s.AttackDirection]=true end
	local sectors={}; for _,sector in E.Sectors do if present[sector] then table.insert(sectors,sector) end end
	sectors=shuffled(sectors,fightRng:NextInteger(1,2000000000))
	local mode=number<E.SpecialModesFromFloor and "ClearWaves" or E.Modes[fightRng:NextInteger(1,#E.Modes)]
	local phases={}
	for i,base in Config.Run.Waves do
		local fronts={sectors[(i-1)%#sectors+1]}
		if i==#Config.Run.Waves or (number>G.EarlyFloors and i==2) then table.insert(fronts,sectors[i%#sectors+1]) end
		local fallback={}; for _,sector in sectors do if not table.find(fronts,sector) then table.insert(fallback,sector) end end
		local phaseMode=i==#Config.Run.Waves and mode or "ClearWaves"
		local defense=defenses[fightRng:NextInteger(1,#defenses)]
		local budget=base+math.min((number-1)*Config.Run.Difficulty.ExtraPerWavePerFloor,Config.Run.Difficulty.MaxExtraPerWave)
		local d=Config.Run.Difficulty
		local maxAlive=math.min(d.BaseAlive+math.floor((number-1)/d.ExtraAliveEvery),d.MaxAlive)
		local reserve=fallback[1] and math.clamp(E.FlankReserve,0,math.min(budget-1,maxAlive-1)) or 0
		table.insert(phases,{Id=i,Budget=budget,Directions=fronts,FallbackDirections=fallback,ScheduledDirection=reserve>0 and fallback[1] or nil,Reserve=reserve,Mode=phaseMode,Duration=phaseMode=="Holdout" and E.HoldSeconds or phaseMode=="Survival" and E.SurvivalSeconds or 0,DefenseId=defense.Id,DefenseLabel=defense.Label})
	end
	local rooms={}
	local kinds=theme=="Office" and {"Workstations","Meeting","BreakRoom","Archive"} or theme=="Laboratory" and {"Lab","ServerRoom","Storage"} or theme=="Warehouse" and {"Storage","Workshop","Archive"} or {"ParkingBay","Workshop","Storage"}
	for _,n in nodes do
		if n.Id~="Entry" and n.Id~="Under" and n.Width>=36 and n.Depth>=36 then table.insert(rooms,{Id=n.Id,X=n.X,Z=n.Z,Y=n.Y,Width=n.Width,Depth=n.Depth,Kind=kinds[interiorRng:NextInteger(1,#kinds)],Variant=interiorRng:NextInteger(1,4)}) end
	end
	local landmarkId=defenseIds[macro=="WarehouseLanes" and 2 or 1]
	table.insert(byId[landmarkId].Tags,"Landmark")
	return {GenerationVersion=G.Version,RunSeed=runSeed,Seed=seed,Number=number,Attempt=attempt,Theme=theme,Label=labels[theme],Macro=macro,MacroLabel=macroLabels[macro],StartNode="Entry",Nodes=nodes,Edges=edges,DefenseZones=defenses,Landmarks={{Id="Main",NodeId=landmarkId,Theme=theme}},SpawnZones=spawnZones,Encounter={Mode=mode,Phases=phases},Rooms=rooms,Upper=macro=="SplitLevel",UpperSide=mirror,AccentIndex=interiorRng:NextInteger(1,4),Signature=string.format("v%d:%s:%s:%d:%d",G.Version,theme,macro,seed,attempt)}
end
function Layout.Validate(plan)
	if not table.find(G.Macros,plan.Macro) or not table.find(G.Themes,plan.Theme) then return false,"Unknown theme/macro" end
	local nodes,adj,combat={}, {},0
	for _,n in plan.Nodes do
		if nodes[n.Id] then return false,"Duplicate node "..n.Id end
		if math.abs(n.X)+n.Width/2>G.HalfWidth or math.abs(n.Z)+n.Depth/2>G.HalfDepth then return false,"Node outside floor "..n.Id end
		nodes[n.Id]=n; adj[n.Id]={}
		if table.find(n.Tags,"Combat") then combat+=1 end
	end
	if not nodes[plan.StartNode] then return false,"Missing entry" end
	for i,a in plan.Nodes do for j=i+1,#plan.Nodes do local b=plan.Nodes[j]
		if a.Y==b.Y and math.abs(a.X-b.X)<(a.Width+b.Width)/2-.01 and math.abs(a.Z-b.Z)<(a.Depth+b.Depth)/2-.01 then return false,"Overlapping nodes "..a.Id.."/"..b.Id end
	end end
	local ids={}
	for _,e in plan.Edges do
		if ids[e.Id] or not nodes[e.A] or not nodes[e.B] or e.A==e.B or e.Width<G.AgentRadius*2+4 or e.State~="Open" then return false,"Invalid edge "..e.Id end
		local a,b=nodes[e.A],nodes[e.B]
		if e.Points[1]~=Vector3.new(a.X,a.Y,a.Z) or e.Points[#e.Points]~=Vector3.new(b.X,b.Y,b.Z) then return false,"Broken endpoints "..e.Id end
		for i,p in e.Points do
			if math.abs(p.X)+e.Width/2>G.HalfWidth or math.abs(p.Z)+e.Width/2>G.HalfDepth then return false,"Edge outside floor "..e.Id end
			if i>1 then local prev=e.Points[i-1]; if prev.X~=p.X and prev.Z~=p.Z then return false,"Diagonal corridor "..e.Id end end
		end
		ids[e.Id]=true; table.insert(adj[e.A],e.B); table.insert(adj[e.B],e.A)
	end
	local seen={[plan.StartNode]=true}; local queue={plan.StartNode}
	for _,id in queue do for _,to in adj[id] do if not seen[to] then seen[to]=true; table.insert(queue,to) end end end
	for id in nodes do if not seen[id] then return false,"Disconnected "..id end end
	if #plan.Edges<#plan.Nodes then return false,"No loop" end
	if #plan.DefenseZones<2 or combat<2 then return false,"Missing combat/defense positions" end
	local defenseIds={}
	for _,d in plan.DefenseZones do if defenseIds[d.Id] or not nodes[d.NodeId] or #adj[d.NodeId]<2 then return false,"Isolated defense "..d.Id end; defenseIds[d.Id]=true end
	if #plan.Landmarks<1 then return false,"Missing landmark" end
	for _,l in plan.Landmarks do if not nodes[l.NodeId] then return false,"Invalid landmark" end end
	local spawnIds={}
	for _,s in plan.SpawnZones do
		local n=nodes[s.NodeId]
		if spawnIds[s.Id] or not n or not table.find(E.Sectors,s.AttackDirection) or s.Weight<=0 then return false,"Invalid spawn "..s.Id end
		if math.abs(s.Position.X-n.X)>n.Width/2 or math.abs(s.Position.Z-n.Z)>n.Depth/2 or s.Position.Y~=n.Y then return false,"Spawn outside node "..s.Id end
		spawnIds[s.Id]=true
	end
	for _,p in plan.Encounter.Phases do
		if p.Budget<1 or p.Budget%1~=0 or not table.find(E.Modes,p.Mode) or not defenseIds[p.DefenseId] or (p.Mode~="ClearWaves" and p.Duration<=0) then return false,"Invalid phase" end
		for _,sector in p.Directions do local found=false; for _,s in plan.SpawnZones do if s.AttackDirection==sector and table.find(s.AllowedPhases,p.Id) then found=true break end end; if not found then return false,"No spawn sector "..sector end end
	end
	return true
end
return Layout
