---
type: design
tags: [system-design, gathering]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Gathering.md"
  - "kb/wiki/entities/Gather Nodes.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/data/gather.gd"
  - "wyrd/scripts/gather_node.gd"
  - "wyrd/scripts/dungeon_gen.gd"
  - "kb/wiki/games/life-sim/Stardew Valley.md"
  - "kb/wiki/games/life-sim/Rune Factory 4.md"
  - "kb/wiki/games/life-sim/My Time at Portia.md"
  - "kb/wiki/games/sports/Osu!.md"
---

# Gathering — Deep Design

> Forward-looking deep design. Current-state: [[Gathering]] (and [[Gather Nodes]]). Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder who *reads stone and green like a page*. Gathering is the **first beat of the spine** (`gather → craft → chart → delve`, ADR 0003) and, per P1, the place the demo spends its *most* new design budget — not a solved substrate. The fantasy is quiet competence: you walk a vault wall-to-wall, you learn the grain of a Pale Veins seam, and the stone *answers* — never punishes. Where [[Combat — Deep Design|combat]] is deliberately short, this doc is deliberately long: that word-budget inversion **is** the spine-protection signal P1 demands. The differentiator the plan protects is that gathering in the Pale Veins becomes a tiny **reading-and-response** craft of its own — the same verb-philosophy as the bow, applied to the rock.

## What ships today (grounded in code)

The gather loop is **whole, well-built, and upside-only** already:

- **Channel verb** — `gather_node.gd::interact()` starts a timed channel; `_process()` cancels on >0.6 m move, death, or HP loss (`_channel_start_hp`). One `E`-press, one harvest, material to the `Game` satchel + Trade XP via `_harvest()`. `channel_seconds()` is the single source of truth (tool `gather_speed`, `quick_mining` ×0.65, `light_hands` ×0.75, Quickroot tonic, Barren-Veins ×1.33).
- **Three kinds, tiered** — `gather.gd::NODE_KINDS` (`ore_rock`/`forage_node`/`log_pile`); `ORE_TIERS` (5, Earthcraft 1–15) and `HERB_TIERS` (6, Wildcraft 1–16). XP/sec climbs +2.5/tier, channel +0.4 s/tier. Locked veins are **visible and named** ("Bogiron Vein — needs Earthcraft 3") — *coveted, not hidden*.
- **Perks & bonus yield** — `Game.gather_bonus(kind)` centralizes deterministic + chance yield (Sturdy Swings, Rich Seams' guaranteed second deep lump, Wellspring's chart +1).
- **Placement** — town patches regrow (`respawns`, 20/30/40 s); dungeon nodes deplete per run, scattered by `dungeon_gen.gd::_scatter_gather_nodes()` from good-twin affixes (`mineral_vein`/`bramble_bloom`/`herbal_patch`/`wood_grove`), tier rolled by `_roll_tier()` against chart tier.
- **Feeds craft directly** — gathered mats are ink inputs in `gather.gd::INK_RECIPES` (e.g. `chalkwash_ink` = palechalk + 2 wild_herb), which feed inscription. The faucet→sink → no-arbitrage gate ([[Balance Philosophy]] §5) is tested.

**What's missing (this doc's job, Pillar One):** every harvest is the *same* hold-to-channel. There is **no vein-reading**, **no branching seams**. The plan names both as the headline spine-depth for the Pale Veins (§4.2). They are net-new.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

Two new gather interactions, both **generous and upside-only** (cozy contract, [[Balance Philosophy]] §2), introduced at **`ore_rock` in the Pale Veins** and authored to generalize later.

1. **Vein-reading (a grain-direction timing/aim minigame).** A Pale Veins ore node shows a faint **grain arrow** (drawn on the channel bar, or as a sweeping highlight along the vein). During the channel a marker sweeps; the player taps `E` *with the grain* inside a **generous window**. The osu!-style read here is deliberately the *opposite* of osu! difficulty: the window is wide, the tempo slow, and — crucially — **a miss is never a loss**. Hit-with-grain = a **bonus chunk** + a roll at **deep ore** (the Wayfinding-ink feed). Miss = the base yield you'd have gotten anyway. This is "skill-indexed progression without zero-sum competition" (Osu! relevance note) tuned cozy: the floor is the current game; the ceiling is new.
2. **Branching seams.** "Passages that branch into other things" — the region's lore anchor made mechanical. On harvest, a Pale Veins node has a chance to **expose 1–2 adjacent nodes** at floor-adjacent tiles (re-using the `_scatter` placement check for floor/occupancy). A *clean* vein-read raises that chance. This turns a vault into a tiny spatial puzzle — clear a wall and the seam keeps giving — and rewards the RF4-style "walk it wall-to-wall" rhythm without ever forcing it (ignore the branch and nothing is lost).

Both are **`ore_rock`-only for the demo** (Earthcraft is the demo's deepened trade, §4.1). Forage/chop keep today's plain channel; the interactions are authored so a future biome can flag forage nodes in too.

### Data model & formulas (GDScript-flavored)

Add a **reading layer** on the node, gated behind a per-node flag so the common path stays cheap (mirrors how Poise lives only on `boss.gd`):

```gdscript
# gather_node.gd additions — only set on Pale Veins ore nodes
var grain_read := false       # this node supports vein-reading
var _grain_hit := false       # set true if the tap landed in-window
const GRAIN_WINDOW := 0.28     # seconds — GENEROUS (vs osu's ~0.05); cozy-tuned
const BRANCH_BASE := 0.35      # base chance to expose adjacent node(s)
const BRANCH_ON_READ := 0.65   # chance when grain was read clean
```

| Term | Value | Notes |
|---|---|---|
| Grain window | ±0.28 s around the marker | wide; auto-pass if input lag is high (clamp, not punish) |
| Read bonus | +1 chunk, always | the floor for a clean read |
| Deep-ore roll on read | 20 % → `pale_deepore` | the Wayfinding-ink feed (Earthcraft → Wayfinding cross-trade, §4.1) |
| Branch chance | 0.35 base / 0.65 on read | exposes 1–2 nodes; chains, but each new node is its own roll so it self-terminates |
| Branch depth cap | 1 generation per harvest | a node spawns neighbours; *those* re-roll on their own harvest — no infinite cascade |

The grain-read result feeds the **existing** yield path: it adds to the `got` accumulator in `_harvest()` exactly where `gather_bonus` and Rich Seams already add, so no new yield system. Deep ore (`pale_deepore`) is a new `MATERIALS` entry whose **only** sink is the Palechalk ink-refine step — keeping it gather-only by construction (the no-arbitrage ADR, [[Balance Philosophy]] §5; deep ores are never shelf-stocked).

### Content to author (tiers / tables / worked examples)

- **`pale_deepore`** material (one `MATERIALS` row, gather-only, ink-feed flavor text in [[Voice and Tone]]).
- **Pale Veins ore node flag** in `_scatter_gather_nodes` / `mineral_vein` rolls: when `scope == pale_veins`, set `grain_read = true` on scattered `ore_rock` decor entries (data-only; the engine already routes `scope` to spawn tables).
- **Worked example (one Palechalk vein, Earthcraft 8, Pale Veins chart):** channel 2.0 s. Player taps with the grain → +1 chunk (base 1 + bonus 1 = 2 palechalk) and a 20 % roll yields a `pale_deepore`; on harvest, a 0.65 branch roll exposes one adjacent Palechalk vein. Net: a single dive into a vault wall snowballs into 2–4 reads, ~1 deep ore, enough to refine one **Palechalk Ink** at the bench — which stabilizes one inscription. The whole spine arc (`gather-read → branch → refine → ink → chart`) sits inside one room.
- **Almanac tie-in (minimal, P1):** one of the 1–2 demo Almanac pages requests *"three reads with the grain"* — teaching vein-reading diegetically and restoring a walkable town corner on completion (the Stardew-bundle / Portia-commission pattern, scoped tiny).

### Edge cases, failure modes, anti-frustration

- **A miss must never feel like a loss.** The base yield is granted regardless; the read only *adds*. A blind tester who never notices the grain still plays the shipped game (P1 spine-growth check is "names a new thing they liked," not "was gated by it").
- **Input-lag fairness** (Osu! relevance note): the window is set wide *because* refresh-rate/latency varies; if `WYRD_FAST_CHANNEL` is set (tests) or the channel is sub-frame, auto-grant the read so `test_skills`/loop suites stay deterministic.
- **Branch cannot soft-lock or flood.** Each branch is one generation; placement re-uses the floor/occupancy guard, so a tiny room simply branches fewer times. Cap total nodes per room to keep the perf budget (§ Cross-cutting, P-perf).
- **No grind trap (Portia anti-pattern).** Branching gives *more in one place*, not *longer everywhere* — it shortens the walk between nodes rather than adding queue-and-sleep downtime; the channel stays minigame-lite, never idle.
- **Co-op:** branch spawns and grain windows are **host-authoritative**; the exposed nodes RPC to peers so every screen sees the same seam (correctness, mirrors the boss-telegraph RPC requirement).

## Interlocks — how this feeds/uses other systems

- **[[Crafting]] / inks:** deep ore is the sole input to the **ink-refine** craft step (Palechalk Ink); the new gather depth exists to feed the new craft depth, both shipping together (P3, §4.2). Plain mats keep feeding `INK_RECIPES`.
- **[[Trades and Leveling]] / [[Earthcraft]]:** the demo's pick-one-of-N mastery (Rich Seams **OR** smelt-yield **OR** faster-channel) reads cleanly off the vein-reading path; deep ore is the **two-hop cross-trade chain** to [[Wayfinding]] ink (§4.1).
- **[[Chart Loop]] / [[Affixes]]:** nodes are still placed by good-twin gather affixes; `mineral_vein` in a Pale Veins chart now carries grain-read veins. Bad twins still place nothing — gathering's "good/bad twin" texture is unchanged.
- **[[Dungeon Generation]]:** `scope`-driven placement already exists; vein-reading is a *flag*, not new generator code — satisfying "second biome by cloning" (Phase 1 exit criteria).
- **[[Economy]]:** deep ore stays off [[NPCs|Hod's]] shelf by construction (no-arbitrage ADR); the loop remains gather → craft, never buy → sell.
- **[[Combat — Deep Design|Combat]]:** orthogonal — both are "one verb deepened by reading," a shared design grammar, but no mechanical coupling.

## Demo scope vs Horizon

Respecting the P7 cut-line (no system ships until a region uses it) and P1 spine-growth:

| Feature | Scope |
|---|---|
| Vein-reading (grain timing/aim) on Pale Veins `ore_rock` | **DEMO** (Pillar One headline spine depth) |
| Branching seams (expose 1–2 adjacent nodes) | **DEMO** (Pillar One) |
| `pale_deepore` → Palechalk-ink-refine feed | **DEMO** (the cross-trade chain made tangible) |
| Earthcraft pick-one-of-N mastery touching gather | **DEMO** (Earthcraft only, §4.1) |
| One Almanac page that teaches a read | **DEMO** (minimal, 1–2 pages total) |
| Vein-reading on **forage/chop** | **HORIZON** (other biomes; demo is `ore_rock`-only) |
| Grain-read on all four trades / every biome | **HORIZON** |
| Gather "rule-changer" affixes (Balatro-style) | **HORIZON** (the full affix table, §10) |
| Passive/tamed-monster gather income (RF4 model) | **HORIZON** (named in [[Economy]], not built) |

## Implementation notes (Godot)

- **Data:** `wyrd/data/gather.gd` — add `pale_deepore` to `MATERIALS`; tune constants. The grain-read window/branch chances live as `const`s on `gather_node.gd`.
- **Logic:** `wyrd/scripts/gather_node.gd` — the read marker hooks the existing `_process()` channel tick (the per-0.5 s "beat" tween is already there to anchor a marker UI); the read result lands in `_harvest()`'s `got` accumulator. Branch spawns call into the same scatter/occupancy logic.
- **Placement flag:** `wyrd/scripts/dungeon_gen.gd::_scatter_gather_nodes()` — set `grain_read = true` on `ore_rock` decor when `scope == pale_veins`; branch-spawn re-uses the floor/occupancy guard.
- **UI:** the grain marker rides the existing billboarded channel bar (`_show_bar`/`_set_bar`) — a small extra quad, no new panel, no `check_ninepatch` surface needed (it is world-space, not kit UI).
- **Tests:** guarded by `test_wyrd_dungeon_scene.gd` (nodes spawn/deplete) and `test_wyrd_loop.gd` (gather→satchel→XP→ink, and the no-arbitrage `_test_economy_gate` for `pale_deepore`). Both run with `WYRD_FAST_CHANNEL=1` → auto-grant the read so suites stay green. Balance-sim **script** (on-demand, not a gate, P10) validates deep-ore drop rate vs. ink demand.

## Open questions

- **Grain input:** re-tap `E` (one-button cozy) vs. a directional nudge with the grain? Lean one-button for accessibility and co-op parity.
- **Branch visibility:** do exposed nodes pop in with a shimmer (telegraphed reward) or were they always faintly visible (read-it-yourself)? Pick per the place-identity playtest.
- **Deep-ore rate:** 20 % on read is a starting guess; the balance-sim sets it against how many Palechalk Inks one chart should yield.
- **Forage parity (Horizon):** does Wildcraft want its *own* read (e.g. "snip at the right bloom") so the spine-depth pattern isn't Earthcraft-exclusive long-term?

## See also / Sources

- [[Gathering]] · [[Gather Nodes]] · [[Earthcraft]] · [[Wildcraft]] · [[Crafting]] · [[Trades and Leveling]] · [[Chart Loop]] · [[Affixes]] · [[Economy]] · [[Balance Philosophy]] · [[Combat — Deep Design]] · [[Universe Build-Out Plan]]
- Code: `wyrd/data/gather.gd`, `wyrd/scripts/gather_node.gd`, `wyrd/scripts/dungeon_gen.gd`
- Refs: [[Stardew Valley]] (bundle/energy-verb), [[Rune Factory 4]] (gather→craft→loop, no-dead-actions), [[My Time at Portia]] (commission board; the queue-and-sleep anti-pattern to avoid), [[Osu!]] (timing-window read, latency fairness, skill-indexed-not-zero-sum)
