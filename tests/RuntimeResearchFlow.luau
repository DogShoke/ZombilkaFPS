-- TEMPORARY Play-only driver. Explicit in-memory Mock backend, never real DataStore.
-- Seeds test-only research; actual GUI buys/newrun/reward selection are driven separately.
local R=game.ReplicatedStorage
local S=R.RunState
local Server=game.ServerScriptService.Server
local D=require(Server.FloorDirector)
local Research=require(Server.ResearchService)
local Profiles=require(Server.ProfileService)
local Schema=require(Server.ProfileSchema)
local C=require(R.Shared.Config)
local p=game.Players:GetPlayers()[1]
local report={Mode="Mock",RealDataStoreVerified=false,Purchases={},Scanner={},Weapons={}}
local changes={}
local oldPublish=Research.Publish
local instance
local function waitFor(check,timeout,message)
	local deadline=os.clock()+timeout
	repeat if check()then return end;task.wait(.05)until os.clock()>deadline
	error(message or "Timed out")
end
local function tune(t,key,value)table.insert(changes,{t,key,t[key]});t[key]=value end
local function stage(value)script:SetAttribute("Stage",value)end
Research.Publish=function(self,player)instance=self;return oldPublish(self,player)end
local ok,err=pcall(function()
	assert(D.EndRun(p,"QAResearchSetup"))
	waitFor(function()return instance and S:GetAttribute("State")=="RunEnded"end,30,"Capture/rebuild failed")
	Research.Publish=oldPublish
	local backend={Values={},Writes=0}
	function backend:GetAsync(key)return Schema.Copy(self.Values[key])end
	function backend:UpdateAsync(key,transform)
		local nextValue=transform(Schema.Copy(self.Values[key]))
		if nextValue~=nil then self.Values[key]=Schema.Copy(nextValue);self.Writes+=1 end
		return Schema.Copy(self.Values[key])
	end
	instance.Profiles=Profiles.new(backend,{Attempts=1,RetryDelay=0})
	instance:Load(p)
	waitFor(function()return S.Research:GetAttribute("Status")=="Ready"end,5)
	local seed={RunId="QAResearchSeed",RunStartedUnixMs=DateTime.now().UnixTimestampMillis-10000,ClearedFloors=100,HighestFloor=100}
	assert(instance.Profiles:AwardRun(p.UserId,seed))
	instance:Publish(p)
	assert(S.Research:GetAttribute("Mode")=="Mock"and S.Research:GetAttribute("Balance")==603)
	report.SeedIsTestOnly=true
	stage("BuyResearch")
	waitFor(function()
		local f=S.Research
		return f:GetAttribute("body_fortification")==1 and f:GetAttribute("starting_budget")==1 and f:GetAttribute("protocol_analysis")==1
			and f:GetAttribute("elevator_scanner")==2 and f:GetAttribute("research_archive")==2
	end,180,"GUI purchase sequence failed")
	assert(S.Research:GetAttribute("Balance")==453)
	report.BalanceAfterPurchases=453
	for _,id in require(R.Shared.ResearchCatalog).Order do report.Purchases[id]=S.Research:GetAttribute(id)end
	tune(C.Run,"IntroDuration",.1);tune(C.Run,"DoorDuration",.1);tune(C.Run,"TravelDuration",.2)
	tune(C.Run.Horde,"BaseSpawnRate",4);tune(C.Run.Horde,"MaxSpawnRate",4)
	stage("StartGlock")
	waitFor(function()return S:GetAttribute("State")=="ChoosingWeapon"end,180)
	assert(p.Character.Humanoid.MaxHealth==103 and p.Character.Humanoid.Health==103)
	assert(S:GetAttribute("Credits")==10 and S:GetAttribute("Rerolls")==1)
	report.StartBenefits={MaxHealth=103,Credits=10,Rerolls=1}
	waitFor(function()return S:GetAttribute("State")=="EncounterActive"end,180)
	assert(p:GetAttribute("SelectedWeapon")=="Glock")
	-- Kill real emerged NPCs at accelerated issuance; not a normal balance run.
	local untilTime=os.clock()+90
	while S:GetAttribute("State")~="ElevatorAvailable"do
		assert(os.clock()<untilTime,"Real floor completion timeout")
		for _,m in workspace:GetChildren()do
			if m:GetAttribute("IsZombie")and not m:GetAttribute("Dead")then m.Humanoid:TakeDamage(10000)end
		end
		task.wait(.15)
	end
	waitFor(function()return S.Research:GetAttribute("Balance")==459 end,5,"Floor checkpoint missing")
	local floor=workspace.OfficeRun:FindFirstChild("Floor001")
	local chosen
	for _,prompt in floor.ElevatorLobby:GetDescendants()do
		if prompt:IsA("ProximityPrompt")and prompt.Enabled and prompt:GetAttribute("RouteId")then
			local sign=prompt.Parent.Parent:FindFirstChild("RewardSign")or prompt.Parent.Parent:FindFirstChild("PatronSign")
			if prompt.ObjectText=="Профессор Вольта"then chosen=prompt end
		end
	end
	for _,v in floor.ElevatorLobby:GetDescendants()do
		if v:IsA("TextLabel")and v.Text:find("СКАНЕР:",1,true)then table.insert(report.Scanner,v.Text)end
	end
	assert(#report.Scanner==3,"Scanner preview missing on patron doors")
	assert(chosen,"Volta route not found")
	p.Character:PivotTo(CFrame.new(chosen.Parent.Parent.CabinFloor.Position+Vector3.new(0,3,0)))
	assert(D.TryTravel(p,nil,chosen:GetAttribute("RouteId")))
	waitFor(function()return S:GetAttribute("State")=="RewardInterlude"end,10)
	stage("ClaimBoon")
	waitFor(function()return S:GetAttribute("State")=="NextFloor"end,180)
	assert(S:GetAttribute("BoonCount")==1 and #S.Build:GetChildren()==1)
	local id=S:GetAttribute("RunId")
	p.Character.Humanoid.Health=0
	waitFor(function()return S:GetAttribute("State")=="RunEnded"end,25)
	if not p.Character or p.Character.Humanoid.Health<=0 then p:LoadCharacterAsync()end
	waitFor(function()return p.Character and p.Character:FindFirstChildOfClass("Humanoid")and p.Character.Humanoid.Health>0 end,10)
	waitFor(function()return S.RunResults:GetAttribute("ResearchStatus")=="Saved"end,5)
	assert(S.RunResults:GetAttribute("RunId")==id and S.RunResults:GetAttribute("ResearchEarned")==6)
	assert(S.Research:GetAttribute("Balance")==459 and S:GetAttribute("Credits")==0 and S:GetAttribute("Rerolls")==0)
	assert(S:GetAttribute("BoonCount")==0 and #S.Build:GetChildren()==0 and S:GetAttribute("Floor")==1)
	assert(not D.EndRun(p),"Duplicate death accepted")
	report.Death={SavedResearch=6,Balance=459,TemporaryBuildCleared=true,NewFloor=1}
	local rejoined=Profiles.new(backend,{Attempts=1,RetryDelay=0})
	assert(rejoined:Load(p.UserId));local saved=rejoined:Get(p.UserId).Profile
	assert(saved.ResearchData==459 and saved.ResearchRanks.body_fortification==1 and saved.Boons==nil and saved.Credits==nil)
	report.MockNewServiceReload=true
	for _,weapon in {"AKM","Mossberg"}do
		stage("Start"..weapon)
		waitFor(function()return S:GetAttribute("State")=="EncounterActive"end,180)
		assert(p:GetAttribute("SelectedWeapon")==weapon and p.Character.Humanoid.MaxHealth==103)
		require(Server.WeaponService).RefreshStats(p) -- Publish the authoritative capacity; equip uses base HUD until first ammo message.
		assert(p:GetAttribute("MagazineCapacity")==C.Weapons[weapon].MagazineSize)
		table.insert(report.Weapons,weapon)
		p.Character.Humanoid.Health=0
		waitFor(function()return S:GetAttribute("State")=="RunEnded"end,25)
		if p.Character.Humanoid.Health<=0 then p:LoadCharacterAsync()end
		waitFor(function()return p.Character.Humanoid.Health>0 and not p:GetAttribute("ResearchBusy")end,10)
	end
	report.Writes=backend.Writes;stage("Done")
end)
Research.Publish=oldPublish
for _,change in changes do change[1][change[2]]=change[3]end
script:SetAttribute("Success",ok);script:SetAttribute("Error",tostring(err or ""))
script:SetAttribute("Report",game.HttpService:JSONEncode(report));script:SetAttribute("Complete",true)
