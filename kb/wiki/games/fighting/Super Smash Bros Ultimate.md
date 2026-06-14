---
type: game
tags: [game-study, fighting, party-fighter, platform-fighter, pvp, delay-based-netcode, roster]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Super_Smash_Bros._Ultimate
  - https://www.inverse.com/gaming/smash-ultimate-rollback-netcode-vs-delay-based
  - https://gamedev.net/forums/topic/708690-smash-bros-ultimates-netcode-doesnt-use-rollback-because-it-would-cause-too-many-side-effects/
  - https://www.eventhubs.com/news/2023/may/22/smash-bros-online-sakurai/
  - https://www.ssbwiki.com/Directional_influence
---
# Super Smash Bros Ultimate

2018 Nintendo Switch platform fighter by Sora Ltd. / Bandai Namco Studios that assembled the largest playable roster in fighting game history (89 characters with DLC) and sold 36+ million copies, making it the best-selling fighting game of all time.

## Design

- **"Everyone is here" roster:** director Masahiro Sakurai's core vision was to include every fighter from every previous Smash entry plus DLC; 74 base characters, 89 total, required resolving licensing negotiations across dozens of IP holders.
- **Percentage damage / knockback model:** unlike HP systems, damage increases a percentage meter that directly scales knockback — the further off-stage at KO, the greater the accumulated damage. Creates come-from-behind tension and legible progression within a stock.
- **Directional Influence (DI):** players hold a direction during knockback to alter launch angle and survival distance; restored from *Melee* with Legacy Smash Input (LSI) layered on top. A blue streak indicator briefly shows the corrected angle, giving visual feedback on successful DI.
- **Spirits system:** 1,300+ collectible spirits replace trophies, each granting passive stat modifiers and unlockable spirit board battles — a massive single-player content layer that coexists with competitive play.
- **Stage Morph:** players designate two stages to alternate mid-match, adding environmental variety to sets.

## Implementation

- **Engine:** rebuilt from scratch for Switch; upgraded lighting and texture rendering versus Wii U *Smash 4*; runs at 60 fps across portable and docked modes.
- **Netcode — delay-based, the key technical story:** Smash Ultimate uses **delay-based netcode**, not rollback. Sakurai explicitly acknowledged the community's rollback requests and rejected them, stating "the side effects were too big." He did not detail those side effects publicly, but the technical reason is widely understood: Smash's physics are items-rich, stage-interactive, and 4-player simultaneous — the game state per frame is far larger and more branching than a 1v1 2D fighter, making deterministic rollback and fast-forward prohibitively expensive or visually disruptive. Brawl, Smash 4, and Ultimate all share this delay-based heritage.
- **Online criticism:** the competitive community has consistently criticized lag, Wi-Fi indicator absence, and regional matchmaking. Sakurai's response emphasized user hardware (wired connection recommended) over architectural change.
- **Note:** the modding community (Project Slippi for *Melee*) demonstrated that rollback *is* achievable for Smash physics on a volunteer budget — though Melee's simpler game state makes the comparison imperfect.

## Why it matters

Ultimate is a proof that an extreme roster bet can be a franchise-defining value proposition — "everyone is here" was a marketing line that became a cultural moment. It also represents the clearest current counterexample to rollback consensus: the highest-selling fighting game in history uses delay-based netcode, and the accessible single-player (Spirits, World of Light, 1,300+ spirit battles) insulates it from the online critique. For Wayfinder, the lesson cuts both ways: a giant content roster buys enormous goodwill; poor online without alternatives destroys ranked confidence.

## Relevance to Wayfinder

- [[Combat]]: percentage-knockback is a highly legible "one verb" combat readout — damage and distance to KO compress into a single number. Wayfinder's one-verb combat design similarly needs a single clear feedback axis for the player to track their moment-to-moment combat state.
- [[Camera and Game Feel]]: DI's blue-angle indicator is a model of minimal, legible physics feedback. Wayfinder's hit-reaction system could borrow the idea of a brief trajectory indicator on heavy hits without cluttering the screen.
- [[Multiplayer Co-op]]: Smash's 4-player simultaneous state as the reason rollback is "too costly" is directly instructive for Wayfinder's co-op server architecture — more simultaneous actors and interactive physics dramatically raise the cost of client-side prediction and correction.

## See also

[[Game Index]] · [[Game Studies]] · [[MMO Netcode and Tick Systems]] · [[Design Influences]] · [[Combat]] · [[Camera and Game Feel]] · [[Multiplayer Co-op]] · [[Street Fighter II]] · [[Tekken 7]] · [[Guilty Gear Strive]] · [[Mortal Kombat 1]]

## Sources

- https://en.wikipedia.org/wiki/Super_Smash_Bros._Ultimate
- https://www.inverse.com/gaming/smash-ultimate-rollback-netcode-vs-delay-based
- https://gamedev.net/forums/topic/708690-smash-bros-ultimates-netcode-doesnt-use-rollback-because-it-would-cause-too-many-side-effects/
- https://www.eventhubs.com/news/2023/may/22/smash-bros-online-sakurai/
- https://www.ssbwiki.com/Directional_influence
