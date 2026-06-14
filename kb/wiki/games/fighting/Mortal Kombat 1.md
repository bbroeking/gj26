---
type: game
tags: [game-study, fighting, pvp, rollback-netcode, kameo-system, seasonal-content, story-mode]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Mortal_Kombat_1
  - https://twistedvoxel.com/mortal-kombat-1-unreal-engine-4-kameos-not-playable/
  - https://www.eventhubs.com/news/2023/jun/28/mk1-stress-test-tech-breakdown/
  - https://www.theloadout.com/mortal-kombat-1/rollback-netcode
  - https://www.psu.com/news/mortal-kombat-1-ps5-rollback-netcode-confirmed/
---
# Mortal Kombat 1

2023 fighting game by NetherRealm Studios — a full timeline reboot that introduced the Kameo assist system, shipped rollback netcode on all platforms (except Switch at launch), and layered a seasonal RPG-boardgame hybrid (Invasions) over the traditional single-player mode.

## Design

- **Kameo Fighter system:** players choose a main fighter plus a separate Kameo character (15 base, non-playable in standard matches) who provides on-demand assist attacks. Kameos are tied to story lore — the roster reflects who Liu Kang recruited in his new timeline — and add a team-composition layer without full tag-team complexity.
- **Invasions mode:** a seasonal single-player/co-op experience built on an interactive world-map where players traverse realms, complete combat challenges, and earn cosmetic rewards (skins, concept art, currency). Seasons rotate every six weeks with new themes and narrative context — a live-service retention loop grafted onto a fighting game.
- **Timeline reboot narrative:** MK1 is the franchise's second full reboot (after MK9), set in Liu Kang's reconstructed reality. The cinematic story mode — a NetherRealm signature since MK9 — returned with high production values and DC Comics guest fighters in DLC.
- **22-character base roster:** deliberately curated versus prior MK titles; expanded via DLC packs including fighters from The Boys, DC Comics, and other franchises.

## Implementation

- **Engine:** NetherRealm shifted from their long-running custom Unreal Engine 3 fork (used through MK11) to a **heavily customized Unreal Engine 4**, requiring the team to rethink integration across their proprietary fighting-game systems. Digital Foundry's stress-test breakdown confirmed the UE4 base with bespoke rendering adaptations.
- **Rollback netcode — the key technical story:** MK1 shipped with **rollback netcode on PS5, Xbox Series X|S, and PC** at launch — a direct response to community pressure following the FGC's post-Strive expectations. This represented a significant architectural departure from MK11, which used delay-based netcode. The Nintendo Switch version launched without rollback due to hardware constraints and faced substantial criticism for degraded online performance.
- **Platform parity gap:** the Switch's absent rollback at launch highlighted that rollback is not universally achievable across hardware generations, a constraint directly relevant to any multi-platform online game.

## Why it matters

MK1 shows the live-service model applied to a premium fighting game: Invasions' six-week seasonal rotation creates recurring reasons to log in beyond ranked matches, transforming what is normally a one-time purchase into an ongoing content platform. The Kameo system is also a notable design bet — adding a second character slot without full tag complexity lowers the cognitive bar while raising strategic depth. The rollback commitment signals that the major fighting game studios now treat rollback as the minimum acceptable standard for new releases post-Strive.

## Relevance to Wayfinder

- [[Multiplayer Co-op]]: Invasions' seasonal board-game co-op layer is thematically close to Wayfinder's chart-loop concept — a procedurally shaped seasonal "realm" you traverse with varied challenges before a culminating boss. The six-week cadence and cosmetic reward structure are concrete references for Wayfinder's seasonal design.
- [[Combat]]: the Kameo assist system separates "main fighter identity" from "tactical option selection" — a possible model for Wayfinder's party composition, where each character has a primary verb but can call on a support skill from a second-slot choice (analogous to a Craft trade or an ally ability).
- [[MMO Netcode and Tick Systems]]: the Switch rollback absence is a live case study in what happens when rollback is scoped per platform — Wayfinder should decide early whether co-op sync architecture needs a hardware floor or a graceful degradation path.

## See also

[[Game Index]] · [[Game Studies]] · [[MMO Netcode and Tick Systems]] · [[Design Influences]] · [[Combat]] · [[Multiplayer Co-op]] · [[Camera and Game Feel]] · [[Street Fighter II]] · [[Tekken 7]] · [[Guilty Gear Strive]] · [[Super Smash Bros Ultimate]]

## Sources

- https://en.wikipedia.org/wiki/Mortal_Kombat_1
- https://twistedvoxel.com/mortal-kombat-1-unreal-engine-4-kameos-not-playable/
- https://www.eventhubs.com/news/2023/jun/28/mk1-stress-test-tech-breakdown/
- https://www.theloadout.com/mortal-kombat-1/rollback-netcode
- https://www.psu.com/news/mortal-kombat-1-ps5-rollback-netcode-confirmed/
