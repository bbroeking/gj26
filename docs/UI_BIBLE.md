# Wayfinder UI Bible — Field Journal

Status: **locked for the UI rebuild** (2026-07-17).

This replaces the mixed Maple / Enamel Night / carved-kit directions. The
chosen system came from a controlled ImageGen comparison of the same Chart
Table in three languages. **Wayfinder's Field Journal** won because it made the
Wayfinding Trade feel specific to Bramblewood while remaining the clearest in
three seconds. It borrows the Field Kit concept's explicit focus and selection
affordances, but not its literal suitcase metaphor.

## North star

The interface feels like a well-used field journal carried by a working
Wayfinder: neighborly, practical, tactile, and quietly magical. Content is more
important than ornament. A player should understand the page purpose, current
selection, consequence, and next action before admiring the frame.

## Semantic material rule

Materials communicate function. Do not apply one skin to every rectangle.

| Material | Meaning | Typical uses |
|---|---|---|
| Warm oat paper | Authored or descriptive content | prose, chart outcome, item description, quest note, empty-state explanation |
| Walnut + muted moss | Persistent controls and live state | tabs, buttons, slots, navigation, meters, HUD, focusable rows |
| Honey-oak edge | Shell and separation | modal edge, portrait well, restrained section boundary |
| Sage | focus, selected, valid, ready | focus ring, selected fill, staged checkmark |
| Terracotta | warning, loss, invalid, danger | missing requirement, downgrade, destructive action |
| Muted gold | reward, rarity, completion | earned state, valuable result, restrained accent |

The world remains visible around both paper and control surfaces. The HUD uses
compact walnut/moss furniture; it never becomes a large paper slab.

## Palette roles

Exact colors may be tuned through contrast testing, but roles may not collapse.

| Token | Starting value | Use |
|---|---:|---|
| `paper` | `#E9D9B4` | main authored-content surface |
| `paper_raised` | `#F3E7CA` | selected/raised paper card |
| `ink_on_paper` | `#38281D` | all primary paper text |
| `ink_on_paper_dim` | `#6D5945` | secondary paper text; never instructions below contrast target |
| `walnut` | `#5A3824` | shell and control edges |
| `walnut_deep` | `#2D1D16` | shadows and outlines |
| `moss` | `#314A2B` | persistent-control face |
| `cream_on_dark` | `#F4E8CB` | text on moss/walnut only |
| `sage` | `#6F8F57` | focus/selected/valid |
| `terracotta` | `#B9563F` | warning/invalid/danger |
| `gold_muted` | `#B68A3A` | reward/rare/completion |
| `scrim` | `rgba(20,16,12,0.58)` | modal world dim |

There is no generic `INK` token. Text color always names its surface.

## Typography

- Display/page title: IM Fell English SC, 28–32px at 1366×768.
- Section heading: IM Fell English SC, 20–22px.
- Body and interactive labels: IM Fell English, **16px minimum**.
- Long-form dialogue: 18–20px with generous line spacing.
- Caption/key hint: 14px minimum; never use captions for required instructions.
- Numeric values use tabular alignment where available.
- Gold is an accent, not a body-text color.

## Spacing and sizing

- 4px base rhythm: 4, 8, 12, 16, 24, 32, 48.
- Minimum interactive hit target: 48×48px.
- Modal safe gutter: 24px at 1280×720 and 1366×768.
- Modal maximum: 88% viewport width, 86% viewport height.
- Primary content uses Containers and flexible columns. At narrow widths,
  three columns may become two plus a page/step transition.
- Ornament consumes no more than 10% of any edge and never reduces a hit area.

## State language

State must remain readable without color alone.

| State | Required treatment |
|---|---|
| Hover/focus | 2–3px sage or muted-gold ring **plus** a small exterior pointer |
| Selected source | sage-tinted fill plus selected label/icon |
| Staged/committed | checkmark plus stable filled state |
| Unavailable | neutral desaturation plus a written reason |
| Invalid | terracotta mark plus a short reason; never color alone |
| Primary action | largest action in its region, moss face, high-contrast label |

White/neon bloom is not a focus treatment.

## Screen grammar

- **HUD:** world-first; compact bottom hotbar/meter cluster; paper only for an
  authored quest note or transient toast.
- **Pack/pages:** clear page title and one semantic tab family; equipment and
  item data are readable cards, not a hand-coded Tetris canvas.
- **Workstations:** left-to-right `source -> decision/work surface -> result`.
  The consequence and primary action remain visible.
- **Dialogue:** lower third; portrait, readable prose, then large choices.
- **Menus:** one focused task per page; no giant empty cream acreage.

## Locked ImageGen prompt stem

```text
Use case: ui-mockup
Asset type: shippable 16:9 Godot game UI at 1366x768
Primary request: [SCREEN SUBJECT AND REQUIRED INFORMATION ARCHITECTURE]
Style/medium: realistic polished production UI; Wayfinder's Field Journal;
warm oat paper for authored content, dark walnut ink, restrained honey-oak
edges, muted moss persistent-control surfaces, sage focus/selected,
terracotta warning, muted-gold reward, watercolor marks, minimal ornament.
Composition/framing: max-width layout with safe world gutters, strong task
hierarchy, little dead space, 48px targets, 16px+ body type.
Constraints: ordinary rounded containers implementable with Godot Containers
and Theme; focus is a 2–3px ring plus pointer; dark text on paper and cream text
on moss; keyboard/mouse/gamepad parity.
Avoid: suitcase hardware, enamel luxury, giant title plaque, generic fantasy
filigree, puzzle-piece sockets, candy-green glossy buttons, tiny text, gold body
text, cream text on cream, full-bleed modal, watermark.
```

## Reference set

- `docs/ui-refs/redesign/hero-hud-field-journal.png`
- `docs/ui-refs/redesign/hero-pack-field-journal.png`
- `docs/ui-refs/redesign/hero-chart-table-field-journal.png`
- `docs/ui-refs/redesign/hero-dialog-field-journal.png`
- `docs/ui-refs/redesign/field-journal-hero-board.jpg`

The references bind hierarchy, semantic material roles, density, state language,
and overall tone. They do **not** require literal generated portraits, unique
chart illustrations, exact item art, ornate bevels, or pixel-for-pixel frames.

## Explicit rejects

- One global text color serving both paper and dark surfaces.
- Maple cream panels mixed with Enamel Night cream text.
- Literal suitcase handles, hinges, and latches as a universal metaphor.
- Giant crests, title cartouches, double/triple gold borders, or heroic-MMO
  grandeur.
- Interlocking puzzle-piece sockets; use ordinary cards and optional drawn
  connector lines behind them.
- Bright identical empty-slot tiling.
- Custom `_draw()` hitboxes for ordinary rows, tabs, or buttons.
- Required information at 11–14px.
- Color-only selection, uncertainty, or validation.

## Implementation rule

Godot `Theme` type variations and reusable Control scenes are the authority.
`_draw()` is reserved for non-interactive ornament and truly specialized chart
connective art. Every normal interaction is a semantic Control with focus,
hover, pressed, disabled, tooltip, and controller navigation behavior.
