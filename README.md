# Zombilka FPS

New Roblox first-person zombie combat sandbox. Rojo 7.7.0 syncs `src/` through `default.project.json` into the open Studio place.

Choose Glock, AKM or Mossberg before the run using the cards or 1/2/3. Zombies start spawning after selection. Death opens selection again.

Floors are generated endlessly from a run seed: offices, laboratories, warehouses and parking areas, with side rooms, multiple routes and occasional upper galleries. The footprint is 264×288 studs (about 3.1× the previous floor area). Only the current floor and a prepared destination are retained. Waves and zombie strength increase gradually, with at most 16 live zombies.

Controls: WASD move, mouse look, Space jump, Shift sprint, C/LeftCtrl slide, RMB aim, LMB fire (hold for AKM), R reload, E elevator.

Mossberg reloads one shell at a time; firing cancels loading and keeps the shells already inserted. Each shotgun shot shows eight pellet tracers.

Movement/world values are in `src/shared/Config.luau`; weapon values and poses are in `src/shared/Weapons.luau`. See `AI/IMPLEMENTATION.md` for Studio observations and `assets/weapons/README.md` for the textures, rigs and animations.
