---
title: UI Kit & Panels
domain: UI & Presentation
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# UI Kit & Panels

> The WyrdUi parchment kit is solid and consistently applied; the next most important step is finishing the shrine-choice modal (currently unstyled) and landing the buff-HUD chip that the roadmap already names as a queue item.

## Current state

**`wyrd_ui.gd`** (`wyrd/scripts/ui/wyrd_ui.gd:1–386`) is a well-factored `RefCounted` singleton that exports the full kit: the six-color palette (INK / INK_MID / TERRACOTTA / SAGE / GOLD / CREAM) and back-compat aliases (`wyrd_ui.gd:18–22`); the nine-patch panel and button-plate paths plus verified margins (`wyrd_ui.gd:26–43`); IM Fell English (body/SC/hand) font loaders; `style_panel`, `style_button`, `style_kit_button`, `style_title`, `style_body`, `style_dim`, `style_chip`, `chip_stylebox`, `mark_selected`, `make_meter`/`set_meter`; and the Spec-44 drawn-detail primitives: `draw_list_row`, `draw_well`, `draw_round_well`, `draw_carved_button`, `draw_parchment_grain`, `draw_flourish`, `draw_ink_bottle`, `draw_scroll`. The nine-patch frame texture is verified (`wyrd_ui.gd:24–26`; `tools/check_ninepatch.py`).

**Inventory panel** (`wyrd/scripts/inventory_panel.gd`) is the most complete: Tetris grid + paper-doll equipment, tabbed (Gear / Satchel / Charts / Trades), drawn-UI scroll with parchment masks on list pages, hover tooltip, drag-and-drop, rarity glows, painted item icons preloaded in `_ready` (white-rect gotcha handled: `inventory_panel.gd:108–117`), and the full mastery-ladder Trades page (spine + perk cards, earned/locked state: `inventory_panel.gd:789–901`).

**Crafting bench** (`wyrd/scripts/ui/crafting_bench.gd`) is the richest drawn panel: tray, base/ink/trophy sockets, mixing pot (drawn copper cauldron), live odds preview, codex, pop animations, tutorial highlights, Spec-43/44/45 features all landed.

**Vendor** (`wyrd/scripts/ui/vendor_panel.gd`), **waystone** (`wyrd/scripts/ui/waystone_panel.gd`), and **loadout** (`wyrd/scripts/ui/loadout_panel.gd`) all use `WyrdUi.style_panel`, `style_button`, `style_title`, etc., and their list rows use `_VendorCard` / `_SkillCard` drawn controls backed by `draw_list_row`.

**Dialog panel** (`wyrd/scripts/ui/dialog_panel.gd`) uses `WyrdUi.style_panel` + a code-drawn `PortraitWell` (silhouette placeholder: `dialog_panel.gd:137–146`). The portrait slot shows a ghosted silhouette — no painted portrait assets yet.

**Shrine-choice modal** (`wyrd/scripts/shrine_choice_modal.gd`) is the one unstyled outlier: `Panel.new()` with no `WyrdUi.style_panel` call, buttons built with `Button.new()` and no `WyrdUi.style_button`, title label with a raw `add_theme_font_size_override` rather than `WyrdUi.style_title`. It is a functional skeleton that never got the kit treatment (`shrine_choice_modal.gd:26–77`).

The **buff HUD chip** (for active shrine buffs) does not yet exist in `player_hud.gd`. The roadmap names it explicitly: "Queue — next candidates: buff HUD chip" (`docs/wyrd-roadmap.md`).

The **chart/affix preview** lives inside `crafting_bench.gd` `_draw_result` (odds rows, stability, trophy line) and in `inventory_panel.gd` `_draw_charts_tab` (chart list with affixes). These are functional but draw using `get_theme_default_font()` for body text rather than `WyrdUi.font_body()` — a polish gap.

## Gaps — what needs fleshing out

- **[BLOCKER — cosmetic]** `shrine_choice_modal.gd` is unstyled: raw Panel, raw Buttons, no kit fonts/colors. Every other modal uses `WyrdUi.style_panel` + `WyrdUi.style_button`; this one doesn't. The buff cards are plain text blobs.
- **Buff HUD chip**: no chip exists to display active shrine buffs during a dungeon run. Named in roadmap queue.
- **Portrait assets in dialog_panel.gd**: `PortraitWell` shows a ghosted silhouette placeholder (`dialog_panel.gd:137–146`). NPC painted portraits are art-pipeline work (out of scope for code), but the code slot exists and works.
- **Body-text font consistency**: several inner `_draw()` calls use `get_theme_default_font()` instead of `WyrdUi.font_body()` (inventory tooltip: `inventory_panel.gd:547`; waystone detail label uses `WyrdUi.style_body` correctly; vendor card inner draw uses `get_theme_default_font()`: `vendor_panel.gd:268`). Low risk but inconsistent.
- **Vendor "cream-on-cream" readability**: roadmap standing followup — "vendor list-row buttons slightly washed (cream-on-cream)" (`docs/wyrd-roadmap.md` standing followups). The `_VendorCard` draw is readable but hover state is subtle on the button plate.
- **Inscribe chart ritual (B6)**: the result slot in `crafting_bench.gd:_draw_result` shows affixes all-at-once as plain text rows. Plan.md Part B / Phase B6 calls for sequential affix reveal with overshoot stamps. This is a *feel* gap, not a missing panel.
- **Scroll marker accessibility**: the slim 4px sage scroll runner in `inventory_panel.gd:_draw_scroll_marker` is easy to miss. A hint label already exists but the thumb is narrow.
- **No dedicated mastery-tree panel**: the mastery ladder lives inside the inventory Pack window (Trades tab). Cross-link with [[system-skills-hotbar]] — both reference the same perk data.

## Plan

### Phase 1 — Shrine-choice modal kit port (the unstyled outlier)
- Apply `WyrdUi.style_panel(_panel)` in `shrine_choice_modal.gd:_ready` (currently missing entirely).
- Replace raw `Button.new()` buff cards with drawn `_BuffCard` controls (mirror `_VendorCard`/`_SkillCard` pattern): `draw_list_row` plate, buff name in `WyrdUi.style_title` / `style_section` font, description in body text, an accent stripe (SAGE = positive buff, GOLD = neutral).
- Replace the raw title label with `WyrdUi.style_title`.
- **DoD:** opening a shrine shows three kit-styled buff cards on the parchment frame — indistinguishable in visual language from the vendor/loadout/waystone panels. A screenshot taken with `WYRD_SHOT=1` shows the styled modal. Gate green (`WYRD_NO_SAVE=1`).
- **Effort: S**

### Phase 2 — Buff HUD chip (roadmap queue item)
- Add a `_buff_chips: VBoxContainer` (or drawn equivalent) to `player_hud.gd`, positioned top-right of the screen clear of the globes and skill bar.
- `game.gd` already carries shrine-buff state; expose a `get_active_buffs() -> Array` signal or poll in `_process`.
- Each active buff renders as a `WyrdUi.chip_stylebox()` chip: name (hand font / Caveat) + remaining duration as a draining trough using `WyrdUi.make_meter` pattern. GOLD accent for positive buffs.
- Remove chip when buff expires (connect to buff-expired signal or poll duration).
- **DoD:** equipping a shrine buff shows a labeled chip with a live ticking duration bar in the HUD; the chip disappears when the buff expires. Logic test: chip count matches `game.get_active_buffs().size()`. Gate green.
- **Effort: S–M**

### Phase 3 — Body-text font consistency pass + vendor readability
- Sweep panels for `get_theme_default_font()` calls inside `_draw()`: replace with `WyrdUi.font_body()` (with null-fallback: `var f := WyrdUi.font_body(); if f == null: f = get_theme_default_font()`). Target files: `inventory_panel.gd` tooltip draw (`inventory_panel.gd:547`), `vendor_panel.gd` inner card draws (`vendor_panel.gd:268`).
- Fix vendor hover contrast: bump `_hover` overlay to `Color(1.0, 1.0, 0.90, 0.14)` (from 0.10) in `_VendorCard._draw`.
- Widen the inventory scroll thumb: increase from 4px to 7px in `_draw_scroll_marker` (`inventory_panel.gd:681`).
- **DoD:** no `get_theme_default_font()` remains in panel `_draw()` bodies; vendor hover is visible in a screenshot; scroll thumb is 7px. Gate green.
- **Effort: S**

### Phase 4 — Inscribe affix reveal (B6b from Plan.md Part B)
This is explicitly scoped in Plan.md Part B / Phase B6b: "chart's affix names reveal one-by-one with a stamp/overshoot instead of appearing all at once." Implementation site is `crafting_bench.gd:BenchView._draw_result`. Do NOT duplicate Plan.md's phases here — see Plan.md Part B / Phase B6 for the full spec.
- The code change: add a `_reveal_t: float` + `_reveal_idx: int` to `BenchView`; on `craft()` success, set `_reveal_idx = 0` and drive it via `_process` at ~0.3s per affix, queue_redraw per step.
- Each revealed affix gets the `pop()` animation (scale-overshoot) already in `BenchView._pops`.
- **DoD:** affixes appear sequentially after crafting, each with a pop/overshoot; total reveal ≤1.2s for a 3-affix chart. Feel-bench capture confirms. Gate green.
- **Effort: M** (mostly reusing existing `_pops` + `stamp` machinery in `BenchView`)

### Phase 5 — Portrait assets in dialog_panel (art-gated expansion)
This phase is BLOCKED on art assets and is listed for completeness:
- `dialog_panel.gd:PortraitWell` is ready to receive a `Texture2D` — add `var portrait_tex: Texture2D = null` and draw it via `draw_texture_rect` inside `PortraitWell._draw` when non-null.
- Caller (`quill_npc.gd`, etc.) passes a preloaded portrait via `dialog.portrait_tex = preload(...)` in `_ready`.
- **DoD:** Quill's dialog shows her painted portrait in the well; fallback silhouette still shows when `portrait_tex` is null. Gate green.
- **Effort: S** (code side only; art pipeline generates the portrait separately)

## Dependencies & links

- [[system-skills-hotbar]] — the mastery-ladder Trades tab in `inventory_panel.gd` renders the same perk data that the hotbar and skill system own; any perk-display change must stay in sync.
- [[system-trades-progression]] — the XP bar and level readout in the Trades page directly reflects trade-level state; trade-level cap changes (ADR 0006, cap 17) affect what the mastery ladder renders.
- [[system-charts-wayfinding]] — the Charts tab in the pack (`inventory_panel.gd:_draw_charts_tab`) and the waystone list (`waystone_panel.gd`) are the player-facing chart case view; chart data changes cascade here.
- [[system-chart-affixes]] — the crafting bench result panel's live odds preview and the post-inscribe affix-reveal (Phase 4) are the primary affix UI surface.
- [[system-inventory-equipment]] — the Gear tab (Tetris grid + paper-doll) is co-owned by the inventory panel; slot layout changes must track `SLOT_OFFSET` in `inventory_panel.gd:28–39`.
- [[system-economy]] — vendor panel is the primary economy UI; wares list + sell list are driven by `EconomyData.WARES` and `game.sell_item`.
- [[system-interactables]] — waystone, shrine, and chest all spawn their panels; shrine spawns `ShrineChoiceModal` (Phase 1 fix target), waystone spawns `waystone_panel.gd`.
- [[system-hud]] — the buff HUD chip (Phase 2) lives in `player_hud.gd`; it must not conflict with the globe positions or skill tray layout.
- [[system-npc-story-tutorial]] — dialog_panel.gd (Phase 5 portrait) is driven by NPC scripts; `quill_npc.gd` is the first caller.
- Plan.md Part B / Phase B6 — the inscribe affix-reveal (Phase 4 here) is the UI surface for that feel beat; implementation coordinates with the feel/animation pass.

## Verification

- **Phase 1** (shrine modal): `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` must stay green; visual check with `WYRD_SHOT=1` — open a shrine in the dungeon and screenshot the styled modal.
- **Phase 2** (buff chip): add a logic test to `test_wyrd_loop.gd` asserting chip count equals `game.get_active_buffs().size()` after a shrine activation; run all four headless suites.
- **Phase 3** (font consistency): `WYRD_NO_SAVE=1` four-suite gate green; screenshot vendor panel with `WYRD_UI_SHOT=vendor` (see `wyrd/tools/capture_ui.sh`) to confirm hover contrast.
- **Phase 4** (affix reveal): add a logic test that `craft()` triggers `_reveal_idx` to increment through all affixes; capture a mid-reveal frame with `WYRD_FEEL=inscribe` (feel bench, Plan.md B-3). Four-suite gate green.
- **Phase 5** (portrait): four-suite gate green; open Quill's dialog and verify portrait renders (`WYRD_UI_SHOT=dialog`).
- All phases: run `wyrd/tools/check_ninepatch.py` after any stylebox or texture change.

## Open questions

- Should the buff HUD chip display duration as a fraction ("8.0s remaining") or as a draining trough? A trough is consistent with the kit meters but requires polling; a text chip is simpler and matches the cozy aesthetic (Caveat hand font).
- Phase 4 affix-reveal speed: 0.3s/affix × 3 = 0.9s total feels right, but a trophy-locked den affix (always last) might warrant a slightly longer pause (0.5s) as the "guaranteed den" payoff. Worth a playtest pass.
