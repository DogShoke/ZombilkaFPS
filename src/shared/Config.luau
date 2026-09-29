local Config = {}

Config.Movement = { WalkSpeed = 16, SprintSpeed = 24, JumpPower = 50 }
Config.Camera = { HipFov = 70, AdsFov = 55, SprintFov = 77, MouseSensitivity = 0.8, FovResponse = 12 }
Config.Pistol = {
	MagazineSize = 12, Damage = 25, HeadshotMultiplier = 2, ReloadDuration = 1.5,
	FireInterval = 0.22, Range = 450, SemiAutomatic = true,
	HipSpreadDegrees = 0, AdsSpreadDegrees = 0,
}
Config.Animations = {
	Idle = "rbxassetid://105345463794666",
	Shoot = "rbxassetid://128130246447749",
	Reload = "rbxassetid://130294402000435",
	Grip = "rbxassetid://93225329241822",
	Inspect = "rbxassetid://115095786328194",
}
Config.Feel = {
	AdsResponse = 18, SprintResponse = 13, SprintFireTransitionSpeed = 28, SprintFireHold = 0.26,
	SwayFrequency = 10, RecoilFrequency = 4.5, CameraRecoilFrequency = 7,
	SwayPosition = Vector3.new(0.0016, 0.0014, 0), SwayRotation = Vector3.new(0.0011, 0.0016, 0.001),
	SwayAdsMultiplier = 0.16, BobHip = 0.018, BobSprint = 0.031, BobAdsMultiplier = 0.12,
	BobWalkFrequency = 9.5, BobSprintFrequency = 12.5,
	StrafeRoll = math.rad(3.3), StrafeShift = 0.06, StrafeResponse = 13,
	HipPose = CFrame.new(-0.32, -0.9, -1.1) * CFrame.Angles(0, math.rad(-90), 0),
	AdsPose = CFrame.new(-1.02, -0.70, -1.2) * CFrame.Angles(0, math.rad(-90), 0),
	SprintPose = CFrame.new(-0.18, -1.1, -1.04) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(-13), 0, math.rad(-13)),
	ViewmodelKick = Vector3.new(0, -0.025, 0.16),
	ViewmodelRotate = Vector3.new(math.rad(5), math.rad(0.4), math.rad(1)),
	AdsRecoilMultiplier = 0.48, CameraKick = math.rad(0.75), CameraYaw = math.rad(0.12),
	CameraRecoilRecoveryFraction = 0.55, LandingKick = 0.055,
}
Config.Vfx = {
	MuzzleDuration = 0.05, TracerDuration = 0.055, TracerMaxLength = 75,
	WorldImpactDuration = 0.14, BodyImpactDuration = 0.2, HeadImpactDuration = 0.26,
	DamageFlashDuration = 0.28, BloodParticleCount = 6, HeadBloodParticleCount = 10, BloodParticleLifetime = 0.2,
}
Config.Zombies = {
	MaxAlive = 7, SpawnInterval = 2.5, RespawnDelay = 1, MinSpawnDistance = 36, MaxSpawnDistance = 105,
	MaxHealth = 100, WalkSpeed = 11, AggroRange = 180, AttackRange = 4.4, PreferredMinDistance = 2.8,
	AttackDamage = 12, AttackWindup = 0.48, AttackRecover = 0.38, AttackCooldown = 1.6,
	AttackCoordinationInterval = 0.75,
	ThinkInterval = 0.16, RepathInterval = 1.15, CorpseLifetime = 3.5,
	ApproachSpacing = 3.8, PersonalSpace = 4, SeparationStrength = 3.2,
	NavigationHalfExtent = 58.5, SpawnSeparation = 8, SpawnFade = 0.45,
	HitReactDuration = 0.13, HeadReactDuration = 0.2, HurtSoundCooldown = 0.55,
	IdleGroanMin = 9, IdleGroanMax = 17, DirectSightInterval = 0.65,
}
Config.Audio = {
	Gunshot = { Id = "", Volume = 0.9, PitchMin = 0.98, PitchMax = 1.02 },
	MechanicalShot = { Id = "", Volume = 0.35, PitchMin = 0.96, PitchMax = 1.04 },
	Reload = { Id = "", Volume = 0.6 }, EmptyClick = { Id = "", Volume = 0.45 },
	WorldConcrete = { Id = "", Volume = 0.35 }, WorldMetal = { Id = "", Volume = 0.42 },
	WorldWood = { Id = "", Volume = 0.35 }, WorldGeneric = { Id = "", Volume = 0.32 },
	BodyHit = { Id = "", Volume = 0.43 }, Headshot = { Id = "", Volume = 0.55 },
	ZombieIdle = { Id = "", Volume = 0.4, MaxDistance = 65 },
	ZombieHurt = { Id = "", Volume = 0.5, MaxDistance = 70 },
	ZombieAttack = { Id = "", Volume = 0.55, MaxDistance = 75 },
	ZombieDeath = { Id = "", Volume = 0.55, MaxDistance = 80 },
	PlayerHurt = { Id = "", Volume = 0.45 },
}

return Config
