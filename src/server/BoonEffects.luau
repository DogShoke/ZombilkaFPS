-- One synchronous effect pipeline. Secondary damage never enters direct-hit hooks.
local Catalog=require(game.ReplicatedStorage.Shared.BoonCatalog)
local Zombies=require(script.Parent.ZombieService)
local Effects={}
local session,owner
local cooldowns,charges={},{}
local salvo=0
local function values(id)
	local b=session and session.Active and session.Boons[id]
	return b and Catalog.Values(id,b.Level,b.Rarity)
end
local function alive()
	local c=owner and owner.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and h
end
local function ready(id,seconds)
	local now=os.clock()
	if now<(cooldowns[id]or 0)then return false end
	cooldowns[id]=now+seconds;return true
end
local function heal(amount)
	local h=alive();if h then h.Health=math.min(h.MaxHealth,h.Health+amount)end
end
function Effects.Bind(run,player)
	session,owner=run,player;cooldowns,charges={},{};salvo=0
end
function Effects.ClearFloor()
	charges={};salvo=0
end
function Effects.Clear()
	local h=alive()
	if h then h.MaxHealth=Catalog.Limits.BaseHealth;h.Health=math.min(h.Health,h.MaxHealth)end
	session,owner=nil,nil;cooldowns,charges={},{};salvo=0
end
function Effects.RefreshHealth()
	local h=alive();if not h then return end
	local v=values("weiss_field_protocol")
	h.MaxHealth=Catalog.Limits.BaseHealth+math.clamp((v and v.MaxHealth or 0)+(session.SupplyHealth or 0)+(session.Meta and session.Meta.MaxHealth or 0),0,Catalog.Limits.MaxHealthBonus)
	h.Health=math.min(h.Health,h.MaxHealth)
end
function Effects.OnFloorStart()
	Effects.ClearFloor();Effects.RefreshHealth()
	local v=values("weiss_field_protocol");if v then heal(v.Heal)end
end
function Effects.Magazine(player,base)
	if player~=owner then return base end
	local v=values("bravo_belt_feed")
	return math.clamp(math.ceil(base*(1+(v and v.Fraction or 0))),base,math.ceil(base*Catalog.Limits.MaxMagazineMultiplier))
end
function Effects.OnReloadComplete(player)
	local v=player==owner and values("bravo_first_salvo")
	if v then salvo=v.Shots end -- Assignment, never extra charges per inserted shell.
end
function Effects.OnShotAccepted(player)
	local v=player==owner and values("bravo_first_salvo")
	local bonus=v and salvo>0 and v.Bonus or 0
	if salvo>0 then salvo-=1 end
	return {SalvoBonus=bonus,Procs={}}
end
function Effects.DirectDamage(player,model,base,context)
	if player~=owner or not session or not session.Active then return base end
	local bonus=context.SalvoBonus
	local h=alive();local adrenaline=values("weiss_adrenaline")
	if h and adrenaline then bonus+=adrenaline.Bonus*(1-h.Health/h.MaxHealth)end
	local voltage=values("volta_high_voltage")
	if voltage then
		local now=os.clock();local entry=charges[model]
		if not entry or now>entry.Expires then entry={Stacks=0};charges[model]=entry end
		bonus+=entry.Stacks*voltage.PerStack
		entry.Stacks=math.min(voltage.Stacks,entry.Stacks+1);entry.Expires=now+voltage.Duration
	end
	return base*math.clamp(1+bonus,1,Catalog.Limits.MaxDamageMultiplier)
end
function Effects.OnKill(player)
	if player~=owner then return end
	local v=values("weiss_coagulation")
	if v and ready("Heal",v.Cooldown)then heal(v.Heal)end
end
function Effects.AfterDirectHit(player,model,headshot,direction,context)
	if player~=owner or not session or not session.Active then return end
	local h=model:FindFirstChildOfClass("Humanoid")
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local shock=values("volta_static_shock")
	if shock and headshot and h and h.Health>0 and not context.Procs.Shock and ready("Shock",shock.Cooldown)then
		context.Procs.Shock=true;Zombies.Stun(model,shock.Duration)
	end
	local push=values("bravo_large_caliber")
	if push and h and h.Health>0 and not root.Anchored and not context.Procs.Push and ready("Push",push.Cooldown)then
		local flat=Vector3.new(direction.X,0,direction.Z)
		if flat.Magnitude>.01 then root.AssemblyLinearVelocity=flat.Unit*push.Speed+Vector3.new(0,math.clamp(root.AssemblyLinearVelocity.Y,-10,10),0)end
		context.Procs.Push=true
	end
	local arc=values("volta_arc_discharge")
	if not arc or context.Procs.Arc or not ready("Arc",arc.Cooldown)then return end
	context.Procs.Arc=true
	local targets=Zombies.Nearby(root.Position,Catalog.Limits.ArcRadius,model,Catalog.Limits.ArcTargets)
	local points={root.Position}
	for _,target in targets do
		local th=target:FindFirstChildOfClass("Humanoid")
		local tr=target:FindFirstChild("HumanoidRootPart")
		if th and tr and th.Health>0 then
			table.insert(points,tr.Position)
			local before=th.Health;th:TakeDamage(arc.Damage)
			if before>0 and th.Health<=0 then Effects.OnKill(player)end
		end
	end
	if #points>1 then game.ReplicatedStorage.CombatRemotes.Feedback:FireClient(player,"BoonArc",points)end
end
return Effects
