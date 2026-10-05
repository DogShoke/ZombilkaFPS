# Zombilka FPS

New single-player first-person zombie shooter. OFFICE OUTBREAK 1.0 adds two office layouts, three waves per floor and guarded elevator travel while preserving the authored FpsGlock.

Rojo maps `src/shared` to `ReplicatedStorage.Shared`, `src/client` to `StarterPlayerScripts.Client`, and `src/server` to `ServerScriptService.Server`. Repository source is authoritative. Office geometry and sanitized visual asset snapshots are built from code; `assets/FpsGlock.rbxm` remains unchanged.

Controls: WASD, mouse, Space; Shift sprint; LeftCtrl or C slide; LMB fire; RMB ADS; R reload; E elevator interaction. Death restarts the current floor. After floor 2, the next floor reuses layout 1 with an increasing displayed floor number.

At run start and after respawn, choose Glock / AKM / Mossberg using cards or 1/2/3. No weapon or zombie spawning before choice. AKM is automatic; Mossberg fires eight pellets with range falloff and a pump animation. Weapon stats/poses live in Shared.Weapons; persistent rigs and motion samples are in assets/weapons. All magazines currently use infinite reserve ammo and refill on reload completion.

No talents, XP, multiplayer, DataStore, inventory or monetization. See `AI/ASSETS.md` for dependencies and the three reaction/death clips that need publication for live Animator playback. See `AI/IMPLEMENTATION.md` for observed Studio tests and limitations.
