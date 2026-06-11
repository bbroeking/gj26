# 38 — Tool slots, mute, potion globes, UI audit

> **Outcome**: gathering tools live in their own equip slots (no bag space),
> audio can be muted in-game, HP/Focus render as Diablo-style potion globes
> anchoring a bottom-center HUD bar, and every UI surface has been
> screenshot-audited and fixed.

## Why

A5 (tools) is the next plan piece, and the user ruled tools must not eat
Tetris-bag space — they're per-trade equipment. B8 shipped audio with no
volume control, which blocks any real playtest session. The pack/satchel/
trades/dialog surfaces have accumulated drift and need one deliberate
audit pass. And the HP/Focus parchment meters never matched the
FATE/Diablo fantasy — the reference (PoE-style bottom bar, screenshot
2026-06-11) is: red HP globe bottom-left, blue Focus globe bottom-right,
framed skill buttons between them.

## Scope

**In:**
- **Phase 1 — tool slots (A5).** Two new equip slots on the paper-doll:
  *pickaxe* (Earthcraft) and *axe* (Wildcraft). New item kinds
  `bogiron_pickaxe` / `bogiron_axe` (models exist:
  `weapon_*_pickaxe/axe.glb` — check exact filenames in `models/`),
  craftable at Hod's Anvil. Equipped tool scales the matching gather
  channel: pickaxe → mining, axe → chopping. No tool = baseline speed,
  never blocked. Tools only fit their slot, never the grid-to-slot
  mismatch path; they DO live in the grid before equipping (they're
  items), but equipping moves them to the dedicated slot like any gear.
- **Phase 2 — mute.** A master mute toggle reachable in-game, persisted
  across sessions in the save. Mutes the one-shot pool AND the music
  channel. A small HUD affordance shows the muted state.
- **Phase 3 — potion globes.** Replace the top-left HP/Focus meters with
  two circular globes at the bottom corners of a bottom-center HUD
  cluster: HP red (left), Focus blue (right), liquid level = current/max
  (drains down, fills up), subtle glass highlight, ink-frame rim to stay
  in the storybook language. Move the skill bar between the globes.
  Draught count + Q hint sits by the HP globe. Damage flash / low-HP
  warning keep working.
- **Phase 4 — UI audit.** Extend the screenshot hook so ONE run captures
  every surface to `/tmp/wyrd_ui_<name>.png`: pack(gear), satchel,
  charts, trades, dialog, vendor, craft-cook, craft-smith, inscribing,
  plus the new HUD. Review each capture; fix what's broken/ugly within
  the existing visual language (ornament on frames/headers, clean type
  for data — the 2026-06-10 usability ruling). Re-capture to confirm.

**Out (explicit non-goals):**
- Tool tiers beyond bogiron (that's A6 node tiers' partner work).
- A full options/settings menu — mute is a toggle, not a menu.
- Re-skinning any UI from scratch; the audit fixes defects, it doesn't
  redesign.
- Click-to-move or any control change (ADR 0004 closed that).

## Files

| Path | Action |
|---|---|
| `wyrd/data/items.gd` | modify — tool kinds + categories |
| `wyrd/data/crafting.gd` | modify — pickaxe/axe recipes at the forge |
| `wyrd/scripts/equipment.gd` | modify — new slots |
| `wyrd/scripts/inventory_panel.gd` | modify — doll slots, audit fixes |
| `wyrd/scripts/gather_node.gd` | modify — tool-aware channel time |
| `wyrd/scripts/sfx.gd` | modify — mute state |
| `wyrd/scripts/game.gd` | modify — mute persistence; tool lookup helper |
| `wyrd/scripts/save_game.gd` | modify — muted field |
| `wyrd/scripts/player_controller.gd` | modify — mute keybind |
| `wyrd/scripts/player_hud.gd` | modify — globes, bottom bar, mute icon |
| `wyrd/scripts/skill_bar.gd` | modify — reposition into bottom cluster |
| `wyrd/scripts/town.gd` | modify — multi-surface screenshot hook |
| `wyrd/test_wyrd_*.gd` | modify — tool/mute/persistence coverage |

## Acceptance criteria

1. Pickaxe and axe craftable at Hod's Anvil; equipping each fills its own
   doll slot and frees its grid cells; mining with a pickaxe channels
   visibly faster (≥25%) than bare-handed; same for axe/chopping; foraging
   is unchanged. Tools can't be equipped into weapon/armor slots.
2. Mute toggles in-game with one input, silences everything including the
   town theme, shows its state on the HUD, and survives a quit/relaunch.
3. HP and Focus render as bottom-corner globes whose liquid level tracks
   the values in real time (verified by screenshot at full and after
   damage); the skill bar sits between them; nothing overlaps at 1280×720.
4. One command captures every UI surface to `/tmp/wyrd_ui_*.png`; each
   capture reviewed; every defect found is either fixed or recorded in
   the notes file with a reason.
5. All three headless suites pass; new tests cover tool-slot equip rules,
   tool-scaled channel time, and mute persistence.

## Open decisions

- **Mute input** — no free mnemonic key (M = satchel). Recommend `F10`
  keybind + a small clickable speaker icon near the globes; record what
  was picked.
- **Tool slot layout** — where the two slots sit on the paper-doll
  (recommend: a second column or below boots, visually grouped as
  "trade tools").
- **Globe rendering** — `_draw`-painted circles vs TextureProgressBar
  with generated art. Recommend painted (consistent with the pack window,
  no asset dependency); add a Midjourney-art pass later only if flat.
- **Tool speed bonus** — recommend −30% channel time, matching the
  Earthcraft 10 perk so they stack to roughly half-time mining.

## References

- Reference image: PoE-style bottom bar (user screenshot 2026-06-11) —
  red globe left, blue globe right, skill buttons centered between.
- `docs/wyrd-skills-combat-plan.md` — A5 entry + spine test.
- ADR 0004 (controls), 2026-06-10 usability ruling (ornament on frames/
  headers only) in `docs/wyrd-trades-recap.md`.
- `wyrd/scripts/ui/wyrd_ui.gd` — palette + meter helpers being replaced
  in Phase 3.
- Memory: `feedback_godot_draw_load_white_texture` — preload any texture
  a `_draw` needs; `feedback_godot_headless_test_harness` — test gotchas.

## Done check

- [ ] Tools craft, equip to their own slots, and speed their verb
- [ ] Mute toggles, shows state, persists
- [ ] Globes track HP/Focus; bottom bar reads like the reference
- [ ] Every surface captured, reviewed, fixed or noted
- [ ] 3 suites green with new coverage; game restarted via MCP
- [ ] Plan doc updated (A5 closed; audit findings logged)
