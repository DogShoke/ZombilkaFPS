# FPS CORE 1.0 implementation

## Architecture

- Rojo source: `src/shared`, `src/client`, and `src/server`. Shared `Config` controls movement, camera, pistol, motion, zombie, and audio values. `Spring` supplies time-based damped motion.
- Client: one input/presentation script, a disposable procedural pistol viewmodel, and one persistent HUD. It owns input, first-person camera presentation, sway, bob, strafe tilt, ADS, sprint pose, recoil, muzzle flash, tracer, impact flash, and hitmarker display.
- Server: `WeaponService` owns magazine, fire cadence, reload, raycasts, headshot decision, and damage. `ZombieService` owns humanoid rigs, chasing, windup attacks, flinch, death cleanup, and replenishment. `Arena` builds the test floor, walls, cover, and spawn placement.

## Controls and values

WASD/mouse/Space use Roblox's standard movement and first-person camera. LeftShift sprints, RMB aims, LMB fires one semi-auto shot, and R reloads. Walk/sprint speeds are 16/24. Hip/ADS/sprint FOV values are 70/55/77. The pistol has 12 rounds, infinite reserve, 25 body damage, 50 head damage, and a 1.5 second server reload. Seven zombies can be alive, with a 2.5 second spawn interval.

The viewmodel is temporary primitive geometry. `Config.Audio` has named hooks for all requested gun and zombie sounds, but every asset ID is empty. No audio is audible until authored assets are supplied.

## Studio verification

- Rojo synced all new modules to the expected DataModel paths; later source changes were present in the Studio script sources.
- Multiple MCP Play sessions loaded the arena, first-person lock, centered mouse, HUD, viewmodel, and zombies. Output was empty in the final session.
- MCP input observed sprint speed 24/FOV 77, ADS FOV 55, pistol ammo decrement, and reload returning to 12.
- Client-to-server shot requests yielded an observed 25 damage body hit and 50 damage headshot. A lethal shot removed that zombie; the spawner returned to seven living zombies.
- A 15-shot request sequence depleted the magazine to 0 without going negative. Repeated reload requests produced one reload period and restored 12 rounds. A burst of five immediate requests spent one round; a forged faraway shot origin spent none.
- Zombies moved toward and damaged the player. A forced death and respawn restored first-person mode with exactly one HUD and one viewmodel. A destroyed-viewmodel render error found in the first session was fixed; final Output was empty.

## Remaining tuning

The MCP screen capture exposed only the edit-time Baseplate, so first-person framing and visual quality still need human inspection in the Play viewport. Mouse sway, bob, strafe tilt, recoil feel, zombie attack timing, and overall difficulty need subjective play tuning. The primitive rig, weapon art, impact visuals, and all audio are placeholders.
