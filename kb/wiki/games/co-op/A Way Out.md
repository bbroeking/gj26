---
type: game
tags: [game-study, co-op, mandatory-co-op, narrative-co-op, split-screen, friend-trial, hazelight, action-adventure]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/A_Way_Out
  - https://pixelation.org/a-way-out-why-hazelights-co-op-experiment-still-hits-different-years-later-3ch
  - https://gamingcypher.com/ea-hazelight-announce-friends-pass-free-trial-co-op-adventure-way/
  - https://www.newsweek.com/way-out-friend-pass-guide-how-use-free-full-game-trial-858615
  - https://www.gameverdict.net/hazelight-studios-games-revolutionizing-co-op-storytelling-in-modern-gaming/
---
# A Way Out

Mandatory 2-player narrative co-op (2018, Hazelight Studios / EA) in which two convicts — Leo and Vincent — must break out of prison and stay on the run together, with every design decision subordinated to the two-person partnership; it is the predecessor to [[It Takes Two]] and the founding proof-of-concept for Hazelight's co-op-only studio identity.

## Design

- **Mandatory 2-player, no solo.** Like [[It Takes Two]], A Way Out cannot be started by a single player. Josef Fares and Hazelight treat the constraint as a creative mandate rather than a limitation: every scene, puzzle, and action sequence is authored assuming two distinct human agents at all times.
- **Dynamic split-screen.** Rather than a fixed 50/50 vertical or horizontal divide, the game uses a *cinematic* split-screen whose partition line shifts, scales, and occasionally dissolves based on narrative context. When Leo and Vincent are close together the screens merge; during action sequences the dominant character gets more real estate. This creates an "intimate sense of presence" that static split-screen cannot.
- **Asynchronous co-op moments.** The game deliberately places the two characters in different states simultaneously — one watching a cutscene while the other can still move and interact, one in dialogue while the other scouts. This asymmetry forces real communication and prevents passive spectatorship.
- **Choice-forcing mechanics.** Many scenarios present two solutions (distract the guard vs. knock him out, pick the lock vs. find a key); the players must negotiate verbally. The game encodes co-op into the decision layer, not just the action layer.
- **Downtime as design.** Non-combat interstitial moments — playing darts, strumming guitar together, arm-wrestling — are first-class content, not filler. They build the emotional rapport the story's climax depends on, and they give exhausted players breathing room without breaking the session.
- **No matchmaking.** Unlike most online co-op titles, A Way Out requires players to invite a specific friend. There is no random-matchmaking lobby. The game is explicitly designed for *known* social pairs.

## Implementation

- **Engine:** Unreal Engine 4; small team of ~30–35 at Hazelight.
- **Session model:** Strict 2-player, friend-invite only. No public matchmaking, no random pairing. Each session is one host and one client, local split-screen or online.
- **Friend Trial (predecessor to Friends Pass).** One player purchases the game; the other downloads a free "Friend Trial" client giving full access to the entire game for that session. The purchasing player initiates the online session and the game prompts the non-owner to download the trial. This was announced at The Game Awards 2017 — it predates and directly inspired the Friends Pass model refined in [[It Takes Two]].
- **Crossplay:** Not supported at launch; the game is platform-siloed (PS4, Xbox One, PC/Origin each separate). Online co-op requires players to be on the same platform ecosystem.
- **Online stability:** Community and press reports describe the netcode as "surprisingly stable" for a small-studio title. No dedicated servers; latency is host-dependent.
- **Sales:** Over 13 million copies sold by April 2026. Won BAFTA Award for Multiplayer (2019). Metacritic 78–79/100.

## Why it matters

A Way Out proved that a zero-solo-option game could be a commercial and critical success when the co-op constraint is the *source* of design ideas rather than a restriction on them. It established the Friend Trial/Pass model — one purchase enables two people to play the full game — as the most effective co-op adoption mechanism Hazelight has found. The dynamic split-screen is still the most sophisticated real-time split-screen framing in mainstream co-op games.

## Relevance to Wayfinder

- **Friend Trial as session onboarding.** The Friend Trial mechanic directly lowered the barrier for co-op adoption (one owner, one free client). Wayfinder's [[Multiplayer Co-op]] design should interrogate a similar "bring a friend into a chart run at no cost" model to reduce friction for the social pair who only one of whom has purchased the game.
- **Asymmetric moment design.** A Way Out's asynchronous scenes — where players are in different states simultaneously — suggest that co-op dungeon design need not synchronize both players at all times. In a Wayfinder chart run, one player could be interacting with a gather node while another scouts ahead or handles an elite, rather than always forcing the party to cluster. See [[Multiplayer Co-op]] and [[Combat]].
- **No matchmaking as brand statement.** Hazelight deliberately excluded random matchmaking to enforce the social-pair experience. Wayfinder could take the opposite position (open matchmaking for 2–4) but should acknowledge the tradeoff: designed-for-strangers co-op feels different from designed-for-friends co-op.

## See also

- [[Game Index]] · [[Game Studies]]
- [[It Takes Two]] · [[Design Influences]]
- [[Multiplayer Co-op]] · [[Combat]]
- [[Full Metal Furies]] · [[Deep Rock Galactic]]

## Sources

- https://en.wikipedia.org/wiki/A_Way_Out
- https://pixelation.org/a-way-out-why-hazelights-co-op-experiment-still-hits-different-years-later-3ch
- https://gamingcypher.com/ea-hazelight-announce-friends-pass-free-trial-co-op-adventure-way/
- https://www.newsweek.com/way-out-friend-pass-guide-how-use-free-full-game-trial-858615
- https://www.gameverdict.net/hazelight-studios-games-revolutionizing-co-op-storytelling-in-modern-gaming/
