---
type: game
tags: [game-study, sandbox, social, vr, ugc, avatar, unity, creator-economy, community]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/VRChat
  - https://wiki.vrchat.com/wiki/Special:MyLanguage/VRChat
  - https://creators.vrchat.com/getting-started/
  - https://hello.vrchat.com/
---
# VRChat

A free-to-play social VR platform (2014, VRChat Inc.) where everything — avatars, worlds, mini-games — is built by the community using Unity, creating the most technically demanding UGC sandbox in the genre.

## Design

VRChat's design bet is that **social presence, not gameplay objectives, is the product**. Players inhabit custom 3D avatars (full-body IK, lip-syncing, eye tracking, finger tracking) in player-built worlds that range from living-room hangouts to concert venues to full game experiences. There is no progression system, no currency at launch, no win state — just the quality of presence.

The standout mechanic is the **avatar upload pipeline**: any Unity project can be packaged with the VRChat SDK and uploaded as a personal or public avatar. This means the entire market of Unity-compatible rigged characters (commissioned art from Booth.pm, Gumroad, and VTuber pipelines) becomes VRChat content. The technical bar is real — only a subset of users create avatars — but the output quality is correspondingly higher than Roblox's blocky defaults.

World design follows the same pattern: Unity-native, full-fidelity, entirely user-made. Worlds include social spaces, escape rooms, rhythm games, and recreations of real locations. The community is strongly organized around subcultural identities: a trans community of 58,000+ members, a Deaf community using avatar sign-language, "Mutes" who navigate entirely through gesture.

**Creator Economy** launched May 2023: groups can offer paid subscriptions using VRChat Credits, with a 50% revenue share. An Avatar Marketplace followed in May 2025 featuring licensed IP avatars (e.g., Quill from *Moss*). Monetization is nascent compared to Roblox but growing.

## Implementation

- **Engine:** Unity (client); custom VRChat servers for instance management and voice relay.
- **Platforms:** PC (Steam, standalone), Meta Quest (December 2018), iOS/Android (October 2025).
- **Scale:** ~120,000 concurrent weekend users by 2025; peak of ~156,700 during a Sanrio concert (February 2026). New Year's Eve 2025–26 drew ~149,000 concurrent.
- **Trust system:** Users earn Trust Ranks based on time spent, friends made, and content uploaded; rank gates permissions (e.g., showing custom avatars). This is a social-reputation system rather than a power-progression system.
- **Avatar file size limits:** Maximum 200 MB compressed / 500 MB VRAM decompressed (enforced July 2024) — a performance budgeting decision notable for game developers.
- **Creator economy split:** Groups receive 50% of subscription revenue; platform retains 50%. Far less creator-favorable than Second Life (90/10) but the infrastructure (VR presence, instance hosting) is more costly.

## Why it matters

VRChat proved that **social presence alone, with zero designed gameplay, sustains a platform at scale** — and that Unity's asset ecosystem can be crowd-sourced into an effectively infinite content library. Its trust-rank social moderation system (reputational gatekeeping rather than rule enforcement alone) is one of the more sophisticated community-safety designs in the genre. The Sanrio concert peak (156,700 concurrent) demonstrates that live events in VR are a genuine venue format, not a gimmick.

## Relevance to Wayfinder

1. **[[Multiplayer Co-op]]** — VRChat's observation that presence quality (avatar fidelity, spatial audio, IK body language) drives social bonding more than game mechanics is directly relevant to Wayfinder's co-op design: the feel of being in the dungeon together matters as much as the loot loop.
2. **[[MMO Social and Endgame]]** — The subcultural community formation (trans community, Deaf community, Mutes) shows how a sandbox social platform generates tight in-groups without designed faction systems — a reference for Wayfinder's guild or community aspirations.
3. **[[Economy]]** — The 50/50 Creator Economy split, launched late (2023, nine years after the platform), shows the risks of delaying creator monetization: strong community norms form around free content first, making paid tiers harder to introduce later.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Economy]] · [[Multiplayer Co-op]] · [[MMO Social and Endgame]]
- [[Second Life]] (pioneered creator rights and virtual economy) · [[Roblox]] (UGC platform with stronger monetization) · [[Habbo Hotel]] (social-world predecessor)
- [[EVE Online]] (player-economy depth)

## Sources

- https://en.wikipedia.org/wiki/VRChat
- https://wiki.vrchat.com/wiki/Special:MyLanguage/VRChat
- https://creators.vrchat.com/getting-started/
- https://hello.vrchat.com/
