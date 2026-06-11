# 40 — Implement contract: Trades page (from Claude Design pilot)

Source: `wayfinder-ui` project → `Trades.html` (approved 2026-06-11).
Design kit: `Wayfinder UI Kit.html` (same project). These are the
measured values the Godot implementation must match.

## Window chrome
- Carved-wood frame (existing `panel_frame_v2_9p.png`), interior cream.
- Title "Adventurer's Pack" — IM Fell SC 24, TERRACOTTA, top-left of
  content, ~36px below frame top.
- Tab row directly under the title, **full content width, 4 equal tabs,
  butt-joined** (no gaps): cream plates, 1.5px ink border, Fell SC 16
  small-caps labels, **no icons**. Active tab: brighter cream +
  terracotta underline 3px along its bottom edge.

## Profession rows (×3, separated by full-width faded-brown rules)
- Emblem: 60px disc at content-left — flat trade color (gold / terracotta-
  brown / sage), double ink ring (outer 3px at r30, inner thin at r24),
  cream glyph centered (✦ ▲ ❀ stand in for compass/mountain/flower).
- Name: Fell SC 21 **INK** (not terracotta — title only is terracotta),
  baseline aligned with emblem center; "Lv N" Fell SC 16 INK
  right-aligned on the same line.
- XP bar: x = name x, width ≈ 56% of content width, h 14; trough
  #ccb893, fill = trade color, 1.5px ink border; caption "N / M xp"
  sans 14 to the right of the bar.
- Unlock cells: 30×30, gap 8, same x as name, one row (wraps if needed).
  EARNED: plate #ede4c8, 2px SAGE border, ink glyph 15px.
  LOCKED: plate #c2b394, 1.5px brown border, level number sans 14
  #5a4a3a.
- Next line: sans 14, #5a4a3a, "Next: <name> · lv N", 8px under cells.
- Row pitch ≈ 120px; divider centered in the gap.

## Data corrections vs the design artboard
- Earthcraft next = "Bogiron Pickaxe · lv 2" (design invented "Cinder
  Ingot" from an underspecified brief).
- Wildcraft next = "Keen Eye · lv 5" (Bramble Bloom is a carto affix).

## Out of scope here
- Other tabs keep their current layouts (each gets its own design round
  per docs/wyrd-ui-design-pass.md Phase 3).
- The tab-row restyle applies to the shared header (all pack pages see
  it) — that's intended; it's window chrome, not page content.
