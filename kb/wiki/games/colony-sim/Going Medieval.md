---
type: game
tags: [game-study, colony-sim, medieval, voxel-building, 3d-construction, colonist-needs, base-defense, plague-setting]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Going_Medieval
  - https://screenrant.com/foxy-voxel-interview-going-medieval-early-access/
  - https://www.pcgamer.com/going-medieval-is-a-colony-sim-that-takes-its-castle-building-quite-seriously/
  - https://gadgetvibes.com/going-medieval-review-2025-colony-builder/
---
# Going Medieval

3D voxel medieval colony sim (Early Access 2021, full release March 2026, Foxy Voxel) set in an alternate-history 14th-century Britain where plague survivors rebuild civilisation — distinguished from genre peers by fully 3D terrain manipulation, underground dungeon construction, and multi-story fortification building.

## Design

- **Full 3D construction as the differentiator.** Where RimWorld and Dwarf Fortress use 2.5D overhead or layered views, Going Medieval gives players genuine 3D building tools: colonists dig into hillsides, carve underground cellars and granary tunnels, and construct multi-story stone towers with functional floors. A castle can have working rooms on every level, creating spatial puzzle-solving absent from flat colony sims.
- **Indirect colonist control.** Players assign tasks and priorities; settlers pathfind and execute autonomously. This creates the same emergent unpredictability as RimWorld — a colonist with low morale might abandon a critical task mid-way — without the direct micro-management of games like Dwarf Fortress's burrow assignments.
- **Colonist mood and needs system.** Each settler tracks needs (food quality, sleep quality, comfort) and traits that interact with those needs over time. Poor conditions accumulate dissatisfaction; sustained neglect causes settlers to leave the colony permanently, not just underperform. The exit threat makes colonist wellbeing a concrete resource management problem.
- **Procedural terrain with customisable hazards.** Maps are randomly generated with adjustable terrain types (hills, flatlands, forests) and threat settings (raid frequency, wildlife aggression). This gives the game a replayability lever absent from handcrafted scenarios.
- **Raid defence as the external pressure spike.** Bandit raids, animal attacks, and neighbouring settlement aggression punctuate the building sim with combat events that test the fortifications players have constructed. Unlike RimWorld where raids are frequent and escalating, Going Medieval's raids serve more as milestone stress-tests for the player's defensive architecture — a castle-building evaluation loop.
- **Standout mechanic — vertical zoning.** Players naturally separate their settlement vertically: ground-level fields and workshops, first-floor workshops and storage, upper floors for sleeping quarters and lookout towers, underground for cold storage and emergency shelters. Vertical zoning creates legible functional strata in the colony without the game enforcing it.

## Implementation

- Built in Unity for Windows. The 3D terrain manipulation uses voxel chunk logic similar to Minecraft's engine pattern but at a larger granularity (multi-block structures rather than single-block placement).
- Early Access from June 2021 to full release March 2026 — an unusually long development cycle; ongoing community feedback shaped the content roadmap substantially.
- 83% OpenCritic recommendation at launch. Often recommended as an accessible entry point for players who find RimWorld's systems opaque, given its more visual 3D building metaphor.

## Why it matters

Going Medieval shows that **3D space is an underexplored constraint in colony sims**: the vertical axis adds a planning dimension that flat sims cannot replicate. Its long early-access runway also demonstrates a content-expansion model where core building mechanics ship first and simulation depth (needs, mood, economy) deepens iteratively — a viable pacing strategy for small teams.

## Relevance to Wayfinder

- The **vertical zone strata** model resonates with Wayfinder's dungeon design: Dungeon floors could encode function by depth (surface camps, mid-level encounters, deep boss chambers) in a way players intuit spatially, not just numerically.
- The **settler-exit threat** (dissatisfied colonists leave permanently) is a [[Balance Philosophy]] note for co-op: party members abandoning a run due to accumulated stress or failure states creates higher stakes than a simple revive system.
- The **raid as castle-evaluation** loop offers a template for Wayfinder's boss encounters: the boss fight should test the specific loadout the player assembled during the run, not bypass it — the dungeon is the castle, the boss is the raid.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Dwarf Fortress]] · [[Banished]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Going_Medieval
- https://screenrant.com/foxy-voxel-interview-going-medieval-early-access/
- https://www.pcgamer.com/going-medieval-is-a-colony-sim-that-takes-its-castle-building-quite-seriously/
- https://gadgetvibes.com/going-medieval-review-2025-colony-builder/
