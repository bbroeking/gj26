---
title: Gathering & Nodes
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Gathering & Nodes

> The channel-harvest loop is mechanically complete and tier-gated across all five ore and six herb tiers — the main remaining work is feel polish (Plan.md Part B / B1–B2) and one data gap: `herbal_patch` still defaults to `wild_herb` instead of rolling a tier-appropriate herb.

## Current state

The gathering system is mechanically solid. `gather_node.gd` implements all three node kinds (`ore_rock`, `forage_node`, `log_pile`) with E-press channel harvesting, a billboarded progress bar, per-beat squash animation, move/damage cancellation, and floating `+N` labels (lines 217–390). Five ore tiers (`copper` req_lv 1 → `hedgesteel` req_lv 15) live in `data/gather.gd:168–185` and six herb tiers (`wild` req_lv 1 → `stonebreak` req_lv 16) in `data/gather.gd:189–208`, each with their own `req_lv`, `xp`, `channel_sec`, and `color`. Level-gating is enforced in `gather_node.gd:71–73` against the correct trade (`earth` for ore, `wilds` for herbs).

Dungeon spawning is fully wired: `dungeon_gen.gd:279–395` scatters `mineral_vein`/`bramble_bloom`/`herbal_patch`/`wood_grove` affixes using weighted tier-roll tables (`ORE_ROLLS_BY_TIER`, `FORAGE_ROLLS_BY_TIER`, `FORAGE_ROLLS_PATCH` in `data/gather.gd:214–228`) keyed by chart tier. The Summit (tier 3) hard-places two `hedgesteel` veins and two `stonebreak` patches even without affixes (`dungeon_gen.gd:345–395`). Starsilver and hedgesteel DO spawn — they appear in `ORE_ROLLS_BY_TIER` tiers 2 and 3 (`data/gather.gd:216–217`); "never spawn" in the task brief is outdated. Town yard nodes (`copper × 2`, `bogiron × 1`, `bittergrass × 1`, wild herb patches, log piles) all respawn on timers (`town.gd:286–315`). Prop GLBs (`prop_ore_vein_v1.glb`, `prop_herb_bush_v1.glb`, `prop_log_pile_v1.glb`) all exist and are loaded with GLB-fallback to procedural primitives (`gather_node.gd:100–124`). Ink-discovery-by-experiment is fully wired: `game.gd:551–625` resolves the `try_experiment()` path; `save_game.gd:23` persists `discovered_inks`; the codex shows riddles after the matching `first_time_hint` fires. Perks `quick_mining`, `rich_seams`, `light_hands`, `keen_eye`, `clean_splits`, `double_ore` all modify harvest (`game.gd:434–476`). Affix modifiers `wellspring` (good: +1 per node) and `barren_veins` (bad: channel ×1.33) are applied in `gather_node.gd:282–290` and `channel_seconds()`.

**One data bug:** `GATHER_BY_AFFIX["herbal_patch"]` in `dungeon_gen.gd:291` still hardcodes `"item": "wild_herb"`. The scatter code overwrites `item_id` via `setup_herb_tier()`, but the fallback item written into the decor dict is wrong for non-wild tiers. This is cosmetically harmless today (the tier lookup wins) but fragile.

**Missing feel:** Plan.md Part B calls out that gather arm articulation (B1) and harvest payoff pop (B2) are unbuilt — the channel currently rotates the whole mesh, not the arm bones; there is no harvest mote burst.

## Gaps — what needs fleshing out

1. **(data bug, low severity)** `herbal_patch` fallback item in `dungeon_gen.gd:291` should be `""` or `"wild_herb"` is misleading — fix to use tier-resolved item as fallback.
2. **(feel — blocker for cozy spine)** Gather arm articulation (B1): whole-mesh rotation instead of arm-bone arc. This is the most-repeated verb in the game; it reads stiff. See Plan.md Part B / B1.
3. **(feel)** Harvest payoff pop (B2): no mote burst, no screen/camera micro-kick, harvest end is just a floating number. See Plan.md Part B / B2.
4. **(town feel)** Town node regrowth is instant (`_regrow` sets `visible = true` and tweens scale from 0, but there is no arrival beat/sound). See Plan.md Part B / B7.
5. **(prop art)** Single shared GLB per kind — all ore veins look identical regardless of tier. Tier-tinting (`_tint_tier`) is applied, but higher tiers deserve at least a crystal-sparkle particle or alternate geometry.
6. **(no dungeon respawn)** Dungeon nodes intentionally do not respawn (`respawns = false`). This is correct design, but a future "evergreen grotto" affix could be a rich addition.
7. **(ink-discovery UX)** The codex riddle appears only after the matching `first_time_hint`; hints are stored in `game.gd:128–153`. The `"still"` and `"forge"` hint keys for deeper inks require visiting those stations — it's not clear whether those hints fire correctly without a playtest.

## Plan

### Phase 1 — Data correctness & harvest gating audit  *(prerequisite for nothing, but hygiene)*
- Fix `dungeon_gen.gd:291`: change `"item": "wild_herb"` → `"item": ""` (the `setup_herb_tier` call resolves the real item; the fallback is only used if `herb_tier` is absent, which never happens for `herbal_patch`).
- Smoke-test: run `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — confirm no regression.
- **DoD:** `herbal_patch` decor dicts in generated layouts have `item == ""` or the correct herb for their rolled tier; no loot regressions in dungeon test.
- **Effort:** S

### Phase 2 — Gather arm articulation (Plan.md Part B / B1)
*Do NOT duplicate Plan.md's phase — this note defers to it. Summary for dependency tracking:*
- Add `GatherSwingModifier` sibling to `bow_draw_modifier.gd`; `player_controller.gd:begin_gather` wires the arm bones through a mine/chop/forage arc instead of rotating `_mesh`.
- Requires Plan.md B0 (`feel.gd` tunables) to land first so swing depth/rate live in the central constants.
- **DoD (Plan.md B1):** arm bones visibly drive the swing; `_mesh.rotation:x` approach removed; forage arc is gentler than mine arc; WYRD_FAST_CHANNEL still works; `test_wyrd_loop` green.
- **Effort:** M (per Plan.md)

### Phase 3 — Harvest payoff pop (Plan.md Part B / B2)
*Defers to Plan.md B2. Summary:*
- On `_harvest()` success (`gather_node.gd:267`): spawn N motes arcing up + outward; brief camera micro-kick; distinct per-material harvest chime via `Sfx`.
- `_float_text` remains; motes are the *additional* payoff layer.
- **DoD (Plan.md B2):** mote burst fires on every harvest; camera kicks; floating text remains; no harvest without motes; cancellation produces no mote burst.
- **Effort:** S (per Plan.md)

### Phase 4 — Town node arrival beat (Plan.md Part B / B7)
*Defers to Plan.md B7. Summary:*
- `_regrow()` in `gather_node.gd:362` currently starts scale-tween with no sound. Add a short rustle/sprout SFX on `_regrow()` and a brief green shimmer on the body (modulate flash).
- Wire to the town ambient beat (B7 swell).
- **DoD (Plan.md B7):** regrown nodes have an arrival beat; the scale-pop already present gets a paired SFX; does not trigger in dungeons (`respawns == false`).
- **Effort:** S (per Plan.md)

### Phase 5 — Tier-variant prop polish  *(expansion/polish, not blocking)*
- Higher ore tiers (starsilver, hedgesteel) deserve a particle shimmer (OmniLight child with low range + CPU particles).
- Deep herb tiers (foxglove, stonebreak) could use a color-glow emissive pulse on the bush mesh.
- `_tint_tier` already sets albedo; extend it to also toggle a small point-light child if `ore_tier in ["starsilver", "hedgesteel"]`.
- **DoD:** starsilver and hedgesteel veins have a faint blue/green glow visible at 3 m; foxglove/stonebreak patches have a matching subtle emissive pulse; all tiers still readable with tinting at 5 m.
- **Effort:** S

## Dependencies & links

- [[system-trades-progression]] — `req_lv` gates on Earthcraft (`earth`) and Wildcraft (`wilds`) trade levels; the mastery perk tree (`quick_mining`, `rich_seams`, `light_hands`) drives harvest bonuses.
- [[system-crafting]] — harvested ore and herbs are the primary crafting inputs; ink mixing at the bench pot is the first downstream use of every gathered material.
- [[system-charts-wayfinding]] — chart tier drives `ORE_ROLLS_BY_TIER` / `FORAGE_ROLLS_BY_TIER` weighting; `mineral_vein`, `bramble_bloom`, `herbal_patch`, `wood_grove` are chart good-twin affixes that place gather nodes.
- [[system-chart-affixes]] — `wellspring` / `barren_veins` good/bad twins directly modify harvest count and channel time (`gather_node.gd:282–290`, `channel_seconds()`).
- [[system-dungeon-generation]] — `dungeon_gen.gd:_scatter_gather_nodes` is the placement engine; chart tier and affix list are its inputs.
- [[system-items-affixes]] — pickaxe and axe tool slots reduce channel time (`channel_seconds():300–304`); equipment lookup goes through `game.equipment`.
- [[system-town-hub]] — town yard spawns the starter node set with respawn timers; the bittergrass patch and bogiron vein are the town's "coveted-but-locked" teaching nodes.
- [[system-save-load]] — `discovered_inks` array and `materials` satchel are persisted; gather-state (depleted nodes) is NOT saved (intentional — nodes reset on load).
- [[system-animation]] — Plan.md B1 (arm articulation) adds a `GatherSwingModifier`; this system note tracks the gather side, animation note tracks the rig side.
- [[system-audio-music]] — Plan.md B0–B2 adds per-beat gather SFX (`mine`/`chop`/`forage` + `gather_chip` + harvest chime); Sfx autoload is already called from `gather_node.gd:206`.

**Plan.md overlaps (DO NOT re-plan here — link only):**
- `Plan.md Part B / B0` — `feel.gd` tunables + SFX stubs; must land before B1/B2.
- `Plan.md Part B / B1` — Gather arm articulation (Phase 2 above defers entirely to it).
- `Plan.md Part B / B2` — Harvest payoff pop (Phase 3 above defers entirely to it).
- `Plan.md Part B / B7` — Town / Living-Atlas ambient feel (Phase 4 above defers entirely to it).

## Verification

- **Phase 1:** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — all assertions green; inspect a logged decor dict for `herbal_patch` kind and confirm `item` field.
- **Phase 2:** Play-test sign-off (per Plan.md B1); `test_wyrd_loop.gd` green with `WYRD_FAST_CHANNEL=1`; feel bench (`WYRD_FEEL=gather_swing`) screenshot capture.
- **Phase 3:** `test_wyrd_loop.gd` green; harvest without cancellation spawns motes; `WYRD_DEBUG_GATHER=1` cancel path produces no motes; feel bench (`WYRD_FEEL=harvest_pop`) screenshot.
- **Phase 4:** Town scene with `WYRD_SHOT=1`; manually observe regrowth SFX; `test_wyrd_transitions.gd` green.
- **Phase 5:** Visual QA — load a tier-3 chart and confirm starsilver/hedgesteel glow visible at 3 m in the Godot editor viewport; screenshot via `godot --path wyrd` + `WYRD_DEV_CHART=tier3 WYRD_SHOT=1`.

## Open questions

- Should depleted dungeon nodes ever respawn mid-run? Current design says no (one-shot per run). A `perennial_groves` good affix could override this — worth noting before the affix system expands.
- The `"still"` and `"forge"` `hint_key` values trigger ink-discovery hints; are these NPC dialogue keys fired reliably on first visit? Needs a playtest to confirm `"still"` (Quill's still area) fires before the player experiments with mothmint.
