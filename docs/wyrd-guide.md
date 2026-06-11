# Wayfinder — Game Guide

*(Formerly "Wyrd" — renamed 2026-06-10.) A cozy fairytale dungeon-crawler set in Bramblewood. You are a wayfinder:
you don't find dungeons — you **inscribe** them. Every chart you craft is a
promise the hollow may or may not keep.*

## Starting the game

```bash
godot --path /Users/bbroeking/projects/gj26/wyrd
```

You begin in **the Chartmaker's Yard** at the edge of Bramblewood. Mara
Linnet will walk you through your first chart — follow the quest scroll
at the top of the screen — it shows live progress (e.g. "2 / 3 herbs").
The parchment buttons bottom-right open your Pack (I) and Satchel (M).

## Controls

| Input | Action |
|---|---|
| **W A S D** / arrows | Move (camera-relative; always-run) |
| **Shift** (hold) | Walk |
| **Space** | Roll — dodge with invulnerability frames |
| **Ctrl** | Dash — fast reposition, no i-frames |
| **F** | Fire your bow (basic shot) |
| **1 – 4** | Skill hotbar (Basic Shot · Power Shot · Multi Shot · Bramble Snare) — skills 2-4 spend Focus |
| **E** | Interact — talk, gather, open, rest, pray, step through |
| **G** | Grab nearby loot |
| **I** | Open / close the inventory (Tetris grid — drag, rotate with R) |
| **M** | Open / close the satchel — materials, inks, trophies, chart case |
| **Z / C** | Rotate camera (or hold right-mouse and drag) |
| Mouse wheel | Zoom |
| **Esc** | Close any open panel |

## The loop

```
GATHER herbs in the yard (and ore/logs inside charts)
   ↓
MIX inks at the Inscribing Table
   ↓
INSCRIBE a chart — pick a template, slot inks, roll the affixes
   ↓
SOCKET it at the Waystone and step through
   ↓
RUN the dungeon the chart describes — fight, mine, forage, loot
   ↓
EXIT through the far waystone → Wayfinding XP → deeper templates unlock
```

A chart is **consumed when you cross**. Death inside doesn't refund it — you
respawn at the entrance (or the last hearth you rested at) and the run is
still yours to finish.

## Trades

Three disciplines level independently (readout at bottom-right):

| Trade | Levels from | Unlocks |
|---|---|---|
| **Wayfinding** (`carto`) | Completing chart runs: `tier×75 + good affixes×40 + bad twins×10` XP | Chart templates and affixes — the whole craft |
| **Earthcraft** (`earth`) | Mining ore rocks (10 XP) | (depth of the mining game — future) |
| **Wildcraft** (`wilds`) | Foraging (8 XP) and chopping log piles (12 XP) | (future) |

Even a botched roll teaches you something — bad twins still grant XP.

## Charts

### Templates

| Chart | Tier | Wayfinding req | Affix slots | Cost | Character |
|---|---|---|---|---|---|
| **Snug** | 1 | 1 | 0 | 1× hedge ink | A pocket cellar. Small, gentle, no surprises — every wayfinder's first. |
| **Tier 1 Hollow** | 1 | 1 | 1 | 2× hedge ink | Your first real roll of the dice. |
| **Hollow** | 2 | 10 | 2 | 3× hedge ink | Bigger rooms, richer runs. |
| **Briar Maze** | 2 | 15 | 2 | 3× hedge ink | Twisted — corridors over rooms, more loops to get lost in. |

### Inks (mixed at the Inscribing Table)

| Ink | Recipe | What it does when slotted |
|---|---|---|
| **Hedge Ink** | 3× wild herb | The everyday ink — doubles the odds of green affixes (Bramble Bloom, Herbal Patch, Wood Grove) |
| **Stoneground Ink** | 2× bogiron ore | Pulls the chart hard toward Mineral Vein (×2.5) |
| **Refined Ink** | 2× hedge ink + 1× bogiron ore | Biases nothing — adds +10% good-twin stability per pot |

Inks **tilt the odds — they don't promise.** The preview panel shows you the
live odds for every eligible affix before you commit.

### Affixes — the good/bad-twin gambit

Every affix slot rolls an affix, then **stability** decides which twin lands:
`stability = base + 0.6 per Wayfinding level + ink bonus` (capped 95% — the
hollow always keeps a sliver of say).

| Affix | Good twin | Bad twin |
|---|---|---|
| **Mineral Vein** (Lv 1) | 3–5 mineable ore rocks inside | *Barren* — no ore |
| **Bramble Bloom** (Lv 4) | 4–6 forage spawns | *Wilted* — nothing grows |
| **Tyrannical** (Lv 5) | Enemies +50% HP, +30% chart XP on completion | *Erratic* — every enemy rolls its own size and vigor |
| **Wood Grove** (Lv 7) | 3–5 log piles | *Stripped* — bare stumps |
| **Festival Pace** (Lv 7) | +50% enemy density | *Lockstep* — thin, quiet halls |
| **Herbal Patch** (Lv 14) | 6–9 herb spawns — the rich version of Bloom | *Frostbit* — nothing |

### Boss dens — the trophy slot

Boss dens **never roll at random**. You ink one in deliberately by slotting
its trophy at the Inscribing Table (the den affix is then guaranteed in one
slot — stability still decides whether the den is *occupied*):

| Trophy | Where it comes from | Den it inks (req) |
|---|---|---|
| **Thorn Essence** | Elites (the glowing, modified ones) drop it ~1 in 4 | **Hedgemother's Den** (Lv 8) |
| **Tusker Tusk** | The Hedgemother's hoard | **Burrow Boar's Wallow** (Lv 12) |
| **Wightpelt** | Snagged on the Burrow Boar's tusks | **Wolf Alpha's Roost** (Lv 14) |
| **Alpha's Fang** | The Wolf Alpha's jaw | **Chart of the Summit** (Lv 16) — the endgame |

That's the chain: *elites → Hedgemother → Boar → Wolf → the Summit.* Each
boss hits differently (the Boar heavy, the Wolf fast, the Queen hardest)
and each death drops the next key into your satchel.

## Hod's counter — gold

**Old Hod Tenter** trades at the forge on the yard's east side. He buys the
gear you haul out of charts (normal 4g · magic 12g · rare 35g · unique 90g —
he melts it down) and sells raw materials and inks at a convenience markup.
Gathering stays the better deal; Hod is for the night you're one pot of ink
short of a chart. Gold shows next to your trades, bottom-right.

## Inside a chart

- **Rooms have roles.** Watch for them: **vaults** hold a guarded chest,
  **shrines** offer a choice of three boons (one per shrine), and the
  **hearthroom** lets you rest — full heal *and* a checkpoint your death
  respawn will use.
- **Elites** travel with a retinue. Brambled ones bleed when they pop,
  Sunlit ones burn on hit, Swift ones close fast, Briarbound ones shrug off
  your snare. One per room at most.
- **The Hedgemother** (boss charts only): the arena seals when she wakes.
  She telegraphs everything — the red circles are honest. Roll out of them.
  Her death drops the gates, her loot, and raises the exit waystone.
- **Bossless charts**: the deepest room holds the exit waystone and a
  reward chest from the start.
- **Leaving**: step through the far waystone. That's when Wayfinding XP
  lands. Loot left on the floor stays on the floor.

## Death

You white out and wake at the dungeon entrance (or your last hearth) at
full HP. The chart is not refunded; the run is still completable. In town
you cannot die — Bramblewood wouldn't allow it.

## Developer corner

- **Dev chart run**: `WYRD_DEV_CHART=tier_1 godot --path wyrd` boots straight
  into a chart with all gather affixes good (seed 12345).
- **Screenshots**: `WYRD_SHOT=1` self-captures `/tmp/wyrd_town.png` (town) or
  `/tmp/godot_selfshot.png` (dungeon) a few seconds after load.
- **Headless tests**: `godot --headless --path wyrd --script res://test_wyrd_transitions.gd`
  (also `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`).
- **Design docs**: `docs/wyrd-slice.md` (decisions), `docs/wyrd-implementation-notes.md`
  (build record), `docs/cartography-keystone-design.md` (the full affix design space —
  what's coming), `CONTEXT.md` (domain language).

## Known edges

- Progress **saves automatically** (`user://wyrd_save.json` — delete it for a
  fresh start; an in-game New Game button is still to come).
- Gathering needs no tools and is instant.
- Combat grants no XP yet; Wayfinding is the spine.
- One dungeon *look* (crypt walls) regardless of scope — though the
  inhabitants now change per scope (imps crowd the Briar Maze, rats the Snug).
