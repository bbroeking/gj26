# Raw Provenance: MMORPG Batch 1

Ingested: 2026-06-14
Feeds: wiki/games/mmorpg/Guild Wars 2.md, EverQuest.md, Ultima Online.md, Star Wars The Old Republic.md, Elder Scrolls Online.md

---

## Guild Wars 2 (2012, ArenaNet)

**Sources fetched:**
- https://wiki.guildwars2.com/wiki/Dynamic_event — official GW2 wiki; full FSM description (Active/Success/Fail/Ready/Preparation states), cooperative reward structure (100% XP per participant, individual loot), anti-griefing rules (no player-triggered fail conditions), scaling up to 100 players for bosses like The Shatterer.
- https://www.guildwars2.com/en/news/the-megaserver-system-world-bosses-and-events/ — official ArenaNet announcement (2014); megaserver pools all servers, dynamic zone instancing, synchronized boss timers (hard-core ~8h, standard ~30min, low-level ~15min), guild consumable for boss triggers.
- https://gdcvault.com/play/1013691/Designing-Guild-Wars-2-Dynamic — GDC talk by Eric Flannum and Colin Johanson on dynamic events design philosophy (requires GDC Vault account; surfaced in search but not fully fetched).
- https://gdcvault.com/play/1016640/Guild-Wars-2-Programming-the — GDC talk on GW2 tech (requires account; not fully fetched).
- https://www.gamedeveloper.com/business/arenanet-details-the-tech-powering-i-guild-wars-2-i-at-gdc-online — primarily an announcement of GDC talk; confirmed hot-patch system (builds in minutes, no downtime).
- https://en.wikipedia.org/wiki/Guild_Wars_2 — engine is modified GW1 proprietary engine with true 3D, new lighting/animation/cinematic systems.

**Key facts confirmed:**
- Dynamic events use FSM with chained outcomes (success/fail produce new events).
- No kill-stealing: all participants get 100% XP and individual loot.
- Megaserver (2014) unified all per-server worlds; zone instances spin up dynamically.
- No holy trinity: all classes self-heal; roles are fluid.
- Horizontal progression: level cap 80, end-game is cosmetic/mastery not stat inflation.
- GDC talks exist for both dynamic events design and tech; full content requires Vault access.

---

## EverQuest (1999, Verant Interactive / Sony Online Entertainment)

**Sources fetched:**
- https://spectrum.ieee.org/engineering-everquest — IEEE Spectrum deep-dive (2005); 1,500+ servers in 13 data centers, "Death Star" facility in San Diego (500+ servers, 30km cabling), zone-based world (20–30 dual-CPU servers per world), 2,500 concurrent per world / 10,000 stored. Launch: 12 worlds/100K players; 2005: 52 worlds/500K players. Just-in-time computing: zone processes launched dynamically on player entry.
- https://www.gamedeveloper.com/business/everquest-20-years-of-retention — internal Daybreak analysis; EQ satisfies social belonging, self-esteem, self-actualization (Maslow tiers); retention strategy = protect core motivations while evolving mechanics; death penalty evolution: XP loss → recoverable XP → reduced sting as content grew.
- https://psychopomp.com/quite-deadly-everquest/ — player account of death mechanics; XP bar reduction, level loss possible, corpse retrieval hours away, cleric resurrection partially restores XP, lag deaths/trains/boat glitches were common, harsh penalties created genuine fear and community bonds.
- https://wiki.project1999.com/Quinlamin's_Comprehensive_Guide_To_Everquest — EQ's trinity is Tank/Healer/Slower (not DPS); dungeon camps on 20–27 minute respawn timers; Monk puller (Feign Death split-pulling) as 4th key role.
- https://forums.mmorpg.com/discussion/392921/the-original-eq-trinity-is-not-the-trinity-of-today — original trinity: Tank/Healer/Slower, not Tank/Healer/DPS; DPS was incidental.
- https://en.wikipedia.org/wiki/EverQuest — True3D engine; Verant absorbed by SOE June 2000; Planes of Power expansion added graveyards, eroded class interdependency.

**Key facts confirmed:**
- Corpse run: body stays at death location with all inventory; respawn at Bind point.
- Original trinity: Tank / Healer / Slower (crowd control), not the modern Tank/Heal/DPS model.
- Dungeon camping: static 20–30 min respawn timers, groups claim camp spots.
- IEEE Spectrum source is canonical for EQ server engineering.

---

## Ultima Online (1997, Origin Systems / EA)

**Sources fetched:**
- https://en.wikipedia.org/wiki/Ultima_Online — release Sept 24, 1997; Origin Systems (EA subsidiary); Richard Garriott producer, Raph Koster lead designer; first commercially successful MMORPG; pioneer of persistent player housing, skill-based classless progression, server shards.
- https://www.raphkoster.com/games/snippets/did-players-destroy-the-uo-ecology/ — Raph Koster's own account: the ecology system assigned resource values to creatures drawn from a shared pool; players depleted it through economic hoarding (sheep→wool→shirts for skill gain), not direct slaughter; AI disabled in beta due to computational cost (radial search + pathfinding); resource values remained in code for decades; Zach Simpson's "In-Game Economics of Ultima Online" coined "faucet-drain economy."
- https://massivelyop.com/2018/01/06/richard-garriott-talks-about-how-players-destroyed-ultima-onlines-ecology/ — Garriott's account: "all the players went in and just killed everything; so fast that the game couldn't spawn them fast enough." [Note: Garriott attributes failure to direct killing; Koster's account is more nuanced. Koster's account from Raph Koster's own blog is likely more accurate on the mechanism — the resource pool, not direct extinction.]
- https://gametyrant.com/news/ultima-online-spent-3-years-developing-systems-that-were-destroyed-by-players — confirms 3 years of ecology system development; removed during beta.
- https://www.uoguide.com/Felucca — Felucca allows non-consensual PvP and looting; housing permitted in both facets.
- https://ultima.fandom.com/wiki/Trammel_(facet) — Trammel introduced in UO: Renaissance (April 3, 2000); mirror of original map; no non-consensual PvP; nearly all non-PvP players migrated to Trammel within months.

**Key facts confirmed:**
- Ecology failure: resource pool depleted by player optimization (skill-grinding), not ecological balance. Koster coined faucet-drain economy concept from this failure.
- Player housing: persistent in world map, not instanced.
- Trammel/Felucca split: April 2000 (Renaissance expansion), not 1997 launch.
- Shards: multiple parallel worlds coined from Black Gate lore.
- Skill-based, classless.

**Flag:** Garriott's account (direct killing) vs. Koster's account (economic hoarding) differ. Koster's version from his own blog is the more technically accurate account.

---

## Star Wars: The Old Republic (2011, BioWare Austin / EA)

**Sources fetched:**
- https://en.wikipedia.org/wiki/Star_Wars%3A_The_Old_Republic — launch Dec 20, 2011; BioWare Austin lead + BioWare Edmonton support; Guinness record: largest voice-over project ever, 200,000+ lines; estimated budget $150–200M; ~$1B lifetime revenue by 2019; peaked 1.7M subscribers, fell below 1M within months; free-to-play Nov 2012; transitioned to Broadsword Online Games 2023. Engine: HeroEngine (Simutronics).
- https://www.swtor.com/info/news/blog/20111007 — BioWare developer blog on companion system: AI toggles per ability (auto/manual), companion substitutes for disconnected group members, explicitly limited for boss-level content requiring human coordination.
- https://www.escapistmagazine.com/BioWare-Fully-Voiced-Old-Republic-Was-a-Dumb-Thing-to-Try/ — BioWare quote calling full voicing "a massively insane expenditure and hugely complicated" (403 on fetch; content from search result).
- https://forums.mmorpg.com/discussion/354305/if-it-is-true-that-swtor-cost-near-500mil — community analysis; voice acting cited as primary cost driver; multi-million dollar voice budget estimate; $500M figure is unverified rumor, $150–200M development estimate is more credible.
- https://www.engadget.com/2012-07-24/the-soapbox-mmos-waste-millions-on-voice-over.html — editorial arguing MMO voice-over is waste; context for cost-vs-engagement debate.

**Key facts confirmed:**
- 200,000+ lines of dialogue; 200+ voice actors; Guinness record holder.
- Budget estimated $150–200M; revenue ~$1B by 2019.
- HeroEngine caused performance issues at launch.
- Companion system: 5 per class, fully voiced, romance options, asynchronous crafting, combat role-fill.
- Free-to-play conversion Nov 2012 after fast subscriber decline.

---

## Elder Scrolls Online (2014, ZeniMax Online Studios / Bethesda)

**Sources fetched:**
- https://en.wikipedia.org/wiki/The_Elder_Scrolls_Online — launch April 4, 2014; ZeniMax Online Studios; proprietary engine; megaserver from launch (NA + EU only, no realm select); moved to buy-to-play June 2015; One Tamriel (Update 12) Oct 5, 2016 PC, Oct 18 consoles.
- https://en.uesp.net/wiki/Online:One_Tamriel — (403 on fetch; content from search). One Tamriel: all PvE zones scale to player level; Alliance zone-access restrictions removed; drops zone instance count by ~2/3 by collapsing per-Alliance zone copies.
- https://www.gamedeveloper.com/production/-i-elder-scrolls-online-i-dev-speaks-to-the-power-of-megaservers-in-mmo-game-design — Matt Firor quote: "the game kinda figures out how many instances of each zone to spin up, and which one to put you in." Megaserver = cluster of servers presented as single logical unit; dynamic instancing; social heuristics group friends/guildmates.
- https://elderscrollsonline.info/mega-server — megaserver houses all players on one logical server in different world instances; zones spawn 10/20/30+ instances at peak, merge during off-peak; eliminates server queues and empty zones.
- https://massivelyop.com/2016/06/15/tamriel-infinium-the-pros-and-cons-of-elder-scrolls-onlines-one-tamriel-level-syncing/ — (403 on fetch; content from search). Pros: freedom, group flexibility, all content relevant. Cons: some players missed defined progression gates.
- https://elderscrolls.fandom.com/wiki/Megaserver — NA and EU megaservers; players never pick a realm; dynamic zone instancing.

**Key facts confirmed:**
- Megaserver from day one (2014), NA + EU only.
- One Tamriel (Oct 2016): level scaling to all zones, Alliance restrictions removed.
- Enemy scaling upward to match player level (not player de-scaling downward).
- Server-side: One Tamriel reduced zone instance count by ~2/3.
- Matt Firor is game director and primary public spokesperson for architecture decisions.
- ESO Plus subscription retained value via Craft Bag (unlimited crafting material storage) — not content locks.

---

## Pages written

| File | Summary |
|------|---------|
| wiki/games/mmorpg/Guild Wars 2.md | Dynamic events FSM, megaserver, no-trinity, horizontal progression |
| wiki/games/mmorpg/EverQuest.md | Corpse runs, Tank/Healer/Slower trinity, dungeon camp culture, IEEE Spectrum server engineering |
| wiki/games/mmorpg/Ultima Online.md | Ecology experiment failure, faucet-drain economy, Trammel/Felucca PvP split, shard invention |
| wiki/games/mmorpg/Star Wars The Old Republic.md | Fully-voiced MMO, 200K lines, HeroEngine, companion async crafting, fast sub collapse |
| wiki/games/mmorpg/Elder Scrolls Online.md | One Tamriel level scaling, megaserver architecture, no realm selection, Craft Bag retention |
