local AudioConfig = {
	Gunshot = { Id = "rbxassetid://3806566911", Volume = 0.75, PitchMin = 0.98, PitchMax = 1.02 },
	MechanicalShot = { Id = "rbxassetid://3821789416", Volume = 0.12, StartTime = 0.35, Duration = 0.09 },
	Reload = { Id = "rbxassetid://3821789416", Volume = 0.5 },
	EmptyClick = { Id = "rbxassetid://3821789416", Volume = 0.3, StartTime = 0.35, Duration = 0.07 },
	WorldConcrete = { Id = "", Volume = 0.35 }, WorldMetal = { Id = "", Volume = 0.42 },
	WorldWood = { Id = "", Volume = 0.35 }, WorldGeneric = { Id = "", Volume = 0.32 },
	BodyHit = { Id = "", Volume = 0.43 }, Headshot = { Id = "", Volume = 0.55 },
	ZombieIdle = { Id = "rbxassetid://121066883602737", Volume = 0.25, MaxDistance = 55, PitchMin = 0.8, PitchMax = 0.95 },
	ZombieHurt = { Id = "rbxassetid://121066883602737", Volume = 0.38, MaxDistance = 65, PitchMin = 1.15, PitchMax = 1.3 },
	ZombieAttack = { Id = "rbxassetid://121066883602737", Volume = 0.48, MaxDistance = 65 },
	ZombieDeath = { Id = "rbxassetid://121066883602737", Volume = 0.42, MaxDistance = 65, PitchMin = 0.65, PitchMax = 0.75 },
	ElevatorArrival = { Id = "rbxassetid://18192219147", Volume = 0.3, MaxDistance = 65 },
	ElevatorOpen = { Id = "", Volume = 0.3, MaxDistance = 40 },
	ElevatorClose = { Id = "", Volume = 0.3, MaxDistance = 40 },
	ElevatorTravel = { Id = "", Volume = 0.25, MaxDistance = 25 },
	PlayerHurt = { Id = "", Volume = 0.45 },
}

return AudioConfig
