# Roguelike progression — continuation checkpoint

Date: 2026-10-08. Branch: `dev`. Read `AGENTS.md`, the ENTIRE
`ZOMBILKA_CODEX_MASTER_PROMPT.md`, this file and recent `AI/IMPLEMENTATION.md`
before continuing. No automatic commit/merge/push.

## Initial audit / milestone 0

- Master brief read in full. Source baseline: Office/OpenArena, 25 authored cells,
  180×180; KillQuota, continuous HordeDirector, two physical floor slots.
- FloorDirector owns phase/world transitions. WeaponService owns server ammo and
  raycasts. EncounterProgress counts genuine deaths; requeues are separate.
- Death previously repeated current floor. Ordinary magazine reload lacked a
  character/travel check at completion. CharacterAdded can race map validation.
- AI/PROJECT.md and old PLAN describe obsolete multi-theme/three-wave behavior;
  GAME.md and current source correctly describe v5. Legacy RuntimeArenaV4 tests
  require inactive modes and assert obsolete death behavior; do not run unchanged.
- Available Studio: `ZombilkaFPS.rbxl`, id `ed0be352-88fb-481c-82cc-970dcb8cd198`.
  Baseline fresh Play: ChoosingWeapon, Floor1, HP100, Alive/Pending0; clicking
  Glock card starts EncounterActive and observed Alive4/Pending1 at normal tuning.
  Output empty. MCP key One is rejected by CoreGUI; mouse card works.
- Skills read: roblox-security, roblox-remote-events, roblox-gui,
  roblox-datastores, roblox-performance. Studio rbx-unit-test guidance inspected.
  Advisory examples are not copied blindly. No installs.
- Selective subagents: architecture review/isolated unit suites, reward UI,
  isolated native effect-test pair. Primary owns integration and all Studio tests.
- Pre-existing changes preserved: modified AGENTS.md and ZombilkaFPS.rbxl;
  untracked .claude/, GAME.md, master brief, skills-lock.json.

## Milestones

- [x] 0 Audit and integration plan; baseline Play.
- [x] 1 Run lifecycle, death reset, results and safe new run — Studio gate passed.
- [x] 2 Three physical labeled patron elevators + selection — Studio gate passed.
- [x] 3 Nine real effects for Volta/Bravo/Weiss — Studio gate passed.
- [x] 4 Rarity/levels/rerolls/fairness — Studio gate passed.
- [x] 5 Credits/vending/merchant — Studio gate passed.
- [ ] 6 Research/persistence/meta purchases.
- [ ] 7 Eight patrons/full catalog (unbuilt effects disabled).
- [ ] 8 Legendary/Duo, Electrotoxin first.
- [ ] 9 Polish and normal-length floor1–12 balance QA.

## Integration plan and ownership

Server RunSession holds temporary inventory, epoch, idempotent results and a
pending research ledger; no production DataStore writes until milestone6.
FloorDirector remains the only world/phase owner. WeaponService exposes explicit
action cancellation. Client Results screen integrates existing input/cursor gates.
Then add reward metadata/selection and local elevator frontage without changing
OfficeTiles/FloorLayout/arena topology. Use existing cabin travel and two slots.

## Current tests / blockers

Milestone1 implemented and tested. New RunSession server ledger; death/forced
respawn ends the run once, invalidates epoch, clears temporary state and generates
actual validated Floor1 in the other physical slot. Results + explicit New Run UI.
Failed reset has a RunRecoveryFailed screen/retry, and respawn cannot bypass it.
Weapon actions cancel eagerly on death/travel; magazine reload checks character.

Changed for milestone1: src/server/{RunSession,FloorDirector,WeaponService,
EncounterProgress}.luau; src/client/{RunResults,WeaponSelection,init.client}.luau;
tests/RunSession.luau, RuntimeRunLifecycle.luau, RuntimeRunFaults.luau,
RuntimeRunFaults.client.luau, RuntimeRunRecovery.luau,
RuntimeWeaponLifecycle.luau, RuntimeWeaponLifecycle.client.luau;
tests/results/RunLifecycleQA.json and AI documentation/GAME.md.

Observed Studio: 7 ledger cases/52 assertions; actual ZombieService deaths and
transitions1->2->3, 33 cumulative kills, results floor3/2 clears, new run Floor1;
six cancellation cases Pending/PreparingFloor/Closing/Moving/NextFloor/Respawn;
injected generation failure cannot be bypassed by respawn, explicit retry succeeds;
Glock/AKM/Mossberg actual remote shots, canceled and normal reloads, death during
reload never inserts rounds into replacement character (11/29/5 after new shot).
Results UI visually inspected; cursor Default, weapon selection hidden. Output
clean except the intentionally injected generation-failure warning. Runtime tests
accelerate timings/server-kill NPCs and do not establish normal balance. Two test
harness timing/feedback errors were fixed (deferred Died, Equipped feedback).
Rojo CLI not found; exact Edit source sync used through MCP, build not claimed.

Studio available; no live persistence verified. No production publication allowed.
Keep source on disk authoritative; synchronize exact sources into Edit before Play
and compare source hashes. Test drivers belong under tests/, outside shipping tree.

## Milestones2/3 implemented and verified

Milestones2/3 source integrated and native tests passed. New BoonCatalog,
Patrons, BoonEffects and RewardService; RewardSelection UI integrated. Three
physical bays at X=-18/0/18 in the existing rear lobby, no arena topology change.
Only Volta/Bravo/Weiss enabled, three Common level1–3 boons each. No rarity rolls,
rerolls, shops or permanent persistence yet. Milestone4 is the first incomplete.
All temporary QA/config changes are confined to Play and must be removed by Stop.

### Observed verification

- Native lifecycle test passed: Floor1 -> advertised Volta route -> exactly one
  arc boon -> Floor2 combat with retained build -> Floor3 reward interlude death
  -> actual Floor1/new run. Stale/duplicate claims rejected; 33 genuine NPC deaths.
- RewardOffers:9 cases,2106 assertions,100 seeded three-patron route samples
  passed in Studio. Includes numeric scalars/descriptions, level1–3 upgrades,
  maxed-card removal, explicit supply fallback and transaction invalidation.
- Updated native fault suite passed all7 phases: Pending, PreparingFloor,
  Closing, Moving, RewardInterlude, NextFloor, Respawn. Console empty.
- Native pathfinding with no jumping reached all3 cabins. Actual E prompt chose
  Volta; actual mouse card granted one talent; actual W left the arrival cabin
  and resumed FloorIntro, cursor locked again. Reward menu releases cursor.
- Initial bays at +/-30 failed existing navigation validation at Tile_5_2;
  corrected to +/-18. Door panels now retract vertically so neighbors stay clear.
- Initial reward UI wrapped card3 from fractional grid width; integer cell widths
  fix passed final desktop visual check (three344x340 cards in one row). Native
  AutomaticCanvasSize clipped narrow scrolling; explicit layout content-height
  canvas passed width400 local QA:1378 canvas/1370 content, card3 fully reachable
  at scrollY758. This is not mobile device emulation.
- Actual native weapon/effect matrix passed all27 cases (9boons x3guns): arc10/10
  collateral, headshot stun beyond ordinary.2s reaction, voltage1.01 repeat ratio,
  magazines14/35/7 after genuine reload, salvo1.12x3 then1.0, horizontal push5
  preserving clamped Y, confirmed-kill heal2 and cap, HP25 damage ratio1.15,
  maxHP106/floor-start heal3. Console empty on passing matrix; Cleanup confirmed.
- Matrix uses an independent temporary RunSession and positioned/anchored native
  NPCs. Push releases after real ray hit before original handling; Field Protocol
  invokes the actual production hook on Humanoid, not physical travel per gun.
  First attempts exposed QA readiness/moving-target issues; driver synchronization
  fixed, assertions preserved. See report for exact limits.
- Separate true integration passed: actual Volta cabin/route through live Director,
  actual mouse card claim, Floor2 combat, real client Fire remote ->25 direct and
  10/10 collateral damage with original Director binding. Death clears Build and
  BoonCount. Results retain prior build and patrons. Prior actual E/W input also
  verified prompt selection and physical exit.
- Ledger rerun:7 cases/53 assertions, including supply-health reset. Reward suite
  rerun:9/2106. Results UI with previous boon visually verified.
- Read-only final code review found no new actionable problems. Shotgun targets
  killed by an earlier secondary arc are skipped to prevent duplicate kill hooks.
- Final16 changed source files exactly equal disk/Edit Source. Final fresh normal
  Play: ChoosingWeapon, Floor1, quota30, HP100/max100, Office/OpenArena5x5, validated
  without fallback,123 parts, Alive/Pending0, BoonCount0, QA objects0; Output empty.
  Studio is left stopped in Edit. No .rbxl save, CLI build or Git mutation claimed.

### Files changed for2/3

New: src/shared/{Patrons,BoonCatalog}.luau;
src/server/{BoonEffects,RewardService}.luau; src/client/RewardSelection.luau;
tests/{RewardOffers,RuntimeBoonEffects,RuntimeBoonEffects.client}.luau;
tests/README_ROGUELIKE.md; tests/results/RoguelikeCoreQA.json.
Modified: src/server/{OfficeMap,ElevatorService,FloorDirector,WeaponService,
ZombieService,RunSession}.luau; src/client/{init.client,CombatHud,RunResults}.luau;
tests/{RunSession,RuntimeRunLifecycle,RuntimeRunFaults}.luau;
GAME.md, AI/{PROJECT,IMPLEMENTATION,ROGUELIKE_PROGRESS}.md.
The1st milestone files are listed above. No agents edited the same file at once.

## Milestone4 — implemented and Studio verified (2026-10-08)

- ProgressionConfig/RewardPolicy implement seeded bands60/30/10/0,
  48/33/17/2,40/32/23/5,33/32/28/7 at floors1/3/6/9. Authored per-effect
  Common/Rare/Epic/Heroic level1–3 tables; fixed cooldowns/targets/stack budgets.
  Owned rarity never downgrades on level upgrade. Maxed boons leave normal pool.
- Rare+ guarantee from floor4 after2 Common-only accepted menus. Epic boost from
  floor8 after3 Epic-free menus,5 percentage points per drought step capped20.
  Aggregate exposure across revisions, one commit on acceptance; supplies noop.
- Ordered first4 affiliations; unseen individual weight2 vs known1 beforehand;
  then total group weight .75/.25. Only3live patrons currently, so8-ID simulation
  verifies this policy without enabling missing effects. Duo-specific bias awaits8.
- Rerolls retain stable token and require exact monotonically increasing revision.
  Two/menu,1charge/success, .25s cooldown, generation checked before spending.
  Owner/phase/cabin/alive/epoch/token/revision validated; failed generation, stale
  card, duplicate request, zero balance, dead/no character cannot spend/grant.
  Starting balance0; actual charge sources await5/6. Carry cap3 defined.
- GUI includes rarity colors/numeric descriptions, balance/limit/button/reason,
  pending guard, rarity-aware build. Client waits60s for initial RunRemotes to
  avoid baseline slow-map startup infinite-yield warning. Final startup Output empty.

Observed native Studio tests (tests/results/RarityRerollQA.json):
- Ledger7cases/53assertions; RewardOffers9/2146; RewardProbability11/121497.
  80k band draws within1.5percentage points; floor1/2 noHeroic; primary4first
  draw74.9067%, pre4new85.48% (target85.714%).108rarity/level scalar contracts.
- Native Heroic3 effects:27cases/9boons×3guns using genuine production select,
  fire/reload and original effect results. Arc36/36; repeatdamage1.04;
  magazines18/45/9; postreloadsalvo1.48×3then1; push12/noaddedY;
  killheal8; adrenaline1.6 at25HP; maxHP128/floorheal14; stun .75 observed
  beyond ordinary react and near authored end. Common1matrix passed in milestone3.
- Real Director-bound run: QA-only3startingcharges, accelerated genuine NPC deaths,
  advertisedVolta arrival, actual mouse rerolls balance3→2→1/revisions1→2→3,
  stabletoken, third/stale/duplicate/outside rejected. Real stale remotes sent too.
  Actual card grants1boon; death resetsFloor1/rerolls0/Build empty. Output empty.
- Desktop3cards/cursor/HUD verified. Isolated400×620 production GUI canvas1546,
  third card fully visible at scroll800; disabled reason/count reachable. This is
  layout QA, not mobile-device emulation. Final normal Play ChoosingWeapon,
  Floor1/quota30/HP100/noNPC/noQA/credits0/rerolls0; Output empty. Stopped in Edit.
- QA harness initialization race was fixed by awaiting live Director methods.
  No runtime game defect or unhandled error claimed from that harness failure.

Files: new src/shared/ProgressionConfig.luau, src/server/RewardPolicy.luau,
 tests/RewardProbability.luau, tests/RuntimeRewardRerolls.luau,
 tests/results/RarityRerollQA.json. Updated RunSession/RewardService/BoonCatalog/
 BoonEffects/FloorDirector/RewardSelection/init.client; RewardOffers,
 RuntimeBoonEffects pair and lifecycle/faults drivers (required revision argument).
 No new OfficeMap/FloorLayout/OfficeTiles changes in this milestone.

## Milestone5 — implemented and Studio verified (2026-10-08)

- RunSession.SetFloor keeps per-floor kill-credit ledger. Genuine defeats pay1
  credit up to objective quota; requeues/cleanup pay nothing; completed floors
  stop paying kills. Completion60+6*(floor-1) commits once. Rebinding same floor
  cannot replenish budget. Add/Spend validate currentepoch, finite nonnegative
  integer amounts and sufficient funds. Configured carrycap1,000,000/budgetcap1000;
  clipped grants count only actual earnings. Death resets balance; results retain
  CreditsEarned/CreditsSpent and UI displays both. All prices/tunings inShopCatalog.
- Safe white/blue NORTHLINE vending is a separate ShopWorld transition prop.
  Created only on arrival, inside existing central cabin, X=-5/Z+5.8 relative to
  cabin. No OfficeMap/FloorLayout/OfficeTiles edits in5; hostile coffee spawners
  untouched. Prompt available after boon claim inNextFloor; purchases optional.
  Opening entersShopInterlude, cancels actions, closes doors/anchors root; free
  Continue returnsNextFloor/unanchors after doors; actual next combat observed.
- Vending finite stock: heal35%maxHP65, reroll60/carrycap3, up to+10runHP110
  with combined healthcap60. Full health/caps/funds/sold reasons server-published.
- From cleared floor4, seeded15%chance replaces exactly one of3door routes with
  MerchantShop/Завхоз; two patron routes remain. Arrival branches into shop,
  never a random patron.4–5items, bounded premium assortment (ownedlevel140,
  newRare/Epic230, next rarity260), utility fillers and explicit once-free10HP+
  servermagazinerefill. Merchant is not a patron. Free exit with0purchases works.
- ShopService caches stock byRunId/floor/kind. Reopening gives new token but
  preservesSold/targets; Buy checks owner/phase/cabin/alive/epoch/token/revision,
  live prerequisites and funds. Synchronous debit/grant/Sold/revision; no yields
  or client prices. Rejected requests do not recreate replicated stock. Sold cards
  keep the actually purchased numbers rather than showing a hypothetical next rank.
- ShopSelection has localized prices/stock/reasons, cursor/input/HUD gates and
  fixed freeContinue outside item scroll. TextService measured name/description
  heights prevent premium clipping. CombatHUD shows credits/rerolls.

Observed native Studio (tests/results/ShopEconomyQA.json):
- Ledger11cases/127assertions; ShopTransactions16/247, including actual ledger
  debits, free stock, reopen, caps, stale/dead/owner/NaN inputs, deterministic
  categories and all3compatible premium forms. Fake players/stat hooks explicitly
  isolated/restored; no live Effects rebind. Regression offers9/2146 +policy11/121497
  pass with merchant disabled only in those patron-only test bodies/restored.
- Native realDirector vending flow:30realNPC deaths +floor1 completion=90credits;
  actualVolta card claim; genuine E prompt opens shop; actual GUI reroll90→30,
  charge1. Five real stale purchase packets did not double-spend. Reopen viaE
  retains bought stock/newtoken. Continue then next combat; floor2award69 =>99;
  actual heal65 =>34. Original synchronous checkout observed HP55.005→90.005,
  exactly35 (defaultcharacter regeneration continues outside the checkout).
  Death in shop resetsFloor1/credits0/rerolls0/Buildempty; resultsEarned159/Spent125.
- Native forcedmerchant (test-onlyChance1/FromFloor1): real combat and advertised
  Завхоз route,2patronchoices retained,5serveritems. Actual freeContinue0purchases
  preserves90credits, starts next combat, finaldeathreset; spent0. Native premium
  checkout itself is covered by isolated service tests, not an unaffordable GUI buy.
- Three malicious Fire packets inShopInterlude produce0Shot feedback; freecursor,
  CombatHUD disabled. Desktop merchant5cards readable. Production panel400×620
  uses1column, canvas1626, lastitemfullyreachable, Continue stays visible. This is
  layout QA, not real-device/mobile emulation.
- QA corrections: initial heal assertion assumed no defaultregen; replaced by
  observation around original Buy. One early AssistantCommand inspected vending
  before arrival and failed; commands now await QA stages. StudioAssistant camera
  reset diagnostic is tooling only. No shipping-script error observed.
- Final fresh ordinary Play: ChoosingWeapon, Office/OpenArena5×5, Floor1/quota30,
  HP100/max100, Alive/Pending0, credits/rerolls/boons0, noQA/noarrivalvending;
  Output empty.22changed source scripts exactly equal disk/Edit (JSON transfer
  preserves CRLF; Luau long-string literals normalize newlines and must not be used
  for exact byte comparisons). Stopped in Edit. SeeShopFinalStartupQA.json.
- Scoped git diff --check forsrc/AI/GAME/tests passes. Full-tree check hit locked
  pre-existing ZombilkaFPS.rbxl; no destructive workaround, save or Git mutation.

Files for5: new src/shared/ShopCatalog.luau, src/server/{ShopService,ShopWorld}.luau,
 src/client/ShopSelection.luau, tests/{ShopTransactions,RuntimeShopFlow}.luau,
 tests/results/{ShopEconomyQA,ShopFinalStartupQA}.json. Modified RunSession,
 FloorDirector,RewardService,ElevatorService,init.client,CombatHud,RunResults;
 tests/RunSession and patron regression harnesses; project docs/test guide.

## Limits / remaining work

Milestones0–5 complete. Stop at this tested milestone boundary for the session.
Stage6 NOT started: no research catalog/profile service or DataStore calls exist.
Do not claim DataStore saved/reloaded/rejoined. Stage7 other5patrons/fourordinary
plusLegendaryperpatron,8Legendary/Duo Electrotoxin,9genuinefloor1–12balance pending.
Only3patrons/9ordinaryboons enabled;5othersDisabled. Ordinary levels/rarities exist,
not the full40catalog. Duo-specific patronbias and special pity await8.
No normal floor1–12balance, late-gameFPS, realmobile/co-op verification claimed.
No RojoCLI build, .rbxl save, commit/merge/push/rebase/reset claimed.

## Exact continuation for next session

1. Read this progress first, then ENTIRE master, AGENTS, GAME, recentIMPLEMENTATION
   and gitstatus/diff. Preserve pre-existing user changes. Never inspect oldproject.
2. Start milestone6; preserve working0–5. Review RunSession/FloorDirector start/end,
   RunResults/ShopService/BoonEffects before integrating benefits. Skills reviewed:
   roblox-security/remote-events/gui/datastores/performance; no newinstalls needed.
3. Implement data-driven5researchareas and server-only versioned profile schema,
   conservative migration/corrupt/newer-schema policy, no blank overwrite after
   failed load, bounded retries and serialized UpdateAsync operations. Research
   payout derives from deduplicated real cleared floors, with durable RunId marker;
   no kill-based permanent farm. Profile never stores temporary boons/credits/items.
4. Apply meta only at freshBegin: small maxHP, startingcredits/rerolls, elevator previews/archives as master,
   with existing health/mag/damage caps. Safe research terminal/minimalpre-runUI,
   authoritative costs/caps/owner/alive/state validation. Failed load must visibly
   disable permanent purchases/payout saving rather than silently replacing data.
5. Verify supported save/reload/rejoin honestly. Check actual Studio/place API
   availability before choosing real vs labelled mock evidence. Mockfault/retry/
   migration/dedupe tests alone MUST NOT be described as verified RobloxDataStore.
   Test save+rejoin, repeated death payout, loadfailure/no-write, research purchase,
   disconnect/BindToClose and newrun benefits/tempreset. Do not change CreatorHub
   permissions or publish the place just to manufacture a passing persistence test.
6. Update checkpoint after6gate, then7fiveotherpatrons/fullworkingtalents,8specials
   startingElectrotoxin,9normal1–12runs/balance. No fake active placeholdertalents.
   Test all3guns, per-shotshotgun budgets, secondaryeffectdepth/count caps,
   damage/save/security failure cases and actual mass-effectperformance.
7. QA scripts remain outsideRojo, installonlytemporaryPlay. SeeREADME_ROGUELIKE.
   Use live runtimeScript for Director singleton (AssistantCommand require may use
   anothercache). Stop removes testhooks/config.22sources last matchedEdit exactly.

Suggested prompt:
"Продолжай по ZOMBILKA_CODEX_MASTER_PROMPT.md и AI/ROGUELIKE_PROGRESS.md с этапа6.
Этапы0–5 реализованы и проверены. Реализуй исследования и безопасные профили,
честно проверь сохранение/повторный вход, затем7–9 по ресурсам. Не меняй генерацию,
не делай commit/merge/push и не объявляй mock проверкой реального DataStore."