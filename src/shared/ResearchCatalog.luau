-- Permanent research definitions. No temporary boons/credits are persisted.
local Catalog={Version=1,Order={"body_fortification","starting_budget","protocol_analysis","elevator_scanner","research_archive"},
	Rewards={PerFloor=6,RecordBonus=3},Limits={ResearchData=1000000,Floor=1000000,Claims=64},
	Stores={Live="ZombilkaResearch_v1",Studio="ZombilkaResearch_Studio_v1"},
	Definitions={
		body_fortification={NameRu="Укрепление организма",DescriptionRu="Каждый ранг: +3 максимального HP в начале нового забега. Максимум +9 HP.",Costs={18,36,60}},
		starting_budget={NameRu="Стартовый бюджет",DescriptionRu="Каждый ранг: +10 кредитов в начале нового забега. Максимум 30 кредитов.",Costs={18,36,60}},
		protocol_analysis={NameRu="Анализ протоколов",DescriptionRu="Один, затем два стартовых переброса талантов. Действует со следующего забега.",Costs={24,48}},
		elevator_scanner={NameRu="Сканер лифтов",DescriptionRu="Первый ранг: один талант первого предложения. Второй: лучшая редкость первого предложения. Переброс меняет предложение; для магазина показываются подсказки о припасах.",Costs={18,36}},
		research_archive={NameRu="Архив исследований",DescriptionRu="Открыть две архивные записи NORTHLINE. Архив не выдаёт таланты.",Costs={12,24}},
	},
	Archive={
		{Title="Протокол NORTHLINE",Text="Экспедиция поднимается по этажам. Таланты, кредиты и перебросы действуют только до завершения забега; исследования сохраняются отдельно."},
		{Title="Памятка отдела снабжения",Text="Вольта изучает электрические разряды, Браво — дисциплину огня, Вайс — восстановление. Автомат и Завхоз продают припасы за кредиты текущего забега."},
	},
}
function Catalog.Benefits(ranks)
	ranks=ranks or {}
	local function rank(id)return math.clamp(ranks[id]or 0,0,#Catalog.Definitions[id].Costs)end
	return {MaxHealth=rank("body_fortification")*3,StartingCredits=rank("starting_budget")*10,
		StartingRerolls=rank("protocol_analysis"),Scanner=rank("elevator_scanner"),Archive=rank("research_archive")}
end
return Catalog
