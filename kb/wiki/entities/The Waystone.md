---
type: entity
tags: [waystone, chart, dungeon-entry, run, exit]
status: draft
updated: 2026-06-13
sources: ["docs/cartography.md", "docs/cartography-keystone-design.md", "docs/cartography-systems.md", "wyrd/data/charts.gd"]
---

# The Waystone

The Waystone (the Chartmaker's Stone in Bramblewood) is the in-world object where a finished [[Charts|chart]] is activated — it is the threshold between the village and a hollow, consuming the chart and generating the run from its parameters.

## Location

The Chartmaker's Stone sits east of spawn (3 tiles east, 1 north), in a small clearing at the edge of the village. It is the cartography hub: pressing **E** or left-clicking it opens the combined [[The Crafting Bench|Crafting Bench]] dialog. The stone doubles as both the crafting station and the entry point, keeping the loop spatially tight.

A lighter Inscribing Table also exists at Maud's hut — it allows ink mixing and chart drafting but has no pedestal, so boss-den trophies cannot be socketed there. (Design/prototype data; `docs/cartography.md`.)

## Entering a hollow

Once a chart is crafted, it sits in the player's chart case. To enter:

1. Approach the Chartmaker's Stone (or, in design intent, left-click the chart in the chart case from anywhere)
2. The chart is consumed; its `template_id`, `tier`, `affixes`, and `seed` are passed to `DungeonGen.generate`
3. The player loads into the generated hollow; the [[Dungeon Generation]] pipeline has already populated rooms, decor, enemies, and gather nodes

In the three.js prototype (`src/game/quest.js`), charts were activated by left-clicking in the inventory. In the Godot implementation, entry is gated through the Waystone interaction. Both approaches consume the chart on entry.

## During the run

Inside the hollow:

- The player fights through rooms structured from entry → combat → optional shrine/treasure/rest → boss (see [[Dungeon Generation]])
- [[Affixes]] that resolved to good twins are active (e.g., extra ore rocks from `mineral_vein`, faster enemies from `sprinter`)
- Bad twins are also active; the player knew the risk when they inscribed
- Completing the boss room and looting the chest triggers run completion

## Completing a run

On exit (chest looted, exit tile reached):

- The chart awards Wayfinder XP via `Charts.completion_xp(chart)`
- Boss trophy items may drop (these unlock the next den in the trophy chain)
- The Living Atlas records the completion, ticking the regional counter
- If a region threshold is crossed, a new biome unlocks

The chart is consumed regardless of outcome — abandoning a run mid-way means losing it. (Design note: "V1: no save state; the chart is consumed on entry." `docs/cartography-keystone-design.md`)

## Echo chart entry

Echo charts (design-stage, not in Godot yet) use the same entry path but call `generateEchoLayout` instead of `DungeonGen.generate`, capturing the overworld tile grid around an anchor point. The player enters a hostile mirror of a familiar location. Entry and exit mechanics are otherwise identical.

## Exit and abandon

The standard exit tile appears in the boss room area after the boss is defeated. An early-exit ("abandon") mechanic has been discussed but not implemented — current behavior is that the chart is consumed on entry and there is no mid-run save state. Proposal for V2: on client close mid-dungeon, the chart remains consumed but the player could re-enter at the entrance (`docs/cartography-keystone-design.md`, open design question).

## See also

- [[Charts]] — what the stone activates; the chart dictionary format
- [[The Crafting Bench]] — the same stone, used as a crafting station
- [[Chart Loop]] — the full loop the Waystone is the entry gate for
- [[Dungeon Generation]] — what runs when a chart is consumed
- [[Affixes]] — the modifiers that become active inside the hollow
- [[Bosses]] — what awaits in the deepest room

## Sources

- `docs/cartography.md`
- `docs/cartography-keystone-design.md`
- `docs/cartography-systems.md`
- `wyrd/data/charts.gd`
