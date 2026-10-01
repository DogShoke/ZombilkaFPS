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
