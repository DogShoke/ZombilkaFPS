-- Temporary server Script, run after RuntimeRunLifecycle leaves ChoosingWeapon.
-- Pair with RuntimeRunFaults.client.luau; Stop discards runtime-only config changes.
local C=require(game.ReplicatedStorage.Shared.Config)
local D=require(game.ServerScriptService.Server.FloorDirector)
local S=game.ReplicatedStorage.RunState
local p=game.Players:GetPlayers()[1]
local control=Instance.new("Folder");control.Name="RunFaultControl";control.Parent=game.ReplicatedStorage
local changes={}
local function tune(t,k,v)table.insert(changes,{t,k,t[k]});t[k]=v end
tune(C.Run,"IntroDuration",.1);tune(C.Run,"DoorDuration",.3);tune(C.Run,"TravelDuration",.5)
tune(C.Run.Horde,"BaseSpawnRate",3);tune(C.Run.Horde,"MaxSpawnRate",3)
tune(C.Run.Encounters,"KillQuota",1);tune(C.Run.Encounters,"QuotaPerFloor",0)
local report={Cases={}}
local function waitFor(check,seconds,message)
	local deadline=os.clock()+seconds
	repeat if check()then return end;task.wait(.025)until os.clock()>deadline
	error(message or "Timeout")
end
local ok,err=pcall(function()
	for index,target in {"Pending","PreparingFloor","Closing","Moving","RewardInterlude","NextFloor","Respawn"}do
		p.Character.Humanoid.MaxHealth=100000;p.Character.Humanoid.Health=100000
		local id=S:GetAttribute("RunId")
		control:SetAttribute("Weapon",({"Glock","AKM","Mossberg"})[(index-1)%3+1])
		local travelAt
		waitFor(function()
			local phase=S:GetAttribute("State")
			if target=="Pending"and phase=="EncounterActive"and S:GetAttribute("Pending")>0 then return true end
			if target=="Respawn"and phase=="EncounterActive"then return true end
			if phase=="EncounterActive"then
				for _,m in workspace:GetChildren()do if m:GetAttribute("IsZombie")and not m:GetAttribute("Dead")then m.Humanoid:TakeDamage(10000)end end
			elseif phase=="PreparingFloor"and target=="PreparingFloor"then return true
			elseif phase=="ElevatorAvailable"then
				local floor=workspace.OfficeRun:FindFirstChild(string.format("Floor%03d",S:GetAttribute("Floor")))
				p.Character:PivotTo(CFrame.new(floor.ElevatorLobby.CabinFloor.Position+Vector3.new(0,3,0)))
				local routeId=floor.ElevatorLobby.ElevatorButton.NextFloor:GetAttribute("RouteId")
				assert(D.TryTravel(p,nil,routeId));travelAt=os.clock()
				if target=="Closing"then return true end
			elseif phase=="ElevatorTravel"and target=="Moving"and travelAt and os.clock()-travelAt>.4 then return true
			elseif phase=="RewardInterlude"then
				if target=="RewardInterlude"then return true end
				local offer=S.RewardOffer;local card=offer:GetChildren()[1]
				assert(D.ClaimBoon(p,S:GetAttribute("RunEpoch"),offer:GetAttribute("Token"),card:GetAttribute("Id"),offer:GetAttribute("Revision")))
			elseif phase=="NextFloor"and target=="NextFloor"then return true end
			return false
		end,60,"Could not reach "..target)
		control:SetAttribute("Weapon",nil)
		local epoch=S:GetAttribute("RunEpoch")
		if target=="Respawn"then p:LoadCharacterAsync()else p.Character.Humanoid.Health=0 end
		waitFor(function()return S:GetAttribute("State")=="RunEnded"end,25,"Reset failed: "..target)
		if p.Character.Humanoid.Health<=0 then p:LoadCharacterAsync()end
		task.wait(1.5) -- Beyond original door/travel deadlines and canceled warnings.
		assert(S:GetAttribute("State")=="RunEnded"and S:GetAttribute("Floor")==1)
		assert(S:GetAttribute("RunEpoch")>epoch and S.RunResults:GetAttribute("RunId")==id)
		assert(S:GetAttribute("Alive")==0 and S:GetAttribute("Pending")==0)
		assert(not p.Character.HumanoidRootPart.Anchored and not p:GetAttribute("InElevatorTravel"))
		local worlds=0
		for _,m in workspace.OfficeRun:GetChildren()do if m:GetAttribute("FloorNumber")then worlds+=1;assert(m:GetAttribute("FloorNumber")==1)end end
		assert(worlds==1,"Stale prepared world survived")
		assert(not D.EndRun(p)and not D.StartRun(p,epoch))
		table.insert(report.Cases,{Target=target,Passed=true})
		script:SetAttribute("Report",game.HttpService:JSONEncode(report))
		assert(D.StartRun(p,S:GetAttribute("RunEpoch")))
	end
end)
for _,x in changes do x[1][x[2]]=x[3]end
control:Destroy()
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
