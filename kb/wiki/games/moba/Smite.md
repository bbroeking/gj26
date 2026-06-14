---
type: game
tags: [game-study, moba, third-person, action, hi-rez, unreal-engine, mythology]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Smite_(video_game)
  - https://smite.fandom.com/wiki/Hi-Rez_Studios
  - https://www.gameleap.com/articles/smite-2-statement-from-hi-rez-president-approach-to-game-design-unreal-engine-5-more
---
# Smite

Third-person mythology-themed MOBA (2014, Titan Forge Games / Hi-Rez Studios) that redefined the genre's camera and combat feel by placing the player directly behind their god instead of above the battlefield.

## Design

- **Core innovation — third-person perspective:** Every ability is aimed manually from an over-the-shoulder camera. Skill shots are literal — you miss a position, you miss the spell. This shifts the game closer to action combat (dodge, strafe, aim) than the point-click command paradigm of LoL and Dota 2.
- **God roster:** 130+ playable gods (as of August 2025) drawn from 15+ real-world pantheons: Greek, Norse, Egyptian, Hindu, Chinese, Japanese, Mayan, Celtic, Roman, Babylonian, Slavic, Polynesian, Voodoo, Yoruba, Arthurian, and Great Old Ones. New gods ship roughly monthly.
- **Map and modes:** Conquest (classic 3-lane map), Joust (1v1 or 3v3 single lane), Arena (circular team fight), Assault (random single-lane), and several rotating modes. The mode variety lets players choose the depth of strategy they want.
- **Matchmaking:** Modified TrueSkill ranking system; Elo-variant in ranked modes targeting equal total team rating. Separate queues by mode; ranked Conquest requires unlocking a minimum god count.
- **Esports:** Annual Smite World Championship with a capped $1 million prize pool. Season 8 introduced a franchise league model (Hi-Rez directly managing teams). Smaller than LoL/Dota esports but maintained a dedicated following for a decade.
- **Monetization:** Freemium — 12 rotating free gods weekly, or a one-time God Pack for permanent access to all current and future gods. Total revenue reached $300 million by 2019. Cosmetic skins follow the typical MOBA model.
- **Smite 2:** Announced January 2024; launched free-to-play January 2025 on Unreal Engine 5 as a full rebuild. Original Smite concluded development February 2025.

## Implementation

- **Engine:** Unreal Engine 3 (original Smite); Smite 2 is UE5. UE3's first-/third-person shooter heritage made it a natural fit for the behind-the-shoulder camera.
- **Netcode:** Standard client-server model inherited from UE3. No separately documented tick rate; comparable to other MOBAs (~30 Hz) given genre conventions. The UE3 networking stack is well-understood — predictive client movement, server reconciliation.
- **Platforms:** Windows, Xbox One, PS4, Nintendo Switch, Amazon Luna (original). Smite 2 expands cross-platform.

## Why it matters

- **Camera as design primitive:** Smite demonstrates that changing a single camera parameter fundamentally reshapes the skill set required, the audience attracted, and the esport produced. Camera choice is not cosmetic — it determines what genre you are.
- **God Pack pricing model:** Permanent roster access via a one-time flat fee was unusual for 2014 free-to-play design and reduced friction for new players nervous about predatory monetization. It also differentiated Smite from LoL's slower unlock grind.
- **Full sequel as live-service transition:** Smite 2's move to UE5 while sunsetting UE3 Smite is a rare example of a live-service game replacing itself with a sequel rather than incrementally upgrading — a high-risk play that sacrificed the original player base in exchange for a clean technical slate.

## Relevance to Wayfinder

- [[Combat]]: Smite's behind-the-shoulder camera and manual aim translate directly to Wayfinder's action combat target — our game already operates in this camera register. Smite validates that a mass market exists for MOBA-like co-op pacing in a third-person action frame.
- [[Skills]]: Smite's mode variety (Conquest depth vs. Arena casual) suggests Wayfinder could offer chart difficulty tiers that map to different player investment levels without fragmenting the game's identity.
- [[Multiplayer Co-op]]: God Pack one-time purchase model is worth considering for Wayfinder's unlock design — reducing recurring friction while maintaining a premium upsell path for cosmetics.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Balance Philosophy]]
- [[MMO Netcode and Tick Systems]]
- Siblings: [[League of Legends]] · [[Dota 2]] · [[Heroes of the Storm]] · [[Paragon]]
- Wayfinder: [[Combat]] · [[Skills]] · [[Multiplayer Co-op]]

## Sources

- https://en.wikipedia.org/wiki/Smite_(video_game)
- https://smite.fandom.com/wiki/Hi-Rez_Studios
- https://www.gameleap.com/articles/smite-2-statement-from-hi-rez-president-approach-to-game-design-unreal-engine-5-more
