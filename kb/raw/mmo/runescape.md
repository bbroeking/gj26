# RuneScape — Raw Research Provenance

Scraped: 2026-06-13. All facts below are drawn from fetched URLs; uncertain claims are flagged.

---

## Source 1: OSRS Wiki — Experience
URL: https://oldschool.runescape.wiki/w/Experience

- Exact XP formula: `Experience = floor(1/4 * sum_{l=1}^{L-1} floor(l + 300 * 2^(l/7)))`
- Closed-form approximation: `1/8 * (L^2 - L + 600 * 2^(L/7) - 2^(1/7)/(2^(1/7)-1))`, accurate within 14 XP
- XP table (key levels):
  - Level 1: 0 XP
  - Level 50: 101,333 XP
  - Level 70: 737,627 XP
  - Level 85: 3,258,594 XP
  - Level 92: 6,517,253 XP  ← exactly half of level 99
  - Level 99: 13,034,431 XP
- XP stored as 32-bit signed integer with one decimal place
- Hard cap: 200,000,000 XP (32-bit limit)
- "Virtual levels" exist beyond 99: level 126 requires 188,884,740 XP
- The amount of XP needed roughly doubles every 7 levels above ~level 20

---

## Source 2: OSRS Wiki — Game Tick
URL: https://oldschool.runescape.wiki/w/Game_tick (fetched via OSRS Wiki)

- Standard tick length: 0.6 seconds (theoretical: 100 ticks/minute)
- Actual tick length varies by world population: 0.606-0.618s; World 302 (high pop): 0.616-0.618s
- Client vs. server: server actions on 0.6s tick; client UI actions on separate 20ms tick rate
- "Each action registered within one tick will start to take place by the beginning of the next tick"
- Movement speed: 2 squares/tick running, 1 square/tick walking
- Special attack recovery: 10% per 50 ticks (25 ticks with Lightbearer ring)
- Stat drain: 1 level per 100 ticks (150 with Preserve prayer)
- Servers can "miss a tick or multiple ticks" — most common on high-population worlds
- Chat messages persist for 5 ticks above player heads

---

## Source 3: OSRS Wiki — Tick Manipulation
URL: https://oldschool.runescape.wiki/w/Tick_manipulation

- Definition: "a method in which players are able to use the tick system to their advantage"
- Works by exploiting skilling timer — certain actions "clear any existing timer", players restart skill on same tick
- 3-tick fishing/woodcutting: reduces normal 5-tick cycle to 3-tick by interleaving herb+swamp tar actions; ~67% XP/hr improvement
- 1-tick cooking: karambwan technique — open new dialogue on same tick as cook; exceeds 1,000,000 XP/hr
- 2-tick methods: use auto-retaliate + rapid weapons to space hitsplats every 2 ticks
- Jagex stance: "considered balanced and accepted due to the extra effort involved by the player"
- Prayer flicking: NOT classified as tick manipulation per wiki, but exploits same tick timing
- Prayer flicking clarification (from Prayer wiki): "Prayer drain is calculated once per tick based on your active prayers but attacks are only affected by prayers that were active at the start of that game tick"
  - Activating/deactivating prayer each tick gets benefit with zero drain if executed perfectly

---

## Source 4: OSRS Wiki — Prayer
URL: https://oldschool.runescape.wiki/w/Prayer

- Drain formula: `seconds per point = 0.6 * (drain_resistance / drain_effect)`
- Base drain resistance: 60 + (2 × prayer bonus points)
- Protect from Melee: 12 drain effect (1 point per 3 seconds at zero bonus)
- Piety/Rigour/Augury: 24 drain effect (1 point per 1.5 seconds)
- 1-tick flicking: toggle prayer every tick to maintain benefit with zero drain — requires precise timing knowledge

---

## Source 5: OSRS Wiki — Skills
URL: https://oldschool.runescape.wiki/w/Skills

- OSRS total skills: 24 (as of 2026; Sailing added as newest skill)
  - F2P: 15 skills (Attack, Strength, Defence, Ranged, Prayer, Magic, Runecraft, Hitpoints, Crafting, Mining, Smithing, Fishing, Cooking, Firemaking, Woodcutting)
  - Members-only: 9 skills (Agility, Herblore, Thieving, Fletching, Slayer, Farming, Construction, Hunter, Sailing)
- RS3 total skills: 29 (per runescape.com game guide — RS3 has additional skills)
- Four official skill categories:
  1. Combat Skills — enhance combat (Attack, Defence, Hitpoints, Magic, Prayer, Ranged, Strength)
  2. Gathering Skills — collect resources (Farming, Fishing, Hunter, Mining, Woodcutting)
  3. Production Skills — convert resources into items (Cooking, Crafting, Fletching, Herblore, Runecraft, Smithing)
  4. Utility Skills — enhance mechanics (Agility, Construction, Firemaking, Sailing, Slayer, Thieving)
- Interlocking outputs: Woodcutting logs → Firemaking fuel → Cooking food

---

## Source 6: OSRS Wiki — Old School RuneScape (History)
URL: https://oldschool.runescape.wiki/w/Old_School_RuneScape

- Announced February 13, 2013 with community poll
- Poll ended March 1, 2013: 449,351 votes cast (below 500K threshold for free access)
- Jagex added OSRS free with existing membership anyway
- Server opened February 22, 2013; permanent commitment announced June 7, 2013
- Peak concurrent players: 257,491 (September 1, 2025)
- F2P for OSRS: proposed January 25, 2015; passed with 85.9% approval; launched February 19, 2015
- OSRS based on August 2007 game archive; evolved separately from RS3 since

---

## Source 7: OSRS Wiki — Polls
URL: https://oldschool.runescape.wiki/w/Polls

- Ongoing content polls: require 70% supermajority (changed from 75% on October 27, 2022)
- Original threshold was 75% of total votes
- Voting eligibility: total level 300+ AND 25+ hours playtime
- "Skip question" votes excluded from calculation
- Three poll types (as of 2025):
  1. Lock-in polls: 70% commits to release
  2. Greenlight polls: 70% advances to full design for later formal vote
  3. Opinion surveys: no threshold, flexible questionnaire
- New game modes, bug fixes, and graphical updates bypass polling entirely

---

## Source 8: RuneScape Wiki — Grand Exchange
URL: https://runescape.wiki/w/Grand_Exchange

- Launched: November 26, 2007
- Located northwest of Varrock
- Replaced player marketplaces at Varrock banks and Falador Park
- Mechanics: clears offers between buyers/sellers in order received
  - Buyer pays seller's lower price; receives price difference if buyer bid higher
  - Seller receives buyer's higher price if seller asked lower than existing buy offer
- GE slots: 8 for members, 3 for F2P
- Buy limits: 4-hour purchase cap per item type; no sell limit
- Tax: 2% sales tax on seller since January 9, 2023; items under 50gp and bonds exempt
- Prices: supply and demand driven; Jagex can intervene if manipulation suspected
- Cross-world: GE transactions function universally across all worlds

---

## Source 9: Wikipedia — RuneScape
URL: https://en.wikipedia.org/wiki/RuneScape

- Launch: January 4, 2001 (browser-based Java game by Andrew and Paul Gower)
- Jagex formally established: December 2001
- RuneScape 2: 2004 (full engine rewrite, full 3D graphics)
- RuneScape Classic: original version renamed after RS2 launch; closed 2018
- RuneScape 3: July 2013 (HTML5 client, customizable UI, orchestral soundtrack)
- OSRS launch: February 2013
- Evolution of Combat: November 20, 2012 (ability-based system replacing tick-only combat in RS3)
- Membership introduced: February 27, 2002 (announced October 4, 2001)
- Microtransactions: April 2, 2012 (Squeal of Fortune wheel)
- Solomon's General Store (cosmetics): July 2012
- Bonds: September 2013 (tradeable membership tokens)
- Treasure Hunter microtransactions removed: January 19, 2026 (community vote, "Integrity Roadmap")
- Lifetime revenue: >$1 billion by 2023
- Over 300 million accounts created
- Guinness records: "largest and most-updated free MMORPG," most original game music (1,300+ tracks)

Client/engine history:
- RuneTek 1-2 (2001-2003): Java, mixed 2D/3D sprites
- RuneTek 3-4 (2004-2008): Full 3D; high-detail option
- RuneTek 5 (2009-2013): Hardware acceleration, DirectX/OpenGL
- RuneTek 7 (2013-2016): HTML5/WebGL (abandoned — performance + threading limitations)
- NXT (2016-present): C++ standalone client

---

## Source 10: RuneScape Wiki — NXT Client
URL: https://runescape.wiki/w/NXT

- NXT launched: April 18, 2016
- Java client phased out: December 18, 2019
- Written in C++11 (with some Objective-C for macOS, JavaScript for Emscripten, some C)
- "Hardware abstraction layer" separates platform-specific code
- Evolved from scrapped HTML5 client project; ported HTML5 codebase to C++
- Key visual improvements: 4x greater draw distance, fully dynamic lighting and shadows
- Background map preloading eliminates loading screens between areas
- Game logic (RuneScript, tick engine) remains entirely Java-based; only rendering layer changed
- Players on NXT and Java clients played side by side during transition period

---

## Source 11: RuneScape Wiki — RuneScript
URL: https://runescape.wiki/w/RuneScript

- Scripting language developed by Jagex for content creation
- Designed so non-Java staff can create game content (quests, items, NPCs, events)
- Compilation: source → bytecode → executed by Java engine (engine cannot read source directly)
- Syntax: C-style with type-prefixed variables (`%varname` for integers)
- Limited array support
- Minor updates: new maps/NPCs via individual script files
- Major updates: new areas, skills, bug fixes require engine source code changes
- OSRS uses RuneTek 3 engine; RuneScript runs on the VM within it
- Quoted from Mod John A (2009 dev blog) and Mod Chris E (2012 forum post)

---

## Source 12: OSRS Wiki — Worlds
URL: https://oldschool.runescape.wiki/w/World

- OSRS: 258 normal members worlds + 54 F2P worlds (as of research date)
- RS3: 137 worlds (excluding instance shards, beta, temporary modes)
- Each world: "containerised virtual machine running the Java-based world application"
- Moved from dedicated physical machines to virtualization (ESXi scheduling)
- Planned migration: Linux CFS/PreemptRT under KVM for better tick performance
- Members worlds: 2,000 players max; F2P worlds: 1,400 players max
- World isolation: shop inventories, respawns, item spawns, resource regeneration — all per-world
- Player data (skills, inventory, quests) stored in global database; syncs on login to any world
- Cross-world: only private chat (Friends List) and Clan Chat span worlds
- GE offers span all worlds universally

---

## Source 13: OSRS-Docs — Queues
URL: https://osrs-docs.com/docs/mechanics/queues/

- Four queue script types:
  1. Weak: removed by strong scripts; cleared on entity interaction, inventory change, interface toggle
  2. Normal: skipped if player has modal interface open
  3. Strong: removes weak scripts; closes modal interface before executing
  4. Soft: cannot be interrupted; executes every tick regardless of delays
- Single underlying queue (not multiple) — all types append to same structure
- Processing loop: indefinite iteration; exits only when all scripts skipped in last loop
- Hard delay mechanic: if any script sets delay, all subsequent scripts (except soft) are skipped that tick
- NPC queues: single priority level (no weak/normal/strong distinction)
- Area queues: zone transitions, music unlocks, farming state updates

---

## Source 14: OSRS Wiki — Ironman Mode
URL: https://oldschool.runescape.wiki/w/Ironman_Mode

- Standard Ironman launched: October 13, 2014
- Ultimate Ironman: same day (no banking)
- Hardcore Ironman: November 10, 2016 (single life)
- Group Ironman: October 2021 (2-5 players; trade freely within group, restricted externally)
- Hardcore Group Ironman: October 2021 (group + permadeath prestige)
- Unranked Group Ironman: May 2022 (no ranking)
- Core rule: "stands alone" — no trading, GE (except bonds), no picking up others' drops
- Exceptions: raids (Chambers of Xeric, Theatre of Blood), Tempoross, Wintertodt, Zalcano
- Safe deaths: Barbarian Assault, Castle Wars, Inferno, Nightmare Zone preserve Hardcore status

---

## Source 15: OSRS Wiki — Combat Level
URL: https://oldschool.runescape.wiki/w/Combat_level

- Formula:
  - Base = 0.25*(Defence + Hitpoints + floor(Prayer/2))
  - Melee = 0.325*(Attack + Strength)
  - Magic = 0.4875*Magic (i.e., 0.325*(floor(Magic/2)+Magic) simplified)
  - Ranged = 0.4875*Ranged
  - Combat Level = floor(Base + max(Melee, Magic, Ranged))
- OSRS max combat level: 126 (melee); Magic/Ranged builds: up to 109
- RS3 max: 152 (after Necromancy added 2023)
- Combat level is descriptive/summary metric, not a hard content gate
- Used to indicate difficulty of defeating opponent

---

## Source 16: OSRS Wiki — Quests
URL: https://oldschool.runescape.wiki/w/Quests

- OSRS total: 180 quests (24 F2P, 156 members) as of May 2026
- Maximum quest points: 335 (46 from F2P quests)
- Quest point cape purchasable at 335 QP
- Difficulty tiers: Novice, Intermediate, Experienced, Master, Grandmaster
- Rewards: QP, XP (fixed to a skill or flexible via lamps/books), items, new area access
- Skill prerequisites: can be met with temporary boosts
- Total fixed XP from all quests: ~14,041,756 (as of June 2020)
- Quest content gates: e.g., West Ardougne inaccessible without completing Elf quest series
- As of June 1, 2026: RS3 has 275 quests (44 F2P, 231 members); 472 quest points

---

## Source 17: Community Analyses — Grind / Time-to-Max

- Time to max all 24 OSRS skills: 2,000-2,500 EHP (Efficient Hours Played) at peak efficiency
- Fastest max cape speedrun record: 771 hours (He Box Jonge)
- Casual/unfocused play estimate: up to ~10,000 hours
- With tick manipulation for gathering skills: Mining rates up to 134,000 XP/hr; without: ~63,000 XP/hr
- Woodcutting 99 at 100k XP/hr methods: ~130 hours
- Note: RS3 estimate of "10,000 hours to max + quests" appears in multiple community sources (uncertain, not from official doc)

---

## Source 18: OSRS Wiki — Combat Triangle
URL: https://oldschool.runescape.wiki/w/Combat_triangle

- Triangle: Melee > Ranged > Magic > Melee (cyclic)
- Melee armour: high melee and ranged defence; poor magic defence
- Ranged armour: high magic defence, moderate ranged and melee
- Magic armour: magic attack bonuses, moderate magic defence, near-zero melee/ranged defence
- Not deterministic — "any combat style can be used effectively against any other"
- Functions as rule of thumb for similar-level opponents

---

## Uncertainty Flags

- "10,000 hours to max RS3 all skills+quests" — community estimate, not official Jagex documentation
- RS3 exact skill count as of research date: search said 29; Wikipedia says game guide lists 29
- Exact tick server lag: varies by world/population; 0.6 is nominal, real is 0.606-0.618
- Specific RS3 world count (137) may drift; sourced from RS3 wiki reference
