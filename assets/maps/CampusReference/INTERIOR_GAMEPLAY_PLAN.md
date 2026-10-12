# Campus V4 — FPS zombie run spaces

2026-10-12. Authorized scope: Blender building contents and authored activity sites. The user explicitly selected this scope instead of Roblox activity implementation. This supersedes neither gameplay source nor the active CorporateComplex.

## Intended run

Explore connected districts while fighting zombies manually in first person. Location choice supplies different cover, routes and optional reward/risk opportunities. Megabonk is a reference for exploration, build growth, loot and optional challenges; this environment is an original zombie campus adaptation. Reference: https://store.steampowered.com/app/3405340/Megabonk/ and official announcements https://steamcommunity.com/app/3405340/announcements/.

The current prototype has no new-mode XP/shop/activity handlers. All sites below are **authored geometry and integration proposals**, not working rewards, purchases or enemy events. Keep server authority, existing weapons and zombie systems when implementing later.

## Building program

| Building | Location / contents | Prepared opportunity |
|---|---|---|
| Central atrium | command/reception arena; upper U gallery and two stairs; consoles, quarantine barriers, maps | elite beacon, loadout workbench, cache |
| West wing | office salvage zone; cubicle islands, archives, printer/copy rooms | salvage caches, risk console |
| East wing | contaminated biolab; specimen pods, benches, decontamination hardware | purifier defence, sample search |
| West annex | armory/security; weapon benches, lockers; observation mezzanine | weapon bench, optional elite signal |
| East annex | server/data centre; rack banks, cooling, control mezzanine | charge relay, data cache |
| Original service warehouse | repair/power workshop; tools, engine parts, upper service deck | power restart and salvage recycler |
| Research B-02, two floors | experimental equipment, reactor/test bays; analysis upstairs | reactor charge, risk experiment |
| Medical C-04 | triage beds, pharmacy, operating bay | limited recovery station, medical cache |
| Logistics D-01 | cargo racks, conveyors, inventory counter | cache/elite cargo encounter |
| Workshop D-02 | vehicle repair, lift frame, tooling, spare parts | recycler and repair reward site |
| Transit terminal | waiting area, ticket counter, baggage, dispatch | radio challenge, luggage caches |
| Fuel mart | retail shelves, cold storage, counter | supply cache / trade station |
| Lakeside café | kitchen, counter, seating, pantry | recovery brew / breakable supplies |
| Field lab E-03, two floors | field samples, analysis, radio and specimen storage | sample search / scanner defence |
| Both security buildings | CCTV, lockers, access controls | route terminal / cache |
| Three maintenance sheds | hollow accessible utility interiors | small power/supply sites |
| Two coffee kiosks | hollow counter/storage interiors | outdoor recovery/trade site |
| Four watchtowers | compact radio/observation booths | radio/cache sites; future NPC ascent verification |

## Spatial rules

- Preserve mountains, detailed fleet, outdoor districts and the 480 × 440 m campus.
- Main combat rooms: open entrance plus independent secondary exit, nominal 6 m bays. Core raised floors require real exterior landings/stairs, not floating doorways. Annex entrances must not terminate inside overlapping wing walls.
- Reserve broad central cross routes and clear entry approaches. Cover is clustered in islands, with a mix of low cover and taller sight blockers. Do not fill the entire footprint with desks.
- Two existing two-storey buildings receive internal stairs through actual slab openings and retain exterior upper access. Atrium/annex/workshop mezzanines receive visible routes; no inaccessible reward perch is accepted by design alone.
- Small kiosks/sheds become hollow shells. Their small rooms are optional service/loot spaces, not mandatory horde choke points.
- Activity props use distinct silhouettes/accent colors and separate object identities. Manifest records building/floor, position, type, interaction approach, recommended footprint, and integration status.
- Decorative geometry, gameplay cover, structural floors and activity props carry separate roles for later collision/LOD authoring.

## Milestones / verification

1. Inventory/design: completed by source and scene review. Live Blender was in Edit Mode; checkpoint before changes preserves the current scene.
2. Geometry/contents: completed. 25 buildings, 31 floor spaces, 55 inactive authored activity sites and 28 breakable supply candidates. Real wall/slab openings, external entry approaches, internal stairs and galleries are present.
3. Blender QA: completed for this art milestone. 849 geometry samples passed with zero failures; no empty meshes/nonfinite coordinates; both FBX exports have zero warnings. Representative interior/cutaway renders inspected. These checks are not Studio runtime proof or a complete navigation guarantee.
4. Later user-authorized map integration: completed as a playable prototype. Filesystem mesh IDs/normalized transforms, physical hulls, spawn/nearby emergence positions and55 inactive markers are connected to ordinary Studio Play. Bounded real input/combat/AI/death/restart and final collision rays verified; details in latest README. Full activity handlers, progression, exhaustive traversal and sustained performance remain pending.

Resume from this plan and the latest README checkpoint; edit the V4 Blender scene, not a previous V1/V2/V3 file. No commit, push, publish or place overwrite is authorized by this asset task.
