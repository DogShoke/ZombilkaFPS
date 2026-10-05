# FPS weapons

The user supplied `assets/Fps Rig AKM.glb`, `assets/Rigged Fps Arms.glb` and `assets/Mossberg 590A1.glb`. Originals are retained. No asset scripts were imported. Creator/license metadata was not included with these files.

## Game assets

- `roblox/FpsAKM.rbxmx`: two skinned MeshParts, 28 imported bones, texture maps for gun and arms.
- `roblox/FpsMossberg.rbxmx`: two skinned MeshParts, 27 imported bones, separately assembled gun and arms.
- `motion/AKMClips.luau`: sampled source Idle, Shoot and Reload actions.
- `motion/MossbergClips.luau`: fitted Idle, pump-action Shoot and one-shell ReloadShell motion.
- `RobloxAssets.json`: uploaded mesh, texture and card image IDs.

`default.project.json` maps these to ReplicatedStorage.Assets. WeaponMotion plays the sampled bone transforms locally; these two weapons do not require separately published Roblox animation IDs. Glock keeps its existing rig, textures and published Animator clips.

Choose Glock, AKM or Mossberg using the initial cards or keys 1/2/3. No viewmodel, movement or zombie spawning before selection. The server validates selection and owns magazine, rate, spread, damage, reload and wave state. Death opens selection again. Weapon values and poses are in `src/shared/Weapons.luau`.

## Blender/export copies

`*_Source.blend` preserve imported source data, including the original editable AKM animations. `*_Prepared.blend` retain the baked setup and authored Mossberg actions; `*_Roblox.blend` contain only the single BaseColor UV on each mesh. The AKM game motion is sampled into AKM_Clips.json after adapting the copied bind pose. Four 2048×2048 sRGB PNGs are in `textures/`. Cycles diffuse color was baked with direct/indirect light disabled and 16px margin.

The final FBXs are `exports/FpsAKM_Roblox.fbx` and `exports/FpsMossberg_Roblox.fbx`. Export includes armature and both meshes, skin weights, no leaf bones and no FBX animation baking. Animations remain in their Blender source/prepared copies and the sampled game modules. Each exported mesh has exactly one UV map and one visible material. Initial exports with two UV maps were removed because Studio selected the old map; the preparation tool now exports copies with one UV directly.

The prepared coordinates are Y-up / −Z forward. Studio requires a complete assembly basis correction. `tools/prepare_studio_templates.luau` moves the copied parts together and preserves imported Bone.CFrame and Motor6D offsets. The same RigBasis is used for the viewmodel and to convert sampled motion. Do not rotate bind bones independently or fix only the visible pose: either causes inverted motion or skin deformation.

Barrel attachments use the actual front cross-section of the source geometry, rather than the highest bounding-box point. Effects use the animated bone transform; tracer origins are frozen at emission so recoil cannot move an existing trace. ADS poses align rear and front sights with camera center.

Corrected user imports are archived in Studio under ServerStorage.WeaponsSourceImport. Original Glock assets were not overwritten. The connected Rojo process may need restarting/reconnecting to pick up new Assets mappings; code directories sync automatically.

## Verification on 2026-10-05

Final FBX reimports had one UV/material on both meshes. Blender renders checked held, shooting, reload and ADS poses. Studio play observed initial cards with loaded images, empty hands and zero spawned zombies; selection starts waves. AKM automatic fire consumes a 30-round magazine and reloads in 2.6s. Mossberg emits eight pellet impacts, consumes one of six shells and moves the pump about 0.263 studs in the runtime sample. Reload duration is 3.6s. Close-range test target took 96 body damage and 144 head damage per full shotgun shot. ADS for both guns was inspected in the viewport. AKM tracer origins measured zero distance from animated Barrel position at creation.

Saved rbxmx files were parsed by a fresh Rojo server and reconstructed through AssetService in Studio: 38 instances for AKM and 37 for Mossberg, no property errors. These reconstructed templates were then exercised in Play. Original Glock Idle and accepted Reload were observed playing. Invalid Order selection and mid-run weapon switching were ignored. A final clean Play session had empty Output. Stop removed all temporary targets, hooks and health changes.

Current gunshot/reload audio uses the existing prototype mix for all weapons. New weapon-specific audio is not implemented.

## Grip, ADS, pellet tracers and shell reload update

AKM ADS now has 2.6 studs of eye relief to keep the receiver/stock outside the camera clipping plane. Mossberg uses 0.9 studs. Both sight axes remain aligned to camera center. `tools/refine_mossberg_motion.py` fits wrists/elbows and preserves finger inheritance, writes the new Idle/Shoot/ReloadShell poses and saves a separate `Mossberg_GripAnimations.blend`. Original bind frames, geometry, weights, textures and imported templates remain unchanged. Compile sampled poses with `tools/compile_motion.cjs`; no FBX reimport is needed.

Each weapon has its own configured tracer width, duration and maximum visible length. Every shotgun shot returns all eight server ray endpoints, including misses. The client draws eight traces from the muzzle position captured for that shot; impact effects remain tied to actual hits.

Mossberg loads one shell after each 1.05s animation until six rounds. A valid shot interrupts loading immediately and consumes one existing shell. Unique reload tokens prevent canceled cycles from adding ammunition. Studio observed 3→4→5→6 refill, and normal mouse input interrupted 3→4→5 with a shot leaving four rounds. Three shots produced 24 traces. Death during loading added no shell and returned to ChoosingWeapon with zero ammo. AKM magazine reload rejected a shot while loading and restored 30; Glock mouse fire created one trace and reloaded 11→12. Updated Mossberg held/ADS grip and AKM ADS were visually inspected in Play. Final Output was empty and Rojo build passed. Stop removed runtime diagnostics and test health changes.
