---
type: concept
tags: [mmo-research, economy, itemization, faucets-sinks, marketplace, binding, rmt, affixes, loot, inflation, mudflation]
status: draft
updated: 2026-06-13
sources:
  - https://www.gamedeveloper.com/design/the-f-words-of-mmos-faucets
  - https://en.wikipedia.org/wiki/Gold_sink
  - https://oldschool.runescape.wiki/w/Grand_Exchange
  - https://www.gamedeveloper.com/pc/ccp-economist-on-i-eve-online-i-s-pure-capitalist-market
  - https://www.fastcompany.com/3024392/meet-the-alan-greenspan-of-virtual-currency-in-eve-online
  - https://www.ccpgames.com/news/2025/ccp-games-appoints-central-bank-economist-stefan-thorarinsson-to-advance
  - https://www.gamespot.com/articles/ten-years-later-lessons-from-diablo-iiis-auction-house-disaster-have-not-been-remembered/1100-6503489/
  - https://unrealitymag.com/economics-101-with-diablo-3s-real-money-auction-house/
  - https://papers.ssrn.com/sol3/papers.cfm?abstract_id=917124
  - https://www.gamedeveloper.com/design/the-differences-between-random-and-randomized-progression
  - https://wowpedia.fandom.com/wiki/Bind_on_Pickup
  - https://www.notebookcheck.net/Path-of-Exile-co-creator-online-RPGs-must-protect-their-economies-even-if-it-costs-developers-cash.1199206.0.html
  - https://arxiv.org/pdf/2210.07970
---

# MMO Economy and Itemization

A synthesis of how massively multiplayer games design their economic loops — covering faucets, sinks, inflation, virtual marketplaces, item binding, real-money trade, and randomized itemization — with design tradeoffs applicable to Wayfinder's [[Economy]], [[Items and Gear]], and [[Affixes]].

---

## 1. Faucets, Sinks, and the Currency Circulation Problem

MMO economies operate on a **MIMO model** (money-in, money-out): some systems inject currency into the world (faucets), and other systems remove it (sinks). When faucets outpace sinks, the money supply inflates and prices rise; when sinks dominate, currency becomes scarce and trade chokes.

### The faucet side

Classic faucets include:
- **Monster gold drops** and quest rewards — the primary injection mechanism in most RPGs.
- **NPC vendor sales** where NPCs pay players for items (a sell price floor).
- **Activity rewards** (daily/weekly bonuses, login rewards in modern live-service games).

A counterintuitive finding (Scott Hartsman, Trion Worlds; gamedeveloper.com): the largest faucets in many MMORPGs are not gold drops but **item overflow** — players gathering or looting far more items than they need, then undercutting each other to liquidate, which drives market *deflation* rather than inflation. NPC price floors and ceilings (items can never sell below buyback price or above NPC purchase price) naturally bound pure currency inflation, so it is less dangerous than often assumed.

### The sink side

Gold sinks remove currency from circulation. Two categories:

| Category | Mechanism | Examples |
|---|---|---|
| **Passive** | Continuous, low-friction removal | Item degradation/repair costs; listing fees; taxes |
| **Active** | Deliberate player spending at inflated prices | Cosmetic NPC items (Ultima Online blue armour); housing (OSRS Construction skill spends millions with no tradeable output); prestige collectibles (Kingdom of Loathing "meat" drains) |

OSRS's **Grand Exchange 2% transaction tax** (introduced December 9, 2021; raised to 2% May 2025, capped at 5M coins per trade) is a passive sink: Jagex uses collected funds to buy and delete regulated items weekly, simultaneously draining currency and items.

RuneScape's **Construction skill** is a pure sink — players spend tens of millions of gold building houses without receiving any tradeable output. It is considered one of the best-designed sinks because the spending is voluntary, valued socially, and scales with the wealth of high-end players.

### Mudflation: item-tier inflation

**Mudflation** (named after MUD predecessors) is the devaluation of old items when expansions introduce strictly more powerful gear, making former "god-tier" items worthless overnight. It is a form of power creep expressed through the economy.

OSRS mitigates mudflation by favoring **horizontal variety** (new items are situationally better, not categorically stronger) and by maintaining item sinks (high-alchemy, Zulrah scales, GE tax) that preserve demand for lower-tier items.

Diablo III's early economy is the cautionary tale: negligible repair costs and ubiquitous gold drops caused gold stockpiles to balloon into the millions; new players could not afford meaningful gear while veteran players dictated prices. The Loot 2.0 + Reaper of Souls overhaul (2014) explicitly targeted this by redesigning drop rates to make in-game play the most rewarding path to gear, removing the Real Money Auction House entirely.

---

## 2. Marketplaces: WoW AH vs OSRS GE vs EVE Regional Market

The design of a player marketplace determines who can trade, at what friction, and how price information is discovered. The three major models each make different tradeoffs.

### World of Warcraft Auction House

The WoW AH is an **individual-listing model**: sellers post a specific quantity at a specific price; buyers scan listings and purchase individually. Addons (Auctioneer, TradeSkillMaster) are the de facto standard for competitive use.

- Price discovery is manual — skilled players identify underpriced listings and flip for profit.
- No buy limits; sellers can post any quantity.
- Listing fees (silver deposit) and AH cut (~5%) act as passive sinks.
- High friction by modern standards, but creates a rich ecosystem of market play.

### OSRS Grand Exchange

The GE is a **blind order-book with automated matching**: buyers and sellers post standing offers at a price; the system matches them automatically. Players never need to meet, advertise, or wait at the exchange.

- First-come-first-served priority for identical price offers; older offers match first.
- **Buy limits per 4 hours** (item-specific; related items like different-dose potions share one limit): designed to prevent wealthy players from cornering critical items (e.g., buying out the entire supply of Prayer Potions).
- Price guide updates based on recent trade volume and price; low-volume items (partyhats) update every few days.
- Jagex enforces a price range per item to prevent extreme manipulation, and reserves direct intervention rights for scam-enabling cases.
- Passed a community poll at 76.3% approval (released February 26, 2015).
- The GE became a community social hub despite its automation — ironically, eliminating the need to meet counterparties in-game created a gathering point.

**Design tradeoff summary (AH vs GE):**

| Dimension | WoW AH | OSRS GE |
|---|---|---|
| Friction | High (manual browsing) | Very low (automatic matching) |
| Price discovery | Player-driven; favors skilled/informed traders | Emergent from order flow |
| Manipulation protection | Weak (addons provide edge) | Strong (buy limits + price ranges) |
| Social texture | Browsing = light social activity | Asynchronous; reduces face-to-face trade |
| Sink mechanism | Listing fee + AH cut | 2% transaction tax |
| Arbitrage | Viable and rewarding | Reduced (efficient matching flattens spreads) |

### EVE Online Regional Market

EVE's market is the industry benchmark for emergent player-driven economies. CCP hired economist Dr. Eyjolfur Gudmundsson (PhD) in 2007 — the first in-house game economist — to monitor and maintain stability.

- **Single-server (Tranquility)**: all players share one market universe. Regional trade routes, hauling, and arbitrage between stations are entire professions.
- "Pure capitalist" model: no NPC price floors, no government interventions. Supply and demand are fully emergent.
- Prices react near-instantly to announced changes — extremely high market efficiency.
- When CCP removed the Tritanium price cap, the market reacted unpredictably: prices ultimately *dropped* contrary to expectations, mirroring real-world economic behavior.
- Core design insight enabling stability: **everything is crafted, everything can be destroyed** — replacement demand is continuous. Unlike WoW where best-in-slot items persist indefinitely, EVE's destruction loop keeps supply from accumulating.
- In 2025 CCP hired Stefán Þórarinsson (former Central Bank of Iceland economist) for EVE Frontier, continuing the tradition of professional economic governance.

### Free Trade vs Constrained Markets

OSRS Ironman mode (no trading allowed) demonstrates the opposite extreme: players must self-sufficiently gather and craft all resources. This creates a purer skilling experience but eliminates community interdependence.

FFXIV uses a Market Board (AH-style free-market with player-set prices), combined with its specialized crafting/gathering class system (8 crafting disciplines, 3 gathering disciplines) to encourage interdependence — procuring materials for one crafting class often requires 6 others.

---

## 3. Binding Systems: BoP, BoE, and Account-Bound

**Binding** is the primary mechanism MMOs use to prevent items from being freely traded, protecting the core reward loop and reducing RMT incentive.

| Binding Type | Tradeable? | Binds when... | Purpose |
|---|---|---|---|
| **Bind on Pickup (BoP)** | No | Enters inventory | Forces content engagement; eliminates purchase-to-power path; reduces RMT incentive |
| **Bind on Equip (BoE)** | Yes, until equipped | First equipped | Enables secondary market for crafters and off-spec drops; wealthy players can buy in |
| **Account-Bound (BoA)** | Between own characters only | Picked up | Catch-up for alts; no economic leakage |
| **Tradeable** | Freely | Never | Maximum economic participation; maximum bot/RMT incentive |

The design rationale for BoP: if all best-in-slot gear were BoE, wealthy players and gold buyers could trivially skip to maximum power, creating massive bot farming incentives. BoP ties power to time invested in specific content.

The design tension: heavy BoP systems kill crafter economies (crafted gear can't compete with BoP drops), while heavy BoE systems enable pay-to-win via gold purchasing and destroy the value of personal achievement.

WoW's group loot 2-hour grace window is a nuanced solution: BoP drops can be traded between players in the same group for 2 hours post-drop, allowing loot distribution and off-spec trades without making the item permanently tradeable.

OSRS takes a mostly tradeable approach (most gear is tradeable), compensating with the GE's buy limits and the inherent "acquired by doing" prestige of rare drops.

---

## 4. RMT, Gold Farming, and Bot Economies

**Real-Money Trading (RMT)** — selling in-game currency, items, or accounts for real money — is the shadow economy underneath any popular MMO.

Economist Edward Castronova's foundational research ("Synthetic Worlds," 2005; SSRN 2006) demonstrated that EverQuest's "Norrath" had a GDP-per-capita comparable to several real-world countries; by the mid-2000s, RMT trade volume across MMOs had grown to hundreds of millions of dollars annually.

Castronova's analogy: RMT in MMOs is like trading Monopoly properties for real money mid-game — it breaks the social contract the other players implicitly agreed to.

**What gold farming actually damages** (Scott Hartsman, Trion Worlds): not item prices directly, but operational harm — account hacking, credit card fraud, bot armies consuming server load, and chargebacks generating card-network fines for studios. A studio executive was challenged to disclose how much they'd paid in Mastercard/Visa fines over 3–4 years; the implication was the number was substantial.

**Developer responses:**
- Binding systems (BoP/BoE) reduce RMT surface area.
- WoW Token (and EVE's PLEX): developer-controlled RMT that captures demand in-house, funds subscription play-time, and partially drains gold from the economy — converting an underground market into a regulated one.
- PoE's economic integrity stance (Chris Wilson): hard bans + account deletion for economy-disrupting cheating; rollbacks paired with cosmetic (not power) compensation for major exploits. Leagues reset economies every 3 months, limiting the ROI of sustained botting.
- Detection research (ACM CHI Play 2025): trade graph anomaly detection can identify gold-farming clusters with high accuracy.

---

## 5. Itemization: Affixes, Rarities, and Loot Tables

### Rarity tiers

The standard ARPG/MMO rarity ladder (Diablo established the canonical form):

| Rarity | Affix Count | Source |
|---|---|---|
| Normal (White) | 0 | Common drops |
| Magic (Blue) | 1–2 | Standard drops at any level |
| Rare (Yellow) | 3–6 | Higher-level content or crafting |
| Unique (Orange/Gold) | Fixed set of thematic affixes | Specific drops or crafting |

Affix tiers scale with item level — a magic item dropped at level 60 carries higher-tier affixes than the same base dropped at level 10. Base type is locked: a Leather Belt cannot become a Chaos Belt through affix rolls.

### Random vs deterministic reward design

**Randomized progression** (the ARPG standard) differs critically from **pure random progression** (lootboxes). The distinction (Game Developer, gamedeveloper.com):

- Randomized ARPG loot: clear triggers (boss kill, end-of-map chest), quality scales with player level, alternative acquisition paths exist (crafting, trade). Player agency is preserved — they choose when to engage the randomization event.
- Pure random (lootboxes): primary progression is gated behind RNG; no skill mitigation; players can go hours without a meaningful upgrade.

Path of Exile's design principle: Rares are the primary source of player power; Uniques provide special mechanics rather than raw stats. This "make Rares count" design prevents a single unique grail item from obsoleting the entire crafting ecosystem.

Last Epoch takes a deterministic crafting approach: players control which affixes appear and upgrade them deliberately, reducing frustration while encouraging experimentation. This is the furthest the genre has moved from pure RNG.

### The loot treadmill

The **loot treadmill** is the core ARPG/MMO endgame engagement loop: gear upgrades gate access to the next content tier, which drops slightly better gear, which unlocks the next tier. WoW's item level architecture is the canonical example:

- Item level moves in tiny increments (e.g., ilvl 392 → 393 → 395 → 397).
- Each increment is small enough to earn in a single session, large enough to feel meaningful.
- No ceiling: item level can grow indefinitely across patches and expansions.
- Seasonal resets partially invalidate prior gear (new zone quest rewards exceed previous raid drops), converting months of effort into vendor trash — leveraging Loss & Avoidance psychology to drive re-engagement with the new season.

**Catch-up mechanics** soften the treadmill for returning or alt players: WoW tracks your highest item level per slot; upgrading below that floor receives a massive Valorstone/Crest discount. Gear floor rises each patch.

### The Diablo III auction house as itemization failure mode

The D3 RMAH's closure (March 18, 2014) was explicitly an itemization lesson: when the marketplace provides more reliable gear acquisition than the core loop (killing monsters), players route around the loop. The auction house was "short-circuiting the core reward loop." Design takeaway: **the most reliable path to an item must be in-game play, not secondary markets** — or at minimum, the secondary market must not be faster or cheaper than play.

---

## 6. Relevance to Wayfinder

**Faucets and sinks:** Wayfinder's [[Economy]] implements textbook single-faucet/single-sink design: selling dungeon gear to Hod (faucet by rarity: 4/12/35/90g) and buying raw materials and inks from Hod's shelf (sink, priced 3–4× gathering opportunity cost). This is the simplest stable configuration — no leakage paths, no arbitrage.

**No-arbitrage smithing gate:** The automated economy gate (`_test_wyrd_loop.gd::_test_economy_gate`) enforces the equivalent of EVE's "everything crafted must sustain demand" principle — any recipe whose inputs are all purchasable must cost more than its output's sell value. This prevents the D3 auction-house failure mode (marketplace bypasses play loop) inside the crafting system itself.

**Deep ores as BoP equivalents:** Palechalk, starsilver, and hedgesteel ores are never stocked on Hod's shelf, functioning like BoP items — they bind the player to the dungeon loop (tier-2 charts) rather than allowing purchase. See [[Items and Gear]].

**Affixes as randomized-not-random loot:** [[Affixes]] in Wayfinder's [[Chart Loop]] follow the ARPG randomized model: clear trigger (chart inscription), scales with chart tier, alternative acquisition path (crafting different ink combinations). The good/bad twin structure prevents any affix from being strictly dominant.

**No marketplace (single-player):** Wayfinder avoids the AH vs GE tradeoff entirely for the demo. If [[Multiplayer Co-op]] later introduces trading, the OSRS GE's buy limits + blind matching is the most defensible anti-manipulation baseline for a small-scale game. EVE's free market is only stable with hundreds of thousands of players providing enough liquidity.

**RMT/binding:** Single-player eliminates the RMT threat. The equivalent concern is the no-arbitrage gate preventing a player from "farming gold through the forge" — a solo analog to bot economies.

---

## See also

- [[Economy]] — Wayfinder's faucet/sink implementation and no-arbitrage gate
- [[Items and Gear]] — rarity tiers, affix counts, and tier progression
- [[Affixes]] — good/bad twin design and the ARPG affix model
- [[Chart Loop]] — how itemization integrates with the progression loop
- [[Crafting]] — the deterministic alternative path to randomized drops
- [[RuneScape]] — OSRS economy, GE design, and item sinks
- [[EVE Online]] — player-driven market design and the destruction loop
- [[World of Warcraft]] — AH design, BoP/BoE, item level treadmill
- [[MMO Progression Systems]] — the gear treadmill and vertical progression
- [[MMO Social and Endgame]] — how economy design intersects with endgame content
- [[MMO Lessons for Wayfinder]] — cross-cutting design conclusions
- [[MMO Research]] — index of MMO research pages

## Sources

- `kb/raw/mmo/economy-progression.md` — full provenance with quotes and data
- https://www.gamedeveloper.com/design/the-f-words-of-mmos-faucets — faucet/sink theory, Scott Hartsman
- https://en.wikipedia.org/wiki/Gold_sink — gold sink taxonomy
- https://oldschool.runescape.wiki/w/Grand_Exchange — GE mechanics and history
- https://www.gamedeveloper.com/pc/ccp-economist-on-i-eve-online-i-s-pure-capitalist-market — EVE economy
- https://www.gamespot.com/articles/ten-years-later-lessons-from-diablo-iiis-auction-house-disaster-have-not-been-remembered/1100-6503489/ — D3 AH post-mortem
- https://papers.ssrn.com/sol3/papers.cfm?abstract_id=917124 — Castronova, RMT cost-benefit
- https://www.gamedeveloper.com/design/the-differences-between-random-and-randomized-progression — loot table design
- https://wowpedia.fandom.com/wiki/Bind_on_Pickup — BoP mechanics
- https://www.notebookcheck.net/Path-of-Exile-co-creator-online-RPGs-must-protect-their-economies-even-if-it-costs-developers-cash.1199206.0.html — Chris Wilson on economy integrity
