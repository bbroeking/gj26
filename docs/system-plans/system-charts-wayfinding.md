---
title: Charts & Wayfinding (the signature)
domain: Wayfinding & Dungeons
type: system
status: partial
effort: L
tags: [wayfinder, plan]
---

# Charts & Wayfinding (the signature)

> The differentiating loop — chart data, affix engine, and inscription bench are all shipped; the single biggest gap is the inscription RITUAL feel (Plan.md B6) and the unimplemented bad-twin effects for two modifier affixes.

## Current state

`wyrd/data/charts.gd` (1–428) is the fully-shipped core: five TEMPLATES (`snug`, `tier_1`, `hollow`, `briar_maze`, `summit`), 15 rollable AFFIXES + 3 boss-den affixes, 8 INKS with weight-bias tables, `compute_weights()`, `effective_stability()` (base_stab + carto_lv × 0.6 + ink/perk bonuses, capped at 95), `inscribe()`, `craft_cost()`, `completion_xp()` (tier × 75 + good × 40 + bad × 10, Tyrannical ×1.3), and `chart_label()`. The Crafting Bench (`scripts/ui/crafting_bench.gd` 1–880) implements Minecraft-style drag-socket inscription with a live odds readout, mixing pot, codex, tutorial pulse guidance, wax-seal stamp animation (0.25 s gold flash), and perk gates for Thrifty Quill, Sure Lines, Master Wayfinder, and Practiced Measures. The Waystone panel (`scripts/ui/waystone_panel.gd`) lists the chart case, shows per-affix detail, and calls `game.enter_dungeon()`. All 14 modifier affixes have runtime effects wired in `layout_loader.gd` (l. 276–318), `player_controller.gd` (l. 1141–1169), and `gather_node.gd` (l. 280, 317); the two bad twins that were open stubs — `wellspring` bad (gather-slower) and `frenzied` bad (enemy hits harder) — are also wired (`gather_node.gd` l. 317, `layout_loader.gd` l. 304). Den-level difficulty scaling is live: tier→den_level map `{1:3, 2:8, 3:13}` feeds `LEVEL_POWER^(den_lv-1)` to hp/dmg multipliers (`game.gd` l. 750, layout_loader l. 316–318). **What is missing:** the inscription ritual feel (B6a/b) — affixes appear all-at-once after a 0.25 s stamp flash; there is no sequential reveal, table-glow pulse, or SFX — and no trophy-slot gating by chart-case capacity (the player could theoretically socket the same trophy into every chart simultaneously with no guard). Additionally, no Tier 2+ exclusive affixes exist, and the `briar_maze` scope has no biome-specific decor beyond corridor ratio.

## Gaps — what needs fleshing out

1. **[BLOCKER for signature feel] Inscription ritual (B6) is unimplemented.** Affixes appear all-at-once; no table glow-pulse, no seal SFX, no sequential overshoot reveal. This is the single highest-value polish item (Plan.md B6). Must happen after B0 audio scaffolding.
2. **Completion notification is a plain toast.** `game.gd` l. 652 / l. 715 awards XP via `award_xp("carto", xp)` and fires `notify(...)` — no fanfare, no affix debrief screen, no "Tyrannical pays off" moment.
3. **No Tier 2+ exclusive affixes.** `hollow` (req_carto: 10) and `briar_maze` (req_carto: 15) draw from the same 15-affix pool as Tier 1. Design intent calls for deeper affixes (corruption stacks, inter-room effects) at higher tiers.
4. **Trophy-slot cap not enforced in the chart case.** Nothing prevents a player from inscribing 3 charts each with the same trophy (each inscription spends one, but there is no "you only have one thorn_essence" guard at the bench level beyond `_remaining()`).  `_remaining()` in `crafting_bench.gd` l. 232 does deduct the trophy cost live, so this is a UI affordance gap, not a logic bug — but the Waystone panel doesn't warn if you socket a chart whose boss-den affix can't be guaranteed anymore.
5. **`briar_maze` scope has no distinctive biome decor.** `scope: "briar_maze"` flows into `dungeon_gen.gd` but the gather/decor pass `GATHER_BY_AFFIX` has no briar-specific variant; it looks identical to `hollow`.
6. **Chart preview at the Waystone is text-only.** `waystone_panel.gd` l. 134–144 shows the affix lines as plain text; no stability color coding (red/green for good/bad twin odds), no tier badge, no expected XP readout.
7. **No "chart expiry" or overflow mechanic.** The chart case is unbounded (Array append). If a player hoards charts, the Waystone list grows without limit. A soft cap (e.g., 8 charts) with a visible full indicator is needed.
8. **`frenzied` bad twin (`seething`) increases enemy damage but has no player feedback.** The multiplier fires (`layout_loader.gd` l. 304), but nothing in the HUD warns the player they are in a "enemies hit harder" chart.

## Plan

### Phase 1 — Inscription ritual feel (B6 — the signature)
*Depends on: Plan.md B0 (`feel.gd` + audio scaffolding) being done first.*

- In `crafting_bench.gd` `BenchView.stamp()`: extend the 0.25 s stamp to a two-stage sequence — (a) table OmniLight in `inscribing_table.gd` brightens to energy 3.0 and pulses down over 0.6 s (signal from bench → table node, or through `game.emit_signal`), (b) the result slot reveals each resolved affix one-by-one with a 0.18 s overshoot scale pop, good twin in `WyrdUi.GOLD` tint, bad twin in `WyrdUi.TERRACOTTA`.
- Play `Sfx.play("inscribe_seal")` at the moment the wax-seal draws (already rendered at `crafting_bench.gd` l. 852 — just needs the audio call).
- The reveal sequence must complete in ≤ 1.2 s total (tune via `feel.gd` once B0 lands).
- Wire the sequential reveal as a coroutine (`await`) driven by a `_reveal_index` counter on `BenchView`; each step calls `queue_redraw()` and `pop("affix%d" % i)`.
- **DoD (a):** Inscribing triggers a table glow pulse + wax-seal SFX audible in headless screenshot. **DoD (b):** Affixes reveal one-by-one with overshoot, ≤ 1.2 s total — verify via `WYRD_UI_SHOT=inscribing` capture. **Clones:** inscribing OmniLight pattern from B2 harvest-pop; overshoot from B3 level-up.
- **Effort:** M

### Phase 2 — Chart completion debrief
*Depends on: Phase 1 (ritual sets the expectation that inscribing feels special; completion should match).*

- When `game.return_to_town()` is called with `abandoning = false` (`game.gd` l. 724), fire a debrief toast listing: chart name, affixes resolved (✓ / ✗), XP awarded, and which perk (Tyrannical bonus) applied.
- Add an `affix_debrief(chart, xp)` helper on `Game` that emits a named signal `run_completed`; the existing HUD (`player_hud.gd`) subscribes and shows a 3 s overlay.
- For Tyrannical specifically: show "+30% XP bonus (Tyrannical)" in the overlay.
- **DoD:** Complete a Tyrannical chart → debrief shows the affix name + XP bonus line. Verify with `test_wyrd_loop.gd` by checking `run_completed` fires with the right XP.
- **Effort:** S

### Phase 3 — Waystone panel polish (chart preview)
*Independent; can run in parallel with Phase 2.*

- Color-code affix lines in `waystone_panel.gd` l. 139–141: good twin label in `WyrdUi.GOLD`, bad twin in `WyrdUi.TERRACOTTA` (already used for cost-unaffordable text).
- Add a tier badge (e.g., "T2") beside the chart name button.
- Show expected XP under the detail block: call `ChartsData.completion_xp(chart)` and render as "≈ N xp on completion".
- Add a soft cap guard: cap chart case at 8 entries; show "Chart case full (8/8)" in the bench result panel when at cap.
- **DoD:** Waystone shows colored affix lines + XP preview. Bench blocks inscription at cap. Verify via `WYRD_UI_SHOT=waystone`.
- **Effort:** S

### Phase 4 — Tier 2+ exclusive affixes
*Depends on: the affix engine in `charts.gd` being stable (it is); Tier 2 templates already exist.*

- Design 3–4 new affixes gated at `req_carto >= 10` that only appear in `hollow` / `briar_maze` runs: e.g., `cursed_ground` (bad: floor tiles damage on-stand; good: tiles briefly root enemies), `overgrown` (good: gather nodes respawn once mid-run; bad: vines slow movement), `crowded_dark` (good: +XP per kill in dark rooms; bad: vision radius shrinks).
- Add them to `AFFIXES` and `BASE_WEIGHTS` in `charts.gd`. Wire the runtime effects per the existing `layout_loader` / `gather_node` / `player_controller` pattern.
- Gating is automatic: `compute_weights()` l. 275 already filters by `req_carto <= carto_lv`.
- Add corresponding inks or bump existing ink biases for the new affixes.
- **DoD:** At Wayfinder lv 10, at least one new affix appears in the Hollow odds column in the bench. Verify via `WYRD_DEV_LEVEL=10 WYRD_DEV_CHART=hollow`.
- **Effort:** M

### Phase 5 — `briar_maze` distinctive decor + affix hint
*Depends on: Phase 4 if "overgrown" is added; otherwise independent.*

- Add a `briar_maze` branch in `dungeon_gen.gd` `GATHER_BY_AFFIX` (or the gather-scatter pass): dense thorn-vine props, darker tile tint, and an "overgrown" forced bonus gather-node even without the affix, matching the template's `"twisted layout — corridors over rooms"` description.
- Expose `scope` to the bench tip in `crafting_bench.gd` `_tip_for("base", ...)` l. 489–495 — add a one-line "Biome: Briar Maze — corridors over rooms" to the template tooltip.
- **DoD:** Opening a briar_maze chart shows visually distinct decor (screenshot comparison). Bench tooltip names the biome.
- **Effort:** S

### Phase 6 — Expansion: deeper chart tiers & trophy chain extension
*Expansion/polish phase — do after Phase 4 stabilizes. Framed as expansion since core chain already reaches Summit.*

- Define a Tier 3 template family (e.g., `sunken_hollow` req_carto: 17) with 3 affix slots. Trophy chain extended by new boss (deferred to [[system-bosses]]).
- Add a `tier_bonus` multiplier to `completion_xp()`: Tier 3 might pay 1.5× the current formula.
- Consider a chart-case "highlight" for Tier 3 charts in the Waystone panel (gold border).
- **DoD:** Inscribing a Tier 3 chart is possible at lv 17 and pays visibly higher XP. Boss den affix slot is gated by trophy possession.
- **Effort:** M

## Dependencies & links

- [[system-chart-affixes]] — sister note covering the full affix design space (good/bad twin mechanics, balance); any new affix added in Phase 4 needs a sibling entry there.
- [[system-dungeon-generation]] — receives the chart's `gen` block + `affixes` array; Phase 5 briar-maze decor lands here.
- [[system-biomes-decor]] — `briar_maze` biome distinctiveness (Phase 5) and any Tier 3 biome belongs here.
- [[system-bosses]] — boss-den affixes (`hedgemother_den`, `burrow_boar_den`, `wolf_alpha_den`) and the trophy chain are the mechanism; boss fight implementation lives there. Phase 6 Tier 3 boss is a blocker.
- [[system-elites]] — `marked_quarry` affix doubles/halves elite trophy drop odds (`layout_loader.gd` l. 852); the trophy economy links charts to elites directly.
- [[system-trades-progression]] — Wayfinding ladder (ADR 0012, single skill); perk unlocks (Thrifty Quill, Sure Lines, Master Wayfinder) gate bench behavior already.
- [[system-gathering]] — `wellspring` affix (+1 yield / +33% gather time) modifies gather node behavior; `mineral_vein`, `bramble_bloom`, `herbal_patch`, `wood_grove` scatter nodes via dungeon_gen.
- [[system-interactables]] — Inscribing Table and both Waystones (portal + exit) are Interactables; ritual glow in Phase 1 lives on the table node.
- [[system-audio-music]] — Plan.md B0 audio scaffolding is a hard prerequisite for Phase 1 (the seal SFX call). Phase 1 must wait for B0 to land.
- [[system-hud]] — completion debrief overlay (Phase 2) is a new HUD surface.
- [[system-ui-panels]] — Waystone panel polish (Phase 3) and the bench both pull from WyrdUi tokens; any new panel chrome must use the kit.
- **Plan.md Part B / Phase B6** — owns the inscription ritual feel end-to-end (B6a table reaction, B6b sequential affix reveal). Phase 1 here IS B6; do not re-specify, implement against Plan.md's DoD. Phases B0 (feel.gd + audio) and B5 (craft reaction) are prerequisites.

## Verification

- **Phase 1 (ritual):** `WYRD_UI_SHOT=inscribing` screenshot shows glow pulse + sequential affix stamps. Play-test sign-off on timing (≤ 1.2 s reveal). Also: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` must stay green (no regression on craft path).
- **Phase 2 (debrief):** `test_wyrd_loop.gd` — add assertion that `run_completed` signal fires with `xp > 0` after exiting a non-abandoned chart. Test a Tyrannical chart via `WYRD_DEV_CHART=tier_1 WYRD_NO_SAVE=1`.
- **Phase 3 (waystone polish):** `WYRD_UI_SHOT=waystone` screenshot confirms colored affix lines and XP preview. Manual test: inscribe 8 charts, verify 9th is blocked.
- **Phase 4 (new affixes):** `WYRD_DEV_LEVEL=10 WYRD_DEV_CHART=hollow` boots into bench; confirm new affix IDs appear in odds column. `test_wyrd_dungeon_scene.gd` must stay green.
- **Phase 5 (briar_maze decor):** `WYRD_DEV_CHART=briar_maze` screenshot comparison shows distinct thorn decor vs hollow.
- **Phase 6 (Tier 3):** Manual playthrough at lv 17; inscribe Tier 3 chart; verify `completion_xp` return value reflects tier bonus (`test_wyrd_loop.gd` assertion).
- All runs: `WYRD_NO_SAVE=1` always; headless suites `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd` all green after each phase.

## Open questions

1. **Chart-case cap:** Is 8 the right number, or should it scale with a perk? (Chartmaster's Satchel perk could add +2 slots.)
2. **Affix debrief placement:** Should the completion debrief appear as a full-screen overlay, or a large toast? A full-screen overlay feels more ceremonial but adds a scene transition; a toast is simpler. Recommend: toast for now, overlay in Phase 6 when Tier 3 makes it feel worth the ceremony.
3. **Tier 3 template name:** `sunken_hollow` fits the Bramblewood lore but needs a world-bible check before locking the string.
4. **Bad-twin HUD warning:** `frenzied` bad (enemies hit 15% harder) and `sprinter` bad (player 10% slower) silently apply — should the HUD surface "Seething" / "Mired Boots" as a persistent debuff chip? This crosses into [[system-hud]] territory; decision needed before Phase 2 wires the debrief.
