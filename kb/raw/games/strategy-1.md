# Raw Provenance — Strategy Case Studies (Batch 1)

Ingested: 2026-06-14  
Agent: Claude Code (game-research analyst)  
Feeds: `wiki/games/strategy/Civilization VI.md`, `wiki/games/strategy/Crusader Kings III.md`, `wiki/games/strategy/StarCraft II.md`, `wiki/games/strategy/XCOM 2.md`, `wiki/games/strategy/Into the Breach.md`

---

## Sources fetched

### Civilization VI (2016, Firaxis Games)
- **https://www.gamedeveloper.com/design/designing-i-civilization-vi-i-s-distinctive-districts-system** — Full article fetched. Primary source. Confirms: Lead Producer Dennis Shirk quote on land-management aspect; population-based district cap (1 per 3 pop); district destroys tile improvements; adjacency bonuses to natural features; encampment defensive ranged attacks; spaceport/seaside resort as late-game replacement improvements. Technical challenge: component-driven art system with 5–6 buildings per district, civilization-specific variants, destructibility tiers.
- **https://en.wikipedia.org/wiki/Civilization_VI** — Search result excerpt. Confirmed: October 2016 release, Firaxis/2K, custom proprietary engine (not Unreal) with day/night cycle, camera rotation, new terrain generation, procedural environmental object placement. Dual tech/civics trees; Eureka/Inspiration boost mechanic (50% cost reduction).
- **https://civilization.fandom.com/wiki/District_(Civ6)** — Search result excerpt. Confirmed specialty district list (Holy Site, Campus, Harbor, Commercial Hub, Entertainment Complex, Theater Square, Industrial Zone, Aerodrome). District cost increases linearly up to +900% as tech/civics are researched.
- **https://www.gamedeveloper.com/design/firaxis-big-swing-with-civilization-vii-convincing-players-to-actually-finish-their-games** — Search result only, not fetched. Not directly cited.

### Crusader Kings III (2020, Paradox Interactive)
- **https://medium.com/@sepehr13n79/detailed-analysis-of-crusader-kings-3-using-the-mda-framework-f1cd575dd382** — Full article fetched. Primary MDA framework analysis. Confirmed: dynasty-as-persistent-entity design; Dynasty Renown currency for Legacies; Lifestyle system (five trees: Diplomacy, Martial, Stewardship, Intrigue, Learning); intrigue/scheme mechanics; character traits driving event outcomes and stress. Dynamics: power struggles, alliance cycles, empire rise-fall. Aesthetics: power/accomplishment, tension, historical immersion, humor from absurd outcomes.
- **https://www.airtel.in/blog/broadband/crusader-kings-iii-review-ruling-a-dynasty-has-never-been-more-immersive/** — Search result excerpt. Confirmed: character-driven design separates CK3 from other grand strategy titles; marriages, alliances, betrayal as primary verbs (not war).
- **https://www.thesixthaxis.com/2019/10/23/crusader-kings-iii-preview-lifestyle-dynasty-religion-accessibility-knights-horse-pope/** — Search result excerpt. Confirmed Lifestyle system preview details. Not fully fetched.
- **Engine:** Clausewitz engine (Paradox proprietary), Jomini successor layer for CK3 3D characters — sourced from general knowledge, confirmed by search result references to Paradox engine family. Flag: no direct URL citation for engine specifics.

### StarCraft II (2010, Blizzard Entertainment)
- **https://simonhalliday.com/2019/09/04/starcraft-ii-a-study-in-asymmetrical-design/** — Full article fetched. Primary source. Confirmed: Terran worker construction loop; Zerg worker consumption + Hatchery larva spawn; time as universal balancing constraint; macro mechanic equivalence (MULE vs. Inject Larva); balance framed as production capacity within time windows rather than per-unit matchups. Notable: Protoss mechanics not detailed in this article.
- **https://liquipedia.net/starcraft2/Game_Balance** — Full article fetched. Confirmed: balance vs. fairness distinction; three balance levers (maps, units/abilities, tech trees); standard nerf/buff terminology. Caveat: article noted balance assessment is difficult until all strategies are discovered.
- **https://www.gdcvault.com/play/1014488/The-Game-Design-of-STARCRAFT** — GDC Vault listing (behind paywall for full content). Listed as source for esports design intent. Not fully fetched; details sourced from search excerpts and prior knowledge.
- **Engine:** Galaxy engine (Blizzard proprietary) — general knowledge, confirmed by search results referencing Galaxy Editor. Lockstep netcode: well-documented SC2 architecture, sourced from general knowledge and competitive RTS literature. Flag: no direct URL citation for netcode architecture specifics.
- **AlphaStar (DeepMind, 2019):** https://arxiv.org/pdf/1105.0755 (balance logistic regression paper in search results) — not fetched; AlphaStar reference from general knowledge.

### XCOM 2 (2016, Firaxis Games / 2K)
- **https://www.gamedeveloper.com/design/a-deep-dive-into-xcom-and-xcom-2** — Full article fetched. Primary source. Confirmed: permadeath consequence depth (class abilities = tactical tools); pod-based enemy activation (fixed spawn positions, not dynamic); monthly cycle structure with fixed mission intervals; cover math (half cover −25%, full cover −50%); concealment mechanics; two actions per turn + attack-ends-turn action economy.
- **https://gamerant.com/xcom-2-procedural-level-detail/** — Search result excerpt. Confirmed: plot-and-parcel system (hand-authored plot + randomly placed parcels); naturalistic bleeding-together encounters; varied tactical options.
- **https://www.gamedeveloper.com/design/xcom-2-and-vision-the-cost-of-an-illusion** — Search result excerpt. Referenced for vision/fog-of-war design analysis. Not fully fetched.
- **https://gdcvault.com/play/1025387/Plot-and-Parcel-Procedural-Level** — Attempted fetch; behind GDC Vault paywall. Speaker: Brian Hess, Firaxis. Summary: "how procedural do your levels need to be to reap benefits while minimizing costs." Specific parcel/plot technical details not accessible without membership.
- **https://en.wikipedia.org/wiki/XCOM_2** — Search result. Confirmed: Unreal Engine 3; War of the Chosen expansion; Steam Workshop modding; Long War 2 total conversion.

### Into the Breach (2018, Subset Games)
- **https://www.gamedeveloper.com/design/reimagining-failure-in-strategy-game-design-in-i-into-the-breach-i-** — Full article fetched. Primary source. Confirmed: Justin Ma quote on unlearning mech-preservation instinct; Power Grid (7 points, city health as true loss condition); mech full heal between battles; pilot XP persistence across mech destruction; 100 hand-designed 8×8 maps (not procedurally generated). Timeline-reset mechanic: one free rewind per run, one pilot carried forward.
- **https://jeremiahgames.com/2019/03/04/perfect-information-the-killer-feature-of-slay-the-spire-and-into-the-breach/** — Full article fetched. Confirmed: perfect information as "mini-puzzle" framing; "when players fail, they can't blame the black box"; nested puzzle granularity (per-turn micro inside per-run macro); parallel with Slay the Spire's enemy intent display.
- **https://en.wikipedia.org/wiki/Into_the_Breach** — Search result excerpt. Confirmed: February 27 2018 release; Subset Games (Justin Ma + Matthew Davis); island sequence structure; procedural scenario generation within fixed island templates; island selection choice after first island.
- **https://medium.com/@stiknork/design-thoughts-on-into-the-breach-9983d24ca62** — Search result excerpt. Confirmed: every number matters; per-damage relevance; tight puzzle per turn.
- **Engine:** Custom (no confirmed engine name found in sources). Two-person team. Flag: engine name unconfirmed — omitted rather than speculated.

---

## Source quality notes

- **Civilization VI**: Strong — primary GDC dev article + Wikipedia + Fandom wiki cross-confirm core design details.
- **Crusader Kings III**: Good — MDA analysis article is secondary (academic framing), but aligns with preview coverage and review excerpts. Engine details (Clausewitz/Jomini) from general knowledge; no direct URL citation obtained.
- **StarCraft II**: Good for race asymmetry and balance philosophy; weak on netcode/engine specifics (GDC Vault paywalled; details from general knowledge). Lockstep architecture is widely documented in SC2 competitive literature but no single fetched URL confirms it.
- **XCOM 2**: Good — GDC deep-dive article is strong; plot-and-parcel details supported by GameRant. GDC Vault plot-and-parcel session paywalled.
- **Into the Breach**: Strong — two complementary design articles plus Wikipedia cross-confirm all major claims. Engine name not confirmed by any source.
