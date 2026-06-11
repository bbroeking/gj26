# 37 — Skill Depth Research: New World Gathering & Crafting

> **Purpose.** Document New World's (Amazon Games) gathering + crafting depth mechanics
> filtered to what transfers to a single-player cozy browser RPG. This is *research input* for
> the gj26 skill-depth spec — it does **not** design Bramblewood's version. Numbers are pulled
> from sources verified in §9; where a source 403'd, it's marked search-only.

---

## 1. The progression spine (0–250)

Every gathering skill (Logging, Mining, Harvesting, Skinning, Fishing) runs **0–250**. The
**0–200** band is the "real" progression (recipe/node unlocks scale here); **200–250** is a soft
extension that mostly feeds **luck** (see §2). Past 250 you bank **Aptitude** levels that roll a
loot/coin container — a flat post-cap reward loop, not new content.

Skill level does two distinct things, and they unlock at **different levels** per node:

1. **Gather level** — the minimum skill to harvest a node tier at all.
2. **Track level** — a higher threshold that lets the node show on your compass/minimap.

Mining ladder (gather / track):

| Material      | Gather lvl | Track lvl |
|---------------|-----------|-----------|
| Iron          | 0         | 25        |
| Silver        | 10        | 35        |
| Oil           | 20        | 45        |
| Gold          | 45        | 70        |
| Lodestone     | 75        | 95        |
| Starmetal     | 100       | 125       |
| Sandstone     | 105       | 130       |
| Orichalcum    | 150       | 200       |

Logging ladder: Young Trees **0**, Mature Trees **50**, Wyrdwood **100** (track 125), Ironwood
**150** (track 200). The pattern is the spine of the whole system: **node tier gates ≈ 0 / 50 /
100 / 150**, and *tracking* always trails *gathering* by ~25–50 levels, so you can chop a tier
before you can reliably *find* it. The reward for grinding the gap is rare-drop luck, not new ore.

---

## 2. Gathering Luck — the headline depth mechanic

Luck is a **bonus added to a die roll**, not a flat drop multiplier. ~82% of New World loot rolls
a **100,000-sided die**; your total luck is added to the result, and rare drops sit *above 100,000*
on the table. So:

- A **100,000** roll table means a rare item that requires >100,000 is unreachable on luck 0.
- Each point of luck lowers the threshold you need to roll. With **+1,000 luck** you have a 1%
  shot at a >100,000 item (you roll 1,000–101,000).
- **Gathering skill itself is base luck**: a level-200 logger carries a **+2,000** logging-roll
  bonus inherent to the skill. Each skill has its own independent luck pool.
- **+1% luck = +1,000 roll** on a 100k table (scales to die size). *(Note: a few secondary guides
  state +1% = +100; the Pacifist RNG source — the canonical community teardown — says +1,000.
  Treat the magnitude as "percent-of-die-size" and pick one convention.)*

Threshold examples (skill-gated rare entry points): **101,000** opens Tier 2/3 rare materials
(needs ~skill 100), **101,800** opens Tier 5 rares (needs ~skill 180). Higher tiers need *both*
skill and stacked luck.

**Stacking sources** (all additive into the same pool): gathering **skill level** (free, baseline)
→ **gear/tool luck perks** (§3) → **gathering-luck food** (§6, a Tier-5 food is the single biggest
buff) → **trophies** (house decor; e.g. a basic loot-luck trophy = +1% rare chance, stackable
across 3 houses) → **territory standing** perks. The single-player takeaway: luck is **one number,
many additive feeders, and skill level is itself the cheapest feeder** — exactly the "number-go-up
surprise" lever.

---

## 3. Tool tiers + tool perks

Each gather skill has its own tool (Logging Axe, Pickaxe, Sickle, Skinning Knife, Fishing Pole).
Tools have **5 tiers**, crafted at rising Engineering levels:

| Tier | Pickaxe example  | Engineering req | Gather speed |
|------|------------------|-----------------|--------------|
| I    | Flint Pick       | 0               | 100%         |
| II   | Iron Pickaxe     | 0               | 125%         |
| III  | Steel Pickaxe    | 50              | 250%         |
| IV   | Starmetal Pickaxe| 100             | 400%         |
| V    | Orichalcum Pickaxe| 150            | 625%         |

Higher tiers = faster channel + more durability + **more perk slots** (early tools have none;
late tools roll **2+**). Tool tier does **not** strictly gate node access in NW (skill level does)
— but a low tier is so slow it's effectively a soft gate.

**Perk types** (each tool type has its own named family; ranges are per-perk roll):

| Perk | Effect | Example range |
|------|--------|--------------|
| **Luck** (Logging/Mining/Harvesting/Skinning Luck) | +rare-item roll bonus while gathering | +2% – +9.3% |
| **Yield** | flat increase to resources gathered | +10% – +19% |
| **Alacrity / Efficiency** | faster gather channel | speed % |
| **Discipline** (Lumberjack's/Prospector's/Tanner's) | bonus-resource / category bonus | varies |
| **Durable** | tool durability up | +25% – +75% |
| **Gathering Recovery** | reduces durability loss per use | varies |
| **Azoth Extraction** | chance for Azoth (travel currency) per gather | varies |

Steal-worthy framing: **a tool is a perk container with 3 axes — speed, luck, yield — and tier
buys you both raw speed and more slots to stack those axes.**

---

## 4. Yield + extra-resource mechanics

Two layers produce the "got 2 instead of 1" feel:

1. **Yield perks** (tool) directly raise the count per gather, +10–19% at T5.
2. **Bonus-resource rolls** off the *same* luck system — high luck/skill rolls can pop an extra
   unit or a tier-up bonus material on top of the base drop. Skill level feeds this (base luck) and
   so do food + trophies. Because yield and luck draw from overlapping inputs, late-game gathering
   feels like every node *might* spit out a surprise rare **and** a doubled stack. The scaling is
   **multiplicative-feeling but additive-mechanically** — exactly why it reads as depth.

---

## 5. Refining chains (raw → refined → component)

Gathered raw → **refined** at a station → **component** for crafting. The five refining skills:
**Smelting** (ore→ingot), **Woodworking** (wood→timber), **Leatherworking** (hide→leather),
**Weaving** (fiber→cloth), **Stonecutting** (stone→block). Cooking is its own thing (§6).

The depth lever is **Yield / Tier-Up Chance**: when you refine, you can roll **bonus output** and,
critically, a chance for the **next-tier refined material** (e.g. craft Iron Ingots, occasionally
get a Steel Ingot's worth of progress / bonus mats). Formula community-derived:

- Base tier-up/yield chance ≈ **Trade Skill Level ÷ 10** → **20% at level 200**.
- Each piece of **refining gear** = **+2% yield**; a full 5-piece set = **+10%**.
- Higher tiers carry a **penalty**: **Tier V refined mats start at −20% base** and gain *no* benefit
  from same-tier refining agents, so only the gear set + skill push them back up. This is deliberate
  — it makes top-tier mats (Asmodeum, Phoenixweave, Runic Leather, Glittering Ebony, Runestone)
  scarce and grindy.

**Quality / gear-score gating:** crafting skill sets the **gear-score floor/ceiling** of output.
Each tier-up with a secondary material adds **+5 min gear score**; using **rare refined mats adds
+15 to min/max**. So *crafting skill + ingredient rarity* jointly determine output quality — the
single-player-friendly idea: **better mats + higher skill = a higher-rolling result, with RNG on
top.**

---

## 6. Cooking specifically (the `cook` model)

Cooking is its own gather→cook→buff→combat loop and the cleanest template for gj26's `cook`.

- **5 food tiers**, recipes gated by cooking level (0 → 150+) and player level.
- **Recipe shape:** one **Primary** ingredient (tier-locked — a Tier-3 dish needs a Tier-3 primary;
  you can't substitute down) + one or more **Secondary** ingredients (any item in the category).
- **Yield scaling:** bonus-output chance rises **+0.10%/level → 20% at level 200**, same engine as
  refining.
- **Food categories:** (a) **Recovery** (e.g. Travel Rations: ~60 HP/s for 20s + regen over 20 min);
  (b) **Attribute** food (+Str/Dex/Int/Foc/Con for a duration — late dishes hit **+40 to +48** to a
  stat for **40 minutes**, gated behind cooking 150–250); (c) **Trade-skill food**, including a
  **gathering-luck food per gather skill** (the biggest single luck buff in §2) and crafting
  gear-score food. Durations scale up with tier.
- **The loop:** gather ingredients in the world → cook a buff food → the buff makes you better at
  *combat or the next gather run* → repeat. Cooking is the connective tissue that makes gathering
  feel purposeful rather than terminal.

---

## 7. Active-gather loop feel

The moment-to-moment loop: **walk to node → hold-to-channel (gather animation + progress bar) →
resource + XP burst + occasional surprise (luck/yield pop).**

- **Channel time** scales *down* with tool tier (faster gather speed) and *up* with node tier —
  Wyrdwood/Ironwood take noticeably longer than Young Trees. (Exact per-node seconds: source 403'd,
  search-only.)
- **Respawn:** nodes respawn on per-type timers (minutes-scale), and NW adds an **anti-camp**
  mechanic: harvesting the same cluster repeatedly makes those nodes **go invisible to you** for a
  cooldown / stop spawning if you don't roam — pushing players to *travel* between nodes.
- **Density/distribution:** nodes are biome-themed and clustered (ore near rock/cliffs, herbs in
  meadows), so *where* you are determines *what* you gather — the map itself is the tech tree.

What makes it satisfying vs tedious: the **progress bar + XP burst** gives a reliable dopamine beat;
the **luck pop** adds variable-ratio surprise; **travel between clusters** breaks monotony; and the
**tool/skill curve** means the same node visibly gets faster over time. Tedium comes from long
channel + low yield + no surprise — avoided by keeping channel short and the surprise rate readable.

---

## 8. STEAL vs DROP (opinionated, for a single-player browser RPG)

| ✅ STEAL | ❌ DROP |
|---------|--------|
| **Gather/Track split** — chop a tier before you can *find* it reliably; tracking as a mid-tier unlock | The full **0–250 grind**; collapse to gj26's existing 3-tier ladder (Brindle/Bogiron/Cinderbloom) |
| **Luck as one additive number** fed by skill + tool + food, with rare drops above a threshold | **Trophies** as house decor / 3-house stacking (no housing system) |
| **Tool tiers = speed + perk slots**; 3 perk axes (speed/luck/yield) | **Territory standing** luck/yield perks (no territories) |
| **Yield perk + bonus-resource roll** ("2 instead of 1" surprise) | **Trading post / economy** — refined-mat scarcity loses meaning solo |
| **Refining tier-up chance** (Skill÷10 → bonus output, chance at next-tier mat) | **Faction bonuses**, war-board, company crafting buffs |
| **Tier-V refine penalty** as a deliberate end-game scarcity knob (tune lightly) | **Azoth / fast-travel currency** tied to gathering |
| **Cooking: tier-locked primary + flexible secondary + timed buffs** feeding combat | **Aptitude / post-250 container** loot loop (no level cap to overshoot) |
| **Gather→cook→buff→combat loop** as the spine that makes gathering purposeful | **Engineering as a separate skill** to craft tools — fold tools into the gather skill itself |
| **Anti-camp roam pressure** via biome-clustered nodes (map = tech tree) | **Per-player node-invisibility** anti-camp tech — overkill solo; use timed respawn instead |
| **Channel + XP-burst + luck-pop** beat for game-feel | Split-attribute foods (NW itself removed them) — keep buffs single-purpose |

**Highest-leverage transfers** (see final note): the additive **luck number**, the **tier-up
refine roll**, the **cooking buff loop**, the **tool = perk-container** model, and the
**channel→burst→surprise** beat.

---

## 9. References

- New World Pacifist — *RNG Explained* (canonical luck/die-roll teardown; verified):
  https://www.newworldpacifist.com/resources/rng-explained
- New World Database — *Chance to Craft Additional Refined Materials* (refining yield formula):
  https://nwdb.info/guides/additional-item-chance *(page 403'd on fetch; numbers cross-checked via search snippet — search-only-verified)*
- Official New World — *Cooking Deep Dive* (food tiers, attribute-food durations/values; verified):
  https://www.newworld.com/en-us/news/articles/cooking-deep-dive
- Fextralife Wiki — *Cooking* (tiers, categories, primary/secondary, yield/level scaling; verified):
  https://newworld.wiki.fextralife.com/Cooking
- ProGameTalk — *Gathering Tools Guide* (tool tiers, gather-speed %, Engineering reqs; verified):
  https://progametalk.com/new-world/gathering-tools-guide/
- StudioLoot — *Gathering Tools Perks* (perk family names per tool; verified — names only, no %):
  https://www.studioloot.com/new-world/articles/gathering-tools-perks/
- StudioLoot — *Crafting for Gear Score and Yield Chances* (Skill÷10 yield, +2%/gear piece, +5/+15 gear score; search-only-verified):
  https://www.studioloot.com/new-world/articles/crafting-for-gear-score-and-yield-chances/
- Game8 — *Mining Leveling Guide 0-200* + StudioLoot Mining/Logging guides (gather/track breakpoints; search-only-verified):
  https://game8.co/games/New-World/archives/339065
- Fandom Wiki — *Luck* and *Trophies* (luck conversion, trophy stacking; search-only-verified):
  https://newworld.fandom.com/wiki/Luck — https://newworld.fandom.com/wiki/Trophies
- The Games Cabin — *All Harvesting Respawn & Gather Times* (per-node channel/respawn seconds; 403'd — search-only):
  https://thegamescabin.com/all-harvesting-respawn-times-gather-times/
- PC Gamer — *1,000 boars luck experiment* (empirical luck confirmation; states +1% = +100, conflicting w/ Pacifist):
  https://www.pcgamer.com/new-world-luck-bonus-percentage/
