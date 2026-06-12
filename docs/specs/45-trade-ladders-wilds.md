# 45 — Trade Ladders: Wildcraft 1→17

> **Outcome**: Wildcraft has a complete unlock ladder to the demo cap of 17 —
> six herb tiers (W1/3/7/10/13/16), every new herb feeding at least one
> recipe (heals, Quill brews, discoverable inks), two perks above 10, and a
> dungeon tier-mix table so deeper charts grow rarer herbs.

Per ADR 0006 (cap 17, extend the others): Wayfinding's 1–16 spread stays
untouched; this spec is additive data work in existing table shapes
(`HERB_TIERS` mirroring `ORE_TIERS`, `RECIPES`, `BUFF_DRAUGHTS`,
`INK_RECIPES`, `PERKS`). Design only — numbers are opinionated anchors for
a pick/edit pass, not brainstorm options.

**Naming note:** the brief floated the old prototype candidates (mossvine,
foxfire, morning_dew). The World Bible's locked taxonomy already names five
future herbs — bittergrass, crowsfoot, mothmint, foxglove-blue, stonebreak —
and the Bible wins on naming. Those five are the new tiers, in that order.
`wild_herb` (shipped, tutorial-entangled) stays the tier-1 id.

---

## 1. The level table (W1 → W17)

| Lv | Unlocks |
|---|---|
| 1 | Wild Herb patches, log piles, **Hearth Draught** (cook, 35), hedge ink (Mara teaches) |
| 2 | — quiet (Wayfinding carries it: carto 1–4 affixes land here) |
| 3 | **Bittergrass** (herb tier 2), **Quickroot Tonic** (still) — *existing* |
| 4 | **Bitter Draught** (cook, 55 vigor) |
| 5 | **Keen Eye** perk (+1 herb) — *existing* |
| 6 | **Clearwater Philter** (still) — *existing* |
| 7 | **Crowsfoot** (herb tier 3) |
| 8 | **Deep Draught** (cook, 80) — *existing* |
| 9 | **Crowsfoot Cordial** (still, move_speed) |
| 10 | **Mothmint** (herb tier 4), **Clean Splits** perk (+1 log, *existing*); **Mothglow Ink** becomes mixable |
| 11 | **Hale Draught** (cook, 140) |
| 12 | **Mothmint Mend** (still, vigor_regen) |
| 13 | **Foxglove-Blue** (herb tier 5), **Light Hands** perk; **Foxglove Ink** becomes mixable |
| 14 | — quiet (carto 14's Herbal Patch affix lands here and feeds the trade anyway) |
| 15 | **Heartsease Draught** (cook, 220) |
| 16 | **Stonebreak** (herb tier 6), **Stonebreak Tonic** (still, grit) |
| 17 | **Second Pour** perk (capstone — the last level-up is felt, echoing the ADR) |

Inks carry no `req_lv` (the pot matches exact multisets; discovery gates
them, spec 43) — "becomes mixable" above means the input herb just unlocked.

XP sanity: `xp_for_level(17) = 2560` cumulative (game.gd:235). At 26–48 xp
per high-tier forage plus 40–70 xp recipes, W13→17 is a few dozen sessions
of gather-and-brew — same cadence Earthcraft hits with palechalk.

---

## 2. Herb tiers — `HERB_TIERS` (new const in gather.gd, mirrors `ORE_TIERS`)

Escalation mirrors ore (copper 1.2s/6 → bogiron 1.6/12 → palechalk 2.0/20):
+0.3s channel per tier, xp ×~1.4 per tier off the forage base (1.0s/8).

| Tier | id | Display | req_lv | channel_sec | xp | Node name | Color | Icon |
|---|---|---|---|---|---|---|---|---|
| 1 | `wild_herb` | Wild Herb | 1 | 1.0 | 8 | Wild Herb Patch | `Color(0.45, 0.62, 0.34)` | ❀ |
| 2 | `bittergrass` | Bittergrass | 3 | 1.2 | 12 | Bittergrass Patch | `Color(0.55, 0.58, 0.30)` | ❧ |
| 3 | `crowsfoot` | Crowsfoot | 7 | 1.5 | 18 | Crowsfoot Patch | `Color(0.26, 0.38, 0.24)` | ⚘ |
| 4 | `mothmint` | Mothmint | 10 | 1.8 | 26 | Mothmint Patch | `Color(0.72, 0.80, 0.74)` | ✾ |
| 5 | `foxglove_blue` | Foxglove-Blue | 13 | 2.1 | 36 | Foxglove Patch | `Color(0.42, 0.50, 0.78)` | ✿ |
| 6 | `stonebreak` | Stonebreak | 16 | 2.4 | 48 | Stonebreak Patch | `Color(0.60, 0.58, 0.50)` | ❁ |

Satchel descs (MATERIALS entries, one line, Bible voice):

| id | desc |
|---|---|
| `bittergrass` | "Sharp on the tongue, kind after. Quill swears by a bitter start." |
| `crowsfoot` | "Three-toed leaves from the cracks between stones. Common, once you know where to look." |
| `mothmint` | "Pale as a moth's wing and blooms at midnight. The fog is fond of it." |
| `foxglove_blue` | "Blue bells with a fierce streak. Steadies the heart — in small doses, mind." |
| `stonebreak` | "A root that splits rock, given time. The Summit grows it; almost nowhere else does." |

Readability: six herbs, six distinct glyphs, a green→olive→dark→pale→blue→grey
color walk, and no two names share a first syllable. Locked patches stay
visible and name their level, like Hod's bogiron (coveted, not hidden).

---

## 3. What each herb feeds

### 3a. Cookfire — heal draughts (`crafting.gd RECIPES`, station `cookfire`)

| Recipe id | Name | req_lv | xp | Inputs | Yields | Heal | desc |
|---|---|---|---|---|---|---|---|
| `bitter_draught` | Bitter Draught | 4 | 22 | bittergrass 2, wild_herb 1, logs 1 | 1 | **55** | "Restores 55 vigor. Bitter going down, warm after. Quaff with Q." |
| `hale_draught` | Hale Draught | 11 | 45 | mothmint 2, wild_herb 2, logs 2 | 1 | **140** | "Restores 140 vigor. Mothmint and woodsmoke — a bottle of even keel. Quaff with Q." |
| `heartsease_draught` | Heartsease Draught | 15 | 60 | foxglove_blue 2, mothmint 2, logs 2 | 1 | **220** | "Restores 220 vigor. Foxglove steadies the heart — in small doses, mind. Quaff with Q." |

`DRAUGHTS` / `DRAUGHT_ORDER` become 35 / 55 / 80 / 140 / 220,
smallest-first quaffing preserved. Bitter Draught (55) sits *below* Deep on
purpose — it's beyond the brief's "above 80" ask, but the W3 herb needs a
sink before W9 and the 35→80 heal gap was real.

### 3b. Quill's still — buff brews (`BUFF_DRAUGHTS`, station `still`)

Existing: quickroot W3 (gather_speed 0.25 / 90s), clearwater W6
(focus_regen 0.5 / 90s). Three new, W9–W16:

| Recipe id | Name | req_lv | xp | Inputs | stat | value | duration | Toast |
|---|---|---|---|---|---|---|---|---|
| `crowsfoot_cordial` | Crowsfoot Cordial | 9 | 40 | crowsfoot 2, bittergrass 1 | `move_speed` | 0.10 | 90s | "Crowsfoot quickens the step — the road runs shorter." |
| `mothmint_mend` | Mothmint Mend | 12 | 50 | mothmint 2, crowsfoot 1 | `vigor_regen` | 1.0 /sec | 120s | "Mothmint settles in — scratches close as you walk." |
| `stonebreak_tonic` | Stonebreak Tonic | 16 | 70 | stonebreak 2, foxglove_blue 1 | `grit` | 0.15 | 90s | "Stonebreak sits heavy in the blood — the bites land softer." |

Plumbing each stat needs:
- `move_speed` — already a summed player stat (player_controller.gd:918–927,
  hunters_stride); add `buff_value("move_speed")` into the sum. Cheap.
- `vigor_regen` — new: a per-second heal tick while the buff runs. New hook.
- `grit` — new: multiply damage taken by `(1 - grit)` at the player's
  damage-intake point. New hook.

Satchel descs:

| id | desc |
|---|---|
| `crowsfoot_cordial` | "Quill's road-brew. Quaff with Q when hale — your stride runs a tenth quicker for a while." |
| `mothmint_mend` | "Mothmint settled into syrup. Quaff with Q when hale — scratches close as you walk." |
| `stonebreak_tonic` | "Stone in a bottle, near enough. Quaff with Q when hale — bites land softer for a while." |

### 3c. Bench pot — two new discoverable inks

Both follow spec 43: unknown at start, exact-multiset match at the pot,
riddle shows once the `hint_key` first-time hint is seen. They target the
affixes that currently have **no** ink bias (tyrannical, frenzied, bursting,
fog_of_hedge, quiver — gilded and festival_pace stay uncovered; see open
questions).

**`gather.gd INK_RECIPES`** (+ `INK_RECIPE_ORDER` append):

| id | Inputs | Yields | hint_key | Riddle |
|---|---|---|---|---|
| `mothglow_ink` | mothmint 2, hedge_ink 1 | 1 | `still` | "Quill: 'Two midnight blooms stirred into the everyday. The fog keeps your secrets after.'" |
| `foxglove_ink` | foxglove_blue 2, bogiron_ore 1 | 1 | `forge` | "Hod: 'Two of the blue bells ground with a lump of my iron. Charts come up mean. Mean pays.'" |

**`charts.gd INKS`** (bias entries):

| id | Name | Icon | Bias | desc |
|---|---|---|---|---|
| `mothglow_ink` | Mothglow Ink | ☽ | fog_of_hedge ×2.2, quiver ×1.8 | "Pale and night-sweet — the fog leans friendly and the bowstring stays dry." |
| `foxglove_ink` | Foxglove Ink | ❖ | tyrannical ×2.0, frenzied ×1.8, bursting ×1.8 | "Blue-black and fierce — pulls the roll toward the mean affixes. Mean pays." |

**MATERIALS** satchel descs:

| id | desc |
|---|---|
| `mothglow_ink` | "Moth-pale charting ink. Charts come up quiet — fog and bowstring favor the bearer." |
| `foxglove_ink` | "Blue-black and faintly fierce. Pulls charts toward the fattened, frenzied, bursting things." |

Mothglow is the *quiet hunter's* ink (stealth + bow); Foxglove is the
*mean-run* ink — the deliberate hard-mode pull, and tyrannical's +30% chart
XP makes "mean pays" literally true. Foxglove Ink's bogiron lump is the
cross-trade pull (Earthcraft feeds Wayfinding through Wildcraft's pot).

### Coverage check — every tier-2+ herb in ≥1 recipe

| Herb | Appears in |
|---|---|
| bittergrass | Bitter Draught, Crowsfoot Cordial |
| crowsfoot | Crowsfoot Cordial, Mothmint Mend |
| mothmint | Hale Draught, Mothmint Mend, Mothglow Ink |
| foxglove_blue | Heartsease Draught, Stonebreak Tonic, Foxglove Ink |
| stonebreak | Stonebreak Tonic |

---

## 4. Perks above 10 (`game.gd PERKS["wilds"]`)

Existing: keen_eye (5, +1 herb), clean_splits (10, +1 log). Two new,
mirroring the existing value shapes (quick_mining's flat channel cut;
double_ore's 25% chance):

| id | lv | Name | desc | Shape it mirrors |
|---|---|---|---|---|
| `light_hands` | 13 | Light Hands | "Foraging and chopping take a quarter less time" | `quick_mining` (earth 10, −1/3 mining time) — applied as a channel multiplier in gather_node |
| `second_pour` | 17 | Second Pour | "25% chance a hearth or still recipe pours a second bottle" | `double_ore` (earth 5, 25% chance) — rolls in `Game.craft()` for wilds `yields_material` recipes |

Second Pour deliberately touches *brewing* feel, not gathering — by 17 the
satchel is full of herbs; the capstone makes the bottles flow.

---

## 5. Where herbs grow

### Town

- **Tier 1:** the existing regrowing wild-herb patches stay (town.gd:256).
- **Tier 2, exactly one:** a regrowing **Bittergrass Patch** beside Quill's
  still, locked until W3 — visible and named, the coveted early goal,
  mirroring Hod's locked bogiron vein in the spoil heap (town.gd:259–265).
- Tiers 3–6 never grow in town (mirrors palechalk: "only the deeper charts
  carry it").

### Dungeon — forage tier mix by chart tier

Mirrors the mineral_vein ore-tier roll in
`dungeon_gen._scatter_gather_nodes` (dungeon_gen.gd:333–339). Applies to
`bramble_bloom` (4–6 spawns) and `herbal_patch` (6–9 spawns) good twins;
the fixed `"item"` in `GATHER_BY_AFFIX` becomes the fallback only.

| Chart tier | Bramble Bloom roll | Herbal Patch roll (deepest herb weighted up) |
|---|---|---|
| 1 | wild_herb 60% / bittergrass 40% | wild_herb 40% / bittergrass 60% |
| 2 | bittergrass 30% / crowsfoot 45% / mothmint 25% | bittergrass 20% / crowsfoot 40% / mothmint 40% |
| 3 (Summit) | mothmint 35% / foxglove_blue 40% / stonebreak 25% | mothmint 25% / foxglove_blue 35% / stonebreak 40% |

So: tier-1 charts grow herb tiers 1–2, tier-2 charts grow 2–4, tier-3 grows
4–6 — a player under-leveled for a patch sees it locked with its level
named, same as ore veins (the `gather_node.gd` ore-tier mechanism
generalizes: one tier-table lookup keyed by node kind instead of the
hardcoded `ORE_TIERS`). Stonebreak existing *only* in Summit-tier charts is
the point — the last herb is a trophy of the endgame chart, and its tonic
(grit) is brewed *for* the Queen fight.

---

## 6. Files (for the eventual /spec implementation pass)

| Path | Action |
|---|---|
| `wyrd/data/gather.gd` | +5 MATERIALS herbs, +8 MATERIALS consumables/inks, new `HERB_TIERS`, +2 `INK_RECIPES`, order appends |
| `wyrd/data/crafting.gd` | +6 RECIPES, station recipe lists, DRAUGHTS/ORDER, BUFF_DRAUGHTS/ORDER |
| `wyrd/data/charts.gd` | +2 INKS bias entries |
| `wyrd/scripts/game.gd` | +2 wilds PERKS, Second Pour roll in `craft()`, `vigor_regen` tick, satchel/tray exposure |
| `wyrd/scripts/gather_node.gd` | generalize `setup_ore_tier` → tier table by kind (herb tiers) |
| `wyrd/scripts/dungeon_gen.gd` | herb tier roll in `_scatter_gather_nodes` per the mix table |
| `wyrd/scripts/town.gd` | one locked Bittergrass Patch by the still |
| `wyrd/scripts/player_controller.gd` | `move_speed` buff into stat sums; `grit` at damage intake |

---

## 7. Acceptance criteria

1. Trades page shows a Wildcraft unlock at 13 of the 17 levels (2 and 14
   are the only quiet ones, and 14 is carried by carto's Herbal Patch).
2. Each of the five new herbs gathers only at/above its req_lv, with
   distinct glyph/color/name in the satchel, and feeds ≥1 recipe.
3. Heal ladder quaffs smallest-first: 35/55/80/140/220.
4. Three new brews apply their stat for their duration; toasts in voice.
5. Mothglow and Foxglove inks are discoverable at the pot (not known at
   start), bias their listed affixes in the bench preview, and their
   riddles unlock from the `still`/`forge` hints.
6. Tier-mix table verified: a tier-1 chart never spawns crowsfoot+, a
   tier-2 never spawns foxglove+, stonebreak appears only in tier 3.
7. Light Hands shortens forage/chop channels by 25%; Second Pour doubles a
   wilds material craft ~25% of the time.
8. All three headless suites stay green; saves from before the spec load
   clean (new materials default to 0, no ink regression).

---

## 8. Open questions

1. **Glyph rendering** — ❧ ⚘ ✾ ✿ ❁ ☽ ❖ must render in the satchel font
   (IM Fell + fallbacks). Verify before locking; swap any tofu for safe
   picks (◌ family is the fallback pool).
2. **"Heartsease Draught"** — heartsease is itself a real herb name; risk
   of reading as a seventh herb. Alternative: "Foxglove Draught". Kept
   because it's the prettiest line in the ladder.
3. **gilded + festival_pace still have no ink.** Two inks cover five of the
   seven uncovered affixes; the festive/golden pair reads Earthcraft-flavored
   (gold leaf, bright pigment) — propose covering them in spec 45-earth
   rather than forcing a third wilds ink.
4. **Heal curve 140/220** — anchored to "deep_draught × ~1.75 per step",
   not to measured Summit boss damage. Needs one balance pass against
   tier-3 hits before shipping numbers.
5. **`vigor_regen` and `grit` are new buff plumbing** — `buff_value()`
   reads any stat, but regen needs a tick and grit a damage-intake hook.
   Confirm both hooks are in scope for the implementation spec.
6. **`GATHER_BY_AFFIX.item` vs the tier roll** — with herb tiers rolled,
   the fixed `"item": "wild_herb"` becomes dead weight for forage entries.
   Recommend keeping it as the fallback when no tier table matches.
7. **Bible taxonomy drift** — the Bible's *existing* forage rows
   (whitleberry, hedgecap, wishrose) aren't in the game; `wild_herb` isn't
   in the Bible. Recommendation: keep `wild_herb` for the demo (shipped,
   tutorial-entangled), fold the Bible's berry/mushroom rows into the
   post-demo 8–10 tier extension the ADR anticipates.
8. **Stonebreak's Bible note** ("Mining XP boost when held") is honored in
   spirit (a cross-trade tonic brewed from it) but not literally; a
   held-herb XP wrinkle is a post-demo idea, noted here so it isn't lost.

## References

- `docs/adr/0006-demo-level-cap-17.md` — the cap decision this implements
- `wyrd/data/gather.gd` (`ORE_TIERS` pattern), `wyrd/data/crafting.gd`,
  `wyrd/data/charts.gd` (INKS/AFFIXES), `wyrd/scripts/game.gd`
  (PERKS/SKILL_HINTS), `wyrd/scripts/dungeon_gen.gd:284–341`,
  `wyrd/scripts/town.gd:256–265`
- `docs/specs/43-recipe-discovery.md` — the discovery contract new inks ride
- `docs/WORLD_BIBLE.md` — herb names from the locked taxonomy's future list
