# Zombilka FPS

New single-player first-person zombie shooter. Seeded procedural floors replace the two fixed office layouts. Offices, laboratories, warehouses and parking areas have three waves, guarded elevator travel, loop routes and occasional upper galleries while preserving the authored weapons.

Rojo maps `src/shared` to `ReplicatedStorage.Shared`, `src/client` to `StarterPlayerScripts.Client`, and `src/server` to `ServerScriptService.Server`. Repository source is authoritative. Office geometry and sanitized visual asset snapshots are built from code; `assets/FpsGlock.rbxm` remains unchanged.

Controls: WASD, mouse, Space; Shift sprint; LeftCtrl or C slide; LMB fire; RMB ADS; R reload; E elevator interaction. Death restarts the current generated floor. The next numbered floor is generated from the run seed; cleared geometry is removed after arrival. Only two physical slots are used, without a finite floor limit. Footprint: 264×288 studs; galleries are 10 studs above ground with two stairs. Run.Generation and Run.Difficulty hold generation/progression tuning. Simultaneous zombies rise from nine to a cap of 16; wave counts and enemy stats also have explicit caps.

At run start and after respawn, choose Glock / AKM / Mossberg using cards or 1/2/3. No weapon or zombie spawning before choice. AKM is automatic; Mossberg fires eight pellets with range falloff and a pump animation. Weapon stats/poses live in Shared.Weapons; persistent rigs and motion samples are in assets/weapons. Reserve ammo is infinite; Mossberg loads one shell per animation and allows firing to cancel, retaining inserted shells.

No talents, XP, multiplayer, DataStore, inventory or monetization. See `AI/ASSETS.md` for dependencies and the three reaction/death clips that need publication for live Animator playback. See `AI/IMPLEMENTATION.md` for observed Studio tests and limitations.
