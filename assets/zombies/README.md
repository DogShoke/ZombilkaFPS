# Zombie variants

The user-provided `source/zombie_ani_player.fbx` and `textures/world_people_colors.png` are preserved. Ten characters are split into five female and five male variants; four accessories stay with their respective bodies.

The game uses `roblox/Zombie_*.rbxmx`, mapped to `ReplicatedStorage.Assets.Zombies` in `default.project.json`. These contain the uploaded skinned meshes, matching bones, motors, original UVs and palette texture. `RobloxAssets.json` records the actual mesh and texture IDs. Studio copies have a height of approximately 6 studs. No imported scripts are included.

`exports/Zombies_All_Roblox.fbx` is the corrected combined export; `exports/Zombie_*.fbx` are individual exports. The FBXs have normalized 1.8-unit bodies with object transforms baked consistently into mesh and armature data. Studio imported them lying along Z at 1.8 studs, so the stored Roblox templates rotate the complete skeleton and meshes together and uniformly scale to 6 studs. Do not use the original combined FBX directly for runtime NPCs.

The source FBX had inconsistent layout and cluster bind matrices. `tools/prepare_variants.py` restores rest/bind alignment from the original cluster data before normalization. `tools/verify_exports.py` checks all individual exports for height and weighted head/bone alignment. `Zombies_Prepared.blend` keeps all 30 source actions as retained data; they are not exported as Roblox animation clips after the rest-pose correction. Runtime walk, idle, attack and hit presentation uses `src/client/ZombieVisuals.luau` bone poses. Combat, movement decisions and health remain server controlled.

On 2026-10-05 the ten saved templates were read through a fresh Rojo server and reconstructed in Studio, then tested in Play. All ten original prepared variants stood at root Y=183 on floor Y=180; walking reached 11 studs/s and thigh transforms varied by approximately 40 degrees. The saved versions subsequently spawned in normal waves with visible textures and animated bones. Body/head shots dealt 25/50 damage; zombie attacks dealt 12; death disabled query/collision. Original source clips still need retargeting/publication if desired.
