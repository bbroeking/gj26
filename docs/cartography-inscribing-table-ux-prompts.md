# Inscribing Table — UX Moment Prompts

Each prompt captures **one specific moment in the player's interaction**, not just a static screen. The verb shape is `place → recall → inscribe`; these prompts let us evaluate whether each moment *feels right* before we lock the visual treatment.

All anchor to Image #25 via `--sref` so the parchment-and-watercolor look stays consistent.

## Locked stem

Prepend to every prompt:

```
A flat overhead view of a fantasy crafting interface, drawn as a single
page from a cartographer's field journal in the tradition of fairy-tale
storybook art. Sepia-brown ink linework with a slight hand-drawn wobble.
Watercolor washes in cream parchment, sage green, sepia brown, terracotta
red, dusty teal, burnished gold. Aged paper grain visible beneath the ink,
deckled edges. Composition is the interface itself — the page IS the UI.
```

Append to every prompt:

```
--sref [URL OF IMAGE #25] --sw 250 --style raw --ar 16:9 --v 7
```

> **First step**: upload Image #25 to Midjourney, get the URL, then use that URL in `--sref` for **every prompt below**. This is what makes the eight gens feel like siblings.

---

## Run order

Run **calibration first**. If it doesn't capture the parchment look, increase `--sw` to 400 and re-run. Once calibration locks, run the eight moments. Don't tune individual prompts until you've seen the whole sweep — you might find one moment is so right it sets the rest.

---

## Calibration — `cal-empty-page`

Used to verify the `--sref` is transferring properly before we run the eight expensive interaction moments.

```
SUBJECT: a single empty parchment page lying flat on a dark wooden
desk, viewed from directly above. A small ornate hand-blown glass
ink bottle stands in the right margin of the page. The page has
deckled torn edges, faint foxing in the corners, and a single
watercolor smudge at the upper-left where ink once spilled.
Margin doodles in cursive sepia ink along the bottom edge.
```

---

## Moment 1 — `ux-empty-first-open` (the page on first arrival)

Discovery starts here. The grid is empty; the codex is mostly question marks; the Inscribe button is dimmed.

```
SUBJECT: a three-column interface drawn as a single parchment page.
LEFT column titled "Ingredients" lists six small hand-painted
ingredient miniatures in a vertical stack — herb bundle, charcoal
stick, mushroom cap, ore-chip cluster, water flask, mossvine —
each with a small count number in cursive ink beside it. CENTER
column shows a 3×3 grid of empty inscribing slots with sepia ink
borders, all empty; immediately to the RIGHT of the grid a
hand-drawn sepia arrow curves outward to a small empty ink bottle
sitting in a sketched circular ink-well — the output sits beside
the grid, not below it. Below the grid, dimmed text reads
"Inscribe" in faint sepia ink. RIGHT column shows a folded codex
page edge with five ink-bottle silhouettes filled with question
marks, two with the sage and charcoal labels. Faint marginalia
along all edges. Hint text near the grid in cursive: "Try mixing
some ingredients".
```

---

## Moment 2 — `ux-mid-experiment` (the puzzle moment)

Player has placed three ingredients but no match yet. The button reads "Inscribe (Unknown)" — the risky verb.

```
SUBJECT: the same three-column parchment interface, but mid-attempt.
The CENTER 3×3 grid has three herb bundles placed in a vertical
column down its left edge, six slots remaining empty. To the RIGHT
of the grid, a hand-drawn sepia arrow curves outward to an empty
ink bottle in a sketched ink-well circle — the output sits beside
the grid, awaiting result. The LEFT ingredient panel shows the herb
count visibly reduced (the cursive number lower than other items).
The far-RIGHT codex panel shows one entry highlighted with a faint
pulse: "Hedge Ink — 1 ingredient away" rendered in sage green ink.
Below the grid, the Inscribe button now reads "INSCRIBE (UNKNOWN)"
in burnished gold script with a small question-mark glyph. Faint
sepia thinking-lines float above the grid.
```

---

## Moment 3 — `ux-recipe-matched` (production confidence)

The grid matches a known recipe. Button confidently shows the output ink's name.

```
SUBJECT: the same three-column parchment interface. CENTER 3×3 grid
fully populated for the Hedge Ink recipe: three herb bundles in a
vertical column down the center, two charcoal sticks in opposite
corners. The grid glows with a soft warm sepia halo. To the RIGHT
of the grid, a hand-drawn sepia arrow curves outward to a small
green-glowing Hedge Ink bottle sitting in a sketched ink-well
circle — the output is staged beside the grid, ready to flow. The
far-RIGHT codex entry "Hedge Ink ✓" is highlighted with a soft
golden halo around its name. Below the grid, the Inscribe button
reads "INSCRIBE HEDGE INK" in burnished gold illuminated script,
the button itself filled with a confident sage-green watercolor
wash and a small ink-bottle glyph.
```

---

## Moment 4 — `ux-hover-ghost` (the assist)

Player hovers over a known recipe; the grid previews the pattern as a translucent ghost.

```
SUBJECT: the same three-column parchment interface. The CENTER 3×3
grid is empty of solid ingredients but shows three semi-transparent
ghost-silhouettes of herb bundles in a vertical column and two ghost
charcoal sticks in opposite corners — drawn as if traced lightly
onto the parchment in faint pencil. To the RIGHT of the grid, a
faint ghost-arrow curves to an empty ink bottle in a sketched
ink-well circle — the output preview is staged beside the grid.
The far-RIGHT codex entry "Hedge Ink" has a hand-drawn cursor
hovering over it, the entry glowing softly. A faint sepia line
connects the codex entry across the page to the grid, showing the
source of the preview. Below the grid, dimmed text: "Click to fill
from bag".
```

---

## Moment 5 — `ux-inscription-success` (the reward)

The inscription resolves. Sparkle, glow, ink bottle appears, XP floater.

```
SUBJECT: extreme close-up on the CENTER of the parchment interface —
the 3×3 grid with five ingredients in the Hedge Ink pattern, the
entire grid lit by a soft burst of warm golden particles rising from
the cells. To the RIGHT of the grid, a hand-drawn sepia arrow flows
outward to a glass ink-well that now holds a luminous green-glowing
ink bottle, freshly inscribed. The arrow itself is animated as a
trail of golden particles, suggesting the ink "flowing" from grid
to bottle. Floating above the grid in illuminated cursive script:
"★ Hedge Ink Discovered  +50 XP". Sparkle marks scatter across the
parchment around the whole grid-and-bottle composition.
```

---

## Moment 6 — `ux-smudge-recovery` (cozy failure)

Mismatched ingredients. A watercolor smudge replaces the grid contents; one charcoal returns to the bag.

```
SUBJECT: extreme close-up on the CENTER of the parchment interface —
the 3×3 grid where five ingredients have melted into a dark grey-
sepia watercolor puddle pooling at the bottom of the grid. Three
thin smoke wisps rise from the smudge in faint cursive curlicues.
To the RIGHT of the grid, the hand-drawn arrow flows outward to a
glass ink-well that now holds only a single charcoal stub —
salvaged from the failed mix. The arrow itself is faint and sooty,
suggesting the failed flow. On the far-RIGHT panel, the History
tab is shown with a fresh entry highlighted: "12:34 — Smudge
(3 herbs, 2 mushrooms)". A small hand-drawn sad face sits in the
page margin in sepia ink. The mood is gentle disappointment, like
a kitchen mishap.
```

---

## Moment 7 — `ux-codex-three-tabs` (the memory)

Detail on the right panel — the codex with KNOWN / HINTS / HISTORY tabs.

```
SUBJECT: a detail close-up of just the RIGHT codex panel of the
interface, drawn as a folded edge of the parchment page peeking
through. Three small tabs across the top in illuminated sepia
script: "KNOWN", "HINTS", "HISTORY". The KNOWN tab is currently
selected and underlined. Below the tabs, a list of entries: "Hedge
Ink ✓" with a small green ink-bottle illustration; "Charcoal Bind
✓" with a charcoal-grey ink-bottle; "Stoneground ?" with a faded
silhouette; followed by five more entries with question-mark
silhouettes. Each entry has a tiny pattern-preview grid to its
right showing the recipe shape. Marginalia in cursive ink along
the panel edges.
```

---

## Moment 8 — `ux-auto-fill-flow` (the satisfying production click)

The animation moment when a player clicks a known recipe and ingredients fly from the bag to the grid.

```
SUBJECT: the three-column parchment interface mid-action. The
far-RIGHT codex entry "Hedge Ink ✓" is highlighted with a golden
ring. Three delicate sepia-ink arrows curve through the air from
the LEFT ingredient panel — passing over the page — and deposit
three herb bundle illustrations into their proper slots in the
CENTER 3×3 grid. Two more arrows curve from the charcoal stick
entry into the opposite corner slots. To the RIGHT of the grid, an
empty ink bottle waits in its sketched ink-well circle, the
hand-drawn arrow leading to it dimly visible. The ingredient counts
in the LEFT panel visibly tick downward, with small subtraction
marks in cursive ink beside them ("-3"). Below the grid, the
Inscribe button is already beginning to glow, label reading
"INSCRIBE HEDGE INK". The whole movement is fluid like ink running
across paper.
```

---

## How to evaluate when results come back

Print all 8 + the calibration on a single contact sheet (or open them in a tab grid). Score each on three axes:

| Axis | Question to ask |
|---|---|
| **Tone** | does it feel like Bramblewood, or did the prompt drift into a different game? |
| **Clarity** | can a stranger glance at this and understand what the player is doing? |
| **Cohesion** | do all 8 feel like the same page being looked at from different angles, or do they feel like 8 separate UIs? |

If cohesion fails: the `--sref` weight isn't strong enough — bump `--sw 250 → 500` and re-run.

Pick the **two highest scorers**. We translate those through `reference-to-ui` to lock the actual CSS. The other six become inspiration for hover states, animations, and edge-case visuals.

## What this set deliberately omits (Phase 2 prompts)

These are NOT in this batch — we'll prompt them after the core look locks:

- The **Quill at the table** NPC moment (we can decide once we know if Phase 1 has the NPC)
- The **partial-match codex sub-state** (one-away hints) — covered loosely by Moment 2
- The **chart inscription screen** (the second-tier UI) — separate batch, after the table look is locked
- The **shelf of inks** still life — gallery shot, not interaction moment

## Save outputs to

```
docs/concept-art/cal-empty-page.png
docs/concept-art/ux-empty-first-open.png
docs/concept-art/ux-mid-experiment.png
docs/concept-art/ux-recipe-matched.png
docs/concept-art/ux-hover-ghost.png
docs/concept-art/ux-inscription-success.png
docs/concept-art/ux-smudge-recovery.png
docs/concept-art/ux-codex-three-tabs.png
docs/concept-art/ux-auto-fill-flow.png
```

Bring slug names back to me when picked — I'll do the `reference-to-ui` translation pass and we'll write the real CSS against your chosen winners.
