# World of Warcraft — Raw Provenance Notes

Bullet facts extracted from fetched sources. Immutable record; wiki page synthesizes from here.
Compiled 2026-06-13.

---

## Expansion Timeline

- **Launch**: November 23, 2004. World of Warcraft (Vanilla).
- **The Burning Crusade (TBC)**: January 2007 — level cap 60→70, Outland, flying mounts, Heroic dungeon difficulty introduced, first PvP arenas.
- **Wrath of the Lich King (WotLK)**: 2008 — level cap 70→80, 10/25-man raid split with shared lockout.
- **Cataclysm**: December 2010 — rebuilt 1-60 world, talent tree first major overhaul (41 pts down from 71); peak subs preceded Cataclysm.
- **Mists of Pandaria (MoP)**: 2012 — talent trees replaced by 6-tier 18-choice grid (6 rows × 3 choices); daily quests expanded massively (~54/day on Pandaria alone, pool of ~278).
- **Warlords of Draenor (WoD)**: 2014 — Garrisons (player housing lite); Mythic difficulty added to raids and dungeons (patch 6.0/6.2); sharding introduced (patch 6.0.2, October 2014); WoW Token launched April 2015 ($20 USD → in-game gold or 30 days game time).
- **Legion**: 2016 — Mythic+ dungeons added (patch 7.0.3, July 19 2016), replaced Challenge Mode; Artifact Weapons (spec-locked power); zone scaling added for Broken Isles; World Quests replaced daily quests; Legion Honor system with PvP-exclusive talents.
- **Battle for Azeroth (BfA)**: 2018 — Azerite system (Heart of Azeroth neck gear replacing tier sets).
- **Shadowlands**: 2020 — Covenant system; Conduits; Great Vault (weekly chest) introduced; level squish (120→60).
- **Dragonflight**: November 28, 2022 — dual talent trees (Class Tree + Spec Tree) restored; profession revamp with quality tiers, Crafting Orders, and specializations.
- **The War Within (TWW)**: 2024 — begins Worldsoul Saga trilogy; Delves (solo-ish instanced content) added to Great Vault.
- **Midnight**: March 2, 2026 — second Worldsoul Saga expansion. Player Housing confirmed.
- As of Feb 2026: 10 released expansions, 11th (Midnight) launched March 2 2026.
- Sources: https://noping.com/blog/world-of-warcraft-expansion-packs-in-order, https://wowpedia.fandom.com/wiki/Expansion

---

## Subscriber Numbers

- Peak subs: 12 million worldwide, October 2010 (Blizzard press release, confirmed by investor.activision.com).
- Q1 2011: 11.4 million (−600k after Cataclysm launch honeymoon).
- Last officially reported subs: 5.5 million (2015, after Blizzard stopped reporting).
- Estimated 2026: ~7.25 million (third-party estimate; Blizzard does not publish).
- Sources: https://investor.activision.com/news-releases/news-release-details/world-warcraftr-subscriber-base-reaches-12-million-worldwide, https://headphonesaddict.com/world-of-warcraft-player-count/

---

## Server Architecture

### Realm System
- As of 2009: 700+ realms served by 10 data centers (WA, CA, TX, MA, FR, DE, SE, KR, CN, TW); 13,250 server blades; 75,000 CPU cores; 112.5 TB blade RAM; 1.3 PB total storage.
- Operations staff: 68 people managing the GNOC.
- AT&T provided data center facilities and network management (2009 figure).
- Source: https://www.datacenterknowledge.com/archives/2009/11/25/wows-back-end-10-data-centers-75000-cores

### Sharding
- Introduced: patch 6.0.2 (October 2014) for WoD launch.
- Mechanism: when a zone exceeds player density threshold, the server automatically creates a new "shard" — a copy of that zone. Incoming players are placed on shards; players on different shards cannot see each other; each shard has its own NPC and resource-node spawns.
- Players are re-sharded when: joining a party in same zone, toggling War Mode, using Chromie Time.
- Currently: enabled on all retail Normal realms; disabled by default on RP realms but activated if server stability requires.
- Source: https://warcraft.wiki.gg/wiki/Sharding_(term)

### Layering
- Identical to sharding but realm-wide (all zones).
- Used for WoW Classic launch to alleviate overcrowding; later removed.
- Source: https://blizzardwatch.com/2019/05/14/say-goodbye-sharding-wow-classic-will-use-new-layering-system-manage-server-population/

### Phasing
- Distinct from sharding: changes world appearance to match player's story progression (e.g. post-Wrathgate Icecrown).
- Players in different phases cannot see each other.
- Party Sync allows progression-mismatched players to share the party leader's phase.
- Source: https://warcraft.wiki.gg/wiki/Sharding_(term)

### Cross-Realm Zones (CRZ)
- Purpose: prevent undercrowding (opposite of sharding); combines players from multiple realms into a single zone instance.
- Matches servers of same type (PvE/PvP/RP) from the same datacenter within 3 hours of your server time.
- Connected Realms (patch 5.4, 2013): permanently merge low-pop realms at the server level — they share the same world space as though one realm.
- Source: https://wowpedia.fandom.com/wiki/Cross-realm_zones, https://wowwiki-archive.fandom.com/wiki/Connected_Realms

---

## Spell Batching (Combat Tick)

- Original WoW combat tick: **400ms batch window**. Blizzard quote: "Any action that one unit takes on another different unit used to be processed in batches every 400ms."
- Self-cast actions (healing yourself, self-buffs): applied **instantly**, not batched.
- Batched actions (damage, healing others, buff/debuff application, knockback, interrupts): queued; apply at next batch window.
- Workflow: attack table roll + hit/miss + damage calc happen IMMEDIATELY when cast resolves → effect application enters batch queue → applies at next 400ms window.
- Pre-WoD (before Warlords of Draenor): always a 400ms batch window.
- Post-WoD (improved servers): batch window ~20ms.
- WoW Classic (original launch): 10ms batch window (not 400ms; Blizzard changed it for Classic 1.13).
- Gameplay consequence: both a warrior Pummel and a mage Polymorph could succeed simultaneously if both entered the same 400ms batch (each was valid at batch-start). Led to "both warriors stunned at original positions" double-charge scenarios.
- Source: https://github.com/magey/classic-warrior/wiki/Spell-batching

---

## Talent Trees — Full History

### Original System (Launch → Wrath)
- 51 talent points at cap (grew to 71 points by end of WotLK).
- Three trees per class; 31-pt capstone talents.
- Problems: >80 talents per class; passive talents everyone took regardless of playstyle; overpowered cross-tree hybrid builds; 30-50% performance gap between specs.
- Source: https://blizzardwatch.com/2022/10/31/wow-cataclysm-talent-trees/

### Cataclysm Revamp (2010)
- 41 talent points; 31-pt capstones.
- Players forced to spend 31 pts in their main tree before branching.
- Cut "passive talents that everyone took anyway, or really lame talents."
- Level 10 spec selection added; Mastery stat introduced (delays complexity to higher levels).
- Result: 5-10% performance variance vs previous 30-50%.
- Remaining issues: "trap" talents; few hard decisions per spec; awkward %-chance mechanics.
- Source: https://worldofwarcraft.blizzard.com/en-us/news/2878505/dev-watercooler-cataclysm-talent-tree-post-mortem

### Mists of Pandaria (2012)
- Talent trees abandoned entirely. Replaced with 6-tier grid: 6 rows × 3 choices = 18 talents.
- One choice per row, rows unlocked at levels 15/30/45/60/75/90.
- Trees absent from MoP through end of Shadowlands (a decade without trees).
- Source: search results

### Legion / BfA (2016-2020)
- Artifact Weapons: spec-locked alternate progression with AP (Artifact Power); expanded talent-like nodes on the artifact.
- BfA: Heart of Azeroth necklace + Azerite armor replaced tier sets with proc-based traits.
- Neither system is called "talent trees."
- Source: expansion wiki entries

### Dragonflight Dual Trees (Nov 2022)
- Full branching talent trees restored after ~10-year absence.
- TWO trees per spec: Class Tree (universal class abilities, utility) + Specialization Tree (role-specific power).
- Points divided equally between the two; cannot dump all into one.
- Gate mechanics: 8 points required to unlock Row 5+; 20 points for Row 8+.
- Choice nodes (octagonal) = mutually exclusive options at a node.
- Design rationale: "increase player agency"; "meaningful rewards while leveling"; prevents utility sacrifice for pure DPS.
- Save/share talent loadouts supported.
- Source: https://news.blizzard.com/en-us/world-of-warcraft/23797209/world-of-warcraft-dragonflight-talent-preview, https://blizzardwatch.com/2022/10/31/wow-cataclysm-talent-trees/

---

## Classes and Specializations

- 13 classes (as of Midnight era): Warrior, Hunter, Mage, Rogue, Priest, Warlock, Paladin, Druid, Shaman, Monk, Demon Hunter, Death Knight, Evoker.
- 39 total specializations: 6 tank, 7 healer, 13 ranged DPS, 13 melee DPS. Most classes = 3 specs; Druid = 4 specs; Demon Hunter = 2 specs.
- Holy Trinity (Tank/Healer/DPS) underpins group content design.
- Source: https://warcraft.wiki.gg/wiki/Specialization

---

## Dungeon and Raid Instancing

### Lockout System
- Lockout prevents repeated instance farming.
- Introduced: patch 1.9.0 (2006) — moved from absence-based resets to fixed calendar resets.
- Raids + Mythic dungeons: weekly reset (Tuesday in Americas, Wednesday in EU).
- Heroic dungeons: daily reset at 9:00 AM (7:00 AM EU).
- Types:
  - **ID-based (hard lockout)**: classic raids (Molten Core → Sunwell) and Mythic raids — bound to specific instance ID.
  - **Loot-based (soft lockout)**: LFR and Normal/Heroic raids since Siege of Orgrimmar — can re-enter but only loot once/week per difficulty.
  - **Flexible boss-based**: Normal raids WotLK → Throne of Thunder — can kill each boss once/week across groups.
- Source: https://warcraft.wiki.gg/wiki/Lockout

### Difficulty Tier History
- **Vanilla (2004)**: Normal only; raids were 40-man (most), 20-man (ZG, AQ20), 10-man (UBRS).
- **TBC (2007)**: Heroic dungeons introduced; most raids 25-man; Karazhan + Zul'Aman = 10-man.
- **WotLK (2008)**: Raids gained variable difficulty (N/HC); patch 3.3.0 allowed per-boss difficulty switching.
- **Cataclysm (2010)**: LFR (Raid Finder) introduced with Dragon Soul — flexible 10-25 players, lower loot quality.
- **WoD (2014)**: Mythic difficulty added (fixed 20-player; no flexible scaling).
- **Legion (2016)**: Mythic+ added (patch 7.0.3).
- **Current**: LFR (10-30), Normal (10-30), Heroic (10-30), Mythic (fixed 20) for raids; Normal, Heroic, Mythic, Mythic+ for dungeons.
- Source: https://warcraft.wiki.gg/wiki/Instance_difficulty, https://warcraft.wiki.gg/wiki/Lockout

### Mythic+ System (Legion 2016)
- Introduced patch 7.0.3 (July 19, 2016), replacing Challenge Mode.
- 5-player Mythic dungeons with a Keystone (consumable item) that sets the level and affixes.
- Completing within timer: Keystone upgrades by 1+ level. Failing timer: key depletes (still progresses but at lower level next week or degrades).
- Affixes (weekly rotating) stack as key level increases: e.g. Tyrannical/Fortified at M+10, additional affixes at M+4 and M+7.
- Loot in Legion: 2 items at end chest; beating timer = 3rd item. Modern: Great Vault tracks Mythic+ completions.
- Mythic+ Rating system (introduced later) replaced the raw key level metric.
- Source: https://wowpedia.fandom.com/wiki/Mythic%2B (403; data from search), https://maxroll.gg/wow/resources/mythic-dungeon-mechanics

### Great Vault (Weekly Chest)
- Introduced: Shadowlands (patch 9.0).
- Predecessor: Grand Challenger's Bounty (Legion/BfA M+ chest) and War Chest (PvP).
- Structure: up to 9 choices; player picks 1 per week. Three categories: Raids, Dungeons, World.
- Raid slot: defeat 3/6/9 bosses for 1/2/3 choices.
- Dungeon slot: complete Heroic+ dungeons (number thresholds vary by patch).
- World slot (TWW era): Delves and world events; PvP removed from Vault in TWW.
- Resets weekly.
- Source: https://warcraft.wiki.gg/wiki/Great_Vault

---

## Quest System Design

- Scale: 600 quests at original design goal → 2,600 at Vanilla launch → 7,650 by WotLK.
- Quest text hard-capped at 511 characters (Blizzard design rule for clarity).
- GDC talk by Jeff Kaplan (lead designer) identified key design failures:
  - **Christmas Tree Effect**: too many quests at a hub simultaneously → players complete arbitrarily, bypassing narrative.
  - **Collection quest failures**: arbitrary gathering, bad creature density, excessive inventory management, RNG "shitty streaks."
  - **Gimmick quests** (vehicle mechanics): more fun for designer than player.
  - **Poor quest writing**: ego-driven verbosity.
  - **Mystery mishandling**: vague objectives force players to external guides.
- Design solutions: progressive drop rates (guarantee acquisition through increasing kill-per-% chance); breadcrumb quests (waypoints between hubs); hub-and-spoke flow (introduced strongly in TBC); interface clarity (minimap markers, quest log, instant feedback).
- **World Quests** (Legion): replaced fixed daily quests on the Broken Isles; semi-weekly reset (Dragonflight changed from daily to semi-weekly after player feedback about feeling "pressured").
- Source: https://www.gamedeveloper.com/game-platforms/gdc-learning-from-i-world-of-warcraft-i-s-quest-design-mistakes

---

## Leveling and Zone Design

- Vanilla: linear level 1-60 through fixed zones; no scaling.
- TBC: level 60-70, Outland.
- Zone scaling: added with Legion Broken Isles (patch 7.0); applied to rest of world in patch 7.3.5.
- Patch 9.0.1 (Shadowlands pre-patch): Chromie Time system — 1-10 (new starting zones), then one expansion's zones scale to 50; players can do almost all of one expansion's story in one playthrough.
- Level squish history: 120→60 in Shadowlands (9.0), making expansion treadmill more visible.
- Content obsolescence: all gear from previous expansion replaced by first green items in new expansion zones.
- Remix seasons: repackaged older expansions with accelerated leveling (e.g., MoP Remix).
- Source: https://wowpedia.fandom.com/wiki/Zone_scaling, search results

---

## Professions and Economy

### Profession Structure
- Gathering professions: Mining, Herbalism, Skinning, Fishing — gather raw materials from nodes in the world.
- Production professions: Blacksmithing, Alchemy, Tailoring, Leatherworking, Engineering, Jewelcrafting, Enchanting, Inscription, Cooking.
- Service professions: Enchanting (applying to others), some crafting via Crafting Orders.
- Max characters can have 2 primary professions; unlimited secondary professions (Cooking, Fishing, First Aid historically).
- Skill 1-525 (Cataclysm era; varies by expansion).
- Dragonflight revamp: "quality" added to gathered materials and crafted items; higher quality = higher ilvl gear or stronger potions; Crafting Orders = AH-like requests for cross-player crafting; profession specialization trees added.
- Source: https://warcraft.wiki.gg/wiki/Profession, https://dotesports.com/news/everything-to-know-about-the-new-crafting-and-profession-system-in-world-of-warcraft-dragonflight

### Auction House and Economy
- AH = primary market mechanism for player-to-player trade.
- Vanilla economy: gold scarce, mostly direct trade and guild crafting; AH less active.
- TBC/WotLK: daily quests added reliable income → prices rose, gold became easier to acquire.
- Cataclysm: gold inflation became significant design problem.
- Gold sinks: repair costs, expensive mounts, service fees (realm transfer, name change), Blizzard-designed purchases.
- WoW Token (April 2015, WoD era): $20 USD → in-game gold (price varies by server economy) OR 30 days game time. Creates official real-money → gold pathway. Stabilized some inflation by giving gold a real-money floor/ceiling, but created tighter real-money/gold link.
- Source: https://alteil.com/wows-economy-over-the-years-how-gold-and-trading-have-evolved/, https://meminsf.silverstringmedia.com/labour/a-history-of-world-of-warcrafts-gold-economy/

---

## PvP System

- Vanilla: world PvP only initially; Honor system added (patch 1.4/1.5) — rank-based gear gating with weekly rank recalculation; Dishonorable Kills for NPC murder.
- Battlegrounds: Warsong Gulch (capture the flag), Arathi Basin (domination), Alterac Valley (territory control); players traveled to BG entrances.
- TBC: Arenas (2v2, 3v3, 5v5) introduced; first PvP season; rating-based rewards (Gladiator, Rival, Challenger titles); arena rating = gear access.
- TBC–WotLK: Honor points as currency to buy PvP gear.
- Legion: Honor system reworked — honor points became a leveling currency (PvP levels); first true PvP-exclusive talent rows (separate from PvE talent trees).
- Rated Battlegrounds: introduced in Cataclysm — 10v10 organized rated BGs with rating/rewards parallel to arenas.
- Source: search results, https://wowpedia.fandom.com/wiki/Honor_system

---

## Addon / Lua API

- WoW ships with a Lua runtime exposed to AddOns and macro scripts.
- AddOn structure: `.toc` (manifest, Interface version), `.lua` (logic), optional `.xml` (UI frame definitions).
- API namespaced under `C_*` prefix (266+ systems documented as of patch 12.0.5 / April 2026).
- Security model:
  - **Hardware event (#hwevent)**: certain functions (e.g. cast spell, interact with NPC) only executable from genuine user input events — prevents bots from automating gameplay.
  - **#noscript**: functions unavailable inside restricted secure frames.
  - **#framexml**: FrameXML-only functions, not available to third-party addons.
- Lua version history: launched on Lua 5.0; upgraded to Lua 5.1 with TBC (January 2007) gaining vararg system + incremental GC; sandboxing prevented addon use of `package/require`.
- Official documentation: `/api` in-game command; `Blizzard_APIDocumentation` in the client.
- Notable capabilities: unit frames, combat log parsing, action bars, minimap, auction scanning, raid/boss timers (DBM, BigWigs).
- Key restriction: addons cannot programmatically cast spells, move the character, or interact with NPCs without genuine hardware events.
- Source: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API, https://www.lua.org/wshop08/lua-whitehead.pdf

---

## Garrisons (Player Housing Lite)

- Introduced: Warlords of Draenor (2014).
- Player claims a plot of land in Draenor; upgrades through 3 tiers; chooses which buildings to place (determines benefits and follower missions).
- Followers: sent on missions to gather mats, reducing farming.
- Social problem: players stayed in Garrisons instead of using cities — killed organic social hubs.
- Player housing (true): announced for Midnight (launched March 2, 2026).
- Source: https://kotaku.com/world-of-warcrafts-coolest-new-feature-garrison-build-1461162733

---

## Reputation / Retention Systems

- Reputation factions: Friendly → Honored → Revered → Exalted (4 tiers post-Friendly; 5 including Neutral).
- Reputation gates access to faction gear, recipes, mounts, titles.
- Daily quests: introduced TBC patch 2.1 (Netherwing, Ogri'la, Sha'tari Skyguard); initial cap 10/day; raised to 25/day; removed entirely in patch 5.0 (MoP).
- MoP: ~54 dailies/day possible from a pool of ~278 (player backlash: "daily quest burnout").
- Legion World Quests: replaced dailies; semi-weekly (or daily) rotation; map-scattered rather than hub-based; scaled reward quality.
- Dragonflight: World Quests moved to semi-weekly reset after player pressure-complaint.
- Shadowlands Covenants: 4 Covenants each with unique abilities, cosmetics, story; players locked into one per character per patch — major design controversy; opened cross-Covenant in later patches.
- Source: search results, https://wowpedia.fandom.com/wiki/Daily_quest

---

## Gear Treadmill / Expansion Power Reset

- All expansion gear becomes obsolete with first quests of next expansion (early greens outscale previous tier gear).
- Item level inflation: each expansion raises ilvl ceiling by ~100-200+ points.
- Within-expansion treadmill: LFR < Normal < Heroic < Mythic ilvl tiers; new raid tier each major patch obsoletes previous tier.
- Borrowed power systems per expansion: Artifact Weapons (Legion), Azerite/Heart of Azeroth (BfA), Covenants+Conduits (Shadowlands) — each fully deleted at next expansion.
- Great Vault mitigates RNG by guaranteeing one loot choice per week.
- Sources: https://blizzardwatch.com/2021/05/28/eternal-leveling-price-endgame/, search results

---

## Source URLs Used

1. https://warcraft.wiki.gg/wiki/Sharding_(term)
2. https://blizzardwatch.com/2019/05/14/say-goodbye-sharding-wow-classic-will-use-new-layering-system-manage-server-population/
3. https://github.com/magey/classic-warrior/wiki/Spell-batching
4. https://wowpedia.fandom.com/wiki/Talents_(history) (403; data from search + BlizzardWatch)
5. https://blizzardwatch.com/2022/10/31/wow-cataclysm-talent-trees/
6. https://worldofwarcraft.blizzard.com/en-us/news/2878505/dev-watercooler-cataclysm-talent-tree-post-mortem
7. https://news.blizzard.com/en-us/world-of-warcraft/23797209/world-of-warcraft-dragonflight-talent-preview
8. https://warcraft.wiki.gg/wiki/Lockout
9. https://warcraft.wiki.gg/wiki/Instance_difficulty
10. https://wowpedia.fandom.com/wiki/Mythic%2B (403; data from search)
11. https://maxroll.gg/wow/resources/mythic-dungeon-mechanics
12. https://warcraft.wiki.gg/wiki/Great_Vault
13. https://www.gamedeveloper.com/game-platforms/gdc-learning-from-i-world-of-warcraft-i-s-quest-design-mistakes
14. https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
15. https://www.datacenterknowledge.com/archives/2009/11/25/wows-back-end-10-data-centers-75000-cores
16. https://investor.activision.com/news-releases/news-release-details/world-warcraftr-subscriber-base-reaches-12-million-worldwide
17. https://warcraft.wiki.gg/wiki/Profession
18. https://dotesports.com/news/everything-to-know-about-the-new-crafting-and-profession-system-in-world-of-warcraft-dragonflight
19. https://wowpedia.fandom.com/wiki/Daily_quest
20. https://wowpedia.fandom.com/wiki/Cross-realm_zones
21. https://wowwiki-archive.fandom.com/wiki/Connected_Realms
22. https://noping.com/blog/world-of-warcraft-expansion-packs-in-order
23. https://headphonesaddict.com/world-of-warcraft-player-count/
24. https://alteil.com/wows-economy-over-the-years-how-gold-and-trading-have-evolved/
25. https://kotaku.com/world-of-warcrafts-coolest-new-feature-garrison-build-1461162733
