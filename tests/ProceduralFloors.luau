-- Studio Server while idle. Not mapped into the shipping place. Returns a report.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Layout=require(game.ServerScriptService.Server.FloorLayout)
local Office=require(game.ServerScriptService.Server.OfficeMap)
local Progress=require(game.ServerScriptService.Server.EncounterProgress)
local function equal(a,b)
	if typeof(a)~=typeof(b) then return false end
	if type(a)~="table" then return a==b end
	for k,v in a do if not equal(v,b[k]) then return false end end
	for k in b do if a[k]==nil then return false end end
	return true
end
local report={Plans=0,Themes={},Macros={},Modes={},Examples={},Navigation={}}
for _,seed in {123456,246813,987654} do
	local sequential={}
	for n=1,200 do sequential[n]=Layout.Generate(seed,n) end
	for n=200,1,-1 do
		local p=Layout.Generate(seed,n); local ok,r=Layout.Validate(p)
		assert(ok,tostring(r)); assert(equal(p,sequential[n]),"Order-dependent plan")
		if n>1 then assert(p.Macro~=sequential[n-1].Macro,"Adjacent repeated macro") end
		report.Plans+=1; report.Themes[p.Theme]=true; report.Macros[p.Macro]=true; report.Modes[p.Encounter.Mode]=true
		if not report.Examples[p.Macro] then report.Examples[p.Macro]={Seed=seed,Floor=n,Theme=p.Theme} end
	end
end
for _,theme in Config.Run.Generation.Themes do assert(report.Themes[theme]) end
for _,macro in Config.Run.Generation.Macros do assert(report.Macros[macro]) end
for _,mode in Config.Run.Encounters.Modes do assert(report.Modes[mode]) end
-- Invalid graph/volume data must be rejected before construction.
do
	local p=Layout.Generate(123456,1); p.Edges[1].B="Missing"; assert(not Layout.Validate(p))
	p=Layout.Generate(123456,1); p.Nodes[2].X=p.Nodes[1].X; p.Nodes[2].Z=p.Nodes[1].Z; assert(not Layout.Validate(p))
end
-- Mandatory obligations, time, pressure and tactical retreat are separate gates.
do
	local p=Progress.New({Budget=2,Mode="Survival",Duration=1})
	Progress.Step(p,2,2,true,true,1.5,false); assert(not p.Complete and p.Pending==2)
	Progress.Spawned(p); Progress.Step(p,0,2,true,true,1.5,true); assert(not p.Complete)
	Progress.Requeue(p); assert(p.Pending==2 and p.Defeated==0)
	Progress.Spawned(p); Progress.Defeated(p); Progress.Spawned(p); Progress.Defeated(p)
	assert(Progress.Step(p,0,2,true,true,1.5,false))
	p=Progress.New({Budget=2,Mode="Holdout",Duration=2})
	Progress.Step(p,1,1,true,true,0,false); assert(p.Elapsed==0,"Empty holdout progress")
	Progress.Spawned(p); Progress.Step(p,1,2,false,true,0,true); assert(p.Elapsed==0,"Outside progress")
	Progress.Step(p,1,3,true,false,0,true); assert(p.Elapsed==0,"Failed-spawn progress")
	Progress.Step(p,1,4,true,true,0,true); assert(p.Elapsed==1)
	Progress.Step(p,1,5,false,true,0,true); assert(p.Elapsed==1,"Retreat erased progress")
	Progress.Step(p,1,6,true,true,0,true); assert(p.Elapsed==2 and not p.Complete)
	Progress.Defeated(p); Progress.Spawned(p); Progress.Defeated(p); assert(Progress.Step(p,0,7,true,true,0,false))
	p=Progress.New({Budget=1,Mode="Holdout",Duration=2}); Progress.Spawned(p); Progress.Defeated(p)
	Progress.EnsurePressure(p,3); assert(p.Budget==4 and p.Pending==3 and p.Defeated==1)
end
report.Obligations="Passed"
local holder=Instance.new("Folder",workspace); holder.Name="ProceduralFloorVerification"
local ok,message=pcall(function()
	for _,seed in {123456,246813} do for _,theme in Config.Run.Generation.Themes do for _,macro in Config.Run.Generation.Macros do
		local f=Office.CreateFloor({Run=holder,Seed=seed},8,4,{FullValidation=true,Override={Theme=theme,Macro=macro}})
		assert(f.Layout.Macro==macro,"Unexpected fallback: "..f.Model:GetAttribute("FallbackReason"))
		table.insert(report.Navigation,{Seed=seed,Theme=theme,Macro=macro,Checks=f.Model:GetAttribute("NavigationChecks"),Parts=f.Model:GetAttribute("PartCount"),BuildSeconds=f.Model:GetAttribute("BuildSeconds"),ValidationSeconds=f.Model:GetAttribute("ValidationSeconds")})
		f.Model:Destroy()
	end end end
end)
holder:Destroy(); assert(ok,message)
return report
