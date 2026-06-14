---
type: game
tags: [game-study, co-op, mandatory-co-op, puzzle-platformer, mechanic-variety, goty, split-screen, narrative-co-op]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)
  - https://geekculture.co/geek-interview-hazelight-studios-josef-fares-it-takes-two/
  - https://facewaretech.com/blog/interview-hazelight-studios-talks-facial-animation-on-it-takes-two/
  - https://www.hazelight.se/games/it-takes-two/
  - https://whatsontech.co.uk/is-it-takes-two-cross-platform-or-crossplay-in-2024/
---
# It Takes Two

Mandatory co-op puzzle-platformer (2021, Hazelight Studios / EA) — a two-player-only narrative adventure built entirely around the word "collaboration," in which a divorcing couple is shrunk to toy-size and must work together through a mechanically fresh chapter-per-level design; won Game of the Year at The Game Awards 2021.

## Design

- **Mandatory two-player, zero solo.** There is no single-player option. The game does not start without two players. This is a design constraint enforced at every level: all puzzles, all combats, all traversal sequences assume two distinct human agents. Director Josef Fares: "We design from the beginning around two players rather than adding co-op to a single-player structure."
- **"Never repeat" as the governing rule.** Fares pushed developers to introduce new mechanics with almost every chapter and never repeat a major mechanic level-to-level. Examples: one player controls time-rewind while the other clones herself; one uses a nail gun while the other uses a magnet; a snowball-fight chapter uses fully different mechanics than the toy train chapter. This sustained variety is the game's primary mechanical identity.
- **Mechanics tied to narrative theme.** Each chapter's new mechanic reflects the story beat being explored — the split-personality book chapter grants players literally divergent abilities; the shed/garden levels tie tools to the couple's emotional arcs. The mechanics are not just fun for their own sake; they literalise the theme of collaboration.
- **Friends Pass: asymmetric purchase model.** One player buys the game; the other downloads a free "Friends Pass" client and plays with full access. This lowers co-op barrier dramatically (the partner does not need to own the game). The game sold 30 million copies by April 2026, with Friends Pass cited as a significant driver of adoption.
- **No collectibles, no padding.** Fares explicitly rejected traditional collectible loops: "Let's make the world interesting, make the player explore, and not have some shit to collect." The game is paced like a film rather than a game designed to inflate playtime.
- **Split-screen always.** Both local and online play use a split-screen layout so each player sees their own character at all times. No camera handoff, no follow-cam compromise. This was a fixed technical decision that shaped every environment's visual design (legibility at half-screen width).

## Implementation

- **Engine:** Unreal Engine 4. Custom scripting via AngelScript (using Hazelight's open-source UnrealEngine-AngelScript integration), which allowed faster iteration on per-chapter mechanic prototypes than C++ alone.
- **Exclusively 2-player, no more.** The implementation never needs to handle 3+ player logic, server-side state, or matchmaking beyond a single partner connection. This constraint radically simplifies the networking layer: it's always exactly one host and one client, or local split-screen.
- **Online architecture: P2P, one-host-one-client.** Community and platform sources confirm the game uses a direct connection between two players. There are no dedicated servers. Crossplay is limited to within platform families: Xbox One/Series X|S + Windows PC can play together; PS4/PS5 play together; no cross-network crossplay (Xbox ↔ PlayStation).
- **Nintendo Switch port (2022, Turn Me Up Games).** The Switch version required a custom networking solution because the original codebase was not built around Switch's local wireless API. Targeted 720p handheld / 1080p docked at 30 fps. This illustrates a common porting tax when co-op networking is not abstracted from platform-specific layers.
- **Respawn system.** On death, the player respawns quickly. During difficult sections (including boss fights) the living player can accelerate the dead partner's return by button-mashing. This is a no-friction co-op quality-of-life decision: death is never a session-ender.
- **Critical and commercial reception.** Metacritic 89 (PS5). Game of the Year: The Game Awards 2021, D.I.C.E. Awards 2022. Best Multiplayer: Golden Joystick Awards 2021. 1 million copies in one month; 7 million by mid-2022; 30 million by April 2026.

## Why it matters

It Takes Two is the definitive proof-of-concept that a **mandatory co-op constraint** can be a creative superpower rather than a commercial liability. Every level, mechanic, and puzzle was designed for two — not designed for one and retrofitted. The "never repeat" mechanic rule is an unusually rigorous commitment to player novelty that the game executed at commercial scale. The Friends Pass model is the most successful co-op adoption mechanic in the genre.

## Relevance to Wayfinder

- **Co-op-first design posture.** Hazelight's lesson is that co-op depth requires designing the core loop for two (or N) players from day one, not bolting it on. Wayfinder's [[Multiplayer Co-op]] spec targets 2–4 players; the design implication is that every chart run mechanic should be interrogated for "does this actually require/benefit from a partner?" rather than "does this break if someone joins?"
- **Friends Pass as discovery funnel.** The free-client model dramatically expanded It Takes Two's reach. Wayfinder could consider a similar "bring a friend free for the session" mechanism for chart runs — a friend of a Wayfinder owner can join a run without purchasing, lowering social friction at the cost of a license unit. See [[Multiplayer Co-op]].
- **Mechanic freshness per run type.** The "never repeat" principle maps directly to Wayfinder's [[Chart Loop]] affix system: different affix combinations should produce mechanically distinct run feels (an "all traps" chart vs. a "heavy elite" chart vs. a "harvest bounty" chart), not just stat changes. The lesson is that variety needs to be procedural if you can't hand-craft every run.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]]
- [[Monster Hunter World]] · [[Deep Rock Galactic]] · [[Helldivers 2]] · [[Sea of Thieves]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Bosses]] · [[Chart Loop]]

## Sources

- https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)
- https://geekculture.co/geek-interview-hazelight-studios-josef-fares-it-takes-two/
- https://facewaretech.com/blog/interview-hazelight-studios-talks-facial-animation-on-it-takes-two/
- https://www.hazelight.se/games/it-takes-two/
- https://whatsontech.co.uk/is-it-takes-two-cross-platform-or-crossplay-in-2024/
