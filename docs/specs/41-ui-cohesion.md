# 41 — UI/HUD cohesion + Phase-3 page designs

> **Outcome**: every visible UI element — windows, HUD, overlays — derives
> from the Wayfinder UI Kit; no element uses an orphan style. The remaining
> pages get their Claude Design rounds (Phase 3 of the design pass), and
> the HUD joins the system instead of living outside it.

## Why

The user's read after the pilot: "it's not very cohesive — each part
doesn't look like it fits with the others." Accurate: the windows now
speak carved-wood kit language, but the HUD still mixes three older
dialects — bramble-nest globes (the pre-spec-39 direction), a parchment
skill tray, bare-label chips (draughts, mute, trades strip), and old
plain buttons (Gear/Satchel/Trades). Cohesion is a system property; it
needs one inventory, one kit, and every element re-derived.

## Scope

**In:**
- **Phase A — cohesion inventory.** Capture every surface (the 10 window
  shots + town HUD + dungeon HUD incl. a boss bar) and table every
  element → which style system it uses today (wood-kit / bramble /
  old-parchment / bare-label). The table drives the work; it lives in the
  notes file.
- **Phase B — extend the kit with HUD components.** One Claude Design
  round adding to the kit page: HP/Focus globe treatment that matches the
  carved-wood chrome (decide there: wood-ring globes vs bramble accents
  reconciled with wood), skill slot + tray, action button, quest tracker
  plate, toast, draught/mute chip, boss bar, interact prompt. The globes
  question is settled by the artboard, not in code.
- **Phase C — Phase-3 page designs** (the design-pass queue): Pack/Gear,
  Dialog, Vendor, Craft, Satchel, Charts, Inscribing. Same pilot loop;
  batch 2-3 pages per approval gate to keep momentum. Cut-line: Pack +
  Dialog are must-haves.
- **Phase D — implement the HUD redesign** from the extended kit
  (player_hud globes/chips/quest plate, skill_bar tray/slots, boss bar).
- **Phase E — full audit**: all captures re-taken (town + dungeon +
  windows), 3-second read test per surface, suites green, game restarted.

**Out (explicit non-goals):**
- New gameplay surfaces, new systems, new keybinds.
- Painted icon/emblem art generation (tracked separately; cells/emblems
  keep drawn glyphs until that lands).
- Re-opening the frame choice (carved wood is locked from spec 39).

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/player_hud.gd` | modify — globes, chips, quest plate from kit |
| `wyrd/scripts/skill_bar.gd` | modify — tray + slots from kit |
| `wyrd/scripts/boss_bar.gd` | modify — kit treatment |
| `wyrd/scripts/inventory_panel.gd` | modify — per approved page designs |
| `wyrd/scripts/ui/*.gd` (craft/vendor/inscribing/dialog) | modify — per designs |
| `docs/specs/41-ui-cohesion-notes.md` | new — inventory table + decisions |
| `docs/specs/40-ui-from-design-notes.md` | append — per-page contracts |

## Acceptance criteria

1. The inventory table exists and every "orphan style" row is either
   re-derived from the kit or explicitly accepted with a reason.
2. The kit page contains the HUD components; the user approved the globe
   treatment at a gate.
3. Pack + Dialog (minimum) have approved artboards and matching Godot
   implementations; each further page that lands follows the same loop.
4. Town HUD + dungeon HUD captures read as the same game as the windows.
5. All three suites green; game restarted via MCP.

## Open decisions

- **Globe treatment** — wood-ringed vs bramble-reconciled; settled by the
  Phase B artboard + user gate.
- **Quest tracker** — plate vs slim banner; let the artboard propose.
- **Batch size per approval gate** in Phase C — default 2-3 pages.

## References

- `docs/wyrd-ui-design-pass.md` (the pass plan + pilot retro + lessons:
  short prompts, text seeding, name every data point).
- `docs/specs/40-ui-from-design-notes.md` (pilot contract format).
- Memory: white-texture gotcha; `tools/check_ninepatch.py` for any new
  frame-like assets.

## Done check

- [ ] Inventory table written; no unexplained orphan styles
- [ ] Kit extended with HUD components; globe gate passed
- [ ] Pack + Dialog designed, approved, implemented (+ as many further
      pages as the session allows)
- [ ] HUD implemented from kit; town + dungeon captures cohesive
- [ ] Suites green; restart done; notes updated
