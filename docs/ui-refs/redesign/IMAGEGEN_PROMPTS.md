# UI redesign ImageGen prompt record

Generated with the built-in ChatGPT ImageGen tool on 2026-07-17. All outputs
were copied into this directory; the originals remain in Codex's generated
image store.

## Controlled direction comparison

All three prompts used the live Chart Table screenshot as a composition/content
reference and held this workflow constant:

> Supplies on the left; a five-socket chart assembly surface and four ink
> choices in the center; chart preview, requirements, and one dominant
> **Inscribe Chart** action on the right. 1366×768, 48px targets, readable type,
> little dead space, visible world gutters, practical Godot implementation.

The changed style lines were:

1. **A — Wayfinder's Field Journal:** warm oat paper, dark walnut ink, carved
   oak edge, sage/terracotta watercolor marks, wax seal/chartmaker stamps,
   ornament only at masthead/corners.
2. **B — Enamel Night Cartographer:** dark pine-teal enamel, warm cream type,
   leaf-gold rules, walnut structure, copper/terracotta warnings, parchment only
   as the inset preview document.
3. **C — Bramblewood Field Kit:** honey-walnut case, moss-felt recesses, cream
   labels, brass clasps, painted icons, functional seams and small leaf marks.

Shared negatives: cream-on-cream, gold body text, tiny text, glossy candy-green
buttons, excessive vines/filigree, bright identical slots, giant empty areas,
and watermarks.

## Chosen-direction hero set

The final four prompts used the locked stem in `docs/UI_BIBLE.md` with these
screen subjects:

- **HUD:** compact quest note, five-slot bottom Skill bar, integrated HP/Focus,
  compact Pack/Chart/system controls; at least 88% of the world unobstructed.
- **Pack:** semantic Gear/Satchel/Charts/Trades tabs, equipped column with seven
  named slots and character figure, backpack item cards with comparison and an
  explicit Equip action.
- **Chart Table:** corrected three-column workflow; ordinary rounded sockets,
  text-first preview, small reusable biome emblem, explicit focus/selected/
  staged/unavailable states.
- **Dialogue:** lower-third portrait/prose/choice layout; 18px+ prose; large
  stacked choices; world visible above.

The ImageGen files are design references, not assets consumed by the game.

## Waystone hero

The Waystone hero reused the chosen Chart Table Field Journal image as its
visual anchor. The prompt asked for a compact 1366×768 in-world master-detail
page: a roughly 38% Chart Case list on the left and a 62% travel folio on the
right, with selected Chart identity, Den level/difficulty, Affix rows, a small
hand-drawn route sketch, estimated XP, and one dominant **Step Through** action.
It also required a deliberately designed `No Charts Waiting` state directing
the player to Mara's Chart Table, plus the locked paper/walnut/sage/terracotta
palette, restrained ornament, readable type, 48px targets, and visible world
gutters. The output is `hero-waystone-field-journal.png`.

## Field Journal production kit

The asset-fidelity pass used `hero-chart-table-field-journal.png` as a locked
style reference and generated four project-bound sources with the built-in
ChatGPT ImageGen tool:

- `component-sheet-field-journal-v1.png`: twelve isolated UI furniture pieces
  spanning journal frames, raised paper, buttons, tabs, sockets, divider,
  focus pointer, emblem, and tooltip.
- `wyrd/assets/ui/field_journal/icon_atlas_source_v1.png`: a strict 4×4 atlas
  of sixteen Wayfinding materials and navigation objects on flat magenta.
- `chrome/journal_panel_source_v1.png`: one symmetric parchment/oak panel with
  clean nine-slice corridors.
- `chrome/primary_button_source_v1.png`: one empty moss primary-action plate
  with protected corners and native-text center.

The chroma sources were converted locally with the ImageGen skill's soft-matte
and despill helper. The icon atlas was split into sixteen transparent 256×256
assets. The panel and button were trimmed and normalized to 512×512 and 384×128
nine-slice textures. Runtime assets remain under
`wyrd/assets/ui/field_journal/`; the concept sheet remains in this directory.

## Painterly interaction-state kit v2

The second production pass used both `component-sheet-field-journal-v1.png`
and `hero-pack-field-journal.png` as style references. The built-in ChatGPT
ImageGen prompt requested a strict 2×2 chroma-key atlas containing exactly four
blank, isolated components: a quiet parchment button plate, selected sage tab,
square item/socket well, and compact leaf-arrow focus pointer. It required
frontal orthographic presentation, large gaps, uninterrupted stretch corridors,
no text, no shadows, and a perfectly flat `#ff00ff` background.

The source and soft-matted atlas are stored as
`chrome/component_atlas_{source,alpha}_v2.png`. Mechanical quadrant crops
produced `quiet_button_9p_v2.png`, `selected_tab_9p_v2.png`,
`item_well_9p_v2.png`, and `focus_leaf_v2.png`. The selected tab and pointer are
live in the Pack capture `slice13-pack-painted-statekit-live.png`; the quiet
button and item well are registered Theme resources for the next shared-row
component slice.

## Shrine blessing icon atlas

Generated with the built-in ChatGPT ImageGen tool on 2026-07-19, using
`wyrd/assets/ui/field_journal/icon_atlas_source_v1.png` as a style-only
reference. The production prompt was:

> Create exactly ten distinct fairytale shrine-blessing emblems in a perfectly
> regular 5-column by 2-row grid, one centered emblem per equal cell. Match the
> reference's hand-painted storybook game-item rendering, heavy warm-brown ink
> contour, compact readable silhouette, restrained highlights, and tactile
> material. In strict reading order: red heart wrapped in bramble leaves for
> vigor; thorned arrowhead with a small flame for arrow damage; golden eye over
> an arrow point for critical chance; split thorn crown for critical damage;
> sparrow wing crossed with an arrow for fire rate; winged boot with a brook
> curl for move speed; luminous blue-green root spiral for Focus regeneration;
> oak-bark shield for dodge resilience; herb sickle with a sprouting leaf for
> gathering speed; pale moon above a cooling hourglass for Skill cooldown.
> Use walnut outlines, oat gold, moss/sage, muted terracotta, and sparing
> moonlit blue. Use a perfectly uniform `#ff00ff` chroma-key background; equal
> padding; no overlap, dividers, text, numerals, watermark, border, reflection,
> or cross-cell shadow. Keep every emblem legible at 72px.

The versioned source and soft-matted atlas live in
`wyrd/assets/ui/field_journal/icons/shrine/`. Deterministic 5×2 cropping,
alpha validation, trim, resize, and 256px centering produced the ten runtime
files named by Shrine buff ID. Their accepted live use is
`slice25-shrine-blessing-live.png`.
