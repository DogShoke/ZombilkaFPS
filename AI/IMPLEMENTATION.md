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

## OFFICE OUTBREAK 1.0 — implementation and observed verification

The playable prototype now has two reusable office layouts, three server-owned waves per floor, an elevator loop, C slide and O sensitivity/options. FpsGlock.rbxm is unchanged. The old Zombilka repository was never inspected. This section supersedes the sandbox descriptions and empty-audio statements above.

### Accepted reload presentation

The root cause was two client paths: R locally played Reload before server acceptance, while empty LMB only requested a reload. Both now send the Reload request. WeaponService validates and starts its one server-owned 1.5s reload, then sends `ReloadStarted(duration, serial, character)`. The owning client plays animation/audio only from that event. Serial and character guards reject duplicates/stale starts. Repeated requests during reload are ignored by the server. Playback speed is clip length / authoritative duration; Reload stops at completion while looped Idle stays available. The only bounded readiness check observes animation Length, never ammo per frame.

### Movement and settings

SlideController runs bounded horizontal movement before simulation, using Humanoid WalkSpeed/Move and AssemblyLinearVelocity while retaining gravity. It preserves initial direction, limits steering and sweeps a body box with the Players collision group and RespectCanCollide. No BodyVelocity or persistent acceleration is used. C requires a new press, life, ground, movement and cooldown; ADS, jump, menu/travel, death, losing ground, low speed and duration cancel it.

Final config: minimum speed 15, initial speed 30, final speed 16, stop threshold 7, duration 0.8s, cooldown 0.45s, steering response 1.3, exit/jump horizontal cap 24. Camera drop is 1.3 studs, response 14, slide FOV 80. Camera height and FOV blend back smoothly. The transform remains camera -> hip/sprint/ADS pose -> SlideOffset -> recoil/sway/bob/strafe; authored joints/bones remain Animator-owned. Shooting does not cancel slide. RMB cancels slide before ADS. Space returns to ordinary jump.

SettingsController creates one persistent SettingsGui with a 0.20-2.50 slider, default 1.00, numeric Russian label and O toggle. It applies UserInputService.MouseDeltaSensitivity once; the existing Roblox camera consumes it. Value survives respawn within the session. Options unlocks the cursor, blocks fire/ADS/sprint/slide/jump, hides crosshair and requests central pause. WeaponService also rejects fire/reload during Options or elevator travel. No DataStore is used.

RunClock freezes wave deadlines and zombie attack/spawn timing. Active zombie roots and Animator tracks pause; the exact pre-pause track speeds are restored, preserving attack timing. Dead-corpse cleanup remains bounded by wall time.

### Office, waves and elevator

OfficeMap builds `Workspace.OfficeRun.Floor01/Floor02`, each with Geometry, Props, ZombieSpawns, ElevatorLobby and PlayerSpawn. Floors are 156x156 studs, at heights 180/212, with 16-stud ceilings, broad central/perimeter/cross routes, windows, a distant skyline, overhead lighting, emergency accents and wayfinding. Floor 1 emphasizes cubicles; Floor 2 emphasizes conference tables, glass meeting boundaries and executive desks. Reception, kitchen/break corner, storage/copier, plants and side routes are present. Part-built furniture is combined with the sanitized Creator Store Office Chair; cosmetic pieces are noncolliding where appropriate. Visual captures exposed oversized chairs and a reception sign at sight height; chair scale, lighting and the overhead sign were corrected. Final map preview has 754 descendants, including lights, UI and distant skyline.

FloorDirector owns WaitingForPlayer, FloorIntro, WaveActive, BetweenWaves, FloorCleared, ElevatorAvailable, ElevatorTravel and NextFloor. Waves are 5/7/9, intro/inter-wave delays 4s, paced spawning 1.15s. Eight distributed zones enforce minimum distance 32, maximum 210, obstacle overlap and zombie separation checks, with a preference away from the player's front. Completion requires the entire budget spawned AND zero living wave zombies. Zombies no longer replenish indefinitely.

Doors use deterministic 0.85s tweens, disabled collision during motion and green/red status. The prompt is enabled only after the third wave; its server handler additionally validates the owner, floor, live character, cabin bounds, zero zombies and complete budget. Activation is accepted once. The passenger is secured inside, doors close, the director waits 3.5s, then relocates to the other closed cabin, opens doors and releases the passenger. A small camera vibration, upward HUD and arrival ding support travel. The next intro waits for actual cabin exit before doors close. Floor number increments independently of the layout index; Floor 3 reuses layout 1, so the loop can repeat without building additional maps. Death restarts the current floor's waves. Old zones no longer spawn.

The HUD shows Russian floor/wave/remaining-enemy information and concise clear/elevator/arrival messages. It updates from replicated attributes; client requests cannot clear waves or unlock the elevator.

### Zombie presentation and audio

ZombieAsset is a sanitized snapshot of Roblox Drooling Zombie (187789986), including its R6 joints, body meshes/textures and face. Eight imported scripts/modules were disabled and removed in Edit mode; none of its AI architecture runs. Existing server pursuit, pathfinding, coordinated attacks, damage, hit detection and cleanup remain in ZombieService. Path-computation continuations now check that the zombie still exists before using a destroyed rig.

Animator clips: Idle 125750544 (Idle), Run 125749145 (Movement), Attack 180416148 (Action). Run speed follows measured horizontal speed relative to configured speed 11. Attack playback spans windup/recovery; damage remains the validated server moment at 0.48s and never depends on an animation loading. BodyHit, HeadHit and Death are original short KeyframeSequences in ZombieClips, with Action2/Action3/Action4 track priority. Reactions are bounded/throttled; death immediately removes AI, attack, collision and query, then cleans up after 3.5s.

BodyHit/HeadHit/Death work as registered Animator clips in Studio. For published servers, the experience owner must publish the editable `ServerStorage.OfficeAuthoredClips` sequences and fill the three Config.ZombieAnimations slots. Until then, finite joint/death fallback poses keep live combat functional. Temporary Studio registration IDs are not saved as published IDs.

AudioConfig centralizes validated gunshot 3806566911, reload 3821789416, zombie growl 121066883602737 and arrival ding 18192219147. Mechanical/empty layers use short excerpts of reload; zombie states currently reuse a spatial growl with varied pitch/volume and spam throttling. These are prototype choices requiring listening review. Door/motor, impact, hit-confirmation and player-hurt slots remain documented and empty. Full provenance, mesh/texture/animation IDs and script-removal details are in AI/ASSETS.md. The current Glock visuals were not replaced by Roblox Pistol.

### Studio MCP evidence

Tests were performed on connected ZombilkaFPS.rbxl on 2026-10-01, with continuation/final checks on 2026-10-04. Repository source was copied into the matching Studio instances through MCP; no Rojo server process was detected, so automated live Rojo syncing is not claimed.

- Real R after a shot and 12 shots followed by repeated empty LMB produced two total accepted Reload plays, with no duplicate empty-click restart. Loaded Reload length was 2.041667s and speed 1.361111; ammo returned to 12 and only Idle remained playing. The final October 4 repeat observed the same values and Idle length 2.083333s.
- Real C after sprint ran for about 0.8s, peaked near 29.7-29.92, ended near 16.3 and dropped camera about 1.30 studs; FOV approached 80 and height/FOV restored. Holding C produced one start. Space exited to jump with measured maximum horizontal airborne speed 24 and no sliding while airborne.
- A temporary Studio-only local harness called the same input action functions for sub-second combinations: sprint shot spent ammo at WalkSpeed 24; slide shot spent 11 -> 10 while slide stayed active; slide -> ADS cancelled slide and restored camera to approximately zero/FOV 55. The harness was removed from Edit source, and no test hook is in the repository. Direct virtual mouse injection was denied by Roblox capability checks; that attempt was abandoned. Real mouse and keyboard tests cover the separate input bindings.
- O visibly enabled SettingsGui, unlocked/shown cursor and hid crosshair. A real slider click set both displayed sensitivity and MouseDeltaSensitivity to 1.93. Closing restored center lock. One-second server samples during Options showed zero health/spawn/simulation-time advancement.
- Both floors completed all three 5/7/9 budgets. Runtime tests intentionally used server TakeDamage to advance waves and preserved the final living zombie before each wave completion: state stayed WaveActive, alive was 1 and prompt stayed disabled for all six samples. These are state-machine tests, not a claim of manually playing all combat at normal health.
- After final death, doors opened to x +/-13.2 and prompt enabled. Actual E activated the elevator. Observed Floor 2 arrival at y215, NextFloor, open doors and released root; actual exit began its first wave. The subsequent Floor 2 -> Floor 3 transition reused layout 1 at y183 with display floor 3 and new combat. The closed-door relocation represents upward travel even when the reusable layout changes physical height.
- Server-authoritative test shots dealt 25 body then 50 head damage (100 -> 25), fired BodyHit and HeadHit, then lethal head damage played Death. Head query/collision were disabled and corpse removed. Idle, Run and Attack playback were observed on live zombies.
- Forced death/respawn, including while Options was open, left one HUD, one SettingsGui, one FpsGlock, Sliding=false, CameraOffset=0, unlocked server root and fresh FloorIntro. Mouse remained hidden/center locked. The latest check had empty server Output and no game-script errors.
- Pause playback test: a Run track at 0.65 changed to 0 during pause and returned to 0.65 afterward.
- PreloadAsync succeeded for Glock animation IDs, zombie Run and gun/reload sounds. Initial cloud fetches temporarily failed for the avatar mood and Glock clips; subsequent preload/restart loaded them successfully. Hidden-avatar appearance is disabled in StarterPlayer and early server initialization to avoid the user's catalog mood. MCP mouse interpolation also emitted TestAutomationUtils/CoreGUI warnings; those are tool-generated and are distinguished from game-script errors. After clearing historical tool messages and observing the final run, client and server gameplay logs had no new errors.

### Remaining human review and publishing

The prototype loop is implemented and mechanically tested. Production art/sound quality is not declared verified by MCP. Review slide feel, sensitivity range, office navigation/cover, zombie animation weight, normal-health difficulty, lighting/atmosphere and the sound mix in the actual Play viewport. Additional ready-made environment props and unique hurt/attack/death recordings remain an art pass. Publish the three authored zombie reaction/death clips before relying on Animator playback in a live experience; recheck animation/audio permissions in that published experience.

No automatic commit was made. An existing WIP checkpoint (878348c) was present when development resumed on October 4. Final source diff was inspected; git diff --check passed, default.project.json parsed successfully, FpsGlock asset had no diff, and no temporary QA hook remained in source. The pre-existing modified rbxl is not overwritten by a shell export.

## 2026-10-04 user revision: remove settings and fix movement

Supersedes the settings behavior described above. Removed SettingsController, O HUD hint, Options remote/server handler, OptionsOpen combat gates and slider config. Camera sensitivity is a fixed shared Camera.MouseSensitivity (1). Native Roblox menu and elevator input gates remain.

Sprint no longer requires grounded FloorMaterial: held Shift plus movement preserves WalkSpeed 24 through Jumping/Freefall. Added Movement.SlideInputBuffer (0.18s), so a quick C press waits for actual movement speed to reach the existing minimum; cancellation clears pending input. Existing slide cooldown, collision sweep, steering and speed cap remain.

Observed in connected ZombilkaFPS Studio using real keyboard input:
- Quick W + Shift + C: slide activated, peak horizontal speed 29.97, camera drop 1.30 studs. Subsequent sprint jump retained WalkSpeed 24 and horizontal speed approximately 24 in 116 airborne frames.
- Established sprint -> C -> Space after 0.2s: slide canceled before airborne frames, horizontal speed remained approximately 24, camera offset returned to zero. Releasing Shift restored WalkSpeed 16.
- SettingsGui and Options remote absent; O no longer opens a settings GUI. Output was empty after both tests.
- Edit sources exactly match repository; play mode stopped. No runtime QA hooks added to repository sources. No commit or place-file export performed. git diff --check -- src AI passed.

## 2026-10-04 held sprint / slide input revision

C now uses ContextActionService at High priority + 1, independently of processed InputBegan events. Text boxes, native menu and elevator blocking still prevent gameplay input. Sprint intent is read from held LeftShift/RightShift each render frame, instead of relying on edge events. Slide cancellation immediately restores the requested WalkSpeed before physics, including held sprint.

Lowered shared JumpPower from 50 to 38 and explicitly applied UseJumpPower=true/JumpPower on the server for every character spawn. The previous shared jump setting was unused; it now controls player jumping.

Final Studio test used an unobstructed temporary runtime lane: W and LeftShift held continuously; C pressed twice with no Shift release; both slides started/ended; WalkSpeed after each slide remained 24 and current horizontal speed returned to 24. Shift was still held and release-event count was zero. Jump apex was approximately 2.30 studs above grounded root height, measured airborne time 0.334 seconds, airborne WalkSpeed 24. Output empty. Temporary lane and observation hooks removed by stopping Play; no test instances/source persisted. No commit.

## 2026-10-04 — physical slide input and textured game asset

Actual user input was observed in Studio. W + Shift + C never reached InputBegan or IsKeyDown(C); C without Shift did reach the client. This invalidates prior synthetic-key tests as proof that the physical chord works. Added LeftControl as an alternate slide key, retained C, preserved the Studio assistant's processed-input fallback in Rojo source, and added rising-edge key polling. Text entry/menu restrictions remain. User confirmed LeftControl works while sprinting. Final runtime check: continuous W + LeftShift, two LeftControl slides, two starts/two ends, both exit WalkSpeed values 24, Shift still held. The lost physical Shift+C chord remains an external input issue; no claim that it was repaired.

Imported FpsGlock_FullyTextured assigned Arms ColorMap 104563458117746 and Glock ColorMap 76283602140992 with white MeshPart colors. New persistent arms mesh 119543931671165 and gun mesh 72354353674240 applied to a copy of the existing game template; existing part sizes/CFrames, motors, 30 bone names/parents/rest poses, 132 CFrameValues and AnimationController retained. Original assets/FpsGlock.rbxm was not overwritten. New assets/FpsGlock_GameTextured.rbxmx is the Rojo FpsGlock source. Both maps verified on the imported model under temporary inspection light; light and local EditableMesh preview removed. Runtime viewmodel loaded both mesh IDs/maps and 30 bones, Idle length 2.083 seconds playing, animation bone translation observed during shoot/reload. Output empty. Rojo build passed; generated QA place removed. No commit.

## 2026-10-04 — higher, quicker jump

User identified and changed a Studio Shift+C shortcut; physical Shift+C now works. Previous missing key input was an editor shortcut conflict, not a slide physics failure.

JumpPower increased from 38 to 50. New small client JumpController applies extra vertical gravity only during an initiated jump: ascent multiplier 1.65, descent 2.15, configured in shared Movement. Center-of-mass VectorForce has world-relative vertical force only, no horizontal velocity changes and no global gravity changes. Clears on landing/death/other humanoid states; rebind disconnects old listener and removes old force/attachment. Existing sprint/slide cancellation and landing presentation retained.

Observed Studio runtime on a temporary safe flat lane: final power-50 jumps from rest and sprint each rose about 6.11 studs, reached apex around 0.191s, landed around 0.354s. Sprint airborne WalkSpeed/horizontal velocity stayed 24. Jump out of a slide was also exercised with the initial stronger candidate before tuning down. Same-session old settings (38, additional force disabled) rose 4.22 studs, apex 0.204s, landing 0.386s. Grounded final force zero. These are current observations, replacing reliance on prior jump measurements. Final shared config synced to Edit, temporary lane/hooks removed by Stop. Rojo build and diff checks passed. No commit.

## 2026-10-04 — soften jump descent

User found the previous descent too fast and wanted longer sprint/slide jumps. Kept JumpPower 50 and ascent multiplier 1.65; reduced JumpFallGravity from 2.15 to 1.15. Studio runtime on an unobstructed temporary lane: sprint jump and jump 0.18 seconds into a slide each rose 6.11 studs, traveled 9.80 studs, stayed airborne about 0.408s, and retained WalkSpeed 24. Slide start observed. Previous tuning lasted approximately 0.354s, so flight time/distance at the same sprint speed increased about 15%. Output empty. Stopped Play to remove temporary lane/observers; shared config synchronized. No commit.

## 2026-10-05 — longer jumps, cursor and ten imported zombies

Cursor enforcement moved to its own final RenderStep, independent of character/viewmodel readiness. JumpFallGravity is 0.65 and sprint airborne speed is 28 (ground speed 24); power 50 and ascent multiplier 1.65 remain. Observed sprint and slide-exit jumps on a temporary safe lane: 13.218 studs distance, 6.110 studs height, about 0.4795 seconds airborne, landing WalkSpeed 24. This is approximately 35% farther than the previous 9.80-stud tune. Cursor was hidden during runtime checks. User fixed the Studio Shift+C shortcut conflict earlier; that diagnosis remains valid.

Split the user-provided zombie FBX into ten bodies (Female A-E / Male A-E) with four matching accessories. Repaired original FBX cluster/rest bind disagreement, retained source files and original UVs, normalized complete mesh/skeleton copies, and exported individual FBXs plus Zombies_All_Roblox.fbx. The user imported the corrected combined file. Studio templates rotate the complete skeleton and meshes from Z-up to Y-up and uniformly scale from 1.8 to approximately 6 studs. Each character gets one retained pelvis subtree with its own 26 or 30 imported bones and body/accessory motors. All share palette texture 135266649823455.

Ten standalone rbxmx templates are stored in assets/zombies/roblox and mapped to ReplicatedStorage.Assets.Zombies by default.project.json. Actual mesh IDs are recorded in RobloxAssets.json. Server ZombieVariants supplies invisible physical root/torso/head hitboxes and welds the imported visual rig to them. ZombieRig keeps server movement, health, spawn fade, pause and corpse behavior. ZombieVisuals drives client bone presentation for idle, walk, attack and reaction; source actions are retained in the prepared blend, but have not been retargeted/published as Roblox clips. Legacy ZombieAsset/Clips remain a fallback when templates are unavailable.

Studio runtime observed all ten prepared variants standing at root Y=183 on a temporary floor at Y=180; head/root offsets were approximately 2.49-2.68 studs, walking reached 11 studs/s, thigh pose varied by about 40 degrees over 1.5 seconds. Normal waves spawned the new variants. Validated remote shots dealt 25 body / 50 head damage; three attacks each dealt 12; a real registered zombie died with State Dead and zero query/collision parts. Console was empty. A fresh Rojo server parsed the saved rbxmx sources; reconstructed templates had Model scale 1 with baked part/bone values, correctly textured upright geometry, and spawned again in Play with arm pose variation approximately 18 degrees. Thus the saved assets, not only imported Studio copies, were exercised. All seven edited code/config sources were compared against the fresh Rojo data and matched.

Temporary runtime lanes/observers were removed by Stop. Edit preview and inspection light removed. User-imported source group preserved in ServerStorage.ZombiesSourceImport. The original live Blender Glock scene and original FpsGlock.rbxm were not changed. Obsolete huge export and diagnostic output removed. No commit. The existing Rojo process did not hot-reload the changed project mapping; the connected Edit folder was synchronized from the fresh project's canonical data. Restart/reconnect the normal Rojo session when needed to pick up the new Assets.Zombies mapping.

## 2026-10-05 — Glock / AKM / Mossberg selection

Added shared Weapons definitions, server-authorized selection and per-weapon combat, three client selection cards with rendered model images, automatic AKM firing and eight-pellet Mossberg shots with range falloff. FloorDirector waits in ChoosingWeapon with no spawning; hands/HUD are empty and movement is blocked until choice. Respawn resets selection. Magazine/reload/combat remain server-owned. Glock keeps its original template and published clips.

Prepared copied user GLBs in background Blender: repaired visible bind poses, retained weights, baked four 2048px sRGB color maps, assembled separate shotgun and arms and authored Idle / pump Shoot / shell-loading-hand Reload actions. Sampled AKM source actions and Mossberg authored actions into compressed local motion modules. Final FBX contains one BaseColor UV/material per mesh. Initial two-UV exports mapped incorrectly in Studio; replaced with single-UV versions and user confirmed textures. Imported meshes/textures/cards and persistent rbxmx templates are documented in assets/weapons.

Corrected the complete Studio assembly basis while retaining imported bind Bone.CFrame and motor offsets. Motion deltas are converted through the same RigBasis; simply rolling the visible weapon inverted reload motion. ADS uses source rear/front sight points. Barrel attaches at the front bore cross-section, uses animated Bone.TransformedWorldCFrame, and creates a frozen tracer origin at emission instead of moving an existing trace with recoil.

Observed Studio: cards/images loaded; ChoosingWeapon had zero spawned/alive zombies and no camera viewmodel. Selecting started FloorIntro then WaveActive. AKM held fire depleted its magazine and reload restored 30 rounds after 2.6s. Mossberg emitted eight impact events for one shell, pump transform varied about 0.263 studs, reload accepted 3.6s, and close-range full hits dealt 96 body / 144 head damage. Both final ADS views were inspected in the viewport. Two AKM tracer creation samples measured zero offset from the animated Barrel. Respawn returned to cards with zero spawned; invalid Order selection was ignored, and mid-run switching from Glock to AKM was rejected. Glock Idle (2.083s) and accepted Reload (2.042s source clip, fitted to 1.5s) were observed playing. Cursor hidden after selection. Final clean-session Output was empty.

Fresh Rojo parsed disk rbxmx and reconstructed AKM (38 instances) / Mossberg (37) through AssetService without property errors; those reconstructed templates were exercised in Play. All eight edited gameplay/module sources matched the connected Edit sources. Build and diff checks passed. Corrected original imports archived under ServerStorage.WeaponsSourceImport; old broken-UV copies removed. Stop removed temporary targets, hooks and test health changes. No commit, no new sound IDs and no overwrite of original FpsGlock.rbxm.

## 2026-10-05 — ADS, shotgun grip, tracers and interruptible shell loading

Updated shared weapon eye relief (AKM 2.6, Mossberg 0.9), tracer styles and Mossberg Shell reload mode (1.05s per shell). Server emits all eight ray endpoints, including misses; client pairs them with the captured animated muzzle via cosmetic shot serial. Ammo remains authoritative on server. Shell cycles use unique tokens, add one round after each animation, and cancel on valid fire/death/character change/elevator travel. Magazine reload remains unchanged for Glock/AKM.

Refined copied Mossberg poses with analytic arm fitting, wrist orientation and inherited fingers; avoided extra finger rotations that displaced the glove. New Idle, pump Shoot and ReloadShell modules retain imported geometry, bind frames and weights. Editable actions are saved separately in assets/weapons/Mossberg_GripAnimations.blend. Crossfades smooth one-shell cycles and interrupted motion. No new mesh/texture upload or FBX reimport required.

Observed Studio: 3→4→5→6 shell refill; actual mouse input canceled after two shell insertions and fired, leaving four; eight traces per shell, 24 for three shots. Death 0.3s into shell loading added no round and returned to empty ChoosingWeapon state. AKM shot during magazine reload was rejected, then ammo restored to 30; Glock mouse input produced one tracer and reload 11→12. Updated AKM ADS and Mossberg held/ADS grip were visually inspected. Final Output empty; Rojo build and diff check passed. Stop removed all runtime QA hooks/markers/health changes. No commit.

## 2026-10-05 — endless generated floors

Added pure seeded FloorLayout data generation and rebuilt OfficeMap around 264×288-stud floors (3.124× the former 156×156 footprint). A shuffled four-theme cycle selects offices, labs, warehouses and parking; room types, merged room sizes, partitions, glass, prop variants and gallery side vary by floor seed. Central spine, crossing aisles and perimeter ring connect rooms. Floor 2 introduces a 10-stud gallery; subsequent floors have a 40% gallery chance. Two 14-stud-wide stair approaches use smooth colliders with decorative treads. Existing chair snapshot is reused; cars, racks, lab equipment, railings and other props are native parts, with no new uploaded assets.

FloorDirector generates a destination after clearing the last wave, keeps at most current + next floor, uses alternating physical slots, and destroys cleared geometry after arrival. Logical floor numbering has no ending. Server-only TryTravel shares prompt validation; elevator bounds follow the cabin transform. Respawn retains the current layout and reopens weapon choice; pending destinations are discarded. HUD shows floor theme. Shared Run.Generation and Run.Difficulty contain size/height/progression settings. Wave budgets add two per floor up to +18 per wave; alive cap grows from 9 to 16. Health, speed and damage are capped. Zombie navigation uses each floor's bounds rather than the old ±75 clamp; vertical sight does not bypass stair pathfinding, and fallen NPCs are removed so a wave cannot remain blocked.

Observed Studio: initial ChoosingWeapon had zero waves/spawns. First wave retained five enemies with 100 health/11 speed. User confirmed a real E-prompt elevator transition. Accelerated native server QA completed five guarded transitions, reached floor six, observed budgets 9/11/13/15/17 on wave three, distinct floor seeds, all four themes and a maximum of two loaded floor models. High-floor tuning accepted 16 of 20 spawn attempts, with 16 alive, 180 health and speed 14. Outside-cabin travel was rejected. Death during ElevatorTravel returned to ChoosingWeapon on the original floor, one loaded floor, unanchored character and travel flag false.

The reusable tests/ProceduralFloors.luau verified 200 seeded layouts reproduce their data and have distinct seeds. Engine navigation found all 60 room/stair/gallery probes across all four themes. Native zombie AI climbed from Y279 to Y289 and approached within 4 studs of the player, then attacked on the gallery. Character navigation reached the upper gallery through both stairs (Y289, near Z0). Warehouse/gallery, office, lab and parking views were inspected. Final Output was empty; Rojo build/diff checks passed. Runtime QA scripts, map folders, accelerated values and test health were removed by Stop. Edit contains one normal generated map preview. No automatic commit.
