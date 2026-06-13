---
type: entity
tags: [crafting-bench, inscribing, chart, ink, recipe-discovery, ui]
status: draft
updated: 2026-06-13
sources: ["docs/cartography-inscribing-table-design.md", "docs/specs/42-chart-crafting-ui.md", "docs/specs/42-chart-crafting-ui-notes.md", "docs/specs/43-recipe-discovery.md", "docs/specs/43-recipe-discovery-notes.md"]
---

# The Crafting Bench

The Crafting Bench (in-game: the Inscribing Table) is the single station in [[Bramblewood]] where a player inscribes [[Charts|charts]] — it combines the mixing pot (raw materials → [[Inks]]) and the inscription sockets (inks + chart base → chart) into one physical object at the Chartmaker's Stone.

## Physical layout

The bench UI has three panels (spec 42, `docs/specs/42-chart-crafting-ui.md`):

- **Left — satchel tray**: draggable rows for every ownable input. One row per unlocked chart base (shown as a rolled parchment with name + tier), one row per ink type (with count), one row per trophy. Locked templates show ghosted with their Wayfinder level gate. Zero-count rows hide to keep the tray compact.
- **Center — bench sockets**: one large **base socket**, up to three **ink sockets** (revealed only when the placed base has `affix_slots > 0`), and one **trophy socket** (revealed when the base supports it). Drag from the tray to a socket; click a socketed item to return it; invalid drops snap back.
- **Right — result slot**: once a base is placed, shows the chart name, tier, live odds bars per affix slot (drawn from `compute_weights` + `effective_stability`), the trophy guarantee line when a den trophy is slotted, and the full cost with have-counts. Clicking the result slot (or the Craft button) inscribes the chart straight to the chart case with a gold stamp animation.

The bench also contains a **mixing pot** sub-area for producing inks without leaving the station.

## The mixing pot

The mixing pot accepts raw materials dragged from the satchel tray. It operates as a running claims dict (materials stay in the satchel until mix). Two modes:

- **Auto-mix** (discovered recipes only): dropping the third ingredient of a known recipe immediately fires `mix_ink` and clears the pot.
- **"Try the Mix"** button (the risky verb, spec 43): for unknown recipe amounts. Results:
  - Exact match, undiscovered recipe → **discovery**: recipe learned, ink produced, +50 Wayfinder XP, gold bloom toast
  - Exact match, already discovered → normal auto-mix
  - No match → pot consumed (cheapest material returned as consolation); then 60% **smudge** (nothing), 30% **wild ink** (random common ink), 10% **serendipity** (bottle of an undiscovered ink item — recipe stays unknown)

Clicking a non-empty pot without a recipe match empties it. Ink pots can also be dropped into the pot (e.g., refined ink requires 2 hedge ink + 1 ore).

## Codex strip

Below the pot, a codex strip shows the discovery status of all ink recipes:

```
● Hedge Ink        — 3× wild herb (vertical)     [discovered]
◌ Stoneground Ink  — try earthen materials…       [hinted: Hod's dialogue]
◌ ???                                             [unknown]
```

Hinted lines only show their riddle after the corresponding first-time NPC hint has fired (gated by `seen_hints`). The codex carries the "what exists" knowledge for inks the player has run out of.

## Trophy socket and boss dens

When a chart base with `affix_slots > 0` is placed, the trophy socket is revealed. Dropping a boss trophy (e.g., `thorn_essence`) slots it; this guarantees that the `hedgemother_den` affix appears in one slot of the rolled chart. The trophy is consumed on craft. The stability roll still applies — the den can still resolve to the bad twin (Empty Throne). `TROPHY_TO_AFFIX` mapping lives in `wyrd/data/charts.gd`.

## Live odds preview

The result slot's odds bars update live as inks are socketed or removed. They display the normalized weight percentage for the most-likely affix per slot — not a guarantee, but the honest probability. This is the player's primary tool for deciding which inks to slot. Under the hood: `compute_weights(tier, ink_ids, carto_lv)` → normalize → display.

## Tutorial integration

The tutorial teaches the bench hands-on. Steps 2 and 3 (mix ink, inscribe Snug chart) use guided crafts: a pulsing gold ring highlights the target socket or pot area; other interactions are soft-locked. Mara's dialogue rewrites to placement language ("Set the Snug parchment on the bench. Now the ink — pour it into the round socket."). Tutorial triggers are unchanged in `wyrd/scripts/game.gd`.

## Implementation notes (spec 42 decisions)

- **Click-crafts, no drag-out** — clicking the result slot or Craft button inscribes immediately; charts go straight to the chart case with a stamp animation
- **Public bench API** (`place_base / socket_ink / socket_trophy / pot_add / craft / close`) mirrors what the mouse handlers do, enabling headless test driving
- **Tray rows are 26px compact** — the full list can overflow at 560px if template count grows beyond ~7; scroll/paging is a noted followup
- The old `inscribing_panel.gd` was deleted after parity; the bench replaced it entirely

## See also

- [[Charts]] — what the bench produces
- [[Inks]] — what the mixing pot produces; the affix bias each ink carries
- [[Affixes]] — the modifiers whose odds the result slot previews
- [[The Waystone]] — where a finished chart is consumed to enter a hollow
- [[Chart Loop]] — the full loop that the bench sits in the center of
- [[Wayfinding]] — the Trade that gates templates and ink recipes

## Sources

- `docs/cartography-inscribing-table-design.md`
- `docs/specs/42-chart-crafting-ui.md`
- `docs/specs/42-chart-crafting-ui-notes.md`
- `docs/specs/43-recipe-discovery.md`
- `docs/specs/43-recipe-discovery-notes.md`
