---
type: entity
tags: [npcs, town, characters, bramblewood, dialogue]
status: draft
updated: 2026-06-13
sources:
  - docs/WORLD_BIBLE.md
  - docs/wyrd-guide.md
  - docs/quest-items-models.md
  - wyrd/scripts/wayfinder_npc.gd
  - wyrd/scripts/vendor_npc.gd
  - wyrd/scripts/quill_npc.gd
  - wyrd/scripts/town.gd
  - wyrd/scripts/ui/vendor_panel.gd
---

# NPCs

The three live NPCs in the Chartmaker's Yard — Mara Linnet, Old Hod Tenter, and Quill the Herbalist — each anchor a corner of [[Bramblewood]]'s economy and serve as the player's tutorial guides for their respective Trade loops.

## Mara Linnet, the Wayfinder

**Role:** Tutorial anchor and chart-craft mentor. **Location:** Center-north of the yard, facing the player spawn (pos 20, 17 on the 40×40 grid). **Interact:** E — opens a dialog modal.

Mara walks the player through their first chart from step 0 to step 6: gather herbs → mix hedge ink → inscribe a Snug → socket at the Waystone → run it → debrief on the Tier 1 loop. Her dialog pages key off `Game.tutorial_step`; once the Summit has been cleared she switches to a permanent congratulatory set.

**Voice example** (from `wayfinder_npc.gd`): *"New boots. Good — the yard could use a pair."* / *"The fiercer things — the marked ones, with the glow about them — carry thorn essence."*

She uses `wanderer_v3.glb`, normalized to 1.7 m. Her dialog color is a warm amber-gold (Color 0.95, 0.85, 0.6). She is not a vendor — interaction is dialog only.

> ⚠️ `docs/WORLD_BIBLE.md` does not name a "Mara Linnet" — the Bible names the original NPC roster (Maud Pennycress, Old Hod Tenter, Sir Withering of Trelliswick) but the Wayfinder character was added for the Godot slice. Code is canonical: her name is Mara Linnet (class `WayfinderNpc`, `wyrd/scripts/wayfinder_npc.gd`).

## Old Hod Tenter, the Smith

**Role:** Buy/sell vendor — gold economy faucet and convenience ink shelf. **Location:** Just south of the forge, east side of the yard (FORGE_POS − 1.5 m west, + 3 m south). **Interact:** E — opens Hod's Counter, a two-column panel (sell left, buy right).

**Selling:** The player clicks any gear item in their pack to sell it. Hod "melts it down." Sell prices by rarity (from `wyrd/data/economy.gd`):

| Rarity | Gold |
|---|---|
| Normal | 4g |
| Magic | 12g |
| Rare | 35g |
| Unique | 90g |

**Buying (Hod's wares):** Six items at a convenience-tax markup (gathering is always the better deal):

| Material | Price |
|---|---|
| Wild Herb | 3g |
| Logs | 4g |
| Bogiron Ore | 7g |
| Hedge Ink | 12g |
| Stoneground Ink | 18g |
| Refined Ink | 38g |

Boss trophies are never sold — the trophy chain passes only through the hollows.

**Voice example** (from `vendor_panel.gd`): *"Sparks like to find sleeves. Mind the anvil, state your business."*

He uses `npc_hod_v3.glb`, normalized to 1.72 m (his in-lore height, from the prototype's `npcs.js`). His prompt color is forge-warm (Color 0.95, 0.8, 0.5).

Hod also operates **the anvil** beside the forge (a `CraftStation` node, station id `"forge"`) where players smelt ores into bars and craft trade tools. See [[The Crafting Bench]] and [[Trades and Leveling]].

The World Bible entry on Hod: *"Was a soldier somewhere once; doesn't talk about it. Will smith bronze gear for you for cheap because he's lonely."*

## Quill, the Herbalist

**Role:** Dialog NPC and still operator — brews tonics (buffs) rather than food (heals). **Location:** South-west herb corner of the yard (pos 11, 29.5); her still is just beside her (pos 13, 30.5). **Interact:** E — opens a dialog modal. The still is a separate `CraftStation` (station id `"still"`).

Quill's still produces **sharpening tonics** (buffs) as opposed to the cottage cookfire which produces **healing draughts**. Her dialog distinguishes this clearly: *"The hearth feeds you; my still sharpens you."*

Her tonic shelf includes (from `wyrd/data/gather.gd`):
- **Quickroot Tonic** — gathering channels run 25% faster for a duration.
- **Clearwater Philter** — Focus pools 50% faster.
- **Crowsfoot Cordial** — move speed +10% for a duration.
- **Mothmint Mend** — HP regenerates while walking.
- **Stonebreak Tonic** — incoming damage reduced for a duration.

A bittergrass patch sits beside her still (locked until Wildcraft 3), marking her corner as the visible goal for players leveling [[Wildcraft]].

**Voice example** (from `quill_npc.gd`): *"Mind the beds — the yellow-tipped ones are nearly ready."* / *"They keep a week if you don't shake them too hard."*

She uses `npc_quill_v2.glb`, normalized to 1.62 m (her in-lore height). Her prompt color is herb-green (Color 0.72, 0.88, 0.6).

> ⚠️ Quill is not named in `docs/WORLD_BIBLE.md` (which was locked before the Godot slice). Code (`quill_npc.gd`) and the prototype's `npcs.js` are the source of truth for her name and role. The Bible's naming rules (plain English + hedge/herb surnames) are consistent with "Quill."

## Named NPCs not yet in the game

The World Bible locks two further characters for future addition:

- **Maud Pennycress** — village matron, runs the dairy and the cottage cookfire. Currently the cookfire is a `CraftStation` without an NPC keeper. The quest *The Harvest Picnic* (deliver three cooked brindle beef) is hers. `docs/quest-items-models.md` lists a **pantry_stew** model for her follow-up quest.
- **Sir Withering of Trelliswick** — eccentric retired knight at Trelliswick Folly. Will teach Falconry. Quest items planned: `falcon's_whistle`, `whickerhares_foot`, `thorn_crown` (boss drop). Not yet implemented.

## Town stations (non-NPC interactables)

The yard also contains station interactables the player uses without a keeper NPC:
- **Inscribing Table** — chart crafting (Mara stands beside it, but the table is its own `Interactable`). See [[The Crafting Bench]].
- **Portal Waystone** — socket a chart and step through. See [[The Waystone]].
- **Cookfire** — station id `"cookfire"`, beside the cottage door. Future home of Maud.
- **Well** — decorative (visual only in current build).
- **Signpost** — decorative.

## See also

- [[Bramblewood]] — the village and its named locations
- [[Chart Loop]] — the full loop Mara teaches
- [[Economy]] — Hod's gold faucet and the buy/sell prices
- [[Gathering]] — materials that feed Quill's still
- [[Wildcraft]] — Trade gating Quill's deeper herbs
- [[Earthcraft]] — Trade gating Hod's deeper ores
- [[The Crafting Bench]] — Hod's anvil and the cookfire recipes
- [[The Waystone]] — what Mara directs the player to use
- [[Items and Gear]] — gear sold to Hod

## Sources

- `docs/WORLD_BIBLE.md` — character Bible (Maud, Hod, Sir Withering, naming rules)
- `wyrd/scripts/wayfinder_npc.gd` — Mara's dialog tree, tutorial step logic
- `wyrd/scripts/vendor_npc.gd` — Hod's vendor scaffold, heights, prompts
- `wyrd/scripts/quill_npc.gd` — Quill's dialog, her GLB, herb-corner lore
- `wyrd/scripts/town.gd` — all NPC positions in the yard, station wiring
- `wyrd/scripts/ui/vendor_panel.gd` — Hod's counter UI, wares list, sell logic
- `wyrd/data/economy.gd` — sell-by-rarity and WARES definitions
- `docs/quest-items-models.md` — quest item model briefs per NPC quest
- `docs/wyrd-guide.md` — Hod's gold section and NPC mentions
