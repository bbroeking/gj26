---
type: game
tags: [game-study, rpg, crpg, larian, dnd5e, co-op, narrative, turn-based, adaptation]
status: draft
updated: 2026-06-14
sources:
  - https://therpggazette.wordpress.com/2025/06/27/rolling-virtual-dice-transmedial-adaptation-of-dd-5e-in-baldurs-gate-3/
  - https://gamerant.com/baldurs-gate-3-dungeons-dragons-5e-different-same/
  - https://deltiasgaming.com/baldurs-gate-3-reactions-explained/
  - https://en.wikipedia.org/wiki/Baldur's_Gate_3
---
# Baldurs Gate 3

Turn-based CRPG (2023, Larian Studios) — a faithful-yet-adapted implementation of D&D 5th Edition rules set in the Forgotten Realms, widely hailed as the definitive digital tabletop experience; won Game of the Year at The Game Awards 2023, BAFTA, and Golden Joystick, selling 20 million+ copies.

## Design

- **D&D 5e transmedial adaptation.** BG3 does not replicate the tabletop rules literally — it adapts them for a solo/co-op video game. The underlying math (d20 rolls, ability score modifiers, proficiency bonuses, advantage/disadvantage) is made *visible* to the player through animated dice and explicit probability displays, which translates the tactile joy of rolling dice into a digital medium. Optional 5e rules (flexible ability score placement, generous multiclassing) are implemented as defaults, prioritizing player agency over mechanical gatekeeping.
- **Reaction system.** D&D 5e defines a "reaction" as a special action triggered by an external event (e.g. Opportunity Attack when an enemy leaves melee range; Counterspell when an enemy casts a spell). BG3 implements reactions with a toggle UI: each reaction can be set to Auto (fires automatically), Ask (interrupts play for a yes/no prompt), or Off. This solves a hard digital design problem — in tabletop play the human DM calls for reactions in real time, but in a video game all potential triggers fire simultaneously, so the Ask mode is the closest equivalent to the tabletop's collaborative moment. The finite-resource constraint (one reaction per round per character) makes every Ask a meaningful tactical micro-decision.
- **Co-op narrative.** Up to four players can each control a party member through the full campaign in online co-op, with split-screen available for couch co-op. The game tracks each player's quest journal independently and allows divergent moral choices — two players can have opposed dialogue outcomes within the same session. This creates emergent "table drama" that mirrors the social tension of a real D&D group. Origin characters (pre-written with voiced inner monologue) give each party member a personal stake even when played by a co-op participant.
- **DM function automated.** With no human DM, perception checks, trap detection, and difficulty class adjudication are automated. The narrator (voiced) fills the DM's descriptive role. The trade-off: the world cannot respond to player backstories as fluidly as a human DM would, and "impossible" player actions have no human to arbitrate them. The game's branching scripts compensate with enormous conditional dialogue trees — reputedly some of the largest ever written.
- **Reaction to player choice.** BG3 is noted for taking player decisions further than prior CRPGs: companions can permanently leave or die based on choices; entire quest branches vanish based on Act 1 decisions; the game supports "evil" playthroughs where conventional NPCs become enemies. The illusion of a living, reacting world is the design goal, even where the scripting is deterministic.

## Implementation

- **Larian's Divinity Engine** (the studio's proprietary engine, internally versioned; built on the DOS2 foundation) handles the large explorable spaces, real-time 3D environments, and physics-driven environmental interactions (the surface/elemental interaction heritage from [[Divinity Original Sin 2]] remains visible in BG3's barrel-physics and terrain effects).
- **Early Access model.** BG3 launched in Early Access in October 2020, three years before the v1.0 release in August 2023. Larian used player feedback at scale to tune encounter difficulty, balance classes, and refine the reaction UI. This is an unusual development strategy for a narrative game: typically story spoilers make Early Access risky, but Larian shipped only Act 1 in EA, protecting the full arc.
- **Sales & awards.** 20 million+ copies as of late 2025; 7 awards at The Game Awards 2023 including GOTY; BAFTA Game of the Year 2024. At peak had over 800,000 concurrent players on Steam (record for a CRPG).

## Why it matters

BG3 proved that **faithful ruleset adaptation + co-op narrative coherence** is achievable at AAA scale, and that the digital reaction/interrupt system is solvable via player-controlled toggle UI rather than automation. It also demonstrated that an Early Access model can fund and improve a narrative game if the shipped slice is genuinely complete. The game reset expectations for CRPG scope and production quality.

## Relevance to Wayfinder

- **[[Multiplayer Co-op]]:** BG3's co-op model — shared world, independent quest journals, divergent moral choices within a session — is the closest AAA reference for Wayfinder's 2–4-player co-op design. The key lesson: give each co-op player a personal stake (origin character or Trade-specific quest) so the group doesn't flatten into a single story.
- **[[Combat]]:** The reaction/interrupt system (Ask vs. Auto toggle) is directly applicable to Wayfinder's combat timing design. Rather than a twitch-based or fully automatic interrupt, a "respond?" prompt keeps combat deliberate without requiring real-time reflexes — fitting Wayfinder's cozy register.
- **[[Trades and Leveling]]:** The 5e class/subclass selection at level-up is a reference for Wayfinder's Trade milestone moments — each milestone should feel like a meaningful identity branch, not just a stat increment.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[Multiplayer Co-op]] · [[MMO Lessons for Wayfinder]]
- Wayfinder: [[Combat]] · [[Multiplayer Co-op]] · [[Trades and Leveling]] · [[Skills]] · [[Items and Gear]]
- Siblings: [[The Elder Scrolls V Skyrim]] · [[The Witcher 3 Wild Hunt]] · [[Disco Elysium]] · [[Divinity Original Sin 2]]

## Sources

- https://therpggazette.wordpress.com/2025/06/27/rolling-virtual-dice-transmedial-adaptation-of-dd-5e-in-baldurs-gate-3/
- https://gamerant.com/baldurs-gate-3-dungeons-dragons-5e-different-same/
- https://deltiasgaming.com/baldurs-gate-3-reactions-explained/
- https://en.wikipedia.org/wiki/Baldur%27s_Gate_3
- https://gam3s.gg/baldur-s-gate-3/review/
