# Spec 53 — Taste refactor (Eliminate Generic AI Frontend)

User applied the "Taste Skill" design operating standard to the game UIs: audit
for slop → rank by impact → improve, held to *"would an experienced product
designer intentionally make this decision?"*

## Audit (5-agent workflow, code + screenshots)
Scores: pack **4**, modals **~4**, foundation **5**, stations **5**, HUD **6**.
The leaves have taste (vector primitives, GlobeGauge, Enamel tokens); the trunk
was missing. Six systemic root causes, almost all in `WyrdUi`:

1. **No default font** → most text fell back to engine Open-Sans, not IM Fell.
2. **No type scale** → 13 ad-hoc sizes (10–24) + a hidden `+1` fudge in
   style_body/style_dim.
3. **No spacing scale** → magic offsets (5/6/7/9/26…) off any grid.
4. **Bifurcated skin** → the Pack + crafting bench still render the *old light
   parchment* inside the dark teal frame (a "warm wash" re-lights them).
5. **Duplicate components** → 4 copy-paste card classes, 3 button languages,
   drifting modal scaffolds (scrim 0.45–0.55, close-hint corner flips).
6. **Off-palette color** → Focus = stock mana-blue; "magic" rarity = SaaS blue.

## Ranked execution
- **Tier 1 — Foundation (D22 ✓):** default font, type scale, spacing scale,
  FOCUS / RARITY / NUMERIC tokens, `style_keyhint`, kill the `+1` fudge, fix the
  HUD flourish collision, route Focus + keybinds + costs through tokens.
- **Tier 2 — Unify the skin:** migrate Pack (inventory_panel), crafting bench,
  and the craft list onto Enamel tokens — kill the parchment wash, fix the
  invisible cream-on-pale icon chips, tier the recipe meta line, tokenize rarity.
- **Tier 3 — Shared components:** one `CardRow` + a modal scaffold factory →
  rebuild enchant / loadout / quill / vendor from one component.
- **Tier 4 — HUD finish:** content-hug chip height, run-meta icons + hierarchy,
  painted draught icon, paper-doll with a figure.

## Tier 1 — what shipped (D22)
`wyrd_ui.gd`: `SIZE_DISPLAY/TITLE/SECTION/BODY/LABEL/CAPTION/MICRO` type scale;
`SPACE_1..6` (4/8/12/16/24/32) spacing scale; `FOCUS` (luminous teal-cyan),
`NUMERIC`, and a `RARITY` ramp (magic→sky-teal not SaaS blue, rare→GOLD,
unique→TERRACOTTA, normal→INK_MID); `apply_defaults()` sets
`ThemeDB.fallback_font` = IM Fell English (the highest-leverage fix — unstyled
Labels stop rendering Open-Sans); `style_keyhint()` for one keybind badge;
style_body/style_dim drop the `+1`; style_title/section route to the scale.
`game.gd` calls `apply_defaults()` at boot. `player_hud.gd`/`skill_bar.gd`:
Focus globe + cost/count → FOCUS/NUMERIC, all keybinds → style_keyhint, quest
chip flourish (which crossed the objective baseline) + wax seal removed.

Verified: all six suites green; in-bog capture shows IM Fell body everywhere,
on-palette Focus, unified cream keybinds, no flourish collision.
