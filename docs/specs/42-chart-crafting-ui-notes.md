# Implementation notes — 42-chart-crafting-ui

## Decisions
- **Click-crafts, no drag-out** (the spec's open decision): clicking the
  result slot or Craft button inscribes straight to the chart case with a
  gold stamp flash — charts aren't grid items, dragging them out had no
  destination.
- **Public bench API** (`place_base / socket_ink / socket_trophy /
  pot_add / craft / close`) is the same code path the mouse handlers use —
  the transitions test drives it headlessly (10 new checks), no pixel
  drags needed.
- **Pot auto-mixes on exact recipe match** — drop herbs until the pot
  contents equal a recipe, `mix_ink` fires and the pot clears. Clicking a
  non-empty pot empties it. Ink pots can also be dropped into the pot
  (refined ink needs 2 hedge ink + 1 ore).
- **Trophy tray rows only render when owned** — an empty Trophies section
  for a new player would just be noise.
- **Tutorial highlight = pulsing gold ring** drawn on the target rect
  (pot at step 2, base socket → result at step 3, ink socket at step 6),
  with soft-locks: steps 2/3 only accept the taught drop.

## Deviations
- **Design-page reconciliation deferred**: the 'Crafting Bench' artboard
  was briefed and rendered in `wayfinder-ui`, but the implementation
  proceeded from the spec contract in parallel (user said go). A
  side-by-side pass against the artboard is a followup — expected deltas
  are decorative (rolled-parchment base art, pot art), not structural.

## Tradeoffs
- Tray rows are 26px (compact) — the full template list + inks + materials
  + trophies overflowed the 560px window at comfortable density. If more
  templates land (A6+), the tray needs scroll or paging.

## Surprises
- The old inscribing panel deleted cleanly — nothing else referenced it
  (table + town hook were the only call sites), and the transitions test
  never touched the panel (it drives Game/ChartsData directly), so the
  rebuild's blast radius was exactly the spec's file list.

## Followups
- Side-by-side vs the 'Crafting Bench' design page; lift its decorative
  treatments (rolled base, copper pot art) if they read better.
- Fresh-save manual tutorial run (acceptance #4's human half).
- Bench art one-offs: painted ink-pot icons in sockets (text glyphs now).
- Tray scroll/paging before the template count grows past ~7.
