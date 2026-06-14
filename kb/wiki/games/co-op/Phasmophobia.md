---
type: game
tags: [game-study, co-op, horror, investigation, social, evidence-system, pve]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Phasmophobia_(video_game)
  - https://driffle.com/blog/phasmophobia-review-a-deep-dive-into-ghost-hunting-horror/
  - https://phasmophobia.fandom.com/wiki/Evidence
  - https://soren.com/en/news/phasmophobia/2026-01-31-phasmophobia-2026-roadmap-the-path-to-version-10
  - https://www.co-optimus.com/game/7473/pc/phasmophobia.html
---
# Phasmophobia

Co-op horror investigation game (Early Access September 2020, Kinetic Games) where 1–4 ghost hunters enter haunted locations, gather evidence using paranormal equipment, identify the ghost type, and escape before a hunt kills them.

## Design

Phasmophobia's co-op loop is built on **information asymmetry and division of labor without hard role assignment**. There are no locked classes; instead, the shared equipment kit — EMF Reader, Thermometer, Spirit Box, UV light, Ghost Writing Book, DOTS Projector, video cameras — naturally distributes tasks across the team. One player monitors CCTV feeds from the safety of the van while others enter the building. Someone operates the Spirit Box (which requires speaking aloud and listening for responses via the game's voice recognition engine); someone else hunts for fingerprints with UV. The ghost hears players through their actual microphones, creating genuine tension in how teammates communicate — shouting "over here" can draw a hunt.

There are 27 ghost types, each with a fixed three-piece evidence combination drawn from seven possible evidence types (EMF Level 5, Ghost Orb, Freezing Temperatures, Ghost Writing, Spirit Box, UV fingerprints, DOTS silhouette). On standard difficulty players collect three pieces to narrow identification; Nightmare difficulty hides one piece; Insanity hides two. The **sanity mechanic** connects individual and team states: low sanity triggers hunts and ghost activity; the team starts a run collectively and sanity drops independently, so a player who lingers too long indoors makes the environment more dangerous for everyone.

Session structure: players choose a contract (location + optional secondary objectives), purchase and load equipment in the van, investigate, record findings in the in-game journal, then submit a ghost identification guess on return. Death means losing all equipment carried — creating an economic risk/reward decision about how much gear to bring vs. how much to risk.

Standout mechanic: **voice-recognition ghost interaction**. Saying a ghost's given name, asking questions through the Spirit Box, or even idle conversation can provoke reactions. This is not a UI system — it is the game engine listening to the player's real microphone, making silence itself a cooperative tool.

## Implementation

Developed by a solo UK developer (Kinetic Games, Southampton) in **Unity**. Sessions use a **host-authoritative peer-to-peer model**: one player hosts and others connect; host machine quality affects session stability. The game launched September 2020 in Early Access; console versions (PS5, Xbox Series X/S) followed October 2024; Nintendo Switch 2 support announced for 2026. As of the 2026 public roadmap, Kinetic Games is undertaking a full **Unity 6 migration and netcode rewrite** — the existing netcode is widely cited by the community as a source of ghost desyncs and laggy hunt sequences. The upgrade promises dedicated relay infrastructure and more stable host-client latency. Player count is 1–4 per lobby; no public dedicated servers currently exist.

## Why it matters

Phasmophobia demonstrated that **a solo indie developer with a $0 marketing budget could reach 100,000 concurrent Steam players** on the strength of streaming culture and emergent co-op comedy. The horror genre's co-op tension — one player in danger while others watch remotely — is a content-creation machine. The evidence-identification loop is a masterclass in **observable progress within a short session**: players always know roughly how far they are from an answer, but the ghost can kill them before they get there.

## Relevance to Wayfinder

- **Asymmetric information co-op without hard roles.** Phasmophobia's van-vs-interior split is a spatial role system: some players take risk, others manage information. Wayfinder could model this in dungeon runs — a Wildcrafter scouting ahead while a Wayfinder reads chart affixes from a safe anchor point — as a natural expression of Trades rather than a locked mechanic. See [[Multiplayer Co-op]].
- **Death with economic stakes, not permadeath.** Losing carried equipment on death creates session-level risk without resetting all progress. This is a finer-grained model than full permadeath and worth considering for [[Bosses]] and [[Combat]] in chart runs.
- **Voice and ambient tools as co-op glue.** The real-microphone ghost interaction is obviously out of scope for Wayfinder, but the principle — cooperative tools that require coordination to use correctly, and that produce failure if misused — applies to co-op skill use and dungeon interactables.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Bosses]]
- [[Design Influences]] · [[Deep Rock Galactic]] · [[Helldivers 2]]
- [[MMO Netcode and Tick Systems]]

## Sources

- https://en.wikipedia.org/wiki/Phasmophobia_(video_game)
- https://driffle.com/blog/phasmophobia-review-a-deep-dive-into-ghost-hunting-horror/
- https://phasmophobia.fandom.com/wiki/Evidence
- https://soren.com/en/news/phasmophobia/2026-01-31-phasmophobia-2026-roadmap-the-path-to-version-10
- https://www.co-optimus.com/game/7473/pc/phasmophobia.html
