# Wayfinder — Trades recap (state of the skill system, 2026-06-10)

One-page source of truth for what the skill system *is* right now — pulled from
code, not memory. When this disagrees with an older design doc, the code wins
(see "Stale docs" at the bottom).

**Language rule (CONTEXT.md):** a leveling discipline is a **Trade**, never a
"Skill". "Skill" is reserved for hotbar abilities (Bow, Power Shot, …).

## The identity (ADR 0003)

Cozy-skilling is the spine. The player is a resident of Bramblewood who
gathers, crafts, and charts; combat is one verb among many. **Wayfinding (the
chart craft) is the differentiator** — the other trades exist to feed it.

## The three trades

All trades share one XP curve: `xp_for_level(n) = (n-1)²·8 + (n-1)·32`
(Lv2 = 40, Lv3 = 96, Lv5 = 256, Lv10 = 1080, Lv16 = 2880). Level-ups toast
automatically via `Game.award_xp`. Viewed in-game on the **Trades page (K)**.

| Trade | Code key | XP comes from | Feeds |
|---|---|---|---|
| **Wayfinder** | `carto` | Completing charts: `tier×75 + good×40 + bad×10` (×1.3 with Tyrannical good) — paid at the exit waystone, not at inscribe | Unlocks chart templates + affixes (the whole ladder below) |
| **Earthcraft** | `earth` | Mining ore — 10 xp per bogiron lump | Stoneground ink, selling ore to Hod (7g); later: smithing (A7) |
| **Wildcraft** | `wilds` | Foraging herbs (8 xp) and chopping logs (12 xp) | Hedge ink; later: cooking/alchemy with Quill (A8) |

**Update 2026-06-10 — Earthcraft and Wildcraft are real trades now:**
- **Channel gathering (A4):** harvests are a 1.0–1.6s channel with a progress
  bar; moving or taking damage cancels it.
- **Cottage Hearth (A8-lite, Wildcraft):** 2 herbs + 1 log → Hearth Draught
  (35 hp, lv 1) · Deep Draught (80 hp, lv 8). **Q quaffs**, smallest bottle
  first; the HUD counts your bottles. Cooking pays Wildcraft XP (15/35).
- **Hod's Anvil (A7-lite, Earthcraft):** 2 ore → Bogiron Bar (lv 1, 12 xp) ·
  bar + 2 logs → Longbow (lv 4) · 2 bars → magic Bogiron Ring (lv 8). Gear
  yields go straight into the pack (space checked before materials spend).
- **Perks (A9):** Wildcraft 5 *Keen Eye* +1 herb · Wildcraft 10 *Clean
  Splits* +1 log · Earthcraft 5 *Sturdy Swings* 25% double ore · Earthcraft
  10 *Miner's Rhythm* −35% mining channel.
- The Trades page (K) ladders now list every recipe + perk per trade.
Still pending: node tiers (A6), tools (A5), the full smithing/alchemy tables.

## Where each verb is practiced

**In town (regrowing, tutorialized):**
- 6 herb patches around the Chartmaker's Yard — regrow 20s
- 3 ore rocks at Hod's spoil heap by the forge — regrow 40s
- 3 log piles at the cottage — regrow 30s
- First harvest of each kind triggers a one-time hint dialog (saved in
  `seen_hints`): Mara voices forage + logs, Hod voices ore.

**In dungeons (deplete per run, placed by chart affixes):**
| Affix | Nodes |
|---|---|
| Mineral Vein (lv 1) | 3–5 ore |
| Bramble Bloom (lv 4) | 4–6 herbs |
| Wood Grove (lv 7) | 3–5 log piles |
| Herbal Patch (lv 14) | 6–9 herbs |

Bad twins of these affixes place **zero** nodes — denial is the downside.

## The Wayfinder loop (carto is the meta-trade)

materials → ink → chart → dungeon → completion XP + materials → better charts

**Ink recipes** (mixed at the Inscribing Table): 3 herbs → hedge ink ·
2 ore → stoneground ink · 2 hedge + 1 ore → refined ink. Inks bias affix
rolls (hedge ×2 on green affixes, stoneground ×2.5 on Mineral Vein, refined
+stability). Stability decides good-vs-bad twin:
`min(95, base_stab + carto_lv×0.6 + ink_bonus×100)`.

**Unlock ladder (all gated by carto level):**
- Lv 1: Snug, Tier 1 Hollow templates · Mineral Vein
- Lv 4: Bramble Bloom · Lv 5: Tyrannical · Lv 7: Wood Grove, Festival Pace
- Lv 10: Hollow template · Lv 14: Herbal Patch · Lv 15: Briar Maze
- Lv 16: Chart of the Summit (endgame)

**Boss dens never roll randomly** — they're trophy-slotted:
elites drop thorn essence → Hedgemother's Den (lv 8) → tusk → Boar's Wallow
(lv 12) → wightpelt → Wolf Roost (lv 14) → alpha fang → **Summit**
(Hedgemother Queen).

## Economy touchpoints

Hod buys gear by rarity (4/12/35/90g) and sells materials: herb 3g, logs 4g,
ore 7g, hedge ink 12g, stoneground 18g, refined 38g. Trophies are never sold —
combat-only. So gold is a *shortcut* into the ink economy, while trophies keep
the boss chain earned.

## Combat "skills" (the other meaning)

Hotbar (1-4 + F): Bow (free, fire-rate scaled), Power Shot (20 focus, burn),
Multi Shot (25, 3 arrows + snare), Bramble Snare (30, AoE root). **No trade XP
from combat yet** — that's B7 on the plan, which would make combat a trade
like the others.

## What's next (docs/wyrd-skills-combat-plan.md)

Shipped: town gather stations (A1), per-skill tutorials (A2), Trades page (A3),
action-bar icons/tooltips (B1), channel gathering (A4), perks (A9), and the
lite cooking/smithing stations (A7/A8).
Order: **B3 per-kind enemy stats** → B2 control scheme decision → B4 boss
movesets → A5 tools → B5 loadouts → A7-full smithing → B6/B7 → A8-full
cooking/alchemy.

## Stale docs (flagged 2026-06-10 doc-vs-code audit)

- `cartography-keystone-design.md` carries the **old** completion formula
  (tier×30+good×25+bad×5, inscribe-time). Shipped: tier×75+good×40+bad×10 at
  exit. The deviation note lives in `wyrd-slice.md` § Deviations.
- `cartography-skill-design.md` describes Quill / Sir Withering / Brother Pell
  as if present — they're v2+ NPCs; only Mara and Hod exist in code.
- "+15% trash HP per tier past 1" exists in `layout_loader.gd` but only
  `wyrd-implementation-notes.md` mentions it; absent from the design docs.
- Earthcraft/Wildcraft read as full crafting trades in `wyrd-slice.md`; in v1
  they're gather-XP-only until A7/A8 land.
