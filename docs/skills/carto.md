# Cartography

> The **keystone skill**. Cartography consumes outputs from every other
> skill (verdant herbs, earthen ores, sanguine drops, lumen springs)
> and produces the only on-demand content in the game — charts, the
> dungeons you walk and loot. Without Cartography, the wolds are a
> static map. With it, the world rolls fresh content.

## The five-station loop

```
gather (wilds/earth/cook/combat) → INSCRIBING TABLE → ink
                                       ↓
                                   PEDESTAL → rune (optional)
                                       ↓
                                   CHARTING → chart (procgen OR echo)
                                       ↓
                                   enter dungeon
                                       ↓
                                   chest loot · carto XP · atlas tick
```

Five stations, one verb-per-station, all wired through the **Cartography
Workshop** (📐 HUD button or **C** key).

## The four pillars

| Pillar | What it does | Open from |
|---|---|---|
| **Workshop** | Hub UI — XP bar, milestone hint, materials/inks/runes/charts at a glance, four launchers | 📐 HUD button · `C` · Chartmaker's Stone |
| **Living Atlas** | Tracks chart completions per region; thresholds unlock walkable biomes (Mossvale, Stillwater, Coalrose, Wightspire, Echofold) | 📜 Open Atlas link in Workshop |
| **Echo Charts** | Reads the **live overworld** around an anchor (village square, forge, perch) and turns its peaceful residents hostile. Same layout you walk daily, hostile cast | Inscribe Chart → echo template (carto 35+) |
| **Inkwell Vessels** | Tier-3 inks need a vessel commissioned from Hod / Quill / Cricket — pulls forge / herbalist / cooper into the carto loop | Talk to Hod, Quill, or Cricket at carto 30+ |

## The Materials view

The Workshop's Materials section is a **planner**, not just inventory:

- Items grouped by essence (verdant / earthen / sanguine / lumen / vessel)
- Live "✓ Can mix: Hedge Ink, Stoneground Ink, Bramblepress Ink" hint
- "Almost: short any lumen (tier 1+)" surfaces near-miss recipes
- **📋 Browse all** opens the Materials Browser modal (4 tabs: Materials / Inks / Vessels / Recipes) with source hints + "Used in" links
- Click any recipe in the browser → workshop **shopping-list mode**: green ✓ ticks on every material the recipe wants, "× Clear target" to exit

## XP sources

| action | xp | notes |
|---|---|---|
| Inscribe a chart | tier × 100 + 40 per good twin + 15 per bad twin | the primary verb |
| Complete a chart (chest looted) | tier × 75 + 40 per good + 10 per bad + 25 if fog_of_hedge | scales with affix outcomes |
| Mix an ink | none | inks are a sub-craft; XP comes from the chart |
| Discover a new recipe | recipe.xpFirst (50–260) | one-time bonus on first inscribe |
| Sketch a feature | none | sketches feed the Field Journal, not Carto XP |

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 1  | **Hedge Ink** | Mix the basic ink for low-tier charts. |
| 14 | **Bog Ink hint** | Tier-2 verdant+lumen recipe surfaces in the Inscribing Table. |
| 25 | **Ember Ink hint** | Tier-2 sanguine recipe — produces charts with stronger affixes. |
| 30 | **Vessels unlocked** | Hod / Quill / Cricket dialogs grow a "Commission a Vessel" choice. |
| 35 | **Echo: Bramblewood Square** | First echo template available in the Charting modal. |
| 40 | **Echo: Hod's Forge** + **Tidewater Ink (carto+lumen)** | |
| 45 | **Echo: Withering's Perch** | Tier-3 sanguine echo. |
| 50 | **Rune Slot** (with magic 30) | Bake a passive into charts (air → enemy −1, fire → +30% loot, etc). |

## Ink ladder

| ink | tier | gate | pattern shorthand | bias |
|---|---|---|---|---|
| Hedge Ink | 1 | carto 1 | 3 verdant column | baseline |
| Charcoal Bind | 1 | carto 1 | 1 charcoal_stick center | +5% stability |
| Stoneground Ink | 1 | carto 4 | 3 earthen column | mineral_vein +30% |
| Bramblepress Ink | 1 | carto 6 | 3 sanguine column | tyrannical +30% |
| Wellspring Ink | 1 | carto 8 | 3 lumen column | bramble_bloom +30% |
| Refined Ink | 2 | carto 12 | T of earthen + hedge_ink center | +5% stability |
| Bog Ink | 2 | carto 16 | + with lumen center, verdant arms | fog + bloom |
| Lustrous Ink | 2 | carto 18 | + with refined_ink center, ore_dust arms | mineral + gilded + gem |
| Ember Ink | 2 | carto 28 | X-corners sanguine + charcoal_stick center | tyrannical + bursting |
| **Forge-Brand Ink** | **3** | **carto 32** + Clay Flask | sanguine X + ember_ink center | tyrannical 1.5×, bursting 1.3×, +10% stab |
| **Aurora Ink** | **3** | **carto 36** + Bound Parchment | T2 verdant + bog_ink center | bramble_bloom 1.5×, fog 1.3×, +10% stab |
| **Tidewater Ink** | **3** | **carto 40** + Glass Vial | T1 lumen + lustrous_ink center | mineral + gilded + bloom + 10% stab |

Tier-3 inks have a baked-in **+10% stability** bonus on top of affix
multipliers — the endgame stability ceiling.

## Vessel commissions

| Vessel | NPC | Cost | Use |
|---|---|---|---|
| Clay Flask | Hod | 30 gp + 1 stoneground_ink + 2 charcoal_stick | Forge-Brand Ink |
| Bound Parchment | Quill | 40 gp + 1 vellum + 2 wishrose | Aurora Ink |
| Glass Vial | Cricket | 50 gp + 1 wellspring_ink + 1 ore_dust | Tidewater Ink |

The "Commission a Vessel" choice appears in each NPC's dialog at
**Cartography 30**.

## Chart templates

| chart | tier | gate | affix slots | ink slots |
|---|---|---|---|---|
| Snug | 1 | carto 1 | 0 | 1 |
| Tier 1 Hollow | 1 | carto 1 | 1 | 2 |
| Hollow | 2 | carto 10 | 2 | 3 |
| Briar Maze | 2 | carto 15 | 2 | 3 |
| Sunken Hut | 3 | carto 22 | 3 | 4 |
| Delve | 3 | carto 30 | 3 | 4 |
| **Echo: Bramblewood Square** | **2** | **carto 35** | 1 | 2 |
| **Echo: Hod's Forge** | **3** | **carto 40** | 2 | 3 |
| **Echo: Withering's Perch** | **3** | **carto 45** | 2 | 3 |

Echo charts read the live overworld at inscribe time — the layout
mirrors the place you echoed; only the cast changes. A carto-savvy
player who walks the village every day predicts cover and chokepoints
that a brute-force Lv 50 won't.

## Living Atlas regions

| Region | Counted scopes | Threshold | Biome unlock |
|---|---|---|---|
| Bramble Hollows | snug, tier_1, hollow, briar_maze | 3 | **Mossvale** |
| Drowned Lanes | sunken_hut | 4 | **Stillwater Fens** |
| Earthroot Drifts | delve | 5 | **Coalrose Pits** |
| Wightspires | (placeholder) | 6 | **Wightspire Reach** |
| The Echoes | echo_village, echo_forge, echo_perch | 5 | **The Echofold** |

Biomes are persistent walkable instances (pinned seeds) — no chart
consumed, no carto XP on exit. They're places, not crafts.

## Affix system

Charts roll **N affixes** based on template. Each affix has a "good
twin" and a "bad twin"; carto level shifts the roll toward good:

```
effective_stability = base_stability + cartoLv × 0.6 + ink_bias_total
                       (capped at 95%)
```

Refined / tier-3 inks add a flat `_stability` modifier. Affix bias
multipliers (e.g. tyrannical 1.5×) shape *which* affix lands more
often, while stability shapes whether it lands good or bad.

See `src/data/affixes.js` and `src/data/affixWeights.js`.

## Where the code lives

| Surface | File |
|---|---|
| Workshop UI | `src/ui/cartographyWorkshop.js` |
| Living Atlas | `src/data/atlas-regions.js`, `src/game/atlas.js`, `src/ui/atlasMap.js` |
| Echo layout generator | `src/scene/dungeon.js` (`generateEchoLayout`) |
| Echo place catalog | `src/data/echo-places.js` |
| Vessel commission helper | `src/main.js` (`vesselCommissionChoice`) |
| Materials inspector | `src/game/materials.js` |
| Materials Browser modal | `src/ui/materialsBrowser.js` |
| Inscribing Table | `src/ui/inscribingTable.js` |
| Pedestal | `src/ui/pedestal.js` |
| Charting modal | `src/ui/charting.js` |
| Ink recipes | `src/data/inkRecipes.js` |
| Source hints + recipe status | `src/game/materials.js` |

## Reference docs

- `docs/cartography-systems.md` — single-doc overview of the four
  pillars with diagrams, hook points, and a Lv 1→50 player journey.
- `docs/design/cartography-keystone.md` — original design doc framing
  cartography as the progression spine.
- `docs/design/cartography-depth-20.md` — 20-idea backlog for next
  iterations (Atlas Codex, NPC-signed charts, themed chart families,
  etc).
- `docs/design/cartography-skill-design.md` (legacy) — earlier design
  notes; superseded by the systems doc.
