-- One reversible Studio switch. Published games retain the existing legacy mode.
return {
	StudioMode = "EndlessSurvivalPrototype", -- rollback: "LegacyFloors"
	LiveMode = "LegacyFloors",
	Prototype = {
		Map = "Campus", -- rollback: Corporate
		DesiredAlive=5, SpawnInterval=1/0.65, IntroSeconds=3,
		Lighting={ClockTime=12.5,Brightness=2,Ambient=Color3.fromRGB(155,164,177),
			OutdoorAmbient=Color3.fromRGB(175,185,195),FogStart=420,FogEnd=900},
		CampusLighting={ClockTime=16.5,Brightness=2,Ambient=Color3.fromRGB(112,125,137),
			OutdoorAmbient=Color3.fromRGB(145,156,166),FogStart=1800,FogEnd=6500},
		CampusAtmosphere={Density=.16,Haze=1,Glare=.1},
	},
}
