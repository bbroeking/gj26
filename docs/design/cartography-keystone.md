# Cartography as the keystone skill

> Reframing cartography from "one of 10 skills" to "the player's
> progression spine." All other systems already feed into it; surfacing
> that explicitly lets the carto loop do triple duty as the game's
> exploration verb, crafting verb, and content gate.

## Why cartography becomes the spine

Cartography is the only skill that:

1. **Consumes outputs from every other skill.**
   - Wilds → herbs / berries / mushrooms → ink ingredients
   - Earth → ores → ink ingredients (stoneground, ember)
   - Magic → runes baked into charts (rune slot at carto 50)
   - Cook → field rations (consumed during dungeon runs)
   - Combat skills → gear that survives the dungeons

2. **Produces the only on-demand content** in the game — charts are
   enterable dungeons. Without charts, the wolds are a static map.

3. **Has the most ingredients-per-output ratio.** A single chart wants:
   ingredients → ink (3×3 recipe), ink → rune (pedestal), inks +
   parchment + sketch → chart (charting). Three distinct verb-stations.

OSRS players already understand this shape — Slayer was their keystone
because it touched every combat skill. Bramblewood's equivalent is
cartography touching every gathering / crafting / magic skill.

## What needs to be true for that to work

| Need | Status |
|---|---|
| **Cartography has a clear UI surface** that shows the player their progress | ❌ scattered across 3 modals |
| **The carto loop is short enough** to feel rewarding | ✅ ~5 min from raw → chart |
| **Charts reward more than just the dungeon** | ⚠️ chest loot only, no carto XP |
| **There's a visible carto-progress beat every session** | ❌ XP floats but no overarching tracker |
| **Players know cartography exists** in hour 1 | ⚠️ tutorial mentions chartmaker but no HUD entry |

The discoverability + status-surface gaps are what we're filling now.

## The Cartography Workshop UI

A unified panel accessible from the HUD-tools cluster (📐 button), and
also from interacting with the Chartmaker's Stone in-world. Replaces
the current 4-choice dialog at the stone.

**Layout (single panel, no tabs — info dense by default)**:

```
╔═══════════════════════════════════════════════════╗
║ 📐 Cartography Workshop                       [×] ║
║ Lv 5 · 240 / 512 XP    ▰▰▰▰▰▱▱▱▱▱            ║
║ Next: Lv 8 — Stoneground ink unlock              ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║ MATERIALS                                         ║
║   🍄 Hedgecap: 3   🫐 Whitleberry: 5             ║
║   ☐ Charcoal Stick: 8   📜 Vellum: 5             ║
║                                                   ║
║ INKS                                              ║
║   ▣ Hedge Ink: 2    ▣ Charcoal Bind: 1           ║
║   ▢ Wellspring Ink (need: 1 ink + 1 stone)       ║
║                                                   ║
║ RUNES                                             ║
║   ⨀ Air: 0    ⨀ Water: 1    ⨀ Earth: 0          ║
║                                                   ║
║ CHARTS                                            ║
║   ▤ Tier 1 Hollow: 1   ▤ Snug: 0                 ║
║                                                   ║
║ ┌─────────────────────┬─────────────────────┐   ║
║ │ Mix Inks            │ Press Runes         │   ║
║ ├─────────────────────┼─────────────────────┤   ║
║ │ Inscribe Chart      │ Field Journal       │   ║
║ └─────────────────────┴─────────────────────┘   ║
║                                                   ║
║ SKETCHES THIS SESSION: 2 · cow, well             ║
╚═══════════════════════════════════════════════════╝
```

Clicking any of the 4 action buttons opens the existing modal (inscribing
table / pedestal / charting / field journal). When that modal closes,
the workshop reopens — single source of "where am I in the carto flow."

## The 5 design changes around it

1. **HUD entry**: 📐 button in the hud-tools cluster (between Map and Journal)
2. **Stone interaction**: clicking the chartmaker stone opens the
   workshop instead of the 4-choice dialog
3. **Modal breadcrumbs**: closing the inscribing/pedestal/charting modal
   returns to the workshop if that's where it was opened from (not back
   to the world)
4. **Status surface**: workshop shows `player.skills.carto` + ink
   inventory + rune inventory + chart inventory + next milestone
5. **Sketch counter**: workshop shows "Sketches this session" so the
   player sees that out-of-workshop sketching also feeds the skill

## What I'm NOT changing

- **The recipes / inks / runes / chart templates** — those are already
  authored and balanced; this is UX work, not content work
- **The chart-affix system** — already feels good; charts roll fine
- **XP curves** — carto curve was already tuned in the recent xpForLevel pass
- **The chartmaker stone's location** — east of spawn, recently
  reorganized; the workshop is just the new dialog you see at the stone

## Cost

~150 lines: 1 new JS file + ~30 lines of HTML markup + ~50 lines CSS +
small wiring tweaks to existing modals' close handlers. ~1.5h shipped.

After this, cartography reads as a deliberate progression system rather
than three separate menus that happen to share an ingredient pool.
