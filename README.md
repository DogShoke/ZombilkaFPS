# Zombilka FPS

New Roblox first-person zombie combat sandbox. Rojo 7.7.0 syncs `src/` through `default.project.json` into the open Studio place.

Choose Glock, AKM or Mossberg before the run using the cards or 1/2/3. Zombies start spawning after selection. Death opens selection again.

Current milestone: one authored Office OpenArena on the fixed 5×5 grid, 36-stud cells and 180×180 footprint. Seed selects complete desk/reception/server/lounge tile variants; individual props never scatter. The central landmark, small raised tile with two ramps, clear entrance and four corner spawn edges keep fixed roles. Other layouts are temporarily disabled in ordinary Play; later floors repeat this topology with different modules. Existing KillQuota, continuous horde, ground emergence, 16-enemy cap and elevator remain. Actual tile bounds, collisions, entrance views and navigation are validated. See docs/LEVEL_GENERATION.md and src/server/OfficeTiles.luau to edit the prototype.

Подробное описание текущего генератора, его ограничений и мест для изменений: [docs/LEVEL_GENERATION.md](docs/LEVEL_GENERATION.md).

Controls: WASD move, mouse look, Space jump, Shift sprint, C/LeftCtrl slide, RMB aim, LMB fire (hold for AKM), R reload, E elevator.

Mossberg reloads one shell at a time; firing cancels loading and keeps the shells already inserted. Each shotgun shot shows eight pellet tracers.

Movement/world values are in `src/shared/Config.luau`; weapon values and poses are in `src/shared/Weapons.luau`. See `AI/IMPLEMENTATION.md` for Studio observations and `assets/weapons/README.md` for the textures, rigs and animations.
