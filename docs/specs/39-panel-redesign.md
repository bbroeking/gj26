# 39 — Panel UI redesign (replace the hedgewood direction)

> **Outcome**: the hedgewood vine frames are gone; a new panel style — picked
> by the user from distinct generated candidates — skins every window through
> one skin module, built from assets that are *designed* for nine-patch use
> instead of fought into it.

## Why

The spec-38 hedgewood pass proved the styling pipeline works but the
direction wrong: organic asymmetric vine art fights the nine-patch (margins
guessed three times, a tendril tiled across panel interiors, every panel
needed bespoke asymmetric insets), and the user rejected the look. The
readability wins from that pass (bigger type on trades/satchel, measured
row advance) are keepers. The lesson to encode: **generate frame art that is
symmetric, border-only, and interior-clean — or don't nine-patch it.**

## Scope

**In:**
- **Phase 0 — revert to baseline.** Restore `panel_frame_9p.png` as
  `PANEL_TEX_PATH` with its original symmetric margins; back out the
  per-side margin plumbing and the asymmetric content insets in
  inventory/craft/inscribing/vendor panels (symmetric insets, sized for
  the baseline frame). KEEP the bigger type, measured row advances, and
  shortened row copy from the readability pass. All 10 captures clean.
- **Phase 1 — style exploration.** Generate 3–4 genuinely distinct panel
  directions via Midjourney (the connector flow). Every prompt must
  request: *symmetric border, uniform thickness on all four sides, plain
  empty parchment interior, frontal, isolated, square* — nine-patch-able
  by construction. Candidate directions (adjust freely): (a) refined
  ink cartouche — double-line border, corner flourishes, wax accent;
  (b) pale carved wood — symmetric chamfered frame, small corner
  carvings; (c) stitched linen/leather journal border; (d) brass-and-ink
  cartographer plate. Present crops to the user; **stop at a pick gate**
  (AskUserQuestion) before implementing.
- **Phase 2 — skin module.** Build the chosen direction properly:
  - frame nine-patch (verify programmatically: the center region of the
    texture contains only low-variance parchment — add this check to a
    test or tool script so bad art can't ship again);
  - separate corner-ornament overlays IF the style has heavy corners
    (drawn at fixed size on top, never stretched);
  - matching button plate, section divider, and header treatment;
  - all routed through `WyrdUi` so panels don't hand-build styleboxes
    (today `inventory_panel` duplicates the stylebox — consolidate).
- **Phase 3 — apply + audit.** Reskin all surfaces, run
  `tools/capture_ui.sh`, review every capture, fix, re-capture. The HUD
  bramble globes/tray stay as shipped (user liked the direction) unless
  the new panel style clashes — flag if so, don't silently restyle.

**Out (explicit non-goals):**
- HUD bottom bar changes (globes/skill tray are spec-38, accepted).
- The dialog panel's Midjourney frame — it has its own art; only touch
  if the user's pick clashes hard.
- New fonts, new palette — type and colors stay per the UI bible.
- Any gameplay/system change.

## Files

| Path | Action |
|---|---|
| `wyrd/assets/ui/hedgewood_frame_9p.png` | delete (archive ref stays in docs/ui-refs/) |
| `wyrd/assets/ui/panel_frame_v2_9p.png` (+ corners) | new — the picked style |
| `wyrd/scripts/ui/wyrd_ui.gd` | modify — single skin module, revert per-side margins |
| `wyrd/scripts/inventory_panel.gd` | modify — symmetric insets, consume WyrdUi stylebox |
| `wyrd/scripts/ui/craft_panel.gd` | modify — symmetric insets |
| `wyrd/scripts/ui/inscribing_panel.gd` | modify — symmetric insets |
| `wyrd/scripts/ui/vendor_panel.gd` | modify — symmetric insets |
| `wyrd/tools/check_ninepatch.py` | new — center-region cleanliness check |
| `docs/ui-refs/` | new mock files for the chosen + rejected directions |

## Acceptance criteria

1. Phase 0: baseline restored — all 10 `capture_ui.sh` surfaces render with
   the original parchment frame, bigger type intact, no clipped/overlapping
   text anywhere.
2. Phase 1: ≥3 distinct candidates generated and shown; the user picked one
   via an explicit gate; rejected candidates archived in `docs/ui-refs/`.
3. Phase 2: `check_ninepatch.py` passes on the new frame (center region
   variance below threshold; border thickness within ±15% across sides);
   `WyrdUi` is the only place styleboxes are constructed.
4. Phase 3: all 10 surfaces re-captured in the new skin and reviewed; the
   three headless suites stay green; game restarted via MCP.

## Open decisions

- **Candidate set** — the four directions listed are suggestions; pick
  whatever reads most distinct. At least one should be *quiet* (close to
  the current baseline, refined) so the user can choose "less, but
  better."
- **Corner overlays vs pure nine-patch** — decide per the picked art;
  record in notes.
- **Upscale before cutting** — Midjourney upscale of the picked candidate
  before asset-cutting if the 1024 grid crop is soft.

## References

- `docs/specs/38-tools-mute-globes-ui-notes.md` — what went wrong with
  organic nine-patching (margins ×3, interior tendril tiling).
- `docs/UI_BIBLE.md` master stem; memory `chunky toon, not painterly`
  (bold ink outlines, flat cel-shaded, no --style raw).
- Browser flow: connector browser "personal", Midjourney imagine tab.
- Memory `godot-draw-load-white-texture` — preload any texture used in
  `_draw`.

## Done check

- [ ] Hedgewood gone; baseline captures clean with big type
- [ ] 3–4 candidates generated, user picked at a real gate
- [ ] New frame passes the nine-patch check; WyrdUi owns all styleboxes
- [ ] 10/10 surfaces re-captured clean in the new skin
- [ ] Suites green; game restarted; notes file updated
