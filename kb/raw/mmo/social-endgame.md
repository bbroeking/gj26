# Raw Provenance: MMO Social Structures and Endgame Design
<!-- Immutable once written. Facts + source URLs only. No synthesis. -->

ingested: 2026-06-13
researcher: Claude Sonnet 4.6 (claude-code)

---

## Source 1: "Rethinking the Trinity of MMO Design" — Game Developer (Gamedeveloper.com)
URL: https://www.gamedeveloper.com/design/rethinking-the-trinity-of-mmo-design

- The tank/healer/DPS holy trinity emerged from EverQuest adapting D&D mechanics; EverQuest locked warrior=tank, cleric=healer permanently.
- WoW refined this via talent trees, enabling limited role flexibility within classes.
- Core advantages: encounter predictability (devs know group composition), role-shorthand communication, alt-character replayability.
- Core problems: DPS dominates because solo advancement rewards damage output; tank/healer failures are catastrophic while DPS variance is not; role imbalance; setting-archetype mismatches.
- Designer Brian "Psychochild" Green proposes eliminating specialized roles while preserving class identity — all classes access damage, survival, and support through different mechanical expressions.
- Pre-WoW, "holy trinity" meant tank, healer, and *mezzer* (crowd control) — DPS was assumed background; mezzing, buffing, and debuffing roles vanished in the modern era.
- Guild Wars 2 abolished the trinity but kept designing content the traditional way — broadly considered a partial failure of execution.
- Source: game developer editorial, no byline date confirmed; designer cited by name.

---

## Source 2: "Game Design Patterns for Building Friendships" — Gamedeveloper.com
URL: https://www.gamedeveloper.com/design/game-design-patterns-for-building-friendships

Based on Project Horseshoe report (industry design workshop).

Four core factors for friendship formation:
1. **Proximity** — density ratio (players vs map size), guild hubs, shared events, recurring schedules, elastic instancing.
2. **Similarity** — visible distinctions (titles, gear), faction identity in-group cohesion, shared difficult experiences. Perceived similarity matters more than actual similarity.
3. **Reciprocity** — iterative exchanges, complementary roles creating mutual dependency (tank+healer), escalating costs as friendship deepens.
4. **Disclosure** — rich opt-in communication tools, quiet moments for natural conversation, mechanics encouraging safe vulnerability.

Anti-patterns: showing real names/locations early; extreme skill differentials; frequent post-match splitting; zero-sum resource competition early in relationships.

Success metrics: % repeated co-play sessions (co-play 2 vs 1); familiar faces; friend-list interaction; communication acceptance rates.

Quote: "As game designers, this is one of our great powers and responsibilities. We design these machines."

---

## Source 3: "Social Design Practices for Human-Scale Online Games" — Lostgarden.com (Daniel Cook, 2018)
URL: https://lostgarden.com/2018/12/29/social-design-practices-for-human-scale-online-games/

Dunbar's layers (Robin Dunbar, 1980s anthropology):
- 5 intimate friends (crisis trust)
- 15 best friends (high sympathy/support)
- 50 good friends (regular emotional/economic support)
- 150 casual friends (maximum meaningful relationships — "Dunbar's Number")

Groups above 150 require formal bureaucracy, hierarchy, and weak-tie systems.

Friendship time costs: casual = 40–60 hours; good = 90–110 hours; best = 200+ hours. Maintenance: best friends require at minimum monthly interaction.

Adding more than 150 players to a social group actively damages social bonds (contradicts traditional MMO scaling logic).

Large groups (500+) develop toxic sub-groups, griefing tribes, intergroup conflict as cultural norm, scope creep in moderation.

Games like Dofus succeeded despite poor tutorials because players brought existing friend networks in — high-trust communities sustain engagement.

---

## Source 4: "A Match Made In…Well, Somewhere: Matchmaking Systems and Social Breakdown in MMOs" — kaylriene.com (2021)
URL: https://kaylriene.com/2021/05/22/a-match-made-in-well-somewhere-matchmaking-systems-and-social-breakdown-in-mmos/

- WoW's Dungeon Finder (patch 3.3, Wrath of the Lich King) was cross-server matchmaking — removed need to form groups through server chat.
- Pre-LFD, manual group assembly created natural relationship-building opportunities ("groups were a pure social experience").
- Post-LFD: players complete content with strangers they'd never see again; negative behavior consequences reduce (no reputation damage); skilled players gain no server standing.
- Teleportation directly to dungeons eliminates "sense of place" — dungeons become abstract gameplay spaces disconnected from world.
- Undeniable success in increasing accessibility and retention, but created irreversible negative externalities on community.
- Mythic+ partially addresses this by requiring manual group assembly; regional cross-server still undermines local community.
- WoW Classic deliberately excluded Dungeon Finder to protect old-school MMO social experience.

---

## Source 5: "So You Want to Build an MMO 6/18 — Social Systems & Community Architecture" — Alexander Bakharev, Medium (April 2026)
URL: https://medium.com/@alexander.bakharev_16063/so-you-want-to-build-an-mmo-6-18-social-systems-community-architecture-62ab56185d53

Raph Koster's "convenience-community tradeoff": QoL features reducing friction eliminate potential connection points. Each automated system (matchmaking, fast travel, instancing) trades social interaction for accessibility.

Guild structures across games:
- FFXIV: single Free Company (FC) loyalty → deep commitment model
- ESO: five-guild approach → specialization (trading, PvE, PvP, social)
- EVE: corporation system → maximum complexity; CEO authority, 30+ permission roles, hostile takeover mechanics

WoW's guild leveling system FAILED: Cash Flow perk incentivized mass-invite spam guilds and gold siphoning. Blizzard fixed by making all guilds effectively max level.

Gaiscioch community: "rank means greater responsibility, not power over others" — peer-voted advancement tokens, servant leadership model.

Party size has social consequences:
- 4-person parties (FFXIV): create tank/healer scarcity, DPS queue pressure
- 6-person parties (FFXI): allow support roles, reduce individual pressure

EverQuest/FFXI "forced grouping" created bonds less through mandate and more through "repeated encounters in a closed server population." **Recurring encounters matter more than mandatory dependency.**

Star Wars Galaxies: Entertainers in cantinas provided XP buffs; Battle Fatigue (healable only through Entertainers) mechanically required regular visits. When removed, cantina community collapsed. **Social spaces need mechanical reinforcement, not just design appeal.**

FFXIV's hub: Limsa Lominsa became the player hub NOT because of aesthetics but because shortest distance from Aetheryte to Market Board. "Service clustering, not aesthetic appeal, determines where players congregate."

FFXIV's Commendation system: deliberate cultivation of prosocial norms through post-dungeon voting.

Bartle's Taxonomy (1996): Killers → Socializers leave → Achievers leave (lose audience) → Killers leave (no prey). Ecological balance matters.

Yee's Daedalus Model (2005, empirical, 3200 players): Achievement and Social mildly positively correlated (r = .10) — contradicts Bartle's opposition.

Kim's Social Action Matrix (2014): Compete, Collaborate, Explore, Express — deliberately tunable per project.

Raider.io gatekeeping: need score to join groups, can't get score without joining groups — a documented catch-22.

Discord/Social SDK: 39% more gameplay days when Discord accounts linked in Pax Dei (2025 data).

New World: peaked at 900K concurrent, dropped 98% within a year; shut down October 2025.

Daniel Cook's "Kind Games" (GDC 2024): tit-for-tat cooperation emerges when players expect prosocial behavior; initial norm-setting matters more than punishment.

EVE's CSM (Council of Stellar Management): 10 elected members, NDA-signed, attend dev meetings, fly to Iceland for summits — most developed player governance in genre.

Judgement Day Heist (EVE, 2017): CSM member betrayed alliance, plundered 1.5 trillion ISK. Only possible because EVE's mechanics make trust a gameplay resource.

"Scarab Lord" title (WoW): required server-wide cooperation + individual questline. One to three players per server earned it. Power = legibility: any player immediately understands what it represents.

GW2 fashion ("Fashion Wars 2"): ArenaNet officially embraced it April 2025, added Cosmetic Inspection features.

FFXIV's sprout/mentor crown: widely mocked as "Burger King crown"; Astrope mount at 2,000 completions pursued without genuine mentoring.

Level sync implementations compared:
- FFXIV: skill-stripping (lose abilities above synced level)
- GW2: stat-only downscale (keep all skills, reduced stats)
- ESO: universal upscale (all content scales, undermines progression feeling)
- City of Heroes: sidekick/exemplar system (earliest praised bidirectional implementation)

---

## Source 6: "Raid Design Lessons from WoW, Guild Wars 2, and Final Fantasy 14" — PCGamesN
URL: https://www.pcgamesn.com/mmo-raids

Raid size evolution:
- WoW Classic: 40 players
- FFXIV: 8 players
- GW2: 10 players
- Destiny 2: 6 players
Industry trend: smaller, more sustainable teams.

WoW director Ion Hazzikostas: "a consistent sense of challenge is absolutely essential to raid design" — avoid one role facing disproportionate complexity while others find content rote.

ArenaNet's Jason Reynolds: raids foster "socialisation and camaraderie, which is doubly critical to the MMO genre."

Reid (ArenaNet): adding raids later in GW2's development created barriers — existing 5-player groups suddenly needed 5 more members; deterred some players.

FFXIV director Naoki Yoshida (Yoshi-P): "what makes a raid good or bad is not the difficulty level, but whether the gimmicks and mechanics are convincing enough."

Modern raid design prioritizes meaningful mechanics over raw difficulty.

---

## Source 7: Mythic+ Mechanics — Maxroll.gg guide (current as of Midnight season, 2026)
URL: https://maxroll.gg/wow/resources/mythic-dungeon-mechanics

- Group size: exactly 5 players (1 tank, 1 healer, 3 DPS).
- Keystones scale infinitely; each level adds 10% enemy health and damage.
- Timer upgrade: <20% remaining = +1; 20–40% = +2; >40% = +3. Fail timer = -1 downgrade.
- Affix breakpoints: +2 (Lindormi's Guidance), +5 (Tyrannical or Fortified), +7 (Xal'atath's Guile), +10 (all active).
- Seasonal dungeon rotation: 8 dungeons per season (mix of current expansion + returning).
- Mythic+ introduced in Legion (2016); seasonal rotation concept from Dragonflight Season 1.
- Raider.io catch-22: need score to join groups; can't earn score without joining groups.

---

## Source 8: GW2 Dynamic Events — GDC 2010 talk overview
URL: https://gdcvault.com/play/1013691/Designing-Guild-Wars-2-Dynamic

Presenters: Eric Flannum (lead designer) and Colin Johanson (lead content designer), ArenaNet/NCsoft, GDC Europe 2010.
Goal: create "an exciting, living, breathing online world that encourages social interaction between players."
Problems addressed: stagnation of core MMORPG content; traditional quests as solo experiences.
Dynamic events: occur in open world zones; multiple outcomes cascade into new events; no kill-stealing (individual rewards); no explicit group-forming required.
(Full content behind GDC Vault paywall; limited detail available.)

---

## Source 9: GDC 2024 "Kind Games" — Daniel Cook
URL: https://media.gdcvault.com/gdc2024/Slides/GDC+slide+presentations/Kind+Games+-+GDC+2024+-+Daniel+Cook.pdf

- Prosocial cooperation via tit-for-tat: majority of players copy prosocial behavior when they expect others to do the same.
- Initial norm-setting more effective than punishment systems.
- GW2's individual rewards in dynamic events prevent kill-stealing conflicts while preserving cooperation.

---

## Source 10: WoW Wrath Classic Dungeon Finder Debate — GameSpot (2022)
URL: https://www.gamespot.com/articles/wow-wrath-of-the-lich-king-classic-devs-talk-server-woes-the-dungeon-finder-debate-and-heroic-dungeons/1100-6507788/

Blizzard excluded LFD from WoW Classic: goal was protecting old-school MMO social experience and keeping Classic distinct.
Critics: LFD depersonalizes the game, gives players little reason to act decently since they never see each other again.
Defenders: matchmaking made the game accessible to players who couldn't spend 6 hours looking for a group.
Classic servers don't have same player density as Retail: automated systems prone to long queues and frequent dropouts.

---

## Source 11: EVE Online Social Contract / Trust Research
URL: https://www.researchgate.net/publication/401376537_Beyond_the_sandbox_Autonomy_trust_and_social_capital_in_the_high-stakes_universe_of_EVE_Online

EVE as "sandbox": making nearly anything legal (without technical exploit) allows treachery, betrayal, and social play as gameplay mechanics.
Reputation and emergent ethical codes ("space Bushido") are fundamental to the social order.
Reputation plays crucial role in accessing alliances and opportunities.
Trust is a gameplay resource that can be weaponized.

---

## Source 12: FFXIV Endgame Difficulty Tiers
URL: https://ffxiv.consolegameswiki.com/wiki/Difficulty

Difficulty tiers:
- Normal raids/trials: story-level, most players
- Hard mode: stepping stone
- Extreme trials: challenging, standard pre-Savage content
- Savage raids: 8-player, core endgame raiding; weekly loot lockout per boss
- Ultimate raids: hardest content; independent of patch tier; prestige/cosmetics
- Alliance raids: 24-player casual raids

---

## Source 13: Palia — Cozy MMO Design
URL: https://www.pcgamer.com/cozy-community-mmo-palia-turns-fishing-and-cooking-into-co-op-activities/
URL: https://mmorpg.gg/palia-what-we-know/

- Party size: 4 (matching activity slot limits).
- Communities smaller than typical MMO guilds to emulate cozy tight-knit feel.
- Collaborative rather than competitive social atmosphere.
- Shared activities: fishing and cooking become co-op (benefits for playing together, but solo viable).
- Design goal: "cozy" = smaller, close-knit, collaborative communities.

---

## Source 14: RuneScape / OSRS Social Design
URL: https://oldschool.runescape.wiki/w/Clan

- Clans = organised groups for PK, skilling, boss fights, minigames, or community.
- OSRS Clan Halls: private areas accessible only to clan members.
- Clan Coffer: private shared money bank — economic social binding.
- Community fragmented into thematic sub-community groups (communities of practice structure).
- Social bonds combine gameplay bonds + social bonds (described as "messy assemblage of bondage").

---

## Notes on source uncertainty

- GDC Vault content (Dynamic Events talk, Designing for Friendship) is paywalled; metadata confirmed but full content not fetched. Flag: some specifics inferred from overview descriptions only.
- Raider.io catch-22 described by Bakharev (Medium, 2026) — corroborated by community discussion but not from Blizzard or Raider.io directly.
- FFXIV sprout/mentor characterization and Burger King crown meme: community-sourced characterization from Bakharev summary; widely corroborated in FFXIV discourse.
- EVE Judgement Day heist figures (1.5 trillion ISK) from Bakharev secondary source, not primary EVE news source. Flag as approximate.
- New World shutdown date (October 2025) from Bakharev (2026) — consistent with known trajectory but not independently verified in this session.
