# FPS CORE 1.0 implementation

## Architecture

- Rojo source: `src/shared`, `src/client`, and `src/server`. Shared `Config` controls movement, camera, pistol, motion, zombie, and audio values. `Spring` supplies time-based damped motion.
- Client: one input/presentation script, the authored FpsGlock viewmodel, and one persistent HUD. It owns input, first-person camera presentation, sway, bob, strafe tilt, ADS, sprint pose, recoil, muzzle flash, tracer, impact flash, and hitmarker display.
- Server: `WeaponService` owns magazine, fire cadence, reload, raycasts, headshot decision, and damage. `ZombieService` owns pursuit, attack, death, and replenishment; `ZombieRig` owns procedural visual construction and poses. `Arena` builds the test floor, walls, cover, and spawn placement.

## Controls and values

WASD/mouse/Space use Roblox's standard movement and first-person camera. LeftShift sprints, RMB aims, LMB fires one semi-auto shot, and R reloads. Walk/sprint speeds are 16/24. Hip/ADS/sprint FOV values are 70/55/77. The pistol has 12 rounds, infinite reserve, 25 body damage, 50 head damage, and a 1.5 second server reload. Seven zombies can be alive, with a 2.5 second spawn interval.

The viewmodel is the authored FpsGlock rig. `Config.Audio` has named hooks for gun, impact, zombie, and player sounds, but every asset ID is empty. No audio is audible until authored assets are supplied.

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

## ZOMBIE COMBAT + AUDIO + VISUAL POLISH 1.0

### Zombie presentation and asset handoff

The repository has no authored zombie asset. `ZombieRig` keeps the server-owned R6-style humanoid functional while separating its appearance and procedural gait, attack pose, flinch, spawn fade, and collapse from AI. The shell now has variant skin/jacket colors, a simple face and torn jacket detail. These details do not intercept weapon raycasts. No Toolbox content was imported. To replace it with a proper asset, provide a Roblox model with a Humanoid, HumanoidRootPart, named Head and torso hit regions, working Motor6D/Animator rig, walk/idle/attack/hurt/death animations, and permission for this experience to use any mesh, texture, or animation IDs. Preserve the model's root and hit-region contract when adapting `ZombieRig.Create` and `ZombieRig.Pose`.

### Behavior, combat, and spawning

`ZombieService` uses explicit Spawn, Idle, Chase, AttackWindup, AttackRecover, HitReact, and Dead states. Dead removes the zombie from active targeting and cannot transition back. Normal body hits show a short visual flinch without interrupting an ongoing attack; headshots have a longer head/torso snap and can interrupt windup. Repeated hits use a serial to avoid stale color resets. Direction supplies a small visual twist without physics impulses.

Zombies take direct MoveTo pursuit when a throttled line-of-sight probe is clear. Obstacles trigger a path, recomputed at most on the configured interval, with waypoint progression, fallback direct movement, and a stuck jump/repath check. Stable per-zombie approach angles and personal-space steering spread the group around the player. Crowd work is quadratic in the deliberately small seven-zombie cap and runs only at the configured think interval; no per-zombie Heartbeat or per-frame path calculation is used. Zombie/player collision groups remain noncolliding to avoid pushing or pinning.

Attacks have a visible arm/torso windup, a single server damage moment after 0.48 seconds, recovery, and a per-zombie cooldown. A shared per-player 0.75 second windup gate spaces out simultaneous attackers. Range and sight are checked at the damage moment, so leaving range or breaking sight avoids the hit. The client shows a brief red edge vignette, small camera impulse, and compact health bar/number. Damage and health stay server-owned.

Death immediately leaves the combat set, disables corpse collision and raycast targeting, anchors a controlled fall, then fades and removes the corpse after 3.5 seconds. Headshot kills fall faster/further. Spawns use existing zones, 36-105 stud distance limits, a check against walls and cover, separation from other zombies, and a preference for positions outside the player's frontal view. New zombies fade in. Replacements wait at least one second after a death and still obey the 2.5 second spawn cadence; no wave or difficulty system was added.

### Audio and visual feedback

`Config.Audio` is the registry for layered gunshot/mechanical sounds, reload/empty, concrete/metal/wood/generic impacts, body/head confirmation, optional zombie groan, zombie hurt/attack/death, and player hurt. `Audio.Play` makes one short-lived Sound per event, supports volume/pitch and world rolloff, and safely returns when an ID is empty. Zombie hurt sounds are throttled and groans are infrequent. **All IDs remain empty** because this repository has no sound assets; no IDs were fabricated. Supply licensed sound IDs for those named slots to hear them.

The server sends its raycast material, normal, and direction with shot confirmation. Client impacts use restrained, directional blood bursts or tinted concrete dust, metal sparks, wood debris, and generic particles. World impacts leave a tiny temporary mark. All effect instances use Debris cleanup. The barrel flash and tracer were made slightly smaller and shorter, especially for ADS; the existing recoil and FpsGlock architecture remain intact. Headshots retain the stronger gold hitmarker and distinct sound slot.

Lighting now uses a brighter late-day ambient balance, slight color grade, and short distant fog without hiding targets. The arena layout remains the same; floor seams, material contrast on cover, trim, wall lamps, and a clearer spawn pad improve legibility. Cosmetic seams and trim do not intercept raycasts.

### Studio MCP verification and review

- Rojo synchronized the new `Shared.Audio` and `Server.ZombieRig` modules and updated script sources into the connected Place1. Two Play sessions loaded the arena, Glock, HUD, and zombie crowd with empty game Output after the substantial changes.
- Runtime inspection observed Spawn/Chase/AttackWindup/AttackRecover/Idle states, zombie pursuit to attack range, health loss from attacks, one server-confirmed 50-damage headshot, and a 25-damage body hit. The body-shot test tool itself raised an inspection-only error because it looked for an unnamed HUD label; the shot succeeded, and the labels are now named.
- A forced lethal headshot immediately set Dead, anchored the collapse, disabled Head query, reduced the alive count, then returned to seven alive with no corpse after four seconds. A forced player respawn restored one Glock and one HUD; the health display followed server Humanoid health, and the cursor remained hidden.
- After the first successful run, attack starts were spaced, spawn checks were tightened, corpse color reset was added, and the flash/tracer sizes were reduced. A final Play session confirmed the synced 0.75 second coordination gate, seven-zombie cap, new arena detail, one HUD/one Glock after forced respawn, hidden cursor, and an empty game Output. A real mouse click produced one observed muzzle flash, tracer, impact anchor, and ammo decrement. Server observations showed AttackWindup at 0.83 seconds, AttackRecover and exactly 12 damage at 1.33 seconds, then the next attack at 1.66/2.16 seconds. Client observation caught damage overlay animation and health HUD updates. Server-confirmed body/head shots showed 25/50 damage and HitReact. A forced body kill set Dead, disabled attacking/query/collision, and anchored the collapse. No game runtime errors were found; one MCP inspection snippet used an incorrect HUD label name and was corrected in source. Studio MCP screen capture is edit-time only, so live visual feel, audio mix after IDs are supplied, animation quality, lighting, and difficulty still need human Play viewport review.
