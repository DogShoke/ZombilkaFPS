local Config = {}
Config.Weapons = require(script.Parent.Weapons)

Config.Movement = {
	WalkSpeed = 16, SprintSpeed = 24, SprintJumpSpeed = 28, JumpPower = 50,
	JumpRiseGravity = 1.65, JumpFallGravity = 0.65,
	SlideMinSpeed = 15, SlideInitialSpeed = 30, SlideEndSpeed = 16, SlideStopSpeed = 7,
	SlideInputBuffer = 0.18, SlideDuration = 0.8, SlideCooldown = 0.45, SlideSteering = 1.3, SlideExitSpeed = 24,
	SlideCameraDrop = 1.3, SlideResponse = 14, SlideFov = 80,
}
Config.ZombieAnimations = {
	Idle = "rbxassetid://125750544", Run = "rbxassetid://125749145", Attack = "rbxassetid://180416148",
	BodyHit = "", HeadHit = "", Death = "", -- Source-authored ZombieClips; publish for live Animator playback.
}
Config.ZombieAnimationTuning = { RunSpeed = 11 }
Config.Run = {
	Waves = { 5, 7, 9 }, IntroDuration = 4, BetweenWaves = 4, SpawnInterval = 1.15,
	DoorDuration = 0.85, TravelDuration = 3.5, Tick = 0.1,
	FloorHeight = 48, BaseHeight = 180, HalfExtent = 132,
	Generation = {
		HalfWidth = 132, HalfDepth = 144, CellSize = 48, RoomSize = 36,
		DoorWidth = 14, CeilingHeight = 28, RoomWallHeight = 8,
		UpperChance = 0.4, UpperHeight = 10, RampLength = 48, RampWidth = 14,
		Themes = { "Office", "Laboratory", "Warehouse", "Parking" },
	},
	Difficulty = {
		ExtraPerWavePerFloor = 2, MaxExtraPerWave = 18,
		BaseAlive = 9, ExtraAliveEvery = 3, MaxAlive = 16,
		HealthPerFloor = 4, MaxHealthMultiplier = 1.8,
		SpeedPerFloor = 0.1, MaxSpeed = 14,
		DamagePerFloor = 0.6, MaxDamage = 24,
	},
}
Config.Camera = { MouseSensitivity = 1, HipFov = 70, AdsFov = 55, SprintFov = 77, FovResponse = 12, ElevatorShake = 0.025, ElevatorShakeFrequency = 18 }
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
	SlideOffset = CFrame.new(0.08, -0.16, 0.08) * CFrame.Angles(math.rad(-5), 0, math.rad(9)),
	CameraRecoilRecoveryFraction = 0.55, LandingKick = 0.055,
}
Config.Vfx = {
	MuzzleDuration = 0.05, TracerDuration = 0.055, TracerMaxLength = 75,
	WorldImpactDuration = 0.14, BodyImpactDuration = 0.2, HeadImpactDuration = 0.26,
	DamageFlashDuration = 0.28, BloodParticleCount = 6, HeadBloodParticleCount = 10, BloodParticleLifetime = 0.2,
}
Config.Zombies = {
	VariantFolder = "CityZombies",
	MaxAlive = 9, MinSpawnDistance = 32, MaxSpawnDistance = 360,
	MaxHealth = 100, WalkSpeed = 11, AggroRange = 420, AttackRange = 4.4, PreferredMinDistance = 2.8,
	AttackDamage = 12, AttackWindup = 0.48, AttackRecover = 0.38, AttackCooldown = 1.6,
	AttackCoordinationInterval = 0.75,
	ThinkInterval = 0.16, RepathInterval = 1.15, CorpseLifetime = 3.5,
	ApproachSpacing = 3.8, PersonalSpace = 4, SeparationStrength = 3.2,
	NavigationHalfExtent = 75, SpawnSeparation = 8, SpawnFade = 0.45,
	HitReactDuration = 0.13, HeadReactDuration = 0.2, HurtSoundCooldown = 0.55,
	IdleGroanMin = 9, IdleGroanMax = 17, DirectSightInterval = 0.65,
}
Config.Audio = require(script.Parent.AudioConfig)
return Config
