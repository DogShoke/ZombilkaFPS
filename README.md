# Zombilka FPS

New Roblox first-person zombie combat sandbox. Rojo 7.7.0 syncs `src/` through `default.project.json` into the open Studio place.

Choose Glock, AKM or Mossberg before the run using the cards or 1/2/3. Zombies start spawning after selection. Death opens selection again.

Floors are generated endlessly from a versioned run seed: four themes and six combat layouts, alternate routes, two defense positions and reachable split-level galleries. The footprint is 264×288 studs. After three introductory floors, the final wave can require a holdout or timed survival followed by mandatory cleanup. Attack directions are announced; generated floors pass runtime navigation checks with bounded retries. Only the current floor and a prepared destination are retained, with at most 16 live zombies.

Подробное описание текущего генератора, его ограничений и мест для изменений: [docs/LEVEL_GENERATION.md](docs/LEVEL_GENERATION.md).

Controls: WASD move, mouse look, Space jump, Shift sprint, C/LeftCtrl slide, RMB aim, LMB fire (hold for AKM), R reload, E elevator.

Mossberg reloads one shell at a time; firing cancels loading and keeps the shells already inserted. Each shotgun shot shows eight pellet tracers.

Movement/world values are in `src/shared/Config.luau`; weapon values and poses are in `src/shared/Weapons.luau`. See `AI/IMPLEMENTATION.md` for Studio observations and `assets/weapons/README.md` for the textures, rigs and animations.
