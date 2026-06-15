---
type: design
tags: [system-design, dungeon-gen]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Dungeon Generation.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "wyrd/scripts/dungeon_gen.gd"
  - "wyrd/scripts/layout_loader.gd"
  - "wyrd/data/charts.gd"
  - "wyrd/data/affixes.gd"
  - "kb/wiki/games/roguelike/Spelunky.md"
  - "kb/wiki/games/roguelike/Dead Cells.md"
  - "kb/wiki/games/roguelike/Caves of Qud.md"
  - "kb/wiki/games/arpg/Hades.md"
  - "kb/wiki/games/strategy/Into the Breach.md"
---

# Dungeon Generation — Deep Design

> Forward-looking deep design. Current-state: [[Dungeon Generation]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You inscribed a chart — *remembered a way the village forgot* — and now you walk it. The generator's whole job is to make that remembered place feel **found, not rolled**: a hollow with its own ecology, its own quiet sorrow, that you couldn't have predicted but that reads as belonging to *this* chart. In the cozy spine (`gather → craft → chart → delve → return → grow`, ADR 0003) generation is the **payoff renderer**: it is where the ore-affix you slotted becomes a real seam in a real wall, where the boss-trophy you carried home returns as a sealed arena. It is not a system the player *uses* — it is the world the rest of the spine pours into. Its prime directive (per [[Universe Build-Out Plan]] §8) is that a delve must be *recognizably its biome to a blind tester*, never a recolor.

## What ships today (grounded in code)

The generator is **real, tested, and load-bearing** — the four headless suites guard it.

- **`dungeon_gen.gd::generate(seed, cfg)`** is the whole pipeline: a generate-and-test loop over `MAX_ATTEMPTS = 12` seed variants (Knuth-decorrelated: `base + attempt * 2654435761`), keeping the first layout to clear `SCORE_THRESHOLD = 0.70` or the best of twelve. It *always* returns a playable layout.
- **`_generate_one`** is the TinyKeep pipeline: place non-overlapping rooms (`ROOM_TRIES = 90`) → assign shapes (rect / circle / irregular) → Delaunay over room centers (`Geometry2D.triangulate_delaunay`) → Kruskal MST for connectivity → re-add `loop_fraction` (default 0.32) of non-MST edges → carve 3-wide L-corridors → score → assign roles+themes → dress → scatter gather nodes.
- **Quality scoring** (`dungeon_score.gd`, 6 metrics) gates on `connectivity == 1.0` (BFS flood-fill) and bands `critical_path / room_count / floor_ratio / corridor_ratio / dead_ends`. Crucially, `_score_cfg(cfg)` **shifts the acceptance bands per chart** — a 28-grid Snug uses tighter room-count bands so it doesn't silently degrade to a best-of-12 fallback.
- **The boss room** is the BFS-farthest room from entry (`_farthest_room`), forced to a full rectangle (the arena seal needs clean edges).
- **`cfg` is the chart's `gen` block** (`charts.gd` → `Game.run_cfg()`): `grid / room_min / room_max / room_count_* / loop_fraction / corridor_ratio_max / boss_kind / scope / tier / affixes`. This is the **biome seam** — the whole differentiator is data, not code.
- **`layout_loader.gd` consumes the layout**: `SPAWN_TABLES` keyed on `scope` ("snug" / "hollow" / "briar_maze" / "crypt") pick the weighted enemy mix; `BOSS_KINDS` / `ENEMY_KINDS` carry per-kind stats; affix modifiers (`_read_chart_modifiers`) multiply HP/density/speed; `_scatter_gather_nodes` reads good-twin bias affixes (`GATHER_BY_AFFIX`) into ore/forage/log decor.
- **Seed determinism for co-op already works**: in a chart run, `layout_loader._ready()` seeds `_rng` from `chart_seed ^ 0x5DEECE66`, so every peer builds *identical* tiles, kinds, elites, and jitter — the host syncs state, never spawns (`net_spawn`, `NetFoe%d` deterministic naming).

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**A new biome is a kit over this generator, never a new engine** (P2). The Pale Veins (Pillar One) ships as: a `scope` string, a `gen` block, a `SPAWN_TABLES` row, a `ROOM_THEMES` set, a tileset, and a few affix/ink rows. Concretely the kit touches exactly these seams:

1. **Scope → spawn table.** Add `"pale_veins"` to `SPAWN_TABLES` (e.g. `[["hedgewight", 45], ["skitterling", 30], ["rat", 25]]`). One data line gives the biome its creature feel.
2. **Theme pool → dressing.** Add stone themes (`pale_vault`, `branching_seam`, `ore_gallery`) to `ROOM_THEMES` with focal+satellite rules pointing at Pale-Veins tile GLBs, and a `COMBAT_THEMES` row for the region. The "no two adjacent rooms share a theme" rule and flush-to-wall placement (spec 28) are inherited free.
3. **Affix bias → generation.** Extend `GATHER_BY_AFFIX` with the region's signature node (a `pale_vein` ore-rock variant), so a good twin seams real ore into the walls. The **branching-seam gather minigame** (Pillar One spine depth) is a generation concern: when an `ore_rock` is mined, the gather node exposes 1–2 *pre-placed-but-dormant* adjacent nodes — so `_scatter_gather_nodes` must place small clusters, not lone rocks, and tag the satellites `dormant: true` for the runtime to reveal. This makes the lore anchor ("passages that branch into other things") **mechanical**.
4. **Boss-as-affix → arena.** The Burrow Boar already exists in `BOSS_KINDS`; the Pale Veins houses it by gating `burrow_boar_den` behind the `tusker_tusk` trophy (already wired in `TROPHY_TO_AFFIX`). The collapsing-vein gimmick is a per-room layout hook, below.

**Diegetic legend & rumor header (P3).** A deterministic one-line storybook blurb composes from `template + scope + resolved affixes` (string-table fragments, *not* generation logic). This is the cheapest place to make a chart *feel like* its biome — near-zero authoring per run.

### Data model & formulas (concrete, GDScript-flavored)

The biome kit is fully expressible as **data tables added to existing dicts** — no new `_generate_one` branches:

| Seam | File / dict | Pale Veins addition |
|---|---|---|
| `scope` | `charts.gd` template `scope` | `"pale_veins"` |
| spawn table | `layout_loader.SPAWN_TABLES` | `pale_veins: [[hedgewight,45],[skitterling,30],[rat,25]]` |
| creature stats | `layout_loader.ENEMY_KINDS` | `hedgewight: {model, scale, hp, damage, speed, atk_cd}` |
| themes | `dungeon_gen.ROOM_THEMES` | `pale_vault / branching_seam / ore_gallery` |
| combat themes | `dungeon_gen.COMBAT_THEMES`(per-region) | the stone themes |
| tile GLBs | `layout_loader.DECOR_MODEL` + `DECOR_COLLIDER` | ~20 Pale-Veins meshes |
| gather bias | `dungeon_gen.GATHER_BY_AFFIX` | `pale_vein: {ore_rock, palechalk_ore, count:[3,5]}` |
| affixes/inks | `charts.gd.AFFIXES` / `INKS` | Stoneflesh twin + Palechalk Ink |

Scoring constants stay shared; only the **bands** flex via `gen` block keys (`floor_ratio_min/max`, `corridor_ratio_max`, `room_count_*`). The acceptance gate is:

```
accept(layout) := score.connectivity == 1.0
              and SCORE_THRESHOLD <= weighted_sum(6 metrics within their cfg bands)
```

**Per-room layout hooks (the new generic primitive Pillar One adds).** Boss gimmicks that touch the *grid* (Boar's collapsing veins, Hedgemother's thorn-arena) generalize cleanly: a room may carry a `hazard` tag the runtime reads. The collapsing-vein is a set of `breakable_wall` decor entries on the boss-room perimeter that the Boar's tusk-quake converts to floor — reusing the existing `Breakable` wrapper (`DECOR_BREAKABLE`) and the arena-gate machinery (`_make_arena_gates`). This stays *one generic hook* (`room.hazard`), not per-boss generator code — the Into the Breach lesson: telegraphed, grid-legible hazards over hidden scripting.

### Content to author (tiers / tables / worked examples)

A biome kit's generation-facing deliverables (the P2 checklist, generation slice):

- **~20 tile GLBs** sorted into theme focal/satellite roles (a focal owns room center; satellites arrange by `walls/corners/cluster/scatter`). Author against the locked `--cref` stem; systems-first on **tinted dummy clones** with dummy-debt tracked (P5).
- **1 spawn-table row** (4-creature family weights) + **4 `ENEMY_KINDS` stat blocks**.
- **3 theme entries** with focal+satellite rules; a **per-region `COMBAT_THEMES`** list.
- **1–2 ASCII setpiece templates** in `data/rooms/` (the `_load_template` / `SETPIECE_DECOR` path) — the Spelunky lesson: hand-authored chunks inside procedural assembly buy authored feel for cheap.
- **1 gather-bias row** + the branching-seam dormant-cluster tag.
- **Worked example — a Pale Veins delve:** chart `{template: hollow, scope: pale_veins, tier 2, affixes:[pale_vein(good), stoneflesh(good)], seed}` → generator places 6 rooms on a 48-grid, MST + 0.32 loops, boss room = BFS-farthest, themes drawn from the stone pool (no two adjacent the same), 3–5 palechalk seams scattered as dormant clusters, Hedgewight/skitterling/rat spawned by depth, Boar gated only if `burrow_boar_den` was inked. The summary card reads: *"A wallow in the Pale Veins, where the stone branches into other things."*

### Edge cases, failure modes, anti-frustration

- **Generation never fails open.** `generate` always returns the best-of-12; `rooms.size() < 2` falls back to two fixed rooms; `_delaunay_edges` degenerates to a nearest-neighbour chain on <3 centers. A degraded layout is *playable*, just less pretty — correct for a cozy game.
- **Connectivity is a hard gate** (`== 1.0`): an unreachable boss room is the one unacceptable failure. The MST guarantees it; the score asserts it.
- **The abandon stone** (`layout_loader._build_exit_waystone`) always spawns at entry: a boss chart can never soft-lock a player who can't fell the boss — they walk home for nothing but they walk home (cozy contract, Balance Philosophy §2).
- **Tighten bands with the grid** or small charts silently degrade — `_score_cfg` already does this; any new biome with a non-default grid **must** ship matching `room_count_*` / `floor_ratio_*` bands or the on-demand balance-sim flags it.
- **Co-op determinism is fragile to `randf()`.** `_read_chart_modifiers`/`_build_enemies` already weave in non-seeded `randf()` calls for trophy rolls — these must route through the chart-seeded RNG or peers diverge. Guard with a co-op build-parity check.
- **Decor must never block a corridor mouth** (`_is_corridor_mouth`) — inherited; new tiles get it free.

## Interlocks — how this feeds/uses other systems

- **[[Charts]] / [[Chart Loop]]** — the `gen` block + seed *are* the chart; generation is the loop's payoff renderer. The summary card reads live odds off the same `compute_weights`/`effective_stability`.
- **[[Affixes]]** — good-twin bias affixes drive `_scatter_gather_nodes`; modifier affixes drive `layout_loader._read_chart_modifiers`; boss-den affixes choose `bossKind`. New biomes ship *flavored variants of the existing ~9 affixes*, not a new roster (P3, the affix-budget risk).
- **[[Gather Nodes]]** — generation *places* the nodes; the branching-seam minigame is a generation-time dormant-cluster placement.
- **[[Enemies]] / [[Bosses]]** — `scope` picks the spawn table; the boss room is the generator's farthest-room output; per-room `hazard` tags carry boss-gimmick grid effects.
- **[[Combat]]** — room roles + BFS depth drive density and the calm→dense pacing into the boss.
- **[[Multiplayer Co-op]]** — seed determinism means every peer builds identically; the host syncs state only.
- **[[Save System]]** — the chart (not the built layout) persists; a delve rebuilds deterministically from the seed, so no map blob is saved.

## Demo scope vs Horizon

**Demo (Pillar Zero + One, built now):**
- Crypt retrofit to the biome-kit template (it already *is* one) — the reference kit. **DEMO**
- The **Pale Veins kit** produced *purely by cloning* — no new generator code (Phase-1 exit criterion). **DEMO**
- The generic **`room.hazard` layout hook** for the Boar collapsing-vein + Hedgemother thorn-arena gimmicks. **DEMO**
- **Branching-seam dormant-cluster** placement (spine depth). **DEMO**
- Pale-Veins-flavored affix variants + Palechalk ink bias into `GATHER_BY_AFFIX`. **DEMO**
- Procedural rumor header + summary card (strings over existing math). **DEMO**

**Horizon (named, NOT built — P7 cut-line):**
- **Echo Charts** (`generateEchoLayout` — capture the overworld grid as a dungeon). Designed in `cartography-systems.md`, never ported. **HORIZON**
- The **Deepening ladder** (+1 affix slot per depth rank, *density not bigger bosses* — the lore-safe long-tail; first post-demo system). **HORIZON**
- Briarward (re-skinned shipped Briar Maze, houses the Wolf) + the Summit, as kits cloned later. **HORIZON**
- Affixes-as-rule-changers altering *topology* across many biomes. **HORIZON**
- The schema/cross-ref linters — deferred until a *second* biome exists to cross-reference (P10). **HORIZON**

Anti-escalation holds at the generator level: the Summit is the same `hedgemother_v2` silhouette scaled, in a `crypt`-scope chart — **no King of Brambles, no new boss class** (P6). Generation never introduces a creature larger or worse than the Hedgemother.

## Implementation notes (Godot)

- **Generator:** `wyrd/scripts/dungeon_gen.gd` (static, pure) + `wyrd/scripts/dungeon_score.gd`. New biome = data added to `ROOM_THEMES` / `GATHER_BY_AFFIX`; the `room.hazard` hook is a small `_generate_one` addition.
- **Consumer / build:** `wyrd/scripts/layout_loader.gd` (`SPAWN_TABLES`, `ENEMY_KINDS`, `BOSS_KINDS`, `DECOR_MODEL`/`DECOR_COLLIDER`). The collapsing-vein reuses `breakable.gd` + `_make_arena_gates`.
- **Chart data:** `wyrd/data/charts.gd` (`TEMPLATES.gen`, `AFFIXES`, `INKS`); `wyrd/data/affixes.gd` is the *gear* affix helper (distinct from chart affixes — don't conflate).
- **Setpieces:** ASCII templates under `wyrd/data/rooms/`.
- **Tests:** `test_wyrd_dungeon_scene.gd` guards the build (layout → scene); `test_wyrd_loop.gd` guards the chart→run path; both must stay green. Add a **co-op build-parity assertion** (two seeded builds produce identical decor/enemy lists) and an **on-demand balance-sim** check that new bands don't degrade every chart to best-of-12.
- **Perf:** the ~20-tile kit must hit the desktop Forward+ 60fps budget — instance repeated wall/floor tiles, cap enemy count so the Boar fight + room density stay in budget (§6 perf workstream).

## Open questions

- **Branching seams as topology vs decor:** dormant-cluster placement (decor) is cheap and deterministic; mutating the *grid* mid-run (true branching passages) breaks co-op determinism unless every reveal routes through the chart-seeded RNG. Lean decor for the demo.
- **Theme adjacency across biomes:** does the "no two adjacent rooms share a theme" rule need a per-biome theme count floor (≥3) to avoid a checkerboard of two themes? Likely yes — make it a kit-checklist line.
- **Echo Charts determinism:** capturing a live overworld grid is inherently non-seed-deterministic for co-op — does the host snapshot and broadcast the grid? Defer until co-op chart-reader seat (Horizon).
- **Should `room.hazard` be a generic tag or a closed enum?** A closed enum keeps the balance-sim able to reason about it; an open tag is more flexible. Lean closed enum for the demo.

## See also / Sources

- [[Dungeon Generation]] · [[Charts]] · [[Chart Loop]] · [[Affixes]] · [[Gather Nodes]] · [[Enemies]] · [[Bosses]] · [[Combat]] · [[Multiplayer Co-op]]
- [[Universe Build-Out Plan]] · [[Balance Philosophy]]
- [[Spelunky]] (authored chunks in procedural assembly) · [[Dead Cells]] (fixed map + procgen internals; concept-graph room constraints) · [[Caves of Qud]] (hybrid fixed/procgen; seed-as-chart) · [[Hades]] (run-authored difficulty as affixes) · [[Into the Breach]] (telegraphed grid-legible hazards)
- Code: `wyrd/scripts/dungeon_gen.gd`, `wyrd/scripts/layout_loader.gd`, `wyrd/data/charts.gd`, `wyrd/data/affixes.gd`
