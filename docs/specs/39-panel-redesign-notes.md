# Implementation notes — 39-panel-redesign

## Decisions
- **P0 revert kept the height increase.** The window stays taller than
  pre-spec-38 (`+96` bottom band vs `+64`) because the readability type
  sizes (15px ladder rows, 18px satchel names) need the room; only the
  asymmetric hedgewood plumbing was backed out.
- **Mid-flight scope addition (user, 2026-06-11):** five reference shots
  (OSRS thieving scroll + skills grid, WoW spellbook/talents/professions)
  arrived during Phase 1. Read as a *layout* directive, not just chrome:
  icon-forward, dense, game-y pages — WoW-professions-style trade rows
  (big emblem + bar + unlock icon cells), OSRS-style level grids and
  torn-scroll lists. Phase 1 expanded from 4 frame candidates to 4 frames
  + 3 layout mocks; the pick gate now chooses frame chrome AND layout
  language.

## Deviations
- **Dialog panel reskinned despite the spec's "don't touch" guard.** The
  user reported it "completely illegible" mid-implementation, and the old
  Midjourney scroll art clashed with the picked wood direction — both
  spec-listed reasons to touch it. New: carved-wood frame, 19px dark body
  text on cream, IM Fell speaker line. The mj_dialog_ribbon art stays in
  docs/ui-refs/ for reference.

## Tradeoffs
- **Emblems are drawn discs + glyphs (✦▲❀), not painted art.** Good
  enough to prove the professions-row layout; painted trade emblems are a
  natural Midjourney/Claude-Design follow-up.
- **Unlock cells show glyph-or-level, names on hover only** — chose
  density (OSRS ref) over always-visible labels; the "Next:" line keeps
  the most useful name on screen.

## Surprises
- The first revert attempt's Python heredoc died on quote escaping and
  silently deleted the hedgewood texture while it was still referenced;
  re-ran with assert-guarded replaces. Pattern to keep: every targeted
  source edit asserts the needle exists before replacing.

## Followups
- ~~"Chart of the Summit" ellipsizes~~ — moot; the text-column layout was
  replaced by unlock cells (full name lives in the hover/Next line).
- **Claude Design phase (user directive, 2026-06-11):** with the layout
  language locked (wood frame + professions rows + OSRS cells/scroll
  lists), the user wants the pages properly *designed* in Claude Design
  (claude.ai/design) before more pixel-pushing in code — drive their
  existing design project tab via the connector, one artboard per page
  (trades, satchel, pack, vendor, dialog), then implement from those.
- Painted trade emblems + painted tool icons (pickaxe/axe still flat
  plates in the pack grid).
- Vendor/satchel could adopt the OSRS torn-scroll list mock
  (docs/ui-refs screenshots) once Claude Design passes on them.
