---
title: Constructive Resource Pillar — Red Team Review
status: review — revise before production implementation
date: 2026-09-02
reviewer: game-economy and small-team production red team
reviewed:
  - docs/production/CONSTRUCTIVE-RESOURCE-PILLAR.md
  - docs/research/current-resource-crafting-audit.md
  - docs/research/crafting-systems-comparative-research.md
  - CONTEXT.md
  - docs/adr/0003-cozy-skilling-spine.md
  - docs/adr/0013-vertical-progression.md
  - docs/adr/0016-four-trades-level-23.md
  - docs/adr/0018-authored-charts-single-player-focus.md
---

# Constructive Resource Pillar — Red Team Review

## Verdict

**REVISE, then greenlight a reduced vertical slice. Do not greenlight R0–R8 as
one production initiative.**

The pillar's desired feeling is correct for Wayfinder: resources should buy a
chosen next Chart, a preparation decision, or a visible act of care. That is a
good fit for the accepted cozy-skilling spine and for the existing strongest
system, physical Chart inscription. The proposal is also right to reject
voxel-building, upkeep, repairs, timers, and item-reroll gambling.

The proposed first slice nevertheless bundles **five new systems**—a canonical
resource registry, a transaction/receipt framework, goal routing, salvage,
persistent overflow storage, and project-state/world presentation—before it
has proved one player need. For a small team, that makes the first “constructive
return” more likely to ship as administrative UI and edge-case persistence than
as a satisfying expedition-to-place transformation.

Greenlight only this narrower first proof:

1. make existing station/economy data truthful;
2. add one *raw-material-only*, optional Lantern Walk contribution and its
   damaged/finished Town projection; and
3. test whether players can find, fund, and explain it.

Defer salvage, Pack recovery, pity, a general ledger, and a generic Project
Board until that proof exposes a real need. They are individually reasonable
later systems, but they are not prerequisites for learning whether restoration
is the missing emotional payoff.

## What the proposal gets right

- It protects the core loop instead of importing a second survival/building
  game. ADR-0003 makes cozy skilling the spine, while ADR-0018 makes authored
  Charts the differentiated agency purchase; finite worksites are a better fit
  than free placement.
- It correctly treats Charts as the premier sink. Chart inscription already
  previews, revalidates, spends atomically, materializes a deterministic Chart,
  and only then commits it (`wyrd/scripts/game.gd:11884-11955`). A new resource
  feature should inherit that standard rather than replace it.
- Satchel/Pack separation is a real, valuable constraint. Materials already
  stack in `Game.materials`; the 5×6 Pack is gear-only (`gather.gd:4-6`,
  `inventory.gd:1-18`). The pillar does not accidentally introduce material
  Tetris.
- Automatic Chapter restorations should remain earned story consequences, not
  retroactive material tolls. This respects the campaign authority and avoids
  converting a boss victory into a delayed grind gate.
- “Choice before chance” is compatible with a game that already puts voluntary
  variability in Chart conditions and drops. It should not be copied from Path
  of Exile into crafted-item destruction or rerolls.

## Severity-ranked findings

### P0 — Lantern Walk's Dust requirement creates the first forced-grind loop

**Finding.** Lantern Walk is offered immediately after First Knot but costs
four Mending Dust. Dust only comes from destroying unequipped non-unique Gear.
The Chapter itself has no Earthcraft or Wildcraft gate: First Knot is gated by
Wayfinding 4 for clues and 8 for its boss (`wyrd/data/campaign.gd:75-91`). Its
boss/reprise rewards are valuable rare/unique Gear, while ordinary combat
drops are only 50% likely (`wyrd/data/drops.gd:8-24`). Four Dust therefore
means either discarding potentially useful early vertical-progression items or
repeating Delves until enough low-fit items happen to arrive.

This breaks the stated contract that one short run advances a selected goal.
It also undermines the “constructive, not extractive” promise: the first act of
care is funded by converting the rewards the player has just been taught to
evaluate and equip into anonymous dust.

**Correction.** Remove Dust from the first Project entirely. Make Lantern Walk
an early proof with only 6 Logs, 2 Bogiron Bars, and 4 Wild Herbs—or reduce it
further after a timed fresh-save route. Bogiron is itself Earthcraft 3
(`gather.gd:354-356`), so the Worksite must appear only after the first
explicit Earthcraft lesson, or the source card must say it is unavailable
rather than advertising a false immediate goal.

Introduce salvage only after there are at least two ongoing Dust destinations
and telemetry shows a meaningful rate of full-Pack abandonment. Do not use a
mandatory Dust cost to justify the salvage feature.

### P0 — “Project-only Dust” is an orphaned currency for most of the game

**Finding.** A player who does not want the optional project, or who completes
Lantern Walk, has no stated use for Dust in the first release. Conversely, the
proposal says a short run can advance through “1 Dust-equivalent from deliberate
salvage,” making salvage a de facto reward expectation before the player has a
reason to value it. This is the exact extra currency problem the pillar seeks
to avoid.

**Correction.** Either defer Dust as above, or add it only to a Chapter that
ships with two finite, already-visible Projects and stop awarding/previewing it
before their gates. Keep the first release policy strictly Project-only; do not
also add charm re-inks. A Dust-to-charm lane turns a cleanup currency into
combat power, immediately demanding economy balance, optimal salvage analysis,
and player regret protection.

### P0 — The proposed resource registry has the wrong boundary unless it models story authority

**Finding.** R0 calls for one registry covering “material/source/use,” but the
current Satchel contains several distinct things: renewable raw goods,
refinements, Chart components, consumables, campaign awards, clues, protected
Seals, and Wayweaver inputs. The accepted campaign code explicitly keeps the
Unwritten Road witnesses out of material/refund arithmetic
(`wyrd/data/campaign.gd:54-61`), while Chart components can be granted by
onboarding, completion, rumours, or campaign transitions rather than gathered.
A validator that requires every identifier to have one renewable source will
incorrectly force story records into the economy or report valid authored
content as broken.

**Correction.** Split the proposed registry into a minimum of four policies:

| Policy | Examples | Validator requirement |
|---|---|---|
| renewable making good | ore, herbs, logs, inks | display, source route, consumer or explicit stockpile policy |
| crafted/consumable good | bars, draughts, enchant reagents | recipe/transaction owner and use |
| Chart component | Base, Waymark, Binding | acquisition contract: renewable, starter grant, return grant, or story grant |
| campaign witness | clues, Seals, Root Runes, Threads | campaign authority and no generic spend/salvage/vendor route |

Do not call the table a universal resource registry. Call it a **content
availability manifest**, with `acquisition_policy` rather than a mandatory
“mercy source.”

### P0 — R1 understates migration and mutation scope by calling it a narrow seam

**Finding.** `Game.add_material` and `Game.spend_materials` are small and useful
seams (`game.gd:9972-9993`), but `game.gd` also has many direct
`materials[id] = …` writes for campaign grants, refunds, starter supplies,
Wayweaver actions, save reconciliation, and browser fixtures. Existing
Wayweaver crafting also has its own atomic delta path. A “ResourceLedger-style
service behind existing Game methods” will not yield one receipt per resource
event unless it touches these paths too; then R1 is no longer narrow and risks
breaking the campaign/save boundary.

**Correction.** Make R0 a read-only audit first. In a separate hardening task,
inventory every direct material mutation and classify it as regular making,
campaign authority, migration, or test fixture. Only then introduce a minimal
receipt event for normal `add_material`/`spend_materials` transactions. Keep
campaign/Wayweaver mutation adapters separate until their behavior is proven
unchanged. Do not block Lantern Walk on a general ledger extraction.

### P1 — The Pack recovery requirement is sound, but it is not a small salvage add-on

**Finding.** The current game correctly leaves a full-Pack pickup in the live
scene and notifies the player (`item_pickup.gd:112-132`). That is not persistent
across return, restart, or scene destruction. A return chest changes save
schema, item serialization, ownership, UI, re-entry behavior, duplicate
prevention, and every pickup source. SaveGame currently serializes only the
Pack and equipment explicitly (`save_game.gd:77-105`, `374-393`). “Leave
marked at the exit” cannot be presented as a safe option until it is durable.

**Correction.** Decide the policy before R3 and write a one-page invariant:
one item has exactly one owner among world pickup, Pack, equipment, return
chest, or destroyed-by-confirmed-salvage. The safest first implementation is a
single explicit **Send to Return Chest** action on a failed pickup, immediately
moving that item out of the world; do not promise a later world-scene recovery.
Test boss, chest, crafted, save/load, abandon, death, duplicate scan, and full
chest behavior. Keep it independent from Dust: pickup safety is a release
quality issue even if salvage is deferred.

### P1 — The resource UI is at high risk of becoming a menu layer over the game

**Finding.** The current differentiator already asks players to reason about a
physical 3×3 Chart grid, component types, Ink capacity, Affixes, station gates,
and a Pack. R2 asks to build a reusable source-card/pin system and integrate it
into Forge, Chart Table, and Project Board, while the HUD adds a next-action
prompt. This is four surfaces plus discovery persistence, source-selection
logic, and localisation/voice work. “Nearest missing input” is not a neutral
rule: it produces misleading advice when an input is locked, not yet discovered,
available in multiple places, or less valuable than a prerequisite.

**Correction.** First ship a *read-only missing-input row* on Lantern Walk and
one existing forge recipe. It should show current/required count, a single
plain-language source, and its gate; no global Pin, HUD tracker, or find-next
navigation. Test this with players. Add one persisted pin only if players
still lose their goal between Town and Hollow. The HUD must show one named goal
and **why it cannot progress**, not infer an omniscient best route.

### P1 — The anti-grind rules need an eligibility model before they can be tested or trusted

**Finding.** “First-clear certainty” and “after three eligible completed
Charts” sound player-friendly, but eligibility is undefined. Is a chart
eligible by family, biome, tier, seed, Affix, Trade gate, active pin, room
generation, or completion versus abandonment? The game intentionally preserves
procedural room/content uncertainty while Charts author distributions
(ADR-0018). Without a deterministic source contract, the system can either
promise an item that cannot spawn or silently turn every chosen goal into a
hidden quest override.

**Correction.** Do not build a generic pity system in the first slice. For
critical progression, use existing authored grants and campaign rewards. For
one future targetable renewable, define an explicit `source_family`, a
completion-only counter, a qualifying chart predicate, and a guaranteed reward
slot that replaces—not adds to—one normal payout. Persist counter state only
after that contract exists. A seeded sample audit can test this; an “all seeds,
all routes” promise is disproportionate for a procedural game.

### P1 — The proposed budgets are useful hypotheses, not executable acceptance criteria

**Finding.** Several targets measure incompatible units. A Project “20–30
material units + 8–12 Dust” treats a 1-second herb gather, a two-ore bar, and a
gear destruction as interchangeable. “Merchant share” requires instrumented
player behavior, not a deterministic simulator alone. The current drop table
has randomness and source placement is authored/procedural; the project has no
measured baseline from fresh players.

**Correction.** For Lantern Walk, set one observable route target instead:
from a fresh save at its availability gate, a player who follows the displayed
sources finishes the Worksite in **no more than two ordinary appropriate
Charts plus Town gathering**, without selling or salvaging Gear. Record elapsed
time, missing-input exposure, purchases, and abandonment. Set broad campaign
budgets only after that route and five comprehension sessions exist.

### P2 — The proposal conflicts with its own Trade-XP language

**Finding.** The Trade table says Earthcraft earns from “mining/refining/
smithing/salvage,” but the salvage specification never says whether it awards
XP, how much, or whether that can be exploited by crafting, salvaging, and
recrafting cheap Gear. ADR-0016 requires activity-specific Trade progression;
the pillar correctly says buying and consuming award none. Salvage is a
particularly dangerous ambiguous activity because it destroys a power item.

**Correction.** Award **no Trade XP for salvage** in its initial version.
Treat it as inventory resolution, not craftsmanship. If later testing wants a
salvage mastery fantasy, give it a separately capped, source-aware design and
prove no craft→salvage loop produces efficient XP.

### P2 — “Five surfaces” hides a significant presentation and QA expansion

**Finding.** Calling Charmwright an attachment and Project Board a nearby
object does not reduce the number of supported states. Each requires input,
focus/scan priority, screen/UI contract, disabled/gated view, save/load,
Town placement, screenshots, Web packaging, and regression coverage. Town
already projects campaign settlement from read-only campaign views; adding a
second persistent restoration model must not make scene code infer durable
truth from loose materials.

**Correction.** For the first proof, make Lantern Walk a single inspected
world Worksite with a compact contribution panel, not a general Project Board.
Use a data definition only when a second project demonstrates shared structure.
Keep `project_state` as explicit Game-owned saved state with a pure projection
function, and do not extend the dormant network/campaign replication paths for
a product explicitly focused on single-player (ADR-0018).

### P2 — Terminology will blur the currently coherent ubiquitous language

**Finding.** `CONTEXT.md` defines Chart Table, Satchel, Pack, Gear, Pickup,
and Chapter carefully. The proposal introduces Project, Worksite, Project
Board, Charmwright, Mending Dust, source card, pin, mercy source, and “finish”
without deciding which are player-facing domain terms. It also alternates
between “construction,” “tending Project,” “Worksite,” and “restoration.” That
will make UI, dialogue, tests, data identifiers, and documentation drift.

**Correction.** Before implementation, add only the approved player-facing
terms to `CONTEXT.md`: recommend **Worksite** for the physical place and
**Tending** for the optional contribution, while retaining **restoration** for
the automatic Chapter outcome. Do not expose “Project Board,” “mercy source,”
or “Mending Dust” until their systems are approved. Avoid calling Dust
“Hollow salvage”; it describes an origin, not an item.

### P3 — The two-transformation rule needs a machine-checkable exception policy

**Finding.** The guideline is good, but it currently relies on a semantic
exception: raw herb → Hedge Ink → Refined Ink → Chart is said to be two
refinements because inscription is not counted. Existing deep/Wayweaver paths
already have bespoke multi-part production. Without a per-recipe policy, the
cap will be argued around rather than prevent recipe bloat.

**Correction.** Have the availability manifest tag every recipe output as
`raw`, `refined`, `prepared`, `chart_component`, `consumable`, `gear`, or
`campaign_witness`. Validate that ordinary recipes consume at most one
intermediate making good; require an explicit `long_chain_reason` for a
campaign exception. Do not attempt a universal directed-graph depth rule: it
will misclassify deliberate Chart and campaign grants.

### P3 — The research borrowing needs one Wayfinder-specific success measure per reference

**Finding.** The comparative research is thoughtful, but “Minecraft + Valheim
+ Stardew + Monster Hunter + Builders 2 + PoE” is still a large reference
palette. Most of the proposed systems are derived from different games at
once: wishlists, blueprint sites, recycling, merchant relief, source cards,
pity, optional field preparation, Affix choice, and visual variants. A solo
team cannot tell which borrowed idea caused the player benefit or the friction.

**Correction.** State one deliberate borrowing per vertical slice:

- Lantern Walk: **Builders 2-style finite visible blueprint → communal
  completion beat**.
- Later source clarity: **Monster Hunter-style target card**, only if players
  cannot route themselves.
- Later salvage: **Stardew-style deterministic recycling**, only if excess
  Gear is a measured pain.

The expected Wayfinder-specific proof is always the same: a player returns
from a Hollow, makes one legible choice, and sees their chosen Road or Town
change without reducing Chart authorship to a checklist.

## Revised production plan

### Gate A — truth and route audit (must precede content)

1. Resolve the two unreachable Rootroad Still recipes and delete the dormant
   `repair_all` / `CHART_TIER_FEE` data unless their full mechanics are funded.
   `VendorPanel` currently hides `repair_all` despite `EconomyData` advertising
   it (`vendor_panel.gd:231-234`; `economy.gd:29-63`).
2. Produce a read-only availability manifest for the existing early recipes
   and Lantern Walk inputs. It must distinguish renewable, granted, and
   campaign-protected acquisition policies.
3. Hand-walk and automate one fresh-save route to First Knot, then to the
   proposed Worksite. Do not set its cost until its availability state is
   known.

### Gate B — narrow Lantern Walk proof

1. Create one Worksite with damaged and completed states, one atomic spend,
   one cosmetic choice, and one convenience payoff.
2. Use no Dust, salvage, generic pin system, return chest, or pity mechanic.
3. Present missing counts and one source line in its local panel. Reuse the
   current Game transaction boundary; add a focused save/load and double-spend
   test.
4. Run five fresh-player sessions. A pass is 4/5 players explaining source,
   cost, finished change, and next action unaided.

### Gate C — respond to evidence, not the initial architecture

- If Gear is regularly abandoned: build the return-chest ownership invariant.
- If players cannot route materials: add a single persisted goal card, then
  test it across one forge and one Chart interaction.
- If low-fit Gear remains unsatisfying after safe recovery exists: prototype
  deterministic salvage with no XP and at least two live sinks.
- If a targetable uncommon actually causes repeated completed Charts: add one
  authored qualifying-source/pity contract, not a global system.

## Required test matrix when a system is approved

| Feature | Minimum proof |
|---|---|
| Worksite | gate hidden/visible; exact atomic spend; partial state; complete-once; save/load; both finishes equal mechanically; Town projection does not alter campaign progression |
| availability manifest | unknown ID; missing display; renewable with no source; recipe cycle; protected campaign record incorrectly listed as vendor/salvageable |
| return chest | full Pack; pickup/chest/boss source; save/load; return/abandon/death; one-owner invariant; no duplication |
| salvage | preview equals commit; equipped/unique/story blocked; no XP; no buy/sell/craft arbitrage; no duplicate output |
| goal routing | unavailable gate reason; discovered/multiple source behavior; save/load; HUD never claims a random room is guaranteed |
| economy | measured route duration; purchase share; repeat count; Pack-full rate; abandoned Chart rate; player comprehension result |

## Final recommendation

**Revise.** The design direction is worth pursuing, but the construction layer
must first earn its place as a tiny authored Worksite built from resources the
player already understands. The game does not need a generalized resource
economy to prove that returning home can feel constructive. It needs one
truthful route, one visible transformation, and evidence that players want a
second one.
