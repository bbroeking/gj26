# Cartography — what it is, where you do it, how it works

> Cartography is the **map-making skill** in Bramblewood. You sketch the
> world, mix inks, transmute inks into runes, and inscribe charts that
> become enterable dungeons. Mechanically: a gathering-and-crafting loop
> that feeds the magic + dungeoning systems.

## TL;DR

| Verb | Where | Tool / Item | Output |
|---|---|---|---|
| **Sketch** a landmark | Anywhere near a "notable" tile | press **N** | +Carto XP, bramble-press ink seed |
| **Mix ink** | Inscribing Table | raw ingredients (herb / mud / berry) | one of 8 inks |
| **Transmute** ink → rune | Pedestal | one ink + one runestone | one rune (e.g. `rune_air`) |
| **Inscribe chart** | Inscribing Table | blank vellum + ink + sketch | a `chart_*` item |
| **Enter dungeon** | anywhere | left-click chart in inventory | step into the chart's hollow |

## Locations in the village

```
                             ┌─────────┐
                             │ Maud's  │  Inscribing Table is here too
                             │  Hut    │  (right-click → "Mix ink")
                             └────┬────┘
                                  │
                          (cobble path)
                                  │
       ┌──────────────────────────┴───────────────────┐
       │                                              │
   ┌───┴────┐    "X" = spawn (15,15)         ┌────────┴────────┐
   │ Quill  │       •                         │   Chartmaker    │
   │(herba- │                                 │      Stone      │
   │ list)  │                                 │  (15+3, 15-1)   │
   └────────┘                                 │  pedestal +     │
                                              │  inscribing     │
                                              └─────────────────┘
```

- **Chartmaker's Stone** — east of spawn, 3 tiles east + 1 north. The
  central cartography hub. Click it (or press E next to it) to open the
  combined Inscribing Table + Pedestal dialog. Lets you mix any ink, mint
  any rune, and inscribe any chart in one place.
- **Inscribing Table at Maud's hut** — lighter version. Mix inks and
  scratch chart drafts; no pedestal here, so no rune minting.
- **Quill the herbalist** — sells the cheaper ingredients (Whitleberry,
  Hedgecap, Wishrose) and gives you ink hints when your Cartography level
  unlocks new recipes.

## Skill levels & milestones

Cartography unlocks new ink recipes as you level. From `src/data/skill-milestones.js`:

| Lv | Unlock |
|----|--------|
| 1  | Hedge ink, Wellspring ink (basic blue + green family) |
| 8  | Charcoal bind, Refined ink |
| 14 | Bog ink (deep dungeon-floor charts) |
| 22 | Stoneground ink (earth-element transmutes) |
| 25 | Ember ink (fire-element transmutes) |
| 35 | Lustrous ink (cosmic + travel runes) |

The skill rises from three verbs:
1. **Sketching** notable tiles with N — small XP per unique landmark seen.
2. **Mixing** ink at the table — XP per recipe completed.
3. **Inscribing** a chart — large XP per chart written.

## Ink → rune table (Pedestal)

| Ink | Rune |
|---|---|
| Hedge ink | `rune_air` |
| Stoneground ink | `rune_earth` |
| Bramblepress ink | `rune_fire` |
| Wellspring ink | `rune_water` |
| Charcoal bind | `rune_mind` |
| Refined ink | `rune_body` |
| Bog ink | `rune_chaos` |
| Lustrous ink | `rune_cosmic` |
| Ember ink | `rune_fire` (alt path) |

Source: `INK_TO_RUNE` in `src/game/spells.js`.

## Chart varieties

| Chart | Tier | Notes |
|---|---|---|
| `chart_blank` | — | base item; combine with ink + sketch to author |
| `chart_tier_1` | 1 | small Wolds hollow, intro dungeon |
| `chart_hollow` | 1 | low-stakes corridor map |
| `chart_snug` | 1 | tight-room variant |
| `chart_delve` | 2 | mid-tier delve |
| `chart_briar_maze` | 2 | corridor-heavy, kiting-friendly |
| `chart_sunken_hut` | 3 | water + mist affixes |

Each chart is an inventory item; left-click in inventory to enter its
dungeon. Inside, the dungeon generator uses the chart's tier + affixes to
populate enemies, loot, and the boss table (see `src/game/quest.js`,
`docs/design/05-boss-design.md`).

## Tutorial path (in-village)

For a brand-new player, the natural cartography intro is:

1. Talk to Quill, buy 2 Whitleberries (1 coin each).
2. Forage a Hedgecap from the meadow north of the village (auto-spawns).
3. Walk to the Chartmaker's Stone, press E.
4. **Mix Hedge ink** (Whitleberry + Hedgecap) — first mix, big Carto XP.
5. **Transmute → `rune_air`** at the same dialog.
6. Inscribe a Tier-1 chart (consumes ink + a blank vellum).
7. Click the chart in inventory → enter the dungeon.

This sequence is partially gated by the in-village tutorial chain: the
`chart` step in `TUTORIAL_STEPS` (src/main.js) fires after your first
quest accept and points you at the standing stone.

## Where the code lives

- `src/ui/inscribingTable.js` — ink mixing UI, recipe table.
- `src/ui/pedestal.js` — ink → rune transmutation UI.
- `src/data/skill-milestones.js` — Cartography unlock thresholds.
- `src/data/items.js` — chart definitions, ink definitions, parchment items.
- `src/game/spells.js` — `INK_TO_RUNE` mapping.
- `src/game/quest.js` — chart entry, dungeon spawn handoff.
- `src/main.js` — `CHARTMAKER_TILE` constant + onPathDone hooks for the
  click-the-stone interaction.
