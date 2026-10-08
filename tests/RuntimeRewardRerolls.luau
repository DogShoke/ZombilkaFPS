-- Temporary Studio server Script. Actual GUI clicks drive funded rerolls/claim.
-- QA grants three starting charges and accelerates NPC deaths; never ship this.
assert(game:GetService("RunService"):IsStudio())
local R=game.ReplicatedStorage
local S=R.RunState
local C=require(R.Shared.Config)
local P=require(R.Shared.ProgressionConfig)
local Merchant=require(R.Shared.ShopCatalog).Merchant
local D=require(game.ServerScriptService.Server.FloorDirector)
local p=game.Players:GetPlayers()[1]
local changes={}
local function tune(t,k,v)table.insert(changes,{t,k,t[k]});t[k]=v end
local function stage(value)script:SetAttribute("Stage",value)end
local function waitFor(check,seconds,message)
	local deadline=os.clock()+seconds
	repeat if check()then return end;task.wait(.05)until os.clock()>deadline
	error(message or "Reward reroll QA timeout")
end
local report={Coverage="Native Director-bound run, actual GUI reroll/claim, accelerated real NPC deaths; QA-only starting charges"}
local ok,err=pcall(function()
	waitFor(function()return D.EndRun and S:GetAttribute("State")=="ChoosingWeapon"end,60,"Director initialization")
	tune(P.Rerolls,"Starting",3)
	tune(Merchant,"Chance",0)
	tune(C.Run,"IntroDuration",.1);tune(C.Run,"DoorDuration",.1);tune(C.Run,"TravelDuration",.2)
	tune(C.Run.Horde,"BaseSpawnRate",3);tune(C.Run.Horde,"MaxSpawnRate",3)
	tune(C.Run.Encounters,"KillQuota",3);tune(C.Run.Encounters,"QuotaPerFloor",0)
	stage("Reset")
	assert(D.EndRun(p,"QA reset"))
	waitFor(function()return S:GetAttribute("State")=="RunEnded"end,30,"First-floor rebuild")
	if p.Character.Humanoid.Health<=0 then p:LoadCharacterAsync();task.wait(.5)end
	assert(D.StartRun(p,S:GetAttribute("RunEpoch")))
	assert(S:GetAttribute("Rerolls")==3)
	stage("Select Glock")
	waitFor(function()return p:GetAttribute("SelectedWeapon")=="Glock"end,90,"Click Glock in native selection GUI")
	p.Character.Humanoid.MaxHealth=100000;p.Character.Humanoid.Health=100000
	waitFor(function()
		if S:GetAttribute("State")=="EncounterActive"then
			for _,m in workspace:GetChildren()do
				if m:GetAttribute("IsZombie")and not m:GetAttribute("Dead")then m.Humanoid:TakeDamage(10000)end
			end
		end
		return S:GetAttribute("State")=="ElevatorAvailable"
	end,60,"Native quota combat")
	local f=workspace.OfficeRun.Floor001;local prompt
	for _,v in f.ElevatorLobby:GetDescendants()do
		if v:IsA("ProximityPrompt")and v.ObjectText=="Профессор Вольта"then prompt=v;break end
	end
	assert(prompt,"Volta route")
	p.Character:PivotTo(CFrame.new(prompt.Parent.Parent.CabinFloor.Position+Vector3.new(0,3,0)))
	assert(D.TryTravel(p,nil,prompt:GetAttribute("RouteId")))
	waitFor(function()return S:GetAttribute("State")=="RewardInterlude"end,30,"Reward arrival")
	local offer=S.RewardOffer
	local epoch,token,revision=S:GetAttribute("RunEpoch"),offer:GetAttribute("Token"),offer:GetAttribute("Revision")
	local first=offer:GetChildren()[1]:GetAttribute("Id")
	assert(#offer:GetChildren()==3 and S:GetAttribute("Alive")==0 and S:GetAttribute("Pending")==0)
	local cabin=p.Character:GetPivot()
	p.Character:PivotTo(cabin*CFrame.new(25,0,0))
	assert(not D.RerollBoon(p,epoch,token,revision),"Outside-cabin reroll accepted")
	p.Character:PivotTo(cabin)
	assert(not D.RerollBoon(p,epoch,"wrong",revision))
	assert(not D.RerollBoon(p,epoch-1,token,revision))
	assert(S:GetAttribute("Rerolls")==3)
	report.InitialRevision=revision;report.Token=token
	stage("Click reroll 1")
	waitFor(function()return offer:GetAttribute("RerollsUsed")==1 end,120,"First actual GUI reroll")
	assert(S:GetAttribute("Rerolls")==2 and offer:GetAttribute("Token")==token and offer:GetAttribute("Revision")>revision)
	assert(not D.RerollBoon(p,epoch,token,revision),"Replay reroll accepted")
	assert(not D.ClaimBoon(p,epoch,token,first,revision),"Old card revision accepted")
	report.FirstRevision=offer:GetAttribute("Revision");report.FirstBalance=S:GetAttribute("Rerolls")
	stage("Click reroll 2")
	waitFor(function()return offer:GetAttribute("RerollsUsed")==2 end,120,"Second actual GUI reroll")
	assert(S:GetAttribute("Rerolls")==1 and offer:GetAttribute("Token")==token)
	assert(not D.RerollBoon(p,epoch,token,offer:GetAttribute("Revision")),"Third reroll accepted")
	report.FinalRevision=offer:GetAttribute("Revision");report.FinalBalance=S:GetAttribute("Rerolls")
	stage("Click one card")
	waitFor(function()return S:GetAttribute("State")=="NextFloor"end,120,"Actual GUI claim")
	assert(S:GetAttribute("BoonCount")==1 and #S.Build:GetChildren()==1 and not offer:GetAttribute("Active"))
	assert(not D.RerollBoon(p,epoch,token,report.FinalRevision),"Consumed reward rerolled")
	assert(not D.ClaimBoon(p,epoch,token,first,report.FinalRevision),"Consumed reward claimed twice")
	report.Build=S.Build:GetChildren()[1]:GetAttributes()
	p.Character.Humanoid.Health=0
	waitFor(function()return S:GetAttribute("State")=="RunEnded"end,30,"Death rebuild")
	assert(S:GetAttribute("Floor")==1 and S:GetAttribute("Rerolls")==0 and S:GetAttribute("BoonCount")==0 and #S.Build:GetChildren()==0)
	report.DeathReset=true;report.StaleAndDuplicateRejected=true;report.OutsideRejected=true
end)
for _,change in changes do change[1][change[2]]=change[3]end
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
stage(ok and "Complete"or "Failed")
