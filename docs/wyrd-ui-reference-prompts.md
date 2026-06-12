# Wayfinder — UI reference prompts, round 2 (detail pass)

The drawn UIs are structurally right but flat — plain rects, bare circles,
no painted detail. This batch generates **reference images to match**:
page heroes that show what each surface *should* look like at full
storybook density, plus element sheets we can crop straight into textures.

**Flow (the spec-39 pipeline):** run prompts in Midjourney → save picks to
`docs/ui-refs/round2/<slug>.png` → Claude measures/crops → treatments get
lifted into the `_draw` implementations and the kit (`wyrd_ui.gd`).
Frame-like art must pass `wyrd/tools/check_ninepatch.py` before use.

## Locked stem (append to every prompt)

```
hand-painted storybook game UI mockup, carved pale-oak wood frames with
bramble and leaf relief carving, parchment-cream panels, warm earthy
palette (oak brown, moss green, parchment cream, hearth-orange accents),
bold clean ink linework, flat storybook illustration, crisp readable
layout, no photorealism, no glossy plastic, no neon, no text rendering
errors --ar 16:9 --stylize 250 --v 7
```

For element sheets swap the aspect: `--ar 3:2`.

## Page heroes

### 1. `hero-bench` — the Inscribing Table (crafting bench)
```
game crafting bench UI: left column is a wooden tray of labeled rows
(rolled chart scrolls, small ink bottles, herb bundles); center is a
workbench surface with one large rectangular parchment socket holding a
rolled chart, a row of three round ink-well sockets, one diamond-shaped
trophy socket, and a copper mixing pot with herbs floating in it and a
carved wooden button reading TRY; below the pot a small open codex page
lists recipes, two written in ink and three as question marks; right
column shows a finished chart with a wax seal, a list of odds written as
inked percentages, and a large carved CRAFT button
```

### 2. `hero-forge-panel` — Hod's Anvil recipe list
```
game crafting menu UI on a parchment scroll: a vertical list of fourteen
recipe rows, each row a small painted icon (anvil-struck bar, pickaxe,
axe, bow, leather cap, boots, jerkin, ring) with a name in dark ink, an
ingredient cost line in smaller script, and a carved wooden SMITH button
on the right; locked rows are grayed with a small iron padlock; a
scrollbar carved like a twisted vine runs the right edge
```

### 3. `hero-pack` — the pack (Tetris grid + doll)
```
game inventory UI: left side a paper-doll figure of a small chibi
adventurer surrounded by carved equipment sockets (helmet, chest, boots,
bow, ring, pickaxe, axe); right side a parchment grid of square slots
holding painted items (a shortbow across two cells, a leather cap, a
copper ring) with rarity-colored corner ribbons; bottom edge a row of
satchel pouches with material counts
```

### 4. `hero-trades` — the Trades page
```
game professions UI: four horizontal profession rows on parchment, each
with a round painted emblem (compass rose for wayfinding, pick and
mountain for earthcraft, leaf and antler for wildcraft, arrow and fang
for huntcraft), a name in illuminated capitals, a horizontal experience
trough filled with glowing amber, and a strip of small square unlock
cells — some painted with perk icons, some empty parchment
```

### 5. `hero-vendor` — Hod's counter
```
game vendor UI: a wooden market counter ledger split in two columns; left
column SELL shows the player's gear as painted miniatures with gold-coin
prices; right column BUY shows shelf rows of materials (herb bundle,
logs, ore lumps, ink bottles) each with a price in stamped coins; center
top a painted portrait roundel of a gruff old smith with a leather apron;
gold purse total in a carved corner plate
```

### 6. `hero-dialog` — speech panel
```
game dialogue UI: a low wide carved-wood panel across the bottom of a
cozy 3D forest village scene; left end holds a painted portrait roundel
of a soft-spoken herbalist woman with herbs in her hair; the panel face
is parchment with two lines of dark ink dialogue text and a small
"continue" leaf glyph pulsing at the right end
```

### 7. `hero-hud` — globes + skill tray
```
game HUD bottom cluster: a deep red liquid-filled glass globe in a carved
wood ring on the left, a deep blue focus globe on the right, and between
them a tray of five square skill slots framed in carved oak, each slot a
painted skill icon (arrow, fan of arrows, bramble coil, gold mark, bark
shield), with parchment keybind tags 1-4 and F below; thin vine-carved
quest plate floating top center
```

### 8. `hero-loadout` — the kit picker
```
game skill-loadout UI: a parchment panel titled in illuminated script;
nine horizontal skill rows each with a round painted skill icon, a name,
a one-line ink description and focus cost; three rows are marked chosen
with a wax seal stamp; two rows are dimmed with an iron padlock and a
small antler glyph; a wide carved APPLY button at the bottom
```

## Element sheets (crop-ready)

### 9. `sheet-frames` — nine-patch borders
```
sprite sheet of four ornate rectangular UI frames on a flat dark gray
background, each frame border-only with an empty transparent center,
symmetric edges and corners: one carved pale-oak with leaf relief, one
darker iron-banded oak, one parchment scroll edge with curled corners,
one thin vine-and-thorn border; clean separation between frames
```

### 10. `sheet-sockets-buttons` — interactive states
```
sprite sheet on flat dark gray: a row of round ink-well sockets in three
states (empty recessed, filled with glowing ink, gold-highlighted); a
diamond trophy socket empty and filled; three carved wooden buttons in
normal, hover-glow, and pressed states; a square skill slot empty,
filled, and on-cooldown with a radial shadow sweep
```

### 11. `sheet-bottles-props` — bench props
```
sprite sheet on flat dark gray: five small hand-blown ink bottles each a
different shape and color (round green, angular gray, tall luminous
white, squat charcoal with ash flecks, pale chalk-white wash), a copper
mixing pot with swan-neck still, a rolled parchment chart with wax seal,
a wax seal stamp, an open codex book, a quill in an ink pot
```

### 12. `sheet-icons` — emblems + skill icons
```
sprite sheet of round painted game icons on flat dark gray, bold ink
outlines, flat cel shading: compass rose, pickaxe on mountain, leaf with
antler, arrow with fang; then nine square skill icons: single arrow,
heavy flaming arrow, fan of three arrows, bramble snare coil, piercing
bolt through rings, falling thorn volley, bursting thorn ring, gold
hunters mark sigil, bark shield, precise killing arrow
```

## After generation

Drop picks into `docs/ui-refs/round2/` with the slug names above, then
say the word — the measure/crop/implement pass mirrors how spec 39's
mocks became the kit. Expect heroes to drive layout *treatments* (painted
sockets, scroll headers, vine scrollbars) and sheets to become actual
textures (after `check_ninepatch.py` for the frames).

Alternative: the Meshy MCP can generate these (`meshy_text_to_image`,
3–9 credits per image ≈ 36–108 credits for the full batch of 12) if you'd
rather not run Midjourney — say so and Claude runs the batch.
