# Wayfinder UI — Design Choices Manifest

Every UI reference we ever generated lives in **this folder** (`docs/ui-refs/`).
The ones we actually *picked* were promoted into the game under
`wyrd/assets/ui/`. Until now the picks lived only in chat history — this file
records **which candidate won each surface and why**, so new work can match the
language instead of re-deriving it.

Visual index of the winners: **`design_language_board.jpg`** (in this folder).

## The folder

- `*.webp` — all Midjourney candidates, grouped by set: `hero_*` (title /
  inventory / dialogue / hud), `hud2_*` (bubble / cradle / crescent / satchel),
  `maple_A|B|C_*` (the panel skin), `icons_chunky|painted_*`,
  `kit_*` (button / card / frame / ornament / slot), `shop_list|merchant|tabbed_*`,
  and older `mj_*` refs.
- `*.html` — the pickers we clicked through to choose.
- `design_language_board.jpg` — labeled board of the winners.
- `wyrd/assets/ui/**` — the winners, knocked-out / 9-sliced and wired in.

## The picks

| Surface | Chosen | Also referenced | Where it lives in game |
|---------|--------|-----------------|------------------------|
| Panel skin (master) | `maple_B_4` | `maple_A_4`, `maple_C_2` | `wyrd/assets/ui/maple/`, `wyrd/assets/ui/kit/` + `scripts/ui/wyrd_ui.gd` `MAPLE_*` palette |
| Title screen | `hero_title_3` | — | `wyrd/assets/ui/menu/title_bg.webp`, `scripts/main_menu.gd` |
| Inventory | `hero_inventory_3` | — | `scripts/inventory_panel.gd` |
| Dialogue | `hero_dialogue_4` | — | `scripts/ui/dialog_panel.gd`, `wyrd/assets/ui/menu/dialogue_ref.webp` |
| Shop (Quill's Still) | `shop_list_4` | `shop_merchant_3`, `shop_tabbed_2` | `scripts/ui/quill_panel.gd` |
| HUD orbs / hotbar tray | `hud2_cradle_3` | `hud2_bubble_4`, `crescent_1/4` | `scripts/player_hud.gd`, `scripts/ui/hotbar_*.gd` |
| Item / skill icons | `icons_chunky_4` | — | `wyrd/assets/ui/icons/`, `wyrd/assets/ui/items/` |

## The language ("match the choices" = this)

- Warm **cream / parchment** panels inside chunky **rounded wooden** frames.
- **Leafy ivy / vine / mushroom + gold filigree** ornament — on frames only,
  never on body text.
- Soft **jade-green** accents; hand-painted storybook icons.
- Everything **pudgy and rounded** — no hard edges or sharp brackets
  (taste rule, memory `feedback_wyrd_ui_soft_not_hard`).
- **Quiet recessed cells; colour lives on the filled items** (2026-07-02) —
  do not tile a panel with bright identical slots.
- Dark ink text on cream, high-contrast and readable.

## How a choice becomes a change (the pipeline)

1. **Generate** candidates in Midjourney → drop the `.webp`s here, add to a
   `*_picker.html` for side-by-side.
2. **Pick** the winner → record it in the table above.
3. **Get it in-game** one of two ways:
   - **Code-draw to match** — reproduce the look with `StyleBoxFlat` / `_draw`
     primitives in `wyrd_ui.gd` + the panel script. Best for slots, cells,
     buttons, layout. (This is how the 2026-07-02 quiet-cell pass was done.)
   - **Painted slice (Path B)** — isolate the component in MJ, knock the
     background out (`magick … -fuzz 15% -fill none -draw "color 0,0 floodfill"`
     ×4 corners `+channel -trim`), 9-slice or sprite it, preload it in
     `WyrdUi._kit_cache`, draw via `draw_texture_rect`. Best for ornate frames,
     crests, ivy.
4. **Verify** — `WYRD_NO_SAVE=1 WYRD_SHOT=1 WYRD_UI_SHOT=<surface> godot --path .
   --quit-after 700` → `/tmp/wyrd_town.png`; compare against the reference and
   iterate until it matches.
