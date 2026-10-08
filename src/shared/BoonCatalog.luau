-- Authored rarity/level values; fixed proc budgets never receive a multiplier.
local Catalog={Version=2,Order={
	"volta_arc_discharge","volta_static_shock","volta_high_voltage",
	"bravo_belt_feed","bravo_first_salvo","bravo_large_caliber",
	"weiss_coagulation","weiss_adrenaline","weiss_field_protocol",
},Limits={BaseHealth=100,MaxHealthBonus=60,MaxMagazineMultiplier=1.5,MaxDamageMultiplier=2,ArcTargets=2,ArcRadius=18}}
local function percent(fraction)
	return (string.format("%.1f",fraction*100):gsub("%.0$",""))
end
local function boon(id,patron,name,category,rarityValues,description)
	Catalog[id]={Id=id,Patron=patron,NameRu=name,SlotOrCategory=category,MaxLevel=3,
		RarityEligible={"Common","Rare","Epic","Heroic"},Compatibility={Glock=true,AKM=true,Mossberg=true},
		-- Scalars remains the Common view for existing tooling and saved definitions.
		Tags={category},Requirements={},Scalars=rarityValues.Common,RarityScalars=rarityValues,Describe=description}
end
boon("volta_arc_discharge","Volta","Дуговой разряд","OnHit",{
	Common={Damage={10,14,18},Cooldown=.9},
	Rare={Damage={13,18,23},Cooldown=.9},
	Epic={Damage={16,23,30},Cooldown=.9},
	Heroic={Damage={20,28,36},Cooldown=.9},
},function(v)
	return string.format("Попадание выпускает разряд: %d урона двум ближайшим зомби в радиусе 18. Не чаще раза в 0,9 с; один раз на выстрел.",v.Damage)
end)
boon("volta_static_shock","Volta","Статический шок","OnHeadshot",{
	Common={Duration={.35,.45,.55},Cooldown=1.5},
	Rare={Duration={.4,.5,.6},Cooldown=1.5},
	Epic={Duration={.45,.55,.65},Cooldown=1.5},
	Heroic={Duration={.5,.65,.75},Cooldown=1.5},
},function(v)
	return string.format("Попадание в голову останавливает цель на %.2f с. Не чаще раза в 1,5 с. Дробины считаются одним попаданием.",v.Duration)
end)
boon("volta_high_voltage","Volta","Высокое напряжение","OnHit",{
	Common={PerStack={.01,.015,.02},Stacks=5,Duration=3},
	Rare={PerStack={.013,.02,.026},Stacks=5,Duration=3},
	Epic={PerStack={.016,.025,.033},Stacks=5,Duration=3},
	Heroic={PerStack={.02,.03,.04},Stacks=5,Duration=3},
},function(v)
	return string.format("Повторные попадания заряжают цель на 3 с: следующие прямые попадания получают +%s%% урона за заряд, максимум 5.",percent(v.PerStack))
end)
boon("bravo_belt_feed","Bravo","Ленточное питание","Weapon",{
	Common={Fraction={.15,.25,.35}},
	Rare={Fraction={.2,.3,.4}},
	Epic={Fraction={.25,.35,.45}},
	Heroic={Fraction={.3,.4,.5}},
},function(v)
	return string.format("Вместимость магазина +%s%% (округляется вверх). Новые места заполняются при обычной перезарядке.",percent(v.Fraction))
end)
boon("bravo_first_salvo","Bravo","Первый залп","OnReload",{
	Common={Bonus={.12,.18,.24},Shots=3},
	Rare={Bonus={.16,.23,.31},Shots=3},
	Epic={Bonus={.2,.3,.4},Shots=3},
	Heroic={Bonus={.24,.36,.48},Shots=3},
},function(v)
	return string.format("Первые три выстрела после завершённой перезарядки получают +%s%% прямого урона. Вставки дробовика не суммируют заряды.",percent(v.Bonus))
end)
boon("bravo_large_caliber","Bravo","Крупный калибр","OnHit",{
	Common={Speed={5,7,9},Cooldown=1.2},
	Rare={Speed={6,8,10},Cooldown=1.2},
	Epic={Speed={7,9,11},Cooldown=1.2},
	Heroic={Speed={8,10,12},Cooldown=1.2},
},function(v)
	return string.format("Попадание отталкивает одного зомби со скоростью %d studs/с. Не чаще раза в 1,2 с. Без вертикального подбрасывания.",v.Speed)
end)
boon("weiss_coagulation","Weiss","Коагуляция","OnKill",{
	Common={Heal={2,3,4},Cooldown=1.2},
	Rare={Heal={3,4,5},Cooldown=1.2},
	Epic={Heal={4,5,6},Cooldown=1.2},
	Heroic={Heal={5,6,8},Cooldown=1.2},
},function(v)
	return string.format("Подтверждённое убийство восстанавливает %d HP. Не чаще раза в 1,2 с, только до максимального здоровья.",v.Heal)
end)
boon("weiss_adrenaline","Weiss","Адреналиновый стимулятор","Damage",{
	Common={Bonus={.2,.3,.4}},
	Rare={Bonus={.26,.39,.52}},
	Epic={Bonus={.33,.5,.66}},
	Heroic={Bonus={.4,.6,.8}},
},function(v)
	return string.format("Прямой урон растёт вместе с потерянным здоровьем: до +%s%% у критического HP. При полном HP бонуса нет.",percent(v.Bonus))
end)
boon("weiss_field_protocol","Weiss","Полевой протокол","Health",{
	Common={MaxHealth={6,10,14},Heal={3,5,7}},
	Rare={MaxHealth={8,13,18},Heal={4,7,9}},
	Epic={MaxHealth={10,16,23},Heal={5,8,12}},
	Heroic={MaxHealth={12,20,28},Heal={6,10,14}},
},function(v)
	return string.format("Максимальное здоровье +%d HP. В начале каждого следующего боя восстановление %d HP; не выше максимума.",v.MaxHealth,v.Heal)
end)
function Catalog.Values(id,level,rarity)
	local definition=Catalog[id]
	local scalars=definition.RarityScalars[rarity or "Common"]or definition.Scalars
	local result={}
	for key,value in scalars do result[key]=type(value)=="table"and value[math.clamp(level,1,definition.MaxLevel)]or value end
	return result
end
return Catalog
