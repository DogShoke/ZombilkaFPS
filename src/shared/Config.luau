local Config = {}

Config.Movement = { WalkSpeed = 16, SprintSpeed = 24, JumpPower = 50 }
Config.Camera = { HipFov = 70, AdsFov = 55, SprintFov = 77, MouseSensitivity = 0.8, FovResponse = 12 }
Config.Pistol = {
	MagazineSize = 12, Damage = 25, HeadshotMultiplier = 2, ReloadDuration = 1.5,
	FireInterval = 0.22, Range = 450, SemiAutomatic = true,
	HipSpreadDegrees = 0, AdsSpreadDegrees = 0,
}
Config.Feel = {
	AdsResponse = 14, SprintResponse = 11, SwayFrequency = 9, RecoilFrequency = 8,
	SwayPosition = Vector3.new(0.0022, 0.0022, 0), SwayRotation = Vector3.new(0.0015, 0.002, 0.001),
	SwayAdsMultiplier = 0.22, BobHip = 0.025, BobSprint = 0.045, BobAdsMultiplier = 0.16,
	BobWalkFrequency = 10, BobSprintFrequency = 13, StrafeRoll = math.rad(3.2), StrafeShift = 0.065,
	HipPose = CFrame.new(0.55, -0.53, -1.15), AdsPose = CFrame.new(0, -0.22, -0.78),
	SprintPose = CFrame.new(0.75, -0.74, -0.91) * CFrame.Angles(math.rad(-17), math.rad(16), math.rad(-21)),
	HipViewKick = Vector3.new(0, -0.045, 0.12), HipViewRotate = Vector3.new(math.rad(3.6), math.rad(0.55), math.rad(1.5)),
	AdsRecoilMultiplier = 0.48, CameraKick = math.rad(0.8), CameraYaw = math.rad(0.16),
	LandingKick = 0.07,
}
Config.Zombies = {
	MaxAlive = 7, SpawnInterval = 2.5, MinSpawnDistance = 36,
	Health = 100, WalkSpeed = 11, AggroRange = 180, AttackRange = 4.4,
	AttackDamage = 12, AttackWindup = 0.48, AttackCooldown = 1.6,
	ThinkInterval = 0.23, PathInterval = 1, CorpseLifetime = 3,
}
Config.Audio = {
	Gunshot = "", MechanicalShot = "", Reload = "", EmptyClick = "",
	BodyHit = "", Headshot = "", ZombieHurt = "", ZombieAttack = "", ZombieDeath = "",
}

return Config
