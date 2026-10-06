# Authored environment game kit — 2026-10-06

203 user-authored assets copied from OfficeKit (55), OfficeZones (44), ParkingKit (52), and ParkingExpansion (52). The four original Blender files and their individual exports are preserved. `tools/prepare_game_kit.py` builds a separate export scene and a combined FBX; it does not save over the source scenes.

The user imported `exports/Environment_GameKit.fbx` in Studio. `roblox/*.rbxmx` contains the resulting uploaded MeshIds, grounded at the origin in metres. All assets have one UV and use `OfficePalette.png`; Roblox texture: `rbxassetid://87744524834349`. MeshPart color is white so the imported default grey tint does not darken the palette. Total source triangles: 95,420. Rojo mounts all 203 templates at `ReplicatedStorage.Assets.EnvironmentKit`.

Export: forward -Z, up Y, unit conversion enabled, space transform enabled, bake_space_transform disabled. Imported sizes were divided by 100. Manifest `dimensions_xyz_m` records the actual Blender world bounds, including authored object rotations; `source_dimensions_local_m` records local dimensions. In Roblox the axes are X/Z/Y. Flat decals can have zero source thickness; Roblox may clamp their MeshPart thickness during scaling. They have no collision or query.

Runtime uses `Config.Run.Generation.StudsPerMeter = 3.5` for all new assets. `OfficeTiles.luau` defines authored whole-module variants; `FloorLayout` uses the fixed Office OpenArena 5×5 grid. Each floor uses a subset, rather than placing the full catalog. Individual mesh visuals are anchored and have no collision/query/touch; practical obstacles use one transparent bounding box. Twelve ceiling lights, structural enclosure, elevator and the compact raised tile use Roblox geometry. See docs/LEVEL_GENERATION.md to edit the current prototype.

The original infected CoffeeSpawner, GroundCracks and GroundDebris remain in ArenaKit with their gameplay effects. The six old generic ArenaKit cover models are no longer selected by OfficeMap. Source imports are retained under ServerStorage; they are not rendered in the playable map.

Orientation fix: a mesh can already be Y-up while its imported PivotOffset is rotated or displaced. ArenaAssets resets BasePart PivotOffsets on the clone before bounding/scaling/grounding; normalized EnvironmentKit templates use identity offsets. Spawn placement applies only the requested yaw. Do not compensate for a stale pivot with an extra 90-degree rotation.

Verification scripts outside the shipped tree: `tests/EnvironmentModels.luau` checks all templates at three yaw angles; `tests/ProceduralFloors.luau` checks deterministic plans and real Roblox paths. Actual observations are recorded separately in `tests/results/EnvironmentGameKitQA.json`.
