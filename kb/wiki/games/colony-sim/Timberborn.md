---
type: game
tags: [game-study, colony-sim, city-builder, water-simulation, drought-cycle, vertical-building, cozy-hard]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Timberborn
  - https://www.gamedeveloper.com/design/deep-dive-timberborn-s-water-mechanics
  - https://www.gamedeveloper.com/marketing/deep-dive-how-we-got-one-million-players-to-give-a-dam-about-timberborn
  - https://mechanistry.com/press/wonders-of-water-timberborn-update-6-adds-3d-water-physics-new-skyward-engineering-and-official-mod-support
---
# Timberborn

Post-apocalyptic beaver city-builder (2021 Early Access → 2025 full release, Mechanistry) where all city-building decisions orbit a physics-simulated water system and a dry/wet season cycle that turns resource scarcity into the central design rhythm.

## Design

- **Water as the universal constraint.** Beavers drink water, irrigate farmland with it, power water wheels for electricity, and route it through production buildings. Every colony layout is fundamentally a water routing problem: dams store supply, floodgates control release, and canals extend irrigation reach. Topology matters — hilltop farms require deliberate canal infrastructure because moisture spreads from water tiles to adjacent ground tiles at diminishing rates, and elevation blocks the spread.
- **Drought as a recurring boss fight.** Dry seasons are announced in advance; water sources gradually weaken before the drought formally begins (a smooth visual signal rather than a hard cut). During drought, all non-stored water disappears and crops die unless irrigated from reserves. The design goal is "memorable moments" — the drought arriving faster than expected while crops still need two more weeks is a reliably tense scenario the player builds toward every cycle, not a random event.
- **Hybrid 2D/3D water simulation.** Each tile connects to four neighbours via virtual pipes; depth values level out continuously. Water momentum is calculated between ticks, enabling realistic flooding: a shallow river pools slowly behind a dam; releasing a full reservoir creates a wave. This simulation is computationally affordable because it is tile-discrete rather than particle-based, enabling colony-scale use without GPU bottlenecks.
- **Faction differentiation as playstyle gate.** Two beaver factions (Folktails: pastoral, bio-based; Iron Teeth: mechanical, industrial) access the same water system through different building vocabularies. This provides replayability without separate rule sets — the constraint (water) is universal; the tools differ.
- **Vertical architecture as a spatial premium.** Unlike flat city-builders, Timberborn allows multi-story construction and underground burrowing. A single tile footprint can support a tower of living quarters, concentrating population density near water while leaving floodplains free for farms. The vertical axis emerged from player demand and became a signature visual identity marker.
- **Standout mechanic — the badwater tide.** Later-game threat variant: instead of drought, contaminated water (badwater) floods the map during bad tide seasons. It kills crops and harms beavers if they drink it, requiring players to build badwater barriers and purification infrastructure. A second-cycle threat that reuses the water routing knowledge players already built.

## Implementation

- Built in Unity (C#). The water simulation is a custom hybrid system derived from academic fluid dynamics research, not a standard physics engine feature.
- Early Access launched September 2021; passed one million players by the time of the gamedeveloper.com deep dive. Full 1.0 launched 2025.
- Update 6 (*Wonders of Water*) added true 3D water physics and official mod support, deepening the simulation further after commercial stability was established.

## Why it matters

Timberborn is the clearest modern example of a **single system (water) that recursively drives every other design decision**: layout, pacing, power generation, food, faction choice, and seasonal survival. Its success with both hardcore strategists and cozy-sim players shows that deep simulation and approachable aesthetics are not mutually exclusive — the difficulty is in presentation and pacing, not in the simulation itself.

## Relevance to Wayfinder

- The **single-resource recursive design** is a direct model for [[Gathering]]: if one material (say, Inkweed) flows through harvesting, crafting, chart-inscribing, and boss unlocking, it becomes a lever the player understands deeply rather than one of many interchangeable inputs.
- The **advance-warning drought rhythm** is a [[Balance Philosophy]] template for Wayfinder dungeon floors: pre-announce escalating threats (torchlight, cold, curse stacks) so players can act preventively, creating deliberate tension rather than unfair spike damage.
- Timberborn's dual audience (hardcore / cozy) maps exactly onto Wayfinder's target: the aesthetic should be warm and readable while the [[Economy]] underneath can carry genuine strategic weight.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Frostpunk]] · [[Banished]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Timberborn
- https://www.gamedeveloper.com/design/deep-dive-timberborn-s-water-mechanics
- https://www.gamedeveloper.com/marketing/deep-dive-how-we-got-one-million-players-to-give-a-dam-about-timberborn
- https://mechanistry.com/press/wonders-of-water-timberborn-update-6-adds-3d-water-physics-new-skyward-engineering-and-official-mod-support
