-- Shared definitions only; stock, eligibility and checkout live on the server.
return {
	Version=1,
	Economy={FloorBase=60,FloorStep=6,KillCredit=1,NoQuotaKillBudget=30,CreditCap=1000000,KillBudgetCap=1000},
	Merchant={FromFloor=4,Chance=.15,PremiumSlots=2,MaxItems=5,EpicChance=.2,Title="ЗАВХОЗ / СКЛАД ПРИПАСОВ"},
	Vending={Title="АВТОМАТ ПРИПАСОВ",Products={"heal","reroll","health"}},
	Products={
		heal={Kind="Heal",NameRu="Медицинский набор",Price=65,HealFraction=.35,
			DescriptionRu="Восстановить 35% максимального HP, не выше максимума."},
		reroll={Kind="Reroll",NameRu="Дополнительный переброс",Price=60,Amount=1,
			DescriptionRu="Один переброс талантов на этот забег. Лимит — 3 заряда."},
		health={Kind="Health",NameRu="Запас прочности",Price=110,Amount=10,
			DescriptionRu="До +10 максимального HP на этот забег. Общий бонус ограничен 60 HP."},
		upgrade={Kind="Upgrade",NameRu="Усиление таланта",Price=140,
			DescriptionRu="Повысить указанный талант на один уровень, сохранив его редкость."},
		rareboon={Kind="RareBoon",NameRu="Редкая разработка",Price=230,
			DescriptionRu="Получить указанный новый совместимый талант редкости Rare или Epic."},
		rarity={Kind="Rarity",NameRu="Повышение редкости",Price=260,
			DescriptionRu="Повысить редкость указанного таланта на одну ступень, сохранив его уровень."},
		free_supply={Kind="Supply",NameRu="Припасы от Завхоза",Price=0,Heal=10,
			DescriptionRu="Бесплатно: восстановить до 10 HP и заполнить магазин. Один набор на этот склад."},
	},
}
