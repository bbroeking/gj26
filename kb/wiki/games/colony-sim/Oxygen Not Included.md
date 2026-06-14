---
type: game
tags: [game-study, colony-sim, physics-simulation, thermodynamics, duplicant-needs, layered-challenge, crafting]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Oxygen_Not_Included
  - https://www.gamedeveloper.com/design/layering-challenges-in-klei-s-survival-sim-i-oxygen-not-included-i-
  - https://www.neogaf.com/threads/oxygen-not-included-is-a-masterclass-in-colony-sim-design.1685195/
---
# Oxygen Not Included

Space colony sim (2019, Klei Entertainment) in which players manage a small crew of "duplicants" inside an asteroid, surviving through interlocked thermodynamics, gas diffusion, power networks, and escalating psychological needs.

## Design

- **Layered simultaneous challenges.** Design lead Graham Jans articulated ONI's core principle: players must balance *all* duplicant needs at once. Solving oxygen doesn't remove the oxygen problem — it just reveals the heat-buildup problem. Each solved layer exposes the next, maintaining a perpetual frontier of competence growth without a difficulty spike.
- **Closed-loop resource conservation.** Every pixel is a resource. The simulation enforces strict mass conservation: all inputs require outputs. Excess heat must be exported somewhere; excess gas must be vented or converted. Players who ignore outputs eventually drown in their own byproducts — a natural consequence without a "failure state" trigger.
- **Thermodynamics as the hidden boss.** Gas diffusion, temperature transfer between materials, and chemical state changes (liquid → gas at boiling points) are modelled with enough fidelity to create genuine engineering problems. A player who builds an efficient oxygen generator may inadvertently superheat their base. The simulation is described internally as "mostly an illusion" — selective fidelity where it matters for gameplay, not full physics.
- **Duplicant needs hierarchy.** Survival demands evolve naturally: first oxygen and food, then waste management, then décor and stress, then morale and recreation. New players and veterans face the same systems; veterans solve them more elegantly. This is a rare design that scales with player skill without changing the rules.
- **Standout mechanic — autonomous task prioritisation.** Players issue orders; duplicants autonomously choose which tasks to execute based on individual skill ratings and proximity. This creates legibility problems (why isn't that task getting done?) that push players toward understanding the simulation rather than just issuing commands.

## Implementation

- Built on **Unity** (C#); gas and liquid simulation runs as a cellular automaton — each cell exchanges material with neighbours each tick, producing emergent diffusion without solving full fluid equations.
- Thermodynamics uses material-specific heat capacities and conductivity values; temperature propagates through physical contact between tiles and entities. The "selective simulation" approach means players can predict outcomes from intuition, but the rules are real enough to reward engineering knowledge.
- Inspired by Dwarf Fortress, Prison Architect, and The Sims; Klei deliberately diverged from Dwarf Fortress's ASCII complexity toward approachable-but-deep visual design with expressive character animation.
- Released 2019 after two years of early access; Metacritic 86. Multiple DLC expansions through 2025; ongoing live support demonstrates the depth of its playerbase.

## Why it matters

ONI is the best executed example of **layered challenge design** in the genre: every system a player masters reveals a deeper system rather than removing challenge. Combined with its physics simulation, it demonstrates that simulation fidelity and accessibility are not opposites — they require *selective* simulation at the right granularity.

## Relevance to Wayfinder

- The **layered challenge model** is the target for [[Gathering]]: basic gather should be immediately accessible; advanced material sourcing (rare ores, seasonal forage) should reveal depth without the tutorial explaining it all upfront.
- **Closed-loop resource conservation** maps onto the [[Economy]]: chart runs should consume materials that must be replenished; surplus from one trade feeds deficit in another — no infinite taps.
- ONI's **duplicant autonomy** (task prioritisation without micromanagement) is a reference for future NPC / party-member design in Wayfinder's co-op layer — see [[Balance Philosophy]].

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Dwarf Fortress]] · [[Factorio]] · [[Frostpunk]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Oxygen_Not_Included
- https://www.gamedeveloper.com/design/layering-challenges-in-klei-s-survival-sim-i-oxygen-not-included-i-
- https://www.neogaf.com/threads/oxygen-not-included-is-a-masterclass-in-colony-sim-design.1685195/
- https://game-wisdom.com/series/game-wisdoms-best-2019-8-oxygen-not-included
