# 58 — Wayfinding depth and Mara's Chart Table

**Status:** Slices A–C shipped; Slice D campaign Seals and Deepening is next
(2026-07-17)

> **Outcome:** Wayfinding becomes a craft the player understands with their
> hands. Components are placed on a small charting grid; their arrangement
> deterministically chooses a destination and route shape; inks tune the
> Affix odds; clues and trophies seal authored Boss Charts. The table starts
> with one obvious recipe and grows into the central mastery surface of the
> level-23 game.

This spec deepens, rather than replaces, the shipped Crafting Bench from specs
42–43. It follows ADR 0016 (four Trades, levels 1–23), ADR 0017 (the local Root
Saga), and the campaign ladder in spec 56.

---

## 1. The design call

Use the legibility of Minecraft's crafting table, but do not copy its 3×3
recipe catalogue literally.

- **The recipe is deterministic.** A valid arrangement always produces the
  same Chart family: destination, route shape, tier, and guaranteed encounter.
- **The journey retains uncertainty.** Inks bias which Affixes appear and how
  likely their good twins are. The preview shows honest odds before the player
  spends anything.
- **Discovery is earned.** Unknown valid arrangements can be tried; success
  records the Chart Recipe permanently in Mara's Codex.
- **Failure is gentle.** An invalid arrangement consumes nothing. A failed
  dungeon attempt spends ordinary materials but returns irreplaceable story
  trophies and permanent relics.
- **The table is not a universal crafter.** Hod's Smithy, Quill's Still, and
  Maud's Hearth retain their own verbs. The Chart Table belongs to Wayfinding.

The compact rule is:

```text
Chart Base + Waymark + Binding + optional Seal = which Chart
Inks + Wayfinding mastery                         = how that Chart behaves
```

This keeps the output comprehensible. A player should be able to say, “the
mire reed sends me to the Sallow Mire; the knotted binding makes it a maze;
the mothglow ink courts fog; the tusk seal calls the Boar.”

---

## 2. The component grammar

### 2.1 Component families

| Component | Answers | Mechanical role | Consumption rule |
|---|---|---|---|
| **Chart Base** | How much can this page hold? | Sets tier, base cost, and socket budget | Always consumed when a Chart is inscribed |
| **Waymark** | Where does the road lead? | Selects biome / destination family | Consumed on inscription |
| **Binding** | What shape does the road take? | Selects Snug, Hollow, Maze, Descent, or Mythic topology | Consumed on inscription |
| **Ink** | What is the road likely to contain? | Biases Affix weights and good-twin stability | Consumed on inscription |
| **Seal** | Whom or what must the road find? | Guarantees a boss, story room, or named hunt | Ordinary seals are consumed; irreplaceable relics are references, never spent |
| **Relic** | Which old roads authorize this? | References permanent Root Runes in late mythic recipes | Never consumed |

### 2.2 Initial component ladder

These names are a content proposal. Existing item IDs and trophies should be
reused wherever they already express the same idea.

| Band | Chart Base | Waymarks | Bindings | Seals |
|---|---|---|---|---|
| Arrival 1–4 | Practice Leaf, Field Parchment | Hedge Sprig | Soft Fold, Loop Cord | none |
| Hedge 5–8 | Stitched Parchment | Hedge Sprig, Thorn Rubbing | Loop Cord, Briar Knot | Thorn Essence / Hedgemother |
| Mire 9–12 | Waxed Vellum | Mire Reed | Hollow Stitch, Sunk Knot | Tusker Tusk / Burrow Boar |
| Summit 13–17 | Atlas Folio | Cold Track, Crown Thorn | Maze Lace, Climbing Cord | Alpha Fang, Crown Seal |
| Rootroads 18–19 | Rootskin Leaf | Oath Rubbing | Pale Binding | Oath Nail / Barrow Jarl |
| Ash Bough 20–21 | Ember Folio | Ember Verse | Cinder Binding | Starheart Coal / Hearth Giant |
| Unwritten 22–23 | Nine-Knot Leaf | Lost-Waymark Tracing | Threefold Binding | Wyrm Scale; Map and six Root Runes witnessed |

The component families make content expansion cheap: a new biome normally
needs one Waymark, one visual landmark kit, a small Affix set, and optionally a
new Binding. It does not need a second crafting system.

---

## 3. The physical table

The table uses a 3×3 **charting grid** plus a four-pot **ink rail**. Unlike a
generic inventory grid, each region carries meaning. Keeping inks on their own
rail preserves the shipped one-to-four-ink mastery ladder without forcing Ink
positions to masquerade as route recipe positions.

```text
                  INK RAIL
          [ INK 1 ][ INK 2 ][ INK 3 ][ INK 4 ]

┌─────────────┬─────────────┬─────────────┐
│  WAYMARK    │   WAYMARK   │   WAYMARK   │  destination / route heading
├─────────────┼─────────────┼─────────────┤
│  BINDING    │ CHART BASE  │  BINDING    │  page and route topology
├─────────────┼─────────────┼─────────────┤
│    RELIC    │    SEAL     │    RELIC    │  permanent story authority / target
└─────────────┴─────────────┴─────────────┘
```

Not every recipe fills every cell. Repetition is meaningful:

- one Waymark draws a normal biome Chart;
- two matching Waymarks target that biome's uncommon rooms;
- three matching Waymarks are a late-game targeted expedition;
- one Binding chooses a familiar route shape;
- two matching Bindings deepen or lengthen the route;
- two different Bindings produce a hybrid only after its recipe is discovered;
- the Seal cell is always singular so a Chart cannot promise two bosses; and
- Relic cells light only for late mythic recipes and reference permanent Root
  Runes without removing them from the Trophy Hall.

### 3.1 Progressive disclosure

The whole grid is visible from the beginning as a carved pattern, but unopened
cells are dark and labelled with the Wayfinding level that reveals them.

| Wayfinding milestone | Table growth |
|---:|---|
| 1 | Center Base, one Waymark, first Ink pot |
| First Snug return (normally 2) | First Binding cell; Green Hollow lesson |
| 4 | Second Ink pot |
| 6 | Living Atlas link |
| 8 | Seal cell; first Boss Chart lesson |
| 10 | Third Ink pot and second Waymark |
| 14 | Second Binding cell; hybrid route recipes |
| 17 | Fourth Ink pot; matching Bindings can deepen a completed campaign Chart |
| 19 | Third Waymark; targeted clue expeditions |
| 22 | Relic cells; Root Rune recipes |
| 23 | The Nine-Knot arrangement and Unwritten Chart |

The table therefore grows with the player. It never opens as nine unexplained
slots.

---

## 4. Output rules

### 4.1 What is guaranteed

Before inscription, the result card always names:

- destination and biome;
- route shape and expected room count;
- tier and recommended Trade band;
- guaranteed story room, boss, or resource room;
- material cost and which items are returned after a failed boss attempt;
- number of Affix rolls;
- every possible Affix family with its current percentage; and
- the chance of each rolled Affix resolving to its good twin.

### 4.2 What remains hidden

The table does not reveal:

- the generation seed;
- the exact spatial layout;
- which optional event room will appear;
- the final Affix roll before inscription; or
- the boss's full move set before the player meets it.

The player authors the promise, not the floor plan.

### 4.3 Resolution order

```text
1. Match the placed components to a Chart Recipe.
2. Resolve the deterministic output: template, biome, topology, tier, Seal.
3. Compute Affix weights from the output plus all placed inks.
4. Apply Wayfinding perks and stability.
5. Roll Affixes and good/bad twins.
6. Generate the seed and create the finished Chart.
7. Record a first-time recipe discovery and update the Living Atlas.
```

Invalid layouts stop after step 1 and spend nothing.

---

## 5. Example recipes

| Arrangement | Output | Lesson |
|---|---|---|
| Practice Leaf + Hedge Sprig + Hedge Ink | **Snug Chart** | Base, Waymark, Ink |
| Field Parchment + Hedge Sprig + Loop Cord + any Ink | **Green Hollow Chart** | Binding changes route shape |
| Stitched Parchment + Thorn Rubbing + Briar Knot + Ash Ink | **Briar Maze Chart** | Destination and topology combine; Ink courts groves |
| Waxed Vellum + Mire Reed + Sunk Knot + Mothglow Ink | **Sallow Mire Chart** | Biome-specific preparation |
| Waxed Vellum + Mire Reed + Sunk Knot + Tusker Tusk Seal | **Burrow Boar Boss Chart** | A Seal makes the encounter deterministic |
| Atlas Folio + Cold Track ×2 + Climbing Cord ×2 + Alpha Fang Seal | **Queen's Summit Chart** | Deep authored expedition |
| Atlas Folio + Pale Wellmark + Climbing Cord ×2 + Stoneground Ink | **Pale Veins Chart** | A physical road recipe; Oath-Rubbings remain ledger facts |
| Atlas Folio + Barrow Mark + Pale Wellmark + Cold Track + Climbing Cord ×2 + Oath Nail + Stoneground Ink | **Barrow Jarl's Watch** | The Oath Nail seals the authored Pale Oath boss road |
| Nine-Knot Leaf + Lost-Waymark Tracing ×3 + Threefold Binding ×2 + Wyrm Scale Seal + Map of Nine Knots and six Root Runes witnessed | **Unwritten Chart** | Whole-game capstone recipe; ledger clues and permanent story records are never spent |

Exact quantities can be tuned in balance. The readable relationship between
inputs and output is the invariant.

---

## 6. Recipe discovery and Mara's Codex

The existing ink experiment becomes one part of a larger discovery book.

Each Chart Recipe has one of four states:

1. **Unknown** — a blank silhouette; no name or ingredients.
2. **Rumoured** — an NPC riddle or found sketch shows two or three clues.
3. **Attemptable** — the player owns the required component families; the
   table can say “a road is taking shape” without naming the result.
4. **Known** — exact ghost layout, output card, source notes, and “stage recipe”
   shortcut are available forever.

Discovery sources:

- Mara's lessons and marginal notes;
- rubbings and chart scraps found in guaranteed clue rooms;
- boss trophies placed on the table for the first time;
- restored panels in the Living Atlas Hall;
- short NPC riddles from Hod, Quill, and the chapter keeper; and
- player experimentation.

The recipe book assists without replacing the physical act. Selecting a known
recipe places translucent **ghost ingredients** on the table. Clicking a ghost
pulls one matching item from the Satchel if available. “Stage all” arrives at
Wayfinding 3 through Practiced Measures.

No recipe is unlocked by merely levelling. A level may reveal a new socket or
permit a component, but the player still learns the arrangement in the world.

---

## 7. Wayfinding 1–23: a deeper identity

Spec 56 remains the cross-Trade ladder. This table states what Wayfinding is
teaching at each level, not only what content appears.

| Lv | Wayfinding lesson / reward |
|---:|---|
| 1 | Read a Base, Waymark, and Ink; inscribe Snug and a Tier-1 Hollow |
| 2 | **Mara's Marginalia:** all early recipe riddles become readable |
| 3 | **Practiced Measures:** stage any known recipe from the Codex |
| 4 | Open the second Ink pot; discover Bramble Bloom |
| 5 | First mastery choice: **Careful Hand** (stability) or **Curious Hand** (discovery returns) |
| 6 | Open the first Binding cell; restore the Living Atlas foundation |
| 7 | Learn doubled Waymarks and route targeting; Wood Grove / Festival Pace |
| 8 | Open the Seal cell; craft the Hedgemother Boss Chart |
| 9 | Pin one favourite recipe to the table; discover Gilded Hollow |
| 10 | Open a third Ink pot and second Waymark; inscribe full Hollow Charts |
| 11 | **Re-ink:** replace one unsealed Ink before a Chart is used, paying the replacement pot |
| 12 | Learn the Mire Reed recipe family and Burrow Boar Boss Chart |
| 13 | Atlas forecasts one guaranteed special room before inscription |
| 14 | Open the second Binding; discover hybrid routes and Wolf Alpha Boss Chart |
| 15 | Restore the Skald Archive; target one campaign clue family |
| 16 | Read dangerous Affix twins before rolling the Summit approach |
| 17 | Open the fourth Ink pot; **Deepening I:** matching Bindings add a layer and a guaranteed Hearth |
| 18 | Learn Rootskin pages and Pale Veins Charts |
| 19 | Open the third Waymark; targeted clue Charts gain visible pity progress |
| 20 | Learn Ember Folios, Cinder Bindings, and Ashen Bough Charts |
| 21 | **Deepening II:** deepen a Boss Chart for its unique reward family, never for story access |
| 22 | Open the Relic cells; combine Root Runes without consuming them |
| 23 | Complete the Map of Nine Knots and inscribe the Unwritten Chart |

### 7.1 Mastery choices

Wayfinding mastery should change how the player uses the table, not add flat
combat damage. Candidate choice tiers:

| Tier | Choice A | Choice B |
|---:|---|---|
| 5 | **Careful Hand:** +5 good-twin stability | **Curious Hand:** better returns from failed Ink experiments |
| 10 | **Sure Route:** preview one more possible Affix | **Long Route:** one more optional room, with a small hazard increase |
| 15 | **Archivist:** clue-targeting inks are stronger | **Surveyor:** special resource-room targeting is stronger |
| 20 | **Binder:** first Deepening costs one fewer Binding | **Threader:** Mythic Affixes gain a little more good-twin stability |

Choices can be re-inked at the Chart Table for a meaningful but renewable Ink
cost. The player is choosing a working style, not making a permanent mistake.

---

## 8. XP and economy rules

Wayfinding XP comes from keeping charting promises:

- completing a Chart is the main repeatable source;
- first-time Chart Recipe, Ink, Waymark, and Affix discoveries pay one-time XP;
- restoring a Living Atlas region pays a milestone award;
- first biome and Boss Chart clears pay authored bonuses; and
- an invalid table arrangement pays no XP because it costs nothing.

Repeated inscription alone pays no XP. Otherwise the optimal strategy becomes
crafting and discarding pages instead of travelling the roads.

The renewable sinks are Bases, ordinary Waymarks, Bindings, and Inks. Campaign
clues live in the Ledger. Root Runes and irreplaceable trophies are referenced
by a recipe rather than consumed. Boss defeat can consume renewable parts, but
must return the unique Seal so a failed fight never forces story replay.

---

## 9. Onboarding storyboard for the table

The first-session teaching sequence remains short and hands-on.

1. **Mara gives one Practice Leaf.** Only the center cell glows.
2. **Place the Base.** The Waymark and Ink cells wake up.
3. **Place the Hedge Sprig.** The result becomes “A small, kind road.”
4. **Mix and place Hedge Ink.** The Snug Chart receives its name and exact cost.
5. **Take the finished Chart.** A stamp, fold, and string animation plays.
6. **Complete the Snug.** The return card connects the table inputs to what was
   encountered: “Hedge Sprig → Bramblewood; Hedge Ink → no harsh surprises.”
7. **Second craft:** Mara gives a Loop Cord. The player sees the same destination
   become a Hollow because the Binding changed.
8. **First Affix craft:** the player adds a second Ink and reads honest twin odds.
9. **First Boss craft:** after the clue threshold, the Seal cell wakes; no other
   new table concept appears during that lesson.

At no point does the tutorial display the complete level-23 recipe catalogue.

---

## 10. UI contract

The screen has four stable regions:

1. **Satchel tray** — compatible components first, incompatible ones still
   visible but clearly labelled.
2. **Charting grid** — large physical objects, drag or click-to-place, readable
   locked cells.
3. **Result card** — guaranteed facts first, weighted possibilities second,
   cost and return rules last.
4. **Mara's Codex** — collapsible recipe pages, rumours, ghost layouts, and
   discovery history.

Required feedback:

- the custom cursor changes over a draggable component, valid cell, invalid
  cell, result, and Codex page;
- invalid placement explains why in one short line and snaps back;
- odds animate from old to new values when an Ink is added;
- guaranteed content uses a seal icon and the word **Guaranteed**;
- uncertainty uses percentages and text, never colour alone;
- the final action is **Inscribe Chart**, not Craft; and
- taking the output uses a tactile stamp / fold / string animation rather than
  instantly disappearing into the Chart Case.

---

## 11. Data model

Keep the existing Chart dictionary as the runtime output. Add recipes and
components as authored data rather than hard-coding combinations in the panel.

```gdscript
const CHART_RECIPES := {
    "green_hollow": {
        "req_wayfinding": 1,
        "pattern": {
            "n": "waymark:hedge_sprig",
            "c": "base:field_parchment",
            "sw": "binding:loop_cord",
        },
        "output": {
            "template_id": "tier_1",
            "biome_id": "bramblewood",
            "topology_id": "hollow",
        },
        "rumour_id": "mara_first_loop",
    },
}
```

The resolver returns a pure preview object. Recipe-required Ink is separate
from optional Affix-bias capacity: Snug visibly requires exactly one Hedge Ink
on the rail, but has zero optional bias pots and therefore no Affix odds.

```gdscript
resolve_chart_recipe(placed_components, ink_ids, seal_id, wayfinding_state)
    -> {
        valid,
        recipe_id,
        known,
        output,
        costs,
        guaranteed,
        affix_weights,
        stability,
        returned_on_failure,
        reason,
}
```

Slice B evolves this compatibility signature into a canonical draft and two
deep operations:

```gdscript
preview_table({"grid": {...}, "ink_rail": [...]}, wayfinding_context)
materialize_chart(preview, seed)
```

The same preview and seed must materialize the same finished Chart. The UI
never spends inputs; `Game.try_inscribe_chart(...)` re-resolves live state,
materializes first, then commits costs, Chart insertion, first discovery, XP,
signals, and save exactly once.

The UI renders this object and performs no recipe math. Inscription uses the
same resolved object, so the preview cannot disagree with the finished Chart.

---

## 12. Migration from the shipped bench

Do not throw away working systems.

- Existing Chart templates become recipe outputs.
- Existing Ink IDs, weight math, stability math, and Affix rolls remain.
- Existing trophies map to Seals.
- Existing discovered Inks remain discovered.
- Existing crafted Charts remain valid and playable.
- The current tray, pot, result card, guided highlights, and click-to-place
  interactions are evolved into the charting grid.
- Old saves receive the basic recipes corresponding to every template they had
  already unlocked under the pre-23 progression model.
- Until Waymarks and Bindings have art, they use deliberate sketch placeholders
  registered through the icon manifest—not font glyphs.

This is a presentation and recipe-identity deepening first. Affix math should
not be rewritten in the same implementation slice.

---

## 13. Recommended implementation slices

### Slice A — recipe resolver, no UI replacement

- [x] Add component and Chart Recipe registries.
- [x] Map the current six templates to six equivalent recipes.
- [x] Build a pure resolver and contract tests.
- [x] Keep the shipped bench UI driving the old calls through the resolver.

**Gate:** passed 2026-07-17. Current Chart dictionaries remain unchanged,
pre-Slice-A saves backfill every legacy recipe available at their restored
Wayfinding level, and all six suites pass (598 checks total).

### Slice B — the physical 3×3 table

- Replace the center sockets with the charting grid.
- Add Base, Waymark, Binding, Ink, and Seal placement validation.
- Render one shared preview object.
- Update the guided Snug tutorial.
- Store ordinary components in the existing material stacks. Mara's table
  supplies renew them for gold after the lesson; before the first Snug clear,
  missing Practice Leaf / Hedge Sprig supplies recover for free.
- Fresh saves know Snug only. The first return grants Field Parchment, Loop
  Cord, and one Hedge Sprig once; Green Hollow becomes known only when its
  attemptable arrangement is successfully inscribed.
- Make inscription deterministic from an explicit seed and atomic in `Game`.
  First discovery and its one-time Wayfinding XP join the same commit.
- Add focusable keyboard/controller placement and host-authoritative co-op
  enforcement. Guests may inspect but cannot inscribe.
- Migrate existing saves once using the maximum component multiplicity needed
  by their known legacy recipes; never grant Inks, Seals, trophies, or Relics.

**Gate:** a fresh player can produce and run Snug without reading prose; every
invalid, stale, repeated, unaffordable, full-case, and guest commit consumes
nothing.

### Slice C — discovery and Codex

- Add Unknown / Rumoured / Attemptable / Known states.
- Add ghost staging and Practiced Measures.
- Present rumours, source clues, discovery history, and ghost recipes. Slice B
  already owns the authoritative successful-discovery save + XP transaction.

**Gate:** three undiscovered arrangements can be inferred from in-world clues,
and an invalid arrangement consumes nothing.

**Gate passed 2026-07-17:** Green Hollow arrives with Mara's first-return
lesson; a completed Tier-1 Chart reveals the Living Atlas's Deep clue; and a
completed Deep Hollow reveals Mara's rain-stained Sallow clue. Both physical
sources are anticipatory before their Wayfinding thresholds, award a
missing-only component lesson once, and leave experimental inscription as the
only recipe-discovery commit.

### Slice D — campaign Seals and Deepening

#### D1 — First Knot campaign Seal

- Add three guaranteed Thorn Whispers to successful Green Hollow returns.
- Move the Hedgemother Boss Chart onto a first-class Seal contract; a campaign
  boss promise is independent of good/bad Affix twins and cannot become an
  Empty Den.
- Protect Thorn Essence through persistent, exact-once escrow. Explicit abandon
  or an unrecoverable in-run session returns the Seal; ordinary costs stay spent.
  Player death remains the shipped encounter reset and is not a failed run.
- Settle First Knot victory once with Tusker Tusk, Green Root Rune, and the
  Trophy Hall restoration entitlement. Legacy Charts remain playable and
  campaign-inert.

**D1 gate:** a fresh host reaches the boss recipe after exactly three eligible
Green Hollow returns, always finds Hedgemother, cannot lose or duplicate the
Seal across abandon/reload/co-op callbacks, and receives each first-clear reward
once.

#### D2 — matching-Binding Deepening

- Add matching-Binding Deepening I at Wayfinding 17 and Deepening II at 21.
- Table Deepening authors an additional layer and guaranteed Hearth before the
  run; the existing far-Waystone choice remains the in-run decision to enter an
  authored next layer and accept an Omen.
- Deepening is optional replay depth and never gates a campaign boss or story
  clear. Queen's Summit's existing two Climbing Cords remain recipe identity,
  not an accidental Deepening trigger.

**Slice D gate:** campaign progress is deterministic and cannot be lost to bad
luck or consumption of an irreplaceable story component.

---

## 14. Acceptance criteria

1. A new player explains Base / Waymark / Binding / Ink / Seal after using each
   once, without seeing all five in the first lesson.
2. Changing only the Waymark changes the destination; changing only the Binding
   changes route shape; changing only an Ink changes visible Affix odds.
3. Every valid recipe has one deterministic Chart identity and one data-owned
   preview used by both UI and inscription.
4. Unknown valid arrangements can be discovered; invalid ones consume nothing.
5. A Boss Chart always presents its boss and returns irreplaceable components
   after failure.
6. Existing Charts, Inks, trophies, Affix math, and saves migrate without loss.
7. The table grows across Wayfinding 1–23 and never presents nine unexplained
   slots during onboarding.
8. All six automated suites remain green; new resolver, migration, and guided
   table contracts join the gate.

---

## 15. Decisions to validate in playtest

- Does spatial arrangement feel meaningfully different from named sockets, or
  is it extra dragging without extra thought?
- Are Waymark and Binding visually distinct at 48 px without reading labels?
- Is the split between deterministic Chart identity and probabilistic Affixes
  immediately understandable?
- Does “invalid costs nothing” invite joyful experimentation, or make random
  brute force faster than following rumours?
- Should doubled Waymarks target uncommon rooms, or should they increase biome
  material density instead?
- Is Deepening best expressed by two matching Bindings, or by a separate press
  action on an already completed Chart?

The first prototype should answer these questions before the level 18–23
content is authored.
