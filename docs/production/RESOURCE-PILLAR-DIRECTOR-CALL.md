---
title: Resource Pillar — Game Director Call
status: recommended direction — human approval gate open
date: 2026-09-02
owner: game director
inputs:
  - docs/research/current-resource-crafting-audit.md
  - docs/research/crafting-systems-comparative-research.md
  - docs/production/CONSTRUCTIVE-RESOURCE-PILLAR.md
  - docs/production/CONSTRUCTIVE-RESOURCE-PILLAR-RED-TEAM.md
---

# Resource Pillar — Game Director Call

## Recommendation

Make **constructive delving** a production pillar of Wayfinder:

> What the Wayfinder brings home from a Hollow should help prepare a chosen
> next journey, shape a useful next Chart, or visibly tend Bramblewood.

The construction layer should be a small number of authored **Worksites**, not
freeform block placement. A Worksite shows the damaged place, its finite
material need, and the future silhouette. When the contribution is complete, a
Neighbor helps finish the work and the changed place remains in Town.

This is the recommendation awaiting human approval. It preserves Chartmaking
as the game's differentiator and adds Minecraft-like constructive consequence
without creating a second survival/base-building game.

## What is approved for planning

- The normal making grammar is `raw source → refined component → chosen use`.
  Ordinary recipes stop at two transformations; Wayweaver is the authored
  long-chain exception.
- Resources remain in the Satchel; the Pack remains Gear-only.
- Crafted results and Worksite finishes are previewable and dependable.
  Optional Chart conditions and found Gear may remain variable.
- Campaign restorations remain automatic story consequences. Optional
  Worksites may tend or personalize the restored place, but never charge the
  player again for a Chapter victory.
- The game uses positive sinks: Charts, preparation, chosen equipment work,
  finite tending, and expression. It does not use durability, repair taxes,
  upkeep, production timers, or destructive crafting failure.
- One Chapter introduces at most one main resource family and one new
  transformation. Existing materials should be deepened or collapsed before
  another identifier is added.

## What the first proof deliberately excludes

The first Worksite will not include:

- Mending Dust or any other new shared currency;
- Gear salvage;
- a persistent return chest;
- a global pin/wishlist system or HUD route finder;
- a generic pity framework;
- a generalized Resource Ledger extraction;
- a reusable Project Board framework;
- free placement, building physics, rooms, raids, decay, or upkeep.

These are evidence-led follow-ups. For example, a return chest becomes a
separate release-quality task if measured Pack-full loss warrants it; salvage
becomes a separate prototype only when excess Gear is a demonstrated problem
and at least two real sinks exist.

## Phase A — make the current game truthful

Before adding a Worksite, assign a Terra content-integrity specialist to:

1. Build a read-only **content availability manifest** with distinct policies
   for renewable making goods, crafted/consumable goods, Chart components, and
   protected campaign witnesses.
2. Surface invalid or unreachable promises, starting with the missing
   Wildgold tool outputs, label-only Wildgold/Dawncap unlocks, and two Rootroad
   Still recipes that have no normal station route.
3. Remove or fully implement dormant `repair_all` and Chart-entry-fee records.
   The design recommendation is removal because repair and entry taxes oppose
   the positive-sink rule.
4. Hand-walk and automate the fresh route through First Knot and the first
   Earthcraft lesson. Record actual material availability before setting a
   Worksite cost.

Exit gate: the existing catalogue makes no false player-visible promise, the
manifest distinguishes economic goods from story authority, and all 23
canonical entrypoints remain green.

## Phase B — one narrow Worksite

The recommended proof is **Lantern Walk**, subject to a final location and
payoff review in the running Town.

- It appears after First Knot **and** the first explicit Earthcraft lesson, so
  every required source is already understandable.
- Its provisional bundle is 6 Logs, 2 Bogiron Bars, and 4 Wild Herbs. The cost
  is not locked until the fresh route is timed.
- It has only damaged and completed authority states. The future silhouette
  can be visible before contribution; construction animation is presentation,
  not another durable state machine.
- Contribution is one atomic transaction. The player may choose warm-brass or
  moss-green lanterns; both have identical mechanics.
- The completion beat changes the physical path, adds one Neighbor response,
  and persists through save/load. Its first useful payoff must be chosen at the
  human gate; it should do one modest thing, not unlock a bundle of systems.
- Its local panel shows current/required counts and one plain source line for
  each missing input. No global tracker is assumed.

Route target: from the moment Lantern Walk becomes available, a player who
follows the displayed sources can finish it in no more than two appropriate
ordinary Charts plus Town gathering, without selling or destroying Gear.

## Phase C — human proof

Run five fresh-player sessions on the complete slice. Observers do not teach.
Four of five players must be able to answer:

1. What does the Worksite need?
2. Where do those materials come from?
3. What changed when it was completed?
4. What do you want to do next?

Record time-to-discovery, source confusion, unnecessary repeats, purchases,
abandonment, and whether the completion felt like a contribution or a toll.
If the result fails, revise the source/cost/payoff loop before adding a second
Worksite.

## Evidence-led follow-ups

Only observed problems authorize the next system:

| Evidence | Next Terra assignment |
|---|---|
| Players lose track of a wanted result between Town and Hollow | Prototype one persisted goal card across one Forge recipe and one Chart input. |
| Valuable Gear is regularly stranded by a full Pack | Specify and test a one-owner return-chest transfer independently of salvage. |
| Low-fit Gear remains unwanted after pickup recovery is safe | Prototype deterministic, no-XP salvage with at least two live finite sinks. |
| A targetable uncommon causes repeated eligible Delves with no progress | Add one authored qualifying-source guarantee, not a universal pity system. |
| Repeated feature work collides in direct material mutations | Inventory the mutation paths, then introduce normalized receipts behind stable `Game` APIs. |

## Staffing order

The game director owns the promise and approves each gate. Sol Ultra owns the
dependency plan, staffing, risks, and evidence summary. Terra specialists own
bounded delivery and do not self-approve their work.

1. **Content-integrity Terra** — availability manifest and current truth pass.
2. **Resource/economy Terra** — timed route and provisional cost calibration.
3. **Worksite Terra** — atomic state/contribution plus Town projection.
4. **Crafting-UX Terra** — local need/source presentation and input traversal.
5. **Independent QA Terra** — save, double-spend, state projection, Web, and
   regression attack.
6. **Human playtest producer** — five-session comprehension and desire test.

At most two Terra builders should edit simultaneously, and only one agent owns
`game.gd`, `town.gd`, or another integration hotspot during a slice.

## Human gate

Before Phase A becomes gameplay implementation, confirm these calls:

1. **Construction scope:** authored, Neighbor-assisted Worksites rather than
   freeform building.
2. **First proof:** Lantern Walk as the initial Worksite.
3. **First payoff:** choose one—source guidance, a Town shortcut, or a small
   station convenience. Recommendation: source guidance because it directly
   strengthens the resource loop without adding power.
4. **Economy cleanup:** remove dormant repair/entry-fee promises rather than
   funding durability and Chart taxes.
5. **Release assumption:** confirm Web-first 1.0 or name the primary platform.

Once these are confirmed, Sol Ultra can issue the first implementation brief
and the Terra delivery/review cycle can begin.
