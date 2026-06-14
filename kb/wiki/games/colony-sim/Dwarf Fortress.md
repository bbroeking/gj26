---
type: game
tags: [game-study, colony-sim, emergent-narrative, simulation-depth, procedural-generation, crafting, economy, ascii]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Dwarf_Fortress
  - https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories
  - https://www.researchgate.net/publication/356686095_Characterization_and_Emergent_Narrative_in_Dwarf_Fortress
---
# Dwarf Fortress

Construction and management simulation (alpha 2006, full release 2022; Bay 12 Games / Tarn & Zach Adams) in which a procedurally generated world history and fully simulated dwarf psychology produce emergent stories of fortress triumph and catastrophic loss.

## Design

- **Simulation-first philosophy.** Dwarves have needs (food, drink, sleep), moods tied to relationship losses and injuries, and individual preferences for materials, food, and art. When neglected, stress accumulates into tantrums, melancholy, or berserk rampages. No scripted event triggers this — it falls out of simulation state.
- **"Losing is fun."** The community mantra. Fortress failures are narratively rich, not punishments: a dwarf's mood spiral, a forgotten flood gate, a goblin siege during winter harvest — each loss is a story. Permadeath with Legends mode lets players read the history of what happened, turning collapse into lore.
- **Emergent crafting and economy.** Players designate labour zones; dwarves autonomously execute tasks across stone-cutting, metalworking, gem-cutting, farming, and brewing. Yearly trade caravans create an export economy: craft high-quality goods → trade for raw materials and seeds → diversify production. "Strange Mood" events inspire dwarves to craft legendary artifacts from materials on hand, generating unique in-world relics.
- **Procedural world generation.** Full geological and historical simulation pre-game: civilisations rise and fall, heroes live and die, sites are built and abandoned. The fortress inherits this history — immigrants arrive with relationships and past traumas from the generated world.
- **Standout mechanic — emergent engravings.** Dwarves with sufficient skill carve murals on walls depicting real events from their past and the world's history, turning the fortress itself into an autobiography. This emergent memorialisation inspired subsequent academic work on procedural narrative.

## Implementation

- Written in **C/C++** (Microsoft Visual Studio); ASCII tile rendering using Code Page 437 characters rather than sprites. The 2022 Steam edition added a tileset and music layer over the same engine.
- Simulation runs on a single thread; all dwarves execute on a priority task queue against a shared world state. No multithreading for dwarf AI — complexity is managed through task queuing depth rather than parallel execution.
- World generation is a full offline simulation pass (minutes of computation) producing a complete geological and historical record before play begins; in-play simulation is incremental from that state.
- Free-to-play for 16 years; the 2022 Steam release exceeded sales projections within 24 hours, topping 1 million copies sold by April 2025, validating a depth-over-polish design bet held for two decades.

## Why it matters

Dwarf Fortress is the foundational proof that **unfettered simulation produces better stories than authored ones**. Every major colony sim (RimWorld, ONI, Frostpunk, Prison Architect) cites it as a primary influence. Its design bet — depth of simulation over interface polish — remained commercially validated even when the interface was baffling ASCII art.

## Relevance to Wayfinder

- The **emergent artefact** model (Strange Mood → legendary item with a name and history) is a direct inspiration for [[Crafting]] tier ceilings: high-skill crafter + rare materials + chart affixes = a named result, not just a stat stick.
- **Layered need simulation** — where unmet lower needs cascade to higher psychological ones — benchmarks the depth target for [[Gathering]]: gather nodes should feel like part of an ecosystem with consequences, not just resource dispensers.
- The **trade caravan economy** (yearly surplus → external trade → unlock materials otherwise unavailable) is a structural model for Wayfinder's [[Economy]] and the chart market.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Oxygen Not Included]] · [[Frostpunk]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Dwarf_Fortress
- https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories
- https://www.researchgate.net/publication/356686095_Characterization_and_Emergent_Narrative_in_Dwarf_Fortress
- https://en.wikipedia.org/wiki/Boatmurdered
