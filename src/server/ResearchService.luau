-- Permanent profile boundary; no DataStore yield in the run state machine.
local Catalog=require(game.ReplicatedStorage.Shared.ResearchCatalog)
local Profiles=require(script.Parent.ProfileService)
local Effects=require(script.Parent.BoonEffects)
local Research={}
Research.__index=Research

function Research.new(run,state,results,remotes,phase,profiles)
	local folder=Instance.new("Folder");folder.Name="Research";folder.Parent=state
	local remote=Instance.new("RemoteEvent");remote.Name="BuyResearch";remote.Parent=remotes
	local self=setmetatable({Run=run,State=state,Results=results,Folder=folder,Profiles=profiles or Profiles.new(),Phase=phase,LastRequest={}},Research)
	remote.OnServerEvent:Connect(function(player,epoch,id,rank,revision)self:Buy(player,epoch,id,rank,revision)end)
	return self
end

function Research:Publish(player)
	if player~=self.Owner then return end
	local data=self.Profiles:Get(player.UserId)
	local profile=data.Profile
	self.Folder:SetAttribute("Status",data.Status)
	self.Folder:SetAttribute("Mode",data.Mode)
	self.Folder:SetAttribute("Balance",profile and profile.ResearchData or 0)
	self.Folder:SetAttribute("Revision",profile and profile.Revision or 0)
	self.Folder:SetAttribute("BestFloor",profile and profile.BestFloor or 0)
	self.Folder:SetAttribute("Busy",data.Busy==true or data.PendingPurchase~=nil)
	self.Folder:SetAttribute("Error",data.Error or "")
	for _,id in Catalog.Order do self.Folder:SetAttribute(id,profile and profile.ResearchRanks[id]or 0)end
	self.State:SetAttribute("ResearchStatus",data.Status)
	player:SetAttribute("ResearchBusy",data.Busy==true or data.PendingPurchase~=nil or data.Status=="Loading")
end

function Research:Benefits(player)
	local data=self.Profiles:Get(player.UserId)
	return Catalog.Benefits(data.Status=="Ready"and data.Profile and data.Profile.ResearchRanks or {})
end

function Research:ApplyStart(player)
	if player~=self.Owner or not self.Run.Active or self.Phase()~="ChoosingWeapon"or player:GetAttribute("SelectedWeapon")then return end
	local meta=self:Benefits(player)
	local data=self.Profiles:Get(player.UserId)
	-- A v0 migration retires old events at load time. This still-unstarted run
	-- was reserved before loading; place its payment identity beyond that boundary.
	if self.Run.ClearedFloors==0 and data.Status=="Ready"and data.Profile
		and self.Run.RunStartedUnixMs<=data.Profile.EvictedBeforeUnixMs then
		self.Run.RunStartedUnixMs=math.max(DateTime.now().UnixTimestampMillis,data.Profile.EvictedBeforeUnixMs+1)
	end
	self.Run.Meta=meta;self.Run.Credits=meta.StartingCredits;self.Run.Rerolls=meta.StartingRerolls
	self.State:SetAttribute("Credits",self.Run.Credits);self.State:SetAttribute("Rerolls",self.Run.Rerolls)
	Effects.RefreshHealth()
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and h.Health>0 then h.Health=h.MaxHealth end
end

function Research:Load(player)
	self.LoadGeneration=(self.LoadGeneration or 0)+1
	local generation=self.LoadGeneration
	self.Owner=player
	player:SetAttribute("ResearchBusy",true)
	self.Folder:SetAttribute("Status","Loading");self.State:SetAttribute("ResearchStatus","Loading")
	task.spawn(function()
		self.Profiles:Load(player.UserId)
		if player~=self.Owner or generation~=self.LoadGeneration then return end
		self:Publish(player);self:ApplyStart(player)
	end)
end

local function integer(value)
	return type(value)=="number"and value==value and value>=0 and value%1==0 and value<1e9
end
function Research:Buy(player,epoch,id,rank,revision)
	local phase=self.Phase();local run=self.Run
	if player~=self.Owner or epoch~=run.Epoch or phase~="ChoosingWeapon"and phase~="RunEnded"then return false end
	if phase=="ChoosingWeapon"and player:GetAttribute("SelectedWeapon")then return false end
	if type(id)~="string"or #id>64 or not Catalog.Definitions[id]or not integer(rank)or not integer(revision)then return false end
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local data=self.Profiles:Get(player.UserId)
	if not h or h.Health<=0 or data.Busy or data.Status~="Ready"or data.Profile.Revision~=revision then return false end
	local now=os.clock();if now<(self.LastRequest[player.UserId]or 0)+.5 then return false end
	self.LastRequest[player.UserId]=now
	-- Set before the first yielding store call: weapon/start remotes cannot race checkout.
	player:SetAttribute("ResearchBusy",true);self.Folder:SetAttribute("Busy",true)
	local ok,reason=self.Profiles:Purchase(player.UserId,id,rank)
	if player==self.Owner then
		self:Publish(player)
		if epoch==run.Epoch then self:ApplyStart(player)end
		self.Folder:SetAttribute("PurchaseMessage",ok and "Исследование сохранено"or tostring(reason or "Не удалось сохранить покупку"))
	end
	return ok
end

function Research:UpdateResult(player,snapshot,ok,receipt)
	if player~=self.Owner or self.Results:GetAttribute("RunId")~=snapshot.RunId then return end
	local status=self.Profiles:Get(player.UserId).Status
	self.Results:SetAttribute("ResearchStatus",ok and "Saved"or (status=="Unavailable"or status=="Corrupt"or status=="NewerSchema")and "Unavailable"or "Pending")
	self.Results:SetAttribute("ResearchEarned",ok and receipt and receipt.ResearchEarnedTotal or 0)
	self.Results:SetAttribute("PendingResearch",ok and 0 or snapshot.ClearedFloors*Catalog.Rewards.PerFloor)
	self.Results:SetAttribute("NewRecord",ok and receipt and receipt.NewRecord==true or false)
end

function Research:Checkpoint(player,snapshot,final)
	-- Snapshot is a detached, server-created ledger; never supplied by a remote.
	task.spawn(function()
		local ok,_,receipt=self.Profiles:AwardRun(player.UserId,snapshot)
		if player==self.Owner then
			self:Publish(player)
			if final then self:UpdateResult(player,snapshot,ok,receipt)end
		end
	end)
end

function Research:Leave(player)
	if player==self.Owner then self.Owner=nil;self.LoadGeneration=(self.LoadGeneration or 0)+1 end
	self.LastRequest[player.UserId]=nil
end

function Research:StartRetryLoop()
	task.spawn(function()
		while self.State.Parent do
			task.wait(20)
			for _,userId in self.Profiles:PendingUsers()do
				if not self.Owner or userId~=self.Owner.UserId then self.Profiles:Retry(userId)end
			end
			local player=self.Owner
			if player then
				local data=self.Profiles:Get(player.UserId)
				if not data.Busy then
					if data.Status=="Unavailable"or data.Status=="Error"or data.PendingPurchase or next(data.PendingAwards or {})then self.Profiles:Retry(player.UserId)end
					if player==self.Owner then
						self:Publish(player)
						self:ApplyStart(player)
						local snapshot=self.Run:GetResults()
						if snapshot then
							local receipt=self.Profiles:Receipt(player.UserId,snapshot.RunId)
							if receipt then self:UpdateResult(player,snapshot,true,receipt)end
						end
					end
				end
			end
		end
	end)
end

return Research
