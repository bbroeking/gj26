# Cozy Life-Sim Design Playbook

A condensed reference for designing Harvest Moon / Stardew Valley / Story of Seasons-style farming and life-sim games. Tailored toward small-team / toon-painted / cozy projects (gj26 fits this mold *much* better than a hardcore MMO).

This pairs with `mmo-game-design-playbook.md` — many cross-references below. Where they conflict, **trust this doc** for cozy / farming projects.

---

## 1. The genre — what it actually is

A **rural life-sim RPG** built on these pillars:

1. **Farming** — plant, water, harvest, sell, reinvest.
2. **Town life** — NPCs with schedules, festivals, gift-giving, romance.
3. **Time + seasons** — calendar drives crops, events, energy.
4. **Multiple side activities** — fishing, mining, foraging, cooking, combat (light).
5. **Slow accumulation** — wealth, friendships, and farm scope grow over months.

It's a **routine simulator** more than a goal simulator. The fun is in the rhythm, not the climax.

### The lineage

| Year | Game | Contribution |
|---|---|---|
| 1996 | Harvest Moon (SNES) | Established the loop: farm + town + seasons + 2-year arc |
| 1999 | HM 64 / Back to Nature | NPC schedules, brisk time (5s real = 10min game), still the genre's reference clock |
| 2000s | Friends of Mineral Town, AWL, etc. | Refined relationships, animals, festivals |
| 2014 | Story of Seasons (rebrand) | HM continued under new name |
| 2016 | **Stardew Valley** | Compressed seasons to 28 days, added open-ended endgame, blended in light combat (mines), redefined the genre for a generation |
| 2020s | Coral Island, Roots of Pacha, Sun Haven, Fields of Mistria | Stardew DNA + new wrinkles (multiplayer, biomes, magic, romanceable diversity) |
| 2020s | Animal Crossing: New Horizons | Pure cozy without the farming sim's productivity pressure — different branch of the same tree |

---

## 2. Why cozy games work — the psychology

Cozy game design rests on three core values (from Lost Garden, the cozy genre's founding analysis):

| Value | Meaning | Manifestation |
|---|---|---|
| **Safety** | No looming threat. No permadeath. No real loss. | Faint at 2 AM = wake up next day with minor penalty, not death |
| **Abundance** | Resources are renewable. No genuine scarcity. | Weeds regrow. Money returns. Time loops. |
| **Softness** | Aesthetics, music, language all gentle. | Pastel palette, slow strings, no swearing |

The brain reward: **predictable progress with no real punishment**. Routine becomes a comfort, not a chore. Compare to MMO endgame which deliberately weaponizes anxiety (raid timers, PvP losses) — cozy games invert that.

### Why they're addictive (the paradox)

Cozy games look low-stakes but are mechanically engineered for compulsion:

- **Frequent, small, predictable rewards.** Every crop matures. Every fishing cast pulls. Every NPC gift moves a heart.
- **Multiple overlapping reward schedules.** Tools level up while crops grow while friendships build while festivals approach.
- **Self-directed goals.** The game doesn't tell you what to do — your brain invents goals and chases them.
- **Min-max temptation despite no-pressure framing.** Players will optimize crop layouts, gift schedules, and energy use voluntarily, because the gentle scaffolding *invites* optimization without demanding it.

---

## 3. Core loop — the cozy machine

```
[Wake up]  →  [Plan day]  →  [Do tasks]  →  [Trade energy/time]  →  [Bedtime]  →  [Tomorrow]
   energy    crops, fish,    walk, water,    one tool tier here,    auto-save     income
   resets    NPC schedule,   chat, mine,     one heart there         next-day     compounds
   inbox     festival prep   forage          one fish caught         events       routine deepens
```

### Three nested loops (cozy version)

| Loop | Tick | Activity |
|---|---|---|
| **Micro (seconds)** | One action | Click crop, swing axe, give gift |
| **Meso (one day)** | Single in-game day | Water all crops, talk to 3 NPCs, fish, sleep |
| **Meta (one season)** | 28-day cycle | Plant→harvest cycle, festival, NPC arc, tool upgrade, building project |

A fourth, **mega loop** runs over years: marriage, children, completion (museum, community center), legacy.

### What makes the loop *good*

- **Daily reset feels generous, not punishing.** Energy refills. NPCs forgive. Crops survive overnight.
- **The day has a natural stop.** When energy runs out or it's late, you sleep. No "one more turn" trap.
- **You always feel like you got something done.** Even a "wasted" day produces some growth (foraging, NPC chat, exploration).

---

## 4. Time and seasons — the engine

### Calendar design (Stardew model, the modern standard)

| Unit | Value | Why |
|---|---|---|
| Season | 28 days | 4 weeks of 7 = legible, festivals land predictably |
| Year | 4 seasons = 112 days | Short enough to see all crops in year 1 |
| Day length | ~14 minutes real time | Long enough for a full task list, short enough to feel snappy |
| Time scale | 10 in-game minutes ≈ 7 seconds real | Fast enough for time pressure, slow enough for chat |
| Daily start | 6 AM | Morning ritual energy |
| Forced sleep | 2 AM | Punishment cap, not death |

Harvest Moon classic: **5 seconds real = 10 minutes game** (Back to Nature standard). Faster than Stardew. Tradeoff: more urgency, less time to read dialog.

### Why the 28-day season is brilliant

- **Crop variety** within a season (multiple plant cycles per season).
- **Festival cadence** every ~7 days feels like "something to look forward to" weekly.
- **Friendship progression** is on a slow drip — no single season *finishes* a relationship arc.
- **Player can see all four seasons** in a real-time week. Year-1 closes a meaningful chapter.

### Energy / stamina design

Energy is the **forcing function** that creates choice without imposing failure:

- Every action costs energy. Energy refills at sleep.
- Some actions cost more (chopping a tree > picking a flower).
- Food refills energy mid-day → kitchen / cooking subsystem becomes meaningful.
- Running out of energy ≠ death — minor faint penalty (lose some money, wake up at home next day).

This is a **gentle** time-pressure system — players self-pace, and the worst case is "I had a less productive day."

---

## 5. NPC relationships — the social engine

The system is mechanically simple but emotionally enormous. Stardew's pattern (broadly applicable):

### Hearts (the friendship meter)

- 10 hearts maximum (14 for spouse).
- Each heart ≈ 250 friendship points.
- Sources of points:
  - Talking: ~20 / day
  - Liked gift: +45
  - Loved gift: +80
  - Hated gift: −40 (relationships can *decay*)
  - Birthday gift: 8x multiplier (huge incentive to learn schedules)
  - Quest completion: variable
- Decay: friendship slowly drops if you don't interact (creates pressure to maintain).

### Heart events (the storytelling layer)

At 2, 4, 6, 8, 10 hearts, scripted scenes unlock. Each reveals more of the NPC's backstory and personality. **This is where the real emotional payoff lives** — the gift loop is just the gate.

### Marriage / romance

- Locks at 8 hearts (you can't progress further without commitment).
- Bouquet from shop = "I'd like to date you." Yes/no decision.
- Marriage = move into your house, daily contributions, more dialog, custom heart events.
- Many cozy games now offer **non-romantic** versions (best friend, roommate) — important inclusivity feature in modern designs.

### Why this works

- **Familiarity through repetition.** Daily greetings, schedule memorization → you know "Pierre is at the shop weekday mornings" the way you know your own neighborhood.
- **Schedules.** NPCs walk routes. They're *somewhere* even when the player isn't there. This sells the world's reality more than any cutscene.
- **Gifts as language.** Learning what someone likes is the gameplay form of "knowing them."
- **Players write the story themselves.** The mechanical scaffolding is sparse — your imagination fills in why you're slowly courting Sebastian.

---

## 6. Activity stack — the side hustles

Farming is the headline, but cozy games sustain attention via **parallel activities**, each with its own progression curve:

| Activity | Why include | Stardew example |
|---|---|---|
| **Farming** | Core income, seasonal planning | Crops + animals |
| **Fishing** | Different pace (one-handed, low-energy, meditative) | Mini-game per cast, fish collection |
| **Mining** | Risk + reward, light combat outlet | Procedural mine floors, monsters, gems |
| **Foraging** | Free rewards from walking | Seasonal plants, mushrooms |
| **Cooking** | Resource sink + buffs | Recipes from TV, hearts, mom |
| **Crafting** | Long-term gear progression | Sprinklers, kegs, preserves jars |
| **Combat** | Optional intensity for those who want it | Skull Cavern, slime hutch |
| **Festivals** | Set-piece moments, community feel | Egg Festival, Stardew Valley Fair |
| **Building** | Visible progress at meta scale | Coops, barns, cabins, sheds |
| **Decoration** | Self-expression | Furniture, rugs, fences, paths |

### Design rule: activities must be **complementary, not redundant**.

Each side activity should:
1. **Feed the core** (fish sell well; mined ores upgrade tools that improve farming).
2. **Use a different "muscle"** (farming = planning; fishing = timing; mining = risk; chat = patience).
3. **Have its own progression** (skill levels, recipe unlocks, region access).

If two activities feel the same, cut one or differentiate harder.

---

## 7. Cozy game design principles (rules of thumb)

| Principle | Rule | Why |
|---|---|---|
| **No real failure** | Worst case = minor penalty + fade-to-morning | Safety is foundational |
| **Abundance** | Resources renew. Mistakes are recoverable. | No anxiety hoarding |
| **Soft aesthetics** | Pastel palette, warm light, gentle music | Telegraphs the genre's promise |
| **Optional everything** | Combat optional, marriage optional, completion optional | Player chooses their pressure |
| **Self-directed goals** | Many overlapping unlocks; game suggests but doesn't gate | Lets each player invent their game |
| **Visible incremental progress** | Skill bar, heart count, farm layout, savings | Always something nudging up |
| **Generous time-of-day** | A day fits a full task list with leftover slack | "I had a good day" feeling |
| **Seasonality** | Seasons change content, mood, music | Built-in novelty cycle |
| **NPC presence** | Schedules, dialog rotation, festival appearances | Town feels alive even when player AFK |
| **One forcing function** | Just one (energy or time-of-day, ideally both) | Creates choice without violence |

### Anti-patterns to avoid

- **Permadeath / save loss.** Genre-fatal.
- **Genuinely scarce resources.** Frustration without payoff.
- **Mandatory grinds.** Optional dailies > required dailies (same as MMOs).
- **Time-locked content with no second chance.** Missing a festival once is okay; locking marriage/quests behind a single window kills the relaxed promise.
- **Loud UI / aggressive notifications.** Breaks the calm. Subtle nudges only.
- **Punishing min-maxers.** Players *will* min-max. Reward it without making non-min-maxers feel stupid.

---

## 8. The "tension that makes it work"

Cozy games seem stakes-free but they have a hidden motor: **gentle time pressure**.

- Day ends → you didn't water the parsnips → they'll still be there but you wasted a day's growth.
- Festival is on the 16th → you forgot → it's gone for a year (mild regret, not catastrophe).
- NPC's birthday → didn't bring a gift → no harm, but you missed an 8x friendship boost.

This pressure is **opt-in regret**, not failure. It's the engine of "tomorrow I'll do better." Without it, you have Animal Crossing's sandbox; with it, you have Stardew's loop.

The dial: **how punitive should missed time be?**

| Setting | Result | Game |
|---|---|---|
| No pressure at all | Zen, low retention | Animal Crossing (different design goal — pure cozy) |
| Gentle (Stardew) | Optimal for most | Stardew |
| Heavy (HM 64) | More urgency, more anxiety | HM 64, classic HMs |
| Real failure (Don't Starve) | Not cozy anymore | Survival genre |

For gj26's cozy art direction: **Stardew-level** is the sweet spot.

---

## 9. Open-ended vs ending design

| Approach | Pro | Con | Examples |
|---|---|---|---|
| **Hard ending after N years** | Builds urgency, tells a story | Players quit before re-rolling; replay is friction | Classic Harvest Moon (2-year ending) |
| **Soft ending + open continuation** | Big climax + permission to keep playing | Some players still treat ending as quit signal | Stardew Valley (year-3 evaluation, then open) |
| **Pure open-ended** | Infinite life-sim feeling | No narrative payoff | Animal Crossing |
| **Episodic seasons** | Live-service refresh hooks | Demands ongoing dev | My Time at Sandrock, modern multiplayer cozies |

**Best practice:** ship Stardew's pattern. Year-3 milestone (community center / grandpa eval / completion ceremony), then the world stays open.

---

## 10. Multiplayer + cozy = the gj26 sweet spot

The art direction (RuneScape × Genshin × cozy) and your interest in MMO design point at an underexploited niche: **shared cozy life-sim**. There's a real market here — Stardew multiplayer has 4-player co-op; Coral Island, Sun Haven all added it. Pure cozy MMO doesn't really exist yet.

### Multiplayer cozy design problems

| Problem | Why it's hard | Approach |
|---|---|---|
| **Shared time** | Day/night sync across players in different timezones | Per-player time *or* shared world-time with sleep voting |
| **Energy pacing** | One player rushes ahead, others left behind | Per-player energy; shared world progress |
| **Economy** | Trading dwarfs solo balance | Bind some items to player; tax cross-player trades |
| **Relationships** | Each player needs their own NPC arcs | Per-player heart values (Stardew approach) |
| **Persistence** | When does the world tick? | Server tick when ≥1 player online; pause otherwise |
| **Griefing** | Easy to ruin someone else's farm | Permission system; instanced farms; reversible damage |

### Two design approaches

1. **Shared farm, shared world** (Stardew co-op): everyone on one farm, shared everything. Simple but requires trust.
2. **Personal farm, shared town** (Animal Crossing-ish, Palia, gj26 candidate): each player has their own plot in a shared overworld. Town hub is communal. NPCs have per-player relationships.

For gj26: **option 2** is more interesting and fits the MMO instinct. The town becomes the social space; the farm is the private one.

---

## 11. Decision matrix — small-team cozy life-sim (gj26)

| Decision | Default | Reason |
|---|---|---|
| Day length | 12–14 min real | Stardew norm, room to breathe |
| Season length | 28 days (4 wk = 1 season) | Proven calendar |
| Forcing function | Energy + time-of-day | Both, gentle |
| Failure cost | Faint = wake at home, lose ~10% gold | Safety preserved |
| Activities | Farm + 1 (forage *or* fish) for jam, +mine/cook later | Don't ship 6 systems half-baked |
| NPC count | 6–8 named, 3 romanceable | Small enough to flesh out, large enough to feel like a town |
| Heart system | 5 hearts max for jam (10 later) | Halve the milestones, scope down |
| Combat | Optional, simple, light mob in a "mine" zone | Hits Achievers without breaking cozy promise |
| Multiplayer | Defer or ship "see other farmers in town" only | Real co-op is post-jam |
| Save | Auto-save on sleep | Cozy convention |
| Art | Locked to ART_BIBLE.md style stem | Already aligned |

---

## 12. MVP slicing — jam-feasible cozy slice

**Goal:** prove the daily loop is satisfying for one in-game season (28 days, ~6 hours real time).

**In scope:**
- One farm plot (player's home)
- One town hub with 3 NPCs (shopkeeper, romance candidate, festival-runner)
- Crops: 3 seeds (parsnip, potato, melon — one per growth length)
- Tools: hoe, watering can, axe (no upgrades for jam)
- One side activity: foraging (free berries/sticks/mushrooms in the meadow)
- Energy + day cycle + auto-sleep
- Sell box that processes overnight
- One festival in the season (day 14 or 21)
- Heart meter for the 3 NPCs (5-heart cap)
- Save on sleep

**Out of scope (post-jam):**
- Mining / combat
- Marriage
- Animals (huge content cost — coops, barns, feeding loops)
- Cooking
- Crafting tree
- Multiplayer
- Multiple seasons

This is roughly the original Harvest Moon scope, minus the second year and animals.

---

## 13. "Is this cozy yet?" smoke test

- [ ] Does the first 10 minutes show: wake up, do one task, get one reward, see one NPC?
- [ ] Can you fail in any way that's worse than "lose a day"?
- [ ] Is there one thing growing/improving even on a "bad" day?
- [ ] Is the soundtrack actually warm? (Not just "fantasy-flavored.")
- [ ] Does the camera, font, and UI all feel "soft"? (No sharp red, no FPS HUD.)
- [ ] Is there an NPC schedule the player can learn?
- [ ] Does ending the day feel like a satisfying close, not a forced cutoff?

If any are "no," fix before adding content.

---

## 14. Cross-references to the MMO playbook

| MMO concept | Cozy translation |
|---|---|
| Bartle Achievers | "Completionist" — collection logs, museum, perfection |
| Bartle Explorers | "Wanderers" — secrets, hidden NPCs, rare forageables |
| Bartle Socializers | "Town-folk" — heart events, festivals, decoration sharing |
| Bartle Killers | Mostly absent — light combat in mines optional |
| Sinks/faucets | Money sinks via building upgrades, decorations, gifts |
| Dunbar 50 | Small-town NPC roster of ~25–30 characters total feels right |
| Endgame contradiction | Solved by horizontal completion (museum, perfection score) |
| Combat archetype | Skip/minimize — combat exists to break up routine, not as endgame |
| Daily reset | The day cycle *is* the reset — no separate weekly chores |

---

## 15. References

**Genre design**
- [Lost Garden — Cozy Games](https://lostgarden.com/2018/01/24/cozy-games/) (foundational)
- [Game Developer — Creating Compelling Gameplay in a Cozy Farming/Life Sim](https://www.gamedeveloper.com/design/creating-compelling-and-continuous-gameplay-in-a-cozy-farming-life-sim-adventure)
- [Deep Root Depths — Examining Stardew Valley's Design Principles](https://deeprootdepths.substack.com/p/examining-the-design-principles-of)
- [Indie Game World — How Stardew Revolutionized Farming Games](https://indiegameworld.com/features/how-stardew-valley-revolutionized-farming-games-from-harvest-moon-to-disney-dreamlight-valley/)
- [PC Gamer — Creators of Stardew & Harvest Moon Talk About Farm Games](https://www.pcgamer.com/the-creators-of-stardew-valley-and-harvest-moon-talk-to-us-about-farm-games/)
- [Game Rant — How Harvest Moon Influenced Stardew](https://gamerant.com/stardew-valley-influences-harvest-moon/)

**Calendar / time / pacing**
- [Coppers and Boars — Truncating the Calendar Year like Stardew](https://coppersandboars.com/2021/10/06/truncating-the-calendar-year-like-in-stardew-valley/)
- [Classic Game Zone — Harvest Moon to Stardew Legacy](https://classicgamezone.com/blogs/harvest-moon-retro-platform-legacy)

**Relationships**
- [Stardew Valley Wiki — Friendship](https://stardewvalleywiki.com/Friendship)
- [Stardew Valley Wiki — Marriage](https://stardewvalleywiki.com/Marriage)
- [Stardrop Saloon — Kinship Studies in Stardew (academic analysis)](https://stardropsaloon.criticalvideogamestudies.com/kinship-studies-in-stardew-valley-analyzing-player-immersion-in-character-relationships/)

**Cozy psychology**
- [Fansview — Why Cozy Farming Games Became So Addictive](https://fansview.com/why-cozy-farming-games-became-so-addictive/)
- [Game Rant — Why You Min-Max in Cozy Sims](https://gamerant.com/reasons-min-maxing-cozy-farming-sims/)
- [SDLC Corp — Exploring Cozy Games](https://sdlccorp.com/post/exploring-the-diversity-of-cozy-games-from-farming-sims-to-narrative-adventures/)
