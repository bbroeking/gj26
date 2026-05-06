# Cartography Systems

> Reference for the four Cartography pillars shipped on the keystone arc:
> the Workshop (the hub), the Living Atlas (long-term spine), Echo Charts
> (overworld inversion), and Inkwell Vessels (cross-skill loop).
>
> Designed so each system multiplies the others: vessels gate tier-3 inks
> that bias affixes on echo charts that fill atlas regions that unlock
> biomes that surface in the workshop's chart inventory.

```
       ┌─── overworld gathering ──┐
       │   wilds   earth   cook   │
       │     ↓      ↓       ↓     │
       │   ingredients + vessels  │
       │           ↓              │
       │   INSCRIBING TABLE       │     ┌── ATLAS ────┐
       │   3×3 grid + vessel ─→ ink     │ regions /   │
       │           ↓                     │ biome locks │
       │      PEDESTAL                   └─────────────┘
       │   ink + stone ─→ rune                ↑
       │           ↓                          │
       │      CHARTING                        │
       │   template + inks + rune             │
       │   ─→ chart (procgen OR echo)         │
       │           ↓                          │
       └─→ enter dungeon / biome ─────────────┘
                   ↓
           chest loot · carto XP · region tick
```

---

## 1. The Cartography Workshop

The hub UI. Replaces the Chartmaker's Stone's old 4-choice dialog with a
single panel that shows your carto progression and launches every
sub-modal in the loop.

**Open from**:
- `📐` HUD button (between Map and Journal)
- `C` hotkey
- Walking up to the Chartmaker's Stone

**Surfaces**:
- Lv + XP bar + next milestone hint (`src/data/skill-milestones.js`)
- Materials / Inks / Runes / Charts pills with live counts
- Sketches-this-session counter (fed by the Field Journal sketch verb)
- Open Atlas link (Charts section header)
- 4 action buttons:
  - **Mix Inks** → Inscribing Table modal
  - **Press Runes** → Pedestal modal
  - **Inscribe Chart** → Charting modal
  - **Field Journal** → sketches index

**Breadcrumb pattern**: when any sub-modal closes, the workshop re-opens
underneath. Implemented via `MutationObserver` on each backdrop's
`.open` class, so the sub-modules don't need to know about the workshop.

**Files**:
- `src/ui/cartographyWorkshop.js`
- `index.html` markup + CSS
- `src/main.js` — `openCartographyWorkshop()`, breadcrumb observers

---

## 2. The Living Atlas

The long-term spine. Every chart you complete fills one tile of a
hidden meta-map; crossing a region's threshold unlocks a new walkable
biome. Charts feed real exploration; the village is a hub, the world
expands as you map it.

**Open from**: `📜 Open Atlas` link in the workshop.

### Regions

Each region is tagged by chart `scope` and gates a biome unlock:

| Region | Scopes counted | Threshold | Biome unlock |
|---|---|---|---|
| Bramble Hollows | snug, tier_1, hollow, briar_maze | 3 | Mossvale |
| Drowned Lanes | sunken_hut | 4 | Stillwater Fens |
| Earthroot Drifts | delve | 5 | Coalrose Pits |
| Wightspires | (placeholder) | 6 | Wightspire Reach |
| The Echoes | echo_village, echo_forge, echo_perch | 5 | The Echofold |

### Biomes

Biomes reuse the existing dungeon system with **pinned seeds** so the
same layout returns every visit. They differ from charts in three ways:

1. **No carto XP on exit** — biomes are places, not crafts.
2. **No chart consumed** — re-enter freely from the Atlas.
3. **Player-friendly leave message** — "🌿 You leave the biome. The
   path back through the gate stays open."

Pinned seeds live in `BIOME_SEEDS` in `main.js`.

### Persistence

Atlas state lives at `player.atlas = { completions, unlockedBiomes }`,
flushed to `localStorage[gj26.atlas.v1]` on every change.

### Hook point

The atlas tick fires inside `exitDungeon()` when the chest was looted
and the scope isn't a biome:

```js
const result = recordChartCompletion(player, dungeon.scope);
if (result.justUnlocked) log('quest', `★ Region unlocked — ${result.region.name}`);
```

**Files**:
- `src/data/atlas-regions.js` — region table
- `src/game/atlas.js` — runtime state + persistence
- `src/ui/atlasMap.js` — modal UI

---

## 3. Echo Charts

Charts that read the **live overworld** and turn its peaceful residents
into hostiles. Same layout you walk every day, run by a different cast.

### How they work

Each echo place defines an `anchorRef` (a runtime constant like
`'cookSpawn'` or `'HOD_TILE'`) plus a radius and an enemy template.
At chart-enter time, `generateEchoLayout(world, scope, anchor)` reads
`world.tileGrid` and `world.blocked` around the anchor and copies the
walkable shape into a dungeon grid:

| Overworld | Echo grid |
|---|---|
| walkable (grass, floor, sand, path) | floor |
| blocked (wall, water, stone, tree) | wall |

Entry lands at the captured center; exit + chest go to a far corner.
Themed enemies are scattered across the floor tiles via deterministic
RNG seeded from the anchor coords.

### Echoes that ship

| Place | Anchor | Carto | Tier | Enemies |
|---|---|---|---|---|
| Echo: Bramblewood Square | cookSpawn | 35 | 2 | bramble_imp ×3, iron_gob ×2 |
| Echo: Hod's Forge | HOD_TILE | 40 | 3 | iron_gob ×2, bramble_charger ×2 |
| Echo: Withering's Perch | WITHERING_TILE | 45 | 3 | hedgewolf ×2, bramble_archer ×2 |

Echo charts go through the **same Charting modal** as procgen charts —
ink-slotting biases the affix roll, rune-slot bakes a passive. Tier
matches the procgen tier ladder.

### Knowledge advantage

Carto-savvy players who walk the village every day can predict cover,
chokepoints, and pull angles in the echo. A Lv 35 player who lives in
the village out-strategizes a Lv 50 brute-forcer.

### Hook point

```js
if (scope.startsWith('echo_')) {
  const anchor = anchorTileForEchoScope(scope);
  if (anchor) layout = generateEchoLayout(world, scope, anchor, affixes);
}
```

**Files**:
- `src/data/echo-places.js` — place catalog
- `src/scene/dungeon.js` — `generateEchoLayout`
- `src/data/items.js` — 3 chart items
- `src/ui/charting.js` — 3 echo TEMPLATES entries
- `src/main.js` — anchor resolver + enterDungeon hook

---

## 4. Inkwell Vessels

The cross-skill loop. Tier-3 inks need a vessel commissioned from one
of three NPCs, each tied to a different skill family. Want endgame
ink? You need the smith, the herbalist, and the cooper.

### The three vessels

| Vessel | NPC | Essence | Cost |
|---|---|---|---|
| Clay Flask | Hod (forge) | earthen | 30 gp + 1 stoneground_ink + 2 charcoal_stick |
| Bound Parchment | Quill (herbalist) | verdant | 40 gp + 1 vellum + 2 wishrose |
| Glass Vial | Cricket (cooper) | lumen | 50 gp + 1 wellspring_ink + 1 ore_dust |

Each NPC's dialog gains a **"Commission a [Vessel]…"** option once the
player reaches Cartography 30. The choice is auto-greyed-out if the
player can't afford the cost (with a hint of what's missing).

### The three tier-3 inks

| Ink | Pattern | Vessel | Bias |
|---|---|---|---|
| Forge-Brand Ink | sanguine X-corners + ember_ink center | Clay Flask | tyrannical 1.5×, bursting 1.3×, +10% stability |
| Aurora Ink | verdant T2 plus + bog_ink center | Bound Parchment | bramble_bloom 1.5×, fog_of_hedge 1.3×, +10% stability |
| Tidewater Ink | lumen plus + lustrous_ink center | Glass Vial | mineral_vein 1.3×, gilded_seam 1.3×, bramble_bloom 1.2×, +10% stability |

Tier-3 inks have an extra **+10% stability** bias on top of the affix
multipliers — they're how endgame players guarantee good twins on
high-affix-slot charts.

### The Inscribing Table change

A **vessel slot** sits between the 3×3 grid and the output:
- Empty: dashed gold border.
- Filled: solid green border + the vessel's icon + name.

Click a vessel in the ingredient list → it slots there (instead of
dropping into the grid). Click the slot itself → unslot.

### Match logic

`matchRecipe(grid, ITEMS, vesselId)` skips any recipe whose `vessel`
field doesn't match the slotted id. Tier-1/2 recipes have no `vessel`
field and ignore the slot entirely. Tier-3 recipes specify their
required vessel.

If the matched recipe consumes a vessel, the inscribe path removes one
from the bag alongside the grid ingredients. Wild/smudge paths leave
the vessel in the bag — a misclick isn't catastrophic.

**Files**:
- `src/data/items.js` — 3 vessel items + 3 tier-3 ink items
- `src/data/inkRecipes.js` — 3 tier-3 recipes + matcher extension
- `src/ui/inscribingTable.js` — vessel slot rendering + click handlers
- `index.html` — vessel slot markup + CSS
- `src/main.js` — `vesselCommissionChoice` helper, wired into Hod /
  Quill / Cricket dialogs

---

## How the four systems compose

Concrete player journey, Lv 1 → Lv 50:

1. **Lv 1–5**: forage hedgecaps, mine ore, fish — fill the bag.
2. **Lv 5–10**: open the **Workshop**, mix Hedge Ink at the table,
   inscribe a Snug chart, run it.
3. **Lv 10–15**: complete 3 snug-scope charts → **Atlas** ticks
   Bramble Hollows full → Mossvale unlocks. Walk to Mossvale from the
   Atlas; gather there.
4. **Lv 15–25**: tier-2 ink recipes unlock; charts get richer. Each
   completion fills its region.
5. **Lv 30**: Hod / Quill / Cricket dialogs grow a "Commission a
   Vessel" option. Buy one, slot it, mix tier-3 ink.
6. **Lv 35**: **Echo: Bramblewood Square** template unlocks in the
   Charting modal. Inscribe one with tier-3 ink for sharp affix bias.
   Run it; the village layout you know cold is now hostile.
7. **Lv 35–50**: clear 5 echoes → "The Echoes" region full → Echofold
   biome unlocks.

Each system multiplies the next. The Workshop made the loop legible.
The Atlas made it durable. Echoes made the village itself a resource.
Vessels pulled every skill into the carto verb.

---

## Where to extend

The most natural next pieces from `cartography-depth-20.md`:

- **#7 Atlas Codex** — the Atlas already tracks completions; logging
  every inscribed chart with its seed turns the Atlas into a personal
  "every line you walked" history.
- **#11 NPC-signed charts** — vessels already pull NPCs into carto;
  signing extends the same surface to chart inscription.
- **#1 Themed chart families** — slot directly into the existing scope
  → atlas-region mapping; just add new TEMPLATES entries + region
  `scopes` arrays.

Anything that consumes or produces a chart can hook the existing
`recordChartCompletion(player, scope)` for atlas progression, and any
new ink can declare a `vessel` requirement to use the existing tier-3
slot.
