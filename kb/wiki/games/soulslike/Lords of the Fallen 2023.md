---
type: game
tags: [game-study, soulslike, action-rpg, dual-world, umbral, unreal-engine-5, co-op, checkpoint-design]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Lords_of_the_Fallen_(2023_video_game)
  - https://www.gamedeveloper.com/design/creating-_lords-of-the-fallen-s_-parallel-world-of-umbral
  - https://fextralife.com/lords-of-the-fallen-duals-worlds-look-double-the-fun/
  - https://www.shacknews.com/article/137359/lords-of-the-fallen-review-score
---
# Lords of the Fallen 2023

Action-RPG (2023, Hexworks/CI Games) — a soulslike distinguished by a simultaneously rendered dual-world system in which death transitions players to the Umbral realm of the dead rather than a loading screen, making the death state itself a traversal and puzzle mechanic.

## Design

- **Axiom / Umbral dual-world system.** The game world exists as two concurrent layers: Axiom (realm of the living) and Umbral (realm of the dead). Players carry an Umbral Lamp that allows peeking into the Umbral layer while remaining in Axiom — revealing hidden bridges, enemies, and loot invisible in the living world. On death, instead of respawning at a checkpoint, the player enters Umbral fully. Umbral is more hostile (enemy density increases over time via "Umbral parasites"), but also opens new traversal paths unavailable in Axiom.
- **Intentional vulnerability in Umbral.** Unlike Dark Souls' hollow/human split (mostly a penalty), Umbral is sometimes mandatory: certain puzzle paths and required items exist only there. Players cannot escape Umbral by dying again — they must find an "Emergency Effigy" (consumable) or reach a Vestige (checkpoint). This turns the death-state into an active gameplay zone rather than a punishment screen.
- **Soulflay mechanic.** Using the Umbral Lamp, players can grab and throw Umbral enemies and objects across the world boundary into Axiom — solving environmental puzzles and destroying enemy armor from a distance.
- **Vestiges (craftable checkpoints).** Players can place Vestige Seeds at fixed anchor points to create their own save-and-respawn nodes, rather than relying solely on pre-placed Vestiges. This gives players limited agency over checkpoint spacing.
- **Co-op throughout.** The campaign supports co-op play. A major "version 2.0" post-launch update (April 2025) improved co-op features and difficulty tuning after mixed reception at launch.
- **Performance at launch.** The dual-world simultaneous rendering was technically ambitious; the UE5 launch version had frame-rate issues and optimization complaints, partly resolved through post-launch patches.

## Implementation

- Engine: Unreal Engine 5 (with Nanite and Lumen); team migrated from UE4 mid-development — described by studio head Saul Gascon as "a blessing" for visual fidelity but requiring a next-gen-only release.
- Developer: Hexworks (subsidiary of CI Games, formed 2020 specifically to build this title).
- Budget: $66.2 million.
- Release: October 13, 2023 (PS5, Xbox Series X/S, Windows).
- Metacritic: 75/100 (PC, "generally favorable"), 70/100 (PS5, "mixed/average").
- Sales: 1 million units in 10 days; 2.5 million by March 2026; 4 million players (including Game Pass) by January 2025.
- Sequel: Lords of the Fallen II announced for 2026, with "Umbral 2.0" addressing criticism that the mechanic felt "too static."

## Why it matters

Lords of the Fallen 2023 is the most ambitious structural mutation of the soulslike death mechanic yet shipped. Rather than treating death as a reset-to-checkpoint event, it integrates the death state into a second traversal layer that changes spatial geometry. The Vestiges crafting system is also a meaningful evolution of checkpoint design: giving players limited control over checkpoint placement introduces a resource-management layer (do I spend a Vestige Seed here or push further?) that traditional fixed-checkpoint soulslikes lack. The UE5 technical story — simultaneous dual-world rendering — is a notable case study in next-gen engine ambition meeting launch-day optimization debt.

## Relevance to Wayfinder

- **Dual-state after failure.** The Umbral death-as-traversal-layer concept is an extreme version of what Wayfinder's chart system gestures at: failure opens a different state of the dungeon rather than simply resetting it. A "ghosted" or darkened version of the dungeon could reveal loot or paths unavailable to the living party. See [[Combat]], [[Bosses]].
- **Craftable checkpoints = resource dial.** Vestige Seeds turn checkpoint placement into a consumable economy — directly analogous to Wayfinder's chart preparation loop. Spending resources to set a respawn anchor in a dangerous area is a meaningful risk-reward choice. See [[Items and Gear]].
- **Umbral parasites as timer pressure.** The increasing Umbral enemy density over time in the death-state creates a soft timer: stay in Umbral longer and the situation worsens. Wayfinder could borrow this for any "downed" or "ghosted" mechanic — the longer you stay down, the harder recovery becomes. See [[Combat]], [[Camera and Game Feel]].

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Dark Souls]] · [[Elden Ring]] · [[Dark Souls III]] · [[Mortal Shell]]
- [[Combat]] · [[Bosses]] · [[Camera and Game Feel]] · [[Multiplayer Co-op]] · [[Items and Gear]]

## Sources

- https://en.wikipedia.org/wiki/Lords_of_the_Fallen_(2023_video_game)
- https://www.gamedeveloper.com/design/creating-_lords-of-the-fallen-s_-parallel-world-of-umbral
- https://fextralife.com/lords-of-the-fallen-duals-worlds-look-double-the-fun/
- https://www.shacknews.com/article/137359/lords-of-the-fallen-review-score
