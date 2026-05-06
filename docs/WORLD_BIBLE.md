# Bramblewood — World Bible

**Status:** locked 2026-04-29.

The mechanical-bones game (chop/cook/fight/level) sits inside an original cozy
fairytale setting. This file is the source of truth for *names, vibe, who-is-
who*. Everything player-visible — quest copy, NPC names, item flavor, log
lines, location signs — flows from here. If a piece of writing doesn't match
this Bible, the writing changes, not the Bible.

## One-line pitch

> *"A storybook valley where the village's biggest problems are pie-thieving
> bramble-imps and the eccentric retired knight in the folly on the hill."*

## The world in three nested rings

```
World           → The Wolds (a long-forgotten enclosed forest valley)
Region          → Bramblewolds (the southern part of the Wolds)
Village         → Bramblewood (where the player lives)
```

The wider Wolds exist in flavor text and quest hooks but the game stays in
Bramblewood and a few day-walk locations. Don't world-build past this — the
intimacy is the point.

## Vibe & tone

- **Warm**, not gritty. **Whimsical**, not satirical.
- **Low stakes** by default; *occasional* moments of sincerity (a village
  funeral, a worried mother) earn their weight by contrast.
- **Storybook prose** in dialog — short sentences, soft humor, characters
  who repeat themselves the same way every time you talk to them.
- **No grimdark** — no graphic violence, no body horror, no swearing harder
  than "blast." Bramble-imp bites are described as "a nasty pinch."
- **Hayao Miyazaki + Beatrix Potter + Wind Waker.** That's the triangle.

The locked UI aesthetic (`docs/UI_BIBLE.md`) — cream paper, brown ink, sage
and terracotta watercolor washes — is the visual half of this tone. Keep
the writing matching the look.

## Player identity

- **Role:** the *new arrival* to Bramblewood. Walked in with a bag, no
  family in town, vague past. The character creator's name + appearance
  is the player.
- **Why you're here:** undefined on purpose. Players supply their own answer
  via roleplay. Hooks (quest copy, NPC dialog) hint without locking it.
- **Class flavor:** Adventurer. Generic on purpose — the player picks their
  identity through skills and clothes, not class selection.

## Cast — the named neighbors

The cook NPC at the stone hut becomes:

> **Maud Pennycress** — village matron. Runs the dairy and the only oven hot
> enough for a feast. Short, sharp, kind. Speaks in small sentences. *"Three
> cooked beef. Don't burn 'em. Off you go."*

The forge NPC (when added) becomes:

> **Old Hod Tenter** — the smith. Was a soldier somewhere once; doesn't talk
> about it. Will smith bronze gear for you for cheap because he's lonely.
> *"Hmph. Bring me ore. Bring me coin. Don't waste my fire."*

The retired knight at the castle (when added):

> **Sir Withering of Trelliswick** — built the folly tower himself, brick by
> brick, after retiring from "a war you've never heard of and I won't bore
> you with." Eccentric. Has a falcon. Will teach Falconry. *"Bird's name?
> Linnet. Don't startle her."*

The Mirror is left unnamed — it's a magic-but-not-explained heirloom in the
village square. Players who Look closer change their look.

## Antagonist — bramble-imps

- **What:** thorn-and-berry-colored sprites about knee-high, with too many
  fingers. Live in the hedgerow. Steal pies, eggs, jewelry — anything shiny
  or warm. Bite if cornered.
- **Threat level:** garden nuisance, not existential. The matron loses
  patience with them; the knight finds them entertaining. Once a year (the
  *Quickening*) they get bolder for a week. Most player combat is during a
  Quickening.
- **Why you fight them:** because Maud needs the dairy herd protected, not
  because they're evil. The game does NOT moralize the kill.
- **Future variation:** a hierarchy — *thorn-imp* (basic) → *bramble-cap*
  (mid) → *Hedgemother* (rare/quest boss). All from the same family.

The current `goblin.glb` is a thorn-imp; rename in display strings only.
The model itself stays.

## Locations — what already exists, what to add

| In the world | Bramblewood name |
|---|---|
| Cook's stone hut (NW) | **Maud's Dairy** |
| Cooking fire | **The matron's hearth** |
| Castle (N) | **Trelliswick Folly** |
| Forge (E) | **The Smithy** (Old Hod's) |
| Mirror (W) | **The Hedge Mirror** (no one knows where it came from) |
| Cow field (S-middle) | **Pennycress Pasture** |
| Goblin camp (SE) | **The Bramble-Hollow** |
| Trees (sparse) | **The Wolds proper** |
| Beach (SW) | **Sallow's End** (a tidal flat with one shipwreck, lore-rich) |
| Path (E–W) | **Old Wagon Road** |

To add in the village pass:
- **Coopers' Hold** — village storehouse (the "bank")
- **Old Mother Well** — village center
- **2–3 cottages** — empty for now, populated with NPCs later
- **Signposts** at trail junctions, hand-painted

## Quest reframe — current quest

Today: *"Slay 3 cows for the Duke's feast → reward Bronze Sword"*

Bramblewood version:

> **The Harvest Picnic** — Maud Pennycress needs three cooked beef for the
> village lunch tomorrow. The dairy cows are penned in the south pasture;
> bramble-imps have been agitating them. Bring three cooked beef to her
> door before sundown. She'll thank you with her late husband's bronze
> sword. *"He won't be needing it. You might."*

Same mechanics, soft sentimental hook.

## Naming rules

- **People:** plain English given names + hedge/herb/textile surnames
  (Pennycress, Tenter, Withering, Linnet, Sallow, Cooper, Quill, Bramble).
- **Places:** descriptive compound or possessive (Pennycress Pasture,
  Old Mother Well, Sallow's End, Trelliswick Folly, the Bramble-Hollow).
- **Skills:** keep generic English. *Cooking* not *Hearthcraft*;
  *Smithing* not *Ironworking*. Skills are unfussy verbs.
- **Enemies:** all bramble-imp family use thorn/berry/hedge words.

## Locked resource taxonomy (2026-04-29)

Bramblewood does **not** use OSRS metal/herb/animal names. Originals only.
Engine identifiers (kind: 'goblin' etc.) stay generic; display strings +
item IDs use this taxonomy.

### Metals & ores (6-tier ladder, original names)

| Tier | Ore | Bar | Old (OSRS) name |
|---|---|---|---|
| 1 | mosswort_ore + palechalk_ore | brindle_bar | copper + tin → bronze |
| 2 | bogiron_ore | bogiron_bar | iron |
| 3 | coalrose (+ bogiron_ore) | cinderbloom_bar | coal → steel |
| 4 | starsilver_ore | starsilver_bar | mithril |
| 5 | hedgesteel_ore | hedgesteel_bar | adamant |
| 6 | wildgold_ore | wildgold_bar | rune |

### Animals & meats

| Creature | Raw | Cooked | Burnt | Hide |
|---|---|---|---|---|
| Brindlecow | raw_brindle | brindle_roast (heal 5) | charred_brindle | wool_flank |
| Pippin | raw_pippin | pippin_spit (heal 4) | charred_pippin | downfeather |
| Whickerhare | raw_whicker | whicker_stew (heal 4) | charred_whicker | whicker_pelt |
| Tuskersnout | raw_tusker | tusker_crackling (heal 7) | charred_tusker | tusker_tusk |
| Hedgewight | raw_hedgewight | hedgewight_strip (heal 9) | charred_hedgewight | wightpelt |
| Bramble-imp | — | — | — | (no meat; drops hedge_ink) |

### Herbs & forage

| ID | Display | Old | Use |
|---|---|---|---|
| whitleberry | Whitleberry | wild_berry | foraging, +1 HP raw |
| hedgecap | Hedgecap | mushroom_red | foraging, brewing |
| wishrose | Wishrose | herb_basic | Quickening-ritual herb, alchemy |
| (future) bittergrass | Bittergrass | — | bitter tea brewing |
| (future) foxglove-blue | Foxglove-Blue | — | toxic alchemy reagent |
| (future) crowsfoot | Crowsfoot | — | common between stones |
| (future) mothmint | Mothmint | — | midnight bloomer |
| (future) stonebreak | Stonebreak | — | Mining XP boost when held |

## Anti-patterns — things this Bible *won't* do

- No multi-page mythology. Lumbridge's Duke and the Wars of the Wolds are
  hinted at, never spelled out.
- No save-the-world stakes. The biggest crisis is "Maud's pie tin is
  missing again."
- No pseudo-fantasy filler words (*Ahnaen, Gwynndor, the Verisaiye*). If
  it sounds like a generated name, throw it out.
- No grim flips later — Bramblewood doesn't have a "twist" where the imps
  are actually demons. They are exactly what they appear to be.

## Cross-references

- `docs/UI_BIBLE.md` — visual language; tone in the writing must match the
  cream-paper feel.
- `docs/ART_BIBLE.md` — 3D model style; characters here look like the cow,
  knight, goblin already in `models/`.
- `docs/ONBOARDING.md` — the OSRS Tutorial Island reference; will need to
  be re-flavored to "the new arrival's first day in Bramblewood" before it
  ships.
- `CLAUDE.md` — engineering spec; references this Bible for naming.
