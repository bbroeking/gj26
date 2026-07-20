# Web smoke

Run `./tools/web_smoke.sh`, open the printed URL in Chromium, and click
**New Game**. The query-gated QA route exercises the release export's real
`Main.tscn → Town.tscn → World.tscn → Town.tscn` path with a Snug Chart.

For the Chart Table/Codex gate, open the second printed URL:
`?wyrd_smoke=snug&wyrd_ui_smoke=codex`. It instantiates the real Chart Table in
Town, presses the real Codex Control, verifies six focusable pages, closes the
Codex and table, then runs the same generated Snug transition. The injected
probe fails closed unless its required UI phases are present.

The milestone release is also public at
`https://bbroeking.github.io/gj26/play/`; append `?wyrd_smoke=snug` to exercise
the same query-gated route against the deployed files.

Pass conditions:

1. The title renders and accepts the New Game click.
2. Town renders without a script/resource error.
3. A Snug World builds with the Compatibility renderer.
4. The completion path returns to Town.
5. `window.__wyrdSmoke` reads
   `{phase: "complete", history: ["title", "town", "world", "complete"]}`.
6. The Chromium console has no missing-resource, GDScript, or JavaScript error.

The enhanced Codex route must instead report:
`title → town → chart_table → codex → chart_table_closed → world → complete`,
and `window.__wyrdSmokeHarness.status` must be `passed`.

## Slice D1 First Knot campaign route

The fourth printed URL uses `wyrd_ui_smoke=d1`. It is a fresh-host campaign
acceptance route, not a campaign-state fixture. Its fail-closed ordered
subsequence is:

`title → town → world → green_world_1 → green_hollow_1 →`
`green_world_2 → green_hollow_2 → green_world_3 → green_hollow_3 →`
`chart_table → boss_preview → boss_world → boss_cleared →`
`homecoming_hall → homecoming_atlas → homecoming_inspected → complete`

Before each physical Green Hollow and the Boss Chart it earns six Wild Herbs
from authored Town patches and stages them with the actual Chart Table pot
Controls. Each exact known Hedge Ink pot settles automatically on its third
supply press (an unknown exact pot instead requires the shipped **Try the Mix**
Control); the driver proves the exact six-Herb spend and two-Ink yield. The
first three Green Hollows are each staged and committed
through the physical table; each must have a distinct newly materialized
`chart_instance_id`, complete a real World return, and bank exactly one Thorn
Whisper. The third return is the only route that supplies missing Thorn
Essence; an existing Essence is never duplicated.

At Wayfinding 8 the real Table stages Field Parchment (Base), Hedge Sprig
(Waymark), Loop Cord (Binding), one visible Hedge Ink, and Thorn Essence in
the Seal cell. The preview must name **Hedgemother's Den**, promise the
Hedgemother, show the exact spend and the one-Seal abandon/unresumable-return
safeguard. Pressing the shipped **Inscribe Chart** Control must call
`Game.try_inscribe_chart`, create canonical `first_knot_boss` provenance, and
hold Thorn Essence in `case` escrow; socketing moves it to `in_run`.

The exported World must build the actual Hedgemother from that contract. The
probe verifies the World config and real boss death callback settle the host
resolver once: the Seal tombstone is `consumed`, Tusker Tusk, Green Root Rune,
and Trophy Hall arrive once, and the ordinary return cannot reward or refund a
second time. After that real Town return, it waits for the ordinary return
debrief and then the Homecoming debrief to release control (closing only their
real dialog completion actions when necessary). It requires exactly one live
`FirstKnotTrophyHall` with its Green Root Rune, Tusker record, and covered
bow-rest nodes; the Town Living Atlas must report
`homecoming_handoff_visible() == true`. The driver then uses the player scanner
and shipped `interact` action on the Hall, requires `TrophyHallInspectDialog`,
and proves deep-copied campaign state and materials are unchanged after the
inspection.

The route reports fourteen required production flags, so phase names alone
cannot pass: table interaction/Green commit, production Ink mixing, Boss
preview/`try_inscribe_chart` escrow, World boss, host death resolver,
terminal-return idempotence, stable Homecoming modal control, live Hall and
Atlas projection, scanner-driven inspect dialog, and copy-only inspection.

The D1 probe budget is 180 seconds. Run it from an origin/profile with no prior
Wayfinder Web save; the title's journey button may restore an existing browser
save and therefore is not by itself a clean-state guarantee. Inspect both
`window.__wyrdSmoke` and
`window.__wyrdSmokeHarness`; the latter must become `passed`. Capture the Boss
preview and World/boss-cleared states if the browser runner supports
screenshots. As with C2, any browser console warning or error, missing
resource, GDScript diagnostic, or `Parameter "material" is null` is a failure.

The 2026-07-17 D1 export measured 116,543,144 B (`index.pck`), 37,695,054 B
(`index.wasm`), and 115,730,132 B for the PCK at gzip -9. The D1 Town-model
manifest includes Maud's Hearth, Hod's Smithy, and the Chartmaker Tower with
their `Image_0`/normal sidecars, plus Mara, Hod, and Quill's rigged, texture,
and walk-animation assets; omitting any of those preload dependencies prevents
Town from parsing in the release even though native tests pass.
The route is longer
than C2 because it channels six real herbs before each of four Charts; a slow
renderer can approach the 180-second watchdog. Re-measure after a Web asset
manifest or import change and retain the captured Boss preview/World images
with the observed phase history.

**Homecoming extension accepted 2026-07-18:** from a fresh browser origin, the
release completed the exact 17-phase D1 sequence above and reported all 14
required production flags. The ordinary return panels and final Homecoming
panel were released only through their real `_finish` actions; the Hall was
acquired by crossing the player's real scanner boundary, opened through the
shipped `interact` action, and left deep-copied campaign/material state equal.
The accepted browser session contained 74 console entries with 0 warnings and
0 errors. If the three clue returns finish below Wayfinding 8, the query-gated
driver earns the remainder through ordinary Tier-1 returns; it never injects XP
or relaxes the Boss Chart gate.

The preserved `build/web-homecoming-qa` release measures 116,179,344 bytes for
`index.pck`, 37,695,054 bytes for `index.wasm`, and 5,890 bytes for `index.html`;
gzip measurements are 115,368,591 and 9,435,036 bytes for PCK and WASM. All 31
native `test_*.gd` entrypoints passed serially after the Web acceptance.

## Slice D2 First Knot Reprise route

The fifth printed URL uses `wyrd_ui_smoke=d2`. It is a query-gated replay
acceptance route. It begins with an explicit `d2_prerequisite_fixture` that
sets only prerequisites already covered by the separate fresh-host D1 route:
First Knot cleared, Wayfinding 21, the entitled known Reprise recipe, and its
exact table inputs (Field Parchment, Hedge Sprig, two Loop Cords, Hedge Ink,
and Thorn Essence). It is deliberately not evidence that a fresh player earns
those prerequisites; D1 remains that proof. The fixture flag is required by
the browser probe and is reported before the table opens.

From the real Town Chart Table onward, this route has no state shortcut. The
player scanner opens the authored Table through the shipped `interact` action,
the real supply Controls stage the Reprise, and the actual **Inscribe Chart**
Control calls `Game.try_inscribe_chart`. The probe requires this ordered
subsequence:

`title → town → d2_prerequisites → chart_table → reprise_preview →`
`reprise_committed → reprise_layer_1 → exit_waystone → deepen_choice →`
`reprise_layer_2 → terminal_hearth → reprise_boss_world →`
`reprise_boss_cleared → reprise_return → complete`.

Layer one must be boss-free. The driver reaches the real non-abandon Exit
Waystone through the interaction scanner, opens its real Far Waystone dialog,
and presses its actual **Press deeper** Control. Layer two must contain and
interact with the authored terminal Hearth, then build the contract-guaranteed
Hedgemother. The death path is the live `Combatant.take_damage`/`died`
callback: it must leave exactly one seeded unique First-Knot Heirloom pickup
and reject a duplicate reward claim. The route exits through the real final
Waystone and proves the Reprise is campaign-inert: no chapter, escrow, relic,
restoration, Tusker Tusk, Ledger, or Thorn Essence refund change occurs.

The D2 browser budget is 240 seconds. Require both `window.__wyrdSmoke.phase`
of `complete` and `window.__wyrdSmokeHarness.status` of `passed`. The latter
requires the explicit fixture flag plus real table, waystone-choice, terminal
Hearth, boss/reward, and inert-return feature evidence; phase names alone
cannot pass.

**Accepted 2026-07-18:** the release build completed the exact 15-stage route
above with all 11 required feature flags and 0 warning/error console entries in
the accepted browser session. The exported artifacts were 116,160,380 bytes
for `index.pck` and 37,695,054 bytes for `index.wasm`; gzip-9 measurements were
115,349,926 and 9,379,534 bytes respectively. The PCK remains the shipping-size
bottleneck and belongs to the later Web startup/asset profiling slice; D2 adds
acceptance coverage, not a claim that final download budgets are met.

## Slice D3 Golden Wallow route

The sixth printed URL uses `wyrd_ui_smoke=d3`. It starts at an explicit,
accepted First Knot Homecoming fixture, then drives the entire new Golden
Wallow chapter through production controls. The fixture supplies only the
prior chapter truth, level prerequisites, and bounded making stock; it does not
bank Golden clues, discover either new Chart, manufacture Mire Ink, clear the
Boar, or settle the chapter.

The player's real scanner reads the Living Atlas source. Three distinct
**Sallow Shallows** Charts are staged and committed at the physical Table,
opened as real World scenes, and returned through the production settlement
path to bank three Gilt Bristles. The Table's Mix workspace then combines
Bittergrass, Mothmint, and an owned Hedge Ink through its real Controls to
discover and make **Mire Ink**. Finally, the Table stages the guaranteed
**Burrow Boar's Wallow** preview, commits Tusker Tusk through Story-Seal escrow,
and opens a real World whose production Boar death callback performs the
exact-once settlement.

The required ordered subsequence is:

`title → town → first_knot_homecoming → shallows_source →`
`shallows_table_1 → shallows_world_1 → shallows_return_1 →`
`shallows_table_2 → shallows_world_2 → shallows_return_2 →`
`shallows_table_3 → shallows_world_3 → shallows_return_3 → mire_ink →`
`boar_preview → boar_world → boar_cleared → golden_hall → golden_atlas →`
`sallow_jetty → complete`.

The probe additionally requires thirteen feature flags proving the bounded
fixture, real Atlas read, physical Shallows and Boss Table work, production
Mire Ink controls, Boar contract/death settlement, and live Trophy Hall,
Living Atlas, and Sallow Jetty projections. Phase names alone cannot pass.

**Accepted 2026-07-18:** a fresh release export completed all 21 phases and all
13 feature proofs with 0 browser warning/error entries. The accepted artifacts
in `build/web-golden-qa-r4` measure 116,598,040 bytes for `index.pck`,
37,695,054 bytes for `index.wasm`, and 5,892 bytes for `index.html`. This run
also proved the Jetty GLB is present in the Web export and caught a production
Table bug: authored recipes may consume an Ink as an ingredient, so owned
Hedge Ink must remain visible in Mix while unrelated Inks and protected Chart
supplies stay hidden.

## Slice D4 Seventh Road route

The seventh printed URL uses `wyrd_ui_smoke=d4`. It begins at an explicit
Golden Wallow settlement fixture: First Knot and Golden Wallow are already
cleared, their Root Runes and restorations are present, Wayfinding is 15, and
Wildcraft is 13. This prerequisite boundary is covered by D1 and D3. D4 does
not inject Seventh Road clues, Mothglow Ink, Wolf completion, Archive knowledge,
Alpha Fang escrow, or Queen completion.

The real Living Atlas source grants its missing-only Briar lesson. Four
distinct **Briar Maze** Charts are then staged and committed at the physical
Table, built as real World scenes, and returned through production settlement.
Each World must carry the next exact `seventh_road_cold_track_1..4` identity
with the `cold_track_clue` presentation; none is the spendable `cold_track`
Chart component. The fourth return opens the Wolf recipe and supplies its one
protected Wightpelt.

The production copper pot next proves the Mothglow boundary twice with the
same exact two-Mothmint/one-Hedge-Ink measure. At Wildcraft 13 the **Try the
Mix** Control must report the level-14 requirement and spend nothing. At
Wildcraft 14 the same Controls discover and settle exactly one Mothglow Ink.
The Table then previews and commits **Wolf Alpha's Seventh Road**, including
the guaranteed Wolf, Wightpelt escrow, Wildcraft-14 preparation note, and
abandon refund safeguard. The real Wolf death callback consumes that escrow
once, awards Alpha Fang, sets the Fang Root Rune, and restores the Skald
Archive.

In returned Town, D4 requires the Seventh Road records in the Trophy Hall and
Living Atlas plus the live Skald Archive. The player's scanner opens the
Archive through the shipped `interact` action; closing its review dialog invokes
the atomic source transaction. Its missing-only Summit lesson tops one existing
Cold Track to two, grants one missing Atlas Folio, and leaves two already-owned
Climbing Cords unchanged.

Finally, D4 proves compatibility without secretly preserving the retired Table
recipe. It installs two deliberately frozen, v2-shaped legacy **Queen's
Summit** Charts with their Alpha Fang already held in `case` escrow. The first
builds the guaranteed Queen and is torn at the real entry-side abandon
Waystone; the old tombstone becomes `refunded` and returns exactly one Fang.
The second frozen record receives a distinct escrow identity, enters its real
World, and Queen death consumes it. Neither frozen record may create a
Queen's Summit chapter, Crown-Thorn, Oath Nail, Crown Root Rune, Pale Stair, or
Town settlement truth.

The required ordered subsequence is:

`title → town → golden_wallow_settlement → briar_source →`
`briar_table_1 → briar_world_1 → briar_return_1 →`
`briar_table_2 → briar_world_2 → briar_return_2 →`
`briar_table_3 → briar_world_3 → briar_return_3 →`
`briar_table_4 → briar_world_4 → briar_return_4 →`
`mothglow_blocked_13 → mothglow_mixed_14 → wolf_preview → wolf_world →`
`wolf_cleared → seventh_hall → seventh_atlas → skald_archive →`
`summit_lesson → legacy_case_1 → legacy_world_1 → legacy_refunded →`
`legacy_world_2 → legacy_consumed → complete`.

The D4 browser budget is 300 seconds. `window.__wyrdSmokeHarness.status` only
becomes `passed` when all 30 phases and all 20 fixture/production feature flags
are present; phase-only completion fails closed. Its legacy fixtures disclose
the historic sealed Chart state; only Alpha Fang is refunded after abandonment.

**Accepted post-review 2026-07-18:** a fresh release export completed all 32
phases and all 20 required production proofs in Chromium. The first Summit was
abandoned through a literal `E` press on the real entry Waystone; the retry
received a new escrow identity and Queen death consumed the second handoff.
The semantic harness reported `passed`. The artifacts measured 116,636,580
bytes for `index.pck`, 37,695,054 bytes for `index.wasm`, and 5,890 bytes for
`index.html`.

## Slice D5 Queen's Summit route

The eighth printed URL uses `wyrd_ui_smoke=d5`. It begins at an explicit
post-Seventh Road fixture: prior chapters, their settlement projections,
Wayfinding 17, one already-earned Alpha Fang, and bounded ordinary Table
makings. It does not grant Crown-Thorns, Queen clearance, Oath Nail, Crown
Root Rune, or Pale Stair truth.

The live Skald Archive is opened through the player scanner and its shipped
interact action. Closing its normal dialog earns the missing-only Crownward
lesson. Four distinct **Crownward Ascent** Charts are then staged and committed
at the real Inscribing Table with two Cold Tracks, Atlas Folio, paired Climbing
Cords, and one visible Refined Ink. Each World is boss-free, returns normally,
and banks the next exact `shed_crown_thorn_1…4` record.

The fifth physical Table transaction stages **Queen's Summit** with Cold Track
northwest, Thorn Rubbing north, Atlas Folio centre, paired Climbing Cords, one
visible Refined Ink, and Alpha Fang in the Seal. Its canonical contract forces
the Queen and holds only the Fang in `case → in_run → consumed` escrow. The
production death callback must settle exactly one Oath Nail, Crown Root Rune,
and Pale Stair. The route then opens and closes the real Pale Stair dialog
twice, proving its repeatable reading is copy-only and remains not walkable.
It returns to Town and requires the Queen record in the Trophy Hall, Crownward
mark in the Living Atlas, and post-Queen page in the Skald Archive.

The fail-closed phase subsequence is:

`title → town → post_seventh_settlement → archive_source →`
`approach_table_1 → approach_world_1 → approach_return_1 →`
`approach_table_2 → approach_world_2 → approach_return_2 →`
`approach_table_3 → approach_world_3 → approach_return_3 →`
`approach_table_4 → approach_world_4 → approach_return_4 →`
`queen_preview → queen_world → queen_cleared → pale_stair_twice →`
`queen_hall → queen_atlas → queen_archive → complete`.

The D5 browser budget is 300 seconds. Its thirteen feature proofs reject any
phase-only report and require the disclosed fixture plus real Archive, Table,
World, canonical settlement, repeated Stair read, and Town projections. Native
save tests own the separately exhaustive abandon/recovery/refund matrix; D5
keeps release-browser proof focused on the full canonical `case → in_run →
consumed` journey.

## Slice D6 Pale Oath final-export route

D6 uses its own strict URL: `?smoke=1&ui=d6`. The legacy
`wyrd_smoke=snug&wyrd_ui_smoke=d6` spelling deliberately does not enable it.
Start from a fresh browser origin. Its only disclosed fixture is canonical
Queen-complete prior-chapter truth; it supplies no Pale Oath clue, Chart,
Oath-Nail escrow, Oath-Rubbing result, reward, Past Thread, Pale Root Rune, or
Rootroad Lift restoration.

The exported game physically reads the Pale Stair breadcrumb and the real Skald
Archive source/boss folio, uses the Inscribing Table to commit four Pale Veins
Charts, and completes each real World return. Those returns must bank the four
distinct Oath-Rubbing ledger facts. The same Table then previews and commits
**The Pale Oath** with its Oath Nail in actual `case → in_run → consumed`
escrow; it may not manufacture a boss handoff directly.

The Barrow Jarl World proves all three host-validated bell reliefs in order
before the real clear. Its normal settlement must leave exactly one Starheart
Coal, Pale Root Rune, Past Thread, and `rootroad_lift` restoration, with the
Nail at zero. Returned Town inspection includes the functional Rootroad Lift,
Hod's oath-stone, Trophy Hall, Living Atlas, and Skald Archive. Finally the
driver equips Driving Volley and hits a valid ordinary target, proving the
real collision-safe displacement rather than just observing the unlock.

The probe accepts only this ordered subsequence:

`title → town → queen_complete_fixture → pale_stair → archive_source →`
`pale_veins_table_1 → pale_veins_world_1 → pale_veins_return_1 →`
`pale_veins_table_2 → pale_veins_world_2 → pale_veins_return_2 →`
`pale_veins_table_3 → pale_veins_world_3 → pale_veins_return_3 →`
`pale_veins_table_4 → pale_veins_world_4 → pale_veins_return_4 →`
`pale_oath_boss_folio → pale_oath_preview → pale_oath_world → jarl_relief_1 → jarl_relief_2 →`
`jarl_relief_3 → jarl_cleared → rootroad_lift → oathstone →`
`pale_oath_hall → pale_oath_atlas → pale_oath_archive → driving_volley →`
`complete`.

It also requires all sixteen D6 proofs: canonical fixture, real Stair and
Archive reads, real Table commits/four loops/four Rubbings, boss preview and
escrow, Jarl World and three host-validated reliefs, exact settlement,
Lift/oath-stone and Town projections, equipped Volley and real displacement,
and the gameplay-driver assertion. Completion with phase names alone fails
closed. The driver itself must reject every prohibited Pale Oath injection;
the probe never treats a reported phase as proof of an injected state.

The D6 budget is six minutes. `window.__wyrdSmoke.phase` must be `complete`
and `window.__wyrdSmokeHarness.status` must be `passed`. Chromium console
warnings and errors are both failures, including missing resources, GDScript
diagnostics, and `Parameter "material" is null`.

`web_smoke.sh` exports first, then mounts `index.pck` from the isolated
`tools/pck_audit_project`. That audit loads every required Rootroads/Jarl/
Oathbound GLB and UI icon, and resolves every production-script remap, from the
actual PCK. It proves virtual paths and generated import/remap rather than trusting
`export_presets.cfg`. Keep the audit green whenever a Pale Oath asset or its
dependency changes; the PCK remains the likely Web download/startup risk.

**Accepted after the final Sol lifecycle repair, 2026-07-18:** the fresh
release completed all 32 ordered phases and all 16 required production proofs.
The browser recorded 72 entries with 0 warnings and 0 errors. The isolated PCK
audit loaded all 55 required resources and measured `index.pck` at 117,332,168
bytes. This rerun includes the repaired live Oathbound dormancy/Reeling states,
sender-bound bell authority, and phase-correct bell models; the focused native
world regression passed 16/16 and the complete serial native gate passed all
54 entrypoints.

## Slice D7 Fire in the Bough final-export route

D7 uses its own strict URL: `?smoke=1&ui=d7`. The legacy
`wyrd_smoke=snug&wyrd_ui_smoke=d7` spelling deliberately does not enable it.
D7 starts at the real title and presses **Begin a New Journey**, so the full
prior saga, its Trade levels, every source lesson, all Charts, the Past Thread,
the Rootroad Lift, and the Starheart Coal must be earned through production
transactions. It injects no campaign, Trade, material, Chart, source, escrow,
reward, restoration, Skill, or manifest state.

The player scanner reads the real Rootroad Lift's ordinary folio and proves the
landing lowered. Five distinct **Ashen Bough** Charts are staged and committed
at the physical Table, socketed through the real Town Waystone, opened as real
Worlds, and returned through the real Far Waystone. Each carries the next exact
`ember_verse_1…5`; the first World
also proves Pack Reader displays the immutable, materialized elite manifest
without rerolling it. The same physical Lift then teaches the Giant folio, and
Quill's real Copper Pot discovers and settles Emberleaf Ink from two Embersage,
Wellwater, and Ash Ink.

The boss Table transaction must visibly force the Hearth Giant and hold only
Starheart Coal in `case → in_run → consumed` escrow. In the actual World, D7
forces all three heat floors, proves an out-of-order Braided Link is a
recoverable unbanked hazard, then banks Hollow, Braided, and Knot Link through
the host-authoritative controller. The Giant kneels rather than dying; exact
settlement leaves zero Coal and one Wyrm Scale, awards Ember Root Rune and
Present Thread, and restores the functional Ember Kiln with its inert
Threefold Loom foundation. D7 opens that real Kiln and crafts exactly one
Starheart Alloy from renewable inputs. It also takes the production Hunter's
Lodge Threadstep lesson and proves one rejected no-spend step and one accepted
authoritative step.

**Owned-clock amendment (2026-07-19):** the strict fresh-save marathon keeps
its fifteen-minute (900-second) **monotonic real-wall** budget, with a target
of 750 seconds or less. It may use exactly 6× simulation time only after the
real `fresh_campaign` report, only through the single `d7_smoke_clock` owner,
and never above 6×. This is not a fixture or gameplay shortcut: all production
inputs, scanner interactions, Table commits, World callbacks, combat results,
and campaign truth remain live.

The owner captures the prior positive scale, restores it before it publishes a
terminal report, restores it on failure and `_exit_tree`, and coordinates with
Hitstop so overlapping freezes preserve the active baseline. The terminal
watchdog is a separate attempt-bound, process-always/ignore-time-scale timer.
The outer 900-second browser budget starts before `fresh_campaign`, so this
timer fires 840 seconds after the lease begins, leaving 60 seconds for startup
and terminal receipt serialization. Complete, failed, and `_exit_tree` paths
invalidate its generation; a later callback is stale evidence and cannot alter
the terminal phase.

The terminal `window.__wyrdSmoke.features.d7_simulation_clock` receipt must be an object,
not a boolean, with this exact semantic shape (numeric baseline may differ from
1 but terminal scale must equal it):

```js
{
  owner: "d7_smoke_clock",
  activated_after_fresh_campaign: true,
  requested_scale: 6,
  observed_scale: 6,
  max_observed_scale: 6,
  captured_baseline_scale: 1,
  watchdog_clock: "monotonic_real_time",
  restored_before_terminal_serialization: true,
  restored: true,
  terminal_reason: "complete",
  terminal_scale: 1,
  training_start_watchdog: {
    duration_sec: 8,
    ignore_time_scale: true,
    armed: false,
    fired: true,
  },
  terminal_watchdog: {
    duration_sec: 840,
    ignore_time_scale: true,
    attempt_token: "d7_fresh_campaign_1",
    generation: 1,
    armed: false,
    fired: false,
    cancelled: true,
    stale: false,
  },
}
```

The injected probe rejects a truthy substitute, an over-cap receipt, a terminal
report whose scale differs from the captured baseline, or a missing, fired,
still-armed, or uncancelled terminal watchdog. The terminal watchdog's nonempty
`d7_` attempt token and positive generation prove an attempt was armed; its
terminal `armed: false`, `fired: false`, and `cancelled: true` prove that owner
invalidated it before serialization. `stale` remains false in the serialized
payload because any late callback necessarily occurs afterward and is a no-op.
In addition to the normal D7 production evidence, release needs focused 1×/6×
parity evidence for ordered phases/receipts, Giant floors and chain banks,
status/cooldown/Threadstep behavior, and final campaign truth. Two independent
fresh exported-Web passes must meet the budget, finish warning/error-free, and
publish restored clock receipts.

Both
`window.__wyrdSmoke.phase === "complete"` and
`window.__wyrdSmokeHarness.status === "passed"` are required. The harness
requires fresh-save, source, Waystone, Table, World, manifest, chain,
settlement, Kiln, and Skill
proof flags, so phase names cannot pass. Browser warnings and errors, including
missing exported resources and GDScript diagnostics, fail the route.

## Slice C2 source route

The third printed URL uses `wyrd_ui_smoke=c2`. Its injected probe is present
and fails closed unless the genuine gameplay driver completes. It requires this
ordered subsequence from the Godot release build:

`title → town → world → atlas_deep_source → chart_table →`
`codex_deep_rumoured → chart_table_closed → world → mara_sallow_source →`
`chart_table → codex_sallow_rumoured → chart_table_closed → complete`

It also requires `window.__wyrdSmoke.features` to contain ten true feature
flags: `c2_gameplay_driver`, `atlas_deep_source_control`,
`mara_sallow_source_control`, `chart_rumour_source_dialog`,
`controller_source_binding`, `world_interact_action`,
`production_town_gathering`, `chart_table_ink_mixing`,
`deep_hollow_table_experiment`, and `sallow_mire_table_experiment`. Reporting
only the phase names cannot pass the route.

The driver earns the first Snug return and its Binding milestone, then completes
ordinary Tier-1 delves to Wayfinding 10. Wild Herbs come from authored Town
`GatherNode` production channels. The player's interaction scanner acquires the
real Atlas panel/rain note and Inscribing Table; the shipped `interact` action
opens them. Literal controller-A binding and source activation are covered by
the native transition suite because a Chromium automation tab has no physical
Gamepad device.

Both experiments use the real Chart Table Controls: Wild Herbs are mixed into
Hedge Ink in the pot, component supply rows stage the clue kit, and the Inscribe
Chart button commits through `Game.try_inscribe_chart`. The route verifies exact
cost consumption and `table_experiment` discovery provenance. It runs the exact
committed Deep Hollow Chart successfully before Mara's rain note can unlock;
only then does it perform the Sallow Mire experiment. The driver never seeds
completion hints, journal entries, source-claimed markers, components, or either
experimental Chart as a shortcut. Direct `ChartsData.inscribe` is limited to
the successful Snug/Tier-1 training needed to reach the acceptance milestones.

Native source captures are stricter but shorter: `capture_chart_sources.gd`
loads the real Town, requires stable nodes `AtlasDeepRumourSource` and
`MaraSallowRumourSource`, opens their real dialog, and completes through each
source Control's public `read_now()` seam. Native fixture eligibility is
deterministic; it does not claim to be the Web gameplay journey.

Any `Parameter "material" is null` entry is a failure. The shared-GLB outline
teardown bug that previously emitted it is covered natively by
`./tools/check_transition_render_errors.sh` and must not regress in Web.

Without `?wyrd_smoke=snug`, the release contains no automated transition and
plays normally. The Codex driver is additionally gated by `wyrd_ui_smoke`; it
cannot run in a normal visit. These smokes check real UI/resource closure and
scene transitions; the native transition suite remains the authoritative
unaided two-Chart gameplay test.

The final Slice C2 release measures 44,265,304 B for `index.pck` and 37,695,054
B for `index.wasm` (43,874,497 B for the PCK at gzip -9). This includes the
explicit `themes/*.tres` export rule; omitting it makes the release fall back to
broken legacy UI even though native tests stay green. The PCK remains 42%
smaller than the 76,172,860 B 2026-07-16 baseline. Re-run these measurements
after changing the Web asset manifest or a model texture's import settings.
