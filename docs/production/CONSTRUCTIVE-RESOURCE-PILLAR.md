---
title: Constructive Resource Pillar
status: initial proposal — narrowed by director call
date: 2026-09-02
owner: game design
depends_on:
  - docs/adr/0003-cozy-skilling-spine.md
  - docs/adr/0016-four-trades-level-23.md
  - docs/adr/0018-authored-charts-single-player-focus.md
  - docs/research/current-resource-crafting-audit.md
  - docs/research/crafting-systems-comparative-research.md
---

# Constructive Resource Pillar

> **Decision status:** this is the full initial proposal, retained as design
> exploration. The adversarial review found the first slice over-scoped. The
> authoritative recommendation is now
> [`RESOURCE-PILLAR-DIRECTOR-CALL.md`](RESOURCE-PILLAR-DIRECTOR-CALL.md): prove
> one raw-material-only Worksite before adding Dust, salvage, global pins,
> pity, overflow storage, or a generalized transaction framework.

## Decision

Wayfinder's resource game is **constructive delving**: every return from a
Hollow should let the Wayfinder make a deliberate next journey, improve a
chosen kit, or visibly tend Bramblewood. The resource system does not add a
parallel Minecraft survival game. It turns the existing `gather → craft →
chart → delve → restore` spine into a legible set of promises:

1. *I know where this comes from.*
2. *I can make one useful thing with it this return.*
3. *My chosen work changes my next Delve or my home.*

The player fantasy is not “extract everything.” It is **a local Wayfinder who
learns what each Road can give, carries its useful remnants home, and makes
Bramblewood more capable because they came back.** Combat earns a place in the
loop by protecting expeditions and targeting creature materials; it does not
replace the Trades as the center of advancement.

This proposal adopts Minecraft's immediate useful conversion, Valheim's
biome/resource/restoration rhythm, Stardew Valley's recipe/source clarity and
recycling, Monster Hunter's targeted goals and safe build correction, Dragon
Quest Builders 2's blueprint-led, Neighbor-assisted worksite, and the
positive-sink principle of Path of Exile. It rejects their scope traps:
freeform voxel building, base-defense upkeep, timer queues, player-market
economies, mandatory repairs, and random reroll gambling.

## Current truth and the production problem

This is an extension of a working system, not a greenfield replacement.

- The Satchel already stores unlimited keyed making goods; the Pack is a
  spatial Gear-only inventory.
- GatherNodes award a material and Earthcraft or Wildcraft XP. Town and Hollow
  nodes use the same channel-and-harvest path.
- The Hearth, Still, Anvil, Ember Kiln, and Chart Table already make real,
  atomic transactions. The Chart Table is the strongest constructive mechanic:
  components and Inks create a seeded Hollow with authored reward/risk bias.
- Gear, boss trophies, campaign clues, Chart case contents, materials, Trades,
  discoveries, and campaign state are already persisted and migrated.
- Chapter settlement already projects authored restorations such as the Trophy
  Hall, Sallow Jetty, Rootroad Lift, Ember Kiln, and Master Forge.

The problem is uneven completion and unclear economic intent. Two Rootroad
Still recipes exist outside the normal Still catalogue; entry fees and repairs
are authored but not live; salvage is planned but absent; resource-source UX
and Pack-overflow recovery are absent; and no all-route validator or economy
telemetry proves that a player can fund a Chapter without unplanned grinding.

Therefore this pillar **does not** add dozens of resources or new generic
benches. It makes the present catalogue truthful, then adds one controlled
salvage lane and optional authored tending projects.

## The loops

| Horizon | Player loop | Desired feeling | Required outcome |
|---|---|---|---|
| One Delve, 5–10 min early / 20–25 min maximum | choose a Chart, gather or hunt, collect Gear/materials, decide return or deepen | “That Road had a character, and I brought something useful back.” | At least one chosen goal advances: recipe input, pinned source, clue, project bundle, or Gear decision. |
| One return, 2–5 min | spend at one station, inscribe the next Chart, salvage one unwanted Gear piece, or add to a Project | “I made a plan, not merely cleared inventory.” | One visible before/after: Satchel count, Chart preview, prepared item, Project state, or loadout change. |
| One Chapter, 60–120 min of first-time play | learn a new resource family, settle a boss Chart, reveal a homecoming, complete one optional tending Project | “This part of Bramblewood works because of my expeditions.” | A new Road/station tier plus one durable village change. |
| Whole campaign, levels 1–23 | develop all four Trades; collect Root Runes/Threads; make Wayweaver | “I became the person who can mend the unfinished Road.” | Wayweaver remains a singular, authored multi-Trade culmination—not a random drop. |

No loop may require real-time production timers, daily chores, a market, or
durability maintenance. A failed Delve costs time and optional preparation,
not previously earned Gear power or Chapter-critical materials.

## Resource grammar and taxonomy

### Normal refinement grammar

The ordinary grammar is capped at **two transformations**:

```text
raw source → refined component → chosen use
```

“Chosen use” is a brew, Ink, Gear frame, charm binding, Chart input, or
Project contribution. A recipe may use raw material directly and skip the
middle step. It may not require a chain of intermediate powders, ingots,
shards, and essences merely to make a normal result. Existing Ink refinement
(`wild herb → Hedge Ink → Refined Ink`) fits the cap; Chart inscription is the
deliberate use of the prepared Ink, not a third refinement tier.

Wayweaver is the sole intentional exception: its named parts make the
cross-Trade finale legible and displayable. Any future exception requires a
human design review and a named campaign payoff.

### Families and destinations

The table is a design contract. “Mercy source” means a slower, bounded
recovery route, never a universal transmutation loophole. Chapter clues, Root
Runes, Threads, and boss-chart escrow remain protected story resources and
are not salvageable, sellable, or purchasable.

| Family | Primary source | Transform | Uses | Sinks / mercy source |
|---|---|---|---|---|
| Earthcraft raw | Copper through Wildgold and Waysteel seams; broken Hollow mechanisms | ore → bar/alloy; direct ore → mineral Ink where authored | tools, Gear frames, charms, stable Bindings, Ember Kiln work | Gear crafting, Chart choices, projects; Hod sells only already-unlocked common materials at a convenience premium |
| Wildcraft raw | herb patches, log piles, Rootroad wells | herb/log → draught, tonic, cord, or Ink | recovery, field preparation, Affix bias, garden/lantern projects | consumables, Chart choices, projects; no timed fermentation queue |
| Huntcraft materials | targeted creature parts, elite/boss trophies, selected encounter rewards | part → motif or field ward; trophy normally remains a campaign input | Boss Charts, named charms/uniques, lodge displays, hunt-focused Chart choices | fixed boss-chart spends with escrow/refund; trophy items never become vendor currency |
| Wayfinding materials | Waymarks, Bindings, Chart Bases, clues, discovered marks | component + Ink → Chart | selected Road, depth/shape, declared Affix distributions, boss pursuit | each Chart is an agency purchase; base components are renewed by ordinary Road play, never Pack clutter |
| Hollow salvage | unwanted Pack Gear and explicitly marked damaged relic drops | Gear/relic → **Mending Dust** (one deterministic project reagent) | tending Projects, non-power restoration finish, bounded charm re-ink | Charmwright conversion; no Gear-to-Gear lottery and no conversion into boss materials |
| Gold | Gear sale, return reward | none | emergency common inputs, a small number of convenience services | bounded merchant purchases and optional presentation services; never Chart-tier tax or repair bill |

`Mending Dust` is a proposed stackable material, not yet implemented. It must
be the only new shared resource in the first slice. Its job is to give low-fit
Gear a dignified, deterministic destination without turning salvage into a
second loot casino.

### Deterministic salvage policy

The future Charmwright Bench is an upgrade attached to Hod's yard, not an
additional town navigation category. Salvaging consumes an unequipped, non-
unique Pack item and returns a fixed quantity of Mending Dust based on its
rarity:

| Item rarity | Dust | Rule |
|---|---:|---|
| Normal | 1 | common clear-out value |
| Magic | 2 | recognizably better return |
| Rare | 4 | meaningful project advance |
| Unique / story / equipped | 0, action unavailable | never destroy a memorable or currently used item by mistake |

The result is previewed before confirmation and is never randomized. Salvage
does not return ore, gold, charm reagents, affixes, or the item's original
inputs. It cannot profit against Hod's sell values or produce a buy → salvage
→ buy loop. Its first release purpose is Project contribution and Pack safety,
not character-power optimization.

## Stations and authored construction

### Five surfaces, tiered rather than proliferating

| Surface | Current truth | Tier policy |
|---|---|---|
| Cottage Hearth | recovery cooking works | Wildcraft recipe bands unlock on the same physical Hearth. |
| Quill's Still | timed preparations work; Rootroad recipes are unreachable in the normal catalogue | Add the level-18/19 Rootroad shelf to this surface after the Rootroad Lift restoration; do not build a sixth brew station. |
| Hod's Anvil / Ember Kiln | forge and later alloy work exist | One Earthcraft workshop family. The Kiln is a visible late upgrade, not a new menu tax. Charmwright is a small attached service, unlocked at its existing Earthcraft milestone. |
| Chart Table | physical staging, Ink mixing, atomic inscription work | Wayfinding tiers add Chart families and Affix capacity/preview, never a separate map bench. |
| Project Board | new, placed near the relevant damaged/restored site | lists a small set of authored tending Projects, source cards, and finished work. It is not a free-placement build menu. |

The station UI must show: required Trade, station/restoration gate, exact
Satchel counts, source card for each missing input, resulting effect, and a
pin action. The existing rule that `Game` owns the transaction remains: UI
only previews and requests a normalized transaction.

### Authored tending Projects

Campaign settlement continues to create its existing required restorations
automatically from boss success. Do **not** retroactively charge materials for
the Trophy Hall, Lift, Kiln, or Master Forge; that would turn narrative victory
into a grind gate.

Tending Projects are optional, finite, authored additions beside those sites.
Each is a **Worksite**, not a freeform build: it presents a damaged site, a
visible future silhouette, an exact material contract, and a nearby Neighbor
who completes the visible work when the contribution lands. This borrows the
feeling of a blueprint becoming a community place without requiring placed
blocks. Each Worksite has damaged → working → tended states, one
Neighbor/Chapter condition, a short bundle, one practical convenience, and one
equal-power appearance choice. They should never unlock mandatory combat power
or the next Chapter.

Proposed first Project: **Lantern Walk**

- **Gate:** First Knot settled and Trophy Hall visible.
- **Bundle:** 6 Logs, 2 Bogiron Bars, 4 Wild Herbs, 4 Mending Dust.
- **Practical payoff:** unlock two persistent recipe/project pins and a Town
  “next source” signpost that points to the pinned material's Road family.
- **Expression:** warm brass lanterns or moss-green lanterns. Both are
  cosmetic only.
- **World result:** before completion, a chalked lantern plan and unlit post
  frames show exactly what will change. After contribution, the responsible
  Neighbor visibly finishes the work, then the Trophy Hall path gains lit
  posts, a named inspectable sign, and a short Neighbor line. Completion
  persists in campaign state and survives save/load.

Later projects should follow the same shape: one per Chapter at most, 3–5
inputs, no more than two resource families plus Dust, and a benefit such as a
source hint, loadout convenience, Project/recipe pin, or non-power décor.
They are a record of care, not a city-builder progression tree.

## Clarity, discovery, and goal selection

Every recipe, project, and Chart component gets a **source card** with:

- current / required Satchel count;
- primary source: Road/biome + action (mine, forage, hunt, return reward);
- minimum Trade and station/restoration gate;
- one mercy source if one exists;
- its useful outputs; and
- `Pin goal` / `Find next` actions.

Critical recipes are never hidden experiments: the story, a Neighbor lesson,
or the relevant Trade level teaches them directly. Optional recipes and Inks
may be discovered through a first pickup, first source interaction, clue,
Neighbor, or Trade milestone. Once discovered, they remain visible even if the
player lacks ingredients. Existing Ink riddles stay as charm; they must be
paired with an actionable source hint after the player has encountered the
relevant source.

A pin selects one active goal, not a long checklist. The HUD can show only the
nearest missing input and a compact action: “Forage Wild Herbs in Snug Roads,”
not a spreadsheet. The Project Board and station panels expose the full card.

## Interaction with the rest of Wayfinder

| System | Pillar rule |
|---|---|
| Charts and Affixes | Charts remain the premier resource sink. Inks and components author a distribution, never a fixed reward script. Resource-affecting Affixes must preview their direction and show visible world evidence. Pinned source cards can recommend a declared Chart family but cannot promise a random room. |
| Four Trades | Wayfinding earns from discovery/completion/restoration; Earthcraft from mining/refining/smithing/salvage; Wildcraft from foraging/chopping/brewing/Ink; Huntcraft from encounters and targeted hunts. Buying and consuming do not award XP. Supporting-Trade gates accompany a Chapter but never demand all four Trades before Wayweaver. |
| Satchel and Pack | All materials, Dust, components, and project bundles live in the Satchel. The Pack stays Gear-only. A full Pack must offer an explicit safe choice before a Gear pickup is lost: equip, salvage when eligible, leave marked at the exit, or send it to a persistent return chest. This policy must be implemented before high-value boss rewards rely on it. |
| Campaign | Clues, Seals, trophies, Root Runes, Threads, and escrow follow existing campaign authority. They are not ingredients for normal projects. Chapter settlement gates a Project's appearance, while Project completion never gates campaign advancement. |
| Saves and migration | Persist `project_state`, chosen visual finish, active pin, source-card discovery, and return-chest contents in the existing versioned save boundary. Projects spend atomically: validate gate, Satchel amounts, and state; record completion; apply materials and world state as one durable transaction. In-progress Delves remain unresumable under the existing controlled refund policy. |

## Anti-grind and economy operating rules

These are launch criteria, not optional tuning advice.

1. **Every selected goal has a route.** A source card always names one primary
   action and, where appropriate, one slower mercy route.
2. **First-clear certainty.** The first eligible completion for a pinned
   Project/recipe family grants a guaranteed component or a guaranteed source
   discovery. Repeat runs provide flexible progress, not permission to begin.
3. **Bounded pity.** After three eligible completed Charts without the pinned
   uncommon material, the next eligible completion grants one. Present this as
   “the trail is getting warm,” not a visible casino meter.
4. **One short run advances something.** A chosen 5–10 minute early Chart
   yields either a needed input, 1 Dust-equivalent from deliberate salvage,
   a clue, a first-clear guarantee, or a useful Gear decision.
5. **Gold is a relief valve, not the loop.** Common, already-unlocked inputs
   may be bought at a premium. Boss, story, and latest-band resources are not
   purchasable. Delete dormant entry-fee and repair data unless separately
   approved and fully implemented; this pillar recommends deletion.
6. **No arbitrage.** Selling then buying, buying then salvaging, and crafting
   then selling must always lose value. A data test enforces it.
7. **Finite care.** A Project stays complete. Cosmetics may expand later, but
   no building has upkeep, decay, raids, or daily resource tax.
8. **Choice before chance.** Crafted output and Project benefit are previewed.
   Randomness belongs to drops and voluntarily authored Chart conditions, not
   to destroying an invested craft result.

### Initial target budgets

These targets are hypotheses to validate with a seeded simulator and five
fresh-player comprehension sessions; they are not economy values to hard-code
without measurement.

| Measure | Early target (Lv 1–8) | Mature target (Lv 9–17) | Deep target (Lv 18–23) |
|---|---:|---:|---:|
| Normal Chart time | 5–10 min | 10–18 min | 15–25 min |
| Time to fund one ordinary next Chart from empty relevant inputs | 1 completed appropriate Chart + Town patch fallback | 1–2 appropriate Charts | 1–2 appropriate Charts, excluding boss prerequisites |
| Normal recipe input families | 1–2 | 1–2 | 1–2, plus named story input only where authored |
| Standard raw cost | 2–6 units | 3–8 units | 3–10 units |
| Project bundle | 10–18 total material units + 4–8 Dust | 16–24 + 6–10 Dust | 20–30 + 8–12 Dust |
| Forced repeat runs for one pinned uncommon | 0 first-clear, then at most 3 | at most 3 | at most 3 |
| Merchant-share of normal inputs | under 25% by count | under 25% | under 20% |
| Pack-full unresolved valuable drops | 0 | 0 | 0 |
| New shared resource types per Chapter | 1 family maximum | 1 family maximum | 1 family maximum |

## Explicit non-goals

- No freeform voxel placement, structural simulation, destructible homes, or
  player housing scores.
- No survival hunger, thirst, crop timers, fuel maintenance, raids, or
  mandatory crafting queues.
- No universal material conversion, global auction house, trading economy, or
  pay-to-progress currency.
- No mandatory durability, repair bills, degradation, or loss of Gear.
- No random reroll loop for invested Gear, no crafting crit lottery, and no
  giant affix text soup.
- No additional long-term inventory Tetris for materials; the Satchel remains
  direct-from-station and the Pack remains Gear-only.
- No replacement of authored campaign restoration with a material toll.

## Human decision gates

These decisions need an accountable human answer before content production
widens the system:

1. **Project payoff:** approve Lantern Walk's source-guidance/pin payoff, or
   choose one different primary convenience. Do not combine shortcut, power,
   recipe unlock, and story escalation in the first Project.
2. **Pack recovery policy:** choose persistent return chest as the default, or
   a clearly safer alternative. The current “leave it in the World” behavior
   is not a production guarantee.
3. **Dormant economy cleanup:** approve deletion of `CHART_TIER_FEE` and the
   `repair_all` ware rather than implementing taxes/repair. This proposal
   recommends deletion.
4. **Salvage boundary:** approve Mending Dust as Project-only in its first
   release, versus allowing it into charm re-inks. Project-only is safer for
   the first economy measurement.
5. **Project expression:** approve purely cosmetic finish choices for launch,
   or fund equal-but-different utility variants with additional balance and
   QA cost. This proposal recommends cosmetic first.
6. **Rootroad Still:** approve exposing Wellmoss Salve and Wellwater Philter
   at Quill's existing Still after Rootroad Lift restoration, instead of
   authoring a separate in-world still.

## Production vertical slice: Lantern Walk

The first slice proves the whole pillar with current early-game content. It
must not depend on the final campaign or require a broad rebalance.

**Player journey:** settle First Knot → see damaged Lantern Walk → pin it →
mine/forage through current Town/Snug content → forge bars and optionally
salvage unwanted Gear → contribute bundle at the Project Board → select brass
or moss-green finish → walk a visibly lit route → use its two persistent pins
to pursue the next Chart/recipe goal.

Success is not “the player has another menu.” Success is five fresh players
being able to answer, unaided: *What does the Project need? Where do I get it?
What did it change? What should I do next?*

### Terra-agent work packages

Packages are independently implementable after their stated dependencies. A
package may add tests and its own implementation notes, but must not rewrite
unrelated systems or treat `Game` as a presentation surface.

| ID | Package | Depends on | Deliverable | Acceptance gate |
|---|---|---|---|---|
| R0 | Content contract and route audit | none | Declarative material/source/use registry covering the first slice's Herbs, Logs, Bogiron Ore/Bar, Dust, Lantern Walk, and related recipe icons. Report unknown IDs, cycles, missing source, or missing consumer. | Headless test fails for a recipe/project material with no known ID/source/display policy; passes current slice data. |
| R1 | Resource transaction seam | R0 | Narrow `ResourceLedger`-style service behind existing `Game` methods for known-ID validation, atomic spend/add, and normalized receipts. No behavior regression. | Existing resource, Chart, inventory, economy, and save tests remain green; each slice spend produces one receipt. |
| R2 | Source cards and pin | R0 | Reusable card component and one persisted active pin; integrate in Forge, Chart Table, and Project Board. | A missing input shows count, source, Trade/station gate, and a Find-next action; pin survives save/load. |
| R3 | Deterministic salvage + Pack recovery | R1 | Charmwright salvage preview/commit, Mending Dust data/icon, and persistent return chest (or approved alternative). | Full Pack + rare drop has a recoverable path across leave/reload; salvaging has exact fixed output, cannot affect unique/equipped/story Gear, and cannot duplicate. |
| R4 | Project state and transaction | R1, R2 | Data-authored Project definition, atomic contribution/complete state, Project Board panel, persistence/migration. | Cannot see before First Knot; partial contributions persist; exact costs spend once; completed Project cannot repay or duplicate. |
| R5 | Lantern Walk world presentation | R4 | Damaged/working/tended Town projection, visible future silhouette/material contract, Neighbor completion beat, both cosmetic finishes, inspect text. | Two saves with different finishes render different visuals but identical mechanics; the future silhouette matches the material contract; no Project node appears from loose materials alone. |
| R6 | Station truth pass | R1 | Rootroad Still catalogue exposure behind restoration, and deletion or implementation of dormant fee/repair data according to the human gate. | Every public economy/station record is visible and transactionally live, or removed; level-18/19 recipe can be made, consumed, saved, and loaded. |
| R7 | Economy simulator and telemetry | R0–R6 | Seeded ledger of sources, spends, purchases, salvage, Chart returns, pin shortages, and Pack-full events; development-only local export. | New-game-to-First-Knot scenario produces a reviewable ledger; all target-budget breaches are reported, not hidden. |
| R8 | Integration and player proof | R2–R7 | Full regression, native and Web smoke extension, five-player comprehension protocol. | 23 canonical gates green; fresh-save slice path works in native/Web; at least 4/5 players identify source, cost, and payoff without external help; failures become prioritized fixes. |

### Dependency sequence

```text
R0 → R1 → {R2, R3}
R2 + R1 → R4 → R5
R1 → R6
{R0…R6} → R7 → R8
```

R0 is deliberately first: without a single source-of-truth content contract,
adding cards, Projects, or new materials would increase the existing drift
between authored data and player-facing availability. R8 is the release gate
for the slice, not an optional polish pass.

## Release evidence for this pillar

The pillar can move from proposed to production-ready only when:

1. Rootroad Still and dormant economy records are made truthful.
2. The material/source validator covers every recipe and Project in the
shipped Chapter bands.
3. Full-Pack valuable Gear has one proven, persistent recovery behavior.
4. Lantern Walk completes atomically, changes Town visibly, survives save
load, and leaves campaign authority intact.
5. The economic ledger demonstrates the stated early targets without vendor
dependence or a forced repeat loop.
6. The existing 23-entrypoint gate and native/Web journey checks remain green.

Only after this proof should the team add the next Project, expanded charm
re-ink, or deeper-band resource content. The game needs stronger legibility
and evidence, not a larger pile of materials.
