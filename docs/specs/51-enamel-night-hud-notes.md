# Spec 51 — Storybook Enamel Night HUD re-skin

## Why
Playtest feedback in the bog biome: *"i dont love the ui... the white
parchment doesnt make sense."* The pale-parchment HUD (cream 9-patch +
sepia ink) was authored against a bright town; over the dark, saturated
dungeon biomes it floated as a bright slab and broke the mood.

## Direction
Two candidates were rendered to the Desktop (Walnut vs. Enamel Night). User
picked **B — Storybook Enamel Night**: deep enamel-teal frames with leaf-gold
filigree and warm-cream body text. The whole HUD now sits *inside* the dark
world instead of on top of it.

## How (no new art — pure re-tint)
The carved-wood UI Kit ninepatch is reused; only colour changes.

- **`wyrd_ui.gd`** — the styling source:
  - Palette: `INK` → warm cream body text; `GOLD` leaf-gold filigree.
  - KIT tokens: `KIT_PLATE` deep enamel face `(0.075,0.231,0.212)`,
    `KIT_WELL` darker trough, `KIT_EDGE` = GOLD.
  - `StyleBoxTexture.modulate_color` darkens the pale wood: `PANEL_MOD`/
    `BTN_MOD` (+hover/press/disabled) teal, `SELECT_MOD` green glow.
  - Button font hover/pressed → GOLD; meter label gains a dark KIT_WELL
    outline so cream reads over bright HP/Focus fills; meter trough border is
    GOLD over a teal well; carved-button disabled face muted teal; flourish
    connector + diamond already gold via KIT_EDGE; flat panel fallback teal/gold.
- **`player_hud.gd`** — quest plate modulates to PANEL_MOD; `✦ Quest` header
  and progress line gilded/sage; mute idle label lightened (was dark-on-dark);
  GlobeGauge ring gilded, nest pegs → KIT_PLATE teal studs; co-op party panel
  teal/gold.
- **Modals** — the texture-backed panels (Charm Table / Loadout / Vendor /
  Quill) had hard-coded bright-cream icon-plate wells
  (`draw_well(self, ir, Color(0.95,0.91,0.80))`); dropped the arg so they use
  the dark teal `KIT_WELL` default and stop clashing on the teal panel.

## Deliberately left parchment
`inventory_panel.gd` (Gear/Satchel) and `crafting_bench.gd` draw a *full*
parchment surface top-to-bottom — an internally-coherent "ledger/journal",
not a bright plate on a teal panel. Flipping those to teal is a separate
design call (warm journal vs. teal slab), flagged for the user rather than
assumed. World-space labels (`wyrd_ui` style_hud_label, `player_controller`
floating tags) and the chart-scroll icon stay parchment by intent.

## Verify
- `test_boot_smoke` 93/0.
- In-bog capture (`WYRD_DEV_CHART=mire WYRD_SHOT_PATH=...`): teal action bar,
  gilt orb rings with teal studs, gilt `QUEST` banner — coherent over the bog.
- `WYRD_UI_SHOT=enchant`: Charm Table reads teal/gold, no cream clash.
