# OFFICE OUTBREAK asset manifest

Only assets actually used are listed below. No old Zombilka project was read. Imported gameplay scripts are not used. Sanitized visual snapshots are reconstructed from repository ModuleScripts; runtime does not load Creator Store model scripts.

| Asset | Source / creator | Use and inspection |
| --- | --- | --- |
| FpsGlock | Existing `assets/FpsGlock.rbxm`; original authorship not supplied | Preserved unchanged. Idle 105345463794666, Shoot 128130246447749, Reload 130294402000435. |
| Drooling Zombie | [187789986](https://create.roblox.com/store/asset/187789986), Roblox | Imported into ServerStorage in Edit mode; disabled then removed eight Script/ModuleScript descendants. Meshes, R6 joint data and face retained in `src/server/ZombieAsset.luau`; old AI never executed. |
| Zombie body meshes/textures | Bundled with Drooling Zombie | Meshes 37683097, 37683150, 37683174, 37683227, 37683263; textures 37686282 / 37687646; face 7074882. |
| Zombie Idle / Run / Attack | Bundled with Drooling Zombie / Roblox | 125750544 / 125749145 / 180416148. Animator lengths observed as 1 / 0.666667 / 2 seconds. |
| Office Chair | [200285525](https://create.roblox.com/store/asset/200285525), consend | Two parts and SpecialMesh; no scripts. Seat converted to an inert Part; all furniture chair collisions/query/touch disabled. Mesh 96065544, texture 96065600. Snapshot in OfficeChairAsset.luau. |
| Pistol Fired / Reload | 3806566911 / 3821789416, existing `ReplicatedStorage.RobloxPistolVisual.Pistol` sound objects | Audio IDs only copied from the already present asset; no Pistol visuals or code integrated. Original audio creator metadata was not present. Successful PreloadAsync, durations 1.474 / 0.868667 seconds. Mechanical and empty-click layers are short configured excerpts of Reload. |
| Roblox Classic Zombie Growl | [121066883602737](https://create.roblox.com/store/asset/121066883602737), divodevs | Creator Store description identifies classic Roblox growl reupload. Successful preload, 1.176 seconds. Shared spatial sample with different pitch/volume for idle, attack, hurt, death; this is an initial mix, not four unique recordings. |
| Elevator Ding SFX | [18192219147](https://create.roblox.com/store/asset/18192219147), Markolo5G | Successful preload, 2.143771 seconds. Low-volume spatial floor-clear/arrival feedback. |

## Original work

OfficeMap constructs the office shell, skyline, desks, displays, kitchen, copier, storage, plants, partitions and elevator from Parts. Two layouts share modules. No giant office pack was imported.

`ZombieClips.luau` contains original finite BodyHit (0.30s), HeadHit (0.38s), Death (3.5s) KeyframeSequences. Studio registers them as temporary Animator assets; these temporary IDs are intentionally not saved to Config. For published play, publish the three clips under the experience owner and fill `Config.ZombieAnimations.BodyHit`, `HeadHit`, and `Death`. Editable sequences are also present in `ServerStorage.OfficeAuthoredClips` in the connected place. Until publication, live servers use bounded joint/death fallback poses; combat never depends on a clip loading.

## Art/audio follow-up

Additional environment search terms: `modern office desk PBR`, `office monitor keyboard`, `office kitchen cabinet`, `photocopier`, `office plant`, `elevator interior`, `office emergency exit sign`. Inspect scripts and geometry before use.

AudioConfig intentionally leaves door open/close, travel motor, world impacts, body/head confirmations and player hurt empty. Source these with clear permission before assigning IDs. No unknown IDs were invented. Evaluate the current reload excerpts and reused growl by ear before treating the sound mix as final.

## 2026-10-05 — user-supplied skinned zombie pack

Current NPCs use ten characters from assets/zombies/source/zombie_ani_player.fbx and the supplied palette textures/world_people_colors.png. Creator/license metadata was not supplied. Original files are retained; no external model scripts are used. The previous Drooling Zombie and R6 clips above are now fallback assets.

Palette image uploaded as 135266649823455. Ten persistent game templates and all 14 mesh IDs are in assets/zombies/roblox and assets/zombies/RobloxAssets.json. Five female/five male bodies retain their UVs and matching hair/hat accessories. Original combined source bind matrices were repaired before FBX export; copied Studio meshes and bones rotated/scaled together to about 6 studs. Source FBX has 38 bones per rig; Studio retained 26 bones for Female D and 30 for each other variant, pruning unused/end bones. No arbitrary bones were added to these imported skeletons; gameplay root/torso/head are separate invisible welded parts.

Walk/idle/attack/hit presentation uses client bone transforms in ZombieVisuals. The 30 original source actions are retained in Zombies_Prepared.blend, but are not Roblox animation assets and are not played by the new rigs. Combat and AI remain authoritative on the server. Details and reproduction tools are in assets/zombies/README.md.

## 2026-10-05 — user-supplied AKM, FPS arms and Mossberg

Sources: assets/Fps Rig AKM.glb, assets/Rigged Fps Arms.glb and assets/Mossberg 590A1.glb. Creator/license metadata was not supplied. Original files retained; no scripts used. Colors baked to four 2048×2048 PNGs and applied to single-UV export copies. Source AKM animations sampled; shotgun actions authored after assembling the separate arms and weapon. Source actions remain editable in prepared Blender copies; game playback uses local motion modules rather than new published animation IDs.

All uploaded IDs are in assets/weapons/RobloxAssets.json. Persistent models are assets/weapons/roblox/FpsAKM.rbxmx and FpsMossberg.rbxmx, mapped through Rojo; Glock remains assets/FpsGlock_GameTextured.rbxmx. Actual model renders supply the three selection card pictures. FBX, UV, rig basis, muzzle/ADS details and observed validation are in assets/weapons/README.md. Weapon audio currently reuses the existing pistol prototype mix.

2026-10-05 generated-floor extension uses native Roblox parts for new lab equipment, parked cars, storage bays and stair galleries. The existing sanitized OfficeChairAsset remains the only imported furniture dependency. No new Creator Store models, scripts, textures or external uploads were added.
