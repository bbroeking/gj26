# Implementation notes — 58-wayfinding-chart-table

## Decisions

- Kept Chart components and recipes in `data/charts.gd`. The resolver, Affix
  weights, stability preview, cost preview, and inscription now share one
  data authority instead of introducing a second UI-owned recipe model.
- Persisted `known_chart_recipes` during Slice A. Slice C owns discovery UI,
  but landing the save field now gives old saves an explicit migration seam.
- Backfill pre-Slice-A saves with every legacy recipe whose mapped template was
  available at the restored Wayfinding level. A current level-16 save therefore
  retains all six existing template recipes.

## Deviations

- Component items are semantic data only in Slice A. The shipped template
  button acts as an adapter for an already-staged canonical pattern, so no
  placeholder Waymark or Binding is charged before Slice B makes those items
  ownable and visible.
- `returned_on_failure` is present but empty. Returning irreplaceable campaign
  Seals changes shipped trophy consumption and belongs to Slice D, while Slice
  A's gate requires current behavior to remain identical.

## Tradeoffs

- The resolver rejects invalid Ink capacity, unknown Inks, and invalid Seals
  even though the old low-level math helpers tolerate some impossible caller
  inputs. The shipped bench already prevents those states, and centralizing the
  invariant keeps the future grid honest without changing reachable behavior.
- A sealed trophy still guarantees the boss-den **Affix**, whose bad twin may
  be empty, rather than guaranteeing the boss itself. This preserves the live
  game; the stronger authored Boss Chart promise is intentionally Slice D.

## Surprises

- The six-template compatibility set includes Sallow Mire, added by the current
  in-progress first-chapter work, not only the five templates in the earlier
  committed slice.
- The Summit's Alpha Fang is embedded in its base cost and its boss comes from
  the template generation block; it does not use the current trophy socket.
- Godot's JSON parser restores numeric Chart fields as numbers that may compare
  as floats even when authored as integers. Compatibility tests therefore lock
  the legacy key set and cast numeric values through the same runtime contract,
  rather than relying on raw Dictionary equality.

## Followups

- Slice B should replace the legacy-template adapter with owned component
  stacks and the physical grid while retaining the resolver unchanged.
- Slice C should add Unknown / Rumoured / Attemptable / Known presentation and
  use `known_chart_recipes` for discovery rather than level auto-unlocks.

## 2026-07-17 — Slice B council decision

Three Terra audits and a Sol critical pass resolved the physical-table
contract before implementation.

- `Charts` remains the pure domain authority. Slice B adds a canonical
  `{grid, ink_rail}` draft, one preview operation, and deterministic
  `materialize_chart(preview, seed)`. Affix candidates use authored order, not
  Dictionary iteration.
- `Game.try_inscribe_chart` is the only mutation boundary. It re-resolves live
  state, rejects stale/full/unaffordable/re-entrant/guest commits, materializes
  before spending, then commits costs, one Chart, discovery, XP, signals, and
  save exactly once.
- Snug visibly requires one Hedge Ink on the rail and has zero optional
  Affix-bias capacity. The hidden Hedge-Ink base charge is removed so the pot
  is charged once.
- Fresh saves know Snug only and receive Practice Leaf + Hedge Sprig. Missing
  starter supplies recover free until the first Snug clear, preventing a
  zero-gold softlock. The first return grants Field Parchment + Loop Cord + one
  Hedge Sprig once and opens the first Binding cell; level 6 now owns the
  Living Atlas link.
- Bases, Waymarks, and Bindings are renewable through Mara's table supply
  drawer after their lessons, not Hod's counter. Existing Ink vendors stay as
  they are.
- Existing saves receive one idempotent compatibility bundle: for each
  component, the maximum multiplicity required by any known legacy recipe.
  Migration never grants Ink, Seals, trophies, or Relics.
- Successful unknown arrangements become known and award one-time Wayfinding
  XP inside Slice B's atomic commit. Slice C owns rumours, Codex pages, ghost
  staging, and discovery presentation.
- Real focusable Controls provide mouse, keyboard, and controller parity.
  Dragging is deferred; click/select-to-place is the primary verb.
- In active co-op, guests may inspect the table but cannot inscribe. The host
  remains authoritative until shared economy synchronization exists.
- Slice-A Seals continue to guarantee a den Affix, not the boss itself. Boss
  promises, returned relics, and Deepening remain Slice D.
- The existing Wayfinder UI Bible and maple kit are sufficient. No new hero
  mockup is required; component icons use registered deliberate placeholders,
  never font glyphs, until the interaction playtest locks their silhouettes.

## 2026-07-17 — Slice B implementation verification

- Mara's renewable component prices were newly authored from 1–20 gold; the
  contract fixed ownership and supply location but did not prescribe prices.
- The live `NetGame` guest path now covers both guards: the physical table is
  inspectable/read-only, and a forged direct `Game.try_inscribe_chart` call is
  rejected without changing materials or the Chart case.
- The six compatibility recipes do not contain a clean pair that differs by
  only a Waymark or only a Binding. Ink-only identity stability is locked now;
  those two single-axis comparisons should be added alongside future recipes.
- The integrated native gate passes: progression 42, save 53, loop/domain 358,
  Chart Table UI 38, dungeon 26, transitions 109, Skills 62, boot 95, co-op 15,
  and UI/icon 27 (825 total). The save harness deliberately emits corrupt-file
  warnings while testing `.bak` recovery; detached-tree/leak warnings remain
  pre-existing test-harness noise.
- Native captures at 1366×768 verified fresh and staged states. Ink 4 remains
  inside the charting surface, the Binding milestone reads “First Snug
  return,” and the staged preview keeps costs and action visible.
- A release Web export passed its query-gated Chromium smoke: title → Town →
  Snug World → Town, with `[web-smoke] title/town/world/complete` in order,
  HTTP 200 for all requested build resources, and no browser warnings/errors.

### Sol rejection and acceptance round

- The first post-implementation review rejected Slice B because first-return
  components were granted but hidden behind recipe knowledge, controller focus
  could not reach Mix Ink, fingerprints were optional, and the preview omitted
  most Affixes and all good-twin chances.
- Terra separated owned/lesson-stageable components from renewably purchasable
  known-recipe stock, added real controller traversal, made fingerprints
  mandatory, and rendered every authored Affix with roll and stability values.
- Ink experiments now reject Chart components, encounter Seals, and every
  non-Ink template base-cost key at both UI and Game boundaries. The rule is
  derived from authored Chart data, so Alpha's Fang and future story keys cannot
  be consumed by a failed experiment.
- Focused regressions exercise the actual first-return tray → unknown Green
  Hollow → discovery commit path, forged guest commit, fresh repeat preview,
  protected-pot no-loss behavior, and authored-order preview copy. Sol's narrow
  re-review cleared the original P1/P2 findings; the Alpha Fang follow-up was
  fixed and reverified before acceptance.

## 2026-07-17 — Slice C1 council decision

Three Terra audits, a Sol architecture ruling, and a Terra challenge pass split
the next milestone honestly. **C1** ships the Codex foundation and one complete
first-return discovery journey. Full Slice C remains open until at least three
undiscovered recipes have genuine, reachable in-world clues.

- Recipe knowledge has three persistent states: Known, Rumoured, and Unknown.
  Attemptable is transient readiness derived from the current Satchel, required
  Ink, unlocked sockets, and authored recipe data. It is never saved.
- An Unknown recipe whose makings are in hand may show the generic Attemptable
  presentation, but it reveals no title, component identity, quantity, slot,
  pattern, output, cost, topology, or ghost. A Rumoured recipe retains its
  source and may separately show a `Makings in hand` badge.
- All six rumour presentation records are authored and validated in C1. Fresh
  Snug is Known with `mara_lesson` provenance. The first Snug return records
  `mara_first_loop` inside the existing return transaction, alongside its
  supplies and before the existing single save. The remaining four recipes stay
  Unknown until their real Atlas, Mara, or campaign source interactions ship.
- `known_chart_recipes` remains the sole knowledge authority. The optional
  journal is `{rumours: Array[String], discoveries:
  Dictionary[String, String]}` and records only validated rumour IDs plus the
  stable provenance IDs `mara_lesson`, `table_experiment`, and `legacy`.
  Normalization preserves rumour order, deduplicates, retains discoveries only
  for canonical known recipes, and fill-only backfills missing provenance as
  `legacy`. It never promotes knowledge and is idempotent. Neither the save
  version nor Chart Table compatibility version changes.
- Exact ghosts exist only for Known recipes. A ghost click stages one owned
  making without spending it. Leaving the Codex clears only ephemeral ghosts;
  the player's actual staged draft remains.
- Wayfinding 3 Practiced Measures means: **Stage every required making for a
  known Chart at once.** Stage All builds and validates one candidate, then
  assigns it once. It merges without erasing or moving player choices; rejects
  missing or pot-claimed stock, occupied-slot conflicts, locked sockets, Ink
  capacity failures, and guests without changing draft, materials, gold, XP,
  or saves. It never auto-buys, selects optional bias Ink or a Seal, inscribes,
  discovers, grants XP, or spends ingredients.
- Mara's existing Codex toggle owns the left 280-pixel column. It alternates
  between a six-page focusable index and one scrollable detail page with Back;
  index and detail are not shown simultaneously, and the physical grid and
  result preview remain visible.
- C1 acceptance is the truthful vertical slice: fresh Snug Known → first-return
  Green rumour plus makings → redacted readiness → experimental inscription
  → atomic Known plus `table_experiment`, one-time XP, and one save. C2 must
  add at least two more genuine clue sources before full Slice C is accepted.

## 2026-07-17 — Slice C1 implementation verification

- `Charts` owns six presentation records, journal normalization, redaction,
  readiness, and known-only drafts. `known_chart_recipes` remains canonical;
  save migration is additive, fill-only, idempotent, and cannot grant recipes.
- The existing left table column is now either a six-page focusable index or a
  compact detail page with Back. Unknown and Attemptable pages leak no identity
  or pattern; Rumoured pages reveal only their truthful source and clues; Known
  pages show player-facing provenance, exact makings, and pale physical ghosts.
- Individual ghosts and Stage All are inventory-pure. Stage All validates the
  whole merged candidate—including duplicate stock, mixing-pot claims, player
  slot conflicts, locked sockets, Ink capacity, and guest authority—before one
  assignment. Failure is a deep-equal no-op.
- Root visual review corrected internal `legacy` copy to “Earlier working,”
  wrapped long ghost names within their wells, and compacted the detail page so
  Stage All remains fully visible at 1366×768.
- Sol first rejected the stale level-3 perk sentence, then accepted after it
  was replaced with the shipped contract: “Stage every required making for a
  known Chart at once.” No P1/P2 findings remain.
- Integrated native gate: progression 42, save 61, loop 370, Chart Table UI 62,
  dungeon 26, transitions 110, Skills 62, boot 95, co-op 15, UI/icon 27 — 870
  checks/contracts with zero assertion failures. Expected detached-tree and
  resource-leak diagnostics remain test-harness noise.
- The enhanced release Web smoke opens the real Chart Table, presses the real
  Codex Control, verifies all six page Controls, closes the Codex/table, enters
  a generated Snug, and returns to Town. Browser history passed
  `title → town → chart_table → codex → chart_table_closed → world → complete`;
  all requested resources returned HTTP 200 with no warnings/errors.

## 2026-07-17 — Slice C2 council decision

Three Terra audits, a Sol ruling, and a Terra correction pass fixed the full
Slice C source chain before implementation.

- The first successful Tier-1 return unlocks the existing Living Atlas source
  inside the return transaction. Before Wayfinding 6 it offers anticipation
  copy only. At 6, reading its faded panel records `atlas_deep_hollow` and tops
  each Deep lesson component up to one. Deep Hollow keeps its canonical
  Wayfinding 10 requirement; the council rejected an erroneous level-8 reading
  because level 8 is the Seal/Hedgemother lesson in every current authority.
- The first successful, non-abandoned Deep Hollow (`template_id == "hollow"`)
  return unlocks a separate rain-stained note beside Mara's table. Before
  Wayfinding 12 it is anticipation-only. At 12, reading it records
  `mara_sallow_reed` and tops each Sallow lesson component up to one. The note
  is its own Interactable, so first-chapter, Summit, and Second Hand Mara dialog
  priorities remain untouched.
- One Game-owned source API re-resolves eligibility and knowledge live, then
  performs rumour append, missing-only component top-up, table revision,
  signals/toast, and exactly one save. Locked, premature, malformed, repeated,
  or already-known reads are mutation- and save-free. Source reading never
  grants recipe knowledge, XP, Ink, gold, or inscription.
- Source kits contain only the recipe's semantic Base, Waymark, and Binding.
  Hedge Ink stays in the existing gathering/mixing loop. Rumoured components
  are not renewable; successful experimental discovery naturally opens their
  known-recipe drawer stock. The journal rumour is the one-shot claim, so spent
  components can never be replenished by rereading.
- `chart_source_unlocks` is an optional, normalized list of source eligibility
  IDs. It is separate from tutorial hints and from the journal's read record.
  No save or Chart Table version bump occurs. Missing-field migration may
  recover Atlas eligibility from truthful Tier-1 completion, or legacy Green
  entitlement plus Wayfinding 6; it may recover Sallow eligibility from legacy
  Deep entitlement plus Wayfinding 12. An explicitly empty list is respected.
  Recovery never invents a rumour, kit, recipe, XP award, or historical claim.
- Already-known target recipes resolve their source without a kit or redundant
  rumour. Personal source reading remains available to guests; source knowledge
  is not RPC-shared, while inscription remains host-only.
- Controller world interaction is in C2 scope for both sources through the
  existing scanner. The ordinary unused Interactable marker is the unread
  affordance. Codex-wide New badges, counters, restoration UI/XP,
  rumour-gated purchases, Briar/Summit sources, and boss/RNG gates are deferred.
- C2 acceptance requires the playable chain Green clue → Atlas clue/kit → Deep
  experimental discovery → Deep return → rain-note clue/kit → Sallow
  experimental discovery, with all repeats, premature reads, abandoned runs,
  migrations, invalid arrangements, and guest-local reads proven idempotent.

## 2026-07-17 — Slice C2 implementation verification

- `Charts` owns two source records, thresholds, recipes, neutral redacted
  toasts, and component-only missing-to-one lesson kits. `Game` exposes one
  defensive `chart_source_status` / `read_chart_source` API; successful reads
  append one rumour, top up only missing ordinary components, invalidate table
  preview state, signal/toast/save once, and award no XP or recipe knowledge.
- Tier-1 and Deep unlocks join their existing successful-return transactions.
  Abandonment is inert. Optional `chart_source_unlocks` persistence is
  normalized and missing-field-only: explicit empties remain authoritative,
  compatibility recovery invents no rumour, kit, discovery, XP, or version.
- The existing tower parchment is now `AtlasDeepRumourSource`: decorative and
  scanner-inert before a Tier-1 return, anticipatory below Wayfinding 6, then
  rereadable without an unfinished marker. A separate
  `MaraSallowRumourSource` appears only after a completed Deep Hollow,
  anticipates below Wayfinding 12, and never borrows Mara's tutorial, Summit,
  or Second Hand branches. Keyboard E and controller A share the real scanner.
- Native 1366×768 captures cover both eligible source prompts, both real
  `ChartRumourSourceDialog` panels, both read states, and Deep/Sallow Rumoured
  Codex detail with the earned kits. The full capture harness passes all 24
  legacy, Codex, and source routes.
- The fail-closed release driver earns the first Snug return, Wayfinding
  progress, and Wild Herbs through real production channels. It scanner-selects
  both physical sources and the authored Inscribing Table, drives the shipped
  interaction action, mixes Ink, stages both lesson patterns with real Controls,
  commits through `CraftingBench → Game.try_inscribe_chart`, and verifies exact
  costs plus `table_experiment` provenance. It runs the exact committed Deep
  Chart successfully before the rain note can unlock. Chromium passed the
  required ordered subsequence with all ten feature flags and zero console
  errors/warnings. The Web manifest explicitly includes the UI theme; without
  that rule native tests were green while release UI failed.
- Sol's first acceptance review rejected a dishonest Web seam that directly
  inscribed the two experimental Charts. The correction removed that seam and
  exposed a real WF10 Table bug: the newly opened northwest Waymark socket won
  visual-order auto-placement even when no live experiment could use it. Supply
  placement now chooses the first same-kind socket whose candidate remains
  valid; a regression proves Deep Hollow still receives Hedge Sprig in `n`.
  Sol's narrow re-review accepted the correction with no P1/P2 findings.
- Final curated native gate: progression 42, save 71, loop/domain 389, Chart
  Table UI 63, dungeon 26, transitions 130, Skills 62, boot 99, co-op 15, and
  UI/icon 35 — **932 checks/contracts**, zero assertion failures. Expected
  detached-tree/resource-leak diagnostics remain test-harness noise.
- Rapid automated returns exposed an autoload-signal lifecycle bug: a retired
  HUD could receive XP/level callbacks while a pause-immune level-up animation
  unwound. HUD and source connections now have explicit scene-owned teardown;
  the release route is clean under the same rapid transition pressure.

## 2026-07-17 — Slice D council decision

Three Terra audits, a Sol architecture ruling, and a Terra response split the
old combined slice into D1 First Knot and D2 Table Deepening.

- D1 owns one truthful campaign vertical slice. A new pure `CampaignData`
  module owns authored chapter definitions, normalized state, eligibility, and
  transition results; it is not an autoload. `Game` remains the sole mutation
  boundary and `SaveGame` only serializes/restores the optional independently
  versioned `campaign_state`.
- Campaign state records per-chapter clue count/clear, permanent relics and
  restoration entitlements, a monotonic attempt ID, and exact-once Seal escrow.
  Recipe knowledge remains in the Chart Recipe authority. Root Runes are
  permanent referenced relics, never material costs or escrow items.
- Exactly three newly inscribed Green Hollow Charts can bank one missing Thorn
  Whisper each, only on a successful non-abandoned return. The finished Chart
  must carry stable `recipe_id == "green_hollow"` (and a unique Chart instance
  ID); a shared `tier_1` template is insufficient proof. Eligibility is checked
  after completion XP in the same transaction, so a return that raises
  Wayfinding 3→4 may bank the first clue. Extra layers never add extra clues.
- The third Whisper appends the First Knot Boss Chart rumour and tops Thorn
  Essence to one only when none is owned. Before First Knot clear, generic
  elites do not drop Thorn Essence; their seeded replay drop may resume after
  the clear. This replaces the prototype's 25% campaign gate with a bound of
  three successful Green Hollows.
- The distinct Wayfinding-8 Boss Chart uses Field Parchment, Hedge Sprig, Loop
  Cord, visible Hedge Ink, and Thorn Essence in the Seal cell. Its materialized
  `campaign_contract` promises Hedgemother directly; ordinary Affixes may vary
  but no good/bad den twin may remove the boss.
- Inscription spends renewable components/Ink and moves the Seal into a
  persistent attempt escrow: `case → in_run → consumed | refunded`. Terminal
  attempt IDs remain tombstoned so duplicate callbacks/reloads cannot settle
  twice. Player death or party wipe keeps the shipped fight reset and is not
  failure. Explicit pre-victory abandon or load reconciliation of an
  unresumable `in_run` attempt refunds the Seal once; ordinary costs stay spent.
- Boss death is the host-owned atomic clear: consume/clear escrow, mark First
  Knot cleared, grant Tusker Tusk and its Ledger entry, record Green Root Rune
  plus Trophy Hall entitlement, and save once. Exit still owns ordinary run XP
  and debrief. Guest departure is inert; host abandon/session loss follows the
  same escrow rule. Guests render the shared contract but mutate no campaign
  state or rewards.
- Existing Charts remain byte-for-byte playable and campaign-inert, including
  legacy Empty Den memories. Missing campaign state may infer a prior First Knot
  clear only from truthful durable proof (`ledger.slots.tusker_tusk` or the
  existing Summit clear), never from loose Thorn Essence or a sealed Chart.
- D2 is separate. Matching Bindings author one extra layer and a guaranteed
  Hearth before the run; the existing far-Waystone `press_deeper` remains the
  choice to enter an already-authored layer and accept an Omen. Deepening is
  opt-in per recipe and optional for story. Queen's Summit's paired Climbing
  Cords remain its legacy identity in D1; Alpha Fang moves to a Seal cell only
  during a later Queen conversion with migration coverage.

## 2026-07-17 — Slice D1 implementation verification

- `CampaignData` now owns the normalized First Knot chapter contract. Exactly
  three distinct, non-empty Green Hollow Chart instance IDs can bank Thorn
  Whispers; the bounded `banked_chart_ids` tombstones reject replay, forgery,
  and compatibility duplicates. Missing legacy IDs synthesize stable
  tombstones instead of making old clue counts reusable.
- The third valid return grants missing-only Thorn Essence and the Mara rumour.
  The Wayfinding-8 Boss Chart visibly requires Field Parchment, Hedge Sprig,
  Loop Cord, two Hedge Inks, and Thorn Essence in its Seal cell. It publishes a
  canonical Hedgemother contract with no Empty Den twin or ordinary boss RNG.
- Seal escrow is bound to chapter, attempt ID, and Chart instance ID through
  `case -> in_run -> consumed | refunded`. The runtime revalidates the exact
  recipe and campaign contract before publishing a run. Boss death is the
  host-owned, exact-once settlement; return, replay, guest departure, and forged
  callbacks cannot reward or refund again. Abandon/unresumable recovery returns
  the Seal once, while death and a full-party wipe truthfully leave it staked
  for the shipped fight reset.
- Legacy campaign inference is deliberately narrow: a Tusker Tusk Ledger slot
  or the durable Summit clear can recover First Knot completion. Loose Thorn
  Essence, a sealed legacy Chart, and an explicit campaign state remain
  authoritative and cannot invent progress.
- Sol rejected the first implementation for five P1/P2 contract gaps: reusable
  clue Charts, hidden physical Ink, attempt-only escrow, missing Summit
  inference, and misleading refund copy. The corrected pass received ACCEPT
  with no remaining P1/P2 or player-legibility blocker. Independent domain
  gates passed 414 loop checks and 105 save checks.
- Native 1366x768 visual QA covered the real Table and Seal preview. The final
  fail-closed Web journey began from the shipped title and used real Town herb
  patches, physical Table supply Controls, production known-recipe Ink mixing,
  three distinct Green inscriptions and Worlds, the Boss preview/commit, the
  actual Hedgemother death resolver, and the ordinary return. Its ordered
  history ended `boss_world -> boss_cleared -> complete`; the injected probe
  passed with all nine production feature flags and Chromium reported zero
  warnings or errors.
- Browser QA caught two release-only defects that native tests could not see.
  The Web manifest now includes the three new Town buildings with their image
  and normal sidecars, plus the Mara/Hod/Quill rig, texture, and walk assets.
  The D1 driver now recognizes the shipped known-recipe behavior in which the
  third Wild Herb Control auto-mixes Hedge Ink, while still exercising `Try the
  Mix` for an unresolved recipe. The final release measures 116,543,144 B for
  `index.pck`, 37,695,054 B for `index.wasm`, and 115,730,132 B for the PCK at
  gzip -9.
- The broad release gate ran all 28 native `test*.gd` entrypoints with zero
  failures. That pass also corrected two legacy harness/runtime edges: Hearth
  can locate the script-mode scene root after healing/saving, and combatants
  fall back to direct planar pursuit when NavigationServer has no usable path.
  D2 remains the next bounded slice: matching-Binding authored Deepening, not a
  second campaign boss or a replacement for far-Waystone Omens.

## 2026-07-17 — Slice D2 council decision

Three independent Terra interface designs, a Sol ruling, and one Terra
feasibility response converged on a single deep Module. The public Table
interface remains `Charts.preview_table()` and `Charts.materialize_chart()`;
matching, eligibility, costs, final-layer promises, and replay policy stay
inside `Charts`. `Game.try_inscribe_chart()` remains the sole mutation seam,
and `Game.run_cfg() -> DungeonGen.generate()` is only the realization adapter.

- Deepening adds one layer to the recipe template's shipped `max_layers`; it
  never resets a newly Table-authored Hollow or Mire to one layer. Existing
  saved Chart dictionaries remain byte-for-byte authoritative and are never
  recomputed or upgraded from current recipe data.
- At Wayfinding 17, only four exact recipe-owned variants exist: Green Hollow
  repeats Loop Cord, Deep Hollow repeats Hollow Stitch, Briar Maze repeats
  Briar Knot, and Sallow Mire repeats Sunk Knot in the second Binding cell.
  Snug has no variant. The First Knot story Chart is reserved for Deepening II.
  Queen's Summit's paired Climbing Cords remain base recipe identity at every
  level and can never trigger generic equal-Binding behavior.
- A materialized variant freezes `depth_contract` with `variant_id`,
  `base_max_layers`, `max_layers`, `added_layer`, and `hearth_layer`. The Hearth
  belongs on the newly authored terminal layer. Entering it remains the far
  Waystone's separate choice and accepts exactly one visible Omen. DungeonGen
  must treat `rest` as a hard required-room role on that layer and return both
  a `rest` room and its focal `interact_role == "rest"`; best-effort room budget
  is not an honest guarantee.
- Wayfinding 21 ships a real `first_knot_reprise`, not an empty capability.
  It requires a cleared First Knot and the familiar Field Parchment, Hedge
  Sprig, Hedge Ink, Thorn Essence Seal, and matching Loop Cords. It is a
  distinct two-layer recipe: layer one is boss-free; layer two guarantees the
  Hearth and Hedgemother. It carries no campaign contract, clue, attempt,
  escrow, refund, Root Rune, restoration, or first-clear settlement. Thorn
  Essence is an ordinary spent ingredient and is excluded from Affix RNG.
- The reprise freezes an `encounter_contract` naming Hedgemother on layer two,
  `first_knot_heirlooms`, `suppress_chain_trophy == true`, and an
  inscription-time reward seed. The suppression prevents the ordinary
  Hedgemother Tusker Tusk/Ledger callback. On death, one seeded unique is added
  to ordinary boss drops: Whispering Yew (`shortbow`), Coatcap of the Bramble
  (`leather_helm`), Thornwood Longbow (`longbow`), or Bramble Jerkin
  (`leather_chest`). A full pack leaves the pickup on the ground; co-op uses the
  existing per-peer drop event.
- First Knot clear appends the reprise recipe entitlement. Load performs an
  additive, idempotent, fill-only entitlement backfill for already-cleared
  saves. This is not a save-version bump or a Chart migration; already-inscribed
  Charts remain untouched.
- Co-op Deepening is in D2. Only the host/fire-keeper chooses Return or Press
  Deeper while another authored layer remains. On Deepen, the host alone calls
  `Charts.deepen()`, replaces NetGame's authoritative active Chart, and
  broadcasts the entire result for a synchronized scene rebuild. Guests cannot
  force either branch. Return retains the existing party-end flow; voting is
  out of scope.
- Preview copy must name exact total layers, the terminal-layer Hearth, the
  fact that the far Waystone controls entry and adds an Omen, and the
  First-Knot Heirlooms family for the reprise. A doubled Binding below its
  threshold explains the level gate and spends nothing. Four-layer Sallow copy
  must make the longer commitment explicit.

## 2026-07-17 — Slice D2 implementation notes

- The implementation kept the council's two public Chart seams intact. Exact
  recipe matching freezes `depth_contract` and `encounter_contract` at
  inscription; runtime consumes those dictionaries without reopening recipe
  policy or upgrading an existing Chart.
- Dungeon generation reserves the terminal `rest` room before the ordinary
  authored-room budget and rejects/retries any attempt missing either the room
  or its focal `interact_role == "rest"`. This is deliberately fail-closed:
  an advertised Hearth cannot degrade into a best-effort decoration.
- Reprise reward selection happens once on the authority from its frozen seed,
  then co-op broadcasts the same concrete unique item to every peer. Each peer
  receives an independent pickup, so a full pack leaves that player's copy in
  the World rather than rerolling or silently banking it.
- Reprise entitlement repair uses the existing campaign-recovery persistence
  hook. It is fill-only and does not change the save schema. Reward claim state
  is intentionally active-run-only: active runs are not resumable, the Chart
  is consumed before entry, and the claim guard exists only to reject duplicate
  death callbacks before the run returns.
- Resume-in-place for an active Chart remains a separate future slice. D2 does
  not imply active-run save migration or recovery beyond the already-shipped
  campaign Seal escrow rules.
- Sol's implementation review accepted the runtime, co-op, generation, and
  persistence axes but caught one player-legibility defect: materialization
  retained the shared template name `Tier 1 Hollow` for the distinct reprise.
  The narrow correction now copies the authored `First Knot Reprise` name only
  onto newly materialized reprise Charts. Regression coverage asserts both the
  stored name and the Waystone-facing `chart_label`; the corrected review
  received ACCEPT with no remaining P1/P2 findings.

## 2026-07-18 — Slice D2 integrated acceptance

- Sol's corrected implementation review is ACCEPT with no remaining P1/P2.
  Native UI captures cover ordinary Green and Sallow Deepening plus the First
  Knot Reprise (`/tmp/wyrd_ui_deepening_green.png`,
  `/tmp/wyrd_ui_deepening_sallow.png`, and
  `/tmp/wyrd_ui_first_knot_reprise.png`). The Reprise preview names its exact
  inputs, two layers, terminal Hearth, guaranteed Hedgemother, and one seeded
  heirloom without overlapping the Ink rail.
- The query-gated release-Web route passed this exact sequence:
  `title -> town -> d2_prerequisites -> chart_table -> reprise_preview ->`
  `reprise_committed -> reprise_layer_1 -> exit_waystone -> deepen_choice ->`
  `reprise_layer_2 -> terminal_hearth -> reprise_boss_world ->`
  `reprise_boss_cleared -> reprise_return -> complete`. All 11 feature flags
  were present and the accepted session contained 34 log entries with zero
  warnings or errors.
- The fixture is intentionally narrow and explicit. It supplies only the D1
  clear, Wayfinding 21, recipe entitlement, and exact material prerequisites
  already proven by the separate fresh-host D1 route. From the Town Table
  onward it uses shipped scanner interactions, supply Controls, inscription,
  far-Waystone dialogue and **Press deeper** button, terminal Hearth, boss
  death callback, concrete pickup, duplicate-claim rejection, and final Exit
  Waystone. It is not fresh-progression evidence.
- Release-only QA exposed four adapter problems that native contract tests did
  not: the first-time Table lesson could retain modal ownership; paged
  Waystone dialogue required a real input event and stable process/physics
  timing; deferred Town scene change could outrun the driver's final stage;
  and fixture campaign normalization had to happen before the inert-return
  snapshot. Each correction is query-gated or an acceptance-driver ordering
  fix; none shortcuts the production Table or dungeon path.
- All 29 native `test_*.gd` entrypoints then ran serially and exited zero with
  no positive assertion-failure summary. Representative totals are 423 loop,
  133 transitions, 105 save, 62 Skills, and 41 dungeon assertions. Raw logs
  still expose pre-existing Godot shutdown resource-leak diagnostics and test
  fixtures that deliberately exercise parse/tree errors; those are cleanup
  debt, not hidden assertion failures (`/tmp/wyrd-d2-serial-u5ruo9`).
- Release artifacts measure 116,160,380 bytes (`index.pck`) and 37,695,054
  bytes (`index.wasm`); gzip-9 is 115,349,926 and 9,379,534 bytes. The PCK size
  is carried explicitly into the later Web startup/asset profiling milestone.
