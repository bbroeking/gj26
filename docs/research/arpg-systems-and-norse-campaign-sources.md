# ARPG systems and Norse campaign source research

**Research date:** 2026-07-17  
**Purpose:** source patterns for a future Wayfinder design pass. This is a pattern
library, not a commitment to ship every system.

**Design outputs:** [ADR 0016 — Four Trades, each level 1–23](../adr/0016-four-trades-level-23.md),
[ADR 0017 — A local Norse-inspired Root Saga may extend below Bramblewood](../adr/0017-local-norse-root-saga.md),
and [Spec 56 — Full-game ARPG systems, level-23 Trades, and the Root Saga](../specs/56-full-game-arpg-saga.md).

## Executive synthesis

The strongest pattern across the official ARPG sources is:

> repeatable run → visible progress or key parts → authored boss → targeted
> reward/permanent unlock → a new, higher-risk run

That structure gives procedural maps a narrative job without asking random
generation to tell the whole story. For Wayfinder, ordinary **Charts** should
sustain gathering, crafting, and loot; completed Charts should also advance a
visible saga track. Milestones unlock authored **Memory Charts**; their bosses
drop named parts that inscribe a **Boss Chart**; the boss grants a permanent
world change and one component of the chase legendary.

The Norse sources support a story about a damaged living order, fate recorded
at roots, physically dangerous revenants, rival elder powers, catastrophe, and
renewal. They do **not** require importing Odin, Thor, nine explorable realms,
or an apocalypse plot. The best fit is a small Bramblewood story whose deeper
roots echo Yggdrasil and Ragnarök while the village remains the emotional scale.

## Source caveat: there is no single Norse canon

The most useful medieval witnesses here are *Völuspá* in the Poetic Edda,
Snorri Sturluson's *Gylfaginning*, and *Grettis saga*. Anthony Faulkes's
academic edition warns that Snorri systematized a body of conflicting
traditions, wrote from a Christian intellectual setting, and sometimes
expanded or altered his material. Treat contradictions as permission to create
an original Bramblewood mythology, not as gaps to force into a franchise-style
canon. [Viking Society edition of *Edda: Prologue and
Gylfaginning*](https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf),
especially the introduction at pp. xxv–xxviii.

## ARPG system families worth considering

| System family | What successful ARPGs use it for | Primary/first-party evidence | Wayfinder implication |
|---|---|---|---|
| **Run combat** | Movement, a repeatable basic action, limited-resource abilities, defenses, statuses, elite modifiers, and readable boss telegraphs create the second-to-second test. | Blizzard's developers explicitly revised opaque boss consequences to improve readability in the [Diablo IV 2.2 patch notes](https://news.blizzard.com/en-us/article/24196854/diablo-iv-patch-notes-2-2). | Keep the Bow as the clear free verb; introduce the small ability loadout gradually; every boss attack needs a tell, arena language, and status explanation. Mystery belongs in lore, not damage rules. |
| **Character and ability growth** | ARPGs separate broad character power from active-skill customization. Skills may unlock over time, specialize individually, and catch up after experimentation. | Last Epoch documents [skill specialization](https://support.lastepoch.com/hc/en-us/articles/46363203944859-Skill-Specialization) and several [skill-unlock sources](https://support.lastepoch.com/hc/en-us/articles/46363194853915-Unlocking-Skills); Path of Exile makes active and support gems itemized systems on its [official game overview](https://www.pathofexile.com/game). | A 1–23 progression needs meaningful milestones, not 22 copies of `+5%`. Unlock active Skills in layers through rank, story, buildings, discoveries, and boss runes. Use modifier runes to change delivery (chain, cone, echo, companion trigger) without creating dozens of redundant buttons. |
| **Itemization** | Readable equipment bases, rarity, affixes, named drops, uniques, sockets/modifiers, and build-changing effects make loot comparable and memorable. | Grim Dawn's official [loot guide](https://www.grimdawn.com/guide/items/the-hunt-for-loot/) distinguishes common bases, affixed items, monster-specific items, Epics/Legendaries, sets, and item-granted skills. | Give rarity tiers distinct jobs. Bosses and elite families should preview at least one identifiable material, base, cosmetic, or rune. Reserve the capstone legendary for a rule-changing identity, not simply the largest number. |
| **Target farming** | Specific monsters and bosses own identifiable pools, turning content choice into an item plan. | Grim Dawn assigns Monster Infrequents and unique equipment to specific enemies in its [monster guide](https://www.grimdawn.com/guide/gameplay/monsters/); Diablo IV Lair Bosses expose keys and targeted Unique pools in Blizzard's [Lair Boss rework](https://news.blizzard.com/en-us/article/24179278/the-2-2-0-ptr-what-you-need-to-know). | The Chart preview should show likely signature rewards. A desired item should imply which biome, creature family, and boss to pursue. |
| **Crafting and salvage** | Controlled improvement makes a usable item achievable, while drop-only ceilings preserve discovery. Salvage turns failed drops into planned progress. | Last Epoch documents [affix tiers](https://support.lastepoch.com/hc/en-us/articles/46361996533147-Affixes), [Forging Potential](https://support.lastepoch.com/hc/en-us/articles/46361900702363-What-is-Forging-Potential), and transformative [Runes and Glyphs](https://support.lastepoch.com/hc/en-us/articles/46361877750043-Runes-and-Glyphs). | Start with four legible verbs: salvage, reinforce, reroll one affix, and inscribe. Let the best raw properties come from dangerous Charts, while a player can reliably craft a competent baseline. |
| **Legendary assembly** | A chase item is strongest when authored identity combines with player-selected provenance and multiple useful intermediate goals. | Last Epoch's [Legendary Items](https://support.lastepoch.com/hc/en-us/articles/46361924310555-Legendary-Items) fuse a Unique and an Exalted item after a keyed dungeon. Grim Dawn's [crafting guide](https://www.grimdawn.com/guide/items/crafting/) uses permanently learned blueprints and nested recipes. | Require a named relic base, a perfected player-made item, and a specific Boss Chart completion. Each intermediate component should already be useful or visible in the village. Duplicate boss relics should convert into deterministic progress rather than become dead drops. |
| **Map/key progression** | An itemized run key names a location, difficulty, modifiers, and rewards; successful runs tend to sustain or raise access. | Path of Exile's official overview says Maps are endgame items with challenge/reward mods ([game overview](https://www.pathofexile.com/game)). Diablo IV's Nightmare Sigils name a dungeon, add modifiers and rarity, and lead to stronger sigils ([developer update](https://news.blizzard.com/en-us/article/23827587/developer-update-closed-end-game-beta-draws-near)). | Every Chart should communicate biome, rank, affixes, danger band, reward bias, and story contribution before entry. Completion should normally yield material toward an equal-or-higher-rank Chart. |
| **Branching run graph and meta-progression** | A web of selectable runs gives repetition direction; milestone encounters and permanent bonuses punctuate it. | Last Epoch's [Monolith of Fate](https://support.lastepoch.com/hc/en-us/articles/46361839099931-What-is-the-Monolith-of-Fate) uses selectable Echoes, Stability thresholds, authored Quest Echoes, timeline bosses, guaranteed boss-pool items, and permanent Blessings. Path of Exile exposes content specialization through the [Atlas passive tree](https://www.pathofexile.com/forum/view-thread/3229978). | Let random Charts fill a visible root/saga track. Add a small Wayfinding constellation that biases future Charts toward preferred biomes, encounters, materials, or fragment types. Keep it much smaller than Path of Exile's Atlas. |
| **Boss-map assembly and ladders** | Sub-bosses and ordinary maps provide named pieces; combining them opens pinnacle fights with exclusive rewards and permanent world progression. | Path of Exile's official Atlas explanation describes Guardian fragments combining to open Shaper/Uber Elder encounters ([Conquerors of the Atlas](https://www.pathofexile.com/forum/view-thread/2679460)). Diablo IV groups Lair Bosses into visible tiers with named keys and reward pools ([Lair Boss rework](https://news.blizzard.com/en-us/article/24179278/the-2-2-0-ptr-what-you-need-to-know)). | Use a short, visible chain: three named Knot fragments → one Boss Chart → a permanent World Rune plus legendary component. Show owned/required fragments on the boss icon and avoid an opaque, purely random summon grind. |
| **Difficulty and risk/reward** | Difficulty tiers, optional run corruption/modifiers, density changes, and capstone gates let the player opt into danger for explicit benefit. | Last Epoch's [Corruption system](https://support.lastepoch.com/hc/en-us/articles/46361874426523-Shade-of-Orobyss-and-Corruption) raises danger and several reward measures and can be reduced. Grim Dawn's [difficulty modes](https://www.grimdawn.com/guide/game-settings/game-difficulties/) alter strength, density, champion frequency, and loot. | Preserve the existing player-versus-den level read, but let advanced Charts add optional depth with a line-by-line danger/reward preview. Higher difficulty should change composition, density, and mechanics—not HP alone—and should be reversible. |
| **Special challenge modes** | Keyed dungeons, arenas/waves, bounties, world events, and optional high-stakes modes keep endgame from collapsing into one activity. | Last Epoch lists Monolith, Arena, and endgame Dungeons on its [official site](https://lastepoch.com/); its [Dungeons guide](https://support.lastepoch.com/hc/en-us/articles/46363322070683-What-are-Dungeons) gives each dungeon a unique mechanic, boss, and end service. Grim Dawn's [exploration guide](https://www.grimdawn.com/guide/gameplay/exploration/) describes sealed, variable challenge dungeons entered with a consumed key. | Do not ship all modes at once. First add one special Chart whose defining rule ends in a unique village/crafting service. Reserve loss-heavy “Oath Charts” for optional play; ordinary Charts should keep the cozy failure model. |
| **Settlement, economy, and services** | Vendors, storage, crafting specialists, respec, transmutation, appearance, factions, and building unlocks turn town into visible progression. | Grim Dawn ties blacksmith recruitment to crafting and differentiates smith bonuses in its [crafting guide](https://www.grimdawn.com/guide/items/crafting/); [service NPCs](https://www.grimdawn.com/guide/gameplay/service-npcs/) cover storage, respec, transmutation, and appearance. | Each repaired Bramblewood building should unlock one clear verb, then gain visible tiers. Candidate functions: Charting Hall, Smithy, Rune Loom, Apothecary, Archive, Hunter's Lodge, and Hall of Oaths—but names must be reconciled with the World Bible before canonizing them. |
| **Enemy ecology and escalation** | Repeat encounters introduce elite variants, family-specific rewards, and rare nemesis-level threats without requiring a new biome every time. | Grim Dawn's [faction system](https://www.grimdawn.com/guide/character/factions/) escalates hostile factions toward more heroes and Nemesis bosses. | A creature family's “Saga Threat” can add champions, altered behaviors, and eventually a named legendary beast to eligible Charts. Keep escalation family-local rather than inventing an ever-worse cosmic faction. |
| **Reward clarity and collection UX** | Loot filters, storage, codices, guaranteed milestones, item compare, recipes, and completion trackers become core systems as content grows. | Grim Dawn explicitly emphasizes reduced junk, exploration rewards, one-time Epic chests, and filtering in its [loot guide](https://www.grimdawn.com/guide/items/the-hunt-for-loot/). | Build icon coverage, filters, source hints, boss-fragment tracking, recipe discovery, and legendary-project progress alongside the items—not after the catalog becomes unmanageable. |

## Norse motifs: what the sources actually give us

| Motif | Source-grounded reading | Original Bramblewood use |
|---|---|---|
| **World tree and roots** | *Völuspá* places Yggdrasil above Urðr's well; *Gylfaginning* gives it roots, wells, beings that damage it, and norns that tend it. The tree is a living order under continual strain, not merely a portal menu. [*Völuspá* 19–20](https://www.heimskringla.no/wiki/Volusp%C3%A1_%28JJA%29); [*Gylfaginning*, Viking Society edition](https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf). | Treat the Chart network as glimpses of one root system under the Wolds. Different biomes are conditions of the roots—flooded, frostbound, hollow, ember-scarred—not literal Norse realms. Completed story Charts mend or understand one local wound. |
| **Norns and fate** | *Völuspá* presents three knowledgeable maidens at the tree who establish laws and shape human lives/destinies. It does not require the modern “three witches weaving everyone's thread” visual cliché. [*Völuspá* 20](https://www.heimskringla.no/wiki/Volusp%C3%A1_%28JJA%29). | Use three recurring functions—what was recorded, what is being tended, and what is now owed—for clues and boss-key parts. Keep the actual figures indirect: root marks, marginal handwriting, three tools, or three village stories. |
| **Jötnar** | The sources do not support a single species of disposable ice giants. In *Gylfaginning*, Skaði is a jötunn's daughter, negotiates with the gods, marries Njörðr, and takes her place among them. [*Gylfaginning* chs. 23–24](https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf). | Reimagine jötunn influence as old, person-like powers of landscape and appetite. Some oppose the village, some bargain, some can be quieted. A boss can be a keeper with incompatible obligations, not an evil race member. |
| **Draugr/revenant** | Glámr in *Grettis saga* is a location-bound, physically overwhelming revenant: he damages a farm, kills livestock, wrestles Grettir, speaks, and leaves a lasting curse. [*Grettis saga*, chs. 32–35, Viking Society translation](https://vsnr.org/wp-content/uploads/2021/11/Outlaws.pdf). | A draugr-like boss belongs to a particular barrow, failed promise, and household memory. Its map affix can distort sight or lighting; defeating it resolves an obligation or relocates remains instead of simply killing “an undead.” |
| **Ragnarök** | *Völuspá* moves through breakdown and death but then sees the earth rise green again; Faulkes summarizes *Gylfaginning* as destruction followed by world renewal. [*Völuspá* 43–58](https://heimskringla.no/wiki/Volusp%C3%A5_%28Moderne_nynorsk%29); [*Edda* introduction](https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf). | Use Ragnarök's shape—warnings, broken bonds, winter/fire, loss, green return—at village scale. The climax should be choosing what Bramblewood tends through the next Quickening, not preventing the end of the universe. |
| **Knowledge bought at a cost** | The Eddic material repeatedly links wisdom to wells, ordeal, prophecy, and incomplete knowledge; even Snorri's frame is a question-and-answer contest that ends with the hall vanishing. [Faulkes's introduction to *Gylfaginning*](https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf). | Every major Chart clue should cost a commitment: consume rare ink, accept an affix, spare a reward, or carry a mark into later runs. The player authors the conditions under which knowledge appears. |

## Design implications for Wayfinder

1. **Use a two-layer narrative.** Random Charts carry clues, recurring symbols,
   and materials. Authored Memory/Boss Charts carry irreversible story beats.
   This keeps procgen replayable while preserving pacing and characterization.
2. **Make boss access legible and partly deterministic.** Three named fragments
   are easier to understand than a hidden percentage. Guarantee first-story
   fragments through explicit milestones; allow target farming for repeats.
3. **Let every boss advance four tracks at once:** story knowledge, a permanent
   world/Chart modifier, a settlement unlock, and a legendary component. One
   boss should not demand four separate grinds.
4. **Make the legendary a village project.** Its components should involve
   gathering, smithing/crafting, inscription, and boss trophies. Display the
   unfinished object in a building so progress is spatial and emotional, not
   only a checklist.
5. **Keep the Norse layer allusive.** Borrow structures and tensions from the
   Eddas and sagas; keep Bramblewood's names, neighbors, humor, and small scale.
   Do not cast recognizable gods, recreate God of War's family conflict, or turn
   the Wolds into a nine-realm theme park.
6. **Protect the cozy spine.** ARPG systems are seasoning under ADR 0003.
   Combat loot should feed the gather/craft/chart loop, while the fastest
   reliable power still comes from playing the whole village game.
7. **Ship the progression kernel before breadth:** Chart preview → completion
   saga progress → one Memory Chart → three visible fragments → one Boss Chart
   → one targeted reward/world change. Prove this loop before adding seasons,
   factions, arenas, or multiple challenge modes.

## Canon/decision conflicts resolved by the design outputs

- The locked `docs/WORLD_BIBLE.md` says Bramblewood is intimate, low-stakes,
  does not escalate past the Hedgemother, and avoids multi-page mythology.
  [ADR 0017](../adr/0017-local-norse-root-saga.md) now permits a **local
  root-cycle** while preserving the warm voice and village-scale stakes.
- ADR 0012 defines **one levelable Trade, Wayfinding**, while project language
  reserves **Skill** for hotbar abilities. [ADR 0016](../adr/0016-four-trades-level-23.md)
  now supersedes it with four independently leveled Trades and keeps Skill for
  hotbar actions.
- ADR 0006/0012 cap progression at 17 for the demo. ADR 0016 raises the
  full-game cap to 23 and Spec 56 supplies the curve/milestone audit.
- ADR 0014 formalizes nine hotbar Skills and seven equipment slots. Spec 56
  preserves the seven equipment slots and three-pick loadout, stages the nine
  existing Skills across Huntcraft, and adds only three late-game verbs.

## Recommended source set for the narrative writer

- Snorri Sturluson, *Edda: Prologue and Gylfaginning*, ed. Anthony Faulkes,
  Viking Society for Northern Research:
  <https://vsnr.org/wp-content/uploads/2021/11/VSNR_Edda-1_prologue_gylfa.pdf>
- *Völuspá* (Old Norse with historical translation and notes), Heimskringla:
  <https://www.heimskringla.no/wiki/Volusp%C3%A1_%28JJA%29>
- *Grettis saga* in *Three Icelandic Outlaw Sagas*, Viking Society for Northern
  Research: <https://vsnr.org/wp-content/uploads/2021/11/Outlaws.pdf>
