local function aimPose(rear, front, distance)
	return CFrame.new(0, 0, -(distance or 0.6)) * CFrame.lookAt(rear, front):Inverse()
end

return {
	Order = { "Glock", "AKM", "Mossberg" },
	Glock = {
		Name = "GLOCK 19", Type = "ПИСТОЛЕТ", Description = "Точные одиночные выстрелы. Удобен на средней дистанции.",
		Template = "FpsGlock", CardImage = "rbxassetid://140411000622881", MagazineSize = 12, Damage = 25, HeadshotMultiplier = 2,
		ReloadDuration = 1.5, FireInterval = 0.22, Range = 450, Automatic = false, Pellets = 1, SpreadDegrees = 0,
		RecoilMultiplier = 1,
		Tracer = { Duration = 0.09, Width = 0.035, Length = 90 },
	},
	AKM = {
		Name = "AKM", Type = "АВТОМАТ", Description = "Плотный автоматический огонь. Удерживай кнопку выстрела.",
		Template = "FpsAKM", CardImage = "rbxassetid://96585576564677", MagazineSize = 30, Damage = 18, HeadshotMultiplier = 2,
		ReloadDuration = 2.6, FireInterval = 0.1, Range = 450, Automatic = true, Pellets = 1, SpreadDegrees = 0.5,
		RecoilMultiplier = 1.3, Motion = "AKMClips",
		Tracer = { Duration = 0.075, Width = 0.028, Length = 110 },
		RigBasis = CFrame.Angles(0, 0, math.pi) * CFrame.Angles(math.pi / 2, 0, 0),
		HipPose = CFrame.new(0.48, -0.64, -0.75),
		AdsPose = aimPose(Vector3.new(0, 0.417, -0.92), Vector3.new(0, 0.47, -2.5), 2.6),
		SprintPose = CFrame.new(0.55, -0.85, -0.55) * CFrame.Angles(math.rad(-18), math.rad(15), math.rad(12)),
	},
	Mossberg = {
		Name = "MOSSBERG 590A1", Type = "ПОМПОВЫЙ ДРОБОВИК", Description = "Мощный выстрел вблизи. После выстрела — перезарядка цевьём.",
		Template = "FpsMossberg", CardImage = "rbxassetid://122432998430250", MagazineSize = 6, Damage = 12, HeadshotMultiplier = 1.5,
		ReloadMode = "Shell", ShellInsertDuration = 1.05, ReloadDuration = 1.05,
		FireInterval = 0.85, Range = 180, Automatic = false, Pellets = 8, SpreadDegrees = 5,
		Tracer = { Duration = 0.14, Width = 0.022, Length = 90 },
		FalloffStart = 45, MinDamageMultiplier = 0.3, RecoilMultiplier = 2.1, Motion = "MossbergClips",
		RigBasis = CFrame.Angles(0, 0, math.pi) * CFrame.Angles(math.pi / 2, 0, 0),
		HipPose = CFrame.new(0.5, -0.64, -0.8),
		AdsPose = aimPose(Vector3.new(0, 0.386, -0.195), Vector3.new(0, 0.37, -2.72), 0.9),
		SprintPose = CFrame.new(0.55, -0.85, -0.55) * CFrame.Angles(math.rad(-18), math.rad(15), math.rad(12)),
	},
}
