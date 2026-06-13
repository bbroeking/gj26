---
type: concept
tags: [mmo-research, runescape, progression, tick-systems, economy, game-design, osrs, rs3]
status: draft
updated: 2026-06-13
sources:
  - https://oldschool.runescape.wiki/w/Experience
  - https://oldschool.runescape.wiki/w/Game_tick
  - https://oldschool.runescape.wiki/w/Tick_manipulation
  - https://oldschool.runescape.wiki/w/Prayer
  - https://oldschool.runescape.wiki/w/Skills
  - https://oldschool.runescape.wiki/w/Old_School_RuneScape
  - https://oldschool.runescape.wiki/w/Polls
  - https://runescape.wiki/w/Grand_Exchange
  - https://en.wikipedia.org/wiki/RuneScape
  - https://runescape.wiki/w/NXT
  - https://runescape.wiki/w/RuneScript
  - https://oldschool.runescape.wiki/w/World
  - https://osrs-docs.com/docs/mechanics/queues/
  - https://oldschool.runescape.wiki/w/Ironman_Mode
  - https://oldschool.runescape.wiki/w/Combat_level
  - https://oldschool.runescape.wiki/w/Quests
---

# RuneScape

RuneScape is a massively multiplayer online role-playing game (MMORPG) developed by Jagex — launched January 4, 2001 — that pioneered the skill-based, class-free progression model and the 0.6-second deterministic game tick, two design decisions that remain unique in the MMO genre and directly inform Wayfinder's [[Trades and Leveling]] and [[Combat]] systems.

---

## History and Versions

| Version | Date | Notes |
|---|---|---|
| RuneScape Classic | Jan 4, 2001 | Browser-based Java; mixed 2D/3D sprites; RuneTek 1-2 |
| RuneScape 2 | 2004 | Full engine rewrite; full 3D; RuneTek 3-4 |
| Evolution of Combat (EoC) | Nov 20, 2012 | Ability-based combat overhaul for RS3; triggered OSRS split |
| RuneScape 3 | Jul 2013 | HTML5 client; customizable UI; orchestral soundtrack |
| Old School RuneScape (OSRS) | Feb 22, 2013 | August 2007 archive restored; community-polled development |
| NXT Client | Apr 18, 2016 | C++ standalone client replaces Java applet in RS3 |

By 2023 the franchise had generated over $1 billion in lifetime revenue and surpassed 300 million accounts. Guinness recognized it as the "largest and most-updated free MMORPG." OSRS peaked at 257,491 concurrent players on September 1, 2025.

---

## Design Layer

### The 23+ Skills Model (Skill-Based, Not Class-Based)

RuneScape has no class system. Characters are defined entirely by which skills they have trained and to what level. In OSRS there are **24 skills** (15 F2P, 9 members-only); RS3 has **29**. Every skill ranges from level 1 to 99 (with virtual levels extending to 126 via the XP cap).

**OSRS skill categories:**

| Category | Skills |
|---|---|
| Combat | Attack, Strength, Defence, Hitpoints, Prayer, Magic, Ranged |
| Gathering | Mining, Fishing, Woodcutting, Farming, Hunter |
| Production | Smithing, Crafting, Cooking, Fletching, Herblore, Runecraft |
| Utility | Agility, Construction, Thieving, Firemaking, Slayer, Sailing |

Skills interlock: Woodcutting logs fuel Firemaking, which supports Cooking, which produces food for Fishing/Mining stamina. This deliberate input-output chaining — not a skill tree or talent system — is how RuneScape creates depth without classes.

**Wayfinder relevance:** The four Wayfinder [[Trades and Leveling|Trades]] (Wayfinding, Earthcraft, Wildcraft, Huntcraft) are the same design philosophy at smaller scale: skill-as-verb, not class-as-identity.

### The XP Curve

All skills share one exponential curve. The formula for total XP required to reach level L is:

```
XP(L) = floor( (1/4) * sum_{l=1}^{L-1} floor( l + 300 * 2^(l/7) ) )
```

A closed-form approximation: `1/8 * (L^2 - L + 600 * 2^(L/7) - 2^(1/7)/(2^(1/7)-1))`, accurate within 14 XP.

**Key milestone values:**

| Level | Total XP | Notes |
|---|---|---|
| 1 | 0 | — |
| 50 | 101,333 | Early mid-game |
| 70 | 737,627 | Competent tier |
| 85 | 3,258,594 | Endgame content gate |
| 92 | 6,517,253 | Exactly half of level 99 XP |
| 99 | 13,034,431 | Skill mastery ("max") |

The curve roughly **doubles XP required every 7 levels** above level 20. Level 92 is exactly halfway to 99 in XP terms — which means the last seven levels (92→99) cost as much as the first 91 levels combined. This is RuneScape's iconic grind signature.

XP is stored as a 32-bit signed integer with one decimal place, capping at **200,000,000 XP** (virtual level ~126). Level 99 remains the meaningful social and functional cap.

### The Combat Triangle

RuneScape uses a rock-paper-scissors combat style system:

- **Melee** beats Ranged (armour absorbs arrows)
- **Ranged** beats Magic (range stays outside spell range; magic armour has near-zero ranged defence)
- **Magic** beats Melee (melee armour has terrible magic defence)

Armour bonuses reinforce this: melee armour blocks physical/ranged hits; magic armour grants spell accuracy but minimal physical protection. The triangle is a design heuristic, not a hard override — higher-level players can overcome the disadvantage, but it creates meaningful decision-making in PvP and endgame PvE.

Combat level (the visible summary number) is calculated as:

```
Base = 0.25 * (Defence + Hitpoints + floor(Prayer/2))
Melee = 0.325 * (Attack + Strength)
Magic = 0.4875 * Magic
Ranged = 0.4875 * Ranged
Combat Level = floor(Base + max(Melee, Magic, Ranged))
```

OSRS max combat level: **126** (melee builds); Magic/Ranged-focused builds cap at 109.

### Quest Design Philosophy

RuneScape treats quests as narrative content with hard skill prerequisites — not optional flavor. Key mechanics:

- **Quest Points (QP):** A meta-currency awarded per quest; gates late content (e.g., Dragon Slayer II requires 200 QP). OSRS maximum: 335 QP; F2P alone provides 46.
- **Skill prerequisites:** Most quests require minimum levels in relevant skills; temporary boosts may substitute. This makes questing a genuine progression gate, not just story.
- **Reward variety:** XP awards (fixed skill or flexible "lamp/book"), items, new area access, unlocked mechanics. Total fixed XP from quests: ~14 million (enough to significantly accelerate early training).
- **Difficulty tiers:** Novice, Intermediate, Experienced, Master, Grandmaster.
- **Content gating through quests:** e.g., West Ardougne remains inaccessible until completing the Elf quest series. This creates a world where story and systems are inseparable.

OSRS has 180 quests (24 F2P, 156 members) as of May 2026.

### The Grand Exchange

The Grand Exchange (GE) launched November 26, 2007, replacing player-organized street markets that had previously required players to advertise, meet, and negotiate in-person at Varrock bank.

**Mechanics:**

- Centralized order-book: buyers and sellers post offers; the system clears them in arrival order
- Buyer who bids over a sell offer gets the item at the seller's (lower) price, pockets the difference in gold
- Seller who asks below a buy offer receives the buyer's higher price automatically
- **Slots:** 8 per member, 3 for F2P
- **Buy limits:** Per-item cap on purchases per 4-hour window (prevents cornering markets)
- **Tax:** 2% sales tax on the seller since January 9, 2023; items under 50 gp and bonds exempt
- Price discovery: supply-and-demand driven; Jagex can intervene on suspected manipulation

The GE enabled efficient price discovery and removed friction from the economy, but also eliminated the social trading culture of haggling and meeting strangers. In Ironman mode, GE access is blocked (except bonds) by design. The GE is a key comparison point for [[Economy]] and [[MMO Economy and Itemization]].

### Ironman Modes

Ironman mode (launched October 13, 2014) formalizes "Do It Yourself" play: **no trading, no GE, no receiving drops from others' kills.** It redesigns the entire progression experience around self-sufficiency.

**The six variants:**

| Variant | Released | Key Restriction |
|---|---|---|
| Ironman | Oct 2014 | Standard — no trade, no GE |
| Ultimate Ironman | Oct 2014 | + No banking |
| Hardcore Ironman | Nov 2016 | + Single life (unsafe death = demoted) |
| Group Ironman | Oct 2021 | 2-5 players trade freely within group only |
| Hardcore Group Ironman | Oct 2021 | Group + prestige permadeath |
| Unranked Group Ironman | May 2022 | Group, no ranking |

Exceptions permit participation in raids (Chambers of Xeric, Theatre of Blood, Tempoross, Wintertodt, Zalcano), which are group-boss activities designed to be self-sufficient per participant.

Ironman is significant because it demonstrates that OSRS's progression is coherent enough that players voluntarily add handicaps to make skilling itself the primary loop. The mode is extremely popular, often representing a large fraction of active accounts.

### Membership and F2P Split

- F2P gives access to ~20% of all content
- Membership unlocks the remaining 9 skills, 156 quests, most of the game world
- Membership introduced February 27, 2002 (announced October 4, 2001)
- OSRS F2P launched February 19, 2015 (polled January 25, 2015; passed 85.9%)
- Bonds (September 2013): tradeable real-money items that grant membership; allows wealthy in-game players to subsidize membership with gold, without directly selling gold

### OSRS vs RS3 Divergence and the Poll System

The **Evolution of Combat** (EoC) on November 20, 2012 replaced OSRS-style tick-based combat with an ability-bar system resembling World of Warcraft. A significant portion of the playerbase left or moved to private servers. Jagex responded by opening Old School servers in February 2013 from a 2007 game archive.

**The poll system** became OSRS's defining governance mechanism: all significant content updates require a player vote. Rules:

- Threshold (changed October 27, 2022): content must receive **70% yes votes** (previously 75%)
- Eligibility: total level 300+ and 25+ hours playtime
- "Skip question" votes excluded from denominator
- Three poll types: Lock-in (70% → release), Greenlight (70% → full design proceeds), Opinion Survey (no threshold)
- Exemptions: bug fixes, graphical updates, new game modes do not require polls

The poll system creates a democratic constraint on development — controversial features face a high bar. It preserves the "feel" of 2007 RuneScape while allowing new content to be added (Raids, Sailing, new bosses). The 70% bar also means minority interests can be satisfied if they represent a majority; it structurally rewards backward compatibility.

OSRS's newest skill, **Sailing**, went through multiple poll iterations before passing — illustrating both the power and the friction of the system.

### The Grind Identity

RuneScape's "grind" is not incidental — it is the product. The exponential XP curve, the variety of training methods within each skill, and the tick-manipulation meta create a game where:

- **Efficient play is a skill in itself** — the same actions yield wildly different XP/hr rates depending on tick-awareness. Mining at 134,000 XP/hr (tick-perfect) vs. 63,000 XP/hr (casual) represents a 2x difference from skill, not equipment.
- **Level 92 = halfway to 99** (in XP) creates a psychological inflection: players who "feel close" to 99 at level 92 are actually halfway through the grind.
- **Time-to-max** ranges from ~771 hours (speedrun record) to ~10,000 hours (casual play) across all 24 skills. Peak-efficiency estimate: 2,000–2,500 EHP (Efficient Hours Played).
- The 200M XP cap and virtual levels give endgame players another ceiling to chase.

The grind is tolerated (and celebrated) because each skill is mechanically coherent, the economy rewards skill products, and reaching level 99 in any skill is a recognized community achievement (the "skillcape" cosmetic is iconic).

---

## Technical Layer

### The 0.6-Second Game Tick

The game tick is RuneScape's most distinctive technical trait. The server processes all game state updates in **discrete 0.6-second intervals** (100 ticks per minute theoretical; actual 0.606–0.618s due to server load).

Key properties:

- **Server-side only:** Client UI interactions (right-click menus, interface tabs) run on a separate 20ms loop and are never tick-limited
- **Deterministic ordering:** All player actions registered in tick N are processed at the start of tick N+1. "The tick length is constant throughout a server for all players, which is due to the fact that player's actions are processed in the same order every time."
- **Action rate ceiling:** Movement is exactly 2 squares/tick running, 1 walking. Combat hit delivery is 1 hit per weapon attack speed (measured in ticks). You cannot attack faster than the weapon's tick delay.
- **World population effect:** High-population worlds run longer ticks (World 302: 0.616–0.618s); low-pop worlds: 0.606–0.611s. Servers can "miss a tick" entirely under load.

**Why this simplifies netcode:** The deterministic tick means the server is authoritative over all game state at fixed intervals. There is no need for lag compensation or interpolation of game events — every client simply receives the state at the end of each tick. The client handles animation smoothing between ticks, but game logic is entirely server-resolved. This architecture predates modern netcode concepts like client-side prediction, and works because RuneScape does not require sub-100ms reaction windows for core gameplay.

See [[MMO Netcode and Tick Systems]] for cross-game comparison.

### The Action Queue and Script Priority

Each player has a single queue of pending scripts (actions). Scripts are classified by priority:

| Type | Behavior |
|---|---|
| **Weak** | Cleared by strong scripts, entity interactions, inventory changes, or interface toggles |
| **Normal** | Skipped if player has a modal interface open |
| **Strong** | Removes weak scripts first; closes modal before executing |
| **Soft** | Cannot be paused or interrupted; executes every tick regardless of delays |

Processing loop: iterate the queue indefinitely until all scripts are skipped in one full loop. Critical rule: **if any script sets a delay, all subsequent scripts except Soft are skipped that tick.** This is why certain techniques (like eating food mid-combat) work on exact tick windows — the delay created by one action determines when the next can process.

NPCs have simpler queues (single priority); Area queues handle zone transitions, music triggers, and farming state.

### Tick Manipulation

Tick manipulation exploits the deterministic queue to achieve higher-than-nominal action rates:

**3-tick skilling (fishing/woodcutting/mining):** A normal fishing cycle is 5 ticks. By inserting a specific action combination (e.g., cleaning a grimy herb + processing swamp tar) on the 3rd tick, players reset the skilling timer and restart it, achieving one gather action every 3 ticks instead of 5. This yields approximately **67% more XP/hr** for the same activity.

**1-tick cooking (karambwan):** Opening a new cooking dialogue on the exact same tick a karambwan finishes cooking triggers the next cook immediately, enabling rates exceeding **1,000,000 XP/hr** in Cooking.

**Prayer flicking:** Prayer drain is calculated once per tick. If a prayer was active at the START of a game tick, it provides its buff. If it drains only at tick boundary, activating and deactivating the prayer within each tick means the buff applies but drain never triggers. Expert players maintain protection prayers (Protect from Melee, etc.) indefinitely with zero prayer point cost using this technique. Drain formula: `seconds per point = 0.6 × (drain_resistance / drain_effect)` where base drain resistance is 60 + 2 per prayer bonus point.

Jagex's stance on tick manipulation: **accepted and considered balanced** because it requires skill and effort to execute; it is not patched. This is a remarkable design position — intentional or not, it creates a skill ceiling within what appears to be simple repeated clicking.

### Java Server Engine and RuneScript

The game's server runs in **Java** on Jagex's proprietary **RuneTek** engine (OSRS uses RuneTek 3). Content is authored in **RuneScript**, a C-style scripting language that:

- Compiles to bytecode, interpreted by the Java engine
- Uses type-prefixed variables (`%varname` for integers)
- Powers all quests, NPCs, items, and interactive events
- Allows non-Java-fluent staff to write and ship content without touching engine code

Minor content updates (new NPCs, maps) deploy as individual RuneScript files. Major updates (new skills, areas, bug fixes) require engine source changes. This separation of content scripting from engine code is a mature content pipeline pattern — analogous to GDScript in Godot as a safer scripting interface over the C++ core.

### World Architecture

OSRS runs **258 members worlds + 54 F2P worlds**. RS3 runs 137 worlds. Each world is a **containerized virtual machine** running the Java world application; Jagex runs these on ESXi (migrating to Linux KVM/CFS/PreemptRT for better tick performance).

**Isolation model:**

- **Per-world state:** Shop inventories, NPC respawns, item spawns, resource regeneration — all isolated
- **Global state:** Player skill levels, inventory, quest status, bank — stored in a central database; synced on every world login
- **Cross-world communication:** Only via Friends List private chat and Clan Chat. GE orders resolve universally across all worlds.

**World capacity:** 2,000 players per members world; 1,400 per F2P world.

**World hopping:** Players rapidly switch worlds to exploit per-world shop inventories (buy scarce items multiple times) or find unpopulated resource nodes. Hopping is built into the social contract — resource scarcity is world-local, not universal.

### Client History: Java Applet → NXT C++

RuneScape began as a Java browser applet. A failed HTML5 rewrite (RuneTek 7, 2013–2016) was abandoned due to WebGL threading limitations. The NXT client launched April 18, 2016:

- Written in **C++11** with a hardware abstraction layer for cross-platform support (macOS uses Objective-C shims; web export used Emscripten/JavaScript)
- **Only the rendering layer changed** — the Java-based server engine and RuneScript game logic were untouched; NXT and Java clients played side by side until Java was retired December 18, 2019
- Visual improvements: 4x draw distance, fully dynamic lighting and shadows, asynchronous background map loading (no load screens)
- This "client-server separation" architecture is clean: upgrade the visual layer independently of the game simulation

---

## Lessons for Wayfinder

The key patterns from RuneScape directly applicable to [[MMO Lessons for Wayfinder]] and Wayfinder systems:

1. **Skill-as-verb, no class identity** — OSRS has no "Ranger class," only a Ranged skill. Wayfinder's Trades follow exactly this: no class lock, just trained disciplines. ([[Trades and Leveling]])

2. **Exponential XP curve with a meaningful halfway point** — Level 92 = half the XP of 99. Wayfinder's 17-level cap makes the tail end of each trade feel earned, not infinite. The OSRS formula is the reference design. ([[Trades and Leveling]])

3. **Interlocking skill outputs** — Woodcutting → Firemaking → Cooking is the design pattern for Wayfinder's gather→cook→sustain loop. ([[Gathering]], [[Crafting]])

4. **The deterministic tick simplifies authority** — OSRS's server-authoritative tick model means no client-side cheating of action timing. For Wayfinder's ENet co-op, host-authoritative processing at fixed intervals is the analogous pattern. ([[Multiplayer Co-op]])

5. **The grind is the product** — Players voluntarily create Ironman constraints to deepen the skilling loop. Wayfinder's chart loop (gather → craft → chart → delve) should feel rewarding to repeat, not a means to an end. ([[Chart Loop]])

6. **Quest-as-content-gate** — Skill prerequisites for quests make progression feel earned. Wayfinder's trophy chain (boss trophies unlock deeper dens) is structurally similar. ([[Bosses]])

7. **Grand Exchange as frictionless economy** — Centralizing trades removes social friction but kills emergent trading culture. Wayfinder's Economy avoids a GE by design (Hod's vending is curated, not an open market). ([[Economy]])

8. **Poll system = backward-compatible development** — OSRS's 70% threshold forces new content to serve the majority. A lesson for Wayfinder: new systems should not invalidate existing progression, or players will reject them.

---

## See also

- [[MMO Research]] — the broader MMO survey project this page feeds
- [[MMO Survey]] — comparative metrics across games
- [[MMO Netcode and Tick Systems]] — the 0.6s tick compared to WoW, FFXIV, EVE
- [[MMO Progression Systems]] — skill-based vs class-based across MMOs
- [[MMO Economy and Itemization]] — GE vs auction houses vs barter systems
- [[MMO Social and Endgame]] — Ironman modes, raiding social structures
- [[MMO Lessons for Wayfinder]] — synthesized design takeaways
- [[World of Warcraft]] — class-based MMO for contrast
- [[EVE Online]] — skill queue / passive progression comparison
- [[Final Fantasy XIV]] — class-switching on one character, alt comparison
- [[Design Influences]] — where Wayfinder's design lineage is documented
- [[Trades and Leveling]] — Wayfinder's OSRS-shaped XP system
- [[Gathering]] — parallels to OSRS gathering skill loop
- [[Crafting]] — parallels to OSRS production skill interlocking
- [[Economy]] — Hod's vending vs the Grand Exchange model
- [[Combat]] — tick-influenced design choices for Wayfinder combat
- [[Multiplayer Co-op]] — host-authoritative model vs OSRS server authority

---

## Sources

Full raw provenance with extracted facts and source URLs:
`kb/raw/mmo/runescape.md`

Key primary sources:
- OSRS Wiki — https://oldschool.runescape.wiki/ (Experience, Game_tick, Tick_manipulation, Skills, Polls, Ironman_Mode, Combat_level, Quests, World, Prayer)
- RuneScape Wiki — https://runescape.wiki/ (Grand_Exchange, NXT, RuneScript)
- Wikipedia — https://en.wikipedia.org/wiki/RuneScape
- OSRS Mechanics Docs — https://osrs-docs.com/docs/mechanics/queues/
