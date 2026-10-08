-- Install as a temporary server Script in Play, after equipping a weapon.
-- Uses real ZombieService deaths with accelerated timings, not normal-length balance.
local C=require(game.ReplicatedStorage.Shared.Config)
local D=require(game.ServerScriptService.Server.FloorDirector)
local S=game.ReplicatedStorage.RunState
local p=game.Players:GetPlayers()[1]
local changes={}
local function tune(t,k,v)table.insert(changes,{t,k,t[k]});t[k]=v end
tune(C.Run,"IntroDuration",.1);tune(C.Run,"DoorDuration",.1);tune(C.Run,"TravelDuration",.2)
tune(C.Run.Horde,"BaseSpawnRate",3);tune(C.Run.Horde,"MaxSpawnRate",3)
tune(C.Run.Encounters,"KillQuota",3);tune(C.Run.Encounters,"QuotaPerFloor",0)
local report={Transitions={},Rewards={},MaxAlive=0,OutsideRejected=false,DuplicateRejected=false}
local routeId,patronName
local function waitFor(check,seconds,message)
	local untilTime=os.clock()+seconds
	repeat if check()then return end;task.wait(.05)until os.clock()>untilTime
	error(message or "Timeout")
end
local function floor()
	return workspace.OfficeRun:FindFirstChild(string.format("Floor%03d",S:GetAttribute("Floor")))
end
local ok,err=pcall(function()
	p.Character.Humanoid.MaxHealth=100000;p.Character.Humanoid.Health=100000
	local initialId=S:GetAttribute("RunId")
	local untilTime=os.clock()+150
	while S:GetAttribute("Floor")<3 do
		assert(os.clock()<untilTime,"Progression timeout")
		local phase=S:GetAttribute("State")
		local count=(S:GetAttribute("Alive")or 0)+(S:GetAttribute("Pending")or 0)
		report.MaxAlive=math.max(report.MaxAlive,count);assert(count<=C.Run.Horde.AliveCap)
		if phase=="EncounterActive"then
			assert(not D.TryTravel(p))
			local alive=S:GetAttribute("Alive")or 0
			for _,m in workspace:GetChildren()do
				if alive>1 and m:GetAttribute("IsZombie")and not m:GetAttribute("Dead")then m.Humanoid:TakeDamage(10000);alive-=1 end
			end
		elseif phase=="ElevatorAvailable"then
			assert(S:GetAttribute("FloorComplete"));assert(not D.TryTravel(p),"Outside cabin accepted")
			report.OutsideRejected=true
			local f=floor();local prompt=f.ElevatorLobby.ElevatorButton.NextFloor
			if S:GetAttribute("Floor")==1 then
				for _,v in f.ElevatorLobby:GetDescendants()do if v:IsA("ProximityPrompt")and v.ObjectText=="Профессор Вольта"then prompt=v;break end end
			end
			routeId=prompt:GetAttribute("RouteId");patronName=prompt.ObjectText
			local at=prompt.Parent.Parent.CabinFloor.Position
			p.Character:PivotTo(CFrame.new(at+Vector3.new(0,3,0)))
			assert(D.TryTravel(p,nil,routeId));assert(not D.TryTravel(p,nil,routeId),"Duplicate travel accepted")
			report.DuplicateRejected=true;table.insert(report.Transitions,S:GetAttribute("Floor"))
		elseif phase=="RewardInterlude"then
			local offer=S.RewardOffer;assert(offer:GetAttribute("PatronName")==patronName)
			assert(#offer:GetChildren()==3 and S:GetAttribute("Alive")==0 and S:GetAttribute("Pending")==0)
			assert(p:GetAttribute("InSafeInterlude"))
			local card=offer:GetChildren()[1];local epoch,token=S:GetAttribute("RunEpoch"),offer:GetAttribute("Token")
			assert(not D.ClaimBoon(p,epoch,"stale",card:GetAttribute("Id"),offer:GetAttribute("Revision")))
			task.wait(.5);assert(S:GetAttribute("State")=="RewardInterlude"and S:GetAttribute("Alive")==0)
			assert(D.ClaimBoon(p,epoch,token,card:GetAttribute("Id"),offer:GetAttribute("Revision")))
			assert(not D.ClaimBoon(p,epoch,token,card:GetAttribute("Id"),offer:GetAttribute("Revision")))
			table.insert(report.Rewards,{Patron=patronName,Id=card:GetAttribute("Id")})
		elseif phase=="NextFloor"then
			local at=floor().PlayerSpawn.Position;p.Character:PivotTo(CFrame.new(at+Vector3.new(0,3,-12)))
		end
		task.wait(.1)
	end
	assert(S:GetAttribute("RunId")==initialId)
	local kills=S:GetAttribute("RunKills")
	assert(kills>=33,"Cumulative actual kills missing")
	local oldEpoch=S:GetAttribute("RunEpoch")
	-- Final death during arrival must cancel the still-anchored travel root immediately.
	p.Character.Humanoid.Health=0
	waitFor(function()return S:GetAttribute("RunActive")==false end,2,"Death not observed")
	assert(not D.EndRun(p),"Duplicate end accepted")
	waitFor(function()return S:GetAttribute("State")=="RunEnded"end,20,"Floor1 rebuild timeout")
	p:LoadCharacterAsync()
	waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")and S:GetAttribute("State")=="RunEnded"end,10)
	task.wait(.5)
	assert(S:GetAttribute("Floor")==1 and floor():GetAttribute("FloorNumber")==1)
	assert(S:GetAttribute("Alive")==0 and S:GetAttribute("Pending")==0)
	assert(S:GetAttribute("Credits")==0 and S:GetAttribute("Rerolls")==0 and S:GetAttribute("BoonCount")==0)
	assert(not p:GetAttribute("InElevatorTravel")and not p.Character.HumanoidRootPart.Anchored)
	assert(p:GetAttribute("SelectedWeapon")==nil)
	local r=S.RunResults:GetAttributes()
	assert(r.RunId==initialId and r.HighestFloor==3 and r.Kills>=kills and r.ClearedFloors==2)
	assert(r.ResearchEarned==0 and r.ResearchStatus=="Unavailable")
	assert(not D.StartRun(p,oldEpoch),"Stale start accepted")
	local epoch=S:GetAttribute("RunEpoch")
	assert(D.StartRun(p,epoch));assert(not D.StartRun(p,epoch),"Duplicate start accepted")
	assert(S:GetAttribute("State")=="ChoosingWeapon"and S:GetAttribute("RunId")~=initialId)
	assert(S:GetAttribute("Floor")==1 and S:GetAttribute("RunKills")==0)
	task.wait(5)
	assert(S:GetAttribute("State")=="ChoosingWeapon"and S:GetAttribute("Alive")==0 and S:GetAttribute("Pending")==0,"Stale callback restarted combat")
	report.Results=r;report.DeathReset=true;report.StaleStartRejected=true;report.NewRun=true
end)
for _,x in changes do x[1][x[2]]=x[3]end
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
