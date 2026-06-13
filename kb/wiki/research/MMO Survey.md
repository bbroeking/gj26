---
type: concept
tags: [mmo-research, design-influences, economy, multiplayer, combat, architecture, itemization, progression]
status: draft
updated: 2026-06-13
sources:
  - https://www.raphkoster.com/games/snippets/did-players-destroy-the-uo-ecology/
  - https://www.raphkoster.com/games/snippets/a-uo-postmortem-of-sorts/
  - https://gdcvault.com/play/1016629/Classic-Game-Postmortem-Ultima
  - https://en.wikipedia.org/wiki/Ultima_Online
  - https://en.wikipedia.org/wiki/EverQuest
  - https://psychopomp.com/quite-deadly-everquest/
  - https://www.gamedeveloper.com/design/rethinking-the-trinity-of-mmo-design
  - https://www.guildwars2.com/en/news/guild-wars-2-design-manifesto/
  - https://www.guildwars2.com/en/news/the-megaserver-system-world-bosses-and-events/
  - https://wiki.guildwars2.com/wiki/Dynamic_level_adjustment
  - https://en.wikipedia.org/wiki/Lineage_II
  - https://en.wikibooks.org/wiki/Lineage_2/Castle_Sieges
  - https://www.invenglobal.com/articles/20251/under-siege-by-bot-farms-lineage-classics-growing-crisis
  - https://en.wikipedia.org/wiki/Path_of_Exile
  - https://www.gamedeveloper.com/design/path-of-exile-economy-currency-trading
  - https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
  - https://en.wikipedia.org/wiki/Albion_Online
  - https://lucasgraphic.com/posts/project-gorgon-a-weirdly-deep-old-school-mmorpg
---

# MMO Survey

A breadth survey of the most influential massively multiplayer online games — design innovations and notable implementation traits — assembled as reference for [[Design Influences]] and the broader [[MMO Research]] cluster. Each entry covers what the title pioneered in design and any structural or architectural distinction relevant to Wayfinder.

Raw provenance (all facts + source URLs): `kb/raw/mmo/survey.md`.

---

## Ultima Online (1997)

**What it pioneered:** open-world sandbox, player housing, skill-based progression without levels, the first large-scale online economy, and the concept of sharded server architecture.

Ultima Online launched September 24, 1997 and reached 100,000 subscribers within six months, peaking at roughly 250,000 in July 2003. Its most radical design choice was rejecting levels entirely: characters advanced every skill by using it, unconstrained by class. This usage-based model meant a player could be a master blacksmith and a journeyman swordsman simultaneously, with no prescribed path.

**Player housing** was placed directly in the open world — a persistent, claimable piece of land that could be furnished and used as a shop. Raph Koster described townstones (guild halls with shared storage) as the feature he most wished had shipped complete; the housing system became the template every subsequent MMO iterated on.

**The ecology collapse** is UO's most-cited design autopsy. Koster built an AI "Artificial Life" engine where every creature had discrete resource values (meat, hide, feathers). The intent was a living ecosystem: kill too many rabbits, rabbit populations fall, wolves that hunted rabbits decline, and so on. It was removed during beta — not because players killed everything, but for two compounding reasons. First, the CPU cost of radial pathfinding searches was prohibitive at scale. Second, and more instructively, player hoarding disrupted the closed resource pool: players killed sheep to farm wool, crafted thousands of shirts for skill XP, and hoarded the shirts rather than letting resources re-enter circulation. The pool drained; no new sheep spawned. Economist Zach Simpson's subsequent paper "In-Game Economics of Ultima Online" coined the phrase **faucet-drain economy** to describe the failure mode. Koster's own postmortem conclusion: "Closed economies can't work."

**The shard model** originated here as both a technical necessity and a narrative fiction. One server could not handle the load, so multiple parallel copies of the world were run. Koster named them "shards" in lore: in *Ultima I* the hero shattered the villain Mondain's Gem of Immortality, each fragment containing a full copy of the world Sosaria. Each server was therefore one shard. The word entered the wider industry as the standard term for parallel-world server architecture. Technically, shards ran on clusters of Sun Microsystems hardware running Solaris.

**The PvP problem** was existential. Unrestricted open PvP drove players out by the thousands through griefing. Koster initially resisted safe/wild zoning — he believed players would self-regulate — but the data proved otherwise. The Renaissance expansion (May 2000) introduced Trammel (consensual PvP) and Felucca (unrestricted PvP), mirrored worlds that let players self-select their risk level. Koster later wrote that safe/wild separation was correct and mixed-PvP servers proved "not profitable and not sustainable."

**Wayfinder relevance:** the usage-based skill model directly informs [[Trades and Leveling]]; the faucet-drain lesson shapes [[Economy]]; the housing/community social structures inform [[Multiplayer Co-op]]; the open/safe zoning tension is upstream of dungeon instancing decisions.

---

## EverQuest (1999)

**What it pioneered:** the holy trinity of tank/healer/DPS, forced grouping as social glue, contested spawn camping, the severe death penalty, and zone-based server architecture as an MMO template.

EverQuest launched March 16, 1999 — the first commercially successful MMO with a fully 3D engine and the first to feature a formal guild system and raiding. Brad McQuaid designed "The Vision": a world defined by hardship, interdependence, and genuine consequence.

**Zone server architecture** divided Norrath into 500+ discrete zones (plains, dungeons, cities), each running as a separate server process. Crossing a zone boundary triggered a full loading screen and hand-off between zone servers. Cities were often split across multiple sub-zones by file size and complexity. Each named server was in practice a cluster of machines; peak visible populations exceeded 3,000 per server.

**The holy trinity** crystallized in EQ's high-end raiding. The class system sorted into four blocks — Melee (Warrior, Monk, Rogue), Priests (Cleric, Druid, Shaman), Casters (Wizard, Magician, Necromancer, Enchanter), Hybrids (Paladin, Shadowknight, Bard, Ranger, Beastlord) — with each player assigned a specific role. The canonical group composition was: a Warrior to hold aggro, a Cleric for Complete Heal and resurrection (the only class that could fully rez), and an Enchanter for crowd control (mezz) and mana regen. DPS classes were plentiful; tank and healer were bottlenecks. This supply/demand imbalance became a durable design pattern: encounter designers could predict group composition exactly and balance around it. Gamedeveloper.com's "Rethinking the Trinity of MMO Design" traces the pattern's spread directly to EQ.

**Death penalties** were catastrophic by design. Dying dropped your corpse (with all equipped gear) at the location of death and respawned you naked at your last bind point — sometimes an hour of travel away. Each death cost substantial experience; enough deaths deleted a freshly earned level. The corpse recovery was a social event: high-level Clerics would mount rescue operations, guild members would form escort parties. The psychopomp.com retrospective captures the lived experience: "a Norrath friendship built as effectively as fighting your way to somebody's corpse." The harsh penalty drove grouping as a survival strategy rather than preference.

**Contested spawns** placed rare named mobs on fixed respawn timers (often hours). Guilds and players would "camp" spawn points indefinitely, generating fierce competition for loot access. This produced server-wide social hierarchies and reputation economies — kill-stealing a spawn earned lasting enmity — but also drove communities to form alliances around shared interests and mutual threats, validating Koster's community formation thesis from UO.

**Wayfinder relevance:** the trinity design is a direct reference point for [[Combat]] (Wayfinder deliberately rejects it in favor of one-verb combat); the death penalty and risk/reward tension inform the dungeon run stakes in [[Chart Loop]]; the zone-server model is the precursor to modern instancing.

---

## Guild Wars 2 (2012)

**What it pioneered:** elimination of the holy trinity in cooperative PvE, dynamic events replacing static quest-givers, the megaserver population architecture, and universal level-downscaling to keep all content perpetually relevant.

GW2 launched August 28, 2012 as a buy-to-play title (no subscription). ArenaNet published a design manifesto that explicitly positioned the game as a rejection of established MMO conventions. The title's three most transferable design contributions:

**No holy trinity.** GW2's combat design eliminated tank, healer, and DPS specialization from open-world PvE. All players share the same objectives in events; killing a mob near other players grants everyone 100% of the XP and loot — no kill-stealing, no loot contention, no required grouping. Players work together naturally because incentives are aligned, not because a content gate forces a specific party composition. Each class can deal damage, provide support, and sustain themselves, removing the queue bottleneck caused by healer/tank scarcity.

**Dynamic events.** Static quest-givers ("!" exclamation-mark NPCs) were replaced with world-state events. Villages are assaulted by bandits; if players fail to defend, buildings burn and NPCs flee — the world reflects outcome. Events chain: success unlocks follow-up events; failure spawns a new reactive event. The design goal, stated at GDC 2012 (Flannum and Johanson), was "an exciting, living, breathing online world that encourages social interaction." The GDC session is paywalled but the manifesto blog post confirms the explicit intent.

**Megaserver (2014 retrofit).** The original server model segregated players by "world" (named server), causing population fragmentation — sparse maps on low-pop worlds, world boss timers varying server-by-server. The megaserver replaced this with dynamic map instances: a weighted load balancer reads party, guild, language, home world, and frequent co-players, then assigns each player to the optimal map copy. World boss events shifted to synchronized real-time schedules (hard-core bosses approximately every 8 hours; standard events on the hour/half-hour; low-level events at :15 and :45 past). Cross-instance state reporting was disabled because accurately tracking another map's progress was architecturally infeasible. The net result: no overflow maps, no empty worlds, no population-dependant boss scheduling.

**Dynamic level adjustment (downscaling).** Every open-world zone scales high-level players down to zone_max + 1. The formula: R = (base power stat at effective level) / (base power stat at actual level); all stats multiplied by R. Players retain their full skill loadout, equipment quality, runes, and sigils — so a high-level character remains appreciably stronger than a native-level character — but cannot trivialize the zone. Design goals: prevent high-levels from depriving low-levels of rewards; keep every zone permanently relevant. WvW and Structured PvP invert the mechanic, scaling all players up to level 80.

**Personal story** used biography questions at character creation to branch narrative, with fully instanced story chapters. This separated "my story" from shared open-world exploration — the instanced dungeon as personal narrative space.

**Wayfinder relevance:** dynamic level downscaling is a direct design option for [[Multiplayer Co-op]] (allowing higher-level players to meaningfully join low-level runs); the no-trinity design validates Wayfinder's one-verb [[Combat]] approach; dynamic events are upstream of thinking about [[Dungeon Generation]] procedural encounter variety vs. scripted quest flow; megaserver population distribution is a model for long-term [[MMO Server Architecture]] thinking.

---

## Lineage / Lineage II (2003)

**What it pioneered:** castle siege as a territorial economy mechanism, the clan as the load-bearing social unit, and the definitive case study in how bot/RMT economies destroy player-driven markets.

The original *Lineage* (1998, NCSoft, Korea) introduced the castle siege concept — the world's first massive-scale PvP battle over territory with economic consequences. *Lineage II* launched in Korea on October 1, 2003 (NA/EU: 2004) and reported 40 million unique users in a single month (March 2007), reaching 94 million total by the early 2010s.

**Castle siege design.** Seven castles exist in Aden; sieges run biweekly, each lasting exactly two hours. Any clan of level 4+ may register. Attackers must: raise a clan flag (resurrection anchor), breach the gate or walls, destroy two Life Crystals inside, then have the clan leader inscribe at a rear statue within five minutes of reaching it. Defenders win by running out the clock. The winner gains control of NPC shop tax rates in linked territories — taxes flow automatically to the castle vault, creating a direct economic return on political power. Owning a castle is also a prestige signal. The design combines asymmetric attack/defend roles, infrastructure-as-objective, timed urgency, and territory-as-economy in a way no Western MMO had previously executed at this scale.

**The bot/RMT economy crisis.** Lineage Classic's ongoing crisis (documented by Inven Global through February 2026) illustrates the structural fragility of player-driven economies at scale. Bot operations use VPNs, stolen accounts, and fully automated routines — detect mob, attack, loot, sell, reconnect under a new account when banned. A typical hunting ground shows 40 accounts with sequential numeric IDs running continuously. The flood of bot-generated Adena causes deflation: item prices converge to barely above NPC sell price, collapsing the reward loop that makes the game worth playing for legitimate players. The perverse outcome: cheap Adena makes real-money item upgrading cheaper, widening the gap between paying and non-paying players rather than closing it. NCSoft's 15 enforcement iterations (1.38 million accounts restricted as of early 2026) have not solved the problem; the Inven Global conclusion is stark: "The battle between illegal programs and security measures has no clear end." The underlying issue is structural — any competitive manual resource loop creates bot-farming incentives.

**Wayfinder relevance:** the castle siege design is upstream of any territory/endgame guild systems; the bot/RMT crisis is the definitive argument for instanced or otherwise bot-resistant [[Economy]] and [[Multiplayer Co-op]] architectures; the clan-as-social-unit (with economic stakes) is a model for guild design.

---

## Diablo / Path of Exile (ARPG-adjacent)

**What it pioneered:** randomized affix-based itemization as the core reward loop (Diablo), the no-gold barter-currency economy and seasonal league resets (Path of Exile), and fully instanced per-party areas as an alternative to shared open worlds.

These are not MMOs in the traditional sense, but both are directly upstream of Wayfinder's [[Chart Loop]], [[Affixes]], [[Items and Gear]], and [[Economy]].

**Diablo 2 itemization (2000).** The affix system established the ARPG loot paradigm: every magic, rare, and crafted item generates with randomly selected prefixes and suffixes drawn from weighted frequency tables. Item level and rarity cap affix count and available pools. Unique items have fixed stats; rares are fully random within type constraints; the best sword in the game can have a damage roll anywhere from 230% to 270%, driving the "hunt for GG item" loop indefinitely. No personal loot: all co-op loot dropped in a shared pile, creating friction and trade incentives simultaneously. Diablo 2's itemization is routinely cited as the genre's foundational template; Path of Exile was built explicitly as its spiritual successor.

**Path of Exile (2013, GGG).** Four design decisions stand out:

1. **Instanced everything.** All areas outside encampments are fully isolated per player or party. No shared open world outside towns. Instances persist for 8-15 minutes after the last player leaves, then expire. Consequence: no resource contention, no kill-stealing, no bot interference in your run — but also no emergent cross-player encounters.

2. **Barter currency, no gold.** There is no gold. Instead, 20+ currency items (orbs and scrolls) each have a specific crafting function: a Chaos Orb rerolls all modifiers on a rare item; an Exalted Orb adds a new modifier; a Mirror of Kalandra duplicates an item. Every currency item is simultaneously a crafting tool and a trade medium. This eliminates inflation: using a currency item to craft removes it from circulation. The Gamedeveloper.com analysis shows exchange rates emerge from each currency's (drop rate − consumption rate) ratio, with players acting as informal currency changers. Gold was added in patch 3.25.0 but remains non-tradeable (NPC-only), preserving the barter economy for player trade.

3. **Passive skill tree as character space.** 2,268 nodes on a shared tree; each class starts at a different position. Up to 123 points per character through leveling and quests. Every build must path through the tree uniquely, making character design a first-order gameplay decision. No classes in the hot-swappable sense — a choice of starting position and path is effectively permanent.

4. **Seasonal league resets.** Every 3-4 months, a new Challenge League launches with a fresh economy and a unique mechanic. All characters and items migrate to Standard (permanent league) at season end — nothing is lost. The reset creates controlled scarcity: in week one of a new league, even basic currency orbs have real value again; a Chaos Orb "that barely registers in Standard can buy a meaningful gear upgrade in week one." Balance changes each season shift which builds are viable, creating a collective puzzle-solving experience rather than exploiting a solved meta. Standard exists for players who prefer permanence; the reset is opt-in, not punitive. (Game-Wisdom analysis of the PoE 2 seasonal model.)

**Wayfinder relevance:** the affix system is the direct template for [[Affixes]] on charts; instanced areas are the primary model for [[Dungeon Generation]] and [[Multiplayer Co-op]] (each run = one party instance); barter-currency thinking informs [[Economy]] (no inflation spiral, currency items as meaningful drops); seasonal resets are a long-term design option for [[Chart Loop]] economy health; the passive tree is a reference for [[Trades and Leveling]] depth without class lock-in.

---

## Albion Online (2017) and Project Gorgon

Two smaller titles that demonstrate skill-based and sandbox design at the edges of the AAA MMO space, directly relevant to Wayfinder's cozy-skilling identity.

**Albion Online** (Sandbox Interactive, launched globally July 17, 2017) was built with an explicit design goal: recreate the player-driven world of Ultima Online with a modern engine (Unity; cross-platform including mobile and console). Its signature system is "You Are What You Wear" — the game has no class system. The equipment worn determines the character's active abilities and role. Swap from a sword-and-board set to a staff and you become a mage; roles are fluid. Nearly every item in the game is crafted by players, in player-constructed buildings, from player-gathered resources — a genuinely closed player-driven economy with no NPC gear flooding the market. Risk is stratified by zone color: Yellow (limited PvP, no full loot), Red (moderate risk), Black (full loot on death). Guilds of up to 300 members contest castles and territories via ZvZ (Zerg vs Zerg) large-scale battles, with alliances amplifying political power.

**Project Gorgon** (Elder Game Studios, Eric Heimburg; Early Access 2018) is a deliberately niche, low-budget MMO that leans into old-school discovery design. Heimburg previously worked as senior engineer on Asheron's Call 1 and 2. The game has 100+ skills; characters combine any two combat skills as primary and secondary (Fire Magic + Psychology, Unarmed + Necromancy) alongside support skills, crafting, and gear-sourced bonuses. The NPC favor/relationship system is a load-bearing social mechanic: cultivating relationships with specific NPCs unlocks storage, recipes, services, and entire gameplay systems — the world opens through relationship rather than quest completion. The design eliminates quest markers entirely; discovery-first exploration is the content. Unusual mechanics — certain death types grant experience and unlock unique interactions, players can be cursed into animal forms, hidden languages exist to decode — reflect a design ethos of depth through weirdness rather than polish.

**Wayfinder relevance:** Albion's "you are what you wear" is a design data point for flexible role systems in [[Combat]] and [[Trades and Leveling]]; its full-loot risk stratification maps to dungeon risk calibration; Project Gorgon's NPC favor system is upstream of [[NPCs]] depth and [[Economy]] social design; both titles validate skill-based/classless progression for a non-combat-primary game.

---

## Comparative Table

| Game | Launch | Architecture | Standout Design Idea |
|---|---|---|---|
| Ultima Online | 1997 | Sharded parallel worlds; Sun/Solaris clusters | Usage-based skill advancement; player-driven craft economy; safe/wild zone split |
| EverQuest | 1999 | Zone-server clusters; 500+ discrete zone processes | Holy trinity crystallized; corpse-run death penalty as social glue; contested spawn camping |
| Lineage II | 2003 | Shared open world; large-server clusters | Castle siege as territorial economy; clan as load-bearing social unit |
| Guild Wars 2 | 2012 | Megaserver dynamic map instances; real-time boss timers | No trinity; dynamic events; universal level downscaling |
| Diablo 2 | 2000 | Peer-to-peer instanced games | Randomized prefix/suffix affixes as the ARPG loot paradigm |
| Path of Exile | 2013 | Server-hosted instanced areas per party | Barter currency = crafting material; 2,268-node passive tree; seasonal league resets |
| Albion Online | 2017 | Shared open world + Unity; cross-platform | "You Are What You Wear" classless system; full-loot risk stratification by zone color |
| Project Gorgon | 2018 EA | Small-scale shared world | 100+ skills; NPC favor system as world-access gate; discovery-first, no quest markers |

---

## See also

- [[MMO Research]]
- [[World of Warcraft]]
- [[RuneScape]]
- [[EVE Online]]
- [[Final Fantasy XIV]]
- [[MMO Server Architecture]]
- [[MMO Netcode and Tick Systems]]
- [[MMO Economy and Itemization]]
- [[MMO Progression Systems]]
- [[MMO Social and Endgame]]
- [[MMO Lessons for Wayfinder]]
- [[Design Influences]]
- [[Items and Gear]]
- [[Affixes]]
- [[Chart Loop]]
- [[Economy]]
- [[Multiplayer Co-op]]
- [[Combat]]

---

## Sources

All facts with URLs: `kb/raw/mmo/survey.md`.

Primary sources consulted:
- Raph Koster, "Did players destroy the UO ecology?" — raphkoster.com
- Raph Koster, "A UO postmortem of sorts" — raphkoster.com
- GDC Vault, "Classic Game Postmortem: Ultima Online" — gdcvault.com/play/1016629
- Wikipedia: Ultima Online, EverQuest, Lineage II, Path of Exile, Albion Online
- "Quite Deadly — Death, Dying & EverQuest in 1999" — psychopomp.com
- "Rethinking the Trinity of MMO Design" — gamedeveloper.com
- GW2 Design Manifesto — guildwars2.com/en/news/guild-wars-2-design-manifesto/
- GW2 Megaserver blog — guildwars2.com/en/news/the-megaserver-system-world-bosses-and-events/
- GW2 Wiki: Dynamic level adjustment — wiki.guildwars2.com
- "Under Siege by Bot Farms: Lineage Classic's Growing Crisis" — invenglobal.com
- Lineage 2 / Castle Sieges — en.wikibooks.org
- "Path of Exile Economy: Currency Trading" — gamedeveloper.com
- "Design Philosophy Behind PoE 2's Seasonal Model" — game-wisdom.com
- Project Gorgon review — lucasgraphic.com
