---
title: Bosses, Trophies & Den Progression
domain: Enemies & Combat
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Bosses, Trophies & Den Progression

> The 3-phase boss machine, sealed arena, and trophy chain are fully wired end-to-end; the two biggest gaps are the boss bar hardcoding "The Hedgemother" for all kinds and the Ledger (trophy→stat boost) seam called out in ADR 0013 but not yet implemented.

## Current state

**boss.gd** (322 lines) implements a fully functional 3-phase machine extending `combatant.gd`. It covers three movesets driven by `kind` (set by `layout_loader.gd:669`): `hedgemother` (radial sweep + root stomp, phases 1–3), `burrow_boar` (line-telegraphed charge alternating with stomp), and `wolf_alpha` (chained pack-lunge, 2/3/4 lunges by phase). Telegraph decals (disc + line corridor) are procedurally built each wind-up and freed on resolve (`boss.gd:218–291`). Arena seal gates (`layout_loader.gd:730–794`) raise on `aggroed` and drop on `died` (and on party-wipe in co-op). `reset_fight()` (`boss.gd:79–92`) restores full HP and cancels mid-telegraph on player death.

**Trophy chain** is fully wired: each boss's `BOSS_KINDS` entry carries a `trophy` key (`layout_loader.gd:142–155`); on death `game.add_material(trophy, 1)` runs and a toast fires (`layout_loader.gd:671–679`). Elite enemies have a 25% chance to drop `thorn_essence` (the first-link key), scaled by `marked_quarry` (`layout_loader.gd:857`). `TROPHY_TO_AFFIX` in `charts.gd:190–194` maps each material to its den affix; `crafting_bench.socket_trophy()` (`crafting_bench.gd:111–130`) enforces the `req_carto` gate before inscribing. `game.run_cfg()` (`game.gd:758–766`) reads the slotted den affix and resolves it to `boss_kind` via `DEN_TO_BOSS`.

**Summit** is defined: `charts.gd:59–66` has the `summit` template (cost `alpha_fang + refined_ink + hedge_ink×4`, scope `crypt`, hard-coded `boss_kind: "hedgemother_queen"`). `game.gd:718–721` sets `summit_cleared = true` and notifies on return. `BOSS_KINDS["hedgemother_queen"]` (`layout_loader.gd:154–155`) reuses `hedgemother_v2.glb` at scale 4.6 with 160 HP / 13 damage; `trophy` is `""` so no further chain exists.

**Gaps vs claimed complete:** `boss_bar.gd:37,54` hardcodes "The Hedgemother — Unyielding" for all boss kinds — the Boar and Wolf Alpha show the wrong name. ADR 0013 explicitly defers `ledger.gd` (trophy→live stat boost, source #3). The `hedgemother_queen` runs the same `hedgemother` moveset with no distinguishing phase-3 escalation.

## Gaps — what needs fleshing out

1. **[blocker] Boss bar name is hardcoded** — `boss_bar.gd:37,54` shows "The Hedgemother — Unyielding" for every boss kind. `_build_boss` calls `bossbar.prime(boss_hp)` (`layout_loader.gd:703`) but never passes `boss_kind` or a display name. Boar/Wolf fights are silently mislabeled.
2. **Ledger / trophy stat boost** — ADR 0013 names this explicitly as "followup: `ledger.gd` — make trophies a live, capped stat source." The seam exists (trophies land in the satchel as materials) but equipping them for a stat bonus is unwired.
3. **Summit / hedgemother_queen is a re-skin only** — the Queen reuses the standard hedgemother moveset at larger scale. She is the endgame boss and deserves at least one distinguishing attack (summon wave, enrage on phase 3, expanded arena).
4. **Den difficulty band readout** — ADR 0013 notes "Surface the den level and the resulting band before the player commits to a chart." The `den_level` is computed in `game.run_cfg()` but nothing in the crafting bench or waystone preview surfaces it.
5. **No "new boss" path** — adding a 4th biome boss requires touching `BOSS_KINDS`, `TROPHY_TO_AFFIX`, `AFFIXES`, `BASE_WEIGHTS` exclusion list, and a new chart template. There is no central registration — just four parallel edits across three files.

## Plan

### Phase 1 — Boss bar label fix (unblock correctness)
- Add a `display_name` key to each `BOSS_KINDS` entry (`layout_loader.gd:142–155`): `"The Hedgemother"`, `"The Burrow Boar"`, `"The Wolf Alpha"`, `"The Hedgemother, Queen of Thorns"`.
- Update `_build_boss()` to pass `display_name` (and the boss's existing `IMMUNE_KINDS`) to `bossbar.prime()`.
- Update `boss_bar.gd:prime()` and `set_phase()` to accept and display the injected name instead of the hardcoded literal.
- **DoD:** Starting a Burrow Boar run displays "The Burrow Boar" on the boss bar at aggro; Wolf Alpha shows "The Wolf Alpha"; Queen shows her full name. Verified by `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den` boot + `WYRD_SHOT=1` screenshot.
- **Effort:** S

### Phase 2 — Den difficulty readout at the bench
- In `crafting_bench.gd`'s result slot preview (`BenchView._draw_result_slot`), read `game.run_cfg()` with the currently placed base/trophy to extract `den_level`.
- Display a band chip ("Den lv 8 · you lv 6 → **very hard**") using the same delta logic as ADR 0013's bands table (delta ≤ −2 easy, −1..+1 moderate, ≥ +2 very hard).
- Player Wayfinding level is available via `game.trade_level("carto")` (used already at `crafting_bench.gd:76`).
- **DoD:** Crafting bench result slot shows den level and difficulty band for any template with a boss. `WYRD_DEV_LEVEL=6` + inscribing a tier-2 hollow shows "Den lv 8 · moderate". Covered by `test_wyrd_loop.gd` if a new assertion checks the string, or by screenshot.
- **Effort:** S

### Phase 3 — Ledger: trophy → capped stat boost
- Implement `ledger.gd` as a data file: maps trophy material ID → `{"stat": String, "bonus": float, "cap": float}`. Start with `thorn_essence → {crit_chance: +0.04, cap: 0.12}`, `tusker_tusk → {damage_flat: +2, cap: 6}`, `wightpelt → {move_speed: +0.05, cap: 0.15}`, `alpha_fang → {fire_rate: +0.08, cap: 0.16}`.
- Add `apply_ledger_bonuses(player)` to `game.gd` that iterates satchel materials against the ledger (counts, not just presence, so repeated runs compound up to the cap).
- Call it from `player_controller._derive_stats()` after gear bonuses are applied.
- **DoD:** Killing the Hedgemother and exiting grants a persistent +4% crit up to 12%. `test_wyrd_loop.gd` asserts `crit_chance` is higher post-trophy than pre. Save/load round-trip preserves the boost (`test_wyrd_transitions.gd` covers save round-trips).
- **Effort:** M

### Phase 4 — Queen of Thorns: unique phase-3 mechanic
- The Queen already runs `boss.gd`'s hedgemother moveset. For `kind == "hedgemother_queen"` extend `_begin_attack()` to add a **summon burst** on phase 3: spawn 2 `skeleton` enemies via a deferred `layout_loader` call (or emit a signal the loader catches) alongside the normal attacks.
- Add a distinct ground telegraph (wider disc, deeper red) that signals "she calls the dead" so the player sees the shift.
- Phase-3 cooldown tightens to 1.0 s (vs 1.3 for standard Hedgemother) to match the 160 HP / 13 dmg threat.
- **DoD:** Entering phase 3 on the Queen spawns 2 skeletons and shows a wider red disc; standard Hedgemother at phase 3 does not summon. Verified by headless `test_wyrd_dungeon_scene.gd` — assert `get_tree().get_nodes_in_group("enemy").size()` increases after the Queen crosses the 33% threshold.
- **Effort:** M

### Phase 5 — Expansion: 4th biome boss (future)
- Document the registration pattern so a new biome boss is one edit per concern. Candidates per world bible: a **Bog Hag** (swamp biome) or a **Bramble Golem** (hedge biome).
- A future boss needs: `BOSS_KINDS` entry, `TROPHY_TO_AFFIX` pair, `AFFIXES` boss-den entry, a chart template or promoted affix, a new boss moveset method in `boss.gd`, and `gather.gd` trophy material.
- This phase is a **design gate** — block on world/biome expansion, not a code gap now.
- **DoD:** Written checklist in `docs/specs/` for "add a new boss", referencing the five file locations above.
- **Effort:** S (documentation only until the biome is greenlit)

## Dependencies & links

- [[system-combatant-ai]] — `boss.gd` extends `combatant.gd`; HP, hurtbox, flash, knockback, death signal, nav chase all live there. Phase 1's display_name flows through `boss_bar`, not combatant.
- [[system-chart-affixes]] — the boss-den affixes (`hedgemother_den`, `burrow_boar_den`, `wolf_alpha_den`) are defined in `charts.gd:AFFIXES` alongside all other affixes; stability and `req_carto` enforcement applies equally.
- [[system-charts-wayfinding]] — trophy inscribing (`TROPHY_TO_AFFIX`, `socket_trophy`) is the upstream activation of the den chain; the summit template sits in `TEMPLATES`.
- [[system-elites]] — elites are the first link in the trophy chain (25% `thorn_essence` drop at `layout_loader.gd:857`); `marked_quarry` affix scales the drop rate.
- [[system-trades-progression]] — `req_carto` gates each den (lv 8 / 12 / 14); the Wayfinding level in `game.gd` enforces it in `crafting_bench.socket_trophy()`. ADR 0013's den-level bands feed Phase 2.
- [[system-drops-loot]] — boss death drops a loot pile (`boss.role = "boss"`, `boss.depth = 9`) via the standard combatant drop path; trophy is a separate `game.add_material()` call.
- [[system-hud]] — the boss bar (`boss_bar.gd`) is a separate CanvasLayer; Phase 1 touches it directly.
- [[system-status-effects]] — `boss.gd:IMMUNE_KINDS` blocks root/snared; burn/bleed run at 50% duration (`REDUCED_DURATION`). The "Unyielding" tag surfaces this to the player.
- [[system-save-load]] — `summit_cleared` (`game.gd:108`) is a save field; Ledger bonuses (Phase 3) must also ride the save dict.

Plan.md Part A (combat-feel SHIPPED P1–P5) covers the animation/audio layer that makes the boss fights feel punchy — bosses already benefit from that pass. Part B loop-feel (B0–B7 PLANNED) covers gather/craft/inscribe/level-up feel; den-difficulty readout (Phase 2 above) complements B6 (affixes feel) and should be sequenced alongside that pass.

## Verification

- **Phase 1** (boss bar label): `WYRD_NO_SAVE=1 WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den godot --path wyrd` + visual confirm via `WYRD_SHOT=1`; or add an assertion to `test_wyrd_dungeon_scene.gd` that the BossBar label text includes "Boar" when the boss kind is `burrow_boar`.
- **Phase 2** (den readout): `WYRD_DEV_LEVEL=6` boot + open the Inscribing Table + place a tier-2 base; screenshot via `WYRD_SHOT=1`. No headless assertion available without a bench-drive helper.
- **Phase 3** (Ledger): extend `test_wyrd_loop.gd` — kill the Hedgemother (drive the dungeon to completion), assert `game.trade_data["carto"].get("thorn_essence_bonus", 0) > 0` or the derived `crit_chance` increased. Save-load round-trip tested by `test_wyrd_transitions.gd` once the Ledger field is in the save dict. Run with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd`.
- **Phase 4** (Queen summon): extend `test_wyrd_dungeon_scene.gd` — force a Summit run (`WYRD_DEV_CHART=summit`), drive the boss below 33% HP programmatically, assert `get_tree().get_nodes_in_group("enemy").size() >= 2`. Run with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`.
- All runs: prefix with `cd wyrd` is not needed — use `--path wyrd` or `--path .` from the `wyrd/` directory per CLAUDE.md convention.

## Open questions

1. **Ledger stat selection** — which trophy maps to which stat? Current suggestion (Phase 3) follows a flavor logic: `thorn_essence` → crit (the Hedgemother's reactive parries), `tusker_tusk` → flat damage (raw force), `wightpelt` → move speed (wolf evasion), `alpha_fang` → fire rate. Confirm before implementing.
2. **Queen summon count** — 2 skeletons per summon burst is conservative. Should the number scale with phase-3 duration (re-summoning every N seconds while below 33%)? This affects how punishing the Summit is.
3. **Trophy → Ledger consumption** — does slotting a trophy into a chart *spend* it from the Ledger pool, or are Ledger bonuses accumulated independently of chart crafting? Currently trophies are consumed by `craft_cost()` when inscribing a boss den. If the Ledger bonus comes from owning the trophy (not spending it), the satchel count matters. Needs a ruling.
