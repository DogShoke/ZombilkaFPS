-- Server-only temporary run ledger. Persistence is deliberately a separate boundary.
local HttpService = game:GetService("HttpService")
local Progression=require(game.ReplicatedStorage.Shared.ProgressionConfig)
local Economy=require(game.ReplicatedStorage.Shared.ShopCatalog).Economy
local Research=require(game.ReplicatedStorage.Shared.ResearchCatalog)
local RunSession = {}
RunSession.__index = RunSession

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in value do result[key] = copy(item) end
	return result
end

function RunSession.new()
	return setmetatable({Epoch=0, Active=false, Results=nil}, RunSession)
end

function RunSession:Begin(now, benefits)
	assert(not self.Active, "End the previous run first")
	self.Epoch += 1
	self.Id = HttpService:GenerateGUID(false)
	self.RunStartedUnixMs=DateTime.now().UnixTimestampMillis
	self.Active, self.StartedAt = true, now
	self.HighestFloor, self.Kills, self.ClearedFloors = 1, 0, 0
	self.Credits, self.CreditsEarned, self.CreditsSpent, self.Rerolls = 0, 0, 0, 0
	self.Rerolls=Progression.Rerolls.Starting
	self.Meta=benefits or Research.Benefits({})
	self.Credits=self.Meta.StartingCredits or 0
	self.Rerolls=self.Meta.StartingRerolls or self.Rerolls
	self.Pity={CommonDrought=0,EpicDrought=0};self.PatronOrder={}
	self.Boons, self.Modifiers, self.Patrons, self.Completed = {}, {}, {}, {}
	self.PendingResearch = 0
	self.SupplyHealth=0
	self.Floor,self.KillBudget,self.FloorKills=1,0,{}
	return self.Epoch
end

function RunSession:IsCurrent(epoch)
	return self.Active and epoch == self.Epoch
end

function RunSession:RecordKill(epoch)
	if not self:IsCurrent(epoch) then return false end
	self.Kills += 1
	local kills=self.FloorKills[self.Floor]or 0
	if not self.Completed[self.Floor]and kills<self.KillBudget then
		self.FloorKills[self.Floor]=kills+1
		self:AddCredits(epoch,Economy.KillCredit)
	end
	return true
end

local function amount(value)
	return type(value)=="number"and value==value and value>=0 and value<=Economy.CreditCap and value%1==0
end
function RunSession:SetFloor(epoch,floor,killBudget)
	if not self:IsCurrent(epoch)or not amount(floor)or floor<1 or not amount(killBudget)then return false end
	self.Floor,self.KillBudget=floor,math.min(killBudget,Economy.KillBudgetCap)
	return true
end
function RunSession:AddCredits(epoch,value)
	if not self:IsCurrent(epoch)or not amount(value)then return false end
	local added=math.min(value,Economy.CreditCap-self.Credits)
	self.Credits+=added;self.CreditsEarned+=added
	return true
end
function RunSession:SpendCredits(epoch,value)
	if not self:IsCurrent(epoch)or not amount(value)or self.Credits<value then return false end
	self.Credits-=value;self.CreditsSpent+=value
	return true
end

function RunSession:CompleteFloor(epoch, floor)
	if not self:IsCurrent(epoch) or not amount(floor)or floor<1 or self.Completed[floor] then return false end
	self.Completed[floor] = true
	self.ClearedFloors += 1
	self.PendingResearch=self.ClearedFloors*Research.Rewards.PerFloor
	self:AddCredits(epoch,math.min(Economy.CreditCap,Economy.FloorBase+Economy.FloorStep*(floor-1)))
	return true
end

function RunSession:Finish(now, reason)
	if not self.Active then return nil end
	self.Results = {
		RunId=self.Id, HighestFloor=self.HighestFloor, Kills=self.Kills,
		RunStartedUnixMs=self.RunStartedUnixMs,
		ClearedFloors=self.ClearedFloors, Duration=math.max(0, now-self.StartedAt),
		Patrons=copy(self.Patrons), Boons=copy(self.Boons),
		CreditsEarned=self.CreditsEarned, CreditsSpent=self.CreditsSpent,
		ResearchEarned=0, PendingResearch=self.PendingResearch, ResearchStatus="Pending", Reason=reason,
	}
	self.Active = false
	self.Epoch += 1 -- Invalidates callbacks before a replacement character/run exists.
	self.Credits, self.Rerolls, self.PendingResearch = 0, 0, 0
	self.Boons, self.Modifiers, self.Patrons = {}, {}, {}
	self.Pity={CommonDrought=0,EpicDrought=0};self.PatronOrder={}
	self.SupplyHealth=0
	self.Meta=nil
	self.Floor,self.KillBudget,self.FloorKills=1,0,{}
	return copy(self.Results)
end

function RunSession:GetResults()
	return copy(self.Results)
end

return RunSession
