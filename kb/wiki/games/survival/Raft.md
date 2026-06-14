---
type: game
tags: [game-study, survival, crafting, co-op, ocean, base-building, resource-gathering, progression]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Raft_(video_game)
  - https://store.steampowered.com/app/648800/Raft/
  - raw/games/survival-3.md
---
# Raft

An ocean-survival co-op game (full release June 2022, Redbeet Interactive / Axolot Games) in which up to ten players begin on a 2×2 wooden platform and build an ever-expanding seafaring base by hooking debris from the ocean current before it drifts out of reach.

## Design

- **The hook as gathering verb.** Every other survival game sends players into a world to gather; Raft inverts this: the world flows past you. Players wield a throwing hook to snag barrels, wood planks, scrap, and organic matter drifting on the current, then haul them aboard before they pass. This single constraint — you cannot leave the raft early; the raft is always moving — channels all gathering through one spatial act and keeps co-op players naturally synchronized around the boat's edge.
- **Research table as recipe gate.** New crafting blueprints are not discovered by combining random items; instead, materials must be physically placed on a research table, which reveals what can be built from that material family. This front-loads discovery to the act of collecting new stuff, making each new material type feel like a key that unlocks a wing of the crafting tree.
- **Raft-as-home.** The raft is simultaneously the player's base, vehicle, and survival unit. It can be extended with additional planks, multi-storied, fitted with crop plots, animal pens (goats, chickens), a purifier for fresh water, a cookfire, and eventually engines and sails. The emotional investment is unusually high because your base is your progress — losing raft sections to the shark is loss of both shelter and crafted infrastructure.
- **Shark as pacing mechanic.** A shark permanently circles the raft and periodically attacks plank foundations. Players must craft shark bait to redirect attacks or dive with a spear to kill the shark (it respawns). This is a soft timer: ignore the shark and the raft degrades; manage the shark and you buy time to gather. It introduces light tower-defense tension without ever being a full combat game.
- **Narrative islands and radio receiver.** The world is an infinite procedurally generated ocean, but hand-authored story islands are scattered throughout. Crafting a radio receiver lets players triangulate and navigate toward these islands, each of which contains lore about the climate-catastrophe setting and new blueprint tokens. The structure is pure sandbox between islands, then authored discovery — a hybrid open-world/story pacing.
- **Co-op scaling.** Supports up to 10 players on a shared raft. Tasks naturally distribute: some hook debris, others cook, others expand the raft or defend from the shark. No formal role assignment; division of labor emerges from raft scale and momentary need.

## Implementation

- **Engine:** Unity.
- **Co-op netcode:** Listen-server (host-authority) model; up to 10 players; integrated voice chat; cross-platform play (PC and console as of December 2024). No dedicated server binary is publicly distributed.
- **World generation:** Procedural infinite ocean with seeded chunk generation for debris and island placement. Story islands are fixed authored content that appears at predetermined progression triggers.
- **Platforms:** Windows (full release Jun 2022); PS5 and Xbox Series X/S (Dec 2024).
- **Sales:** 5 million+ copies by 2024; #1 Steam bestseller for two consecutive weeks at 1.0 launch.

## Why it matters

Raft solved a quiet design problem: how do you give a survival game a home-building loop without the "walk away from your base forever" problem? By anchoring your base to a moving vehicle that you cannot leave, every crafted addition is always visible and always at stake. The research-table unlock model is one of the cleaner crafting-progression designs in the genre — it decouples "what you can build" from an abstract skill level and ties it directly to material diversity, which is what gathering should feel like it rewards. Five million copies from a two-person initial prototype suggests the core hook-and-build fantasy resonates broadly.

## Relevance to Wayfinder

- **Research-table progression** maps cleanly onto Wayfinder's [[Crafting]] unlock path: tying new recipe discovery to first encounters with new materials (ore, bark, ink) rather than spending skill points keeps gathering meaningful at every tier.
- **The raft-as-stake** concept suggests Wayfinder's town/hub should feel vulnerable or invested — things you've crafted and built should feel like things you can lose, to make [[Gathering]] and [[Crafting]] matter emotionally, not just mechanically.
- The **co-op division of labor** emerging from shared spatial tasks (not role menus) is a model for Wayfinder's [[Multiplayer Co-op]] design: give players distinct things to do on a shared stage rather than assigning classes.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[Gathering]] · [[Crafting]] · [[Economy]] · [[Multiplayer Co-op]]
- [[Minecraft]] · [[Valheim]] · [[Subnautica]] · [[Rust]]

## Sources

- https://en.wikipedia.org/wiki/Raft_(video_game)
- https://store.steampowered.com/app/648800/Raft/
- raw/games/survival-3.md
