---
type: design
tags: [system-design, items-economy]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/entities/Items and Gear.md"
  - "kb/wiki/systems/Economy.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/games/arpg/Diablo III.md"
  - "kb/wiki/games/arpg/Path of Exile.md"
  - "kb/wiki/games/arpg/Last Epoch.md"
  - "kb/wiki/games/arpg/Diablo II.md"
  - "wyrd/data/items.gd"
  - "wyrd/data/drops.gd"
  - "wyrd/data/economy.gd"
  - "wyrd/data/charts.gd"
  - "wyrd/scripts/game.gd"
---

# Items Gear and Economy — Deep Design
> Forward-looking deep design. Current-state: [[Items and Gear]], [[Economy]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine
You are a Wayfinder who *brings the den home*. The boss you quieted leaves a raw thing — a boar's tusk, a wolf's fang, a hedge-thorn — and the meaning of that trophy is not made in the dungeon but at the chartmaker's bench, where you **inscribe it into your Ledger** and it becomes a small, permanent way you walk the Wolds differently. That is the whole itemization fantasy: *you go home to craft, not just to sell* (plan §4.5). Gear itself stays deliberately shallow — one verb, the bow, never a new weapon class or tier (P8) — so the emotional weight of "what did I earn" lands on the **trophy ritual** and on the **inks** that are the economy's value spine (P12). Loot stays a gift, never noise (the D3 smart-drop lesson, [[Diablo III]]); inflation is structurally impossible because the things you'd hoard are *consumed* to make charts (the PoE currency-as-crafting lesson, [[Path of Exile]]).

## What ships today (grounded in code)
Loot is already whole and tested. `drops.gd::roll_drop(role, depth)` rolls a tier per kill — `_roll_tier()` is `min` of two d10 biased up by `ROLE_TIER_BIAS` and `depth/2`, bosses clamped to tier ≥ 8 and dropping `BOSS_DROP_COUNT = 3`. `_tier_to_rarity()` maps to normal/magic/rare/unique; `items.gd::make_item()` then rolls 0/1/3/predefined affixes (`N_AFFIXES`). `_pick_kind()` already **excludes** trade tools (pickaxe/axe) and the capstone `warbow`/`starsilver_band` from random loot — those are anvil-forged. Two uniques ship (`UNIQUES`: Whispering Yew, Coatcap of the Bramble) with graceful rare fallback. The gold loop is one faucet, one sink: `economy.gd::SELL_BY_RARITY` (4/12/35/90 by rarity) and `WARES` (herb/logs/ore/three inks), with the **no-arbitrage gate** asserted in `test_wyrd_loop.gd::_test_economy_gate` and deep ores (palechalk/starsilver/hedgesteel) kept off Hod's shelf by construction. The trophy→den mechanic is also live but is a *different* mechanic from this design: `charts.gd::TROPHY_TO_AFFIX` consumes `thorn_essence`/`tusker_tusk`/`wightpelt` as **chart inputs** to guarantee a boss-den affix (`inscribe()`, `craft_cost()`). This design adds a *second, non-consuming* path for a *raw* trophy and leaves the den-inking path untouched.

## Deep design
### Core mechanics (precise, Wayfinder-flavored)
- **The Wayfinder's Ledger.** A single charm object the player owns from the first boss kill — not a gear slot, not in the Tetris pack. It holds up to **N inscribed trophy-boons** (demo `N = 3`, one per shipped boss). Boons are **flat, small, capped, and horizontal** — never raw damage, never a stat that scales (per P8 and [[Balance Philosophy]] "gold/power is comfort, not power").
- **The two-beat ritual.** (1) A boss drop yields a **raw trophy** to the satchel (distinct from the chart-input trophy material). (2) At the inscribing bench, `inscribe_ledger(trophy_id)` consumes the raw trophy + a small ink cost and writes a permanent line into the Ledger. Reuses the existing inscription verb and bench UI — **no new tech** (plan §4.5).
- **Demo boons** (each a named line, all horizontal): Boar tusk → **+knockback resistance**; Wolf fang → **+1 dodge i-frame**; Hedgemother thorn → **bleed lands full-duration on bosses**. None changes a damage number; all change *how you read and respond* — the same lens combat uses (P8).
- **The dissolve sink.** `dissolve_to_inkdust(item)` melts an unwanted gear item into **ink-dust**, a currency-material that tops up an ink pot. This routes loot overflow *back into the value spine* rather than only into gold (P12). It is the cozy mirror of D2/LE shatter-salvage ([[Last Epoch]]) but feeds the ink economy, not a gear-crafting tree.
- **No-arbitrage as canon.** "Top-of-ladder materials are gather-only" is promoted to an ADR with a test assertion: a deep material may **never** be both shelf-stocked and a peak recipe input. This is what makes the dissolve sink safe — ink-dust can supplement a pot but can't manufacture a deep ink whose recipe needs a gather-only ore.

### Data model & formulas (GDScript-flavored)
The Ledger is a save-versioned array; boons are pure data so the balance-sim can assert no raw-damage creep.

```gdscript
# data/ledger.gd
const TROPHY_BOONS := {
    "boar_tusk":       {"name": "Boar's Footing",   "stat": "knockback_resist", "value": 0.30},
    "wolf_fang":       {"name": "Wolf's Step",       "stat": "extra_iframe",     "value": 1},
    "hedgemother_thorn":{"name": "Thornbound",       "stat": "boss_bleed_full",  "value": true},
}
const LEDGER_CAP := 3            # demo: one slot per shipped boss
const INSCRIBE_INK_COST := {"refined_ink": 1}
```

`game.gd::inscribe_ledger(trophy_id)` → check `material_count(raw_trophy) >= 1` and `can_afford(INSCRIBE_INK_COST)` → spend both → append `TROPHY_BOONS[trophy_id]` to `ledger` → emit `gear_changed` so `_derive_stats()` folds boons in alongside equipment affixes (the existing derive path). `dissolve_to_inkdust(item)` → `add_material("ink_dust", DISSOLVE_YIELD_BY_RARITY[item.rarity])` and remove the item.

| Lever | Value | Why |
|---|---|---|
| `LEDGER_CAP` | 3 (demo) | one boon per shipped boss; no stacking |
| ink-dust yield (normal→unique) | 1 / 2 / 4 / 8 | rarity feeds the sink proportionally |
| ink-dust → pot top-up | 4 dust = 1 pot-equivalent | always worse than gathering (no-arbitrage) |
| boon power budget | 0 raw-damage points | horizontal-only, balance-sim asserted |

The **no-arbitrage assertion** extends `_test_economy_gate`: for every `INK_RECIPES` entry whose inputs include a deep material, assert that material `not in WARES` AND `ink_dust` cannot substitute for it.

### Content to author (tiers / worked examples)
- **3 raw-trophy items** + 3 Ledger boon lines (above), each with a WORLD_LORE-voiced Codex entry on first inscription (e.g. "Boar's Footing — *you have stood where the boar stood; the ground knows your weight now*").
- **`ink_dust` material** + its top-up recipe wired into `mix_ink`/the still.
- **Worked example (no-arbitrage holds):** a Magic Longbow sells 12 g and dissolves to 2 ink-dust. 2 dust < the gather-cost of one hedge ink pot's herbs, so dissolving is a *convenience* path, never a faucet — gathering stays cheapest, exactly as the gate demands ([[Balance Philosophy]] §5).
- **Worked example (boon is horizontal):** Thornbound makes bleed land full-duration on a boss — it changes the *value of reading the bleed window*, the boss TTK target band (30–60 s) is unchanged because no damage number moved.

### Edge cases, failure modes, anti-frustration
- **Ledger full:** inscribing a 4th boon (Horizon) needs an explicit overwrite confirm; in demo, all three fit, so this is a guard, not UI.
- **Trophy lost:** raw trophies persist in the save'd satchel; they are never auto-consumed by the den-inking path (`TROPHY_TO_AFFIX` uses the *separate* trophy-material ids).
- **Dissolve regret:** confirm-on-dissolve for rare+ items; uniques warn loudly (the one place loot is precious).
- **The D3 trap:** no trading, no auction, no market — a boon is earned by quieting a boss, full stop (the [[Diablo III]] RMAH lesson is the reason this is hard-coded out, not deferred).
- **Inflation:** because dissolve feeds *consumable* ink and gold has one sink (Hod's shelf), there is no hoardable store of value to inflate (the [[Path of Exile]] structural fix).

## Interlocks
- **[[Charts Affixes and Inks — Deep Design|Charts/Inks]]:** dissolve feeds ink-dust into the **ink value spine** (P12); the Ledger reuses the inscription verb the bench already runs. Note the *two distinct* trophy paths — chart-input (consumed for a den affix) vs Ledger (consumed for a permanent boon).
- **[[Combat — Deep Design|Combat]]:** every boon is a reading/response lever (i-frame, knockback-read, bleed-window), matching the one-verb-deepened-by-reading doctrine (P8/P9). The boss drops that seed the Ledger come from the trophy chain.
- **[[Crafting and Inks — Deep Design|Crafting]]:** ink-dust enters via the still/ink-mix; the anvil still forges the gear ladder and the no-arbitrage gate guards both.
- **[[Gathering — Deep Design|Gathering]] & [[Trades and Leveling — Deep Design|Trades]]:** deep ores stay gather-only (the ADR), keeping tier-2 charts the only road to the top of the ladder.
- **[[Chart Loop — Deep Design|Chart Loop]]:** the trophy chain (Hedgemother → Boar → Wolf → Summit) is the only faucet for raw trophies; town grows as the chain is walked (P4), so the Ledger is town-anchored.

## Demo scope vs Horizon
| Feature | Scope |
|---|---|
| Wayfinder's Ledger + 3 boons (Boar/Wolf/Hedgemother) | **DEMO** (Pillar One ships the Boar boon; crypt seeds the Hedgemother) |
| Dissolve-to-ink-dust sink | **DEMO** |
| No-arbitrage ADR + test assertion | **DEMO** (Phase 0 ADR) |
| Raw-trophy item + Codex line per boss | **DEMO** |
| Inscribed-gear temper budget (Hod's Anvil) | **HORIZON** (P7 — only if a region needs it) |
| Uniques-as-mechanics roster expansion | **HORIZON** |
| Bramblewood Weaves / sockets | **HORIZON** |
| Smart drops (class-stat bias) | **HORIZON** (one-verb game makes it low-value now) |
| Ledger cap > 3 / overwrite UI | **HORIZON** |

The hard cut-line (P7): no new gear tier, no new weapon class, ever — the demo's *entire* itemization addition is the Ledger ritual + the dissolve sink. Everything richer is named, unbuilt (plan §10.7).

## Implementation notes (Godot)
- **New:** `wyrd/data/ledger.gd` (`TROPHY_BOONS`, caps, costs — pure data). `Game.inscribe_ledger()` and `Game.dissolve_to_inkdust()` in `scripts/game.gd` beside `mix_ink`/`sell_item` (lines ~324–549).
- **Touch:** `drops.gd` boss path to emit the raw-trophy material on a boss kill; `items.gd`/`gather.gd` for the `ink_dust` material; `economy.gd` only if Hod ever shelves dust (he won't, by ADR).
- **Derive:** fold Ledger boons into the existing `_derive_stats()` on the `gear_changed` signal (no new derive path).
- **UI:** the Ledger is a panel on the inscribing bench surface — must pass `wyrd/tools/check_ninepatch.py` and get a `WYRD_UI_SHOT` capture (plan §6 UI workstream).
- **Save:** Ledger array + raw-trophy satchel entries go through the **migration ladder** (Phase 0), never a destructive reset.
- **Guarded by:** `test_wyrd_loop.gd` — extend `_test_economy_gate` with the no-arbitrage assertion (deep material never shelf-stocked nor dust-substitutable); add a `_test_ledger_boon_horizontal` asserting no boon touches a raw-damage stat. The four headless suites stay the only hard gate (P10); the balance-sim validates boon power on demand.

## Open questions
- Does the Ledger boon apply in co-op per-player or party-pooled? (Host-authoritative contract, plan §4.6 — likely per-player, resolve before persisted shared data.)
- Should dissolving a *unique* yield a keepsake (Codex line) so it never feels purely destructive?
- Is one raw-trophy-per-boss-kill the right faucet, or one per *chain leg completed* (rarer, more ceremonial)?
- Where does ink-dust top-up sit relative to discovered-ink recipes — supplement only, or can it ever complete a known recipe?

## See also / Sources
- [[Items and Gear]] · [[Economy]] · [[Balance Philosophy]] · [[Charts Affixes and Inks — Deep Design]] · [[Combat — Deep Design]] · [[Crafting and Inks — Deep Design]] · [[Universe Build-Out Plan]]
- [[Diablo III]] (RMAH / smart-drop lessons) · [[Path of Exile]] (currency-as-crafting) · [[Last Epoch]] (salvage/forging) · [[Diablo II]] (charm/socket horizontal boons)
- Code: `wyrd/data/items.gd`, `wyrd/data/drops.gd`, `wyrd/data/economy.gd`, `wyrd/data/charts.gd`, `wyrd/scripts/game.gd`
