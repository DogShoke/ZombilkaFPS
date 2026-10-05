# OFFICE OUTBREAK 1.0

## Current task — 2026-10-05, Procedural Defense 2.0

Implement the user's ZombilkaFPS_PROCEDURAL_DEFENSE_CODEX.md in the existing Rojo project. Completed: six deterministic combat graphs across four themes, real loops/two defense positions/gallery approaches, thematic landmarks, validated geometry with bounded retries/fallback, phase-specific semantic spawn sectors and announced flanks, mandatory ClearWaves/Holdout/Survival obligations, safe recovery, server-authorized elevator/death reset, and readable HUD. No quest mechanics or cooperative mode.

Studio evidence and limits: 600 deterministic plans; 48 theme/macro/seed navigation samples with 2,008 actual path queries; player and NPC traversal of both gallery approaches; five consecutive transitions, Holdout/Survival cleanup gates, spawn-failure/recovery accounting and death reset; no-kill cap-filled flank; actual sprint interception; 16-enemy comparative server sample. See tests/results/ProceduralDefenseQA.json and AI/IMPLEMENTATION.md. Normal-length player balance/readability remains for human playtesting. No commit requested for this implementation.

Preserve authored FpsGlock and server combat. Build two readable office floors, three configurable waves per floor, a server FloorDirector and sliding elevator transition. Fix accepted-reload animation, add C slide. Settings and their pause menu were removed on 2026-10-04 at user request; sprint retains speed through jumps and quick slide input survives acceleration. Use sanitized ready-made zombie/visual/audio assets; record provenance and actual Studio observations. No talents, persistence, multiplayer or automatic commit.

2026-10-05 extension: add Glock / AKM / Mossberg selection cards before spawning; bake the user-provided weapon/arms colors; assemble and animate the separately supplied shotgun and arms. Preserve originals and existing Glock. Fix new-rig orientation, reload motion, ADS and barrel effect origins. Rojo files remain authoritative.

Current extension: endless larger generated floors with offices/labs/warehouses/parking, multiple routes and side rooms, occasional upper levels, and capped gradual difficulty. Preserve selection, combat and elevator guards. Replace reuse of two authored layouts with two bounded physical slots containing newly generated layouts. Verify player/NPC stair traversal, navigation, consecutive travel, difficulty limits and death reset in Studio.

2026-10-05: User requested ten original faceted city zombies based on attached references. Before starting, existing progress was committed as 8b9cd35 and fast-forwarded/pushed to origin/main. New generated pack is integrated through Rojo assets and Config.Zombies.VariantFolder, with ten variants runtime-tested. The user subsequently requested publishing the current changes to main and a Russian guide to the existing generator; docs/LEVEL_GENERATION.md records its current behavior and editing points.
