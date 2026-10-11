# Native Studio migration checks

## Current ordinary prototype — no QA setup required

Press Play in ZombilkaFPS.rbxl and choose a weapon. GameModeConfig.StudioMode defaults
to EndlessSurvivalPrototype, so the shipping init builds CorporateComplex and starts
the minimal combat preview; no QA script or separate place needed. Existing Edit
preview is safely archived for runtime. Old OfficeRun remains in LegacyMapArchive.
Rollback: StudioMode="LegacyFloors", wait for Rojo sync, then restart Play.
LiveMode remains legacy; no Experience publication/settings changes.

Observed ordinary-run evidence: results/PrototypeOrdinaryPlay_20261011.json,
PrototypeOrdinaryCollision_20261011.json and three Prototype_*.png screenshots.
Earlier blank3D limitation below is historical: current ordinary Play/Edit view worked.
Avoid rerunning redundant checks; user is evaluating map visuals/gameplay next.

## Earlier isolated M1 checks (historical)

These QA files are outside default.project.json and are not shipping scripts.
Run only in a fresh local Studio Play session, then Stop even after an error.
Do not save/publish the temporary world or change Experience settings.

- CorporateMapQA.luau: temporary ModuleScript returning a function(map,options).
  Build CorporateMap under a QA-owned Workspace folder at an isolated origin;
  invoke from a native Server Script with an optional dedicated ZombieRig ActorModel.
  It checks paths/clearances/flags/counts and actual actor walking. Never pass a player
  character as ActorModel. The script must set JSON Report/Complete attributes for
  observation, as described in the migration progress document.
- RuntimeCorporateChase.luau: temporary native Server Script. Run while legacy
  ChoosingWeapon is idle; creates QA_ChaseWorld at(450,400,0). Uses production
  ZombieService and a real test player. Observe Complete/Success/Report attributes.
- RuntimeCorporatePerch.luau: run AFTER Chase completes in the SAME Play session;
  uses its map and tests real NPC ascent/attack at three cover tops. Player teleport
  to a roof does not prove player jump accessibility. These scripts are sequential:
  they share ZombieService/player and must never run concurrently.

Native Script execution matters: MCP execute_luau has a separate require cache.
Direct MCP module Count() is not authoritative evidence for a production service
already required by init. Observe replicated state/real instances and native Script
report attributes instead. Stop removes native QA additions; verify no QA_ leftovers.

results/EndlessMap* retain v1 failures and v2 retests. The two movement reports observe
server and client separately: server-only WalkSpeed/Sliding cannot prove or disprove
the client's local slide state. Collision and movement cases used ordinary keyboard
inputs after choosing Glock, rather than forced movement during the input interval.

No accepted 3D screenshot exists at this checkpoint. Navigation and collision evidence
does not prove appearance, weapon compatibility, enjoyable layout, new endless combat,
XP/rewards, long-run performance or DataStore persistence. See
AI/ENDLESS_MIGRATION_PROGRESS.md before continuing or changing acceptance status.
