-- Shared definitions only. Server owns rolls, spending and run counters.
return {
	Version=1,
	Rarities={
		Common={Rank=1,NameRu="ОБЫЧНЫЙ",Color=Color3.fromRGB(183,199,205)},
		Rare={Rank=2,NameRu="РЕДКИЙ",Color=Color3.fromRGB(91,174,255)},
		Epic={Rank=3,NameRu="ЭПИЧЕСКИЙ",Color=Color3.fromRGB(188,132,248)},
		Heroic={Rank=4,NameRu="ГЕРОИЧЕСКИЙ",Color=Color3.fromRGB(247,189,86)},
	},
	RarityOrder={"Common","Rare","Epic","Heroic"},
	RarityBands={
		{FromFloor=1,Weights={60,30,10,0}},
		{FromFloor=3,Weights={48,33,17,2}},
		{FromFloor=6,Weights={40,32,23,5}},
		{FromFloor=9,Weights={33,32,28,7}},
	},
	Pity={RareFromFloor=4,CommonDrought=2,EpicFromFloor=8,EpicDrought=3,EpicStep=5,EpicBonusCap=20},
	Patrons={PrimaryCap=4,KnownWeight=1,NewWeight=2,PrimaryMass=.75,OtherMass=.25,RouteCount=3},
	Rerolls={Starting=0,CarryCap=3,PerOffer=2,Cooldown=.25},
}
