# ZombilkaFPS 2.0 — MASTER TASK: SAFE MIGRATION TO ENDLESS SURVIVAL

**For:** Codex acting as the lead developer on the existing Roblox project  
**Project:** `C:\Roblox\ZombilkaFPS`  
**Status:** New direction approved by the project owner, 2026-10-11  
**Authority:** This task supersedes the former floor/elevator gameplay goal. `AGENTS.md` and all user safety constraints still apply. The old Hades-like master brief remains historical reference for boon definitions, not the specification for game flow.

## 0. Mission, in one sentence

Transform the **existing**, working ZombilkaFPS prototype into a **single-player first-person endless zombie survival roguelike** with **one hand-authored interconnected corporate complex**, continuously escalating hordes, **server-authoritative XP pickups**, level-ups that offer **one of three patron boons**, shops, and persistent meta-research. A run continues **until the player dies**; there are **no floors to clear, mandatory elevators, mandatory end boss, or winning time limit**.

Do not start a new game, throw away working systems, or silently delete the old gameplay mode. Work in incremental, testable milestones with explicit rollback paths. Start with a compelling playable vertical slice before mass-producing features.

## 1. Confirmed design decisions — DO NOT REOPEN without a genuine blocker

1. **Mode:** endless survival until death. There is no fixed 15/20/30-minute endpoint. Any timed boss/elite encounter is optional pressure, not an end-of-run requirement.
2. **World:** one **hand-authored** large connected corporate complex with office, parking, and technical/service areas. No procedural room mazes, tile-scattered props, or new floors per encounter.
3. **Combat:** first-person Glock 19, AKM, and Mossberg 590A1; movement, sprint, slide, ADS and existing weapon rigs preserved.
4. **Progression:** zombies award XP. The player collects visible XP drops, levels up, and selects **exactly one of three** boons. The default single-player behavior is to pause gameplay during the choice.
5. **Patrons:** eight: **Dr Weiss (medicine/blood), Professor Volta (lightning), Toxicologist Radke (poison/acid), Sergeant Bravo (ballistics), Engineer Grid (explosions/fire), Dr Nord (ice), Operator Vector (movement), Dispatcher Sigma (drones/technology)**.
6. **Boon quality:** Common, Rare, Epic, Heroic; special Legendary and Duo boons. Ordinary boon levels 1–3 where supported. Four-patron **soft affinity**, not a hard lock. Limited rerolls with some purchasable in-game.
7. **Power curve:** build should feel clearly powerful after roughly **8–12 minutes** of ordinary survival; the run remains playable and challenging beyond that, indefinitely.
8. **Death:** ends the run; resets XP, temporary boons, run credits, run items and rerolls; retains research data, unlocked permanent upgrades and achievements. Results show survival time, kills, level, build and earned research.
9. **Economy:** keep run credits, vending machines and the rare Zavkhoz merchant, adapted to one map. Research Data remain the persistent meta-currency.
10. **Current unfinished content must not be faked:** only Volta, Bravo and Weiss have previously been live with 9 verified normal boons. The other five patrons, Legendary and Duo were unfinished as of the last provided checkpoint.
11. **No automatic publish, Experience settings changes, DataStore permissions changes, asset publication, commit, merge or push.** Ask first.

## 2. Known starting state — AUDIT rather than assume it is unchanged

The provided 2026-10-09 checkpoint (`AI/ROGUELIKE_PROGRESS.md`) reports:

- Branch then `dev`; source scripts through Rojo are authoritative; Rojo CLI was not available in that previous Codex environment, although disk/Edit script equality was checked via Studio MCP.
- Active prototype: Office/OpenArena v5, 5×5 authored tile grid, ~180×180 studs, one KillQuota mode, continuous `HordeDirector`, two physical floor slots.
- `FloorDirector` controls phases/world transitions; `RunSession` owns temporary run ledger/epochs; `WeaponService` owns guns and server raycasts; `ZombieService` owns zombie behavior; `RewardService`, `BoonCatalog`, `BoonEffects`, `RewardPolicy`, `Patrons` manage boons; `ShopService`, `ShopWorld`, `ShopCatalog` manage shopping.
- Three physical patron elevators and a reward interlude were verified; rarity/levels/rerolls/pity/soft weights and shop economy were verified with automated and Studio tests.
- Stage 6 research (`ResearchCatalog`, `ProfileSchema`, `ProfileService`, `ResearchService`, `ResearchPanel`) exists, including five research branches and mock-tested server-safe purchases, retries and idempotency.
- **Real Roblox DataStore persistence/rejoin is NOT VERIFIED:** place was unpublished, `PlaceId=0`, real GetAsync was denied. Mock tests are not real persistence evidence. Do not bypass this restriction or quietly substitute fake persistence.
- Former stages 7–9 (five additional patrons, Legendary/Duo and full balance) were not complete.
- Existing environment library reportedly contains ~203 authored Office/Parking assets. Reuse these and verify current asset references, orientations, textures and collision.

Before editing: inspect the CURRENT tree, `git status` and diff, `AGENTS.md`, `GAME.md`, entire previous master prompt, newest `AI/ROGUELIKE_PROGRESS.md`, `AI/IMPLEMENTATION.md`, `default.project.json`, relevant tests, existing place, and actual runtime. Some `AI/PROJECT.md` / historical notes contain obsolete floor/three-wave information: do not treat them as current source of truth. Report discrepancies explicitly.

Never inspect or reuse `C:\Roblox\Zombilka` (the abandoned old project).

## 3. Non-negotiable migration safety

### 3.1 Preserve/roll back

- DO NOT rewrite everything or delete old systems in a single pass.
- Keep working Legacy Floor Mode isolated/inactive behind a temporary, **internal developer feature flag** or equivalent well-documented rollback path until endless mode passes its gates. Do not expose a player-facing mode toggle unless needed.
- Preserve authored assets, weapons, zombie visuals, animations, sound, data schemas, test fixtures and previously functioning code.
- Do not destructively edit the user's `.rbxl` or Blender source scenes. Be alert to unsaved Studio modifications and locked files. Avoid overwriting user work.
- Existing working-tree changes must be preserved; **do not require a clean tree by deleting anything**.
- No commit, merge, push, reset, rebase, force checkout or file deletion without explicit user approval. Do not create a new branch without approval when it would disrupt active local changes.
- Do not write to a live production DataStore or reset real player profiles. Do not publish without express approval.
- At each milestone keep the last verified playable state restorable. If a milestone fails, report exactly what failed and stop adding dependencies on it.

### 3.2 Architecture

- Server authoritative: damage, ammo, zombie AI, XP awards and pickup, level progression, reward rolls, active boons, purchases, timed difficulty, end-of-run and persistent research.
- Client: input, FPS presentation, visible pickup FX, UI, camera and boon VFX. Do not trust client-submitted XP, health, credits, kill counts, ranks, rarity, choice IDs or pickup coordinates without server verification.
- Prefer adapting existing modules and stable public interfaces to duplicate service frameworks. Avoid a giant god-module.
- Rojo filesystem files must remain canonical for Luau. Map geometry/asset authoring also needs a reproducible, documented source (e.g., committed Roblox model assets or an **authored fixed layout definition**), not only ephemeral Play instances or untracked unsaved Edit changes.
- Separate **survival duration** from real wall-clock time, and from `FloorNumber`. Do not pretend elapsed minutes are floors internally.
- Invalidate stale callbacks on death/new run via run epoch/token. Make payouts and purchases idempotent.
- Existing legacy source may remain in the repo during migration, but it must not run in parallel and spawn a second director or duplicate enemies.

### 3.3 Allowed autonomy

- Implement ordinary technical details with reasonable, documented defaults.
- If a design choice materially changes the approved loop, existing persistent schema safety, user assets, map scale/composition, gameplay identity or resource cost, ask concise questions with concrete alternatives before proceeding.
- Do not pause for permission after every trivial subtask. Finish safe milestones autonomously.

## 4. Intended player experience

1. Player reaches the simple pre-run setup / research UI. For the first vertical slice, reusing the current safe weapon-selection UI is fine; do not make a giant hub first.
2. Player selects Glock, AKM or Mossberg and starts **RunId N** with level 1, XP 0, survival time 0, no temporary boons, and research-derived starting bonuses.
3. Player spawns at a central readable plaza/office entrance on the single authored map. Hordes approach from multiple predictable, sufficiently distant and telegraphed directions.
4. Kills produce XP pickups and limited run-credit progress. XP pickups attract/merge safely, the player collects them, levels up.
5. On level-up, combat enters **BoonChoice**. Present three viable cards drawn from eight patrons according to availability, rarity, affinity and pity; choose one; apply once; resume the same survival run at the same location.
6. Intensity increases according to ACTIVE SURVIVAL TIME (not time paused in menus). Specials/elite encounters and optional world events may appear later, without requiring an elevator or mission clear.
7. Vending machines are fixed authored locations; Zavkhoz may appear as a rare limited-time/limited-stock event. Shops use run credits and remain safe/valid without granting endless immortality through menu exploits.
8. No victory screen due to time. At 20, 40, 60+ minutes gameplay continues with bounded NPC counts, bounded effect chains and repeatable but controlled long-run rewards.
9. On death, end exactly once, stop effects and spawns, calculate real session results, commit eligible research rewards safely, show results, and return to new-run preparation.

## 5. Hand-authored map: corporate complex

### 5.1 Map constraints

- FIRST deliverable is **one designed combat space**, not procedural generation. Do NOT scatter office desks/cars randomly across a giant baseplate.
- A first playable footprint around **300–400 studs across** is an initial design target, subject to native sightline/performance/playtest findings, not a demand to build a huge empty world.
- Readable connected zones: (A) corporate lobby/reception and office plaza; (B) open parking with grouped cars/columns/barriers; (C) technical/service annex with racks/containers/equipment. Optional small raised walkway/platform with **two wide zombie-traversable approaches**.
- Start zone is readable and immediately connected to combat. No dead-end office maze. At least two meaningful rotation routes around main combat obstacles and several wide crossings between zones.
- Create **purposeful authored prop clusters** (cubicles, reception island, parked car groups, loading/service block, technical station). Every cluster contributes cover, route choice or recognizable landmark. No random single-prop scatter.
- Maintain continuous sightlines and approach anticipation. Mix low, medium and hard cover without cluttering every route. Ensure player sightline and zombie pathing; no tiny mandatory corridors.
- Large props have appropriate simplified `CanCollide`/`CanQuery` combat hulls; avoid the regression where players walk through cars and shelves. Tiny purely cosmetic debris can be noncolliding.
- Do not confuse an infected coffee-machine objective prop with benign vending shops.
- Use existing authored asset kits first. Use Blender MCP only for genuinely missing structural modules, without destructively editing existing rigs/scenes. Keep mesh/UV/texture/pivot/scale stable and verified in Roblox.
- No Roblox Toolbox imports or unlicensed source content without user approval.

### 5.2 Authoring and approvals

- Produce a top-down map layout + brief zone-by-zone rationale before final detailed art; use playable low-poly blockout first. The user has rejected several aesthetically bad procedural layouts. A clean combat space takes priority over scenery volume.
- Build/serialize a stable version in the **current repository's** asset/model workflow. Avoid making a one-piece giant Blender mesh that prevents independent collision and gameplay tuning.
- Test view from spawn, crossings, cover use, routes, boundary enforcement, collision and enemy navigation with actual Studio actors. No unreachable rooftops or NPC farming exploits.
- Do not delete the old OfficeTiles/OfficeMap project files as a shortcut. Disable the legacy mode until migration validated.

## 6. Endless Survival Director

- Adapt `FloorDirector` orchestration to a new `SurvivalDirector` **or** a clean mode-aware controller. Audit and choose the least risky composition; only one runtime director may own phases.
- Recommended phases: `PreparingRun`, `ChoosingWeapon`, `SurvivalIntro`, `SurvivalActive`, `LevelUpChoice`, `ShopChoice`, `RunEnded`, `RecoveryFailed`. Names may adapt to existing state conventions.
- Phase transitions must be server-authenticated and resilient to death/respawn/disconnect/race conditions.
- Store `RunId`, `Epoch`, `ActiveSurvivalSeconds`, `Kills`, `Level`, `CurrentXP`, `XPRequired`, `Credits`, `Build`, `Rerolls`, `ResearchStatus`, `Intensity`, `Alive/Pending`, and a single offer token/revision in appropriate owned state. Replicate only necessary readonly UI fields.
- Only `SurvivalActive` advances survival timer, HordeDirector pressure, status effect timers and other simulation clocks. Pause must not award free survival time/research.
- The run ends only on death or explicit user exit/abandon (define exit semantics to avoid farming and loss bugs). There are no mandatory elevator rounds, wave clear gates, floor slots or per-floor objectives in this mode.
- Enemy softlocks must not block progression. Encounter count is not a gate; players gain XP by combat.
- Preserve the former `RunSession` safeguards: epochs, genuine kills, duplicate-award prevention, results snapshot and weapon-action cancellation.

## 7. Horde spawning and AI for one open world

- Reuse current ZombieService/ZombieRig/variants, nav/path safeguards and emergence FX.
- Replace dependence on floor number with a centrally configurable **time/intensity progression curve**. Initial example: 0–3 min manageable, 3–6 rising density, 6–10 intense, 10–15 specials, 15–20 severe, >20 escalating threats with safe performance caps. These are tuning bands, not hard gameplay gates.
- Never spawn an enemy at the player's feet. Prefer authored SpawnLanes and validated emergence points around the active combat zone, often roughly 45–100 studs away depending on visibility/path and map scale. Retain telegraph + nonattacking emergence.
- Do not spawn arbitrarily on top of cover, through shop structures, behind sealed walls, or in unreachable service corners.
- Zombies must **come to the player**. Track approach progress; recycle truly stuck/out-of-sight NPCs without crediting kills or drops, with bounded retries.
- Current 16 `Alive+Pending` cap is a sensible **starting safe setting**, not an obligation to raise to 100. Profile real runtime performance before increasing; optional staged targets 20–24 only if proven stable. Escalate via spawn tempo, variant mix and specials, not only unbounded HP.
- Address current player sprint speed (~24 studs/s) versus common zombie chase speed (~11) fairly: interceptors, faster variants, lane choices, partial surrounding — never unfair instant teleports or impossible melee attacks.
- Maintain a reasonable pace even if the player remains near one zone; no mandatory long exploration to find enemies.
- Use bounded event/loop work, pooled objects where appropriate and no unlimited heartbeat connections/path requests.

## 8. XP, pickups, levels, and selection

### 8.1 XP rewards

- Server grants XP only for genuine, validated enemy deaths, with optional server-authorized events/elites. No XP for technical zombie cleanup, recycled NPCs, effect-only repeated kills, fake remotes or stale epochs.
- Initially, visible XP samples/crystals drop at enemy death locations. They must be easy to notice and collectible at reasonable magnet radius (~12–18 studs as a tunable starting point).
- Do not create hundreds of individual replicated physical gem Parts. Implement aggregation/stacking, pooling or lightweight client visualization with server-controlled pickup ledger and spatial validation. Merge nearby samples and enforce maximum active representations. Define lifetime/cleanup and fairness so old drops do not leak memory; consider no-loss UX on dense waves.
- Network-safe collection: server validates run, alive state, distance/region, pickup ID, not-already-collected and availability. Clients cannot choose an arbitrary reward amount or teleport a pickup claim.
- Excess XP carries over to later levels. Handle several levels gained in one server tick, with queued offers and no nested windows/double claims.

### 8.2 Leveling pacing

Tune to **approximate** outcomes from normal human play:

| Survival time | Expected boon gains/upgrades |
| --- | --- |
| 3 min | 2–3 |
| 6 min | 4–5 |
| 10 min | 7–9 |
| 15 min | 10–12 |
| 20 min | 13–16 |

This is a target, not a fabricated guarantee. Design the XP curve from measured player kills/minute and gem collection rate; test Glock, AKM and Mossberg rather than blindly hard-coding level thresholds. Balance should allow an exciting build around 8–12 minutes.

- Allow ongoing level-up/meaningful choice **beyond 20 minutes**. When unique boon pools are exhausted, provide sensible bounded repeatable/stat/supply choices without uncapped damage, immortality or endlessly spawning devices. Do not silently end progression.

### 8.3 Three cards & server security

- Reuse `BoonCatalog`, `Patrons`, `BoonEffects`, `RewardService`, `RewardPolicy` where compatible. Replace the reward trigger (elevator reward) with a **LevelUpReward** abstraction rather than duplicating the boon engine.
- Offer exactly three distinct meaningful cards where the pool permits; transparent, clearly labeled fallback if exhausted. Select **one** only. Persist choice within the run and apply server-side once using `RunId`/epoch + offer token + revision + exact card ID; reject duplicates, stale claims, wrong owner, dead/invalid characters and forged rarity.
- Card UI shows patron, rarity, talent name, current/new level and actual server-driven numbers. Scroll works at narrower widths and mouse unlock/relock is correct. Do not assume mobile support without testing it.
- Existing normal rarities Common/Rare/Epic/Heroic preserved; Special Legendary/Duo requirements should be adapted from floor gates to `level`, active minutes and prerequisite boons.
- Soft four-patron affinity preserved: already selected patrons become more common after early choices, other patrons remain possible. Neither 8-patron catalog placeholders nor unimplemented effects should enter the pool.
- Preserve 1–3 boon levels, limited rerolls (carry cap and per-menu limit as appropriate), pity that advances only on accepted offers (not reroll farming), deterministic seeded sample testing and actual weapon compatibility. Research that used to preview elevators (`scanner`) needs a documented meaningful replacement, not a silent lost purchase.
- Initial production feature gate enables only **already implemented** live patrons. Add remaining five/Legendaries/duos after core endless mode works; do not pretend they are currently done.

## 9. Single-player pause contract (critical)

- On level-up, the player can make an unhurried choice while **simulation time is paused**. Mere client overlays with server combat running are NOT acceptable.
- Reuse/audit existing `RunClock` or central simulation clock; all survival timers, cooldowns, spawn scheduling, DoT/HoT, AI attacks, temporary invulnerability windows and timed effects must respect pause semantics. Carefully handle `task.delay`/`task.wait`: wall-clock timers can still fire during a paused modal unless guarded.
- During level-up, disable movement/firing/reload inputs and damage; freeze/stabilize zombies and pending spawn/windup appropriately without leaving broken Humanoids or anchored corpses on resume. No hidden accumulation of spawned enemies during the pause.
- On resume, restore exactly the prior active run; no duplicate AI, stale damage, time jump or awarded XP.
- Support queued level-ups one at a time. Death/disconnect/reset destroys old offers and unpauses/cleans safely.
- First version is **single-player only**. Do not architect a global multiplayer pause illusion or implement co-op in this task. Report what multiplayer would later require.

## 10. Economy, shops and optional events

- Retain `ShopService`, `ShopCatalog` and existing server-authoritative transaction protections (finite stock, price validation, stale packet rejection, epoch, once-only items).
- Remove per-floor reward and capped per-floor kill-credit accounting from the ACTIVE endless mode; keep old implementation behind legacy mode. Replace with bounded credit income from genuine combat, special enemy drops and optional events. Prevent a stationary or unattended infinite-credit exploit; spending/rewards should not grow without meaningful combat.
- Use fixed, thoughtfully placed shop terminal(s) within the authored map. A rare Zavkhoz merchant can appear as a scheduled/conditional event; no merchant elevator.
- Shops must not be an infinite safe-zone exploit. Choose and document a safe interaction design (e.g. require no enemies nearby and pause only during the legitimate menu; no survival-time/research gain while inside). Server must enforce distance, active state, stock and per-run entry restrictions.
- Optional events after core vertical slice: infected 3-layer coffee-machine spawner, equipment supply pod, elite zombie. These may award XP, credits or research according to distinct rules. No key hunts or mandatory NPC cleanup gates. The infected coffee machine is **not** an ordinary shopping terminal.
- No new boss needed in this migration. Endless mode has **no final boss**; later elites/bosses can occur as repeatable encounters without ending the run, after separate user approval.

## 11. Persistent research and results

- Preserve the five already authored research branches, purchased ranks, receipt safeguards and profile schema. Existing `ProfileService` uses `ZombilkaResearch_v1` (live) / isolated Studio test namespace; verify real current code before any changes.
- **Do not wipe or replace profiles**, silently change store names/keys, write to production, or grant permanent currency from mock/failed persistence. Preserve old `BestFloor` for historical data; add safe versioned fields (e.g. `BestSurvivalSeconds`) only with backward-compatible migration.
- Research payout now derives from genuine survival-time thresholds / milestones and validated achievements, **not floor completion**. Payout must be once per RunId+milestone, idempotent across death, rejoin, retry and shutdown. Time paused in menus cannot count toward milestones.
- Temporary XP, levels, boons, credits, items and world state MUST NOT be saved in permanent profile by default.
- Preserve research terminal functionality, early-run body HP, credits and rerolls; redesign legacy elevator scanner benefit into a comparable, clearly communicated reward-info / boon-choice preview.
- Real DataStore save/rejoin remains a **known BLOCKER** until the user authorizes a published TEST Experience/API. Do not publish or toggle Experience settings on your own. Mock tests must be labeled Mock. If unavailable, show honest `Unavailable/Pending` UI and still allow gameplay safely (no fabricated durable purchases).
- A server crash after a pending unconfirmed save may lose rewards; document residual risk instead of guaranteeing what Roblox does not guarantee.
- Results screen for endless: active survival duration, real kills, attained level, XP, boons/build, credits earned/spent, research pending/saved/unavailable, best survival record if verified. Provide explicit New Run action.

## 12. HUD and world feedback

- Keep FPS weapon viewmodel, hitmarkers, health, magazine, reload, camera, FOV, sprint/slide and existing control behavior.
- Replace prominent `Floor/Quota/Elevator` HUD items with: elapsed **active survival time**, player **level**, XP bar, credits, health/ammo, enemy pressure, limited active objective/event indicator, and a small boon-build access/view.
- XP pickup particles/glow must be readable on mixed office/parking surfaces. Avoid overbright screen-filling FX; cheap pooling and per-frame budgets.
- Level-up cards are the central UX, with genuinely readable rarity and patron color. The game is paused, cursor unlocked, then restored reliably when the card is selected.
- Shop overlay and boon overlay must not overlap; transitions and errors provide a safe cancel/recovery state.
- Do not spend substantial time generating portraits, boss models, elaborate cutscenes, or lore UI before the game loop works.

## 13. Implementation milestones — MANDATORY order and gates

### M0 — Audit and safe migration strategy

- Verify current Git changes, game modes, Rojo/MCP connectivity, source-of-truth and latest stage6 persistence checkpoint.
- Produce a module dependency map and a migration table: KEEP / ADAPT / LEGACY-DISABLE / ADD.
- Capture a reproducible old-mode baseline in Studio, with actual Results/UI/Combat observations and regression tests.
- Define a rollback switch and the exact files to change in M1–M3. No destructive changes.
- **Gate:** user gets concise overview; proceed autonomously absent a material design blocker.

### M1 — Hand-authored playable map (not a generator)

- Produce top-down layout and greybox of lobby, parking and technical area on one connected map; import/reuse existing meshes and stable colliders.
- Position purposeful cover islands, main rotation loop, secondary crossing routes and spawn lanes. Keep playable footprint deliberate, not empty.
- Store authored world reproducibly and preserve legacy floor geometry offline.
- Studio: player can walk/sprint/slide through all zone links; large props stop player correctly; native zombies reach player from each zone; no blocked/isolated spots.
- **Gate:** record screenshots/coordinates and a map review that distinguishes technically navigable from actually fun. Do not declare 'excellent combat level design' from pathfinding alone.

### M2 — Endless run lifecycle / timed HordeDirector

- Enable endless mode through internal safe mode selector. Stop active legacy floor transitions and kill-quota checks in the new mode only.
- Start run, server active clock, pressure curve, death once, results, restart same authored map and cleanup correctly. No duplicate world ownership.
- Studio tests with 3 weapons and actual NPCs, death/restart, leaving/rejoining while unpublished with persistence unavailable.
- **Gate:** sustained combat works on one map, no unexplained pauses or false win transition.

### M3 — XP drops, level-ups and three boon cards (PLAYABLE VERTICAL SLICE)

- Server XP ledger, efficient gems, pickup/magnet, levels/overflow, queued level-ups, true single-player pause, 1-of-3 cards, reroll, tokenized grants.
- Initially use only the 9 already working talents from Volta/Bravo/Weiss and current rarities.
- Validate real level-up, actual pickup, server reward choice, resumed firing, saved within run, cleared after death.
- **Gate:** the user can play a normal 5–10 minute new-mode session end-to-end. STOP adding big features if it is boring or broken. Collect visual and timing evidence. This is the priority milestone.

### M4 — Reward quality and full patron catalogue

- Adapt rarity/pity/affinity to player level, number of accepted menus and elapsed time. Keep actual card stats and server effect tables aligned.
- Implement the remaining five patrons with real ordinary abilities and relevant animation/FX only as needed; use existing master brief for character design. Keep disabled incomplete abilities out of offers.
- Test all effects with Glock/AKM/Mossberg, with shotgun pellet proc budget, caps and no recursive secondary-damage explosions.
- **Gate:** all eight patrons offer functional abilities, and none of the offered cards are only cosmetic placeholders.

### M5 — Legendary and Duo boons

- Implement prerequisites and first live Duo **Electrotoxin (Volta + Radke)**, then other approved combinations. Legendary belongs to each patron as appropriate.
- Make triggering/combo logic bounded, client VFX affordable and special rarity distinct from standard multiplier tiers.
- Test grant eligibility, prerequisite removal if applicable, repeatable damage non-recursion, network abuse and large groups. Test long-run strong build, no infinite healing/invulnerability.
- **Gate:** demonstrable actual Duo gameplay with natural weapon damage and scalable effects.

### M6 — Shops, events and research adaptation

- Reposition vending/shopping in the authored world and retain Zavkhoz as rare optional event. Introduce fair XP/credit event rewards and income limits.
- Retarget research payout to deduplicated active survival-time milestones; retain secure profile logic. Convert scanner upgrade semantics. Update results.
- Maintain Stage6 DataStore real-rejoin status `BLOCKED` until user-approved published TEST place. Mock is separate. Do not delay core XP loop waiting for publish permission.
- **Gate:** no free money/health/pause exploit, purchases survive menu close within run, purchases reset at death, research behavior honest under unavailable datastore.

### M7 — Balance, endless longevity and performance

- Test honest normal-speed sessions at 3, 6, 10, 15 and 20 min; accelerated simulation separately to 30, 45 and 60+ min. Test each weapon and several builds.
- Inspect actual perceived combat: density, time chasing zombies, meaningful movement, kill rate, XP pickup rate, cards, survivability, special effects and FPS.
- Tune so a powerful build typically emerges around 8–12 min, while intensity stays engaging at 20+ min with bounded spawn/effect budgets.
- Watch server CPU, client FPS, network, allocations, path computations, lingering pickups, particle count and long-lived connections. Do not invent passed metrics.
- **Gate:** real Studio evidence for the new loop and explicit list of remaining balance problems.

### M8 — Documentation, rollback validation and final handoff

- Update `GAME.md` to describe CURRENT shipping endless mode, not old floors. Move superseded notes under HISTORICAL explicitly.
- Update `AI/PROJECT.md`, `AI/IMPLEMENTATION.md`, relevant tests/README and write `AI/ENDLESS_MIGRATION_PROGRESS.md` throughout the project.
- Validate clean new-mode startup, restarting after death, reload/ADS/slide, XP/boon, shop/credits, research unavailable behavior, no leftover temporary test code or duplicated directors.
- Verify source scripts match disk/Edit when using Studio MCP; note if Rojo CLI not found. Never claim Rojo build if not run. Never overwrite user `.rbxl` silently.
- Present files changed, rollback steps, evidence paths, known issues, real vs mock tests, and exact next steps. No Git mutations.

## 14. Detailed QA matrix (minimum)

**Gameplay / lifecycle**

- Fresh run starts Level1, XP0, Time0, no boons and correct starting research bonuses.
- Active time pauses in level-up/shop/results; resumes exactly without time jump.
- Level-up overflow produces sequential, nonstacked offers; one accepted boon each.
- Death mid-gem-collection, mid-attack, mid-reload, mid-level choice, mid-shop, mid-spawn and mid-DoT results in one terminal run and no stale grants.
- New run has no leftover zombie, gems, damaging FX, timers, bonus HP, boon proc state, unclaimed card or pending spawn from prior run.
- User cannot restart an old run by faking a RemoteEvent; test stale session tokens and invalid input types.

**XP & rewards**

- XP awarded exactly once per genuine NPC kill even with 8 Mossberg pellets, chained lightning, poison ticks and explosions.
- No XP for `Requeued`/technical cleanup, fake enemies or duplicate corpse callbacks.
- Pickup only when server distance/ID/epoch conditions hold; no out-of-range or double pickup.
- Pickups coalesce/despawn without memory growth or client/server count mismatch.
- All three cards are valid and shown with exact numbers; no disabled patrons, rarity downgrade or silent empty choice.
- Rerolls consume only after successful revision, no pity farming or duplicate charge.
- No source of endless free talent upgrades after pool exhaustion; fallback always explicit.

**Combat & AI**

- Glock/AKM/Mossberg magazine/reload/ADS/sprint/slide intact after migration.
- Zombies from each spawn lane reach active moving player across map; use true no-jump and ordinary NPC navigations where appropriate.
- Collision with cars/counters/racks/ramps correct for players, NPCs and weapon raycasts.
- Player not forced into a maze; can see at least two viable rotation paths from major combat areas.
- No unfair immediate back-spawns; visible warning/emergence has safe duration.
- No long gaps waiting for last zombie, no floor quotas, no forced floor exit.

**Economy/persistence**

- Purchases debit once, stock sold once, no purchase in invalid phases or out of distance.
- Permanent research never erased by a failed load; no mock fallback masquerading as real.
- New time-based research payout deduplicated on run ID + milestone, including death/leave/lag. Previous `BestFloor` stays readable.
- Real rejoin persistence only marked VERIFIED on a user-authorized published TEST Experience and authentic DataStore requests. Otherwise remains BLOCKED.

**Performance & longevity**

- Repeatable XP/FX logic and NPC creation have effective caps/pooling; no O(n^2) unbounded per-frame loops.
- Normal and accelerated long-run tests labeled separately. Validate 20/30/45/60+ min if resources permit.
- Server and client output inspected for uncaught errors and leaks; avoid claiming stable 60 min on a 30 sec probe.

## 15. Skills and subagents — pragmatic use

- Review locally available installed skills relevant to Roblox (e.g. roblox-security, roblox-remote-events, roblox-gui, roblox-datastores, roblox-performance, roblox-animations and Studio testing). Use **only verified useful guidance**, never automatically install or execute unknown third-party skill code.
- Use subagents selectively for independent reviews, isolated service prototypes, unit test design, asset catalog, and UI implementation. The **primary agent** owns integration, shared architecture, live Studio MCP runtime and end-to-end acceptance.
- Do NOT let multiple agents concurrently edit `FloorDirector`/`RunSession`/`RewardService`/`Config` or the same Studio world. Do not spin up agents merely because they exist.
- If Blender MCP is available, use it when needed for a missing **specific** modular prop/structure. Do not generate hundreds of unreviewed meshes.

## 16. Progress reporting and stop conditions

- Create/update `AI/ENDLESS_MIGRATION_PROGRESS.md` at the end of EACH milestone with: exact scope, source files changed, screenshot/repro evidence, test names/results, unverified claims, blocking decisions, performance observations and safe continuation instructions.
- Clearly distinguish `IMPLEMENTED`, `TESTED IN STUDIO`, `MOCK ONLY`, `NOT TESTED`, `BLOCKED`, and `REQUIRES USER PLAYTEST`.
- If you approach resource/context limits: finish the current small safe work item, save source files/test evidence/progress, leave Studio stopped in Edit, and give the exact next command. Do not promise invisible background work.
- Stop if the next step would destructively overwrite user content, publish, change permissions, alter live user profiles, require unlicensed assets, or cause unexpected architectural replacement. Ask the user.
- Never claim the entire migration finished because mock QA passes. **The new mode must be genuinely playable in a fresh Studio Play session.**

## 17. Immediate action on receiving this task

1. Read all rules and latest source, including real `git status`/diff and newest checkpoint. Prior drafts may be stale.
2. Briefly report your KEEP/ADAPT/DISABLE/ADD inventory, major risks, rollback mechanism and the concrete M0–M3 plan.
3. Ask only essential questions where a major decision is truly unresolved. The approved decisions above do not require reconfirmation.
4. Begin M0 then M1–M3 sequentially; do not just return a plan. Pause at the **M3 playable vertical-slice gate** if level design/game feel is inadequate instead of blindly proceeding through M4–M8.
5. Keep progress records and tests current, no Git mutations, no unauthorized publish or DataStore changes.

**Success criterion:** The user can launch ZombilkaFPS, pick a gun, run around ONE coherent corporate complex, face zombies who approach them, collect dropped XP, level up and choose functional boons during a genuinely paused single-player game, resume fighting without changing floors, continue beyond twenty minutes, die, see accurate results, and start fresh with temporary power gone and safely preserved permanent research where verified. The old implementation remains safely recoverable during the migration.
