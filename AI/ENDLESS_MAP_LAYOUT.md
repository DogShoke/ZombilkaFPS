# Corporate Complex — authored M1 blockout

2026-10-11. Design written before geometry implementation. Source of truth: `src/shared/CorporateLayout.luau`; reproduction: `require(Server.CorporateMap).Build()`.

320 × 320 studs; north is −Z. Ground circulation is level; version 2 adds two visible maintenance decks with two wide ramps each to prevent narrow rack/container tops becoming unreachable farming positions. No roof or jump-required approach. Spawn (0, 20) faces north toward reception. This is a combat blockout with reused art, not final detailed environment art or a claim of fun.

```text
                         NORTH −Z
       PARKING              OFFICE                 SERVICE
  ┌─────────────────────────────────────────────────────────┐
  │   security     ═══ north crossing z=−92 ═══    loading  │
  │   cars N       │   cubicles / reception    │  racks N   │
  │                │                          │            │
  │ ═══════════ central crossing z=0 ═════════════════════ │
  │   cars S       │         SPAWN            │  racks S   │
  │                │    lounge / archives     │            │
  │   barrier      ═══ south crossing z=92 ═══    utility  │
  └─────────────────────────────────────────────────────────┘
                   x=−56                 x=56
```

The parking loop runs along x=−140/−56 and z=−92/+92 around two car islands. The service loop runs along x=56/140 and the same crossings around rack/loading islands. All three horizontal crossings connect both loops without doors; centre reception/lounge islands are passed on their exterior flanks, not through furniture. Each major cover group has exterior flanks; mandatory gaps remain at least 16 studs. Outer perimeter is a circulation lane, not a spawn-only inaccessible ledge.

- **Lobby/office:** reception north of spawn supplies a readable focal point, lateral cubicle banks break distant fire without enclosing small rooms; southern lounge gives low cover. Two sparse archive groups mark outer office circulation.
- **Parking:** paired parking banks use existing ArenaCar meshes at the normal 3.5 studs/metre kit scale. Painted bays, columns, a security booth and short barriers identify an actual parking court. Cars are individually queryable/collidable simplified hulls, not a single giant island blocker.
- **Service:** paired server stations, an authored loading container and utility station provide hard cover and visible asymmetric identity. Racks and containers retain collision; cosmetic chairs/plants do not obstruct mandatory routes.

Authored ground spawn lanes lie in open crossings/perimeter positions. Runtime still validates player distance, rear approach, separation, overlap and real path; the layout never grants spawn approval by itself. No event spawner or shop currency behavior is included. Reserved shop sites are benign future vending locations, distinct from infected coffee machinery.

`CorporateMap.Build({Parent=workspace, Origin=Vector3.new(0,180,0), Greybox=false})` owns ONLY its returned `CorporateComplex` model. It refuses a colliding existing name instead of deleting user content; caller destroys only its own model during controlled cleanup. It does not invoke OfficeMap/FloorDirector, delete OfficeRun/Baseplate, adjust Lighting, save a place, or change Experience settings. A detached/custom Parent supports isolated tests.

Returned contract: `Model`, `Run` (alias), `Origin`, `Spawn`, `Entry`, `Bounds`, `Zones`/`SpawnSources` (ground emergence lanes), `NavGraph={Nodes,Edges}`, `Layout`, `Probes`, `DeckProbes`, `ShopSites`. Nodes use local `X,Y,Z`; lanes use world `Position`. Native authored-map tests use `ZombieService.Configure(Zones, Bounds, 1, NavGraph.Nodes, Model)` for initial tuning. The optional fifth argument selects the authored world for spawn overlap validation; legacy four-argument calls clear that override and retain OfficeRun lookup.

Verification pending primary Studio integration: spawn view; walking/sprint/slide on all three crossings and both loops; weapon queries/car/rack collision; native no-jump paths from every lane to spawn and all zones; actual NPC approaches; boundary escape attempts; asset pivot/texture/orientation review. Static layout alone does not satisfy M1. Parent agent records evidence and findings in `AI/ENDLESS_MIGRATION_PROGRESS.md`.

## Version 1 → 2 correction

Primary Studio QA observed native navigation and three-zone pursuit passing. A stationary top-of-cover probe exposed two failures: first ServiceNorth ServerRackTwin and Loading ArenaContainer produced no player damage in 30 seconds. Cars passed (damage after approximately 12.9 seconds), so car geometry is preserved. Failure evidence is retained in `tests/results/EndlessMapPerchQA_v1.json`; these results are not version 2 acceptance.

Version 2 provides a visible 36×24-stud maintenance deck over the north rack bank, its top aligned to the actual mesh hull height (~7.35). Two 12-wide, 22-long ramps reach it from north/south (~18.5°). Ends z=−78/−10 stay outside crossing lane disks at −92/0. Loading has an 18×12 deck at its actual roof (~7.56) and two 12-wide, 20-long ramps (~20.7°), ends z=−152/−100. No invisible anti-player barrier, AI speed/range change or player movement change is used. Decks are physical visible DiamondPlate surfaces, not replacement invisible hulls. `DeckProbes` contains separate elevated test targets; ground navigation probes remain unchanged. Models stay individually editable in the authored layout. Primary must repeat top pursuit and no-jump ramp tests, plus original ground navigation and clearances.

The existing Studio rendering capture returned blank 3D even for legacy content/debug geometry; therefore native navigation evidence does not count as passed visual/art review. Preserve that limitation until a reliable view is observed.

Primary repeat of v2 passed48 native no-jump paths (including4 ramp approaches),
all ground corridor samples, two dedicated actor walks, three-region actual NPC
attacks and all three top-of-cover attacks. Production player walk/sprint/slide crossed
the central link through all zones; representative car/rack/container side collision
stopped the player. Full visual/art review and remaining traversal checks stay pending.
See progress and tests/results for actual timings and precise limitations.
`ENDLESS_MAP_LAYOUT.svg` shows top-down polygons sampled from the native v2 collision
parts, with authored spawn markers; it is a schematic, not a screenshot.

Latest 2026-10-11: ordinary Studio Play now builds CorporateComplex at(0,180,0)
through GameModeConfig.StudioMode=EndlessSurvivalPrototype; isolated QA is no longer
needed to see/play the map. Existing weapons and normal NPC combat active, no
FloorDirector/elevators/XP. Court signs face inward and prototype uses daylight.
Actual ordinary Play and Edit3D were observed; screenshots saved in tests/results/
Prototype_*.png. Old blank capture status above is historical. Edit preview is tagged
EndlessPrototypePreview and archived safely on Play; old OfficeRun is preserved in
ServerStorage.LegacyMapArchive. User map review remains pending; see CURRENT progress.
