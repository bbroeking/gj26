---
type: game
tags: [game-study, roguelite, action-roguelike, boon-system, meta-progression, crafting, gathering, narrative-roguelite, supergiant]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Hades_II
  - https://www.gamespot.com/articles/hades-2-everything-we-know-about-supergiants-upcoming-roguelite/1100-6520218/
  - https://www.pcgamesn.com/hades-2/arcana-cards
  - https://www.thegamer.com/hades-2-arcana-cards-upgrades-unlock-cost-activate/
  - https://wolfsgamingblog.com/2026/05/06/hades-2-review-god-tier-roguelike-action/
---
# Hades II

A roguelite action RPG (2025 full release, Supergiant Games) and sequel to [[Hades]], in which Melinoe — witch daughter of Persephone — battles through a remapped underworld and surface world, driven by expanded systems including Arcana cards, in-run resource gathering, cauldron crafting, and a new Hex magic layer, all wrapped in the same narrative-saturation approach that defined the original.

## Design

- **Dual run paths:** Unlike [[Hades]]'s single descent, Hades II offers two route directions: downward into the underworld (toward Chronos) and upward through the surface world (toward Olympus). Each path has distinct biomes, bosses, and boon pools, effectively doubling run variety and requiring separate build optimization.
- **Arcana card system — meta-build layer:** Between runs, players spend Ashes at the Altar of Ashes to unlock 27 Arcana Cards — passive abilities equippable to Melinoe at run start. Equipping cards costs Grasp (a soft cap on simultaneous active cards, expandable with Psyche). Cards range from simple stat boosts to rule-changers (extra boon choices, altered enemy behavior, new resource drops). This is the permanent build layer that spans runs, analogous to the Mirror of Night in [[Hades]].
- **Boon system (retained and expanded):** Olympian gods offer run-time boons providing three-way branching effects per chamber. Duo boons — requiring boons from two specific gods — are retained and expanded. Supergiant's core insight from [[Hades]] is preserved: the combination of permanent Arcana passives + run-time boon drafting creates a two-axis build space that feels both authored and emergent.
- **Hex system — goddess Selene:** Melinoe's "cast" slot is occupied by a Hex: a Selene-granted summon/special attack powered by a Magick meter (replenished by attacking). Hexes have skill-tree upgrades unlocked through run performance, adding a third character-specific progression axis alongside Arcana and boons.
- **In-run resource gathering and cauldron crafting:** Players gather materials during runs (herbs, minerals, enemy drops) and use a Cauldron at the Crossroads hub to craft incantations. Incantations unlock new run features, tools (e.g., a Silver Spade to dig up plants), and upgrade paths. This is a significant structural departure from [[Hades]]: a skilling/crafting loop nested inside the meta-progression layer.
- **Fear difficulty system:** An opt-in escalating difficulty layer that adds modifiers to runs in exchange for rare resource drops. Analogous to [[Hades]]'s Heat system but tied directly to resource economy rather than pure challenge.
- **Familiars:** Small creatures discovered on runs can be brought along as companions, providing passive benefits. A light pet system that adds collection incentive without heavy systems overhead.

## Implementation

- **Engine:** Custom Supergiant engine (same as [[Hades]]); all previous Supergiant games use their proprietary C++ framework. The engine handles the dense particle effects and reactive dialogue triggers that define the studio's feel.
- **Narrative saturation approach:** Every chamber traversal can trigger voiced dialogue, god commentary, or NPC relationship advances. The game maintains a queue of contextual comments so that repeated runs surface new lines for months. This approach requires authoring thousands of lines of conditional dialogue but eliminates the "dead-silent dungeon" problem.
- **Dual-path procgen:** Each run path is a separate procedurally sequenced room chain with typed chambers (combat, merchant, fountain, special encounter). Room type sequences are weighted per region, ensuring pacing. The two paths share a boon pool but have distinct enemy rosters and room art sets.

## Why it matters

- Hades II is the most fully realized example of **narrative-saturated roguelite**: a game where story progression, character relationship advancement, and mechanical progression are entirely co-scheduled. No session feels narratively inert.
- The **Arcana + boon two-axis build** is the current state of the art for permanent/run-time progression layering in the genre — the Arcana layer gives each run a starting identity while boon drafting provides adaptive specialization.
- The addition of **in-run gathering feeding hub crafting** is a direct bridge to the cozy-skilling genre: Hades II is the first AAA-adjacent roguelite where you stop to dig up herbs with a spade. This validates Wayfinder's core loop at a high-profile level.
- Metacritic: 94/100 (PC), 98/100 (Switch).

## Relevance to Wayfinder

- **[[Chart Loop]]:** The expedition→Crossroads hub→craft incantation→expedition loop in Hades II is the closest structural analog to Wayfinder's chart-run→town→gather/craft→chart-run loop. The key lesson: the hub must have active verbs (craft, plant, upgrade) not just passive currency sinks.
- **[[Dungeon Generation]]:** Hades II's typed-chamber procgen with region-specific enemy rosters is directly applicable to Wayfinder's crypt-tier architecture. The two-path structure suggests Wayfinder could use chart affixes to route players through differentiated sub-biomes of the same dungeon.
- **[[Affixes]]:** The Arcana card system — a finite set of persistent build choices made from a pool before each run — is a high-fidelity model for how chart affixes should feel at the run-start selection screen.
- **[[Items and Gear]]:** The gathering-crafting-incantation chain in Hades II is a proof point that players in action roguelites will engage with resource loops if the crafting output is mechanically meaningful (unlocking run features, not just buffing stats).
- **[[Combat]]:** The Magick bar that recharges through attacking (replenishing the Hex resource) is a clean one-verb combat resource model — attacking both deals damage and funds your special. Wayfinder's one-verb combat should consider a similar self-sustaining resource design.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Hades]] (direct predecessor — link for sequel context) · [[Darkest Dungeon]] (gothic roguelite comparison)
- [[Slay the Spire]] (boon-drafting parallel) · [[The Binding of Isaac Rebirth]] (narrative-free action roguelite contrast)
- [[Chart Loop]] · [[Dungeon Generation]] · [[Affixes]] · [[Items and Gear]] · [[Combat]]

## Sources

- https://en.wikipedia.org/wiki/Hades_II
- https://www.gamespot.com/articles/hades-2-everything-we-know-about-supergiants-upcoming-roguelite/1100-6520218/
- https://www.pcgamesn.com/hades-2/arcana-cards
- https://www.thegamer.com/hades-2-arcana-cards-upgrades-unlock-cost-activate/
- https://wolfsgamingblog.com/2026/05/06/hades-2-review-god-tier-roguelike-action/
