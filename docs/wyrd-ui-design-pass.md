# Wayfinder — UI design pass via Claude Design (v1, optimized 2026-06-11)

Optimized via /plan-optimizer; trajectory 71 → 84 → 87 → 87 → 89.

**Goal:** every player-facing page gets a deliberate design in Claude
Design before more code styling — on the locked spec-39 language — and
each approved design lands in Godot with a measurable fidelity check.

**The trap this plan exists to avoid:** Claude Design produces *working
web UI* (React/HTML). None of that code ports to Godot. Its output here
is a **visual specification** — an artboard we measure (geometry, type
scale, spacing, color) and reimplement in `_draw`/Controls. Any design
that leans on web-only affordances (hover transitions, shadows, real
scrollbars) gets simplified at design time, not discovered at port time.

## Locked constraints (seed every design session with these)

- Chrome: pale carved wood frame (`assets/ui/panel_frame_v2_9p.png`)
- Layouts: professions rows + OSRS unlock cells (trades); torn-scroll
  lists (satchel/vendor refs in docs/ui-refs/); Diablo doll+grid (pack)
- Palette: INK #3a2c20 · TERRACOTTA #b14c33 · SAGE #6f8a3f ·
  GOLD #b58637 · CREAM #f3e6cb
- Type: IM Fell English SC headers · system-clean body (the 2026-06-10
  usability ruling: ornament on frames/headers only)
- Canvas: 1280×720, windows ≈ 630×600 max

## Phase 1 — the UI kit artboard (the structural keystone)

One persistent "Wayfinder UI Kit" page in the Claude Design project
holding the design system: palette swatches, type scale, the wood frame,
button/cell/bar/emblem components. Every page artboard composes FROM the
kit, so revisions propagate and page designs can't drift apart.
**Done when:** kit page exists, user has eyeballed it, components match
the locked constraints.

## Phase 2 — pilot page: Trades (full loop, then retro)

Seed: kit + the in-game capture (`/tmp/wyrd_ui_trades.png` via connector
file upload) + the constraint block above + what the page must show
(3 trades, XP, unlock cells, hover/Next line).
Loop: design round → user reacts → ≤1 revision round → approve.
Extract: a measured spec (px geometry, sizes, colors as WyrdUi tokens) —
written into `docs/specs/40-ui-from-design-notes.md` as the implement
contract. Implement in Godot → capture → **side-by-side** vs artboard →
user sign-off.
**Retro gate:** if the pilot took > ~2 sessions or fidelity was poor,
fix the workflow (or drop to Midjourney-mock flow) before scaling.

**Pilot status (2026-06-11): COMPLETE.** Project `wayfinder-ui` holds
the kit + approved Trades.html; implemented in Godot same-day; suites
green. Retro: the loop works — total cost ~1 session. Lessons now
encoded: short prompts (long ones error out), text-only seeding (no
file uploads through the connector), and the design agent invents data
when the brief gives bare numbers — always name every cell in briefs.

## Phase 3 — remaining pages, in player-value order

1. Pack/Gear (most-opened window)  2. Dialog (every NPC touch)
3. Vendor  4. Craft (cook/smith share one design)  5. Satchel
6. Charts  7. Inscribing Table (biggest, last — most components reused
by then)

Per page, same loop as the pilot. **Time box: one design + one revision
round per page** — if it's not approved by then, ship the closest
version and move on; this is a cozy game, not a design agency.

**HUD is explicitly out of artboard scope** (in-world overlays — globes,
skill tray, prompts). Only if a page design exposes a clash does the HUD
get a targeted follow-up.

## Connector mechanics + fallback

Drive the user's existing Claude Design project tab via the Chrome
connector (browser "personal"); upload captures with file_upload; paste
the constraint block verbatim into each design chat. **Fallback** if the
connector/design tool fights us twice in a session: user drives Claude
Design by hand from the same seed text (kept in this doc), or we revert
to the Midjourney mock → measure → implement flow that shipped spec 39.

## Risks

- **Web-native drift** (the trap above) — countered by the constraint
  block + simplify-at-design-time rule.
- **Asset gaps surface mid-pass** (painted trade emblems, tool icons) —
  expected; queue them as Midjourney one-offs, don't block the page.
- **Scope creep into systems** ("the vendor page needs a buyback tab") —
  design only what the code already does; new features go to the build
  plan, not the artboard.
- **Connector flakiness** — fallback above; never burn >15 min on tab
  wrangling.

## Success metric for the whole pass

Every page: (a) 3-second read test — a newcomer can say what the page is
for from the capture alone; (b) side-by-side fidelity the user signs off;
(c) all suites stay green after each page's implementation.

## Cut-line

Pilot + Pack + Dialog are the must-haves. Everything after survives a
cut — the spec-39 styling is already shippable.
