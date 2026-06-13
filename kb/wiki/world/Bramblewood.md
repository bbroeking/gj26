---
type: world
tags: [setting, geography, factions, locations, npcs]
status: draft
updated: 2026-06-13
sources: ["docs/WORLD_BIBLE.md", "docs/WORLD_LORE.md", "CONTEXT.md"]
---

# Bramblewood

Bramblewood is the small hedge-trimmer's hamlet where the player lives — a single clearing carved from the Bramblewolds, surrounded by an ancient living hedge that resists taming but accepts tending.

## Geography

The world is structured in three nested rings (`docs/WORLD_BIBLE.md`):

```
World   → The Wolds (a long-forgotten enclosed forest valley)
Region  → Bramblewolds (the southern part of the Wolds)
Village → Bramblewood (where the player lives)
```

The wider Wolds exist in flavor text and quest hooks only. The game stays in Bramblewood and a handful of day-walk locations; the intimacy is intentional and must not be over-built.

## Founding

Bramblewood began as a hedge-cutters' hamlet. The first families arrived from Sallow's End three or four winters after the tide receded — hedge-cutters, a wool-comber, and one widowed cooper. They cleared a patch in the old enclosure, built nine cottages, dug Old Mother Well, and began *tending* the hedge rather than fighting it. The trimming continues every spring since (`docs/WORLD_LORE.md`).

## Locations

| Name | Notes |
|---|---|
| **Maud's Dairy** | Cook's stone hut (NW); the matron's hearth is the village oven |
| **Trelliswick Folly** | Castle (N); Sir Withering built it himself after retiring |
| **The Smithy** | Forge (E); Old Hod's, rarely welcoming |
| **The Hedge Mirror** | Village square (W); magic heirloom of unknown origin; lets players change appearance |
| **Pennycress Pasture** | Cow field (S-middle); bramble-imps agitate the herd here |
| **The Bramble-Hollow** | Goblin/imp camp (SE); the imps' territory |
| **Coopers' Hold** | Village storehouse and bank; run by the Cooper sisters |
| **Old Mother Well** | Village center; gathering point for festivals |
| **Old Wagon Road** | Main E–W path; six cottages visible from the bend (legends say seven) |
| **Sallow's End** | Tidal flat SW, three hours' walk; one shipwreck, lore-rich |
| **The Pale Veins** | Hod's ore quarries underground — delve scope (`docs/WORLD_LORE.md`) |
| **Hag's Furrow** | Wild hedge-line E; where Mother Onywyn forages; Cricket won't deliver there |

## Named Cast

**Maud Pennycress** — village matron, runs the dairy. Short, sharp, kind. The spine of village daily life. *"Three cooked beef. Don't burn 'em. Off you go."*

**Old Hod Tenter** — the smith, former soldier of a forgotten war. Lonely; will smith bronze gear cheap. *"Hmph. Bring me ore. Bring me coin. Don't waste my fire."*

**Sir Withering of Trelliswick** — retired knight, built the folly himself. Eccentric; owns a falcon named Linnet. Teaches Falconry. Veteran of a *named* war — quite different from Hod's *forgotten* one. The two men drink at the well on Pieday and do not speak of it.

**Mother Onywyn** — the current herb-tender, great-granddaughter of the Onywyn who bound herself into the bramble during the Hard Frost. Not malevolent; thinking very slowly. Her use of foxglove and wishrose without consulting Brother Pell's *Marked Pages* is an ongoing, politely unspoken tension.

**Brother Pell** — cloister keeper; maintains the *Marked Pages*, a two-century herb index. Exchanges weekly letters with Onywyn via Cricket; the letters are mostly about weather.

**Cricket** — the sixteen-year-old orphan letter-carrier, lives above the cooperage. Sir Withering taught him to read.

**Eldra** — keeps wicks burning during the Quickening; shares weekly tea with Maud.

**The Cooper Sisters (Marra and Wisp)** — run Coopers' Hold; first cousins of Maud's late husband. Maud deposits only coppers in protest of the bank fee.

**Quill** — raised partly at the smithy after Hod's wife Bramwen (Quill's aunt) passed; Hod is gentler with Quill than with anyone and pretends not to be.

## The Bramble-Imps

Thorn-and-berry-colored sprites, knee-high, with too many fingers. Live in the Bramble-Hollow. Steal pies, eggs, and shiny things; bite if cornered. Threat level: garden nuisance, not existential. A hierarchy exists: *thorn-imp* (basic) → *bramble-cap* (mid) → *Hedgemother* (rare/quest boss). The current `goblin.glb` model represents a thorn-imp; display strings use the Bramblewood names.

The [[Enemies]] page covers their combat stats; the [[World Lore]] page covers the Hedgemother's mythic identity.

## The Quickening

First week of First-Spring. The bramble-imps grow bolder — stealing, agitating cows, untying washing lines. Eldra burns extra wicks; Brother Pell rings the cloister bell at sundown for seven nights. Most player combat happens during or near a Quickening (`docs/WORLD_LORE.md`).

## Naming Rules

- **People:** plain English given names + hedge/herb/textile surnames (Pennycress, Tenter, Withering, Bramble, Sallow, Cooper, Quill).
- **Places:** descriptive compound or possessive (Pennycress Pasture, Old Mother Well, Sallow's End, Trelliswick Folly).
- **Skills:** unfussy generic verbs — *Cooking* not *Hearthcraft*; *Smithing* not *Ironworking*.
- **Enemies:** all bramble-imp family use thorn/berry/hedge words.
- **No pseudo-fantasy filler names** (*Ahnaen, Gwynndor*). If it sounds generated, throw it out.

## Resource Taxonomy (locked 2026-04-29)

Bramblewood does not use OSRS metal/herb/animal names. The six-tier ore ladder runs: mosswort/palechalk → bogiron → coalrose → starsilver → hedgesteel → wildgold. Creature names: Brindlecow, Pippin, Whickerhare, Tuskersnout, Hedgewight. Key forageables: Whitleberry, Hedgecap, Wishrose. Full table in `docs/WORLD_BIBLE.md`.

## See also

- [[World Lore]] — deeper lore, legends, calendar, NPC interconnections
- [[Voice and Tone]] — writing rules for player-visible text
- [[Gathering]] — GatherNode kinds and resource flow
- [[NPCs]] — per-NPC detail and schedules
- [[Enemies]] — bramble-imp family stats and hierarchy
- [[Chart Loop]] — the dungeon delve that starts at the Pale Veins

## Sources

- `docs/WORLD_BIBLE.md` — canonical setting, cast, locations, taxonomy
- `docs/WORLD_LORE.md` — deeper lore, legends, NPC interconnections, calendar
