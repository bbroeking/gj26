---
type: game
tags: [game-study, strategy, turn-based-tactics, perfect-information, roguelite, puzzle, indie]
status: draft
updated: 2026-06-14
sources:
  - https://www.gamedeveloper.com/design/reimagining-failure-in-strategy-game-design-in-i-into-the-breach-i-
  - https://jeremiahgames.com/2019/03/04/perfect-information-the-killer-feature-of-slay-the-spire-and-into-the-breach/
  - https://en.wikipedia.org/wiki/Into_the_Breach
  - https://medium.com/@stiknork/design-thoughts-on-into-the-breach-9983d24ca62
---
# Into the Breach

Minimalist turn-based tactics roguelite (2018, Subset Games), fielding a squad of three mechs on 8×8 hand-designed maps against fully telegraphed enemy attacks, where civilian survival rather than mech preservation is the true victory condition.

## Design

- **Perfect information** — all enemy positions, intended attack targets, and attack patterns are revealed before the player's turn resolves. There is no fog of war during combat; every relevant fact is visible. This converts each turn into an explicit optimization puzzle rather than a guess under uncertainty.
- **Inverted loss condition** — mech destruction is not defeat. The Power Grid (capped at 7 points, one per remaining city) is the true health bar. Losing cities triggers game-over; losing mechs is a tactical setback. Players must unlearn the instinct to protect their units at all costs and instead prioritize civilian infrastructure.
- **Constrained turn structure** — each turn presents tightly scoped optimization: defend the Power Grid, earn Reputation (upgrade currency), acquire Reactor Cores (mech abilities), and preserve pilots (who accumulate XP and a persistent bonus that survives mech loss but not permanent destruction). Every resource matters.
- **Roguelite run structure** — borrowed from developer Subset Games' FTL: Faster Than Light. Islands progress in sequence; within each island, scenarios are generated procedurally from preset map templates (100 hand-designed 8×8 maps total). Island selection order gives meaningful strategic choice after the first island clears.
- **Mech healing between battles** — mechs fully restore HP between missions (within a run), encouraging aggressive play and removing the "healing tax" grind common in tactics games.
- **Pilot persistence** — pilots survive mech destruction and can be reassigned; they carry accumulated XP bonuses. Permanent pilot death (Power Grid wipe) is the meaningful character loss, not mech loss.

## Implementation

- Developed in a custom engine by a two-person studio (Justin Ma and Matthew Davis), the same duo behind FTL. The small team size constrained scope to a well-defined, tightly tuned system with zero procedural map generation—all 100 maps are hand-authored to guarantee tactical quality.
- Perfect information required building an AI that expresses all its intentions in advance: enemy units commit to an attack vector before the player acts, making the AI's decision space constrained to "choose a target" rather than "react to player moves."
- The timeline-reset mechanic (one free time rewind per run, carrying one pilot forward into a new timeline) is implemented as a full run restart with pilot state serialized and re-injected, giving failure a meaningful but non-catastrophic consequence.

## Why it matters

- Into the Breach is the definitive case study for **perfect information as a fairness contract**: when players cannot blame a hidden system, they accept losses as skill gaps rather than luck, deepening engagement with the system's mechanics.
- The inverted loss condition (protect civilians, not mechs) demonstrates how reframing the goal of a tactics game can completely change its emotional texture—from preservation anxiety to aggressive problem-solving.
- Nested puzzle granularity (per-turn micro-puzzle inside a per-run macro-puzzle) is a replicable template for roguelite design that wants to feel fair and readable rather than chaotic and dice-dependent.

## Relevance to Wayfinder

- **[[Combat]]** — telegraphed enemy attacks (clear intent display) are directly applicable to Wayfinder's dungeon encounters; showing enemy next-move indicators would make combat feel fair and skill-expressive rather than reaction-dependent.
- **[[Dungeon Generation]]** — the hand-authored-maps-within-procedural-selection model (preset room templates, procedurally assembled runs) is a strong precedent for Wayfinder's crypt generation: quality control through curation, variety through selection.
- **[[Balance Philosophy]]** — the "mechs heal between encounters, power grid does not" economy cleanly separates tactical resource (HP) from strategic resource (city health), a model for separating Wayfinder's in-dungeon health from inter-run chart-key stakes.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Balance Philosophy]] · [[Combat]] · [[Dungeon Generation]]
- [[XCOM 2]] (tactical predecessor; Firaxis; permadeath contrast) · [[Slay the Spire]] (parallel perfect-information roguelite) · [[FTL Faster Than Light]] (same developer; shared roguelite DNA)

## Sources

- https://www.gamedeveloper.com/design/reimagining-failure-in-strategy-game-design-in-i-into-the-breach-i-
- https://jeremiahgames.com/2019/03/04/perfect-information-the-killer-feature-of-slay-the-spire-and-into-the-breach/
- https://en.wikipedia.org/wiki/Into_the_Breach
