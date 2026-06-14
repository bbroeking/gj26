---
type: game
tags: [game-study, colony-sim, city-builder, faction-politics, social-survival, law-system, narrative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Frostpunk_2
  - https://11bitstudios.com/games/frostpunk-2/
  - https://retrostylegames.com/blog/frostpunk-game-design/
  - https://gamerant.com/frostpunk-1886-war-mine-remake11-bit-studios-upcoming-games/
---
# Frostpunk 2

Society-management city-builder (2024, 11 Bit Studios, Unreal Engine 5) that shifts the franchise's crisis from environmental survival to political survival, asking players to govern a post-apocalyptic city-state through a faction council rather than direct construction orders.

## Design

- **District-scale building over individual structures.** Rather than placing single buildings, players zone entire districts — food, housing, industry, extraction — and the district generates its own internal logistics. This abstraction lifts the camera to "city-state governor" without losing the resource-constraint feeling of the original.
- **Faction council as the core pressure loop.** A 100-seat council represents competing ideological factions. Laws require majority votes (51 seats) or supermajorities (67 seats) for power-granting measures. Players negotiate, make promises, and broker coalitions — broken promises damage trust and can trigger faction rebellions, creating a second resource (political capital) layered over material resources.
- **Idea Tree as locked tech.** Factions propose research branches via an Idea Tree; adopting one faction's ideas locks out rival branches and increases that faction's political leverage. This encodes long-term ideological commitment into the progression system, echoing the irreversible law branches of the original.
- **"Social survival" as the sequel's thesis.** The director framed the shift explicitly: "the biggest enemy is always human nature." Environmental crises (cold, fuel) remain, but faction unrest, inequality, and broken promises can end a run as surely as a coal shortage — pressure comes from within as much as from the frost.
- **Standout mechanic — the weekly timescale.** Frostpunk 1 ran in real-time hours; FP2 operates on weekly turns. This prevents the original's frantic micro-management, forcing the player to think in terms of policy cycles rather than crisis reactions. Tension accumulates slowly and releases in council votes rather than sudden freezing events.

## Implementation

- Unreal Engine 5; previous entry used 11 Bit's proprietary Liquid Engine. The switch enabled mod support and the larger scale city views required by district building.
- City geometry is procedurally decorated within district zones, reducing hand-placement work while maintaining visual coherence at the new scale.
- Reception strong: 85/100 Metacritic, 95% OpenCritic recommendation; 592,000 copies sold and $18.5M revenue by December 2024; "Best Sim/Strategy Game" at The Game Awards 2024.

## Why it matters

Frostpunk 2 demonstrated that a sequel can successfully pivot a colony sim's central axis — from "beat the environment" to "beat political entropy" — without abandoning the core tension loop. The faction council is a model for how to encode ideological commitment into game systems: choices are not reversible, coalitions are fragile, and long-term trust compounds like a resource.

## Relevance to Wayfinder

- The **Idea Tree locked-branch structure** maps cleanly onto [[Affixes]]: opposing affix clusters could be mutually exclusive, so committing to a Crypt run's "bone cold" affix closes off the "cursed warmth" cluster for that chart.
- The **policy-cycle timescale** (weekly rather than real-time) is a [[Balance Philosophy]] note: cozy games benefit from deliberate pacing — let players think between crises rather than react to them.
- The **faction-trust resource** is a design reference for [[Economy]]: reputation with trade partners or NPC factions could compound or decay, giving Wayfinder an invisible economy alongside gold.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Frostpunk]] · [[RimWorld]] · [[Dwarf Fortress]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Frostpunk_2
- https://11bitstudios.com/games/frostpunk-2/
- https://retrostylegames.com/blog/frostpunk-game-design/
- https://store.steampowered.com/app/1601580/Frostpunk_2/
