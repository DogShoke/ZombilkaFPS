-- Native Script in Studio Play only. Accelerates timings; Stop restores all runtime changes.
-- Start while ChoosingWeapon, then click a weapon card. Never put this in the shipped tree.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Director=require(game.ServerScriptService.Server.FloorDirector)
local Zombies=require(game.ServerScriptService.Server.ZombieService)
local Layout=require(game.ServerScriptService.Server.FloorLayout)
local Clock=require(game.ServerScriptService.Server.RunClock)
local player=game.Players:GetPlayers()[1]
local state=game.ReplicatedStorage.RunState
local report={Transitions={},PendingGuard=false,NoSpawnDebt=false,RecoveryDebt=false,Holdout=false,Survival=false,DeathReset=false}
local function waitFor(predicate,seconds)
	local endTime=os.clock()+seconds
	repeat if predicate() then return end; task.wait(.05) until os.clock()>endTime
	error("Runtime QA timeout: "..tostring(state:GetAttribute("State")).." floor="..tostring(state:GetAttribute("Floor")))
end
local originalGenerate=Layout.Generate
local originals={}
local function tune(t,key,value) table.insert(originals,{Table=t,Key=key,Value=t[key]}); t[key]=value end
tune(Config.Run,"IntroDuration",.1); tune(Config.Run,"BetweenWaves",.1); tune(Config.Run,"SpawnInterval",.04)
tune(Config.Run,"DoorDuration",.1); tune(Config.Run,"TravelDuration",.15); tune(Config.Run.Encounters,"WarningDuration",.1)
tune(Config.Run.Encounters,"FlankAfter",.2)
-- Exercise both profiles in the actual director, independent of this random run's choices.
Layout.Generate=function(seed,number,...)
	local p=originalGenerate(seed,number,...)
	if number==4 or number==5 then
		local mode=number==4 and "Holdout" or "Survival"
		p.Encounter.Mode=mode; local final=p.Encounter.Phases[#p.Encounter.Phases]
		final.Mode=mode; final.Duration=.5
	end
	return p
end
local ok,err=pcall(function()
	waitFor(function() return player.Character and player.Character:FindFirstChild("Humanoid") end,15)
	player.Character.Humanoid.MaxHealth=100000; player.Character.Humanoid.Health=100000
	waitFor(function() return state:GetAttribute("State")=="WaveActive" end,30)
	assert(not Director.TryTravel(player)); report.PendingGuard=true
	local before=state:GetAttribute("Pending"); local min=Config.Zombies.MinSpawnDistance
	Config.Zombies.MinSpawnDistance=1000; task.wait(.3)
	assert(state:GetAttribute("Pending")==before and not state:GetAttribute("FloorComplete")); report.NoSpawnDebt=true
	Config.Zombies.MinSpawnDistance=min
	local recovered,checkedSurvival=false,false
	local limit=os.clock()+240
	while state:GetAttribute("Floor")<6 do
		assert(os.clock()<limit,"Sequence timeout")
		local phase,mode=state:GetAttribute("State"),state:GetAttribute("EncounterMode")
		local character=player.Character; local root=character.HumanoidRootPart
		local number=state:GetAttribute("Floor")
		local floor=workspace.OfficeRun:FindFirstChild(string.format("Floor%03d",number))
		if phase=="WaveActive" then
			local elapsed,duration=state:GetAttribute("ObjectiveElapsed"),state:GetAttribute("ObjectiveDuration")
			local hold=mode=="Holdout" and elapsed<duration
			if hold then
				local area=floor.Props:FindFirstChildWhichIsA("Part")
				for _,p in floor.Props:GetChildren() do if p.Name=="DefenseArea_"..state:GetAttribute("DefenseId") then area=p break end end
				character:PivotTo(CFrame.new(area.Position+Vector3.new(0,3,0))*CFrame.Angles(0,math.pi,0))
			else character:PivotTo(CFrame.new(0,root.Position.Y,110)*CFrame.Angles(0,math.pi,0)) end
			if mode=="Survival" and elapsed>=duration and state:GetAttribute("Alive")>0 and not checkedSurvival then
				assert(not Director.TryTravel(player)); checkedSurvival=true; report.Survival=true
			end
			if mode=="Holdout" and elapsed>=duration then report.Holdout=true end
			local kill=not hold and (mode~="Survival" or elapsed>=duration)
			for _,m in workspace:GetChildren() do if m:GetAttribute("IsZombie") and not m:GetAttribute("Dead") then
				if not recovered then
					local kills=state:GetAttribute("Defeated"); m:Destroy(); Zombies.Count()
					assert(Zombies.Diagnostics().Recovered==1); assert(state:GetAttribute("Defeated")==kills)
					recovered=true; report.RecoveryDebt=true
				elseif kill then m.Humanoid:TakeDamage(10000) end
			end end
		elseif phase=="ElevatorAvailable" then
			assert(state:GetAttribute("FloorComplete") and state:GetAttribute("Pending")==0 and state:GetAttribute("Alive")==0)
			assert(not Director.TryTravel(player),"Outside-cabin transition")
			local y=Config.Run.BaseHeight+(state:GetAttribute("LayoutIndex")-1)*Config.Run.FloorHeight
			character:PivotTo(CFrame.new(0,y+3,Config.Run.Generation.HalfDepth-11))
			assert(Director.TryTravel(player))
			table.insert(report.Transitions,{From=number,Macro=state:GetAttribute("Macro"),Seed=state:GetAttribute("Seed")})
		elseif phase=="NextFloor" then
			local y=Config.Run.BaseHeight+(state:GetAttribute("LayoutIndex")-1)*Config.Run.FloorHeight
			character:PivotTo(CFrame.new(0,y+3,110))
		end
		local count=0; for _,f in workspace.OfficeRun:GetChildren() do if f:IsA("Model") then count+=1 end end
		assert(count<=2,"Accumulated floors")
		task.wait(.05)
	end
	assert(#report.Transitions==5)
	local floorNumber=state:GetAttribute("Floor"); local seed=state:GetAttribute("Seed")
	player.Character.Humanoid.Health=0
	waitFor(function() return state:GetAttribute("State")=="WaitingForPlayer" end,10)
	player:LoadCharacter()
	waitFor(function() return state:GetAttribute("State")=="ChoosingWeapon" end,20)
	assert(state:GetAttribute("Floor")==floorNumber and state:GetAttribute("Seed")==seed)
	assert(state:GetAttribute("Wave")==0 and state:GetAttribute("Alive")==0 and state:GetAttribute("Pending")==0)
	assert(not player.Character.HumanoidRootPart.Anchored and not player:GetAttribute("InElevatorTravel"))
	report.DeathReset=true
end)
Layout.Generate=originalGenerate
for _,v in originals do v.Table[v.Key]=v.Value end
script:SetAttribute("Status",ok and "Passed" or "Failed")
script:SetAttribute("Report",game:GetService("HttpService"):JSONEncode(report))
script:SetAttribute("Error",err or "")
