# Cartography — Progression & Unlocks (Lv 1 → 99)

The full unlock table for the Cartography skill. Every level that grants a *new verb, recipe, chart, or capability* is listed. Numeric-only levels are filler; the gaps between unlocks are intentional pacing — you should feel the milestones land.

This doc is the source of truth for `CARTO_UNLOCKS` in `src/ui/worldMap.js`. Update both together.

## The pillars

Cartography unlocks fall into six tracks, each with its own pacing:

| Track | What it unlocks | Lv range |
|---|---|---|
| **Map vision** | Fog-of-war, enemy markers, fast-travel, perimeter reveal | 1 → 50 |
| **Chart templates** | Snug → Tier1 → Hollow → Briar Maze → Sunken Hut → Delve → Summit | 1 → 60 |
| **Ink recipes** | Common → Refined → Specialty → Aurora-tier | 1 → 75 |
| **Resource bias** | Mineral / Wood / Herb / Gem / Ink-spring affixes | 1 → 35 |
| **Specialty paths** | Hydrographic / Geological / Biological branches | 35 → 75 |
| **Endgame** | Master Chart, Atlas, Cartographer's Cape | 75 → 99 |

A player at Lv 25 already has access to most of the *core* loop (charts, common inks, fast-travel). Lv 35+ is when **specialization** kicks in. Lv 75+ is **legacy crafting**.

## The full unlock table

Every entry has: `lv`, `name` (the title earned), `track`, and `unlock` (the player-facing description).

| Lv | Title | Track | Unlock |
|---|---|---|---|
| 1 | Apprentice Cartographer | Vision | World map opens with explored-tile memory. Inscribe `chart_snug` and `chart_tier_1`. Mix Hedge Ink + Charcoal Bind. |
| 4 | Greengather | Recipes | Mix **Stoneground Ink** (earthen bias). |
| 5 | Field Surveyor | Vision | Enemies in sight appear on the map. |
| 6 | Tinder Press | Recipes | Mix **Bramblepress Ink** (sanguine, +30% tyrannical). |
| 7 | Branch Walker | Affixes | New affix unlocks: **Wood Grove** (+3-5 log piles in chart). |
| 8 | Wellspring Stage | Recipes | Mix **Wellspring Ink** (lumen, +30% bramble bloom). |
| 10 | Hedgewalker | Vision + Templates | Inscribe **`chart_hollow`** (tier 2, 2 affix slots). Forage stays marked on memory tiles. |
| 12 | Press Master | Recipes | Mix **Refined Ink** (T-shape pattern, +5% stability on every roll). |
| 13 | Hush Walker | Recipes | Mix **Hush Ink** (X-corners; biases lockstep enemy patrols). |
| 14 | Herbal Walker | Affixes | New affix: **Herbal Patch** (+4-6 forage spawns). |
| 15 | Pathfinder | Vision | **Fast-travel** between known landmarks costs 1 chart_blank. |
| 16 | Bog Ink Press | Recipes | Mix **Bog Ink** (cross +; biases Fog of Hedge or Bramble Bloom). |
| 18 | Lustrous Press | Recipes | Mix **Lustrous Ink** (cross + center, +30% mineral_vein, +10% gilded_seam). |
| 20 | Marker | Vision | Inscribe **`treasure_map`**. |
| 22 | Sunken Press | Templates | Inscribe **`chart_sunken_hut`** (tier 3, 3 affix slots, atmospheric bias). |
| 25 | Surveyor | Vision + Polish | Right-click any known tile to **place a named waypoint**. Auto-arrange known recipes at the Inscribing Table. |
| 28 | Ember Press | Recipes | Mix **Ember Ink** (X-corners; +30% tyrannical or bursting). |
| 30 | Delve Press | Templates | Inscribe **`chart_delve`** (tier 3, deeper hollow, longer runs). |
| 30 | Gem Sense | Affixes | New affix: **Gem Seam** (rare gemstone drops in chest). |
| 32 | Survey Map | Recipes | Inscribe **`survey_map`** (regional carto-XP boost for 1 game-day). |
| 35 | Hydrographer | Specialty | Inscribe **`hydrographic_chart`** — dungeons biased toward water rooms + Tideink synergies. |
| 40 | Geologist | Specialty | Inscribe **`geological_chart`** — +50% mineral_vein landing rate, gem yield bonus. |
| 45 | Biologist | Specialty | Inscribe **`biological_chart`** — +30% boss-room rate. |
| 50 | Master Charter | Vision | Walking the map perimeter reveals the full chart. |
| 55 | Wightblood Press | Recipes | Mix **Wightblood Ink** (rare; unlocks wolf_alpha_den). |
| 60 | Tideink Press | Recipes + Templates | Mix **Tideink** (rotation-invariant 4×lumen). Unlock **`chart_summit`** (tier 5, 5 affix slots). |
| 60 | Falconer-Cartographer | Specialty | Borrow Sir Withering's falcon to sketch unreachable tiles remotely. |
| 65 | Aurora Press | Recipes | Mix **Aurora Ink** (T-shape; +50% on rare boss affixes). |
| 70 | Coalrose Press | Recipes | Mix **Coalrose Ink** (+40% sprinter affix). |
| 75 | Grand Charter | Endgame | Inscribe **`master_chart_bramblewood`** — wall-art map revealing the entire overworld permanently. |
| 80 | Atlas Press | Recipes | Mix **Atlas Ink** (all-9-slots; lets you re-roll one affix on any chart). |
| 90 | Atlas-bearer | Endgame | Begin the **Atlas of Bramblewood** commission chain (Brother Pell's quest line). |
| 99 | Grand Cartographer | Endgame | Complete the Atlas. Unlock **Cartographer's Cape** (+5% movement speed, +10% sketch XP, +1 affix-slot ceiling on every keystone, "Grand Cartographer of the Bramblewood" title). |

## Player-facing milestone text

For each entry, the **next unlock** preview shows in two places:

1. **World Map header** — `"Next: Lv N · [Title] — [Unlock description]"`
2. **Field Journal footer** — same line, shown on every visit so the player remembers what they're working toward

The string format is identical across both surfaces.

## Density check

Counting unlocks per band:
- Lv 1-10: 6 unlocks (high — onboarding)
- Lv 10-25: 8 unlocks (high — core loop)
- Lv 25-50: 7 unlocks (medium — depth)
- Lv 50-75: 4 unlocks (sparse — specialization)
- Lv 75-99: 4 unlocks (rare — legacy)

This shape matches the era-feel target: dense early teach + rich mid-game + earned mastery rare in late game.

## Hooks into other systems

- **Resource bias affixes** (`wood_grove`, `herbal_patch`, `gem_seam`) make charts a **resource pump** — you can deliberately roll for what you want to collect.
- **Specialty charts** (Lv 35-45) feed the **Rune Magic** system (see `docs/rune-magic-design.md`) — specialized inks become specialized runes.
- **The Atlas** integrates the Cartographer's quest chain with **Brother Pell** (the curiosity-buying Cloister monk, who also handles cartographer's curses if those ship).

## Next-unlock preview implementation

```js
// src/ui/worldMap.js
export const CARTO_UNLOCKS = [
  { lv: 1,  name: 'Apprentice Cartographer', track: 'vision', text: 'World map opens. Mix Hedge Ink + Charcoal Bind.' },
  { lv: 4,  name: 'Greengather',             track: 'recipes', text: 'Mix Stoneground Ink (earthen bias).' },
  ... (all 33 entries)
];

export function nextUnlock(level) {
  for (const u of CARTO_UNLOCKS) if (u.lv > level) return u;
  return null;
}
```

The Field Journal footer reads `nextUnlock(player.skills.carto.lv)` and displays:

> Next: **Lv 7 · Branch Walker** — New affix unlocks: Wood Grove (+3-5 log piles in chart).

## Maintenance

When a new unlock lands:
1. Add to the table above.
2. Add to `CARTO_UNLOCKS` in `worldMap.js`.
3. Add the corresponding gating check in code (e.g., `if (cartoLv < 14) { /* hide herbal_patch from picker */ }`).
4. If the unlock is a recipe, also gate it in `INK_RECIPES` (`reqCarto` field).
5. If the unlock is a chart template, gate it in `TEMPLATES` in `charting.js`.

The design table here, the data structures, and the gating logic always need to agree.
