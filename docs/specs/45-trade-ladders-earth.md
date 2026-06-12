# 45 — Trade Ladders: Earthcraft to 17

> **Outcome**: Earthcraft has a felt unlock at every level from 1 to 17 — two new
> ore tiers (Starsilver E11, Hedgesteel E15), ten new forge recipes, two new
> perks, and a chart-carry table that actually delivers the new ores — all
> additive data in existing table shapes, with the economy gate proven per recipe.

**Status: DESIGN.** Nothing in this file is implemented. ADR 0006 (demo cap 17,
extend the other trades) is the parent decision. One implementation pass lands it.

## Why

The demo caps at 17 (ADR 0006) but Earthcraft's content stops at E10
(`quick_mining`), and E10 itself is perk-only. A Wayfinder at carto 12+ is
running tier-2 Hollows with an Earthcraft trade that has nothing left to want.
This spec extends the ore/recipe/perk tables so every Earthcraft level-up from
10 to 17 unlocks something you can hold, mirroring the cadence already shipped
below 10 (vein → bar → tools → gear → perk).

## Scope

**In:**
- 2 new ore tiers (`ORE_TIERS` + `MATERIALS` entries in `wyrd/data/gather.gd`).
- Chart-carry extension: which ore tiers roll on Mineral Vein per chart tier
  (`dungeon_gen.gd` — lift the inline roll into a data table).
- 10 new forge recipes E10–E17 (`wyrd/data/crafting.gd`), incl. a tier-3 tool set.
- 4 new item kinds (`wyrd/data/items.gd`): starsilver pickaxe/axe, Starsilver
  Band, Hedgesteel Warbow.
- 2 new earth perks at E13/E17 (`game.gd` PERKS).
- Gate math stated per gear recipe (the `_test_economy_gate` law).

**Out (explicit non-goals):**
- No changes to shipped E1–E9 recipes, the XP curve, or Wayfinding's ladder.
- No new Hod wares (deep ores stay gather-only — see gate section).
- No new chart templates or affixes (tier-3 sourcing flagged in open questions).
- Wildcraft/Huntcraft ladders (sibling 45-* specs); the still/ink hooks below
  are notes for those specs, not deliverables here.
- No new vein models — `gather_node.gd` already tints the shared ore prop per
  tier; the new tiers only need a color.

## The ladder at a glance (1–17)

Levels 1–9 ship today and are untouched. The holes being filled: **E10 has a
perk but no recipe; E11–17 are empty.**

| Lv | Unlock | Status |
|---|---|---|
| 1 | Copper Vein · Copper Bar · Bogiron Bar · Shortbow | shipped |
| 2 | Bogiron Pickaxe / Axe (−30% channel) | shipped |
| 3 | Bogiron Vein | shipped |
| 4 | Longbow | shipped |
| 5 | perk **Sturdy Swings** · Bogiron Cap · Bogiron Boots (magic) | shipped |
| 6 | Bogiron Jerkin (magic) | shipped |
| 7 | Palechalk Vein · Cinderbloom Pickaxe / Axe (−45%) | shipped |
| 8 | Copper Ring (magic) | shipped |
| 9 | Palechalk Ring (rare) · Palechalk Longbow (magic) | shipped |
| 10 | perk **Miner's Rhythm** · **NEW: Palechalk Jerkin (rare)** | hole filled |
| 11 | **NEW: Starsilver Vein · Starsilver Bar** | new |
| 12 | **NEW: Starsilver Pickaxe / Axe (−55% channel)** | new |
| 13 | **NEW: perk Rich Seams · Starsilver Band (rare)** | new |
| 14 | **NEW: Starsilver Longbow (rare)** | new |
| 15 | **NEW: Hedgesteel Vein · Hedgesteel Bar** | new |
| 16 | **NEW: Hedgesteel Cap · Hedgesteel Boots (rare)** | new |
| 17 | **NEW: perk Smith's Thrift · Hedgesteel Warbow (rare)** | new |

The cadence above 10 deliberately mirrors below: vein+bar at the tier level
(11/15, like 3 and 7), tools one level after the ore (12, like 2 and 7), gear
filling the gaps, perk levels paired with a recipe so no level-up is
perk-only. XP cost of the stretch is modest on the shared curve
(`xp_for_level(17)=2560`; 15→17 is 544 xp ≈ a dozen hedgesteel swings plus
smelts) — consistent with how fast 8→10 plays today.

## New ore tiers

Names come straight off the World Bible's locked 6-tier metal ladder
(starsilver = tier 4, hedgesteel = tier 5). The shipped game already diverged
from the bible's tier-1 reading of palechalk (it's our E7 deep ore, and
Cinderbloom names the tier-2 tools), so we keep climbing the bible ladder from
where the game actually is. **Coalrose is skipped** — it's the fuel analog
(coal→steel), and the hedgesteel smelt's log input carries that "slow fire"
idea instead. **Wildgold (tier 6) stays in reserve for post-demo.**

XP-per-second climbs a clean +2.5/tier; channel +0.4s/tier:

| Tier | id | req_lv | channel_sec | xp | xp/sec | Vein name | Node color |
|---|---|---|---|---|---|---|---|
| copper | `copper_ore` | 1 | 1.2 | 6 | 5.0 | Copper Vein | shipped |
| bogiron | `bogiron_ore` | 3 | 1.6 | 12 | 7.5 | Bogiron Vein | shipped |
| palechalk | `palechalk` | 7 | 2.0 | 20 | 10.0 | Palechalk Vein | shipped |
| **starsilver** | `starsilver_ore` | **11** | **2.4** | **30** | 12.5 | **Starsilver Vein** | `Color(0.74, 0.79, 0.90)` |
| **hedgesteel** | `hedgesteel_ore` | **15** | **2.8** | **42** | 15.0 | **Hedgesteel Vein** | `Color(0.42, 0.52, 0.45)` |

`ORE_TIERS` additions (gather.gd):

```gdscript
"starsilver": {"item": "starsilver_ore", "req_lv": 11, "xp": 30,
    "channel_sec": 2.4, "name": "Starsilver Vein",
    "color": Color(0.74, 0.79, 0.90)},
"hedgesteel": {"item": "hedgesteel_ore", "req_lv": 15, "xp": 42,
    "channel_sec": 2.8, "name": "Hedgesteel Vein",
    "color": Color(0.42, 0.52, 0.45)},
```

`MATERIALS` additions (gather.gd) — ores ▲, bars ▬, group earthen, voice per
the bible (plain words, soft humor, no fantasy-isms):

```gdscript
"starsilver_ore": {"name": "Starsilver Ore", "icon": "▲", "group": "earthen",
    "desc": "Pale lumps flecked like caught starlight. The deep seams hold them close."},
"starsilver_bar": {"name": "Starsilver Bar", "icon": "▬", "group": "earthen",
    "desc": "Two lumps poured bright. Keeps a shine the forge can't dull."},
"hedgesteel_ore": {"name": "Hedgesteel Ore", "icon": "▲", "group": "earthen",
    "desc": "Dense as old oak-heart and twice as stubborn. The deepest veins in the Wolds."},
"hedgesteel_bar": {"name": "Hedgesteel Bar", "icon": "▬", "group": "earthen",
    "desc": "Smelted slow over good logs. Hod calls it honest metal and says no more."},
```

### Which charts carry the new ores

Today the roll lives inline in `dungeon_gen._scatter_gather_nodes` (tier 1:
copper 55 / bogiron 45; tier 2+: bogiron 50 / palechalk 50). **Critical
finding:** the only tier-3 chart is the Summit, and it has `affix_slots: 0` —
Mineral Vein can *never* roll there. So the deep ores MUST ride tier-2 charts
(Hollow req carto 10, Briar Maze req carto 15 — exactly the charts an E11–17
player runs). A6's rule makes this work: locked veins are visible and name
their level — *coveted, not hidden*. An E9 player seeing a Starsilver Vein
locked at "Earthcraft 11" in a Hollow is the pitch for the next two levels.

Lift the inline roll into a weight table (proposed home: `gather.gd`, beside
`ORE_TIERS`) so the next tier is a data edit:

```gdscript
# Mineral Vein ore-tier roll weights by chart tier. Tier 3 is for future
# tier-3 charts with affix slots; the Summit itself rolls no affixes.
const ORE_ROLLS_BY_TIER := {
    1: {"copper": 55, "bogiron": 45},                     # unchanged
    2: {"bogiron": 35, "palechalk": 35, "starsilver": 20, "hedgesteel": 10},
    3: {"palechalk": 25, "starsilver": 40, "hedgesteel": 35},
}
```

Tier-1 charts are untouched. Tier-2 keeps bogiron/palechalk as the bulk
(70%) but seeds the deep veins at 30% combined — see open question 2 for the
dilution tradeoff and the rejected alternative.

## Forge recipes E10–E17

All new recipes append to `STATIONS.forge.recipes` in level order. Recipe XP
continues the shipped curve (~req×5, rising). Every piece of gear above E9
rolls **rare** (three affixes) — at this depth the forge is making the gear
you finish the demo wearing.

### Smelting

| Recipe id | Name | req_lv | xp | Inputs | Yields | Desc (in voice) |
|---|---|---|---|---|---|---|
| `starsilver_bar` | Starsilver Bar | 11 | 35 | starsilver_ore ×2 | starsilver_bar ×1 | "Two lumps poured bright. Keeps a shine the forge can't dull." |
| `hedgesteel_bar` | Hedgesteel Bar | 15 | 55 | hedgesteel_ore ×2, logs ×1 | hedgesteel_bar ×1 | "Smelted slow over good logs. The stubbornest bar this side of the Summit." |

The hedgesteel smelt's log input is a deliberate cross-trade pull (Wildcraft
chopping feeds deep smithing) and stands in for the bible's coalrose/steel idea.

### Tier-3 tools (−55% channel)

Pattern continues Bogiron (−30%, 1 bar + 1 log) → Cinderbloom (−45%, 2 chalk +
1 bar + 1 log) → **Starsilver (−55%, 2 bars + 1 log = 4 ore + 1 log)**. The
−10-point step costs roughly double the ore of the prior set — the answer to
"what does −55% cost": a session of E11+ mining, not a vendor trip.

| Recipe id | Name | req_lv | xp | Inputs | Yields | Desc |
|---|---|---|---|---|---|---|
| `starsilver_pickaxe_smith` | Starsilver Pickaxe | 12 | 45 | starsilver_bar ×2, logs ×1 | `starsilver_pickaxe`, normal | "Starsilver-tipped. Mining in less than half the time." |
| `starsilver_axe_smith` | Starsilver Axe | 12 | 45 | starsilver_bar ×2, logs ×1 | `starsilver_axe`, normal | "Starsilver-edged. Chopping in less than half the time." |

No tier-4 tool set in the demo (open question 5 — wildgold, post-cap).

### Gear

| Recipe id | Name | req_lv | xp | Inputs | Yields | Desc |
|---|---|---|---|---|---|---|
| `palechalk_jerkin_smith` | Palechalk Jerkin | 10 | 55 | palechalk ×3, bogiron_bar ×2, logs ×1 | `leather_chest`, rare | "Chalk-plated over oiled leather. Rolls three affixes." |
| `starsilver_band_smith` | Starsilver Band | 13 | 60 | starsilver_bar ×1, copper_bar ×1 | `starsilver_band`, rare | "A pale band that catches light that isn't there. Rolls three affixes." |
| `starsilver_longbow_smith` | Starsilver Longbow | 14 | 65 | starsilver_bar ×2, logs ×2 | `longbow`, rare | "Starsilver-backed yew, strung with intent. Rolls three affixes." |
| `hedgesteel_cap_smith` | Hedgesteel Cap | 16 | 75 | hedgesteel_bar ×2, logs ×1 | `leather_helm`, rare | "Hedgesteel-banded, light as a worry you've put down. Rolls three affixes." |
| `hedgesteel_boots_smith` | Hedgesteel Boots | 16 | 70 | hedgesteel_bar ×2 | `leather_boots`, rare | "Soled for the deepest hollows. Rolls three affixes." |
| `warbow_smith` | Hedgesteel Warbow | 17 | 100 | hedgesteel_bar ×2, starsilver_bar ×1, logs ×2 | `warbow`, rare | "The bow Hod won't admit he's proud of. Rolls three affixes." |

The E16 cap+boots pair mirrors the E5 Bogiron pair; the E17 warbow is the
trade capstone — every input is a deep ore you mined yourself.

### New item kinds (items.gd KINDS)

Four additions; tools follow the existing `gather_speed` shape, the two gear
kinds reuse existing categories so no new equip slots are needed:

```gdscript
"starsilver_pickaxe": {
    "name": "Starsilver Pickaxe", "category": "pickaxe",
    "size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.55,
    "icon_color": Color(0.74, 0.79, 0.90),
},
"starsilver_axe": {
    "name": "Starsilver Axe", "category": "axe",
    "size": Vector2i(1, 3), "base_stat": "gather_speed", "base_value": 0.55,
    "icon_color": Color(0.70, 0.76, 0.88),
},
"starsilver_band": {
    "name": "Starsilver Band", "category": "ring",
    "size": Vector2i(1, 1), "base_stat": "crit_mult", "base_value": 0.15,
    "icon_color": Color(0.78, 0.82, 0.92),
},
"warbow": {
    "name": "Hedgesteel Warbow", "category": "weapon",
    "size": Vector2i(2, 4), "base_stat": "damage", "base_value": 11,
    "icon_color": Color(0.36, 0.46, 0.40),
},
```

- `warbow` extends the weapon base-damage ladder 6 (shortbow) → 8 (longbow) →
  **11**, same 2×4 footprint.
- `starsilver_band` differentiates from `copper_ring` (crit_chance) by keying
  crit_mult — affixes already format/sum it (`of_carnage`); see open question 4
  on the base-stat sum path.

## THE ECONOMY GATE, shown

Law (`_test_wyrd_loop.gd::_test_economy_gate`): a gear recipe whose inputs are
**all Hod-buyable** must cost more at Hod's prices than its sell value
(normal 4 / magic 12 / rare 35). An unbuyable input makes the recipe safe by
construction. Hod's prices: herb 3, logs 4, bogiron_ore 7 → derived
bogiron_bar 14. Unbuyable: copper (→ copper_bar), palechalk, **and both new
ores (→ both new bars)** — this spec adds **no new Hod wares**, so every new
gear recipe is gate-safe by construction. The test iterates
`STATIONS.forge.recipes`, so the new recipes are covered with zero test edits.

| Recipe | Sells | Buyable input cost | Unbuyable inputs | Gate |
|---|---|---|---|---|
| Palechalk Jerkin (rare) | 35 | 2×14 + 4 = 32 | palechalk ×3 | SAFE — note the buyable part alone is 32 < 35, so the chalk is load-bearing |
| Starsilver Pickaxe (normal) | 4 | 4 (logs) | starsilver_bar ×2 | SAFE |
| Starsilver Axe (normal) | 4 | 4 (logs) | starsilver_bar ×2 | SAFE |
| Starsilver Band (rare) | 35 | 0 | starsilver_bar, copper_bar | SAFE (doubly — copper is also unbuyable) |
| Starsilver Longbow (rare) | 35 | 8 (logs) | starsilver_bar ×2 | SAFE |
| Hedgesteel Cap (rare) | 35 | 4 (logs) | hedgesteel_bar ×2 | SAFE |
| Hedgesteel Boots (rare) | 35 | 0 | hedgesteel_bar ×2 | SAFE |
| Hedgesteel Warbow (rare) | 35 | 8 (logs) | hedgesteel_bar ×2, starsilver_bar ×1 | SAFE |

**Price floors if Hod ever stocks the deep materials** (computed against the
binding recipe, so the gate keeps holding):

- palechalk ≥ **2g** (binding: Palechalk Jerkin — 3p + 32 > 35)
- starsilver_ore ≥ **7g** (binding: Starsilver Longbow — 4q + 8 > 35)
- hedgesteel_ore ≥ **7g** (binding: Hedgesteel Boots — 4h + 8 > 35)

Recommendation: don't stock them at all in the demo — gather-only deep ores
keep the gate trivially safe and keep tier-2 charts the only road to the top
of the ladder, which is the cozy-skilling spine working as intended.

## Perks (PERKS.earth additions)

Existing: `double_ore` E5 (25% second lump), `quick_mining` E10 (−⅓ time).
Two more, gathering-feel at 13 and smithing-feel at 17, same dict shape:

| id | lv | Name | Desc (player-visible) |
|---|---|---|---|
| `rich_seams` | 13 | Rich Seams | "Starsilver and deeper veins always give a second lump" |
| `smiths_thrift` | 17 | Smith's Thrift | "1 in 4 forge crafts hand back one raw input — ore, chalk, or logs, never a bar" |

```gdscript
{"id": "rich_seams", "lv": 13, "name": "Rich Seams",
    "desc": "Starsilver and deeper veins always give a second lump"},
{"id": "smiths_thrift", "lv": 17, "name": "Smith's Thrift",
    "desc": "1 in 4 forge crafts hand back one raw input — ore, chalk, or logs, never a bar"},
```

- **Rich Seams** is deterministic (mirrors Wildcraft's `keen_eye`) but scoped
  to tier ≥ starsilver, so it doesn't retro-buff the low-tier economy. Note:
  `Game.gather_bonus(kind)` doesn't currently see the ore tier — the
  implementation either extends the signature or rolls this in
  `gather_node.gd` where `ore_tier` is known.
- **Smith's Thrift** is restricted to RAW inputs (ore/chalk/logs, never bars)
  on purpose: refunding a bogiron_bar would let the all-buyable Longbow recipe
  occasionally craft at 8g against a 12g sell — a chance-based crack in the
  gate. With raw-only refunds the worst all-buyable case (Longbow, refund one
  log) still costs 18g > 12g even on a proc. State this in code comments when
  implementing. (An XP perk at 17 was rejected — at the cap, bonus XP is dead.)

## Cross-trade hooks (notes for sibling specs — not deliverables here)

- **Wildcraft / Quill's still (spec 45-wilds):** a high-tier brew wanting
  `starsilver_ore` ×1 as its mineral note (the lumen group fits), mirroring how
  `clearwater_philter` pulls palechalk. Keeps deep mining wanted by brewers.
- **Wayfinding inks (future ink spec):** a sixth ink ground from
  `starsilver_ore` that leans charts toward the late affixes (echoing /
  marked_quarry), the way chalkwash leans deep — `INK_RECIPES` shape is ready
  for it.
- **Both new gear lines pull logs** (smelt + bows + cap), so Wildcraft chopping
  stays in the Earthcraft loop all the way to 17.

## Files (implementation pass — all additive)

| Path | Action |
|---|---|
| `wyrd/data/gather.gd` | modify — +4 MATERIALS, +2 ORE_TIERS, +ORE_ROLLS_BY_TIER |
| `wyrd/data/crafting.gd` | modify — +10 RECIPES, append ids to STATIONS.forge.recipes |
| `wyrd/data/items.gd` | modify — +4 KINDS |
| `wyrd/scripts/game.gd` | modify — +2 PERKS.earth; Rich Seams in gather bonus path; Smith's Thrift refund in craft() |
| `wyrd/scripts/dungeon_gen.gd` | modify — replace inline ore-tier roll with ORE_ROLLS_BY_TIER lookup |
| `wyrd/test_wyrd_loop.gd` | modify — new perk/craft assertions (gate test needs NO edits; it iterates the recipe list) |

## Acceptance criteria

1. Every Earthcraft level 1–17 lists at least one unlock (vein, recipe, or perk)
   and no level above 9 is perk-only.
2. Starsilver/Hedgesteel veins spawn from tier-2 Mineral Vein rolls, tint via
   the existing `_tint_tier` path, and stand visibly locked below E11/E15.
3. All 10 new recipes smith end-to-end at their req levels; gear comes out at
   the stated kind + rarity with the right affix counts.
4. `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`
   stays green — including `_test_economy_gate` over the grown recipe list.
5. Smith's Thrift never refunds a bar; Rich Seams never procs below starsilver.
6. All player-visible strings read in the World Bible voice (no fantasy-isms;
   ore names from the locked taxonomy).

## Open questions

1. **Summit ore.** The Summit (`affix_slots: 0`) can never roll Mineral Vein, so
   tier-3 carry is theoretical until a tier-3 chart with slots exists.
   Recommend: place 2 fixed Hedgesteel veins in the Summit layout as a one-shot
   "the mountain is made of it" moment — small, flavorful, no Wayfinding ladder
   change. Alternative: do nothing; tier-2 rolls already source everything.
2. **Tier-2 dilution.** Adding the deep ores at 30% combined weight thins
   bogiron/palechalk frequency in shipped tier-2 charts. ADR 0006 says don't
   re-balance shipped content — this is the minimal touch that gives the new
   ores any source at all. Rejected alternative: gate the roll on Earthcraft
   level (threads the `Game` autoload into static dungeon_gen — invasive).
3. **E17 perk alternative.** *Lucky Pour* — "one pour in ten comes out a rarity
   finer." More exciting than Smith's Thrift, but a normal→magic proc on the
   all-buyable Bogiron Cap path (cost 32, rare sells 35) creates a profitable
   3g proc the gate test can't see. Thrift (raw-only) is the safe default;
   pick Lucky Pour only with an explicit EV note in the gate test.
4. **`starsilver_band` base_stat.** Assumes `derived_stats` sums `crit_mult`
   from a base stat the same way it does from affixes (the `of_carnage` /
   `unique_critmult` path exists). If it doesn't, fall back to `crit_chance`
   0.06 and keep the name.
5. **Tier-4 tools.** Wildgold tools (−60%?) are post-demo with the cap lift;
   the −55% set is the demo ceiling on purpose (the last two levels should be
   about gear and the Summit, not faster mining).
6. **Bible drift, recorded.** The bible's table reads palechalk as a tier-1 ore
   (the tin half of brindle/bronze); the shipped game uses it as the E7 deep
   ore. This spec follows the game and climbs the bible ladder for new names —
   if the bible table is ever revised, revise it toward the game.

## References

- `docs/adr/0006-demo-level-cap-17.md` — the cap decision this spec executes.
- `docs/WORLD_BIBLE.md` — locked metal taxonomy (§ Metals & ores) + voice rules.
- `wyrd/data/gather.gd` — ORE_TIERS / MATERIALS shapes.
- `wyrd/data/crafting.gd` — RECIPES / STATIONS shapes; E1–E9 cadence.
- `wyrd/data/economy.gd` — SELL_BY_RARITY, WARES.
- `wyrd/data/items.gd` — KINDS shape, weapon damage ladder.
- `wyrd/scripts/dungeon_gen.gd::_scatter_gather_nodes` — the inline ore roll.
- `wyrd/test_wyrd_loop.gd::_test_economy_gate` + `_buy_cost` — the law.
- Sibling specs (planned): 45-trade-ladders-wilds, 45-trade-ladders-hunt.

## Done check

- [ ] Level table 1–17 has no empty levels and no perk-only levels above 9.
- [ ] Both new veins gatherable in a tier-2 chart run; locked display below req.
- [ ] All 10 recipes craft at req level with stated inputs/yields/rarity.
- [ ] Gate test green with zero gate-test edits; new perk assertions added.
- [ ] Thrift refund excludes bars; Rich Seams excludes tiers below starsilver.
- [ ] Every new player-visible string checked against the bible voice rules.
