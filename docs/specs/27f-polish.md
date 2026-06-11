# 27f — Tooltips + polish

> The closing pass. Hover an item (ground or grid) → tooltip with name/rarity/affixes/stats. Pickup + equip SFX (ElevenLabs). Visual polish on the inventory UI. The loot loop ships *satisfying*.

## Why

After 27a-e the system *works*. 27f makes it *feel*. Tooltips are the readout that makes affixes legible; SFX make every pickup land; visual polish (margins, contrast, the panel's frame) makes the UI not look programmer-art.

## Scope

### A. Tooltips
- A floating `InventoryTooltip` panel that appears on hover (over a grid item, an equipment slot, or a ground beacon).
- Content: item name in rarity colour · category (Weapon / Helmet / Ring …) · base stat line · each affix on its own line.
- Follows the cursor (with screen-edge clamping).
- Hide on mouse-out / panel-close.

### B. SFX (ElevenLabs)
- 3 new SFX: `pickup` (a soft chime), `equip` (a metallic clink), `inv_open` (a paper rustle for opening the panel).
- Generated via the existing ElevenLabs pipeline (key from `.env`). Confirm cost with the user before generating.
- Wired: pickup → grab event; equip → `equip()` call; inv_open → I-key toggle.

### C. Inventory UI polish
- Replace plain rects with framed cells (the spec-15 `tokens.css`-style ink frame, ported to Godot via a 9-slice panel).
- Item-cell hover highlight (subtle glow).
- Rarity colour outlines on the item rect (cream/blue/gold/orange — matches the damage-number tiers from spec 26).
- Equipment slot icons (small placeholder glyph per slot type).

### D. Loot-rain feel
- When an enemy drops multiple items, stagger their spawn over ~0.25s (one every ~80ms) so the drop READS as a cascade — small juice win.

### E. Eval coverage
- No automated evals — this is hover/SFX/visual polish, all hand-tested. Add a screenshot to the notes.

## Files

| Path | Action |
|---|---|
| `godot/scenes/InventoryTooltip.tscn` + `.gd` | new |
| `godot/scripts/inventory_panel.gd` | wire hover → tooltip; cell polish |
| `godot/scripts/item_pickup.gd` | hover → tooltip on the world label |
| `godot/scripts/sfx.gd` | new SFX entries + paths |
| `godot/audio/pickup.mp3` · `equip.mp3` · `inv_open.mp3` | new — ElevenLabs |
| `godot/scripts/combatant.gd` | stagger multi-drops |

## Acceptance
1. Hover any item → tooltip appears with the full readout.
2. Pickup / equip / open-inventory each fire their distinct SFX.
3. The inventory UI reads as designed, not placeholder.
4. Multi-drops cascade out, not all at once.

## Open decisions
- **Tooltip styling** — match the dialog modal's ink frame (`tokens.css` analogue) for cohesion. Lean: port the same look.
- **SFX prompts** — I'll draft, confirm with the user, generate.
- **A 4th SFX — `inv_close`** — or reuse `inv_open` for both. Lean: reuse.
