---
type: game
tags: [game-study, fighting, 3d-fighter, pvp, netcode, rage-system]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Tekken_7
  - https://www.eventhubs.com/news/2021/jun/12/tekken-rollback-netcode/
  - https://www.oneesports.gg/tekken/katsuhiro-harada-claims-tekken-7-already-has-rollback-netcode/
  - https://www.resetera.com/threads/the-biggest-lie-in-gaming-this-year-tekken-7s-rollback-frames-counter.623008/
---
# Tekken 7

2015 (arcade) / 2017 (console/PC) 3D fighting game by Bandai Namco that concluded the Mishima saga, sold over 12 million copies, and ignited the community's most contentious netcode debate in the genre.

## Design

- **Rage System:** when health falls below roughly 25%, players enter Rage mode unlocking a character-specific Rage Art (cinematic, ~30% damage) or lower-risk Rage Drive variants — a deliberate comeback mechanic that compresses the skill gap in close games.
- **Screw Attack:** replaced Tekken 6's Ground Bound with a tailspin that floats opponents for extended air combos without requiring a wall — reshaping combo routing across the entire roster.
- **Power Crush:** high/mid-absorbing armor moves that continue executing through incoming hits, rewarding aggression and adding a third defensive layer beyond sidestepping and blocking.
- **51-character roster (Season 4):** four guest fighters (Geese Howard, Noctis, Negan, Lidia) broadened franchise reach; deep character-specific execution walls maintained the series' skill-ceiling identity.
- **EVO presence:** Tekken 7 anchored the EVO main stage for multiple years, cementing 3D fighters' place in the tournament canon alongside 2D heavyweights.

## Implementation

- **Engine:** Unreal Engine 4 — a first for the series, enabling multi-platform parity and dramatically upgraded visual fidelity.
- **Netcode — the key technical story:** Bandai Namco and producer Katsuhiro Harada have long claimed Tekken 7 uses "3-frame rollback netcode since launch." The community broadly disputes this. In practice, the game uses a **variable input buffer of 0–5 frames** that adjusts to connection quality, functioning identically to delay-based netcode from the player's perspective: matches slow down under packet loss rather than rolling back and correcting.
- **Why 3D makes rollback harder:** Harada's explanation is technically credible — 3D fighters use smooth continuous animations from input to completion, so a visual rollback (snapping a character back a few frames) appears far more jarring than in 2D games whose longer startup animations naturally hide the correction window. Memory and CPU constraints on PS4/Xbox One further capped rollback budget.
- **Arika's Season 4 patch** (2023) improved latency consistency but did not overhaul the architecture.

## Why it matters

Tekken 7's netcode controversy is the single clearest case study in the tension between **3D animation fidelity and rollback correctability**. It forced the entire FGC to articulate the technical difference between rollback architecture and delay-based architecture — and why they feel different even when labelled the same. Its commercial success (12M+ units) proves that a subpar online experience does not kill a franchise with strong offline and competitive identity, but it does cap the accessible online player base.

## Relevance to Wayfinder

- [[MMO Netcode and Tick Systems]]: the 3D animation / rollback tradeoff is directly applicable to Wayfinder's dungeon combat — smooth character animations will resist state rollback; tick-based server authority (rather than client-side prediction) may be the cleaner path for a co-op game.
- [[Combat]]: Tekken's Rage mechanic is a legible comeback tool with clear visual feedback — a pattern worth studying for Wayfinder boss fights where a losing player needs a moment to re-engage.
- [[Multiplayer Co-op]]: Tekken's dedicated competitive infrastructure (Tekken World Tour) shows how tournament scaffolding can sustain a game for years; Wayfinder's social loop is co-op not PvP, but league/seasonal structure lessons transfer.

## See also

[[Game Index]] · [[Game Studies]] · [[MMO Netcode and Tick Systems]] · [[Design Influences]] · [[Combat]] · [[Multiplayer Co-op]] · [[Street Fighter II]] · [[Guilty Gear Strive]] · [[Mortal Kombat 1]] · [[Super Smash Bros Ultimate]]

## Sources

- https://en.wikipedia.org/wiki/Tekken_7
- https://www.eventhubs.com/news/2021/jun/12/tekken-rollback-netcode/
- https://www.oneesports.gg/tekken/katsuhiro-harada-claims-tekken-7-already-has-rollback-netcode/
- https://www.resetera.com/threads/the-biggest-lie-in-gaming-this-year-tekken-7s-rollback-frames-counter.623008/
