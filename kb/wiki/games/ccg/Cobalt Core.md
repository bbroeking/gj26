---
type: game
tags: [game-study, deckbuilder, roguelike, single-player, movement, time-loop, sci-fi, rocket-rat]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Cobalt_Core
  - https://www.gamedeveloper.com/design/how-cobalt-core-makes-movement-as-exciting-as-fighting-in-its-roguelike-deckbuilder-combat
  - https://www.pcgamer.com/deckbuilder-fans-owe-themselves-some-time-with-the-brilliant-cobalt-core/
  - https://store.steampowered.com/app/2179850/Cobalt_Core/
---

# Cobalt Core

Roguelike deckbuilder (Rocket Rat Games / Brace Yourself Games, 2023) — a time-loop sci-fi deckbuilder that adds a 1D movement axis to card combat, making positional dodge-and-line-up decisions as tactically rich as hand management, without adding any numbers larger than single digits.

## Design

- **Movement axis**: Ships slide left and right during combat; both the player and enemies occupy positions on a shared horizontal track. Attacks target specific columns; moving out of the way of an incoming shot is a valid defensive play. This collapses the spatial reasoning of a positional game into a single dimension, making it immediately legible without sacrificing tactical depth.
- **Movement as card resource**: Movement is not free — it costs card actions or specific movement cards. Each turn's hand must be evaluated both for damage output and for repositioning value. Some enemies "seek" (following your ship), others fire fixed-column patterns, each creating a distinct spatial problem to solve with the available hand.
- **Crew system**: A party of three characters (chosen from eight) each contributes a specialised sub-deck (attack, shields, evasion, etc.). The combined deck is shuffled together; synergies between crew card types emerge organically rather than being designed-in per character.
- **Small numbers, high legibility**: The game deliberately avoids double-digit numbers. All values are single-digit; damage, shields, and energy costs stay minimal. This makes mental arithmetic trivial and lets players evaluate plays instantly.
- **No currency / streamlined shops**: Between runs, nodes offer "choose one treat" — no currency to track, no gold economy to manage. Shops are pure choice without a budget constraint.
- **No meta-progression inflating numbers**: Clearing runs unlocks alternate characters and narrative content but does not make existing characters statistically stronger. Each run starts from the same power baseline, keeping the difficulty honest.
- **Time loop narrative**: Three anthropomorphic crew members wake inside a pocket-dimension time loop. An AI companion (CAT) retains memory across loops, gradually restoring the crew's history. The loop structure is both the roguelike justification and a plot device driving the narrative forward.
- **Single-purchase**: No microtransactions, no battle pass. $24.99 at launch.

## Implementation

- Developed solo/small team (Rocket Rat Games), published by Brace Yourself Games. Windows/Switch November 2023; macOS July 2025.
- Metacritic 94; D.I.C.E. Award nomination for Strategy/Simulation Game of the Year.
- The 1D movement system is implemented as an offset integer per entity; collision between ship positions and attack columns is simple integer comparison, making the spatial model extremely cheap to simulate and display.

## Why it matters

Cobalt Core proves that adding a single spatial dimension to a deckbuilder — specifically one that makes movement a valued and scarce resource rather than a free action — creates a qualitatively different feel without overwhelming cognitive load. The small-numbers constraint is equally notable: precision in number design is a discipline that rewards players and reduces balancing surface area.

## Relevance to Wayfinder

- **[[Economy]]**: The "choose one treat, no currency" shop model is a precedent for mid-dungeon reward nodes in Wayfinder. Removing a currency layer from loot rooms reduces bookkeeping and focuses player attention on the choice itself rather than its price.
- **[[Affixes]]**: The crew synergy model (cards from different characters combining in the shared deck) mirrors how affix combinations on a Wayfinder chart could produce emergent builds — affixes designed in isolation that interact unexpectedly when paired.
- **[[Balance Philosophy]]**: The no-meta-progression-power-inflation rule is a direct design statement: every run should be completable on its own merits, not gated behind cumulative upgrades. Wayfinder's chart difficulty should scale with chart affixes chosen, not with hidden stat inflation from prior runs.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- Siblings: [[Slay the Spire]] · [[Inscryption]] · [[Dominion]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Cobalt_Core
- https://www.gamedeveloper.com/design/how-cobalt-core-makes-movement-as-exciting-as-fighting-in-its-roguelike-deckbuilder-combat
- https://www.pcgamer.com/deckbuilder-fans-owe-themselves-some-time-with-the-brilliant-cobalt-core/
- https://store.steampowered.com/app/2179850/Cobalt_Core/
