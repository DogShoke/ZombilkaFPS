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

At the end of CORE 1.0, MCP capture exposed only the edit-time Baseplate. The combat-feel milestone below records the later authored viewmodel integration and static framing inspection.

## FPS COMBAT FEEL 1.0

- The only active viewmodel is the authored `assets/FpsGlock.rbxm`, mapped by Rojo to `ReplicatedStorage.Assets.FpsGlock`. The client clones its `RootPart`, two skinned meshes, `Barrel` bone, and `AnimationController` under `CurrentCamera`. Parts have collision, touch, query, and shadows disabled; no runtime scaling is applied. The block pistol was removed from runtime code.
- The Animator plays Idle (`105345463794666`) continuously, Shoot (`128130246447749`) on fire, and Reload (`130294402000435`) on reload. Grip and Inspect IDs remain in shared config for later.
- Cursor is hidden with `MouseIconEnabled = false` and the mouse remains center locked. The client reapplies both on spawn and each gameplay render frame.
- Sprint fire is allowed at sprint speed. A shot briefly blends the viewmodel toward hip pose, then back to sprint pose after a configurable 0.26 second hold. RMB exits sprint and enters ADS. Rojo code keeps sprint speed and firing separate.
- Whole-rig transform order is camera frame → hip/sprint/ADS pose → sway/recoil/bob/strafe/landing translation → sway/recoil/strafe rotation. Animated bones and joints are left to the Animator.
- FOV remains 70 hip, 55 ADS, 77 sprint. Static FOV 55 asset captures informed the real-rig ADS pose `(-1.02, -0.70, -1.2)` with a -90° yaw. Hip and sprint poses, spring rates, sway, bob, strafe, recoil, sprint fire response, and landing impulse are tunable in `Config.Feel`.
- Viewmodel recoil now starts with a visible rearward/rotational offset and recovers through a time-based spring. Camera recoil is separate: a small upward pitch with minor yaw, with partial recovery so the aim is not pulled fully back.
- The `Barrel` bone positions a short flash emitter and PointLight. A short Beam streak traces from the muzzle; confirmed world/body/head impacts emit restrained particles. Debris removes every transient endpoint and impact anchor; the light returns to zero.
- The HUD uses a smaller ammo label, a fading/tightening ADS crosshair, distinct gold headshot marker, and a brief damage overlay. Server-confirmed feedback drives hitmarkers.
- Zombies now approach around the player with crowd separation and a preferred minimum attack distance. Body hits tilt the torso briefly; headshots add a neck snap. Reactions reset by serial number so repeated hits cannot leave the rig bent. A headshot kill falls more sharply. Attack windup, single damage moment, death cleanup, and replacement spawning remain server-owned.

### MCP verification and remaining review

- Rojo sync showed the RBXM model and changed sources in Studio. Repeated Play sessions produced no game-script errors. The final injected mouse click produced Studio test-automation CoreGUI warnings in Output; the shot still fired.
- In Play, the real model replaced the block model, Idle was playing, Shoot and Reload playback events fired with the expected IDs, and the cursor stayed disabled. A sprint shot spent a round while WalkSpeed stayed 24; sampled viewmodel poses moved from sprint toward hip and returned. Sprint + RMB entered ADS at speed 16/FOV 55.
- ADS runtime inspection put the barrel near screen center in camera coordinates (x about 0.03 studs). Static edit-time captures checked hip, ADS, and sprint framing at their target FOV values; the follow-up tuning moved the ADS pose to center and lowered the sprint gun.
- Sampled muzzle light turned on briefly, then returned to zero. The Beam endpoint and impact anchors cleaned up. A recoil sample caught a downward camera kick; its sign was fixed and the next sample showed upward pitch. A later viewmodel recoil sample led to a stronger immediate kick and slower recovery.
- Server tests again confirmed 25 body and 50 head damage, lethal cleanup, replacement spawning, and zombie damage to the player. A crowded wall sample initially found close stacking; after tuning, a sampled group had about three studs between its closest zombies and the closest zombie was about three studs from the player. A forced respawn recreated one Glock viewmodel and one HUD with Idle playing, hidden cursor, and center lock.
- Audio hooks are ready, but **all** `Config.Audio` IDs remain empty: pistol gunshot, mechanical shot, reload, empty click, body hit, headshot, zombie hurt, attack, and death still need authored sound assets. Studio MCP could capture only edit-time framing; live visual feel, animation quality, sound mix, recoil intensity, and final difficulty still need manual Play viewport evaluation.
