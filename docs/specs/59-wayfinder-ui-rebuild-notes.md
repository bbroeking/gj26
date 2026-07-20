# Implementation notes — 59-wayfinder-ui-rebuild

## Decisions

- **Selected Wayfinder's Field Journal with Field Kit interaction states.** A
  controlled ImageGen comparison held the Chart Table workflow constant across
  three styles. Field Journal scored 92/100; it best expressed Bramblewood and
  made the task clearest. The Field Kit's pointer/ring/check states were clearer
  than the Journal concept's ambiguous multiple green outlines, so those states
  are part of the selected system.
- **Information architecture is in scope.** The request is to make the screens
  usable, so Gear/Satchel/Charts/Trades ownership and transaction workflows may
  change. Existing gameplay commands and key access must remain available.
- **1366×768 is the primary visual target; 1280×720 is the floor.** The capture
  tooling and canonical project instructions currently use both. 1920×1080 and
  ultrawide are regression fixtures rather than separate art directions.
- **Mouse, keyboard, and gamepad parity is a ship criterion.** The current Chart
  Table already demonstrates controller focus graphs; other screens may not
  remain mouse-only.
- **Paper is content, not a universal skin.** Authored prose/outcomes/descriptions
  use paper; persistent controls/live state use walnut/moss. This lets HUD and
  Dialogue belong to one system without turning the whole game into parchment.
- **The emergency seam keeps legacy `INK` paper-safe.** While the current modal
  factory resolves to the pale Maple surface, `INK` and `PARCHMENT` now alias
  `TEXT_ON_PAPER`; dark HUD/chip/meter call sites explicitly request
  `TEXT_ON_DARK`. Legacy list rows become cream rows under Maple so their text
  and surface roles agree until those pages are replaced by Theme components.
- **Charts and Trades remain Pack tabs for this migration.** Existing `M`/`K`
  access and player expectations stay intact while the four pages gain one real
  tab system. They can become sibling destinations later without changing the
  underlying page components or key routes.
- **Dialogue is a lower-third composition, not a reskinned full-screen canvas.**
  Portrait/no-portrait, prose, and choices now use real Containers and Buttons;
  ordinary conversations preserve at least the upper 60% of the world view.
- **The HUD uses one compact field tray with horizontal vitals.** HP and Focus
  flank the Skill row as named meters. Quest prose remains a paper note; live
  actions and vitals use walnut/moss, keeping the ordinary world view dominant.
- **Pack interaction moved off the visual Tetris canvas without changing data.**
  Gear is presented as equipped slots plus a scrolling backpack of semantic
  Buttons. The underlying `Inventory` grid, item positions, `Equipment`, saves,
  and quick-equip swap behavior remain intact.
- **The Chart Table keeps its proven controller/domain adapter.** Its nine
  sockets, Ink rail, Codex, staging, and explicit focus graph were already real
  Controls with unusually deep tests. The rebuild replaces the Maple surface,
  raises type/target floors, and adds Field Journal state styling without
  rewriting Chart resolution.
- **Workstations share a transaction contract before sharing a scene file.**
  Vendor, Cookfire, Forge, Charm Table, Quill, Waystone, and Loadout now expose
  a stable `TransactionShell`, semantic 48px actions, initial focus, and the
  shared focus pointer. This preserves their mature domain bindings while
  establishing the common source → consequence → cost → action grammar.
- **Journal rows are one semantic Button composition, not a drawing helper.**
  `JournalListRow` owns its painted icon well, title/subtitle hierarchy,
  trailing consequence, state badge, disabled treatment, and native focus/
  press behavior. Pack equipment/backpack and Vendor buy/sell rows now provide
  small row models instead of recreating layout or `_draw()` logic. Vendor
  preserves its one-press buy/sell commands; the shared row makes price,
  affordability, owned count, and action explicit before a future optional
  detail pane is considered.
- **Journal row state is a single validated enum.** Tara's review found that
  independent `selected` and `disabled` booleans permitted an undefined
  selected+disabled combination and that unknown Dictionary keys failed
  silently. `JournalListRow.RowState` now admits only normal, selected, or
  disabled; debug builds assert on unknown model keys. Selected pairs sage fill
  with a check, while disabled rows retain readable paper contrast and an
  explicit reason badge.

## Deviations

- **The first implementation uses script-composed Controls rather than moving
  every composition into `.tscn` immediately.** Existing screens and tests are
  script-built. Converting layout and interaction in place removes the urgent
  usability failures with a smaller diff; extracting stable compositions to
  scenes remains a cleanup step rather than a prerequisite for usable UI.
- **A compatibility bridge remains in `WyrdUi`.** Its public style helpers now
  resolve to Field Journal paper/moss styles and the readable type scale, so
  peripheral overlays move coherently in this pass. Obsolete Maple/Enamel asset
  constants and drawing helpers are not deleted until every obscure route has
  deterministic capture coverage.

## Tradeoffs

- **Theme/components before page fidelity.** Rebuilding the foundation delays
  the first full-page replacement but avoids another round of page-local colors,
  sizes, scrims, and hitboxes that drift as soon as the next skin is introduced.
- **Generated references bind rules, not pixels.** This gives up exact painted
  bevel/ornament fidelity in exchange for responsive layouts, real focusable
  Controls, and screens that work without bespoke art for every item or Chart.
- **Field Journal over Enamel Night.** Enamel Night offered strong contrast but
  carried heroic-fantasy MMO weight and depended on layered bevels, gold
  pinstripes, crests, and medallions. Field Journal better serves the humble
  working Trade, while semantic dark control surfaces still solve dungeon HUD
  contrast.

## Surprises

- **The worst contrast failure is deterministic.** `WyrdUi.INK` was changed to
  warm cream for the Enamel Night skin, while `panel_stylebox()` now resolves to
  the pale Maple panel whenever those assets exist. `PARCHMENT := INK` compounds
  the error, producing cream/gold text on cream paper across live screens.
- **The UI is already a large parallel framework.** Approximately 8.8k lines of
  UI code build screens mostly in scripts; `inventory_panel.gd` is about 1.2k
  lines of custom drawing/hitboxes and `chart_table_view.gd` about 0.8k lines of
  fixed-coordinate layout. Reskinning those files in place would preserve the
  causes of drift and inconsistent input.
- **The initial capture script exits too early on this machine.** The 700-frame
  town routes often exited before the two-second screenshot callback. Manual
  1000-frame captures succeeded. Slice 0 must make completion event-driven or
  otherwise deterministic rather than relying on an undersized frame count.
- **The Dialogue vertical slice did not need generated frame art.** A Walnut
  `PanelContainer`, two paper surfaces, one moss portrait well, and themed
  Buttons reproduce the important reference hierarchy with less ornament and
  substantially less code than the previous full-screen draw canvas.
- **Seeded interaction tests found defects that empty screenshots hid.** Pack
  item icons used a nonexistent Godot `Button.icon_max_width` property and one
  tooltip used unsupported `%+g` formatting. Both were repaired before the
  vertical slice was accepted.
- **The Chart Table was structurally healthier than its appearance suggested.**
  Its fixed Maple layout was too small and visually incoherent, but its socket,
  Codex, guest, staging, and focus contracts already preserved the right
  behavior. A visual/semantic migration was safer than replacing the adapter.
- **Several painted transaction cards were mouse-only Controls.** Vendor and
  Charm rows are now Buttons, and Loadout retains drag/drop while adding press
  and controller paths for assign, clear, and quick-item pinning.
- **Live capture can be invalidated by unrelated domain edits after UI tests
  pass.** During the Journal-row work, concurrent campaign and web-smoke edits
  briefly left `game.gd` between matching revisions, so the Game autoload could
  not compile for Town captures. UI work did not patch those unrelated seams;
  it used a no-autoload component harness meanwhile, then reran the real boot,
  Pack, and transaction contracts after the domain edits became consistent.

## Followups

- Decide Pack ownership for Charts and Trades during the screen-map slice.
- Decide whether the Pack's character region uses a live SubViewport, the
  existing player representation, or a deliberate silhouette after measuring
  performance and appearance parity.
- Painted portrait/icon/biome art can receive a separate asset pass after the
  layouts prove they do not depend on it.
- Extract the now-stable transaction and menu compositions into `.tscn` scenes
  after route parity, without changing their public shell and node contracts.
- Delete dormant Maple/Enamel constants and unused painted-kit files only after
  the final capture manifest proves no hidden route still references them.

## Implemented evidence

- `docs/ui-refs/redesign/slice1-contrast-after-board.jpg`
- `docs/ui-refs/redesign/slice2-dialog-live.png`
- `docs/ui-refs/redesign/slice3-hud-live.png`
- `docs/ui-refs/redesign/slice4-pack-board.jpg`
- `docs/ui-refs/redesign/slice5-chart-table-live.png`
- `docs/ui-refs/redesign/slice6-transactions-live.jpg`
- `docs/ui-refs/redesign/slice7-title-live.png`
- `docs/ui-refs/redesign/hero-waystone-field-journal.png`
- `docs/ui-refs/redesign/slice8-waystone-empty-live.png`
- `docs/ui-refs/redesign/slice8-waystone-live.png`
- `docs/ui-refs/redesign/slice9-chart-table-layout-live.png`
- `docs/ui-refs/redesign/slice10-chart-table-mix-live.png`
- `docs/ui-refs/redesign/component-lab-journal-list-row-v2.png`
- `docs/ui-refs/redesign/slice14-pack-journal-rows-live.png`
- `docs/ui-refs/redesign/slice14-vendor-journal-rows-live.png`

Automated contracts:

- `test_ui_theme_contract.gd`
- `test_ui_modal_and_icon_contract.gd`
- `test_ui_hud_and_pack_contract.gd`
- `test_ui_transaction_contract.gd`
- `test_chart_table_ui.gd`
- `test_journal_list_row.gd`

## Layout-correction pass — 2026-07-17

The first themed Waystone and Chart Table captures still preserved the old
composition: oversized unused parchment at the Waystone and three equally
weighted generic boxes at the table. This pass treats the generated reference
as a layout contract, not merely a palette reference.

- The Waystone now has two authored compositions. An empty Chart Case collapses
  to a compact illustrated note with a route back to Mara; a populated Case is
  an asymmetric 360px master list plus a larger travel folio with route sketch,
  Affix reading, difficulty, return estimate, and anchored traversal action.
- The Chart Table is now one light working page within a restrained walnut
  perimeter. Its columns are intentionally unequal (300 / 480 / 320): the
  physical chart surface receives the most room, while the preview gains a
  route sketch and explicit Base / Waymark / Ink requirements.
- The screenshot route now has deterministic `waystone_empty` and `waystone`
  states, so both compositions can be compared at the 1366×768 target.

The Ink Mixing tab is also a full authored state now. The old implementation
left the Chart grid and preview visible while squeezing Quill's pot into the
bottom of the supply column. `bench_mix` now captures a dedicated composition:
an Ink Makings pantry, illustrated copper-pot workspace with stateful actions,
and an Ink Notes folio that reveals only learned measures. Chart Controls remain
alive for state preservation and tests but are hidden while the mixing verb is
active; controller focus and footer instructions change with the verb.

## Painterly asset pilot — 2026-07-17

Research is captured in
`docs/research/godot-painterly-ui-asset-pipeline.md`. The key correction is to
build a small Theme-owned raster kit: `StyleBoxTexture` nine-slices for scalable
furniture, native `Button` text/focus behavior, and tightly cropped painted
icons/ornaments. Full painted screenshots are not runtime backgrounds.

The first vertical pilot now includes sixteen generated transparent Field
Journal icons, a journal-frame nine-slice, and a moss primary-button nine-slice.
The Chart Table loads painted supply icons through semantic row data, uses the
painted copper pot as its central illustration, adds a restrained leaf masthead
mark, and obtains the outer frame and primary-button plates from Theme type
variations. The original semantic Controls and focus pointer remain intact.

Research also found that older 443–554px kit assets were commonly reduced to
40–96px while mipmaps remained off. New sources remain lossless with alpha-edge
fixing; mipmaps should be enabled selectively only after an actual-size A/B
capture demonstrates a benefit.

### Shared journal-shell migration

The generated journal frame is now a Theme-owned nine-slice for both `Panel`
and `PanelContainer` roots (`JournalFrame` and `JournalFrameContainer`). This
keeps the illustrated oak/parchment chrome reusable without replacing native
Containers or interactive Controls.

The Chart Table, Pack, lower-third Dialogue, and Vendor transaction shell now
share that frame language. Pack and Dialogue retain their inner semantic paper
and moss surfaces; Vendor retains its painted, focusable item rows. The live
1366×768 comparison is captured in
`docs/ui-refs/redesign/slice12-painted-journal-shells-live.jpg`.

The migration deliberately stops at top-level furniture. Repeating the ornate
frame around rows, slots, or prose cards would flatten hierarchy and contradict
the approved rule that ornament belongs on the outer frame and masthead.

Tara's architecture review confirmed the next high-leverage seam: deepen the
Theme into a complete painterly skin before adding more page-local art. The next
asset/component slice should cover quiet/secondary and tab states, item/socket
wells, list-row states, tooltip, and focus overlay; Pack is the proving screen,
then the shared transaction family and HUD. Chart's approved composition stays,
but its remaining locally constructed `StyleBoxFlat` state styling should move
behind Theme variations as those components land.

The first part of that state kit is now live. A second ImageGen atlas supplied a
selected sage tab, quiet parchment plate, item/socket well, and leaf focus
pointer. `TabButton` uses the painterly selected plate, and the shared
`UiFocusPointer` now draws the leaf asset for every screen that owns the focus
overlay. The actual-size Pack proof is
`docs/ui-refs/redesign/slice13-pack-painted-statekit-live.png`; it retains the
3px focus ring so keyboard focus still has both color and shape cues.

## Transaction workbench correction — 2026-07-18

The first Cookfire, Forge, and Charm Table migration proved the painterly Theme
and `JournalListRow`, but failed the composition target. It produced coherent
*skinned developer menus*: full records repeated as stacked rows inside one
large parchment page. The generated oak frame carried most of the art direction
while the station itself had no focal object or spatial transformation.

Tara's capture review and the user's rejection establish a stronger contract:

- A transaction screen must embody a physical workbench, not render two arrays.
- The approved Chart Table's dark walnut mat and distinct paper leaves are the
  composition reference. The earlier all-parchment transaction shell is not.
- Cook/Smith use a compact 34% recipe rail and a 66% work surface. The work
  surface owns the selected result hero, ingredient `need / have` wells,
  station transformation emblem, outcome/XP stamp, reserved failure line, and
  one anchored 56px primary action.
- Enchant uses a three-zone gear rail, binding surface, and charm library. The
  accepted live ratio is 26/39/35 so charm effects remain readable without
  surrendering the central item-and-socket focal.
  Bound state is represented by visible sockets around the selected equipment;
  effect prose, reagent cost, and failure reason live on the binding surface.
- `JournalListRow` remains navigation for compact rails only. Full ingredient
  equations, descriptions, repeated action verbs, and repeated XP/error badges
  are removed from list rows.
- Raw Satchel/reagent sentences and the full-width Hearth loadout button are
  removed. Relevant resources become icon wells or compact header chips;
  secondary links move to the footer strip.
- Each station gets one semantic focal illustration and restrained identity:
  copper pot/steam for Cook, anvil/ember strike for Smith, selected item/sockets
  for Enchant. Ornament does not repeat around every row.

The new ImageGen composition target is
`docs/ui-refs/redesign/charm-table-three-zone-target-v1.png`. It is an
implementation reference, not a runtime background. The six production charm
icons were generated as a chroma-key atlas, converted to transparent PNGs, and
saved under `wyrd/assets/ui/icons/charm_<id>.png`; the live panel continues to
use native Controls and loads these by convention.

The interim captures are retained as negative evidence for why the workbench
correction is necessary:

- `docs/ui-refs/redesign/slice15-cook-interim.png`
- `docs/ui-refs/redesign/slice15-smith-interim.png`
- `docs/ui-refs/redesign/slice15-enchant-interim.png`

A deterministic harness now exists at
`wyrd/tools/capture_transaction_ui.gd`, avoiding unrelated Town/model-import
failures during transaction visual QA.

### Cookfire and Forge workbench proof — 2026-07-19

The rejected full-record recipe list has been replaced by a reusable
`TransactionWorkbench`: an oak journal frame around a walnut structural mat,
dark-surface header/footer, and asymmetric paper leaves. Cookfire and Forge now
share a 34% compact recipe rail and 66% selected-work surface while retaining
their existing `Game.craft()` mutation boundary.

The work surface owns the selected result hero, descriptive consequence,
ingredient `Have / Need` wells, station focal medallion, result well, XP, exact
locked/short reason, and one stable 56px primary action. Recipe rows are now
navigation only: icon, meaningful class/effect subtitle, and one availability
mark. The raw Satchel serialization and dominant Hearth loadout button were
removed; `Change skills` is a quiet footer link.

Tara reviewed the first live workbench capture and required removal of three
competing green conclusion bands, larger non-button station focal art, complete
five-row clipping, explicit counts, simplified state marks, and station-aware
subtitles. Those corrections are in the final evidence:

- `docs/ui-refs/redesign/slice16-cook-workbench-live.png`
- `docs/ui-refs/redesign/slice16-forge-workbench-live.png`

ImageGen supplied production focal/result art rather than runtime screenshot
backgrounds. Sources and alpha-cleaned assets are versioned under
`wyrd/assets/ui/field_journal/icons/`: `anvil_v1`, `bogiron_bar_v1`, and
`copper_bar_v1`. The ingots were added to `GatherData.ICON_TEX`, making the
shared material icon authority—not the Forge screen—their owner.

New reusable seams:

- `scripts/ui/components/transaction_workbench.gd` owns shell/header/body/footer.
- `scripts/ui/components/ingredient_well.gd` owns icon/glyph fallback,
  Have/Need presentation, and non-color shortage text.
- `JournalListRow` gained an explicit compact density for navigation rails;
  standard/detail rows retain their existing 68/84px contracts.

### Charm Table binding altar — 2026-07-19

Enchant now composes the shared `TransactionWorkbench` as a purpose-built
26/39/35 altar: compact equipped-gear rail, central binding surface, and wider
known-charm library. The selected item is a large, lightly framed hero beside a
vertical socket stack. Each `CharmSocket` is one focusable horizontal Control:
a 52px icon well plus external bound/empty state copy. Bound sockets invoke the
existing free `Game.unbind_enchant()` path. Charm rows select/preview only;
effect prose, exact reagent costs/reasons, and the sole bind action live on the
binding surface. Reagents use horizontal `Have / Need` strips rather than
ornate squares, so cost cannot be mistaken for a third socket.

This intentionally diverges from the transaction spec's generic
master-detail wording while preserving its source → consequence → requirement
→ action story. It follows the approved three-zone ImageGen target and Tara's
review: bound charms are no longer a second list above bindable charms.

The generated six-charm atlas is now visible in the real UI through
`assets/ui/icons/charm_<id>.png`; missing future art still falls back to a
semantic glyph. `CharmSocketButton` is a Theme variation and
`scripts/ui/components/charm_socket.gd` owns its semantic Control behavior.

Tara's final live-capture gate found no remaining composition blockers after
four corrections: item dominance, external socket labels, the wider charm
library, and horizontal reagent cost. Larger bespoke gear paintings, faint
binding runes, and slightly stronger secondary cost text remain polish rather
than prerequisites for migrating the next screen.

`test_ui_transaction_contract.gd` now proves the 26/39/35 anatomy, 108px-plus
item focal, readable horizontal sockets, wide reagent strip, dominant action,
real bind transaction, interactive bound socket, and real draw-out
transaction. The deterministic live evidence is
`docs/ui-refs/redesign/slice17-enchant-binding-altar-live.png`.

### Quill's apothecary counter — 2026-07-19

Quill's Still now uses the shared painterly workbench as a 35/65 shelf and
counter rather than forcing its old custom-drawn fallback shop. Three
`JournalListRow` wares remain visible and selectable even when the purchase is
blocked; selection opens a large painted item focal, authored use, ownership,
level gate, and exact gold consequence. Only the 56px Buy action is disabled,
and it preserves focus after a purchase so repeat buying does not jump back to
the shelf.

This deliberately changes the legacy one-click row purchase into
select → inspect → buy. Tara accepted the extra step because the counter now
shows information the row could not: full use, ownership, gate, price, gold
remaining, and exact shortfall. The open paper beneath the hero is intentional
breathing room, not a slot for decorative filler. The deterministic capture is
`docs/ui-refs/redesign/slice18-quill-apothecary-live.png`.

### Field Bar loadout editor — 2026-07-19

Loadout now uses a 42/58 Field Bar and Library workbench instead of one blank
paper sheet with five glossy circles. F, slots 2–4, and Q are 68px semantic
horizontal `LoadoutSlot` Controls with stamped key plates, painted icon wells,
full titles, one effect/state line, and written Fixed/Open/Clear/Pinned status.
`LoadoutChoiceRow` extends the shared journal row with a drag payload, so the
quick-use and learned-Skill library no longer draws tiny cards by hand.

The transaction family normally anchors a dominant action, but Loadout is an
intentional exception: `Game.set_loadout()` applies each change immediately.
The old Done plate and a first-pass ornate Close Book plate were both removed;
header ×, Esc/B, and the quiet footer own exit. Mouse drag remains available,
while keyboard and controller Y now carry an occupied Skill and Enter/A places
or swaps it. Click/Enter assigns the first open slot and refuses to silently
replace anything when all three are full.

The deterministic populated capture is
`docs/ui-refs/redesign/slice19-loadout-field-bar-live.png`. Contract coverage
proves the 42/58 anatomy, five slot Controls, semantic library rows, first-open
assignment, Q pinning, and both keyboard and controller carry/swap paths.

### Waystone crossing folio — 2026-07-19

The populated Waystone now shares the workbench as a 36/64 Chart Case and
Crossing Folio. Chart sources are semantic journal rows with Tier, Den Level,
difficulty, and mark count; row focus remains in the Case for fast comparison.
The Crossing keeps route identity, difficulty, affix prose, an inked procedural
route, persistent consumption warning, estimated return, and the sole 64px
`Step Through` action aligned with the exact selected Chart.

Maximum-affix pressure is handled horizontally: only the 45% affix region
scrolls while the 55% route sketch, consumption warning, return, and action
remain fixed. The route drawing remains non-interactive decoration, but was
reworked from rigid debug geometry into a smaller sepia path with waymarks,
stamped trees, nodes, and a standing-stone rune.

The empty state intentionally remains a compact 780×420 workbench instead of
expanding into the populated shell. Its focal is the finished painted Chart
Case asset, and its single action truthfully closes the Waystone rather than
claiming to route the player to Mara. Deterministic evidence:

- `docs/ui-refs/redesign/slice20-waystone-crossing-live.png`
- `docs/ui-refs/redesign/slice20-waystone-affixed-live.png`
- `docs/ui-refs/redesign/slice20-waystone-empty-live.png`

Contract coverage now proves empty and populated anatomy, two-Chart identity
selection, retained comparison focus, side-by-side affix/route composition,
fixed destructive warning, and the single crossing action.

### Wayweaver Mastery ritual — 2026-07-19

The live Mastery surface is `mastery_panel.gd`, not the dormant future
multi-perk choice modal. Its former 900×650 single paper column clipped the
destination, Root Rune state, and primary action below 768p and presented the
one-time legendary work as an administrative checklist.

Tara's domain/UI review found that the test fixture combined two production
states that cannot coexist. Before Wayweaver is owned, the station is a
three-leaf ceremonial transaction: **The Offering → The Masterwork → The
Keeping**. The three exact physical pieces show Held/Need and a terracotta
`SPENDS` seal; story and Rune witnesses remain a separately scrollable kept
ledger; Wayweaver art and result prose dominate the center; Keep/Equip are
radio-card choices; the readiness consequence and sole 64px Forge action stay
fixed in the right leaf.

After Wayweaver is owned, the same shell becomes a tending page rather than an
impossible disabled forge. Obsolete components, placement choices, and Forge
action disappear. The page instead shows the kept witness ledger, Wayweaver in
the player's keeping, and six authored Root Rune icons in a 3×2 binding grid.
Rune binding remains an immediate Game-authoritative cosmetic transaction and
states explicitly that it changes strand color/motes only.

The selected destination now uses the shared sage row state plus a check, and
the Theme explicitly keeps journal-row focus/hover text dark on pale selected
paper. `test_wayweaver_station_ui.gd` now has separate pre-owned Forge and
post-owned tending fixtures, asserts the shared 650px-safe workbench anatomy,
and rejects the invalid combined state. Deterministic routes are `mastery` and
`mastery_tending` in `tools/capture_transaction_ui.gd`.

Per-destination readiness remains a follow-up domain seam: Game currently
reports whether either Keep or Equip is possible. A future preview contract
should report the exact reason/consequence for each destination independently;
the UI still re-queries authoritative state immediately before commit.

Tara's final visual gate found no blocking composition, readability, or
domain-truth issue. The accepted deterministic evidence is:

- `docs/ui-refs/redesign/slice21-mastery-forge-live.png`
- `docs/ui-refs/redesign/slice21-mastery-tending-live.png`

### Startup fit and compact system folio — 2026-07-19

The painted title hero remains the startup art direction; its failure was the
lower action plate, which grew downward from 54% of the viewport and clipped
Quit at 1280×720. Journey actions now remain full-width while Co-op, Options,
Credits, and Quit form a 2×2 secondary grid. The plate grows upward from a 20px
bottom gutter, so both fresh and saved-game variants keep every 48px action
visible without covering the wordmark.

System pages intentionally do not reuse the large three-leaf transaction
workbench. `scripts/ui/components/system_folio.gd` owns a compact painterly
journal frame, walnut header/footer, one oat-paper task leaf, title/subtitle,
48px close, and footer hint. It emits close intent while each page retains its
existing pause, Settings, NetGame, and scene-change authority.

Pause is the 440×460 compact variant (510px with Abandon Run): Resume is the
sole primary action; Options is a quiet paper row; Quit/Abandon are neutral
paper rows with terracotta text. Options is a 600×500 standard variant with a
visible walnut/sage volume track, numeric percentage, semantic CheckBoxes, and
written Muted/Playing and On/Off state. Shared `SystemCheckBox` Theme colors
prevent the former white-focused-text-on-paper failure. Closing nested Options
preserves Pause and its offline pause ownership.

`test_ui_system_contract.gd` proves the 1280×720 safe gutter, 48px target floor,
initial focus, nested one-layer unwind, themed setting controls, and pause
retention. `tools/capture_system_ui.gd` provides direct Pause, Options, Lantern,
and Credits routes independent of Town model imports.

Tara's visual gate found one safety issue in the first saved-game capture:
Begin a New Journey still owned default focus above a valid Continue action.
Saved games now focus Continue and do not pulse the new-game action; fresh
games focus and gently emphasize Begin. Accepted evidence:

- `docs/ui-refs/redesign/slice22-title-fresh-live.png`
- `docs/ui-refs/redesign/slice22-title-continue-live.png`
- `docs/ui-refs/redesign/slice22-pause-live.png`
- `docs/ui-refs/redesign/slice22-options-live.png`

### Lantern network folio — 2026-07-19

The Lantern now uses the stable 760×540 system folio rather than a 640×600
blank form. Offline mode separates **Light a Fire**, the alternative Join row,
and **Fresh Page** with rules and semantic weight: Host is the sole moss
primary, Join is quiet, the address is a light paper inset, and New Game is a
terracotta destructive row isolated from networking. Its first press arms the
existing confirmation in place and uses the stable notice region for the exact
Charts/Trades/Satchel/gear consequence.

Active mode replaces every offline/reset action with the live roster,
host-address copy surface, and Leave Party warning. Offline copy explicitly
says the road rests while the player chooses because Game pauses non-network
modals; active copy says the world keeps breathing because co-op modal
accounting deliberately does not pause simulation. Tara required that truth
correction after the first live capture.

The system contract covers empty-address error/focus, two-press reset arming,
exact modal ownership, active roster/share/leave replacement, and the offline
paused versus active unpaused distinction. Accepted visual evidence:

- `docs/ui-refs/redesign/slice23-lantern-offline-live.png`
- `docs/ui-refs/redesign/slice23-lantern-reset-armed-live.png`
- `docs/ui-refs/redesign/slice22-pause-dungeon-live.png`

### Credits reader — 2026-07-19

Credits no longer replaces the painted title composition with a viewport-sized
cream field. It opens as a 680×610 `SystemFolio` over the dimmed title art, so
the game keeps its strongest startup atmosphere while the bounded oat-paper
reader owns legibility. Authorship, tool attributions, and the closing thank-you
are grouped with separators and a restrained terracotta game title rather than
forming one undifferentiated list.

The reader is a vertical `ScrollContainer`: the current exact attribution fits
at 1280×720, while later contributors can be added without pushing Back below
the safe gutter. The footer provides the same focused 52px Back action and
Esc/B hint as the rest of the system family. `test_ui_system_contract.gd`
proves the shared shell, safe geometry, scroll anatomy, exact attribution
strings, focus, target size, and close behavior.

Tara's blocker-only visual/UX gate passed the title-art composition,
hierarchy, readability, attribution clarity, safe geometry, and close
affordances. Accepted evidence:

- `docs/ui-refs/redesign/slice24-credits-reader-live.png`

### Shrine blessing choice — 2026-07-19

The live dungeon Shrine chooser was the highest-impact remaining peripheral:
its three offers were custom-drawn mouse-only Controls with 13px prose, no
icons, no focus state, and no shared Field Journal furniture. It now composes
the same painterly journal/walnut/paper folio as the compact system family, but
intentionally hides and removes focus from Close. Praying remains a one-way
commitment: Esc is consumed and only one of the three semantic Button cards
releases the Game modal.

Each card now gives the blessing itself the visual focal position, then the
authored name, exact mechanical consequence, and `LASTS THIS DELVE` duration.
The first visible offer owns initial focus, the shared leaf pointer and focus
ring make controller/keyboard position explicit, and every target is 270×310.
`test_ui_peripheral_contract.gd` proves the 1280×720 safe gutter, three-card
anatomy, icon/effect content, initial focus, no false close, cancel blocking,
untouched descriptor emission, and exact modal acquisition/release.

ChatGPT ImageGen's built-in image tool produced one versioned 5×2 chroma-key
source atlas from the existing Field Journal icon atlas style reference. Local
matte removal and deterministic cropping yielded ten transparent 256px assets
under `assets/ui/field_journal/icons/shrine/`, one for every Shrine buff ID.
The generation prompt specified the strict reading-order subjects, warm-brown
storybook contour, walnut/oat/moss/terracotta/moonlit-blue palette, equal cell
padding, 72px legibility, and flat `#ff00ff` removable background; it prohibited
text, borders, watermarks, reflections, and cross-cell shadows.

Tara's blocker-only gate passed the hierarchy, icon/card integration, focus,
consequence and duration wording, safe fit, and commitment affordance. Accepted
evidence:

- `docs/ui-refs/redesign/slice25-shrine-blessing-live.png`

### Storybook vignette caption — 2026-07-19

The reusable onboarding micro-cutscene keeps its live borrowed camera, authored
frame interpolation, skip guard, and exact Game modal lifecycle. Its former UI
was an orphan black letterbox: the sentence sat in a plain 54px bar and the
required skip instruction was only 13px, below the UI Bible caption floor.

The lower bar is now a compact painterly journal-and-walnut caption rail. A
gold story glyph leads the 19px dialogue sentence; a separate right-hand `SKIP`
eyebrow and 16px `Space / Esc` instruction keep the control readable without
competing with the vignette. The rail occupies only the lower world edge and
remains 24px inside the 1280×720 safe area. A restrained 28px walnut top matte
preserves cinematic framing without adding another paper slab.

`test_ui_peripheral_contract.gd` proves named anatomy, safe placement, type
floors, authored caption, and modal/camera release. The existing 134-check
transition suite independently proves that the restyle leaves the production
camera and play-state lifecycle intact. Tara passed the world-first composition,
scene visibility, hierarchy, and safe placement. Accepted evidence:

- `docs/ui-refs/redesign/slice26-story-caption-live.png`

### Knot-Eater road naming — 2026-07-19

The final Unwritten Road naming ritual was the last reachable full modal still
using the legacy parchment helper. It now reuses the generic
`ChoiceCardButton` furniture introduced by the Shrine, proving that the visual
system is a reusable commitment pattern rather than a one-screen skin.

The folio presents **Lantern Path**, **Mended Way**, and **Open Footpath** as
equal 248×280 choices with existing painterly Waystone, cord, and signpost art,
short authored flavor, and an explicit `COSMETIC NAME` consequence. The stable
notice says only the fire-keeper may choose and that all three are cosmetic.
There is no close action; Esc remains consumed; the first road owns focus; only
the Encounter controller can accept a name and release the modal. A versioned
Lantern Path icon copy trims a stray pixel-line from the shared source without
altering the original asset used elsewhere.

`test_road_naming_panel.gd` now has seven production checks covering the three
exact IDs, shared painterly anatomy, art, initial focus, blocking behavior,
retry copy, and exact modal balance. Tara's blocker-only gate passed the Field
Journal match, equal cosmetic communication, commitment affordance, focus, and
safe fit. Accepted evidence:

- `docs/ui-refs/redesign/slice27-road-naming-live.png`

### Final orphan-skin and type-floor audit — 2026-07-19

The reachable surface matrix now has accepted evidence for Startup, System,
HUD, Pack, Dialogue, Chart Table, every current Transaction workstation, and
the live Peripheral commitment/caption rituals. The only full modal still on
legacy helpers is `mastery_choice_panel.gd`; its own contract documents that it
is dormant because current 1–23 Trade ladders contain no multi-perk choice
tier. It remains a future migration trigger, not reachable player UI.

A repository-wide script audit found five explicit sub-14px overrides in live
compact components. Skill fallback names, Charm socket title/status, Enchant
reagent name/count, and loading-screen Affix badges now meet the UI Bible's
14px minimum. Their HUD/Pack, modal/icon, transaction, Map ritual, and boot
suites all remain green. Remaining compatibility-helper calls are confined to
already accepted HUD/title/vendor compositions or the dormant mastery-choice
panel; there is no remaining reachable legacy full-screen orphan.
