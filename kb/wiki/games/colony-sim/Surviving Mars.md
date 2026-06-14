---
type: game
tags: [game-study, colony-sim, city-builder, sci-fi, colonist-simulation, mystery-system, dome-management]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Surviving_Mars
  - https://www.paradoxinteractive.com/games/surviving-mars-relaunched/news/mysteries-of-mars
  - https://survivingmars.paradoxwikis.com/Mystery
  - https://www.haemimontgames.com/dev-diary-3-dome-sweet-dome-by-boian-spasov-from-haemimont-games/
---
# Surviving Mars

Colony-management city-builder (2018, Haemimont Games / Paradox Interactive) set on the Red Planet, combining macro-scale infrastructure planning with per-colonist trait simulation and optional mystery storylines that introduce science-fiction crisis events.

## Design

- **Two-layer resource model.** The outer shell is infrastructure: power grids, water extractors, oxygen filtration, cable and pipe routing across the Martian surface. The inner shell is dome ecology: each pressurized dome contains residences, workplaces, and amenities whose balance determines colonist mood. Players must solve both layers simultaneously — a failing power grid collapses dome life support; a well-powered but under-served dome produces a morale collapse.
- **Per-colonist trait and need simulation.** Every colonist carries traits (Loner, Dreamer, Genius) and four tracked stats: Health, Sanity, Comfort, and Morale. Traits interact with dome design non-trivially — a Loner colonist loses Comfort daily if their dome population exceeds 30, so optimal dome design varies by trait distribution. Players can filter Earth applicants by desired traits, adding a soft recruitment layer to expansion.
- **Mystery system — optional narrative injection.** Each game can include one Mars storyline (e.g., alien contact, AI rebellion, corporate war) and one asteroid event. These are not scripted cutscenes but condition-gated event chains that interact with colonist traits, dome building inventories, and terraforming progress. The Inner Light mystery, for instance, requires 250 colonists with the Dreamer trait and specific research unlocked — effectively a long-run questline embedded in the simulation.
- **Scanning and resource scarcity.** Sectors must be scanned before construction; scanning reveals deposits, anomalies, and mystery triggers. This creates an exploration loop within the city-builder framing — expansion is gated by knowledge, not just materials.
- **Standout mechanic — the supply rocket cadence.** Early-game survival depends on importing consumables from Earth by rocket. Rockets have a travel time, forcing players to forecast supply needs 30-40 in-game days out; a miscalculated order can leave colonists without food or medicine mid-crisis. This instils a habit of long-range planning before the colony becomes self-sufficient.

## Implementation

- Built on the Haemimont-developed engine previously used for Tropico 5 and Victor Vran; Paradox sold the IP to Abstraction Games in 2021.
- Relaunched as *Surviving Mars: Relaunched* (2025), consolidating all DLC and updating the UI, signalling continued commercial relevance.
- Metacritic: 73–76 across platforms. Praised for depth; criticised for tutorial sparsity.

## Why it matters

Surviving Mars explored how to layer individual-agent simulation atop infrastructure city-building without either layer overwhelming the other. The mystery system is an underappreciated template for injecting narrative into sandbox sims: storylines are unlocked by simulation state, not by time, so the player's choices determine when (and whether) they fire.

## Relevance to Wayfinder

- The **trait-gated event design** of the Mystery system is a model for [[Affixes]]: a dungeon affix could trigger a special encounter only when the player's chart includes specific secondary affixes, rewarding build synergy with rare narrative events.
- The **supply-rocket cadence** (long forecast horizons for consumables) mirrors the intent behind [[Gathering]] loops: players should need to plan resource extraction *before* they need the crafted output, not just-in-time.
- The **dome ecology model** — inner environment tuned to its occupants' traits — suggests a design space for Wayfinder's party: [[Crafting]] consumables could be trait-matched to a specific companion's affinities rather than generic buffs.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Frostpunk]] · [[Oxygen Not Included]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Surviving_Mars
- https://www.paradoxinteractive.com/games/surviving-mars-relaunched/news/mysteries-of-mars
- https://survivingmars.paradoxwikis.com/Mystery
- https://survivingmars-archive.fandom.com/wiki/Colonist
- https://www.haemimontgames.com/dev-diary-3-dome-sweet-dome-by-boian-spasov-from-haemimont-games/
