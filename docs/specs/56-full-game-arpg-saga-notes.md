# Implementation notes — 56-full-game-arpg-saga

## 2026-07-17 — Milestone 0 council decision

Three Terra audits and a Sol architecture review agreed that the first
production dependency is the four-Trade progression foundation, not Chart
Table Slice B. The table would otherwise bind its UI to the obsolete unified
level model.

### Canonical progression seam

- Runtime and version-2 save keys are `wayfinding`, `earthcraft`,
  `wildcraft`, and `huntcraft`.
- `carto`, `cartography`, `earth`, `wilds`, and `hunt` are read-only migration
  aliases. Runtime mutation with an alias or unknown key is an error.
- A pure progression module owns canonical keys, the level-23 XP contract,
  fresh state, unlock metadata, Skill entitlement rules, and deterministic
  migration helpers. `Game` and `SaveGame` become adapters at this seam during
  the atomic cutover.
- The module interface is also the contract-test surface; callers do not
  reproduce XP, alias, unlock, or migration rules.

### Save migration ruling

- Version 1 `trades.wayfinding.xp` is the authoritative unified lifetime XP.
  Clone it into all four canonical Trades.
- A genuinely pre-version-1 save first performs the historical four-key
  collapse, then clones the resulting unified XP.
- Migrated XP is clamped to `xp_for_level(23) == 4576`; levels are derived
  from XP. This satisfies the no-overflow cap and avoids contradictory saved
  level/XP pairs.
- Version-2 input never reclones or overwrites independent Trade progress.
  Re-running migration must preserve deterministic key and array ordering.
- Recipe backfill runs only after migrated Wayfinding is available. Other
  save fields remain unchanged.

### Skill ownership ruling

- Basic Shot is innate and is not a configurable Focus-Skill entitlement.
- New saves have an empty owned-Focus-Skill set and an empty configurable
  loadout. Power Shot is granted and equipped atomically at its lesson.
- `owned_skills` and the equipped `loadout` are separate persisted concepts.
- Valid persistent Skills in a legacy loadout become owned and retain order.
  Gear-granted Skills remain transient and never enter `owned_skills`.
- In-progress tutorial saves receive any Skill already required by their
  reached lesson. No hidden keybind may cast an unowned Skill.

### Delivery gates

1. **0A — pure contract:** add the progression module and focused contract
   tests without changing live saves or bumping the save version.
2. **0B — atomic cutover:** bump to v2; change `Game`, `SaveGame`, XP call
   sites, perk ownership, pack growth, Skill ownership/loadout behavior, UI,
   and migration tests together. Pack growth remains owned by Wayfinding to
   preserve the shipped exploration cadence.
3. **0C — presentation:** update the Trades/loadout presentation, then build
   Chart Table Slice B against the stable progression interface.

All six canonical suites, the UI/icon contract, the new progression contract,
and fresh-save onboarding must be green before Slice B integrates.

### Milestone 0A verification

- `wyrd/data/progression.gd` now owns the pure seam described above.
- All four 1–23 ladders contain a validated unlock cell: 92 total.
- Migration and Skill-entitlement adversarial cases pass: v2 loadouts cannot
  grant ownership, configurable loadouts stay at three, gear Skills remain
  transient, and future save versions are never downgraded.
- `test_progression_contract.gd`: 38 passed, 0 failed.
- `test_boot_smoke.gd`: 94 passed, 0 failed.

### Milestone 0B verification

- Save schema v2 restores exactly four independent, XP-authoritative Trade
  records. Version-1 Wayfinding XP clones once; pre-v1 synonyms cannot
  double-count; a future-version primary never falls back to a stale v2 backup.
- Basic Shot is innate. Implemented Focus Skills become durable entitlements
  when taught, while the configurable loadout remains zero to three entries.
  The first-return Power Shot is built and cast-tested at Huntcraft 1, so its
  tutorial grant is not re-gated by the normal level threshold.
- Gear Skills remain transient. With a full permanent bar, a gear Skill
  temporarily displaces the last runtime action and removal restores the saved
  loadout without mutating ownership.
- Driving Volley, Threadstep, and Wayfinder's Mark remain planned level-18/20/22
  unlock labels. They cannot be persisted, equipped, or cast until factory,
  UI, behavior, and tests arrive together.
- The mastery-choice seam is intentionally dormant: every currently authored
  Trade tier has one automatic perk. No UI or roadmap claim treats a choice as
  shipped before a real multi-option tier is designed.
- Sol's critical pass found the tutorial re-gate, future-save fallback, ghost
  late Skills, and full-bar gear displacement despite an initially green gate;
  Terra owners repaired them and expanded behavior coverage before acceptance.
- Final integrated gate: progression 42, save 40, loop 323, dungeon 26,
  transitions 107, Skills 62, boot 94, co-op 15, plus the UI/icon contract —
  all passed with zero assertion failures.

### Milestone 0C verification

- Chart Table Slice B now consumes the stable four-Trade interface: a physical
  3×3 component grid and separate Ink rail resolve through pure Chart data,
  while `Game.try_inscribe_chart` is the sole host-authoritative mutation seam.
- Fresh onboarding, first-return Green Hollow discovery, controller traversal,
  mandatory live fingerprints, protected story keys, complete Affix odds, and
  Web export transitions are covered end to end.
- Final integrated gate: progression 42, save 53, loop 358, Chart Table UI 38,
  dungeon 26, transitions 109, Skills 62, boot 95, co-op 15, UI/icon 27 — 825
  checks/contracts with zero assertion failures.

### Chart Table Slice C1 verification

- Mara's contextual Codex now separates durable Known/Rumoured/Unknown
  knowledge from transient, fully redacted Attemptable readiness. The first
  Snug return records Green Hollow's rumour in the same save transaction as its
  lesson supplies; experimental inscription remains the only discovery commit.
- Known pages project non-consuming ghosts onto the physical table. Wayfinding
  3 Practiced Measures stages one fully validated candidate without buying,
  spending, selecting optional Ink or a Seal, or inscribing. Guests can read
  personal pages but cannot mutate the table.
- Final integrated gate: progression 42, save 61, loop 370, Chart Table UI 62,
  dungeon 26, transitions 110, Skills 62, boot 95, co-op 15, UI/icon 27 — 870
  checks/contracts with zero assertion failures.
- Native 1366×768 captures cover the index, Rumoured, Attemptable, Known ghost,
  Stage All success/failure, and guest states. The release Web route passed
  `title → town → chart_table → codex → chart_table_closed → world → complete`
  with every requested resource at HTTP 200 and no browser warnings/errors.
- This is C1, not full Slice C. C2 remains gated on two additional genuine
  clue-source interactions; later authored recipes remain Unknown until then.

### Chart Table Slice C2 verification

- Completed Tier-1 and Deep Charts now reveal two separate physical clue
  sources. The Living Atlas teaches the Deep Hollow rumour at Wayfinding 6;
  Mara's rain-stained note teaches Sallow Mire at 12. Each source is
  anticipatory below its threshold and pays one missing-only component lesson,
  never Ink, XP, or recipe knowledge.
- Deep remains gated at Wayfinding 10. Both lesson arrangements pass through
  the existing atomic experimental-inscription transaction; successful
  discovery makes their ordinary components renewable through Mara's drawer.
- Optional source-unlock migration is additive, idempotent, and explicit-empty
  safe. Abandoned runs, premature/repeat/already-known reads, invalid layouts,
  and guest-local reads are mutation-safe.
- Final integrated gate: progression 42, save 71, loop 389, Chart Table UI 63,
  dungeon 26, transitions 130, Skills 62, boot 99, co-op 15, UI/icon 35 — 932
  checks/contracts with zero assertion failures. Native capture passes 24
  routes; the fail-closed C2 release journey passes through first Snug return,
  production gathering, both real world sources, both real dialogs, both
  Rumoured Codex pages, two physical Table experiments, and the exact committed
  Deep return, with all feature evidence, the exported UI theme, and no browser
  console errors/warnings. Sol accepted the correction after rejecting the
  earlier direct-inscription Web seam.

## 2026-07-18 — Level 1–17 re-ladder council: First Knot Homecoming

Three Terra audits reconciled spec 56 with the live build after Chart Table D2.
The four-Trade, material, crafting, Skill, biome, and legacy boss mechanics are
substantive through level 17, but only First Knot is a campaign-stateful
chapter. Levels 9–17 still use the earlier trophy/Affix chain: they do not yet
have bounded clue ledgers, deterministic Boss Charts, Root Runes, or visible
town restorations. Most immediately, D1 already records `trophy_hall` and the
Green Root Rune exact-once, yet Town projects neither.

Sol accepted **First Knot Homecoming** as the next bounded playable slice and
rejected premature multi-chapter generalization. Terra's feasibility response
agreed. The final seam is:

- `CampaignData` owns one pure, authoritative Homecoming view derived from
  normalized campaign truth and an explicit read-only inspection context.
  Town, the Living Atlas, dialogue, and networking must not independently infer
  clear, relic, restoration, legacy, guest, or Reprise rules.
- The view is presentation-only. Entering Town, hosting, joining, inspecting,
  reconnecting, and acknowledging the debrief cannot mint rewards, repair or
  rewrite persistence, consume Tusker Tusk, or mutate host/guest campaign
  state. The First Knot clear is the durable Tusk display record; no second
  inventory item or progression counter is introduced.
- The host's normalized view is authoritative in a shared Town. Guests may see
  and inspect that projection but earn no local unlock, journal progress,
  inventory, recipe, or save write. D2 Reprise is explicitly ineligible to
  trigger the Homecoming view or debrief.
- Legacy-inferred First Knot clear may reveal the corresponding display only
  from already-normalized truthful state. Projection never synthesizes missing
  rewards or writes inferred facts back to disk.
- The compact yard-side Hall opens one Green Root Rune alcove, one
  non-consumable Tusker record, and an unnamed, covered, mechanically inert old
  bow-rest. The Living Atlas consumes the same projection to paint a wet-road
  handoff toward Sallow. One brief, warm debrief is locally presentation-gated
  by a stable event key without changing campaign truth.
- Golden Wallow remains the next larger vertical slice. That is when the shared
  multi-chapter descriptor, Gilt Bristles ledger, deterministic Boar contract,
  escrow, Mist Root Rune, and Sallow Jetty earn their second-use abstraction.

Homecoming acceptance requires a fresh/cleared/legacy/host/guest/Reprise view
matrix; zero campaign mutation from every inspection and debrief path; visible
Town and Atlas changes after the canonical First Knot callback; persistence and
duplicate-callback regressions; native visual capture; a release-Web route; and
no new runtime diagnostics. Existing legacy Boar/Wolf/Summit encounters remain
playable but must not claim Root Saga completion.

## 2026-07-18 — First Knot Homecoming implementation and acceptance

The council seam shipped without introducing the premature generalized chapter
framework. `CampaignData.first_knot_homecoming_view(state, context)` is the one
pure authority for canonical, normalized legacy, host, guest, and Reprise
presentation. `Game` adapts it, `NetGame` publishes the host snapshot and fails
closed immediately on join/server loss, and Town consumes it idempotently. A
Reprise return keeps the permanent Hall/Atlas record and suppresses only the
one-shot debrief. The completed and abandoned-Reprise cases both key from the
active recipe identity, so neither can masquerade as a first Homecoming.

Town now projects exactly one compact yard-side Hall with a Green Root Rune,
non-consumable Tusker record, and draped mechanically inert bow-rest. The same
view paints `WET ROAD → SALLOW'S END` into the Living Atlas. The warm debrief
waits behind the ordinary return modal, is presentation-only for the local
session, and never changes campaign or materials. Hall inspection is one
controller-parity interaction verb and opens acknowledgement copy only.

Sol's first review caught the abandoned-Reprise identity edge and accepted the
correction with no remaining P1/P2 findings. Independent Terra QA first caught
the late-join projection/debrief race; the final implementation revokes the
stale local view and any open unauthorized debrief synchronously. Terra then
accepted the domain, presentation, network, and visual contract. Dedicated
native captures are `/tmp/wyrd_homecoming_hall_v4.png` and
`/tmp/wyrd_homecoming_atlas_v4.png`; the Hall silhouette, draped rest, and Atlas
wet-road mark are readable in their authored camera frames.

The release-Web proof ran from a clean origin and passed:

`title → town → world → green_world_1 → green_hollow_1 → green_world_2 →`
`green_hollow_2 → green_world_3 → green_hollow_3 → chart_table →`
`boss_preview → boss_world → boss_cleared → homecoming_hall →`
`homecoming_atlas → homecoming_inspected → complete`.

All 14 fail-closed feature flags were present. The accepted browser session had
74 entries and 0 warnings/errors. Preserved artifacts in
`wyrd/build/web-homecoming-qa` measure 116,179,344 bytes (PCK), 37,695,054
bytes (WASM), and 5,890 bytes (HTML); gzip sizes are 115,368,591 and 9,435,036
bytes for PCK/WASM. The full serial native gate passed all 31 `test_*.gd`
entrypoints (`/tmp/wyrd-homecoming-final-serial-1784356567`). During that gate,
an existing 4% super-crit made the execute-ring test probabilistic; the test now
uses the combatant's existing crit-disable seam, leaving the documented
super-crit runtime contract unchanged, and passed ten consecutive focused runs.

The next council/implementation slice is **Golden Wallow**: the first new
deterministic chapter and the justified second use for a shared chapter
descriptor, with Gilt Bristles clues, Boar Boss Chart/escrow, Mist Root Rune,
and Sallow Jetty restoration kept in one bounded vertical slice.

## 2026-07-18 — Golden Wallow implementation council

Two independent Terra audits reconciled the level-9–12 saga promise with the
live project. Sallow Mire already has a complete biome package, native
Mothmint, a physical level-12 Chart recipe/source, and the Burrow Boar's charge
moveset and model. It does **not** yet have campaign truth for Gilt Bristles,
Mire Ink, the Golden Wallow Boss Chart, Mist Root Rune, or Sallow Jetty. The
existing legacy `burrow_boar_den`/Wightpelt chain remains playable and cannot
prove or settle the authored chapter.

The council locked this bounded contract:

- Add `golden_wallow` as the second data-authored campaign chapter, not a new
  general quest framework. Generalize the proven descriptor, normalization,
  clue ledger, Boss Chart contract, escrow, settlement, and projection seams
  only as far as two real chapters require. First Knot migration and behavior
  remain byte-for-byte compatible at their public boundaries.
- Do not call the clue route “Gilded Hollow”; that is already the player-facing
  name of the `gilded` Affix. `sallow_shallows` / **Sallow Shallows** is a short,
  one-layer level-9 Mire Chart using the shipped bog art, enemies, room grammar,
  and native Mothmint. Its exact level-9-valid Table pattern is Mire Reed north,
  Field Parchment centre, Loop Cord west, plus one Hedge Ink. The post-First-
  Knot Atlas handoff grants its Rumour and one missing-only component lesson;
  experimental Table inscription remains the discovery commit.
- Only a successful, non-abandoned, host-authoritative final return from a
  distinct, non-empty `sallow_shallows` Chart instance banks the next Gilt
  Bristle. One Chart can bank at most once; side-prop reading is copy-only; the
  ledger caps at three. This gives levels 9–11 a real Mire campaign spine while
  the existing full `sallow_mire` remains the level-12 destination.
- Add renewable **Mire Ink** at Wildcraft 10. The physical experiment uses one
  fixed-Town Bittergrass, one native-Shallows Mothmint, and one Hedge Ink. Its
  source and Boss preview explicitly name the Wildcraft-10 dependency; no Ink
  or Trade XP is silently injected. Both required herbs are deterministic in
  the authored world package.
- `golden_wallow_boss` / **Burrow Boar's Wallow** is a level-12 physical Chart
  using the existing Sallow pattern (Mire Reed north, Waxed Vellum centre, Sunk
  Knot west), Mire Ink on the rail, and Tusker Tusk in the level-8 Seal socket.
  Its immutable campaign contract always builds `burrow_boar`; an ordinary or
  bad Affix can never turn that guarantee into an Empty Wallow.
- Reuse the proven physical-Story-Seal escrow: Tusker Tusk moves through
  `case → in_run → consumed|refunded`; Mire Ink is an ordinary inscription
  cost. At Bristle III the transition targets one missing Tusker only when the
  prior chapter key is absent. A pure generalized `seal_use_allowed` authority
  must drive preview, staging copy, host commit recheck, and direct compatibility
  adapters so a pending Thorn Essence/Tusker cannot be spent on the wrong newly
  committed legacy Chart. This closes the soft-lock without adding a second
  persisted “ready reservation” state. Already materialized legacy Charts are
  grandfathered and remain campaign-inert.
- First clear settles once: Wightpelt, Mist Root Rune, and Sallow Jetty. Do not
  ship Wallow-Treader Boots or fishing in this slice. Campaign-awarded Wightpelt
  is protected for the future Seventh Road rather than spendable in a newly
  committed legacy Wolf Chart; it is never silently reminted after settlement.
  No loose Tusk, Wightpelt, old Boar kill, or Ledger slot may infer Golden clear.
- Generalize the read-only settlement projection and host snapshot. The host
  publishes on join/Town/settlement; guests render Hall/Jetty truth read-only,
  never persist it, and clear it synchronously on join loss/session end. The
  Jetty's bounded verb launches a held Mire Chart; full fishing remains later.

Acceptance must cover pre-Golden First Knot saves, fresh/uncleared/eligible/
three-clue/cleared states, exact distinct Chart IDs, wrong/repeated/abandoned
returns, visible Wildcraft gating, preview/commit Seal routing, one open escrow,
case/in-run/refund/crash tombstones, forced Boar contract, legacy Boar inertia,
duplicate death, exact-one awards, save normalization, host/guest reconnect,
copy-only Hall/Jetty inspection, native visual capture, and a clean release-Web
route from First Knot Homecoming through three Shallows, the Wallow, and Jetty.

## 2026-07-18 — Golden Wallow implementation and acceptance

The bounded chapter is shipped. `CampaignData` now owns a real second chapter
descriptor and generalized clue, Boss Chart, Story-Seal, settlement, and
projection authorities while preserving the First Knot public behavior. Three
distinct successful Sallow Shallows returns bank Gilt Bristles; wrong,
repeated, abandoned, empty-ID, guest, and legacy Boar paths remain inert. The
third clue supplies only a missing Tusker Tusk. The physical Table discovers
Mire Ink at Wildcraft 10 from Bittergrass, Mothmint, and Hedge Ink, then commits
Burrow Boar's Wallow with the Tusk held through the proven escrow lifecycle.
The immutable World contract produces the Burrow Boar and its real death
callback settles Wightpelt, Mist Root Rune, and Sallow Jetty exactly once.

Town and co-op presentation consume the shared read-only projection. The
Trophy Hall and Living Atlas record the Golden return, while the restored
Jetty exposes its bounded held-Mire-Chart launch verb. Guest state is host
published, never saved locally, and synchronously revoked on session loss.
The Jetty uses the new authored low-poly asset
`models/building_sallow_jetty_v1.glb`; its reproducible Blender source is
`models/scripts/build_sallow_jetty_v1.py`. Native and in-game review confirmed
the dock, mast, lantern, mooring, and folded wet-road Chart read as a single
settlement landmark. Sol's integrated review accepted the corrected result
with no P1/P2 findings.

The release-Web gate starts only after an explicit accepted First Knot fixture
and then uses real scanner, Atlas, Chart Table, Mix, World, boss-death, and
settlement paths. The accepted R4 run completed:

`title → town → first_knot_homecoming → shallows_source →`
`shallows_table_1 → shallows_world_1 → shallows_return_1 →`
`shallows_table_2 → shallows_world_2 → shallows_return_2 →`
`shallows_table_3 → shallows_world_3 → shallows_return_3 → mire_ink →`
`boar_preview → boar_world → boar_cleared → golden_hall → golden_atlas →`
`sallow_jetty → complete`.

All 13 fail-closed production feature flags were present and the browser log
contained zero warnings/errors. Browser QA found and fixed two release-only
integration gaps: the Web export manifest now includes the Jetty GLB, and the
Mix pantry now exposes an owned Ink only when an authored recipe consumes it
as an ingredient (required by Mire Ink) while continuing to hide protected
Chart supplies. A slightly longer query-only World dwell also avoids tearing
down the compatibility renderer during its first reflection-probe step.

The preserved artifact is `wyrd/build/web-golden-qa-r4`: 116,598,040-byte
PCK, 37,695,054-byte WASM, and 5,892-byte HTML. The semantic probe validator,
boot smoke (103/103 scripts), `git diff --check`, focused Table contract, and
all 36 serial native `test_*.gd` entrypoints passed. Full logs are at
`/tmp/wyrd-golden-final-1784360554`. The next council slice is the Seventh
Road; Golden Wallow is closed and must remain its regression floor.

## 2026-07-18 — Seventh Road implementation council decision

Three Terra audits and a Sol architecture review resolved the next bounded
slice. The implementation is **the authored Wolf-only Seventh Road chapter**,
not the whole narrative Chapter III. Queen's Summit remains the following
authored campaign slice, but this release must include a narrow, persistent,
non-campaign Summit handoff so the one canonical Alpha Fang can never be lost
to ordinary abandon or crash behavior.

The locked progression is preparation at level 13, Wildcraft-14 Mothglow Ink,
then the shipped Wayfinding-15 Briar Maze. Do not lower Briar or invent a
temporary survey Chart. A real Living Atlas source grants a missing-only Briar
lesson; physical Table experimentation remains discovery. Four distinct,
successful, host-authoritative Briar returns bank four ledger-only Cold Tracks.
They use `seventh_road_cold_track_1…4` and a `cold_track_clue` presentation
family; they are never confused with the existing physical `cold_track`
Waymark used by Summit.

The exact Boss Table is Thorn Rubbing north, Stitched Parchment centre, Briar
Knot west, Mothglow Ink on the rail, and Wightpelt in the Seal. It resolves
`seventh_road_boss` / **Wolf Alpha's Seventh Road**, requires Wayfinding 15 and
Wildcraft 14, and freezes `wolf_alpha` into its campaign contract. First clear
settles exactly one Alpha Fang, Fang Root Rune, and a visible first-stage Skald
Archive. The Archive is a bounded Town Interactable that reviews completed saga
clues and, at Wayfinding 16, provides the missing-only legacy Summit lesson.
Full clue-targeting Ink behavior waits until a later Archive upgrade.

Mothglow gains its missing Wildcraft-14 mix gate without deleting prior
discovery or owned bottles. Old bottles remain ordinary usable Ink, but the
Wolf Boss commit still requires current Wildcraft 14. Locked mixes spend
nothing. Additive campaign-state migration adds an empty `seventh_road`
chapter, Fang Root Rune, and Skald Archive without inferring truth from loose
Wightpelt, Alpha Fang, Ledger slots, legacy Wolf death, `summit_cleared`, or old
Charts.

Newly committed `queens_summit` Charts move Alpha Fang from an ordinary base
cost into the visible Seal and carry a single immutable
`legacy_summit_handoff` contract. Its persistent tombstone lifecycle is
`case → in_run → consumed|refunded`: pre-Queen abandon and unresumable reload
refund once; Queen death consumes once; party wipe retains `in_run`. It never
mints a clue, Root Rune, restoration, Oath Nail, debrief, or campaign clear.
Existing materialized Summit Charts remain byte-for-byte playable and
campaign-inert. This requires an explicit non-Affix protected-Seal rule and an
escrow policy that recognizes both campaign contracts and this one named
handoff contract; it must not become a generic escrow framework.

Host authority remains the sole mutation/save seam. Guests receive the shared
read-only settlement projection, cannot read sources for rewards, and lose
Hall/Atlas/Archive truth synchronously on disconnect. Acceptance is the Golden
regression floor plus focused campaign/content/runtime/presentation/co-op/save
tests and a clean release-Web route through four Briars, Mothglow, forced Wolf,
Archive, Summit Alpha refund, retry, and Queen handoff consumption. No authored
Queen settlement, Crown-Thorns, Crown Root Rune, Oath Nail, final stair,
Glintband, new biome/enemy, generic quest framework, or universal Town presenter
belongs to this slice.

## 2026-07-18 — Seventh Road implementation and acceptance

The bounded Wolf chapter is shipped. Four distinct successful Briar Maze
returns now carry host-frozen `seventh_road_cold_track_1…4` records, and their
runtime props consume the four authored titles and page sets rather than one
generic Cold Track dialog. Mothglow is a real Wildcraft-14 experiment, and the
Wolf Boss recipe enforces current Wildcraft 14 independently at Codex readiness,
Table resolution, and host commit—even when an old Mothglow bottle is owned.
Wolf Alpha's Seventh Road freezes its guaranteed Wolf contract and moves the
one Wightpelt through durable case/in-run/consumed-or-refunded escrow.

The canonical Wolf death settles Alpha Fang to exactly one physical Story Seal,
adds Fang Root Rune, and restores the live Skald Archive exactly once. The
Archive provides a missing-only Queen's Summit lesson through the ordinary
source transaction. Guests can inspect host-projected Hall, Atlas, and Archive
truth but cannot mutate a local source journal, receive its supplies, or save
campaign progress. NetGame receives the host's materialized Cold Track record
inside the Chart, so a guest with a divergent local ledger generates the same
authored World.

New Summit Charts expose Alpha Fang as a real selectable Table Supply and retain
the deliberately campaign-inert `legacy_summit_handoff`. Abandon and
unresumable recovery refund it once; Queen death consumes it once. Recovery now
writes the reconciled backup before the primary, closing the corrupt-primary
fallback replay that could otherwise remint a refunded Story Seal. Existing
materialized Summit Charts remain inert.

Sol accepted the integrated result after the review blockers above were fixed,
with no remaining P1/P2 findings. All 41 native `test_*.gd` entrypoints passed;
the focused post-review floor includes boot 104/104, loop 424/424, dungeon
41/41, transitions 133/133, Skills 62/62, save 111/111, campaign 19/19,
content 11/11, runtime 9/9, co-op 9/9, presentation 8/8, and the Chart Table UI
contract. The post-review release-Web export then passed all 32 D4 phases and
all 20 required production flags in Chromium, using the real literal-E abandon
control between its two Summit attempts. Its artifacts measured 116,636,580
bytes PCK, 37,695,054 bytes WASM, and 5,890 bytes HTML.

The next bounded council slice is the authored **Queen's Summit** settlement:
Shed Crown-Thorns, a campaign-bearing Summit contract, Crown Root Rune, Oath
Nail, and the final stair. It must migrate the safe handoff forward without
double-escrowing old Charts or inferring Queen truth from the D4 handoff.

## 2026-07-18 — Queen's Summit implementation council decision

Three Terra audits and Sol's final architecture review locked a compatibility-
safe two-road chapter. The shipped `queens_summit` recipe and
`legacy_summit_handoff` are retired from every new Table commit but remain
byte-for-byte runtime-valid for already-materialized Charts and open escrow.
They stay campaign-inert forever; no old Queen death, `summit_cleared`, loose
Alpha Fang, legacy Chart, or handoff phase may imply Crown-Thorns, Queen clear,
Oath Nail, Crown Root Rune, or Pale Stair.

At Wayfinding 16, `summit_approach` / **Crownward Ascent** is the clue road. Its
exact physical Table is Cold Track northwest and north, Atlas Folio centre,
Climbing Cord west and east, and one visible Refined Ink on the rail. It has no
Seal and outputs a distinct boss-free Summit template; it never inherits the
legacy Summit template's baked Queen. Four distinct successful,
non-abandoned, host-authoritative returns bank ledger-only
`shed_crown_thorn_1…4` using the `shed_crown_thorn` presentation family.
Reading their authored icy-thorn props is copy-only.

At Wayfinding 17, `queens_summit_boss` / **Queen's Summit** is the chapter
road. Its exact Table is Cold Track northwest, Thorn Rubbing north, Atlas Folio
centre, Climbing Cord west and east, one visible Refined Ink, and Alpha Fang in
the Seal. Its distinct template also has no baked boss; only its immutable
campaign contract forces `hedgemother_queen`. Both new templates carry four
Hedge Ink as ordinary base cost and charge Refined Ink exactly once from the
visible rail.

The new campaign chapter is an additive v3 record requiring Seventh Road clear.
Alpha Fang becomes protected for `queens_summit_boss`; any open legacy handoff
blocks a concurrent Queen escrow, while its frozen Chart continues through the
old lifecycle. New Queen escrow uses `case → in_run → consumed|refunded`, with
only Alpha Fang protected on abandon/recovery. Refined Ink and ordinary
components stay spent. A single persistent
`legacy_summit_alpha_fang_credit` repairs the one upgrade hard-lock: during
v2→v3 recovery, a consumed legacy handoff tops a missing Fang to exactly one,
then marks the credit regardless. Case, in-run, refunded, or merely old Summit
records never qualify. Recovery persists the reconciled marker and inventory
through both primary and backup before play resumes.

Canonical Queen death settles exactly one Oath Nail, Crown Root Rune, and
`pale_stair`. Oath Nail is a protected Story Seal reserved for the future
`pale_oath_boss`; it is not refilled after later spending. The Trophy Hall,
Living Atlas, and Skald Archive consume the shared host projection. Guests are
copy-only and lose the projection synchronously on disconnect. One new static
asset, `models/landmark_rootroad_stair_v1.glb`, reveals in the canonical Queen
arena: a snow-crusted root-and-stone stair with pale light below. Its repeated
inspection names the Pale Oath but never traverses or loads level-18 content.

D5 acceptance must cover additive migration and one-time Fang credit, every old
legacy Chart/escrow phase, cross-contract exclusion, four exact Approach
returns, physical Table/Codex recipes, forced Queen contract, abandon/recovery/
retry/death idempotence, exact Oath/Rune/Stair settlement, save fallback, host/
guest projection, native visual capture, all existing regressions, and a clean
release-Web journey from post-Seventh Archive lesson through four Approaches,
Queen escrow/death, the stair read twice, and Hall/Atlas/Archive settlement.
The old D4 route must use a frozen legacy Chart rather than committing the
retired recipe. Crownward Jerkin, Glintband, and Pale Oath gameplay remain out
of slice.

## 2026-07-18 — Queen's Summit implementation and acceptance

The two-road chapter now ships end to end. Campaign state is v3 with exact
legacy-Fang migration; Crownward Ascent banks four authored Shed Crown-Thorns;
the physical Queen Table places Alpha Fang in the south Seal cell and Refined
Ink on its rail; and only the materialized campaign contract forces the
Hedgemother Queen. Her canonical death consumes the escrow once and settles
exactly one Oath Nail, Crown Root Rune, and Pale Stair. Hall, Atlas, Archive,
save fallback, and host/guest projection all consume the same authority-owned
truth. The static Stair GLB is reproducible from its checked-in Blender script,
copy-only on repeated inspection, and explicitly included in the Web export.

Real release-Web play caught three integration defects that native contract
tests alone could not see. D4 was still calling the now-retired legacy begin
API instead of installing its disclosed frozen v2 cases; D5's smoke assertion
forgot the Queen recipe's south Seal cell; and the new Stair GLB was absent
from the explicit Web include filter. The corrected compatibility route now
installs two exact persisted case records without reopening legacy inscription.
The World boss-death adapter consumes the authoritative changed transition and
owns arena-local Stair presentation, while the export contract and Queen world
test pin the GLB in the PCK. Browser runtime errors are an acceptance failure,
not merely a console warning.

The strengthened final gate rejects Godot's occasional false-zero exit by
scanning every log for script/load errors and nonzero failed summaries. All 47
native entrypoints passed. The focused Queen suites passed campaign 11/11,
content 9/9, runtime 5/5, co-op 6/6, presentation 7/7, and world 9/9; save
roundtrip remains 117/117 and the complete loop 424/424. The final Web PCK
audit contains both `res://models/landmark_rootroad_stair_v1.glb` and its
imported scene.

Fresh final-export Chromium journeys then passed D4's 32 observed phases / 20
production proofs with a literal `E` at the abandon Waystone, and D5's 28
observed phases / 13 required proofs from Archive lesson through four physical
Approaches, canonical Queen death, two scanner-driven Stair reads, and the
Hall/Atlas/Archive return. Both final tabs had zero browser error logs. The
artifacts measured 116,808,328 bytes PCK, 37,695,054 bytes WASM, and 5,890
bytes HTML. Sol's independent standards and spec audits accepted the integrated
milestone with no remaining P1/P2 blocker.

The next bounded council slice is **The Pale Oath**, levels 18–19. It begins at
the readable but non-traversable Stair and must turn the protected Oath Nail
into a generated-Chart road and boss settlement without retroactively changing
Queen or legacy-Summit truth.

## Pale Oath council decision — levels 18–19

The Terra research/QA council, Sol architecture critic, and Terra implementation-
seam response accepted the following binding contract. Implementation must not
reinterpret Queen's already-accepted settlement or the copy-only Pale Stair.

### Source and authored road

- The Pale Stair remains repeatable, copy-only, non-traversable, and incapable
  of changing Campaign, inventory, sources, or scenes. Its copy points the
  player to the Skald Archive.
- At Wayfinding 18, the physical Archive exposes a host-only
  `skald_pale_oath` source transaction. Guests receive the same prose only.
  Its unlock is derived exclusively from canonical `QUEENS_SUMMIT.cleared`,
  never from a loose Nail, old Summit flags, legacy state, or presentation
  objects. The fourth returned Oath-Rubbing reveals a second boss folio.
- Oath-Rubbings are ledger facts (`oath_rubbing_1..4`), never Satchel items or
  Table components. Four distinct successful, non-abandoned, host-authoritative
  `pale_veins` returns are required; RNG, elites, and Trophy Sense cannot bypass
  them.

The exact level-18 `pale_veins` Table grammar is:

```text
NW empty          N Pale Wellmark   NE locked
W Climbing Cord   C Atlas Folio     E Climbing Cord
SW locked         S empty           SE locked
Ink rail: Stoneground Ink x1
```

It requires Wayfinding 18, spends exactly five Hedge Ink as its ordinary
template cost, has one Affix slot, carries no Seal, and guarantees the next
authored Oath-Rubbing room. The first Archive folio grants a missing-only
complete attempt: Pale Wellmark, Atlas Folio, two Climbing Cords, and one
separate Stoneground Ink lesson supply. Pale Wellmarks then join Mara's
renewable drawer; existing Atlas Folio, Climbing Cord, and Stoneground routes
remain renewable.

The exact level-19 `pale_oath_boss` grammar is:

```text
NW Barrow Mark    N Pale Wellmark   NE Cold Track
W Climbing Cord   C Atlas Folio     E Climbing Cord
SW locked         S Oath Nail       SE locked
Ink rail: Stoneground Ink x1
```

It requires Wayfinding 19, spends five Hedge Ink, has zero Affix slots, and the
campaign contract alone forces `barrow_jarl`. The boss folio grants the route
parts missing-only, but never grants or duplicates the Oath Nail. Neither road
has an Earthcraft, Wildcraft, or Huntcraft campaign gate and neither consumes
Wildgold, Wellmoss, or their outputs. Rootskin Leaf is explicitly deferred.

### Campaign v4 and exact settlement

Campaign v4 appends `PALE_OATH` after `QUEENS_SUMMIT` and adds canonical
`threads: []`. Migration from v1-v3 is additive and inert. The chapter awards
Past Thread through `thread_awards: ["past_thread"]`; normalization stores it
as `state.threads`, and it never enters `relics` or material inventory.

The Oath Nail alone follows `case -> in_run -> consumed/refunded`. Ordinary
Table parts and Inks stay spent. Abandon, defeat, disconnect, and crash recovery
refund the Nail exactly once. Canonical settlement must target the final Nail
count to exactly zero, including malformed or duplicate pre-settlement counts.
It awards exactly one Starheart Coal, the Pale Root Rune, Past Thread, and the
single `rootroad_lift` restoration. That one restoration presents both the
functional Lift and Hod's restored oath-stone; there is no second restoration
flag. Starheart Coal is protected for the next authored boss road.

### Playable level-18/19 Trade family

- Earthcraft 18 exposes mineable Wildgold Veins in Pale Veins; Earthcraft 19
  smelts renewable Wildgold Bars and crafts master pickaxe/axe upgrades. The
  starter Wildgold vein never requires a Wildgold tool.
- Wildcraft 18 exposes Wellmoss and Wellmoss Salve. A Pale Well yields Wellwater
  at Wildcraft 19, which unlocks Wellwater Philter.
- Huntcraft 18 makes Driving Volley a real five-arrow, 60-degree close fan:
  0.4x damage per arrow, 26 Focus, six-second cooldown, and one collision-safe
  knockback per ordinary target. Bosses and vow-shielded actors take Poise
  pressure instead. The host owns hit/displacement outcomes. Its one-time,
  deferrable Lodge lesson never overwrites a full three-slot loadout.
- Huntcraft 19 Trophy Sense is deterministic information only: an elite's
  modifier stays readable, its reward-tier floor appears on its target plate,
  and a seeded eligible ordinary trophy gets a pre-kill sigil. It changes no
  RNG, drops, clues, returns, or boss access.

### Rootroads, Stonewake, and the Barrow Jarl

Ordinary Pale Veins Charts use the new rootroads biome and may roll one Affix
family. Good **Stonewake** has marked bell-stones telegraph for at least one
second, then knock enemies outward and deal Poise damage while leaving the
player safe. Bad **Stone's Rebuke** uses the same ground ring and bell sound but
also damages and displaces the player. Neither twin can change clues, bosses,
Wildgold availability, or settlement.

The Barrow Jarl has three relief phases near 75%, 50%, and 25% Vigor. Each
phase vow-shields the Jarl, wakes one Oathbound, clamps that guard's lethal
damage into Reeling, and enables only its matching bell. A host-validated bell
interaction checks phase, proximity, Reeling state, and bell identity, relieves
the guard, and removes the shield. Peers may request the action; only the host
commits and broadcasts it. The Jarl cannot emit canonical defeat until all
three reliefs are complete and then kneels instead of dying violently.

Blender owns the deterministic rootroad kit, bells, Pale Well, gather props,
Lift/well-house, oath-stone, and settlement display props. Meshy credits are
reserved for the rigged Barrow Jarl and one reusable Oathbound base family,
with idle, locomotion, attack, hit, Reeling, relief/kneel, shield, and defeat
coverage. Every new material, component, reward, Skill, and Affix needs a
painted non-placeholder icon.

### Acceptance and implementation guards

D6 is a real final-export Chromium journey from a canonical Queen-complete
fixture. It must physically read the Stair breadcrumb and Archive source,
inscribe at the real Table, complete four real Pale Veins returns, inscribe the
boss road, perform all three real bell reliefs, settle the exact rewards, inspect
Lift/oath-stone/Hall/Atlas/Archive, and equip and hit a valid target with Driving
Volley. It may not inject clues, boss Chart, escrow, relief result, rewards,
Thread, Rune, or restoration. Browser warnings/errors fail the journey, and the
actual PCK must contain every new GLB, imported scene, texture, icon, and
animation dependency.

Two P1 seam guards from Terra's response are binding: `Game`'s exact material-
target settlement path must include Pale Oath so success cannot leave a Nail,
and the Jarl behavior must structurally withhold `died` from the generic boss-
settlement callback until all three host-validated reliefs are complete. Root
remains the sole integrator for the hot `game.gd` seams so campaign and D6
workers cannot overwrite one another.

Deferred from this bounded slice: Rootskin Leaf, Oathnock Bow and the wider
named-unique family, full Wildgold armor/bow, Rootroad Lift traversal into
Chapter V, Fire in the Bough, new endgame pity systems, and cosmetic gear-
attachment work.

## Pale Oath implementation and acceptance — levels 18–19

The accepted slice implements the locked contract end to end. Campaign v4,
the copy-only Pale Stair, the Skald Archive source and boss folio, physical
Pale Veins and Pale Oath Table grammars, four ledger-only Oath-Rubbings,
Oath-Nail escrow, exact settlement, Rootroad town projections, Wildgold,
Wellmoss/Wellwater, Stonewake, Trophy Sense, and the real Driving Volley are
all live. The final production character paths are the skinned, animated
`boss_barrow_jarl_v1.glb` and `enemy_oathbound_v1.glb`; their reproducible
Blender source is `models/scripts/build_pale_oath_characters_v1.py`. No Meshy
credits were spent. Distinct painted icons now identify Starheart Coal, the
Pale Root Rune, Past Thread, and Driving Volley.

Sol's first final audit rejected the encounter despite green happy-path gates.
It found that merely hidden Oathbound still ran physics and collision, raw-hit
clamping could be pierced by crit/marked amplification or status ticks, guest
bell requests could borrow another peer's proximity, and phase-two/three bells
loaded the phase-one model before configuration. Terra's response added one
post-multiplier Combatant damage-floor seam shared by direct, status, and
replicated damage; explicit dormant/Reeling/relieved physics and collision
states; RPC-sender-bound player lookup; and deterministic phase-correct bell
model refresh. The new lifecycle, damage, authority, and construction-order
regressions pass 16/16, and Sol's re-audit accepted all four repaired paths
with no remaining P1/P2 finding.

The settled full serial native gate passed all 54 `test_*.gd` entrypoints with
zero assertion, script, parse, or load failures. Focused evidence includes
Pale world 16/16, campaign 7/7, content 16/16, runtime 10/10,
presentation 5/5, co-op 5/5, Pale Skills 9/9, general Skills 65/65,
save roundtrip 118/118, and the full game loop 426/426. Intentional headless
teardown resource-leak diagnostics remain outside the failure scanner; the
release browser had no diagnostics.

The final post-repair Web export passed the strict D6 route from a fresh
origin. It observed the exact 32 phases from `title` through four physical
Pale Veins returns, all three Jarl bell reliefs, settlement projections,
Driving Volley, and `complete`; all sixteen fail-closed production proofs were
present. The browser produced 72 entries with 0 warnings and 0 errors. The
isolated PCK audit loaded all 55 required resources, including the final
skinned characters and four new icons; `index.pck` measured 117,332,168 bytes.
The PCK remains the known Web-startup bottleneck for the later shipping wave,
not an unrecorded acceptance claim.

The next bounded council/implementation slice is **Fire in the Bough**,
levels 20–21: Ashen Bough, Ember Verses, the Starheart-sealed Hearth Giant,
Threadstep, the Ember Kiln, and the Present Thread.

## Fire in the Bough council decision — levels 20–21

Root accepted the Terra/Sol council after one complete critique round. Campaign
v5 appends `fire_in_the_bough` after the Pale Oath. Five ledger-only
`ember_verse_1` through `ember_verse_5` clues may bank only from five distinct,
successful, non-abandoned `ashen_bough` returns. Ordinary Ashen Bough access is
not gated by another Trade: an eligible host reads the Rootroad Lift source
exactly once at Wayfinding 20, learns the ordinary folio, and sees the lower-
landing animation. Before Pale settlement or below Wayfinding 20 the Lift
remains the existing inspect-only Pale landmark; guests are read-only in every
state. Verse II discloses Emberleaf Ink and Verse V discloses the boss folio.
The Lift grants no components, Ink, or free Chart and never bypasses the Table
or Waystone.

The ordinary Table recipe is `ashen_bough`: north-west Ash Mark, north Cinder
Waymark, north-east Ember Mark, west Cinder Binding, centre Ember Folio, east
empty, Ash Ink rail, five Hedge Ink, and one Cinderbound affix. Its only deeper
variant is `ashen_bough.deepening_variant`: at Wayfinding 21 the optional east
Cinder Binding enables Deepening II under an explicit depth contract. It never
changes clue access or clue count. The boss recipe is exactly
`fire_in_the_bough_boss`: north-west Furnace Mark, north Cinder Waymark,
north-east Soot Track, west Cinder Binding, centre Ember Folio, east empty,
south Starheart Coal, Emberleaf Ink rail, five Hedge Ink, no affix, and a forced
Hearth Giant. It can neither resolve nor match the ordinary deepening variant.

Emberleaf Ink is the one disclosed supporting-Trade gate: Wildcraft 20 mixes
two Embersage, one Wellwater, and one Ash Ink. Every ingredient is deterministic
and renewable, and the game never grants free Emberleaf Ink. Earthcraft,
Huntcraft, brews, gear, and Deepening II remain optional for the base story.
Every ordinary Ashen Chart materializes an `elite_manifest` from a domain-
separated Chart-seed stream, independent of room-generation RNG. The manifest
names the guaranteed first eligible elite slot and its modifier, or explicitly
states that there is no eligible elite. World consumes that exact descriptor;
Pack Reader at Huntcraft 21 only reveals it and presentation consumes no RNG.

Cinderbound has one host-authored 1.25-second, three-pip vent telegraph. Its
good twin harms and Poise-breaks nearby enemies, then creates one nonce-keyed
Focus pickup. The host binds the requesting peer, validates proximity, claims
the pickup atomically once, and grants Focus to that peer. Cinder's Rebuke uses
the same telegraph to damage and slow the player. Guests receive visuals only;
neither twin mutates clues, gathering, boss state, or settlement.

Threadstep at Huntcraft 20 is a collision-safe movement Skill with a fixed
maximum distance of five metres, 20 Focus cost, eight-second cooldown, and a
0.22-second cinder-only grace after acceptance. It cannot cross walls, closed
doors, void, navigation gaps, or arena gates. It bypasses generic
`_try_skill`/`_net_cast`. The owner may have at most one pending nonce: local
preflight requires 20 unreserved Focus and reserves exactly 20 while connected.
The request carries only nonce and normalized direction. The host binds the RPC
sender, derives the host-side puppet origin, validates entitlement/session state
under the existing party trust model, its authoritative per-peer nonce/cooldown
ledger, swept capsule, navigation, gates, and fixed range, then returns a
reliable nonce-keyed accept or reject. Acceptance atomically commits the exact
endpoint and cinder grace once; the matching owner acknowledgement alone
consumes the reservation, debits 20 Focus, and starts the UI cooldown once.
Reject or session loss releases it. Duplicate, late, or mismatched
acknowledgements are no-ops. A connected owner may not time out and release a
live reservation without a host cancellation acknowledgement. A blocked or
rejected Threadstep therefore spends nothing.

The Hearth Giant is a separate encounter controller, not a Jarl reskin. At 75,
50, and 25 percent health, the Combatant damage-floor seam withholds `died` and
raises a heat shield until the next authored chain is banked. The immutable
order is Hollow Link, Braided Link, then Knot Link. The host validates RPC
sender, Chart/attempt identity, proximity, current phase, expected chain, and
unbanked state. A wrong chain causes one modest recoverable hazard and retry;
it never clears prior banks. After all three correct banks the Giant kneels and
banks the fire rather than dying. Direct hits, status ticks, critical/marked
damage, and network snapshots cannot pierce a floor or emit an early death.

Late join is fail-closed. A World-ready handshake is keyed by Chart instance
and attempt. Only after the joining World reports ready does the host send one
reliable, idempotent encounter snapshot containing boss health/aggro, heat
phase, three-bank mask and order, shield, every chain state, current telegraph
kind/nonce/time remaining, and settled or kneeling state. The guest controller
remains inert until the snapshot is applied and ignores stale nonces. Join,
disconnect, and replay never settle or refund the Seal.

Starheart Coal is the sole Story Seal and follows case to `in_run` to consumed
or refunded escrow. Canonical success targets exactly zero Coal and one Wyrm
Scale, then awards the Ember Root Rune and Present Thread and projects the
functional `ember_kiln`; its Threefold Loom foundation is an inert derived
child, not another restoration. Wyrm Scale is reserved for the Unwritten Road.
Starheart Alloy is not a boss award, target, or Seal: its first unit is an
explicit post-clear Kiln craft from two renewable Wildgold Bars and two
renewable Emberglass. The existing Table Mix remains the pre-boss place for
Emberleaf Ink.

Art ships as final low-poly Blender assets for the Ashen branch, Lift landing,
chains, Ember Kiln/Loom foundation, and static props. Meshy is justified only
for a Hearth Giant base/rig if it materially improves the character; every such
result still receives Blender cleanup, canonical skeleton/animation naming,
GLB validation, and a documented fallback. Fire rewards, components, Inks,
chains, Cinderbound, Giant, Threadstep, Pack Reader, and restoration all require
distinct readable icons or UI states rather than glyph placeholders.

The strict Web D7 journey begins from a fresh save and follows production UI:
title and onboarding; accepted Lift inspection; ordinary-folio teaching; five
physical ordinary Table commits and Waystone delves; five distinct successful
returns with frozen elite-manifest proof; Verse II recipe discovery and a real
renewable Emberleaf mix; Verse V boss-folio discovery; boss Table commit with
the real Coal escrow; all three Giant heat floors, one recoverable wrong-chain
proof, and the three correct host-authoritative banks; exact settlement;
Kiln/Loom, Rune, Thread, Scale, Archive, Atlas, and Lift projections; one real
post-clear Starheart Alloy craft; one accepted and one blocked Threadstep; and
Pack Reader's zero-RNG reveal. It may inject no clue, recipe, Chart, Seal,
escrow, chain bank, settlement, reward, restoration, Skill result, or elite
manifest. Required resources must load from the exported PCK; browser warnings
or errors fail the run. Native acceptance includes focused campaign, Table,
world, boss-floor, Threadstep authority, late-join/replay, Cinderbound, save,
and asset tests plus the complete serial `test_*.gd` gate.

**Council timeout amendment (2026-07-18):** because D7 now proves the whole
fresh-save saga rather than beginning from a chapter fixture, its browser
watchdog is fifteen minutes (900 seconds). This changes no acceptance contract:
the route may still not inject campaign, Trade, material, Chart, source,
escrow, reward, restoration, Skill, or manifest truth. Bounded dwell-time
acceleration, scanner positioning, and damage driven through the production
Combatant callbacks are the only automation allowances.

### Fire implementation review — 2026-07-18

The substantive level 20–21 systems are accepted after Terra implementation
and Sol re-review. Ashen Bough has renewable Embersage and Wellwater; the
Hearth Giant holds every heat floor, consumes its authored state clips, and
stays permanently nonlethal after banking; guest World-ready snapshots are
authority-gated and replay presentation without replaying settlement;
Cinderbound has observable Poise, slow, range, and late-pickup behavior; and
Threadstep keeps owner-local Focus until a sender-bound host acknowledgement,
with sampled navigation and reconnect release. Focused evidence is green:
content 9/9, encounter 17/17, Threadstep ledger 9/9, integrated World 8/8,
assets/icons 20/20, and boot 122/122.

D7 remains explicitly unaccepted until the exported-browser marathon satisfies
the fresh production contract above. QA may shorten dwell and drive damage
through the production combat callbacks; it may not call a direct campaign
resolver or directly mutate campaign, Trade, material, Chart, clue, Seal,
escrow, settlement, reward, restoration, or Skill-result truth.

### D7 economy and gathering hardening decision — 2026-07-18

Sol rejected the first fresh-marathon candidate because its later chapter Inks
were not renewable through the route, several gathers called GatherNode
directly, and training completion depended on random gather Affixes. Terra
confirmed those blockers and identified the missing Pale Oath Stoneground path.
Root accepted the critique and kept D7 unaccepted.

The production decision is that a normal Tier-1 Green Hollow always carries one
Copper Ore, one Wild Herb, and one Log node. Gather Affixes remain meaningful
bonus patches; they are no longer the only availability gate for the four core
Trades. The rule is authored in the Chart generation data and verified across
fifty deterministic seeds.

All fresh-marathon harvesting now uses player scanner acquisition plus the
released `interact` InputMap action, holds position through GatherNode's own
channel, and allows that node to own depletion, yield, Trade XP, hints, and
respawn. Dwell and scanner positioning remain the only gather acceleration.
The driver derives each chapter's Hedge Ink runway from authored Chart and Ink
costs, then physically harvests and mixes Golden, Seventh, Refined,
Stoneground, Ash, and Emberleaf requirements at the Chart Table. The Web probe
now requires explicit training and five chapter-economy feature proofs.

Native evidence is additive, not release acceptance: title through First Knot
is 5/5; one real Table/forge/Waystone/World/Far-Waystone training lap is 3/3;
the bounded late-restoration Ink seam is 9/9 and includes production Town
control, scanner harvesting, and one physical Copper-Pot Hedge Ink transaction;
and the post-hardening complete serial gate is 63/63. The synthetic Ink fixture
initially exposed a paused Golden Wallow settlement debrief rather than a
scanner defect; acknowledging that production modal through the shipped Town-
control wait made the exact late-Town seam deterministic in about four seconds.
Sol's independent final audit accepted the native hardening with no remaining
P1/P2 blocker.

The current release Web export passes the isolated PCK audit with 86 loaded
resources at 117,984,788 bytes and is served locally on port 8060. The in-app
browser connector is unavailable, so D7 still requires the clean exported-
browser marathon and warning-free console before Fire can move from
implementing to shipped. This external browser gate remains open while native
work proceeds into The Unwritten Road.

### D7 owned simulation-clock contract — 2026-07-19

#### Decisions

The strict fresh-save D7 journey is too long for an unaccelerated browser
watchdog, but a loose global `Engine.time_scale` change would hide timing and
restoration defects. The release route therefore has one query-gated,
single-owner D7 simulation-clock lease. It begins only after the driver has
reported the real `fresh_campaign` boundary, requests **exactly 6×**, and may
never request or observe a scale above 6×. It changes no campaign, Trade,
material, Chart, source, escrow, reward, restoration, Skill-result, combat, or
input truth; it only shortens the real production route's simulated duration.

The owner captures the pre-lease scale and is the only D7 code allowed to set
or restore it. It must restore that captured scale before serializing either
terminal smoke report, on every driver failure, and from `_exit_tree`. Hitstop
participates by capturing the active baseline when it freezes, preserving it
through overlapping freezes, and restoring that baseline only after the latest
freeze; a cancellation must invalidate delayed callbacks before restoring the
D7 baseline. The D7 driver also owns a monotonic real-wall watchdog, independent
of simulation time, so time-scale cannot extend the fifteen-minute acceptance
budget.

Because the outer browser runner begins its 900-second measure before title and
new-journey work, the in-game terminal guard starts only after `fresh_campaign`
but fires at 840 seconds. That reserves a 60-second startup and serialization
margin. It is a process-always, ignore-time-scale `SceneTreeTimer` stamped with
the D7 attempt token/generation; complete, failure, and `_exit_tree` invalidate
that generation before the terminal payload, making a later callback an
evidence-only stale no-op.

The browser report carries an attempt-bound structured
`d7_simulation_clock` receipt with exact fields:
`owner: "d7_smoke_clock"`, `activated_after_fresh_campaign: true`,
`requested_scale: 6`, `observed_scale: 6`, `max_observed_scale: 6`, a positive
`captured_baseline_scale`, `watchdog_clock: "monotonic_real_time"`,
`restored_before_terminal_serialization: true`, `restored: true`,
`terminal_reason: "complete"`, and a `terminal_scale` equal to the captured
baseline. Its nested `training_start_watchdog` receipt must contain exactly
`duration_sec: 8`, `ignore_time_scale: true`, `armed: false`, and `fired: true`.
Its separate `terminal_watchdog` must contain exactly `duration_sec: 840`,
`ignore_time_scale: true`, a nonempty `d7_`-prefixed `attempt_token`, an integer
`generation > 0`, `armed: false`, `fired: false`, `cancelled: true`, and
`stale: false`. The attempt identity proves it was armed and the terminal state
proves it was invalidated before serialization; any later stale callback is an
evidence-only no-op and cannot retroactively change the serialized receipt.
The injected probe validates these fields rather than accepting a truthy flag.
Release acceptance additionally requires focused 1×/6× parity evidence for
phase ordering/receipts, Giant heat floors and chain banks,
status/cooldown/Threadstep behavior, and final campaign truth; two independent
fresh exported-Web passes below 900 seconds (target ≤750 seconds), each with
zero warnings/errors and a restored terminal scale.

The focused parity proof is now implemented in
`test_d7_clock_gameplay_parity.gd`. It runs the same deterministic production
representative path at 1× and 6×, then deep-compares a normalized snapshot that
excludes wall time and clock-receipt scale fields. The compared truth includes
the ordered Game report history, an exact-target Pale Stair scanner/InputMap
receipt, the generated Hearth Giant's 75/50/25-percent floors, recoverable
wrong chain and 1/3/7 bank masks, live Player Threadstep/Focus/cooldown and burn
outcomes, and canonical Fire settlement. Root repeated the final 6/6 proof
three times with zero warnings or errors.

#### Deviations

- The former “bounded dwell-time acceleration only” allowance is superseded for
  D7 by the explicit, owned 6× lease. It is more tightly scoped and evidenced,
  rather than a general testing acceleration permission.

#### Tradeoffs

- A local dwell-only shortcut would preserve combat timing but cannot cover the
  route's scene-load-heavy duration. A capped, query-only simulation lease is
  accepted only with real-wall timing, restoration, and parity evidence.

#### Surprises

- Hitstop's old hard-coded restoration target could silently reset an active
  accelerated route to 1×, so its baseline/cancellation semantics are part of
  the release contract rather than an implementation detail.
- The live Threadstep harness could query a valid NavigationServer map RID
  before its first synchronized iteration, producing a diagnostic and a flaky
  rejection under load. Production now fails closed while the map iteration is
  zero, and the harness waits on an iteration/readiness boundary rather than a
  guessed number of frames. Root's post-fix five-run stress was clean.
- A JavaScript-only 900-second timeout could fail the semantic harness while
  leaving Godot's 6× lease active. The attempt-owned 840-second in-game guard
  now reaches the normal failure/report/restoration path first.

#### Followups

- Record two independent fresh exported-Web receipts below 900 seconds (target
  at most 750 seconds), with zero diagnostics and both owned-clock watchdog
  receipts valid, before moving D7 from Web-pending to shipped.

## The Unwritten Road council decision — levels 22–23

**Locked 2026-07-18 after three Terra audits, Sol revision, one Terra response,
and root decision.** D8 extends the existing pure Campaign → Chart → runtime
adapter path as Campaign v6; it does not introduce a second quest or inventory
system. Fire remains Web-pending while this native work proceeds.

### Final ritual truth

The Wyrm Scale is the final Chart's only physical Story Seal. It follows the
existing `case → in_run → consumed/refunded` escrow and is consumed exactly
once only by canonical success. The Map of Nine Knots and the Green, Mist,
Fang, Crown, Pale, and Ember Root Runes are immutable campaign references. The
Table and host commit require them and freeze a sorted `story_input_snapshot`
into the Chart/attempt, but they are never removed, reserved, materialized as
Rune-Braid inventory items, or included in refund arithmetic. Past and Present
Threads support the Loom's Map ritual; Unwritten Thread is awarded only after
the final settlement. All three Threads remain references for Wayweaver.

The Chart Table receives one data-owned `required_story_inputs` interface and a
read-only witness presentation. Its two Relic cells project “Older Roads · 3/3”
and “Deeper Roads · 3/3”; a separate Map witness row reports 1/1. Expanded
preview names every required record and any missing one. The campaign/story
fingerprint participates in preview/commit freshness, and no reference enters
material costs. Lost Waymarks remain ledger facts; the physical recipe uses
three renewable Lost-Waymark Tracings.

### Exact late progression

Campaign Charts freeze authored total Wayfinding rewards which replace the
generic tier/Affix completion formula. Campaign recipe discovery XP is zero.
The exact fresh lane is:

```text
Wayfinding 20 floor                              3496
five Ashen clue returns       +68+69+69+69+69 → 3840 (level 21)
Hearth Giant return                         +360 → 4200 (level 22)
five Root Below clue returns   +75+75+75+75+76 → 4576 (level 23)
Unwritten final return                          +0 → 4576
```

Only an eligible clue or boss Chart receives the frozen replacement. Duplicate,
abandoned, non-clue, and Memory Charts cannot replay it; pre-v6 materialized
Fire Charts without the field keep legacy behavior. A progression simulator
must prove the exact floors without a QA driver awarding XP or mutating Trades.

Root Below and its five Lost Waymarks require Wayfinding 22. The Unwritten
Chart requires Fire settled, five distinct Waymarks, Map plus all six Runes,
Wayfinding 23, and Huntcraft 22. Earthcraft/Wildcraft/Huntcraft 23 never block
the story. All four Trades at 23 gate Wayweaver only.

### Chapter, encounter, and mastery contract

Root Below guarantees one reachable Lost Waymark room, one Waysteel source,
and one Root-Sap source on every eligible Chart across seeds. Its first Mythic
twin is Open Thread / Snagged Thread; neither twin may change clues, authored
XP, resource guarantees, boss access, or settlement.

`KnotEaterEncounter` owns a nonlethal, host-authoritative state machine:
Gnawing survival → unbind three old anchors → expose/Reel and mark three knots
→ Name the new road. The Knot-Eater cannot emit campaign settlement from
`died`. Wayfinder's Mark validates sender, entitlement, Focus, cooldown,
attempt/Chart identity, phase, target, proximity/line of sight, and nonce;
blocked requests spend nothing, accepted requests spend once. The encounter
snapshot covers phases, masks, telegraph nonce/time, naming eligibility, and
settled state for late join. Only the exact host naming action settles once.

The Threefold Loom is `stirring` after five Waymarks at Wayfinding 23, when it
references Past and Present and records the permanent Map; it becomes `awake`
after Unwritten Thread and owns the Wayweaver String ritual. Hod's Smithy makes
the Waysteel Frame at Earthcraft 23. Master Hunt turns the exact-once Quiet
Tooth trophy into the Quiet-Tooth Grip at Huntcraft 23. The Master Forge alone
atomically consumes Frame, String, and Grip to create one Wayweaver after
rechecking final clear, all-four-23, the Map, six Runes, and three Threads.
Those permanent references remain. Quiet-Tooth Charm is a separate replay
unique, never the trophy or Grip.

Wayweaver's first successfully cast Focus Skill in a room arms a transient
thread; the next real Basic Shot emits one modest identity echo and clears it.
The pure rules module owns preview/commit policy, while the existing bow socket
owns presentation. Post-clear Memory Charts are campaign-inert and cannot mint
story records, settlement, road names, or another Forge unlock.

The final naming UI offers three authored, mechanically identical names:
Lantern Path, Mended Way, and Open Footpath. The host choice persists only as a
cosmetic `road_name_id`; guests observe it. It never affects rewards, Charts,
or progression.

### Bounded implementation and release gates

Implementation order is: spec/progression simulator; Campaign v6 and migration;
Root Below content/resources/XP; Loom Map ritual and story-witness Table seam;
five-return World path; production Wayfinder's Mark; Knot-Eater/co-op/naming;
master components, Forge, Wayweaver and attachment; campaign-inert Memories;
then full native/export/browser acceptance.

The release PCK baseline is 117,984,788 bytes. D8 targets at most +8 MiB and
must report exact size/startup deltas; a larger delta requires an explicit asset
audit. Reuse rootroad geometry/materials. New 3D scope is bounded to Knot-Eater,
minimal anchors, Wayweaver/mount, and procedural Loom/second-hearth upgrades—no
new NPC rigs, decorative megakit, duplicated textures, or unreferenced raw
models. Meshy spend remains unauthorized until a named deliverable and cleanup
plan are recorded.

Shipping requires both an independent fresh D7 release-Web marathon (900s) and
a separate full fresh title-to-Wayweaver D8 marathon (1800s), production UI and
input only, isolated PCK audit, and zero browser warnings/errors. Neither Fire
nor D8 becomes shipped while either browser gate is missing.

### D8 Slice 0 implementation acceptance — 2026-07-18

Campaign v6, the final-story witness seam, and the exact level-20-to-23 XP lane
are natively accepted as a foundation, not as a shipped chapter. Migration from
v1–v5 is inert and idempotent; it cannot infer Wyrm Scale or Rune ownership from
loose materials. Map and Rune witnesses remain immutable campaign references,
while Wyrm Scale alone follows case-to-run escrow. Generic boss death cannot
settle the final road, and the three cosmetic road names have no mechanical
effect.

The Chart Table now owns Root Below and Unwritten Road recipes, sorted story
snapshots, witness projections, and a story fingerprint without putting a Map,
Rune, Thread, or Lost Waymark into material costs. The five Root Below returns
replace ordinary completion XP with `75/75/75/75/76`; campaign discovery XP is
zero and the final return pays zero. Sol's first review found that two distinct
Charts pre-inscribed against the same pending Waymark could rebind the next clue
but lose its authored reward. Terra accepted the finding. Rebinding now replaces
the clue and its exact indexed reward together; returned IDs, copies, Memory
Charts, ordinary Charts, and legacy Charts remain outside that lane. A shuffled
five-Chart regression proves the exact sequence and replay rejection, and Sol's
re-review accepted the correction with no P1/P2 findings.

Focused evidence is green: campaign 10/10, progression 15/15, final Chart
contract 4/4, cross-contract acceptance 9/9, core loop 426/426, boot 122/122,
Fire compatibility 9/9, and transitions 133/133. The last complete native serial
before the correction was 67/67; a fresh complete serial remains required after
the first playable Root Below slice. D8 is still implementing and has no current
Web acceptance claim.

### D8 Slice 1 Root Below acceptance — 2026-07-18

The ordinary Root Below chapter is natively accepted after three non-overlapping
Terra implementations, a root integration pass, a complete serial gate, and Sol
review. Canonical Fire settlement exposes the physical Threefold Loom source;
Wayfinding 22 makes its lesson eligible. The first read teaches Root Below and
tops up exactly one Nine-Knot Leaf, Lost-Waymark Tracing, and Threefold Binding.
It awards no Chart, Ink, gold, Map, Rune, Thread, or ledger Waymark. Rereads and
guest reads are inert. Once known, Mara renews those ordinary pieces for
10g/5g/7g.

Every eligible Root Below World owns exactly one reachable Lost Waymark reading,
one Waysteel Shard source, and one Root Sap source outside entry and the unused
boss room. The generator rejects attempts that cannot realize those promises.
Fifty deterministic seeds per Open Thread/Snagged Thread side preserve identical
clue and resource coordinates, exact counts, and repeat generation. Both Mythic
twins change only player movement (1.08/0.92); they cannot perturb campaign,
gather guarantees, bosses, costs, gold, or authored XP. Lost Waymark interaction
remains copy-only; only a successful unique return banks the campaign fact.

The root playable gate performed five physical Table commits, production
Waystone transitions, generated Worlds, normal returns, and four real Mara
refills. Starting from 4200 Wayfinding XP and zero gold, the returns paid
`75/75/75/75/76`, reached exactly level 23 at 4576 XP, banked all and only five
sorted Waymarks, paid 28g each, and left 52g after four 22g replacement kits.
Abandon kept ordinary components spent and paid no XP/Waymark; a returned Chart
identity could not mint a sixth clue or replay authored XP. The Atlas projected
0/5 through 5/5 without making the Map. The existing Ember Kiln and the adjacent
Loom remain distinct scanner targets, and no new 3D asset or Meshy spend entered
the slice.

Evidence is green: content 10/10, generation 6/6, presentation/guest authority
13/13, playable loop 7/7, Slice 0 campaign/progression/Table/cross-contract
38/38, core loop 426/426, Chart Table UI PASS, boot 123/123, save 118/118,
transitions 133/133, procgen 17/17, Fire compatibility 17/17, and the complete
serial 71/71. Sol accepted with no P1/P2 findings. Remaining test blind spots
are explicit: the five-run gate calls production APIs rather than navigating
Table/Waystone UI input; it proves resource presence rather than harvesting both
nodes in that loop; seed evidence is sampled; Root Below has no dedicated co-op
five-return race test; and no D8 browser acceptance has run. D8 remains
implementing. Next is the production Wayfinder's Mark and Knot-Eater encounter,
not the final release gate.

### D8 Slice 2 Knot-Eater architecture decision — 2026-07-18

**Locked after Design-It-Twice proposals from three Terra agents, a Sol
revision, one Terra response, and root decision.** The three proposals placed
the same Seam at different depths: one minimal `open/transact/view` encounter,
one boss-scoped command/event reducer, and one caller-first action inbox. The
selected design combines the reducer's testable rules with the inbox's small
Interface. It deliberately rejects both a public security-facts dispatcher and
a game-wide event bus.

`KnotEaterRules` is a pure, boss-scoped Module. It owns phases, authored masks,
validation order, nonce high-water marks, stable accepted/rejected receipts,
the host Mark cooldown ledger, snapshot invariants, and the two-stage naming
transition. Its command/event vocabulary and deterministic replay support are
private. Accepted transitions and receipts live only for the active encounter;
active runs remain non-resumable and no event log enters the save. Removing the
module would distribute these rules across the boss, anchors, player, UI,
transport, and `Game`, so the module provides the intended Depth and Locality.

The player-facing Interface is one intent seam:

```gdscript
press(verb, subject_id) -> receipt
view() -> immutable read model
```

Mark, anchor, and naming callers never construct sender IDs, Chart/attempt
identity, positions, entitlement facts, Focus values, range/line-of-sight
facts, phase, masks, or settlement effects. `KnotEaterEncounter` injects those
through local scene/physics and remote transport Adapters before invoking the
private reducer. The read model contains phase, both masks, active Reeling
target, telegraph nonce/time, Mark readiness and pending receipt, naming
eligibility and all three authored choices, settling state, and the durable
road name. Guests consume the same host snapshot but never receive the host
naming capability. A 12-metre range, 35 Focus cost, 14-second cooldown, and
three-second Reeling window are the production Mark contract.

Focus remains owner-local for D8, matching the accepted Threadstep party-trust
model. The owner preflights Huntcraft 22, ownership/equipment, and 35 available
Focus, then reserves exactly 35 while the request is live. The host binds the
real RPC sender and body and owns World-ready, Chart/attempt identity, phase,
exact active target/Reeling nonce, target uniqueness, distance, line of sight,
nonce, and Mark cooldown/receipt validation. Rejection releases the reservation
without debit or cooldown. The matching host acceptance alone debits the owner
and starts the UI cooldown once; duplicate, late, borrowed-body, or mismatched
acknowledgements are inert. Remote Focus and entitlement are explicitly
party-trust attestations, not independent host account truth.

A Mark-only host `PlayerSkillAccount` is forbidden because it would immediately
split from owner-side regeneration, generic Skill debits, Threadstep, Even
Breath, Focus awards, and HUD state. Independent server-authoritative Focus is a
future all-or-nothing migration of every Focus mutation/read and generic cast,
not an encounter-local shadow balance.

Reconnect correctness is stronger than the current Threadstep template. The
encounter retains every accepted player transition, a per-peer nonce high-water
mark, and the latest unresolved receipt. `snapshot_for_peer(peer_id)` includes
that peer's receipt. A transient reconnect does not discard a live Mark
reservation before reconciliation: an accepted receipt commits the one debit,
while a recorded rejection/cancellation releases it. Evicting an old receipt
can never make its nonce acceptable again.

Naming is a two-stage transition. An accepted host naming intent enters
`settling` and creates one idempotent effect; it does not publish `settled`.
One narrow `Game` wrapper invokes the unchanged
`CampaignData.resolve_unwritten_road`, applies rewards and saves only when
`changed`, and returns the durable result. The encounter reaches `settled` only
after that result succeeds and its durable road name matches the pending choice.
A consumed-tombstone replay with another name cannot overwrite or falsely
settle. `died` remains inert, and only the permanent positive damage-floor seam
may keep the Knot-Eater at one health.

Slice 2 acceptance must cover the pure phase trace and all illegal orders; real
hotbar reservation/receipt behavior; zero-spend rejection and exact-one debit;
dropped acknowledgement plus reconnect reconciliation; sender/body spoofing;
wrong World, Chart, attempt, target, Reeling nonce, range, and line of sight;
simultaneous-peer Mark races; stale/malformed/late-join snapshots in every
phase; nonlethal direct/status/network damage; all three mechanically identical
road names; guest naming rejection; durable exact-once Campaign settlement;
production UI input/read state; focused compatibility; and a fresh complete
native serial. Browser acceptance remains a later D8 release gate.

### D8 Slice 2 Wayfinder's Mark and Knot-Eater native acceptance — 2026-07-18

Wayfinder's Mark and the Knot-Eater encounter are natively accepted after the
three-Terra architecture council, root integration, two Sol revision rounds,
and Sol's final no-P1/P2 review. The physical Huntcraft-22 Lodge lesson owns the
one-time Mark grant; leveling alone grants nothing. A free loadout slot equips
it, a full loadout defers it without loss, and rereads are inert. The production
hotbar exposes the action only during the active Knot-Eater's three-second
Reeling window. Its contract is exactly 35 Focus, 12 metres with line of sight,
and a 14-second cooldown.

The encounter now runs the complete authored sequence: six seconds of Gnawing
after real boss aggro, three physical anchors, host-cadenced exposure of three
physical knots, one Mark per Reeling window, then the blocking road-naming
ritual. The Knot-Eater remains dangerous until naming, is pacified while the
party makes or settles the irreversible choice, and cannot be killed early by
direct, status, or replicated damage. A full-party wipe resets the reducer,
boss, physical actors, cadence, and unresolved ritual window together; passive
guest snapshots refresh the scene and emit terminal presentation once.

Focus remains owner-local and exact-once. The owner reserves Focus before the
intent; the host binds transport sender, live body, World, Chart, attempt,
target, range, line of sight, Reeling nonce, and cooldown. Every Mark answer,
including a pre-World `world_not_ready` rejection, is stored with an explicit
Mark kind and the separate owner reservation nonce. A stable opaque session
token can atomically rebind that ledger to a replacement transport peer without
being broadcast, while the guest retains the same Player body and Focus
reservation. Reconnect snapshots apply a matching accepted or rejected receipt
before considering resubmission; only the absence of any matching authoritative
receipt permits one retry. Sol's final regression review accepted this seam.

Lantern Path, Mended Way, and Open Footpath remain mechanically identical. Only
the host can choose. Escape cannot dismiss the modal, a failed durable write
stays open for the exact same-name retry, and the panel closes only after the
unchanged Campaign resolver confirms the matching Chart, attempt, chapter, and
effect. Save round-trip evidence preserves the cosmetic road name, Thread,
Forge state, and exact identical materials without allowing a second reward.

The distinct Mark icon was generated with the built-in image generation
pipeline and integrated at
`wyrd/assets/ui/icons/skill_wayfinders_mark.png` as a 128×128 RGBA asset. The
Knot-Eater currently reuses the Barrow Jarl GLB as a bounded placeholder; its
production model has not been authored and is not part of this acceptance.

Focused evidence is green: pure rules 18/18, live Player/Mark 16/16,
encounter/damage/reset 21/21, co-op authority/reconnect 17/17, naming panel 5/5,
durable naming 20/20, Skills 72/72, and boot 130/130 across 127 parsed scripts.
The fresh complete native serial is 77/77 test entrypoints. Native Slice 2 is
accepted, but D8 is still implementing: Mastery Components, the Forge
combination, the Wayweaver and gear attachment remain next. A real two-process
ENet run, the independent D7 browser marathon, and the full D8 browser marathon
remain binding release gates.

### D8 Slice 3 Wayweaver architecture decision — 2026-07-18

**Locked after three Terra proposals, a Sol revision, one Terra response, and
root decision.** The mastery chain spends exactly the five authored Root Below
gather pairs: Hod turns three Waysteel Shards into one Core, then the Core plus
two Shards into the Waysteel Frame; Quill turns three Root Sap into Root-Sap
Cord and two into a Threefold Draught; the awake Loom consumes Cord plus Draught
to weave Wayweaver String while merely witnessing all three permanent Threads.
Master Hunt turns the exact-once Quiet Tooth into the Quiet-Tooth Grip. The
Master Forge consumes only Frame, String, and Grip. Map, six Runes, three
Threads, final clear, restoration, and all-four-23 are rechecked but never
spent. Quiet Tooth, Grip, and the campaign-inert replay Charm remain three
distinct IDs.

The two Root Below mastery sources are fixed at exactly one raw material and
bypass Keen Eye and Sturdy Swings. Every mastery conversion bypasses Smith's
Thrift, Second Pour, ordinary Trade XP, and generic `Game.craft()`. This makes
the five-return budget exact even with every perk active; rerunning Root Below
remains the no-RNG recovery path if the player skipped a source.

`WayweaverMasteryRules` is the pure preview/commit policy module. It consumes
normalized Campaign facts, live Trades, physical component counts, and
inventory/equipment ownership, and returns stable requirements plus exact
mutation plans. `Game` is the sole synchronous durable mutation wrapper. A
final `keep` choice preflights a 2×4 pack placement for the new bow; `equip`
preflights only the displaced weapon and needs no pack room when the weapon slot
is empty. Commit recomputes every prerequisite before atomically consuming the
three components and placing exactly one item. Wayweaver is a non-sellable
legendary `ItemsData` weapon, never `materials.wayweaver`; uniqueness scans both
pack and equipment and the old material-output Forge seam is removed.

`WayweaverThreadRules` separately owns session-only room behavior. A World-owned
`RoomPresence` resolves deterministic `{run_epoch, layer, room_id, eligible}`
from authored room bounds; corridors and overlaps fail closed. Each eligible
room has exactly `fresh → armed(identity) → spent`. Only its first successful
Focus Skill may arm; the next real Basic Shot release spends the opportunity
even on a miss. Later Skills cannot overwrite or re-arm. Room exit, layer/run
change, death, reconnect, or armed weapon loss burns/clears state. Both arm and
release recheck that Wayweaver is equipped. Nothing enters the save.

The data-owned identity/effect table is exact: Power Shot, Piercing Bolt, Mercy
Shot, and Wyrdvolley use `pierce` (+1 pierce only); Multi-Shot, Rain of Thorns,
Driving Volley, and Galecall use `fan` (two ±12° arrows at 25% damage, unable to
crit, pierce, execute, carry effects/enchants, or recurse); Bramble Snare and
Thornburst use `root` (0.75-second first-hit root respecting boss/elite
immunity); Heartwood Ward uses `ward` (max-preserving 8 Ward for four seconds);
Hunter's Mark, Threadstep, and Wayfinder's Mark use `mark` (two-second mark
after the Basic Shot's own damage). Threadstep and Wayfinder's Mark arm only
after their matching host acceptance; other Skills arm only after successful
debit/fire.

Co-op remains party-trust without a shadow Focus or inventory account, but the
echo path is dedicated rather than extending the permissive generic cast RPC.
The host binds sender to body, validates a finite nonzero aim, real Basic Shot,
enum, host-computed room key, and a monotonically increasing stable-session
nonce/high-water ledger before applying one echo. Echo arrows cannot recurse.
The attachment resolver owns the complete model path/local transform/Rune
cosmetic record, swaps only the one existing LeftHand `BoneAttachment3D` child,
and never applies the fallback bow's blanket brown tint to Wayweaver. The Trophy
Hall mount is a read-only host projection (`covered → empty → full`), never a
second item authority.

The bounded art deliverable is one textureless Blender-authored rigid GLB,
targeting at most 150 KB, one mesh, two to four matte materials, and no Meshy
spend. It is an asymmetric dark-waysteel crescent with warm root-sap cord, pale
Quiet-Tooth grip, and one bright strand as the sole saturation peak. Component,
weapon, and mount icons remain required. Full legacy armor/weapon attachment is
outside this slice.

### D8 Slice 4 Map of Nine Knots ritual architecture decision — 2026-07-18

**Locked after a Terra production-path audit, Sol revision, Terra response, and
root decision.** The strict fresh title-to-Wayweaver Web route exposed two real
gameplay gaps: no production interaction records the Map of Nine Knots, and no
production source teaches `unwritten_road_boss`. Tests that supplied either fact
directly were not release evidence.

The existing physical Threefold Loom now owns two sequential authored stages.
Its first folio remains the Root Below lesson. After that lesson, the same
scanner target presents `waiting → ritual_ready → map_recorded`; no second Loom,
generic Chart source, or parallel quest authority is introduced. The ritual's
requirements remain exactly Fire in the Bough cleared, five Lost Waymarks,
Past Thread, Present Thread, and Wayfinding 23. Root Runes, Wyrm Scale,
Huntcraft, final materials, and final-clear state do not gate the Map. Runes and
the Map remain independent final-Table witnesses.

One host-only convergent `Game` transaction re-reads live truth, records the Map
through `CampaignData.record_map_of_nine_knots`, and atomically reconciles the
final rumour, known recipe, and existing `source_lesson` discovery provenance.
It spends and grants no item, material, Thread, Rune, Waymark, XP, or gold. A
fresh record and a trusted v6 Map missing knowledge both converge in one save
boundary; a complete repeat is a true no-op with no revision, signal, toast,
publish, or save. Any change increments the Chart Table revision once, emits
only the signals whose data changed, saves once, then republishes Town once.

A dedicated parchment panel shows the five requirements and requires an
explicit **Trace the Map** action; closing prose never mutates campaign state.
Guests receive only a neutral `threefold_loom` view inside the existing host
settlement snapshot, see a read-only panel, and have no ritual RPC or local save
mutation. The final Web driver must reach the Loom through the shipped player
scanner, press the real panel Button, observe Map plus final recipe provenance,
then open the physical Chart Table and prove the final witness rows. Calling the
Game transaction directly is not valid browser acceptance.

### 2026-07-19 stopping point — D7 hardened, D8 core implemented, Web gate open

This is the recorded stopping point for the current orchestration run. It does
not mark the umbrella Wayfinder goal complete and it does not advance work into
a new release slice.

The D7 native path is accepted after three late production defects were closed:

- Every delayed or deferred Far return now carries immutable World generation,
  World instance, stage, and Chart-instance ownership. Waiters revalidate after
  every yield and one claimant may mutate a generation. A five-case regression
  covers stale callbacks, deferred drivers, duplicate claims, and the Giant
  authorization rebind.
- An exact tier-2 `briar_maze` with no generated gather candidates may satisfy
  the prior-saga harvest leg only through append-only scanner evidence for ore,
  forage, and logs. Any visible candidate with zero harvested delta still fails;
  required-biome and gather-spawn-affix layouts cannot use the exception.
- Dialog panels own and release their modal lease exactly once, including when
  freed through `_exit_tree`, preventing later World transitions from remaining
  paused.

The authoritative combined D7 native route passed 5/5 in 458 seconds and
visited 52 of 60 World legs. The focused ownership, status/Far-return,
authored-no-gather, boot, transition, and dungeon suites are green, and Sol's
reviews found no remaining P1/P2 blocker in these changes.

The Web Mire diagnostic was isolated with four fresh headed Chrome variants.
Both MSAA settings produced six framebuffer-blit diagnostics when the dynamic
bog ReflectionProbe was present and zero when it was absent. Production now
skips only that probe on Web; native Mire still creates exactly one. A direct
fresh Web Mire reached World ready with the configured 4x 3D MSAA and zero raw
warnings or blit errors, while the wet-floor/material read remained intact.

Release export r14 is at `wyrd/build/web-r14`. Its isolated PCK audit passed
111/111 resources. `index.pck` is 123,717,744 bytes: 5,732,956 bytes over the
117,984,788-byte baseline and 2,655,652 bytes below the 126,373,396-byte D8
cap. The strict fresh D7 browser run was started against this export, but its
monitor process was lost mid-run during a tool/context boundary. The Chrome
target subsequently exited. Because the missing interval's console diagnostics
cannot be reconstructed, this attempt is **not certified**, regardless of how
far the in-page driver may have progressed.

D8's accepted native implementation now extends through the mastery-component
chain, authoritative Forge transaction and persistence, unique Wayweaver item,
equipped weapon attachment, room-owned Thread echo reducer and co-op receipt
path, Town/Trophy projection, Root Rune cosmetics, and the production Map of
Nine Knots Loom ritual/final lesson. The independent D8 release route has not
been certified in a browser.

The next work item is deliberately singular: rerun r14 from a fresh save under
an uninterrupted 900-second strict D7 monitor and accept it only if the harness
passes with zero browser warnings, errors, assertions, or exceptions. After
that—and not as a substitute for it—run the separate fresh title-to-Wayweaver
D8 release-Web marathon. The real two-process ENet check and remaining bounded
production art are still release gates.

### 2026-07-19 r17-r20 D7 progression and production-gate hardening

**Decision.** The fresh release route now treats the exact authored Wayfinding
ledger and the gathering Trades needed by each generated World as separate
contracts. Support Trades are derived from Chart recipes, recursive Ink inputs,
and the generator's effective biome-resource manifest. They are earned only by
real renewable Town gathering and Forge transactions; they never open a Green
practice Chart or change Wayfinding XP.

The resulting just-in-time targets are Golden WC10, Queen EC3, Pale entry
EC18/WC18, Pale boss EC18/WC19, and Fire entry EC18/WC20. Fire's former
post-five-verses WC20 grind was invalid because the preceding Ashen Worlds must
already harvest Embersage for Emberleaf Ink. The gate therefore moves before
Ashen 1 while the mix itself remains after the five Verses.

**Deviations found by release Web.** r17 exposed a source-order race at Mara's
rain note and a deferred run-debrief owner gap. r18 exposed missing cumulative
scanner proof before an authored empty Briar. r19 cleared both and then reached
Queen's Summit, where Refined Ink requested locked Bogiron at EC1. Council audit
showed the same problem extended to Pale and Fire's promised biome resources,
so the fix is data-owned rather than a Queen-only literal.

**Tradeoffs.** The D7 QA lease accelerates renewable node channel/respawn dwell
but never writes XP or materials. Its Wildcraft support loop is bounded by 240
successful gathers, 100 consecutive no-progress sweeps, and 60 seconds of real
monotonic time. Invalid/cyclic production data fails closed at the route rather
than becoming an empty target that could pass vacuously.

**Verification before r20.** The focused production suites pass 18/18
progression, 5/5 fresh First-Knot-to-Golden, 5/5 Golden handoff, 9/9 prior-saga
evidence, 18/18 procgen including 30 Mire seeds, and all focused Pale/Fire/Root
resource checks. The four required gates remain green at 426/426, 41/41,
134/134, and 72/72. Sol's final review found no remaining P1/P2 issue in this
support-gate slice.

**Follow-up.** Export r20, pass the isolated PCK/size gates, then certify two
independent fresh D7 browser marathons before moving to the strict D8 route.

### 2026-07-19 animation, first-arrival, and ranger-bow correction

**Council decision.** Terra's asset/runtime audit found that the shipped chibi
player already owns idle/walk/run/dash sidecars, while the current rigged
skeleton, ghost, hedge creature, and Hedgemother assets expose only an Idle
clip. Their bind pose is a T-pose, so delaying the first AnimationPlayer
evaluation could flash that pose even though runtime Idle was available. Sol's
bow review also found that the D8 presentation fallback had enlarged and
rotated the previously calibrated shortbow. The accepted immediate slice fixes
runtime presentation without pretending that missing authored locomotion clips
have been created.

Player and resolved creature Idle clips are now evaluated synchronously before
their first rendered frame. Town sidecar poses use a narrow manual time scrub
for breathing and weight shift instead of a permanently paused walk midpoint.
Actual enemy walk/run/attack sidecars remain a Meshy/Blender deliverable; this
runtime seam prevents bind-pose flashes but cannot manufacture those clips.

The first Town arrival now stays behind an opaque **Opening the way…** cover
until `RenderingServer.frame_post_draw` proves a complete Town frame reached
the renderer. The cover then fades before the authored camera vignette begins,
and the first save moves to the end of the vignette. A cold Metal process
measured 2637.0 ms to scene-ready and 17284.2 ms to its first submitted frame;
the immediately repeated process measured 2564.9 ms and 2675.6 ms. This
isolates the severe first-ever hitch to shader/pipeline compilation rather than
the camera timeline. The persistent map-loading layer now processes while the
destination is paused, preventing an immediate Town debrief from freezing its
fade and travel lock. Modal dismissal also owns Esc until key release, so the
same input cannot close dialogue and open Pause beneath it.

The Web export no longer explicitly packs six source JPG/PNG files already
embedded in the three Town-building GLBs. The release PCK fell from 123,752,420
to 93,753,440 bytes, a 29,998,980-byte / 24.2% reduction, while its isolated
audit still loads all 111 release resources. This reduces transfer and decode
pressure, but Web Compatibility cannot use Godot's native shader baker; the
first-render cover is therefore still required.

The familiar bow is calibrated to 0.50 scale (~0.95 m from a 1.902 m source)
and Wayweaver to 0.40 (~0.96 m from a 2.392 m source), both upright with no
obsolete +90° X rotation. Basic Shot now enters an asymmetric bow/string-arm
pose for 70 ms before the arrow exists, and the visible bow flexes across its
limb-width axis on release. The runtime test proves pose-before-projectile.
This is a procedural bridge: the current GLBs have no deforming limb/string rig,
and a final hand-to-cheek draw plus moving string must be authored and exported
against the canonical humanoid rig rather than claimed as complete here.

**Verification.** Required native gates pass at 426/426 loop, 41/41 dungeon,
134/134 transitions, and 75/75 Skills. The Wayweaver presentation runtime passes
21/21. The fresh-arrival capture proves the cover, post-draw reveal, and active
vignette. Native Town startup remains inside its 250 ms post-prewarm budget at
88.3 ms. Web export, 111-resource PCK audit, and semantic smoke-probe validation
pass; the previously required uninterrupted D7/D8 release-browser marathons and
two-process ENet check remain open umbrella gates.

### 2026-07-19 r21-r28 release-marathon continuation

**Late prior-saga production fixes.** The Queen route's four approaches now
derive their exact support requirements from production data and preserve the
required combat-before-gather order. The Wolf route produces one real rare gear
Pickup, the player collects it through the shipped world-pickup action, returns
to Town, opens Hod's physical VendorPanel, and sells the exact row once for the
Queen component budget. Sell rows therefore own stable names and item metadata;
the D7 receipt proves the item, value, inventory delta, persistence, and
single-sale boundary rather than injecting four gold.

Briar's apparent scanner failure was instead a Trade-locking failure. The
accepted exception is deliberately narrow: an exact authored `briar_maze` with
no eligible generated gather target receives one reachable tier-2 gather anchor,
Wildcraft 3 remains a real Table/World gate, and Earthcraft 3 is prepared through
renewable Town mining and Forge transactions. Recipe support planning reads the
Earthcraft requirement, but the physical Chart Table still does not itself
enforce `req_earthcraft`; closing that UI/domain seam is a follow-up rather than
a hidden claim of this route.

**UI and transition seams.** D7's physical Forge steps were migrated from the
retired direct recipe control to the shipped CraftPanel transaction: select the
named recipe row, then press `PrimaryCraftAction`. Copper, Bogiron, Fire inputs,
and Starheart Alloy all use that route. A shared Far Waystone invariant now
treats return as committed when either Town owns the scene or the exact old
World Waystone reports `used=true`. Multi-fold **Return safely** checks that
receipt synchronously before a scene transition can invalidate the World owner;
an unopened depth choice and every genuinely stale target still fail strictly.

**Web packaging.** The source brand icon remains outside the release pack. Six
external Town-building texture dependencies were added explicitly for Maud's
Hearth, Hod's Smithy, and the Chartmaker Tower. Packing their original 2048px
imports exceeded the 126,373,396-byte cap, so exactly those six runtime imports
use a 1024px size limit while the source images stay untouched. This is an
intentional distant-building fidelity/download tradeoff. r25 then measured
104,634,088 bytes and r26 measured 104,635,624 bytes with the isolated PCK audit
green at 111/111 resources and no missing-building-texture browser diagnostics.

**Release evidence and defects found.** r25 reached the Golden deep return and
found that the multi-fold helper rejected a valid `used=true` old-World receipt;
the shared commit invariant above closed it. r26 then completed First Knot,
Golden Wallow (including Deep Hollow), all Briar, Wolf, Queen, Pale Veins, and
Jarl settlement paths before the Fire-entry gate reported 3581 XP instead of the
authored 3496.

The extra 85 was not a Pale reward. It was one post-Golden legacy Green Hollow
practice return (`75 + one bad Affix at 10`) triggered when Briar's new
Earthcraft-3 support requirement entered full Chart training. Baking 3581 into
the campaign would be incorrect because that legacy payout varies by Affix.
Seventh Road now waits for stable Town control, reaches Earthcraft 3 through the
real Forge, and only then considers a training fallback. Wayfinding stays exactly
2016 across that handoff. A data-derived 30-entry award ledger and query-only
per-award receipts preserve the authored lane `3496 -> 3840 -> 4200` and expose
any future stray source/delta without entering persistence.

r27 is preserved at `wyrd/build/web-r27`. Its semantic probe and isolated PCK
audit passed; `index.pck` is 104,643,000 bytes. The fresh browser marathon proved
the XP fix through all four Pale Veins and reached the Pale Oath boss with exact
award receipts. It then found a separate third-bell relief race: the legacy D6
scanner helper could report success after a no-action or wrong-target input edge,
while the host correctly left relief three unbanked. The first diagnostic also
had a string-format precedence error that hid the action-time state. A focused
real Player/InputMap/Bell/controller repro captures this in about three seconds;
the narrow receipt-aware repair requires a live, unstunned player, arms the exact
bell in PlayerController, accepts only a fresh exact-target receipt plus the
matching host `relief_committed` signal, and fails closed on a final-edge
retarget. Its focused regression passes the three direct reliefs, bounded first-
edge stun recovery, exact phase-two commit, and phase-three retarget rejection.
The malformed diagnostic now formats the whole message and retains action-time
distance/evidence before restoring the player.

r28 is preserved at `wyrd/build/web-r28`. Its semantic probe and isolated PCK
audit passed; `index.pck` is 104,655,340 bytes. The fresh browser marathon
confirmed the exact XP ledger and then passed all three live Jarl bell reliefs
and canonical Jarl settlement with no warning or exception. It found the next,
separate boundary during the scheduled post-Jarl return: the intended exit
Waystone remained unused while the scanner owned the nearby abandon stone, and
the last interaction receipt still named `OathBell2`. The route failed closed as
`interaction_did_not_settle`. This exact exit/abandon ownership collision is the
single next D7 release blocker; r28 is not a certified complete D7 release.

**Verification at this checkpoint.** Focused suites pass 20/20 progressive XP,
3/3 Golden-to-Seventh handoff, 4/4 cumulative Trade training, 6/6 Far-return
status/depth, 5/5 stale-return ownership, 6/6 Jarl scanner/host regression,
10/10 scanner target integrity, 16/16 Pale Oath World, and 10/10 Pale Oath Game
runtime. The required core gates were last
green at 426/426 loop, 41/41 dungeon, 134/134 transitions, and 75/75 Skills.
Craft/UI transaction, modal/icon, and theme contracts are green. No change from
this continuation is committed or pushed.

**Council follow-up.** The Jarl currently continues inherited Boss attacks while
vow-shielded and the player is ringing the Oath Bells. The release harness must
remain safe under real stun/retarget pressure and must not disable that AI for
QA. Separately decide whether the intended “alternate combat with bell relief”
experience should pause Jarl attacks during the relief phase; that is a gameplay
rule and co-op design decision, not part of the narrow scanner repair.
