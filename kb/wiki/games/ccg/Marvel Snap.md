---
type: game
tags: [game-study, ccg, digital-card-game, monetization, location-design, snap-mechanic, second-dinner]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Marvel_Snap
  - https://www.gamedeveloper.com/design/why-second-dinner-first-prototyped-marvel-snap-using-physical-cards
  - https://mobilegamer.biz/second-dinner-reveals-the-secrets-of-marvel-snaps-onboarding-and-card-design/
  - https://www.gameshub.com/news/features/marvel-snap-designer-interview-kent-erik-hagman-smart-card-game-design-31692/
---

# Marvel Snap

Digital CCG (2022, Second Dinner) — the radical simplification of the collectible card game — 12-card decks, 6-turn matches, three randomly revealed locations, and a poker-style escalation mechanic that makes every match feel like a negotiation as well as a game.

## Design

- **12-card decks, 6 turns**: Matches last a maximum of 6 turns; each player's deck is exactly 12 cards with no duplicates allowed. The constraint forces every card to matter, enables fast (~3-minute) sessions, and lets players understand the opponent's likely hand state.
- **Three random locations**: Each match assigns three locations, revealed one per turn during turns 1–3. Locations have unique effects (e.g., "cards here have +3 power," "cards can't be played here until turn 5"). The win condition is majority control — winning two of three by total power. Location randomization is the primary replayability engine, generating enormous variety without card pool expansion.
- **Snap and retreat**: Either player can "snap" at any point, doubling the cube stakes. The opponent can then retreat (losing only the current cube value) or accept. If both snap, the cube doubles twice. This creates a bluffing/commitment meta-game layered on top of the card game — skilled players snap when they project a win even if not guaranteed, to pressure opponents into retreating.
- **Collection level progression**: Base card acquisition is tied to collection level (XP-gated progression through card pools 1–5). Cards are unlocked somewhat randomly within pools as players level up, then cosmetic variants (card "borders," animations, alternate art) are purchased separately.
- **Season Pass**: Monthly season pass ($9.99) provides one premium card per season plus cosmetics. The premium card is not pay-to-win-exclusive long-term (it enters the regular pool after the season), but early access is gated by purchase.
- **Ability text discipline**: Cards use minimal text — abilities described in one short sentence. The physical-card prototyping origin enforced this (writing on business cards). Visual effects reinforce ability meaning. This is a deliberate counter-design to Magic's novel-length card text.
- **Top-down and bottom-up card design**: Marvel IP provides top-down hooks (Spider-Man webs a location, Wolverine regenerates power). Bottom-up asks what the game needs mechanically. Most cards blend both, letting IP knowledge be a learning assist.

## Implementation

- Built on **Unity**; launched on Android and iOS October 18, 2022; full Windows release August 23, 2023.
- Originally published by Nuverse (ByteDance subsidiary); transitioned to Skystone Games (January 2025) following ByteDance's US regulatory pressures.
- 22 million downloads and over $200 million in cumulative revenue by 2024.
- Server-authoritative with deterministic location seeding — the same location set is shared between both players' clients from match start, reducing sync surface area.
- Physical prototype origin (writing on business cards) enforced ability conciseness before any engineering was invested, a useful design process lesson.

## Why it matters

- Proved that radical constraint (12 cards, 6 turns) is a feature not a limitation: faster matches increase session count, 12-card decks lower the barrier to deck-building experimentation, and the constraint generates its own strategic depth through location adaptation.
- The snap/retreat mechanic is a uniquely elegant solution to the "losing is unfun" problem. Players can always exit at minimal cost, turning a certain loss into a measured retreat rather than a slow grind-out. This reduces frustration without reducing stakes for the winner.
- Location design as a variety engine is a transferable pattern: instead of requiring massive card pools for replayability, generate variety at the environment layer. 200+ locations create billions of possible match configurations even with a fixed 12-card deck.

## Relevance to Wayfinder

- **[[Affixes]]**: Marvel Snap's location system is the closest existing analogue to Wayfinder's dungeon affix model. Locations are parameterized rule-modifiers applied to a shared space — exactly what chart affixes do to a dungeon run. The lesson: 50–100 well-designed location/affix rules create combinatorial variety without requiring proportional content creation.
- **[[Economy]]**: The collection-level XP gating for base cards (not pay-walled, just time-gated) is a model for how Wayfinder could release charts or affix unlocks: freely acquired through play progression, with cosmetics (card borders → [[Inks]], animated art → visual chart embellishments) as the premium layer.
- **[[Balance Philosophy]]**: Ability text discipline — one clear sentence per card — is directly applicable to Wayfinder's chart affixes and skill descriptions. If an affix needs two sentences, it is probably two affixes.

## See also

- [[Game Index]] · [[Game Studies]] · [[MMO Economy and Itemization]] · [[Design Influences]]
- Siblings: [[Hearthstone]] · [[Magic The Gathering Arena]] · [[Legends of Runeterra]] · [[Teamfight Tactics]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]] · [[Inks]]

## Sources

- https://en.wikipedia.org/wiki/Marvel_Snap
- https://www.gamedeveloper.com/design/why-second-dinner-first-prototyped-marvel-snap-using-physical-cards
- https://mobilegamer.biz/second-dinner-reveals-the-secrets-of-marvel-snaps-onboarding-and-card-design/
- https://www.gameshub.com/news/features/marvel-snap-designer-interview-kent-erik-hagman-smart-card-game-design-31692/
