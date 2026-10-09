# Roguelike Studio QA

## Stage6 persistence and research (2026-10-09)

ProfilePersistence20/172 and ResearchIntegration12/127 execute as temporary Play
Scripts before combat. They use isolated injected stores explicitly labelled Mock,
including commit-then-error, retries, migrations, concurrent merges, cumulative
floor payouts, bounded receipts, schema failure and shutdown enqueue. Integration
temporarily binds Effects to fake characters: mandatory Stop/restart afterwards.
Mock save/new-service reload is NOT real Roblox DataStore/rejoin verification.

RuntimeResearchFlow.luau: Play-only, root-controlled actualGUI driver. Installs
after ChoosingWeapon; deliberately ends initialemptyrun to capture ResearchService
through its Publish method, restores that hook, substitutes an explicitly labelled
in-memory store, seeds test-only603research. AtStage BuyResearch open results
ResearchButton, buy body1/budget1/protocol1/scanner2/archive2 using row+Confirm
(seven separate purchases, total150). Close/NewRun/Glock atStage StartGlock.
Driver accelerates realNPC issuance/deaths to clear actual firstquota30, validates
scanner signs, selects a server-valid patron route; click a real card atClaimBoon.
Driver dies/resets/reloads a NEW mock service from SAME fakebackend; then requests
actual NewRun/AKM and NewRun/Mossberg. Observe Complete/Success/Report. Stop removes
mock profile, hooks and tuning. This does not measure floor1–12balance or real rejoin.

Current PlaceId/GameId0: actual GetAsync capability probe fails with publication
required. Never publish/change Experience settings to force a pass without human
authorization. Production uses ZombilkaResearch_v1; API-enabled published Studio
uses isolated ZombilkaResearch_Studio_v1 (which CAN persist). Mock is injected only
by external QA; there is no silent game fallback or production default overwrite.

Studio MCP start_stop_play became stuck during one restart. Native documented
StudioTestService:ExecutePlayModeAsync / EndTest restored testing without touching
Experience settings or installing test scripts in Edit. If that recurs, inspect
mode before recovery; do not use RunService.Stop (it can retain simulation changes).

Run only in the connected **ZombilkaFPS** Studio place. The `tests/` folder is
outside the shipping Rojo tree. Never publish these drivers/remotes or install
them into Edit. Stop Play between world-mutating suites. They tune settings or
position targets for mechanics checks; they are not floor1–12 balance runs.

Synchronize disk sources into Edit, then start fresh Play. Wait for RunState.State
`ChoosingWeapon`. Studio `execute_luau` direct `require` can have a different
module cache from game Scripts; install a temporary runtime **Script** to invoke
live Director/BoonEffects functions. A nil Director method in an AssistantCommand
is a QA-context issue, not proof that the running Director failed.

## Server-only suites

Create a temporary Script in ServerScriptService, copy the exact file into Source,
and observe its `Complete`, `Success`, `Error`, `Report` attributes.

- `RunSession.luau`:11 cases/127 assertions, pure ledger, economy and supply-health reset.
- `RewardOffers.luau`:9 cases/2146 assertions, local test folders and temporary
  synchronous stat hooks restored before return. Do not overlap with combat QA.
- `RuntimeRunLifecycle.luau`: install before selecting a gun, click Glock, let the
  real NPC-death/floor driver finish. Covers two transitions, patron claim,
  interlude death and true Floor1/new run. First built floor retains normal quota30;
  later floors use quota3. It accelerates timing and server-kills enemies.
- `RuntimeRunRecovery.luau`: injected map failure/retry; expected warning is labelled
  `EXPECTED QA`. Observe success, then Stop to remove test hooks/tuning.

## Paired suites

Install the server `.luau` as a Script in ServerScriptService, then matching
`.client.luau` as a LocalScript in LocalPlayer.PlayerScripts. Observe both scripts'
attributes; inspect Studio Output. Stop afterwards even when Cleanup succeeded.

- `RuntimeRunFaults`:7 phases — Pending, PreparingFloor, Closing, Moving,
  RewardInterlude, NextFloor, Respawn. The client selects weapons through real remotes.
- `RuntimeWeaponLifecycle`: baseline select/fire/reload/cancel/death during reload
  for Glock/AKM/Mossberg.
- `RuntimeBoonEffects`:27 cases,9 boons×3guns, native emerged zombies, real weapon
  selection/fire/reload remotes. It binds an independent temporary RunSession,
  observes original effect results, and restores methods/configuration in Cleanup.
  Native targets are anchored in a clear lane. Push target releases synchronously
  after actual ray hit, before original handling. Field Protocol tests the actual
  Humanoid/floor-start hook; it does not travel physically once per gun. Healing
  uses one genuine kill, plus a separately labelled scalar clamp check.

## Manual end-to-end / visual checks

Complete real quota combat (or labelled accelerated server NPC-death QA). Inspect
three patron signs before entry; no-jump native paths must reach all3 cabins.
Stand in the Volta cabin, face its back-wall button and hold E. A prompt outside
the camera may not render/respond to virtual keyboard input. Confirm advertised
Volta and three distinct cards, free cursor, no live/pending enemies, blocked fire.
Click exactly one card; duplicate/stale requests must not grant again. Leave the
arrival cabin using W and confirm next combat/cursor lock.

For an isolated layout check, instantiate production RewardSelection with a local
cloned offer state (three catalog cards) and no-op claim remote. Width400 must use
one column and canvas height1546 at the current typography, with card3 reachable
at scrollY800. This is layout QA, not device emulation. Destroy the test GUI and
Stop. Desktop must show three340-high cards in one row with readable values.

Selected-boon integration observed separately: actual Volta route/cabin accepted
by live Director, actual mouse card claim, Floor2 combat, production client Fire
at three native anchored enemies: damage25/10/10 with the original Director-bound
session (no independent Effects.Bind). Then final death: BoonCount0, Build empty,
results retain the previous build. See `results/RoguelikeCoreQA.json`.

After all drivers: Stop; compare the22 changed source files against Edit Source;
fresh normal Play must show validated Office/OpenArena5×5, Floor1, quota30, HP100,
ChoosingWeapon, no NPCs and no QA objects. Check Output, then Stop. Rojo CLI was
unavailable in this session; source equality/native Play replace no CLI build claim.

Milestone4 additions: RewardProbability.luau executes 11cases/121497assertions
with 80k rarity and 50k patron samples plus108scalarcontracts. RuntimeBoonEffects
server accepts TestRarity/TestLevel before parenting (defaultCommon1); Heroic3
native27cases passed. RuntimeRewardRerolls.luau grants QA-only3startingcharges,
awaits liveDirector, then stages actual mouse Glock/reroll/reroll/card; observes
balance3→2→1 and deathreset. RarityRerollQA.json records evidence. Narrow reward
GUI now canvas1546 at400×620; card3fullyvisible at scroll800.


Milestone5: ShopTransactions16cases/247assertions and RunSession11/127; shared
stat hooks restored synchronously. RewardOffers/Probability temporarily disable
merchant chance only within their patron-only harness and restore it afterwards.
RuntimeShopFlow.luau: Script attr Merchant=false(default) drives native30kill
firstfloor, actualGlock/card/E/vendingreroll/Continue/Ereopen/Continue; second
floor actualE/heal, deathreset. AwaitStage beforeclicking. It observes original
Shop.Buy to measure exactheal delta because defaultHumanoid regeneration runs.
Merchant=true forcesChance1/FromFloor1, nativeЗавхозroute+5items; actualContinue
with0purchases, nextcombat/deathreset. Stop removes hooks/timing overrides.
Premium checkouts are isolated service tests; nativeGUI flow does not pretend
to buy230creditgoodswith90credits. EvidenceShopEconomyQA/ShopFinalStartupQA.
For exact source comparison sendJSONDecode(JSON-escaped string): Luau long
bracket literals normalizeCRLF and can create false byte-mismatch reports.
