---
type: game
tags: [game-study, colony-sim, city-builder, moral-choice, survival, hope-discontent, law-system, narrative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Frostpunk
  - https://www.gamedeveloper.com/design/frostpunk-an-analysis-of-emotional-narrative-engagement
  - https://techraptor.net/gaming/features/how-11-bit-studios-created-society-survival-simulator-frostpunk
  - https://twincitiesgeek.com/2018/05/frostpunk-is-a-struggle-between-morality-and-survival/
---
# Frostpunk

Survival city-builder (2018, 11 Bit Studios) set in a volcanic-winter apocalypse where players govern the last human settlement, balancing resource survival against a Hope/Discontent system that punishes both cruelty and weakness.

## Design

- **Hope and Discontent as dual loss conditions.** Two bars run in opposite directions: Hope must stay above zero; Discontent must stay below maximum. Laws, resource shortages, deaths, and fulfilled promises all shift both meters simultaneously. Letting either reach its limit ends the run, forcing players to maintain political balance while solving material survival — an elegant compression of governance into two numbers.
- **Book of Laws — irreversible moral branches.** The law system offers binary choices every ~24 in-game hours: child labour vs. extended school programmes; extended shifts vs. rest periods; faith healing vs. proper medicine. Once enacted, laws become permanent and open further refinements down the same branch. The irreversibility makes each decision feel like policy rather than resource purchase.
- **Heat as spatial resource.** The central coal generator radiates warmth in a circular radius that can be overclocked at fuel cost. Buildings placed inside the heat radius function normally; outside it, workers and dwellings suffer cold penalties. This forces players to expand the city in rings, making heat range a spatial constraint that interacts with coal supply — a single resource shapes both layout decisions and short-term crisis management.
- **Scenario-driven structure.** Unlike open-ended colony sims, Frostpunk uses curated scenarios with fixed narrative beats (the Great Storm, the Last Autumn) rather than infinite sandbox play. This lets 11 Bit embed a moral arc into each run while sacrificing replayability depth.
- **Standout mechanic — the Tipping Point.** Citizens don't object all at once; dissatisfaction accumulates quietly until a threshold triggers a public demand event, giving players one last chance to course-correct before losing political control. This teaches players to read early warning signs rather than react to crises.

## Implementation

- Built on 11 Bit's proprietary **Liquid Engine**; the 2027 remaster (*Frostpunk 1886*) migrates to Unreal Engine 5 to support user mods.
- City-building simulation uses a radial layout model (heat emanating from a central point) rather than a grid, unusual for the genre and technically tying spatial logic to a single simulated heat source.
- Citizen AI generates feedback messages after each law passage — flavour text that represents citizen reaction — rather than simulating individual agents. This is a deliberate performance/fidelity trade: emotional resonance via text, not simulation depth.
- Commercial: 250,000 copies in 3 days; 1.4 million in one year; over 5 million in six years. *Frostpunk 2* (September 2024) expanded the formula to faction politics at city-state scale.

## Why it matters

Frostpunk proved that **moral stakes can substitute for simulation depth** in the colony sim genre. Where Dwarf Fortress and RimWorld generate ethics through emergent systems, Frostpunk hard-codes ethical dilemmas into the law system and still produces genuine emotional weight. The design lesson: a player who must choose between child labour and starvation will feel that choice even if the simulation underneath is thin.

## Relevance to Wayfinder

- The **irreversible law model** is a reference for [[Affixes]] on charts: committing to a chart's affix set should feel like policy — you chose it, now live with it for the full run.
- The **Hope/Discontent dual-meter** is a [[Balance Philosophy]] template for dungeon run tension: a cozy run still needs a threat axis (dread, corruption, resource depletion) that climbs alongside player success.
- The **scenario-driven structure** (curated arc over infinite sandbox) suggests Wayfinder's boss-trophy chain is right to resist pure procedural open-endedness — a shaped narrative arc coexists with systemic freedom.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Dwarf Fortress]] · [[Oxygen Not Included]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Frostpunk
- https://en.wikipedia.org/wiki/Frostpunk_2
- https://www.gamedeveloper.com/design/frostpunk-an-analysis-of-emotional-narrative-engagement
- https://techraptor.net/gaming/features/how-11-bit-studios-created-society-survival-simulator-frostpunk
- https://twincitiesgeek.com/2018/05/frostpunk-is-a-struggle-between-morality-and-survival/
