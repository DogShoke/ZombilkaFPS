-- Pure seeded layout data; geometry, enemies and progression are built separately.
local Config = require(game.ReplicatedStorage.Shared.Config)
local G = Config.Run.Generation
local FloorLayout = {}
local labels = { Office="ОФИСЫ", Laboratory="ЛАБОРАТОРИИ", Warehouse="СКЛАД", Parking="ПАРКИНГ" }
function FloorLayout.Generate(runSeed, number)
	local seed = (runSeed + number * 104729) % 2147483647
	local rng = Random.new(seed)
	local themes = table.clone(G.Themes)
	local themeRng = Random.new(runSeed)
	for i=#themes,2,-1 do local j=themeRng:NextInteger(1,i) themes[i],themes[j]=themes[j],themes[i] end
	local theme = themes[(number-1)%#themes+1]
	local upper = number>1 and (number==2 or rng:NextNumber()<G.UpperChance)
	local side = rng:NextInteger(0,1)==0 and -1 or 1
	local rooms, occupied = {}, {}
	local function key(x,z) return x..":"..z end
	for x=-2,2 do if x~=0 then for z=-2,2 do
		-- Keep the central spine and both gallery approaches unobstructed.
		if not occupied[key(x,z)] and not (upper and x*side>0 and math.abs(z)<=1) then
			local merge = z<2 and not occupied[key(x,z+1)] and not (upper and x*side>0 and math.abs(z+1)<=1) and rng:NextNumber()<0.3
			occupied[key(x,z)]=true
			if merge then occupied[key(x,z+1)]=true end
			local kinds = theme=="Office" and {"Workstations","Meeting","BreakRoom","Archive"}
				or theme=="Laboratory" and {"Lab","Lab","ServerRoom","Storage"}
				or theme=="Warehouse" and {"Storage","Storage","Workshop","Archive"}
				or {"ParkingBay","ParkingBay","Workshop","Storage"}
			table.insert(rooms, { X=x*G.CellSize, Z=(z+(merge and .5 or 0))*G.CellSize,
				Width=G.RoomSize, Depth=G.RoomSize+(merge and G.CellSize or 0),
				Kind=kinds[rng:NextInteger(1,#kinds)], Enclosed=theme~="Parking" and rng:NextNumber()<.72,
				Glass=theme=="Laboratory" or rng:NextNumber()<.3, Variant=rng:NextInteger(1,4) })
		end
	end end end
	return { Seed=seed, Number=number, Theme=theme, Label=labels[theme], Rooms=rooms,
		Upper=upper, UpperSide=side, AccentIndex=rng:NextInteger(1,4), Signature=theme..":"..seed }
end
return FloorLayout
