# Implementation notes — 41-ui-cohesion

## Phase A — cohesion inventory (2026-06-11)

Style systems in play: **KIT** (spec-39/40 carved wood + tokens),
**BRAMBLE** (pre-39 nest direction), **OLD** (pre-39 parchment plates),
**BARE** (unstyled labels).

| Element | Today | Action |
|---|---|---|
| Window frames (all 7 windows) | KIT | keep |
| Window title + tab row | KIT (spec 40) | keep |
| Trades page | KIT (pilot) | keep |
| Pack doll slots + grid cells | OLD recessed plates | Phase C design |
| Satchel / Charts lists | plain text in KIT window | Phase C design |
| Craft / Vendor / Inscribing content | OLD buttons + labels | Phase C design |
| Dialog panel | KIT frame, plain text | Phase C design (light) |
| HP/Focus globes | BRAMBLE nests | Phase B/D — gate |
| Skill tray + slots | OLD parchment plates | Phase B/D |
| Action buttons (Gear/Satchel/Trades) | OLD WyrdUi buttons | Phase B/D |
| Quest tracker plate | OLD button-tex plate | Phase B/D |
| Toasts | BARE labels | Phase B/D |
| Draught + mute chips | BARE labels | Phase B/D |
| Gold/trades strip (bottom-right) | BARE label | Phase B/D |
| Boss bar | OLD make_meter (600×34) | Phase B/D |
| Interact prompts / damage numbers / float text | in-world Label3D | accepted — world-space text, not panel UI; restyling would fight readability |

## Decisions
- **Globe ring: wood (variant A)** — user gate 2026-06-11; bramble nests
  removed from GlobeGauge, replaced with carved ring + 4 corner notches.
- **Kit chips everywhere**: toasts, draught/mute, gold/trades strip all
  use `WyrdUi.style_chip` (Label `normal` stylebox — no wrapper nodes).
- **make_meter restyled** to the kit trough (flat + ink border) — the
  boss bar inherits cohesion for free.
- **Cursor (user sidenote)**: designed in HUD Kit (3 states), drawn as
  32px PNGs with PIL per the kit, default state wired via
  `Input.set_custom_mouse_cursor` in Game._ready. Interact/attack swaps
  are a followup (needs hover-target plumbing in the controller).
- **HUD Kit split into its own design file** — the design tool's preview
  iframe pins to page-top and can't be scrolled from outside; one page
  per artboard is the workable pattern (encoded for Phase C).

## Deviations
- (none yet)

## Surprises
- The design agent self-reviews: it caught and fixed its own layout
  overflows on both Trades and Pack before handing off ("Lv 1 wrapping",
  "boots icon reads like LL") — briefs can stay terse about pixel QA.

## Followups
- Cursor interact/attack state swaps (controller hover plumbing).
- Phase C remaining design rounds: Craft, Satchel, Charts, Inscribing —
  all four already wear the kit (frames/buttons/chips), so these are
  refinement rounds, not rescues. Designed+implemented so far: Trades
  (pilot), Pack, Dialog, Vendor.
- Painted trade emblems + tool icons + NPC portraits (the dialog well is
  a ghosted placeholder) — Midjourney one-offs.
- Vendor ware-row buttons read slightly washed (cream-on-cream at 50%
  zoom) — consider a darker plate tint for list-row buttons.
