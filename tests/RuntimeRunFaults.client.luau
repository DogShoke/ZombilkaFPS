local R=game.ReplicatedStorage
local control=R:WaitForChild("RunFaultControl")
while control.Parent do
	local weapon=control:GetAttribute("Weapon")
	if weapon and R.RunState:GetAttribute("State")=="ChoosingWeapon"then R.CombatRemotes.SelectWeapon:FireServer(weapon)end
	task.wait(.1)
end
