# Original arena kit — 2026-10-06

Created in Blender for this project, without downloaded environment assets. Editable sources: `tools/build_coffee_spawner.py`, `tools/build_arena_kit.py`. `CoffeeSpawner.blend` contains the machine/cracks/debris; `ArenaKit.blend` additionally contains six cover models. Manifest JSON files record mesh counts/dimensions. `CoffeeSpawner_Preview.png` shows the machine.

All nine meshes use one UV and the shared 500×50 sRGB `ArenaPalette.png`; faces sample palette cells, without an overlapping baked atlas. User imported `exports/Zombilka_ArenaKit.fbx`. Texture ID: **81680636077136**.

| Template | Mesh ID | Triangles |
| --- | --- | --- |
| CoffeeSpawner | 102454023730182 | 4704 |
| GroundCracks | 138784631842501 | 672 |
| GroundDebris | 97906594010726 | 100 |
| ArenaCar | 102874542370859 | 1124 |
| ArenaContainer | 114573893001975 | 3612 |
| ArenaDeskBank | 102756585989034 | 572 |
| ArenaLabBank | 121217071904634 | 484 |
| ArenaRack | 110527609755916 | 704 |
| ArenaBarrier | 125015207764300 | 352 |

Imported sizes were uniformly divided by 100. Normalized `roblox/*.rbxmx` are Rojo templates under `ReplicatedStorage.Assets.ArenaKit`; the original imported group is preserved in Studio `ServerStorage.ArenaKitSourceImport`. Runtime placement uniformly scales and grounds each model; coffee height 8 studs. No character rig is involved.

Visual meshes have no collision/query. Cover uses transparent box colliders; coffee has a server damage/collision body. `SpawnSources` and `ArenaEffects` add light, steam, shield, layers, hit flashes and reinforcement particles. Dust/steam uses Roblox built-in smoke texture. The optional texture server utility was not needed and is not running.
