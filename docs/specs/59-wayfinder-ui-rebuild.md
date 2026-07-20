# 59 — Wayfinder UI rebuild: Field Journal system

> **Outcome:** every player-facing screen is rebuilt on one accessible,
> responsive Godot Control system whose information hierarchy, input behavior,
> and Field Journal visual language remain coherent from HUD to workstations to
> menus.

## Why

The current UI is unusable for systemic reasons, not because it needs another
skin pass. The live build mixes pale Maple panels, Enamel Night cream text,
dark-teal rows, and glossy green buttons. `WyrdUi.INK` now means cream text for
dark surfaces while the panel factory resolves to pale paper, producing literal
cream-on-cream labels. Load-bearing content is commonly 11–14px, large windows
contain dead acreage, ordinary interactions are custom-drawn mouse hitboxes,
and each script independently owns layout, scrim, close, and focus behavior.

This spec replaces that failure-prone arrangement with semantic visual roles,
a real Godot Theme, reusable Control scenes, a central modal/navigation layer,
and screen-specific information architecture. The locked visual contract is
`docs/UI_BIBLE.md`; ImageGen references communicate hierarchy and tone rather
than pixel-perfect assets.

## Product principles

1. **Purpose before decoration.** In three seconds the player can identify the
   screen purpose, current selection, consequence, and next action.
2. **Materials have meaning.** Paper carries authored/descriptive content;
   walnut/moss carries controls/live state; the world remains visible around
   both.
3. **No color-only state.** Focus, selected, staged, unavailable, and invalid
   each combine color with shape, pointer, check, label, or reason.
4. **Controls are Controls.** Ordinary interactions are semantic Godot Controls,
   not manually tracked `_draw()` rectangles.
5. **All primary inputs ship together.** Mouse, keyboard, and gamepad paths are
   part of every screen, including focus entry and restoration.
6. **References are rules, not screenshots to trace.** Generated art never
   invents source data or becomes a requirement for layout.

## Scope

**In:**

- An emergency semantic contrast seam that fixes current light/dark text roles
  before the full rebuild lands.
- A semantic `WayfinderTheme` with named type variations, material surfaces,
  spacing/type/motion tokens, focus styling, and input glyphs.
- Reusable scene components and a component-lab fixture covering every state.
- One modal/router stack for pause ownership, scrim, z-order, cancel, initial
  focus, and focus restoration.
- Information-architecture and layout rebuilds for every surface in the screen
  map below.
- Responsive behavior at 1280×720 minimum, 1366×768 primary, 1920×1080, and an
  ultrawide fixture.
- Mouse, keyboard, and gamepad navigation; readable tooltips/instructions;
  deterministic visual captures and UI contract tests.
- Removal of legacy palette branches and ordinary custom-hitbox layouts after
  functional parity is demonstrated.

**Out (explicit non-goals):**

- Rewriting inventory, recipe, chart, Trade, combat, networking, or save data.
- Treating ImageGen-rendered portraits, items, Skills, or biome illustrations as
  shipped assets. Existing real assets or deliberate placeholders remain valid.
- Pixel-for-pixel reproduction of paper grain, bevels, botanical ornament, or
  generated text.
- Adding new gameplay systems or changing input bindings without a separate
  gameplay decision.
- A mobile/touch-specific UI. Layout must remain safe at the listed desktop
  fixtures; touch is a later contract.

## Locked visual direction

**Wayfinder's Field Journal**, selected from the controlled Chart Table A/B/C
ImageGen comparison. Direction A scored 92/100 in design review; it borrows
Direction C's explicit focus pointer, ring, selection fill, and staged check.

- Warm oat paper + dark walnut ink for authored content.
- Muted moss + cream text for persistent controls/live state.
- Honey-oak only as restrained shell/separation.
- Sage focus/selected/valid; terracotta warning/invalid; muted gold
  reward/rarity/completion.
- IM Fell type at 16px minimum body, 18–20px dialogue.
- Ornament only on mastheads/corners; never around every row.
- Ordinary rounded rectangles and Containers; no suitcase hardware, giant
  cartouches, puzzle-piece sockets, enamel-luxury layering, or candy pills.

See `docs/UI_BIBLE.md` for exact semantic roles, state language, starting
tokens, and the locked generation stem.

## Screen map and production contract

| Family | Surfaces / states | Required production shape |
|---|---|---|
| Startup | title/main menu, continue/new, network entry, credits | focused vertical task, readable over background, consistent settings entry |
| System | pause, options, system/network, confirmations | one modal shell; explicit apply/back/destructive actions; focus restoration |
| HUD | objective/compass, HP/Focus, Skill bar, Q-slot, run meta, boss bar, status, toast, party/co-op, interact prompt | world-first walnut/moss edge furniture; authored quest/toast paper is transient and collapsible |
| Pack | Gear, Satchel, Charts, Trades; empty/full/scroll/tooltip/drag-or-click states | semantic tabs; container rows/cards; equipped region; inventory views; no custom Tetris hitbox dependency |
| Dialogue | portrait/no portrait; paging; zero/one/many choices; disabled choice | lower third; prose max line length; scrollable large choices; advance/cancel hints |
| Chart Table | Supplies/Mix modes, ink rail, socket grid, preview, requirements, odds/affixes, pot, Codex index/detail/staging, guided tutorial, read-only guest | source → surface → result; normal focusable sockets; connectors may be non-interactive drawing; incomplete action disabled with reason |
| Transaction | Vendor, Cookfire, Forge, Enchant, Waystone, Quill, Loadout, Mastery | shared master-detail shell; source list, selection detail/consequence, cost/requirements, dominant action |
| Peripheral | micro-cutscene caption/skip, debrief, level-up/choice, empty states, error/confirmation banners | shared type/state/shell behavior; no orphan skin |

Before migrating Pack, decide whether Charts and Trades remain Pack tabs or
become sibling pages. Record the decision in the notes file; preserve existing
key access regardless of ownership.

## Information-architecture contracts

### HUD

- Preserve at least 88% of the world unobstructed in the ordinary town state.
- Persistent state uses compact walnut/moss furniture; no full-width paper slab.
- Quest note collapses after updates; shortcuts/context chips appear only when
  useful. Boss, status, party, toast, and ultrawide states must not collide.
- Skill slots communicate key, icon, availability, cooldown, selection/focus,
  resource cost, and disabled reason without depending on icon art.

### Pack

- Gear presents equipped slots and backpack items as actual Controls with a
  compact/standard/detail row system and real scrolling.
- A painted paper doll is optional. Use the existing live character
  representation, SubViewport, or deliberate silhouette; layout may not depend
  on unique appearance art.
- Comparison is readable without hover-only color. Equip/unequip actions and
  focus order are explicit.
- Satchel, Charts, and Trades use the same shell, tabs, rows, empty states,
  tooltips, and scrolling rather than bespoke draw loops.

### Chart Table

- Preserve all behavior from Spec 58: Supplies/Mix, compatible/incompatible
  reasons, click/drag placement, ink rail, pot, preview, guaranteed/weighted
  outcomes, costs/return rules, Mara's Codex, discovery/rumour/ghost/staging,
  tutorial guidance, deterministic inscription, and guest read-only mode.
- The action is disabled while incomplete and states the missing requirement.
- Preview is text-first. A reusable biome emblem/vignette is optional; generated
  chart-specific illustration is never required.
- Socket Controls live in Grid/Center Containers. Optional connector lines are
  drawn behind them and own no hit testing.
- One close affordance. Codex/mode changes do not create a second modal.

### Dialogue

- World remains visible above a lower-third panel no taller than 40% in the
  ordinary state.
- Prose uses 18–20px type and a readable max line length.
- Portrait size is proportional; no-portrait variant gives space back to prose.
- Choices are 48px minimum, scroll when necessary, and expose focus/disabled
  reasons. Generated key glyphs are placeholders for the glyph provider.

### Transaction family

- One shared pattern: source list → selected detail/consequence → cost or
  requirements → primary action.
- Empty, unavailable, insufficient-cost, selected, busy, success, and error
  states are defined once.
- The primary action is visually dominant and remains in a stable location.

## Architecture

### Foundation

Create one semantic foundation; exact file boundaries may adjust during the
component-lab slice, but responsibilities may not recombine into a static bag.

- `UiTokens`: paper/walnut/moss surfaces; `text_on_paper`, `text_on_dark`;
  semantic state/rarity/disabled roles; 4/8 spacing; type scale; motion; hit
  targets; breakpoints.
- `WayfinderTheme.tres`: type variations for Display, PageTitle, SectionTitle,
  Body, Caption, Numeric, Primary/Secondary/Destructive/Icon/Tab buttons,
  LineEdit, Slider, CheckBox, ScrollBar, and Tooltip.
- Material styles: PaperSurface, WalnutFrame, MossWell, FocusRing, Divider,
  portrait/item wells. No runtime Maple/Enamel/kit fallback roulette.
- `UiSafeArea`/breakpoint policy and input-glyph provider.

### Reusable components

**Shell/navigation:** `ModalShell`, `PageHeader`, `CloseButton`, `TabBar`,
`TabButton`, `SectionHeader`, `KeyHint`, `UiRouter`/`ModalStack`.

**Data/actions:** primary/secondary/destructive/icon buttons; `ItemRow` in
compact/standard/detail variants; `ItemCard`, `ItemIconWell`, `EquipmentSlot`,
badges, comparison delta, `RequirementRow`, `CurrencyChip`, `ProgressMeter`,
`EmptyState`, `ScrollableList`, `Tooltip`, `ChoiceCard`, `RecipeRow`,
`TradeProgressCard`, `AffixRow`, and `PartyMemberRow`.

**Feedback:** state presenter for focus(pointer+ring), selected(fill),
staged(check), unavailable(desaturated+reason), and error(terracotta+reason);
toast stack, transient quest note, banner, cooldown overlay, status badge, and
tutorial highlight.

**Specialized compositions:** HUD, Dialogue, Pack, Chart Table, and the shared
master-detail transaction shell.

### Code boundaries

- Screens compose `.tscn` Control scenes and bind data/signals in scripts.
- `Theme` type variations own styling. Screens do not hard-code semantic colors
  or raw font sizes.
- `_draw()` is limited to non-interactive decoration and specialized chart/HUD
  visualization. Every ordinary click target is a Button/Control.
- The router owns modal pause accounting, stack order, `ui_cancel`, initial
  focus, and returning focus. Individual screens do not each invent these.
- Data resolution remains in existing domain/data APIs; UI renders results and
  invokes existing commands.

## Target files

Exact component filenames may be refined in implementation notes; these are
the intended ownership seams.

| Path | Action |
|---|---|
| `docs/UI_BIBLE.md` | locked visual and semantic contract |
| `docs/ui-refs/redesign/` | baseline, direction comparison, hero refs, prompt record |
| `wyrd/themes/wayfinder_theme.tres` | new authoritative Godot Theme |
| `wyrd/scripts/ui/foundation/` | new tokens, glyphs, safe-area helpers |
| `wyrd/scenes/ui/components/` | new reusable Control scenes |
| `wyrd/scripts/ui/components/` | new component behavior |
| `wyrd/scenes/ui/screens/` | new screen compositions |
| `wyrd/scripts/ui/router.gd` | new modal/navigation coordinator |
| `wyrd/scripts/ui/wyrd_ui.gd` | shrink to compatibility bridge, then remove legacy branches |
| `wyrd/scripts/player_hud.gd`, `wyrd/scripts/skill_bar.gd` | migrate to HUD composition |
| `wyrd/scripts/inventory_panel.gd` | replace custom-drawn screen with Pack composition |
| `wyrd/scripts/ui/dialog_panel.gd` | migrate to Dialogue composition |
| `wyrd/scripts/ui/chart_table_view.gd`, `crafting_bench.gd` | migrate to Chart Table composition without losing Spec 58 behavior |
| `wyrd/scripts/ui/{vendor_panel,craft_panel,enchant_panel,waystone_panel,quill_panel,loadout_panel,mastery_choice_panel}.gd` | migrate to transaction family |
| `wyrd/scripts/ui/{pause_menu,options_menu,system_menu,credits_menu}.gd`, `wyrd/scripts/main_menu.gd` | migrate system/startup family |
| `wyrd/test_ui_*.gd` | extend with contrast, layout, focus, router, and state contracts |
| `wyrd/tools/capture_ui.sh` | deterministic state/resolution capture matrix |

## Migration plan and gates

### Slice 0 — freeze evidence and screen ownership

- Archive deterministic before captures at 1280×720, 1366×768, 1920×1080,
  and ultrawide for stable routes.
- Complete the screen/state map and decide Pack tab ownership.
- Record current keyboard/mouse/gamepad paths and missing paths.

**Gate:** every surface and state has an owner, capture route, migration slice,
and parity checklist.

### Slice 1 — emergency contrast seam

- Split text roles into paper/dark semantics and patch current cream-on-cream.
- Remove `PARCHMENT := INK`-style aliases that erase surface meaning.
- Add contrast assertions for the semantic role pairs.

**Gate:** no current stable capture contains same-role text/surface contrast
below 4.5:1 body or 3:1 large text/icons.

### Slice 2 — theme and component lab

- Land tokens, Theme, material styles, type variations, safe-area policy,
  glyph provider, focus pointer/ring, and all component states.
- Build a deterministic component-lab scene at every target resolution.

**Gate:** 48px targets, complete focus/hover/pressed/disabled/busy states,
mouse/keyboard/gamepad traversal, no clipping, contrast targets pass.

### Slice 3 — router and modal shell

- Centralize scrim, pause ownership, z-order, close/cancel, initial focus, and
  focus restoration.
- Migrate one simple system modal first; prove nested/rapid open-close safety.

**Gate:** no modal stacking, double pause count, lost focus, or world input leak.

### Slice 4 — HUD vertical slice

- Rebuild ordinary HUD plus boss/status/party/toast/interact/run-meta states.
- Validate against town and every dark biome before adding more paper surfaces.

**Gate:** world-first layout, no collisions at four resolutions, state updates
remain smooth, controller access works, five-minute combat/town play check.

### Slice 5 — Dialogue vertical slice

- Rebuild portrait/no-portrait, pages, zero/one/many choices, disabled choices,
  scrolling, advance/cancel, and focus restoration.

**Gate:** readable lower third, complete input parity, no full-screen takeover.

### Slice 6 — Pack family

- Resolve screen ownership; rebuild Gear, Satchel, Charts, and Trades using
  semantic tabs, rows/cards, scrolling, tooltips, and comparison.
- Remove ordinary custom hitboxes only after parity tests pass.

**Gate:** every current action remains possible; no clipping; no hover-only
  requirement; focus graph covers all visible actions.

### Slice 7 — Chart Table

- Recompose Spec 58 behavior using source list, focusable grid, preview, Codex,
  tutorial and read-only variants.
- Keep domain resolver/materialization boundaries unchanged.

**Gate:** all deterministic Chart/Codex routes match functional parity; action
disable/reasons are correct; existing Chart tests and transitions stay green.

### Slice 8 — transaction family

- Migrate Vendor → Cook/Smith → Enchant → Waystone → Quill →
  Loadout/Mastery through one master-detail shell.

**Gate per page:** purpose read, all source/detail/action states, input parity,
resolution matrix, and page-specific functional tests.

### Slice 9 — startup, system, and peripheral family

- Migrate title/main menu, pause, options, network/system, credits,
  micro-cutscene/debrief/level-up and remaining overlays.

**Gate:** no orphan visual language or modal/input behavior remains.

### Slice 10 — audit and legacy deletion

- Run the deterministic state matrix and side-by-side rule review.
- Run five-minute town/dungeon/transaction play checks.
- Delete palette branches, unused textures, legacy custom layouts, and
  compatibility shims only after route parity.

**Gate:** all acceptance criteria and the full automated suite pass.

## Acceptance criteria

1. Every surface in the screen map uses the Field Journal semantic material
   rule and no unexplained Maple/Enamel/legacy skin remains.
2. Every stable screen passes the three-second purpose/selection/consequence/
   action read with its intended data state.
3. Body text and controls use at least 16px at 1366×768; dialogue uses at least
   18px; required instructions are never captions.
4. Semantic contrast pairs meet 4.5:1 for body text and 3:1 for large text,
   icons, controls, and focus indicators.
5. Every ordinary interactive target is at least 48×48px and has mouse,
   keyboard, and gamepad access plus visible focus.
6. Focus, selected, staged, unavailable, invalid, and primary states match the
   UI Bible and do not rely on color alone.
7. Modal open/close/cancel behavior, pause ownership, z-order, initial focus,
   and focus restoration are centralized and contract-tested.
8. Stable routes render without clipping or overlap at 1280×720, 1366×768,
   1920×1080, and the ultrawide fixture.
9. HUD remains world-first and collision-free across ordinary, boss, status,
   party/co-op, toast, and interact states.
10. Pack, Dialogue, Chart Table, and every transaction page preserve existing
    gameplay/data behavior while replacing manual layout and ordinary hitboxes.
11. Chart Table retains all Spec 58/Codex/tutorial/guest routes; incomplete
    inscription is disabled and explains missing requirements.
12. Generated images are references only; shipped layout works with missing or
    placeholder portraits/icons/biome art.
13. `capture_ui.sh` produces a deterministic before/after surface matrix and
    stores route metadata (resolution, focus, data state).
14. All six canonical suites, UI/modal/icon contracts, Chart Table UI,
    progression/save contracts, and new theme/layout/focus/contrast tests pass.
15. A five-minute town-to-dungeon play check and one transaction per workstation
    complete without unreadable text, input trap, accidental world input, or
    layout collision.

## Verification commands

```bash
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_boot_smoke.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_coop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_ui_modal_and_icon_contract.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_chart_table_ui.gd
```

Add and run new theme/layout/focus/contrast scripts as they land. Use
`bash tools/capture_ui.sh` for visual QA; it must be upgraded from its current
single-resolution route list during Slice 0.

## References

- `docs/UI_BIBLE.md`
- `docs/ui-refs/redesign/current-ui-baseline-board.jpg`
- `docs/ui-refs/redesign/chart-table-directions-board.jpg`
- `docs/ui-refs/redesign/field-journal-hero-board.jpg`
- `docs/ui-refs/redesign/IMAGEGEN_PROMPTS.md`
- `docs/specs/58-wayfinding-chart-table.md`
- `docs/specs/53-taste-refactor.md` (documents the failed multi-skin seam)
- `docs/WORLD_BIBLE.md`
- `wyrd/scripts/ui/wyrd_ui.gd`
- `wyrd/test_ui_modal_and_icon_contract.gd`

## Done check

- [ ] Every current UI surface/state is mapped and has deterministic evidence.
- [ ] Semantic contrast roles and Theme/component lab pass their contracts.
- [ ] Router/ModalShell owns modal behavior and focus restoration.
- [ ] HUD, Dialogue, Pack, and Chart Table pass their vertical-slice gates.
- [ ] Every transaction, system, startup, and peripheral surface is migrated.
- [ ] Four-resolution capture matrix passes rule-based review.
- [ ] Mouse/keyboard/gamepad paths are complete with visible focus.
- [ ] Legacy palette branches and ordinary custom hitbox layouts are removed.
- [ ] Full automated gate and five-minute play checks pass.
