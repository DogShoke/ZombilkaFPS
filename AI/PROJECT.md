# Zombilka FPS

Current source (2026-10-09): Office/OpenArena5×5, 180×180, continuous horde and
KillQuota only. The multi-theme/three-wave paragraphs below are historical.
Roguelike milestone1 is verified: server RunSession ledger, death ends the run,
actual validated Floor1 rebuild, results screen and explicit new-run selection.
FloorDirector owns physical phases; WeaponService owns ammo/action cancellation.
Roguelike milestones2/3 are verified in Studio: three labeled patron elevators,
server-authoritative rewards and nine level1–3 effects for Volta/Bravo/Weiss.
Milestones4/5 verified: authored four-rarity tables, funded rerolls/pity/softweights,
bounded credits, safe vending and rare Zavkhoz shop. Stage6 research/profile/UI
implemented and tested through explicit mock stores in Studio; actual DataStore
save/rejoin blocked by unpublished place. Other five patrons, special talents and
normalfloor1–12balance remain pending.
Continue using AI/ROGUELIKE_PROGRESS.md for the exact verification checkpoint.

## Historical notes (obsolete behavior below)

New single-player first-person zombie shooter. Seeded procedural floors replace the two fixed office layouts. Offices, laboratories, warehouses and parking areas have three waves, guarded elevator travel, loop routes and occasional upper galleries while preserving the authored weapons.

Rojo maps `src/shared` to `ReplicatedStorage.Shared`, `src/client` to `StarterPlayerScripts.Client`, and `src/server` to `ServerScriptService.Server`. Repository source is authoritative. Office geometry and sanitized visual asset snapshots are built from code; `assets/FpsGlock.rbxm` remains unchanged.

Controls: WASD, mouse, Space; Shift sprint; LeftCtrl or C slide; LMB fire; RMB ADS; R reload; E elevator interaction. Death restarts the current generated floor. The next numbered floor is generated from the run seed; cleared geometry is removed after arrival. Only two physical slots are used, without a finite floor limit. Footprint: 264×288 studs; galleries are 10 studs above ground with two stairs. Run.Generation and Run.Difficulty hold generation/progression tuning. Simultaneous zombies rise from nine to a cap of 16; wave counts and enemy stats also have explicit caps.

At run start and after respawn, choose Glock / AKM / Mossberg using cards or 1/2/3. No weapon or zombie spawning before choice. AKM is automatic; Mossberg fires eight pellets with range falloff and a pump animation. Weapon stats/poses live in Shared.Weapons; persistent rigs and motion samples are in assets/weapons. Reserve ammo is infinite; Mossberg loads one shell per animation and allows firing to cancel, retaining inserted shells.

No talents, XP, multiplayer, DataStore, inventory or monetization. See `AI/ASSETS.md` for dependencies and the three reaction/death clips that need publication for live Animator playback. See `AI/IMPLEMENTATION.md` for observed Studio tests and limitations.
