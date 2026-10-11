# ZombilkaFPS 2.0 — endless migration checkpoint

Date: 2026-10-11. Branch dev; baseline commit 1260454. New authority:
ZOMBILKAFPS_2_0_ENDLESS_MIGRATION_TASK.md, read fully. Old master read fully
as historical boon/safety reference, not current game-flow requirements.

## CURRENT — ordinary Studio Play prototype enabled (2026-10-11)

User clarified priority: make authored map visible/playable through ordinary Play;
do not wait for old visual gate and do not implement XP/full M2–M3 yet. This section
supersedes earlier inactive-prototype/mandatory-gate continuation instructions below.
User also requests: no agents without necessity; avoid repetitive tests the user can
quickly perform. One read-only dependency/review agent was used before that steering;
no further agents or repeated gameplay checks should be started for this checkpoint.

Cause of old game: src/server/init.server.luau unconditionally built OfficeMap and
started FloorDirector. CorporateMap existed only as an isolated QA module call.
Rojo synchronization was working; syncing a module alone did not activate its mode.

Implemented ordinary startup:
- src/shared/GameModeConfig.luau is the single Studio switch:
  StudioMode="EndlessSurvivalPrototype" (default), rollback="LegacyFloors".
  LiveMode remains LegacyFloors; no publishing/settings changed.
- init branches exclusively. Prototype builds Workspace.CorporateComplex at(0,180,0),
  starts existing ZombieService/WeaponService and minimal EndlessPrototype controller.
  It never requires/starts FloorDirector, OfficeMap, ElevatorService or floor objectives.
- EndlessPrototype provides normal weapon selection, three-second intro, bounded
  constant5-enemy replenishment, genuine NPC kill count, death/results and another
  weapon selection on the SAME authored map. No pressure progression, XP, talent
  grants, shops, research payouts/profile access or DataStore writes. This is the
  requested playable map/combat preview, NOT completed M2/M3/full endless survival.
- Dormant compatibility folders/remotes allow existing client initialization; no
  reward/shop/research request has a grant/purchase handler in this prototype.
  Restart validates owner, phase, epoch, living ready character and rate limit.
  Owner/character checks after yielding protect disconnect/reset races.
- Mode-aware HUD, selection and results identify ENDLESS SURVIVAL PROTOTYPE and
  remove floor/quota/elevator objectives; research buttons hidden in prototype.
- Prototype daylight lives in GameModeConfig; runtime applies it only in that branch.
  CorporateMap signs now face the court. Actual meshes remain visible; Greybox=false.
- Old OfficeRun geometry is PRESERVED, not deleted, at
  ServerStorage.LegacyMapArchive.OfficeRun. Legacy source modules untouched.
- Edit contains Workspace.CorporateComplex, tagged EndlessPrototypePreview=true,
  with disabled spawn. Ordinary Play archives that preview in ServerStorage and
  creates one fresh active map. Stop restores Edit preview; no QA script is needed.

Observed ordinary Play (shipping init, no isolated QA map):
- GameMode=EndlessSurvivalPrototype, ActiveDirector=EndlessPrototype, one active
  CorporateComplex v2,143 parts,57 visible meshes,47 combat hulls. Player spawns
  at(0,183,20). OfficeRun absent from active Workspace and retained in ServerStorage.
- All3 normal GUI weapon choices accepted. Real mouse firing + R reload:
  Glock12->11->12; AKM30->21->30 (held automatic fire); Mossberg6->5->6 with
  native shell insertion. Visual weapon presentation seen for all3.
- Naturally scheduled NPCs emerged/chased/attacked: health samples100->88 and later
  death observed in all3 weapon runs. No direct health/NPC spawn/damage injection.
- Ordinary A/D5s moved from office spawn to parkingX~-77.85 and serviceX~77.96.
  No teleport for these traversal observations. Both sides connect to the office.
- Ordinary Results.NewRun click: epoch2->3, ChoosingWeapon, spawn unchanged,
  same authored map; resumed normal combat. Natural NPC damage/3 kills seen through
  actual AKM mouse firing; temporary client camera aiming assisted that damage test,
  with no NPC/damage/ammo edits. Other firing checks struck world geometry.
- Three representative collider checks also used the ordinary active map: test
  reposition to car/rack/container approaches, then real D2s. Each moved toward
  and stopped ~1 stud before hull, no movement override during input.
- Console output empty in observed normal runs. No quota completion/elevator
  transition code is active in this branch. Long-session balance NOT tested.
- Rollback actually checked by temporarily setting StudioMode=LegacyFloors:
  ordinary startup selected FloorDirector/OfficeRun, ChoosingWeapon/floor1/quota30,
  no CorporateComplex active. Default restored to EndlessSurvivalPrototype afterward.
- Final fresh ordinary Play from the new Edit preview confirmed one runtime map,
  preview archived, old map archived, correct prototype controller. Returned to Edit.

Visual evidence now OBSERVED (old blank-capture limitation is historical):
- Ordinary Play renders office furniture, plants, chairs, cars, server racks/decks,
  three signs, weapons and real zombies. Daylight fixed visibly dark first capture.
- Saved native screenshots (not mockups):
  tests/results/Prototype_AKM_Service_20261011.png
  tests/results/Prototype_Mossberg_Parking_20261011.png
  tests/results/Prototype_Edit_Overview_20261011.png
- Screenshot confirms visible prototype, not good final art/balance. Layout is
  visibly sparse/open; user assessment of cover spacing/combat feel still required.
- Exact observed feedback and limitations:
  tests/results/PrototypeOrdinaryPlay_20261011.json
  tests/results/PrototypeOrdinaryCollision_20261011.json

Changed source: GameModeConfig, EndlessPrototype, init.server, CorporateMap(sign),
CombatHud, RunResults, WeaponSelection, init.client. Updated GAME/PROJECT/
IMPLEMENTATION and tests README. Rojo Edit source equality observed for all8 changed
scripts/config (CRLF normalized); relevant unchanged map/layout/zombie sources were
already verified. Rojo plugin auto-sync active; no separate CLI build claimed.

Current handoff:
- Studio ZombilkaFPS.rbxl remains in EDIT with visible CorporateComplex preview and
  daylight/camera overview. Old OfficeRun preserved in ServerStorage.LegacyMapArchive.
- Same place; no need to open another one. CURRENT session already synchronized:
  user can press Play and choose Glock/AKM/Mossberg without manual Rojo Sync.
- No .rbxl save performed. User may Ctrl+S in Studio to retain this Edit scene/scripts
  across reopening. Otherwise reconnect Rojo and Sync after reopening the old file;
  filesystem source remains authoritative and builds the prototype on Play.
- No commit/merge/push/reset/publish/Experience settings or profile writes performed.
- STOP here for user visual/gameplay assessment. Do not advance full M2/M3 or add XP.
  If continuing later, read this CURRENT section first, preserve user work, respond
  to map feedback, and use only necessary checks/agents. Rollback is StudioMode only.

## M0 — AUDITED; legacy baseline observed in Studio

- Preserve existing user changes: AGENTS.md, ZombilkaFPS.rbxl, .claude/,
  skills-lock.json, both master documents. No Git mutations or .rbxl save.
- Studio connected: 13d4d790-f5a1-4187-b2ef-4b4b1de60792, ZombilkaFPS.rbxl,
  PlaceId=0/GameId=0. EnvironmentKit contains203 assets; ArenaKit9; three guns
  and ten CityZombies present. Initial Edit contains OfficeRun preview.
- Native Play baseline: ChoosingWeapon, floor1/quota30, HP100, ready=true,
  credits/rerolls/boons/alive/pending0, ResearchUnavailable, weapon GUI visible,
  cursor free. Actual mouse click Glock -> EncounterActive, issued5/alive5,
  quota unchanged. Snapshot only: sustained NPC navigation/combat NOT yet
  reverified. Native death -> one RunEnded snapshot, temporary data empty,
  new first-floor layout, results GUI visible/cursor free. Output empty.
- Stopped back to Edit. No settings/publication/profile writes performed.
- Rojo CLI absent from PATH; do not claim build. Source synchronization must
  be checked against Edit before acceptance. Existing native tests remain in tests/.
- Current GAME/PROJECT top describe implemented stages0–5 plus partial6. Old
  master incorrectly says no boons/profiles; historical AI/PLAN/PROJECT paragraphs
  incorrectly describe three waves/respawn repeating current floor. Current source
  is 5x5 Office/KillQuota with explicit terminal death and new-run action.
- Real DataStore rejoin remains BLOCKED by unpublished place. This does NOT
  block implementing core XP survival. No mock masquerading as durable progress.

Dependency/ownership:
init -> chosen map -> ZombieService.Start + WeaponService.Start -> ONE director.
Director owns phases/pause/spawn schedule; RunSession owns epoch/temp ledger;
ZombieService genuine death -> XP ledger -> level queue -> RewardService -> effects.
ProfileService remains permanent boundary; no floors disguised as elapsed minutes.

| Action | Modules |
|---|---|
| KEEP | Weapons/rigs/motion, zombie visuals/rig, authored asset kits, boon values, ProfileSchema/ProfileService |
| ADAPT | init, RunSession, ZombieService/EncounterProgress, RunClock, WeaponService, BoonEffects, RewardService, HUD/results/input |
| LEGACY-DISABLE | FloorDirector/OfficeMap/OfficeTiles/ElevatorService/SpawnSources floor orchestration only in endless branch; preserve files |
| ADD | CorporateLayout/CorporateMap, SurvivalConfig internal mode selector, SurvivalDirector, bounded XP pickup ledger |

PLANNED M2 rollback switch: internal SurvivalConfig.Mode will select LegacyFloors
or Endless, with init executing exactly one branch. This selector is NOT implemented
yet. Actual current startup/init is unchanged and always legacy. Current M1 rollback
requires no switch: CorporateMap/CorporateLayout are additive and inactive at startup;
ZombieService.Configure's optional fifth worldModel defaults to the old OfficeRun
lookup. Four-argument legacy calls clear the optional override. New geometry is built
in its owned container; never destroy user Edit OfficeRun/Blender scenes.

M1: authored320x320 lobby/parking/service, explicit cover clusters, two loops,
wide crossings, spawn lanes; map diagram first. Test standalone map before M2.
M2: endless lifecycle/time pressure, death/results/restart, no quota/transition.
M3: real XP drops/collection, overflow queue, exactly3 cards/one grant, true pause.
Critical pause fixes: os.clock combat-effect timers; reload delayed operations;
SetPaused unanchoring emerging roots; spawn/path callbacks after yield; player
slide momentum; client gating before menu replication. Cooldown throttles and
DataStore retry remain wall-clock. No premature M4+ content.

Skills reviewed: roblox-security, roblox-performance (advisory; no automatic
streaming/settings changes or punitive speed-kick code adopted). Subagents:
read-only migration audit and isolated map/layout authoring; primary alone Studio.

## Historical initial milestone status (superseded by CURRENT above)

- M0: AUDITED / baseline TESTED IN STUDIO; limited scope stated above.
- M1: IMPLEMENTED ISOLATED PROTOTYPE v2 / PARTIAL STUDIO VERIFICATION; gate OPEN.
- M2–M8: NOT IMPLEMENTED in new mode.
- Real persistence: BLOCKED. Normal-speed balance/game feel: REQUIRES PLAYTEST.

Resume: read this file, new master, AGENTS, GAME, status/diff; finish M1 native
navigation/collision/actor/visual gates, then sequential M2–M3. Do not enable an
untested director. No commit/push/publish/settings or production profile changes.

## M1 — 2026-10-11 native Studio checkpoint

Implemented:
- CorporateLayout is fixed 320x320 geometry with Parking/Office/Service regions,
  14 purposeful prop groups, two exterior rotation loops, three cross-connections,
  18 explicit ground spawn lanes and reserved future shop sites. No random generation.
- CorporateMap reuses existing Arena/Environment kit meshes and stable combat hulls;
  builds detached, cleans only its own failed build, refuses an existing name, returns
  explicit bounds/spawn/nav/world ownership. No startup, Lighting or Experience edits.
- Version2: visible rack maintenance deck and loading-container deck, each with two
  broad shallow ramps. They fix observed top-of-cover native NPC failures in v1.
  Cars and AI tuning are unchanged. Ground routes remain clear.
- ZombieService accepts optional authored world for spawn-overlap validation;
  legacy OfficeRun behavior is retained. This is the only shipping existing-module edit.
- AI/ENDLESS_MAP_LAYOUT.md records purpose/coordinates/version correction;
  AI/ENDLESS_MAP_LAYOUT.svg is a top-down collision diagram sampled from native v2
  Studio geometry. It is NOT a screenshot or proof of appearance/playability.

Observed native Play tests (normal timers, no persistence):
1. tests/results/EndlessMapNavigationQA_v2.json: PASS. 48 sequential native
   no-jump paths:18 lanes,3 zone targets,21 ground edges,4 deck approaches and2
   actor routes. All12-stud sampled ground corridors clear. Native dedicated
   Humanoid walked car-bank/rack-bank routes in8.81/8.05s. Counts:143 parts,
   57 meshes,47 hulls,58 colliders. Part count is NOT a frame-rate measurement.
2. EndlessMapChaseQA_v2.json: PASS. Production ZombieService spawned/emerged,
   approached and attacked the stationary QA player in all3 regions. Parking15.19s,
   Office11.00s, Service15.00s; each HP100->88, no reported spawn failures.
3. EndlessMapPerchQA_v1.json: FAIL retained. Car passed; rack and container produced
   no damage in30s. EndlessMapPerchQA_v2.json: PASS after ramps/decks; Car11.39s,
   Rack10.46s, Container9.64s, each HP100->88. Player positioned on tops by QA,
   so this specifically proves native AI ascent/attack, not player jump accessibility.
4. EndlessMapMovementClientQA_v2.json: real production D9s, then Shift+D1s,
   C and Shift+D8s, normally selected Glock. Player traversed parking->office->
   service along central crossing: worldX320.57->608.00 atorigin450. Client
   WalkSpeed16/24, slide observed15 samples, max horizontal speed29.62. East wall
   stopped continued input at localX~158. Server observer recorded the same crossing
   separately in EndlessMapMovementQA_v2.json; server-only WalkSpeed/Sliding do
   NOT reflect local movement property/attribute changes and are not slide evidence.
5. EndlessMapCollisionQA_v2.json: real D held2s into car/rack/container from the
   west at ground height; each stopped about1 stud before its hull's west edge.
   This is three representative obstacles, not an exhaustive prop/weapon-ray test.
6. Console output empty during native map/nav/chase/perch/movement tests.
7. Rojo plugin active: Edit CorporateMap/Layout exactly match disk; ZombieService
   matches after CRLF->LF normalization. Rojo CLI absent: no CLI build claimed.
8. Final fresh legacy Play after adapter: ChoosingWeapon/floor1/quota30, no
   CorporateComplex startup; actual Glock mouse click->EncounterActive, one actual
   zombie plus one pending observed after5s. Native death->RunEnded once, epoch2,
   Alive/Pending/actual zombie count0, temporary credits/rerolls/boons0, research
   Unavailable, results GUI visible/free cursor. Console empty. Stopped to Edit.
   This is a bounded startup/death regression, not a sustained old-mode combat test.

Visual gate BLOCKED:
- MCP screen captures have blank 3D for original OfficeRun, new map and client-only
  neon debug part, while GUI draws normally. Replicated map parts exist, are visible
  by property, and participate in real physics. Correct Scriptable camera, unloaded
  overlays and alternate viewpoints did not restore a view. This is an observed
  capture/render limitation; its cause has NOT been established.
- A second client CaptureService diagnostic (callback ready, temporary rbxtemp only,
  no save/upload) also returned blank underlying 3D. Capture IDs include
  M1_CaptureServiceDiagnostic and M1_CaptureService_World_v2; displayed in this chat,
  no screenshot files were saved. Do not cite them as accepted map screenshots.
- Spawn composition, material/texture/mesh orientation, sightline readability and
  enjoyable combat layout are NOT VERIFIED. User normal gameplay assessment remains
  required. No misleading "excellent map" claim from pathfinding.
- Remaining M1 checks: all crossings/loops with production sprint/slide, all important
  props and weapon collision/rays, boundary jump attempts, additional reachable perches,
  reliable screenshots and explicit visual review. Only central crossing controls tested.

Safety/cleanup:
- All QA scripts/modules/actors/test maps were native Play-only and removed by Stop.
  Owned Edit CorporateComplex preview (MigrationOwnedPreview=true, oldv1) removed;
  original OfficeRun preserved, original Edit camera restored. No user map save.
- No new mode/director/XP/cards implemented or enabled. Old floor generator unchanged.
  M2/M3 remain pending because the mandatory M1 visual/complete traversal gate is open.
- QA sources are outside Rojo: CorporateMapQA.luau, RuntimeCorporateChase.luau,
  RuntimeCorporatePerch.luau. Chase then Perch; observe Complete/Report attributes.
  Native Script required: MCP execute_luau require cache is separate from gameplay;
  direct MCP ZombieService.Count() must not be used as runtime evidence.

Previous continuation (superseded by CURRENT and the user's ordinary-Play priority):
1. Read this checkpoint, new task, AGENTS, GAME current notice, status/diff; retain
   pre-existing user files. Do not inspect C:/Roblox/Zombilka. No Git mutations.
2. Verify connected Studio and source equality. Start fresh Play. Reproduce M1 using
   a temporary Server Script, not cached MCP module calls: CorporateMap.Build under
   owned QA folder atorigin(450,400,0); native ZombieService.Configure(...,map.Model).
   Inject CorporateMapQA as temporary ModuleScript plus dedicated ZombieRig actor.
   RuntimeCorporateChase creates QA_ChaseWorld; after Complete run RuntimeCorporatePerch.
3. Restore reliable 3D capture/view without publishing, toggling Experience settings or
   changing user art blindly. If still blank, retain BLOCKED visual status, do not approve
   M1. Production movement controls can still be observed through native client scripts.
4. Complete remaining M1 checks above and record evidence. Then implement M2 selector
   and SurvivalDirector with ONE owner; preserve FloorDirector files behind legacy mode.
5. M3 reuse current9 boons/reward tokens. Genuine death callback must expose XP position;
   no XP for requeue/despawn. Central simulation clock/pause must cover effects, reload,
   emerging anchors, async spawn yields, player momentum and queued menus. Audit risks
   listed above before enabling production branch. No fake floors as elapsed minutes.
6. Test M2 normal combat/death/restart then M3 real pickups/overflow/three cards/security/
   pause-resume/Glock-AKM-Mossberg/5–10min. Record actual observations before acceptance.
7. Stop Studio to Edit, remove only owned QA objects, verify no duplicate directors and
   user file preservation. Update this document after each gate. Real DataStore still
   BLOCKED until user-approved published TEST Experience; no automatic publish/settings.
