-- Force the map failure boundary, ensuring respawn cannot start on an invalid reset.
local Map=require(game.ServerScriptService.Server.OfficeMap)
local D=require(game.ServerScriptService.Server.FloorDirector)
local state=game.ReplicatedStorage.RunState
local p=game.Players:GetPlayers()[1]
local original=Map.CreateFloor
local function waitFor(predicate)
	local limit=os.clock()+25
	repeat if predicate()then return end;task.wait(.05)until os.clock()>limit
	error("Recovery timeout")
end
local report={}
local ok,err=pcall(function()
	assert(state:GetAttribute("State")=="ChoosingWeapon")
	Map.CreateFloor=function()error("EXPECTED QA: injected floor1 generation failure")end
	assert(D.EndRun(p,"QARecovery"))
	waitFor(function()return state:GetAttribute("State")=="RunRecoveryFailed"end)
	p:LoadCharacterAsync();task.wait(.5)
	assert(state:GetAttribute("State")=="RunRecoveryFailed"and state:GetAttribute("RunActive")==false)
	report.RespawnCannotBypassFailure=true
	Map.CreateFloor=original
	local epoch=state:GetAttribute("RunEpoch")
	assert(D.StartRun(p,epoch));assert(not D.StartRun(p,epoch))
	waitFor(function()return state:GetAttribute("State")=="RunEnded"end)
	assert(not state:GetAttribute("RunActive"))
	assert(D.StartRun(p,epoch))
	assert(state:GetAttribute("State")=="ChoosingWeapon"and state:GetAttribute("Floor")==1)
	report.Retry=true;report.NoEarlyRun=true
end)
Map.CreateFloor=original
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
