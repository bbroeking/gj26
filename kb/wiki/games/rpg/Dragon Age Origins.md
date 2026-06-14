---
type: game
tags: [game-study, rpg, bioware, companion-design, approval-system, tactical-combat, origin-stories, narrative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Dragon_Age:_Origins
  - https://dragonage.fandom.com/wiki/Companions_(Origins)
  - https://dragonage.fandom.com/wiki/Approval_(Origins)
  - https://www.thegamer.com/dragon-age-origins-companion-approval-guide/
  - https://dragonage.miraheze.org/wiki/Approval_(Origins)
  - https://www.gamerguides.com/dragon-age-origins/guide/introduction/character-basics/approval
---
# Dragon Age Origins

Tactical role-playing game (2009, BioWare / EA) — a dark-fantasy epic in which a Grey Warden recruit unites fractious nations against a demonic Blight, celebrated for its six origin stories that permanently color NPC reactions, a companion approval system that ties emotional investment to combat performance, and one of the most finely tuned real-time-with-pause tactical combat systems in the genre.

## Design

- **Six origin stories.** At character creation players choose a race/class combination (human noble, dwarf commoner, city elf, Dalish elf, dwarf noble, mage) that delivers a unique opening chapter. Each origin embeds the player in a different social stratum of Ferelden — the mage tower, the alienage slum, the dwarven Proving arena — and leaves lasting traces: NPCs recognize and react to the Warden's background throughout the main campaign, creating a sense of personal stakes rather than a blank-slate hero.
- **Companion approval system.** Eight recruitable companions each maintain a hidden approval score (−100 to +100) affected by every dialogue choice, gift, and party decision. Crossing approval thresholds unlocks new conversation branches, personal quests, attribute stat bonuses (Wynne gains Willpower, Sten gains Strength at high approval), and romance options. Critically, characters with conflicting values react differently to the same choices — gaining Alistair's approval while retaining Morrigan's requires genuine value negotiation, not simple optimization. Low approval risks abandonment or betrayal. Personal quests are gated by reaching "Warm" or "Friendly" thresholds, marrying narrative intimacy to mechanical investment.
- **Tactics system.** Players configure per-companion AI behavior through a scripted condition/action menu (Tactics slots). A rogue companion can be set to "Use Stealth → when health < 25%"; a healer to "Cast Heal → if ally health < 50%." This lets players set and forget companion behavior in routine encounters while retaining full manual pause-and-command control for hard fights — a rare design that satisfies both tactical and casual players simultaneously.
- **Class and ability trees.** Three classes (warrior, rogue, mage) each branch into three specializations unlocked mid-game (e.g., Berserker, Champion, Templar for warriors). Stamina/mana limits per-encounter ability use; sustained abilities toggle on but drain resources continuously. The combination produces fights where resource management is as important as positioning.

## Implementation

- **Eclipse Engine** (BioWare proprietary), switched mid-development causing significant schedule delays. The final game contained 68,260 lines of dialogue voiced by 144 actors — still among the most dialogue-dense RPGs shipped at that time. Orchestral score by Inon Zur performed by a 44-piece orchestra doubled for effect.
- **91/100 Metacritic (PC)**; won multiple Game of the Year awards; sold 3.2+ million copies with one million DLC purchases in the first year. Spawned three sequels (DA2, Inquisition, The Veilguard) and established BioWare's companion-relationship system as an industry template.
- The Tactics menu was a direct response to complaints about party AI in Neverwinter Nights, where companions would stand idle during combat — a case study in listening to player frustration and building a systemic solution rather than patching individual cases.

## Why it matters

Dragon Age: Origins proved that **companion investment can drive mechanical depth**: approval is not just narrative flavor but a stat buffer with real combat implications, making players care about relationships for selfish as well as emotional reasons. The origin-story system demonstrates that **background as first-chapter content** (rather than a stat screen) produces lasting role-play hooks that are difficult to retrofit. The Tactics menu shows that **programmable companion AI** dramatically lowers the skill floor without removing the skill ceiling.

## Relevance to Wayfinder

- **[[Combat]]:** The Tactics system — programmable condition/action AI for companions — is directly relevant for Wayfinder's co-op. Even in a single-player context, NPC allies with configurable behavior reduce friction without sacrificing tactical depth.
- **[[Trades and Leveling]]:** Approval-unlocked stat bonuses tie social investment to mechanical payoff, a model for how Wayfinder's NPC relationships (traders, mentors) could gate Trade perks or bonus gather yields.
- **[[Voice and Tone]]:** The origin-story hook — your background permanently inflects how Bramblewood residents address you — is achievable even with Wayfinder's smaller scope; a starting Trade choice could color early NPC dialogue.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Progression Systems]]
- Wayfinder: [[Combat]] · [[Trades and Leveling]] · [[Voice and Tone]] · [[Balance Philosophy]]
- Siblings: [[Baldurs Gate 3]] · [[Pillars of Eternity]] · [[Pathfinder Wrath of the Righteous]] · [[Disco Elysium]]

## Sources

- https://en.wikipedia.org/wiki/Dragon_Age:_Origins
- https://dragonage.fandom.com/wiki/Companions_(Origins)
- https://dragonage.fandom.com/wiki/Approval_(Origins)
- https://www.thegamer.com/dragon-age-origins-companion-approval-guide/
- https://dragonage.miraheze.org/wiki/Approval_(Origins)
