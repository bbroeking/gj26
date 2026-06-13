# MMO Survey — Raw Provenance
*Facts + URLs. Read-only reference for the wiki page at `wiki/research/MMO Survey.md`.*
*Ingested: 2026-06-13*

---

## Ultima Online (1997)

**Sources:**
- https://www.raphkoster.com/games/snippets/did-players-destroy-the-uo-ecology/
- https://www.raphkoster.com/games/snippets/a-uo-postmortem-of-sorts/
- https://gdcvault.com/play/1016629/Classic-Game-Postmortem-Ultima
- https://en.wikipedia.org/wiki/Ultima_Online
- https://massivelyop.com/2018/06/14/magic-through-serendipity-raph-koster-on-the-glorious-mess-that-was-ultima-online/

**Confirmed facts:**

- Launch: September 24, 1997.
- 100,000 subscribers within six months; peak ~250,000 in July 2003.
- Skill-based character progression (no levels, no classes) — skills advanced by use.
- Player housing: persistent, placed in the open world; heavily desired but
  clunky at launch (Koster: "townstones are at the top of my wish list").
- Craft-based and player-driven economy from day one.

**Shard model:**
- Multiple parallel servers, each a full copy of the world, called "shards."
- Term coined by Raph Koster: lore justification = the villain Mondain's Gem of
  Immortality was shattered; each shard contains a copy of Sosaria. 
  [Source: search results / Wikipedia / UOGuide]
- Original servers ran on clusters of Sun Microsystems hardware running Solaris.
- Scale underestimate: designed for ~300 concurrent, scaled to ~3,000 nine months
  before launch; not prepared for actual audience. (Koster postmortem)

**Ecology / economy collapse:**
- Koster designed an AI "Artificial Life" ecology with resource values per creature
  (meat, hide, feathers). Strategy guide at launch documented resource values.
- Ecology removed during beta: two reasons (a) pathfinding/radial-search CPU cost
  and (b) player hoarding — killing sheep → making infinite shirts → hoarding shirts
  → depleting closed resource pool → no new sheep spawn.
- Economist Zach Simpson's paper "In-Game Economics of Ultima Online" introduced
  "faucet-drain economy" terminology from analysing UO. [Koster ecology page]
- Koster conclusion: "Closed economies can't work."
  Lesson: "A sandbox is not enough" without community structures + incentive systems.

**PvP problem and Trammel/Felucca:**
- Unrestricted open PvP drove players out of the world by the thousands via griefing.
- Renaissance expansion (May 2000): introduced Trammel (consensual PvP only) +
  Felucca (unrestricted PvP, a mirror of the old world). 
- Koster later embraced safe/wild zoning; mixed servers proved unsustainable.

**Community formation insight (Koster):**
- Successful communities need: shared interests, limited resources requiring
  cooperation, external threats/enemies to unite against.

---

## EverQuest (1999)

**Sources:**
- https://en.wikipedia.org/wiki/EverQuest
- https://psychopomp.com/quite-deadly-everquest/
- https://www.gamedeveloper.com/design/rethinking-the-trinity-of-mmo-design
- https://wiki.project1999.com/Brad_McQuaid
- https://forums.mmorpg.com/discussion/458753/what-trinity-dps-tank-healing-is-a-false-trinity

**Confirmed facts:**

- Launch: March 16, 1999.
- First commercially successful MMO to use a 3D game engine.
- First MMO to feature a guild system and raiding (Hall of Fame, 2011).
- Peak 3,000+ players per server; server = cluster of machines.
- Brad McQuaid: lead programmer → producer/lead designer.

**Zone architecture:**
- World divided into 500+ discrete zones; each zone is a separate server process.
  Moving between zones = loading screen ("zone-in").
- Zones divided by complexity/file size; cities often split into multiple sub-zones.
- Each server is "actually a cluster of server machines."

**Holy Trinity / class design:**
- Four role categories: Melee (Warriors, Monks, Rogues, Berserkers),
  Priests (Clerics, Druids, Shamans), Casters (Wizards, Mages, Necros, Enchanters),
  Hybrids (Paladins, Shadowknights, Bards, Rangers, Beastlords).
- Trinity crystallized in high-end raiding: tank held boss, clerics kept tank alive,
  others dealt damage.
- Enchanters equally critical as Clerics for CC (mezz) + mana regen.
  Real EQ group: tank + cleric + enchanter (not simply "DPS").
- Trinity became industry standard because it simplified encounter design and
  made player roles comprehensible. [Gamedeveloper.com]

**Death penalty / corpse run:**
- Dying = corpse drops at death location with ALL equipped items.
- Respawn at "bind point" (potentially hours away); must travel back naked.
- Experience loss on death; enough deaths = demotion to previous level.
- "Train to Zone!" warning: aggroing multiple mobs, dragging them to zone line.
- Extreme death penalty → players helped strangers (resurrection = community currency).
- Harsh penalty drove grouping and interdependence as survival strategy.
  [psychopomp.com article]

**Contested spawns:**
- Named mobs (rare, better loot) had fixed spawn timers; guilds/players would
  "camp" spawn points for hours or days — spawn camping.
- Social friction: kill-stealing, KS disputes, etc. Created scarcity-driven competition
  that paradoxically drove community formation (alliances, server reputations).

---

## Guild Wars 2 (2012)

**Sources:**
- https://www.guildwars2.com/en/news/the-megaserver-system-world-bosses-and-events/
- https://www.guildwars2.com/en/news/guild-wars-2-design-manifesto/
- https://wiki.guildwars2.com/wiki/Dynamic_level_adjustment
- https://gdcvault.com/play/1013691/Designing-Guild-Wars-2-Dynamic (paywalled; metadata only)

**Confirmed facts:**

- Launch: August 28, 2012. Buy-to-play (no subscription).
- Megaserver deployed: 2014 (post-launch patch).

**No holy trinity (manifesto):**
- ArenaNet explicitly eliminated the tank/healer/DPS structure.
- All players share the same PvE objectives; multiple players killing same mob all
  receive 100% XP and loot (no kill-stealing; aligned incentives).
- No formal grouping required for open-world events; players "naturally work with
  everyone around you." [GW2 Manifesto]

**Dynamic events:**
- Replace static quest-givers (no exclamation marks). Events have visible world
  consequences — villages burn, villagers flee — creating organic discovery.
- Events chain: success unlocks follow-up events; failure creates new event state.
- World bosses scheduled on synchronized real-time timers; consistent across all
  map instances. [GW2 Megaserver blog]

**Megaserver technology (2014):**
- Eliminated per-server population silos.
- System = weighted load balancer: reads party, guild, language, home world,
  frequent co-players; assigns players to the optimal map copy.
- Creates map instances dynamically based on total game population.
- World boss scheduling: hard-core bosses every ~8 hours; standard events on
  the hour/half-hour; low-level events at :15 and :45.
- Cross-map state (knowing what's happening on your destination map) disabled
  because cross-instance reporting was architecturally infeasible. [Megaserver blog]

**Dynamic level adjustment (downscaling):**
- High-level player entering low-level zone: effective level = zone_max + 1.
- All stats scale down proportionally; formula: R = (base power at effective level)
  / (base power at actual level); all stats × R.
- Skills, equipment, runes, sigils retained at full quality.
- Design goals: (1) prevent high-levels trivializing content; (2) keep all zones
  perpetually relevant. [wiki.guildwars2.com/wiki/Dynamic_level_adjustment]

**Personal story:**
- Biography choices at character creation branch narrative; instanced story chapters.
  Allows replaying with different outcomes.

---

## Lineage / Lineage II (2003)

**Sources:**
- https://en.wikipedia.org/wiki/Lineage_II
- https://en.wikibooks.org/wiki/Lineage_2/Castle_Sieges
- https://www.invenglobal.com/articles/20251/under-siege-by-bot-farms-lineage-classics-growing-crisis
- https://l2wiki.com/main/locations/activity/siege/
- https://strategywiki.org/wiki/Lineage

**Confirmed facts:**

- Lineage (1998, Korea, NC Soft) — first game to introduce castle siege PvP as
  a world-altering mechanic.
- Lineage II launched Korea: October 1, 2003; NA/EU: 2004.
- L2 reported 40,027,918 unique users in March 2007; 94 million total by ~2010.

**Castle siege design:**
- 7 castles in Aden; sieges biweekly (two hours each).
- Participating clans: level 4+ to join; level 5 required to form a 3-clan alliance.
- Attacker objectives: raise clan flag → breach gate/walls → destroy 2 Life Crystals
  → clan leader inscribes rear statue within 5 minutes.
- Defender objective: run out the 2-hour timer.
- Winning clan controls NPC shop tax rates in linked territories; taxes flow into
  castle vault (accessible only to clan leader).
- Combination of territorial control, economic incentives, timed objectives, and
  asymmetric attack/defend roles. Large-scale: hundreds of players per siege.

**Bot / RMT economy crisis:**
- Bots use VPNs, stolen accounts, automated routines (detect mob → attack → loot →
  sell → reconnect) at industrial scale; typical hunting ground: 40 accounts, short
  English IDs, sequential numbers.
- Bot-generated Adena floods market → deflation → item prices converge to barely
  above NPC sell price → reward loop collapses.
- Perverse dynamic: cheap Adena makes real-money enchant upgrades cheaper, widening
  gap between paying and non-paying players.
- NCSoft response (as of Feb 2026): 15 enforcement iterations, 1.38 million accounts
  restricted, guard NPCs, "Clean Campaign," community reporting events.
- Conclusion: "The battle between illegal programs and security measures has no clear
  end" — detection arms races cannot solve structural economic imbalances. [Inven Global]

---

## Diablo / Path of Exile (ARPG-adjacent)

**Sources:**
- https://en.wikipedia.org/wiki/Path_of_Exile
- https://www.gamedeveloper.com/design/path-of-exile-economy-currency-trading
- https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
- https://miguelballesteros.com/path-of-exiles-complex-item-affix-system-how-mods-can-change-your-gear-and-build/
- http://thegamedesignforum.com/features/RD_D2_5.html

**Confirmed facts (Diablo 2):**
- Randomized affix system on magic/rare/crafted items: each item generated with
  random prefixes/suffixes selected from weighted frequency tables.
- Item rarity (magic/rare/unique) + item level determine affix count and pool.
- Uniques = fixed stats; rares = fully random within type constraints.
- No personal loot at launch (shared/universal loot); loot competition in co-op
  was a social and design friction point.
- Diablo 2's itemization widely considered foundational to ARPG genre.

**Path of Exile design (GGG, 2013):**
- Spiritual successor to Diablo II.
- All areas outside encampments are fully instanced (isolated per player/party).
- No gold: barter economy using functional currency items (orbs).
  Each orb has a dual purpose — both crafting function AND trade value.
  Key orbs: Chaos Orb (rerolls random rare mod), Exalted Orb (adds mod to rare),
  Mirror of Kalandra (duplicates item — ultra-rare).
  Gold re-added in 3.25.0 but non-tradeable (NPC-only).
- Passive skill tree: 2,268 nodes, shared by all classes; each class starts at
  different position. Up to 123 points per character. Pure build-space exploration.
- Seasonal leagues: every 3-4 months a new Challenge League launches with a fresh
  economy and a unique mechanic. All characters/items migrate to Standard at end.
- League reset design purpose: controlled scarcity; fresh economies where even
  basic currency has value again; community shared discovery moment.
  Players who prefer permanence play Standard; reset is not punitive. [Game-Wisdom]
- Party instancing: players in same party share one instance; no automated matchmaking.
  Instance persists for ~8-15 min after last player leaves (PoE2).

**PoE's barter economy lessons:**
- Inflation solved by dual-use: currency consumed in crafting removes it from
  circulation naturally.
- Exchange rates emerge from (drop rate − consumption rate) per currency type.
  Players act as changers, profiting through small spreads.
- Problems created: learning curve (20+ currencies to understand), trading friction
  (manual trades, third-party trade sites), price manipulation.

---

## Albion Online (2017) & Project Gorgon

**Sources:**
- https://en.wikipedia.org/wiki/Albion_Online
- https://fextralife.com/albion-online-review-chart-destiny/
- https://mmos.com/review/albion-online
- https://lucasgraphic.com/posts/project-gorgon-a-weirdly-deep-old-school-mmorpg
- https://store.steampowered.com/app/342940/Project_Gorgon/
- https://mmos.com/review/project-gorgon

**Albion Online confirmed facts:**
- Developer: Sandbox Interactive (founded 2012); global launch July 17, 2017.
- Explicitly inspired by Ultima Online: "recreate the player-driven MMORPG world
  of Ultima Online, with a modern engine."
- Engine: Unity; cross-platform (Windows, macOS, Linux, iOS, Android, Xbox Series X/S).
- "You Are What You Wear": classless system; the equipment worn determines abilities.
  No class lock-in; swap role by swapping gear sets.
- Player-driven economy: nearly every item crafted by players, in player-built
  buildings, from player-gathered resources. No NPC-generated gear flooding market.
- Risk stratification by zone color: Yellow (limited PvP/no full loot),
  Red (moderate risk), Black (full loot on death).
- Guild territory control: guilds (up to 300 members) contest castles and
  territories via ZvZ (Zerg vs Zerg) battles; alliances amplify strategic power.

**Project Gorgon confirmed facts:**
- Developer: Elder Game Studios (Eric Heimburg, Sandra Powers); Early Access 2018.
- Heimburg: former senior/lead engineer on Asheron's Call 1 & 2, Star Trek Online.
- 100+ skills; players combine any two combat skills as primary/secondary
  (e.g., Fire Magic + Psychology, Unarmed + Necromancy).
- NPC favor/relationship system: build relationships to unlock storage, recipes,
  services, and gameplay systems — social depth through world integration.
- Classless freeform exploration; no quest markers; discovery-first design.
- Unusual mechanics: dying is a skill (certain death types grant XP); players can
  be cursed to become a cow or spider; hidden languages to discover.
- Dated visuals and clunky UI acknowledged; the design value is build freedom +
  sense of discovery. [PC Gamer, LucasGraphic review]
