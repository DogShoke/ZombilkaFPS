# Zombilka FPS project rules

- This repository is a new game. Never inspect or reuse the old `C:\Roblox\Zombilka` project.
- Rojo files are the source of truth for code. Use the connected Studio place for runtime verification.
- The server owns combat, ammo, damage, zombie AI, and game state. The client owns input and presentation.
- Keep gameplay values in shared configuration. Avoid unnecessary frameworks and giant controllers.
- Test changes in Roblox Studio at runtime. Do not claim runtime behavior was verified without observing it.
- Do not commit automatically.
