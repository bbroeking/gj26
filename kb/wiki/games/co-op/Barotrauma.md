---
type: game
tags: [game-study, co-op, survival, role-specialization, simulation, traitor-mechanic, dedicated-server, 16-player]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Barotrauma_(video_game)
  - https://gamerant.com/barotrauma-all-crew-roles-explained/
  - https://geekflare.com/hosting/best-barotrauma-server-hosting-options/
  - https://steamcommunity.com/app/602960
  - https://www.co-optimus.com/game/5538/pc/barotrauma.html
---
# Barotrauma

Hardcore co-op submarine survival simulator (2023 full release, Undertow Games / FakeFish / Daedalic) in which up to 16 players crew a submersible navigating the ocean of Jupiter's moon Europa, each filling a specialized technical role to keep the vessel alive against alien fauna, flooding, mechanical failure, and potentially each other — the deepest implementation of *ship-as-game-system* in co-op.

## Design

- **Six non-substitutable crew roles.** Captain (navigation and crew coordination), Engineer (reactor and power grid), Mechanic (hull and machinery), Medical Doctor (crew health and pharmacology), Security Officer (combat and internal threats), and Assistant (flexible support). The roles are not cosmetically differentiated — each requires distinct system knowledge and has access to different areas, tools, and equipment. A session without a Medical Doctor means injuries go untreated; a session without an Engineer risks reactor meltdown. Role coverage is a genuine survival constraint.
- **Critical interdependence as the loop.** The design forces inter-role dependency at every crisis point: Mechanics and Engineers both need the fabricator; Doctors need Security Officers' protection during combat; Captains issue orders but depend on all roles executing correctly. "Survival is most certainly not guaranteed" without understanding how roles function together — the game's central promise. This is the highest-stakes role-interdependency design in mainstream co-op.
- **Traitor mechanic (optional).** Multiplayer sessions can include a randomly assigned traitor crew member with a hidden objective to sabotage the mission. This transforms the game's social layer: trust must be earned, accusations fly, and every role suddenly becomes a potential threat vector. The Security Officer's job expands from alien defense to internal investigation. This is an opt-in module, not the default mode, but it defines the game's reputation.
- **Submarine editor and procedural campaign.** Players can build custom submarines and campaign outposts. The campaign mode has a persistent goal (reaching the Eye of Europa) with resource management across dives. Each dive is a multi-stage operation: route planning, dive execution, crew injury management, and return/resupply.
- **Scale:** Up to 16 simultaneous players — an unusually large session for an intimate survival game. At 16 players the submarine becomes a complex social organism, with specialized sub-groups for each role cluster. At smaller counts (4–8), roles must be doubled up, changing the tension profile.

## Implementation

- **Engine:** MonoGame (C# framework, not a major commercial engine). Lead developer Joonas "Regalis" Rikkonen previously created SCP – Containment Breach on the same stack.
- **Release:** Steam Early Access June 2019; full release March 13, 2023. Platforms: Windows, macOS, Linux.
- **Server model:** Supports both peer-to-peer hosting and dedicated server deployment. Third-party Barotrauma server hosting services (Shockbyte, GTXGaming, etc.) offer rentable dedicated servers optimized for the game's physics-heavy simulation. Dedicated servers are the community-preferred model for reliable 16-player sessions; P2P is viable for smaller groups but vulnerable to host performance.
- **Simulation load:** The submarine simulation (flooding physics, reactor dynamics, power grid state, creature AI) places significant CPU load, particularly during multi-system crises. High-frequency CPUs are recommended for server hosting. This is not a lightweight netcode situation — the simulation is the product.
- **Modding:** Strong mod ecosystem including custom submarines, campaigns, and game mode variants. The Steam Workshop is an active distribution channel.
- **Reception:** Won "Best Hardcore Game" at Game Connection Europe 2018 (during Early Access); "Best Survival Game" at Games Without Borders 2019. Mixed/positive reviews noting steep learning curve as a feature, not a bug.

## Why it matters

Barotrauma is the furthest extreme of *role-as-game-design*: it builds an entire game out of the thesis that players assigned to distinct technical roles within a shared simulation will produce emergent co-op drama without scripted events. The traitor mechanic shows that social deduction can layer on top of any co-op role structure, and that 16 players can sustain meaningful specialization if the system is complex enough to absorb them. It also demonstrates that MonoGame can sustain a commercially viable, long-lived Early Access title — a note for small teams choosing engines.

## Relevance to Wayfinder

- **Role specialization without class locks.** Barotrauma's six roles are job-defined, not character-class-defined — a player *chooses* Captain or Mechanic at session start, not at character creation. Wayfinder's chart runs could adopt a lighter version: players choosing a run-time role ("I'll focus gather, you handle combat") within a class-agnostic system. See [[Multiplayer Co-op]] and [[Crafting]].
- **Shared system as co-op glue.** The submarine *is* the co-op mechanic — maintaining it forces interaction. In Wayfinder, a shared dungeon resource (a portable Wayfinding chart that must be jointly inscribed, or a camp fire that requires fuel from both players) could serve the same binding function, giving co-op players a shared object to rally around beyond just fighting the same enemies. See [[Chart Loop]].
- **Dedicated server as trust signal.** Barotrauma's community migrated to dedicated servers for reliability. If Wayfinder reaches 16-player co-op scale (unlikely at first, but noted), dedicated server support is the prerequisite for a stable experience. At 2–4 players, host-as-server is workable.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Crafting]]
- [[Design Influences]] · [[MMO Netcode and Tick Systems]]
- [[Deep Rock Galactic]] · [[Sea of Thieves]] · [[Helldivers 2]]

## Sources

- https://en.wikipedia.org/wiki/Barotrauma_(video_game)
- https://gamerant.com/barotrauma-all-crew-roles-explained/
- https://geekflare.com/hosting/best-barotrauma-server-hosting-options/
- https://steamcommunity.com/app/602960
- https://www.co-optimus.com/game/5538/pc/barotrauma.html
