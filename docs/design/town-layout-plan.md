# Bramblewood Village — town layout plan

> Reorganize the village hub so it reads as a coherent place instead of
> a scatter of NPCs around an unmarked spawn. Map size 60×30; town
> footprint ~30×16; wilderness fills the rest. Sources: Stardew Valley
> Pelican Town breakdown (ConcernedApe interviews), OSRS Lumbridge
> wiki, RuneScape Varrock layout principles, "Hades' House of the Dead"
> design notes (Supergiant), Christopher Alexander's *A Pattern
> Language* (sections "Small Public Squares" and "Activity Pockets").

## Current state — scatter, not layout

What's in `map.txt` today:
- Spawn (X) at (15, 15) on plain grass
- Maud's stone hut at (3-9, 4-8) — the **only** drawn building
- Path (P) running east at row 13
- Trees scattered in the eastern wolds
- Cows + goblins outside the village (cleaned up earlier)

What's placed via JS constants in `main.js` but **not drawn on the map**:

| NPC / structure | Tile | Offset from spawn |
|---|---|---|
| Chartmaker stone | (18, 14) | +3 east, 1 north |
| Hod (smith) | (19, 16) | +4 east, 1 south |
| Quill (herbalist) | (13, 19) | -2 west, 4 south |
| Sir Withering | (14, 10) | -1 west, 5 north |
| Mirror | (13, 15) | -2 west |
| Practice stump | (17, 16) | +2 east, 1 south |
| Practice ore | (21, 17) | +6 east, 2 south |
| Practice dummy | (21, 16) | +6 east, 1 south |

Three problems:
1. **Maud is isolated** at 10 tiles NW with no path connection
2. **NPCs cluster too close** — Hod and the Chartmaker are 3 tiles apart, no logic to their adjacency
3. **No buildings drawn** for any NPC except Maud — the other NPCs are floating mesh-on-grass

## Design goals

In priority order:

1. **Spawn = the visual center.** Player lands at a recognizable place (village green / market square) and sees landmarks in every cardinal direction.
2. **Critical-path NPCs visible from spawn.** Maud (first quest) + Chartmaker (first dungeon) should be a single look-and-walk away. No hunting.
3. **Functional grouping.** Cooking + smithing share fire. Herbalist + cartographer share quiet workshop space. Knight + falcon at the edge of town facing the wilderness.
4. **Clear boundary.** A hedge or fence ring marks where village ends. Players know "I am leaving safety" when they cross.
5. **Wilderness pull east.** Goblins live east; the village should funnel the player that way for combat encounters.

## The proposed layout

```
   ╔═══════════════════════════════════════════════════════════════════╗
   ║                       T  T  T  T  T  T  T  T  T  T              ║   <- north hedgerow / treeline
   ║                                                                   ║
   ║         ╔═══════╗                                                 ║
   ║         ║Cloister║   ╔══════════╗                                 ║   row 4-7
   ║         ║Pell+   ║   ║ Withering║                                 ║
   ║         ║Onywyn  ║   ║  Perch   ║       (open meadow / forage)    ║
   ║         ╚═══════╝   ╚══════════╝                                 ║
   ║              \         /                                          ║
   ║               \       /  (path)                                   ║
   ║                \     /                                            ║
   ║      ╔═══════╗  \   /  ╔═══════════╗                              ║   row 10-12
   ║      ║Quill's║   \ /   ║   Maud    ║                              ║
   ║      ║ Garden║----+----║  Pennycress║                              ║
   ║      ║  Hut  ║   /|\   ║  + Fire   ║                              ║
   ║      ╚═══════╝  / | \  ╚═══════════╝                              ║
   ║                /  |  \                                            ║
   ║   - - - - - - +-VILLAGE GREEN - - - - - - - PPPPPPPPP - - - >wolds║   row 13 path east
   ║              /    X    \                                          ║
   ║             /  (spawn)  \                                         ║
   ║      ╔═════/════╗        \   ╔═══════════╗  ╔══════╗              ║   row 16-18
   ║      ║  Hod's   ║         \  ║Chartmaker ║  ║Eldra ║              ║
   ║      ║  Forge   ║          \ ║   Stone   ║  ║ Lamp ║              ║
   ║      ║ + Anvil  ║           \║           ║  ║Wright║              ║
   ║      ╚══════════╝            ╚═══════════╝  ╚══════╝              ║
   ║          + practice stump    + practice ore                       ║
   ║          + practice dummy                                         ║
   ║                                                                   ║
   ║                                                                   ║   row 22+
   ║                ::::::: hedgerow boundary :::::::                  ║   <- village edge
   ║                                                                   ║
   ║              cricket loft (above cooperage)                       ║
   ║                                                                   ║
   ║                  southern hedge / cow pasture                     ║
   ║                                                                   ║
   ╚═══════════════════════════════════════════════════════════════════╝
```

Same idea cleaned to coords:

| Slot | Coords | What |
|---|---|---|
| Spawn (X) | (15, 15) | unchanged — village green at the center |
| Maud's hut + fire | (16-22, 10-13) | **moved south-east** from (3-9, 4-8) so it's adjacent to spawn |
| Hod's forge | (8-13, 17-19) | **southwest** of spawn, fence to spawn via path |
| Quill's herbalist hut | (6-9, 11-13) | **west** of spawn — quiet quarter |
| Withering's perch | (11-14, 5-8) | **NW** at higher elevation feel |
| Cloister (Pell + Onywyn) | (3-7, 4-7) | **far NW** — sanctuary on the ridge |
| Eldra's lamp-wright | (24-26, 17-19) | **SE** — quiet artisan |
| Cricket's cooperage loft | (4-6, 22-23) | **far south** — utility building, unobtrusive |
| Chartmaker stone | (18, 14) | unchanged — already well-placed |
| Practice yard | (16-22, 16-18) | unchanged cluster south of spawn |

## What gets drawn vs. left to JS

**On the map (map.txt) — drawn buildings:**
- Maud's hut + fire (already drawn, just relocate)
- Hod's forge + anvil
- Quill's herbalist hut
- Withering's perch (small platform)
- Cloister (Pell + Onywyn share)
- Eldra's lamp-wright shop
- Cricket's cooperage

**Roads (P tiles)**:
- Spine: continue the existing east-west path at row 13 (already there)
- Spurs: short paths from the spine to each building's door

**Boundary**:
- Northern hedgerow (T tiles, line of trees) at row 2-3
- Southern hedgerow at row 23-24
- Eastern boundary opens to the wolds (no hedge — that's the combat exit)
- Western edge fades to forest (existing T scatter)

## Critical-path walk for a new player

After this layout, a brand-new player's first 10 minutes:

1. Spawn at the village green
2. Look NORTH → see Withering's perch (silhouette of a knight) + cloister behind
3. Look EAST → see Chartmaker stone glowing + path leading to wolds
4. Look NW → see Maud's hut adjacent (was hidden 10 tiles away before)
5. Look SW → see Hod's forge with smoke
6. Walk to Maud, accept first quest (Tutorial step 6 fires)
7. Walk back, walk EAST 3 tiles to chartmaker, mix ink
8. Walk EAST along the path → into the wolds → fight goblins

The current scatter has none of this read.

## What I'm NOT proposing

- **No new buildings/NPCs.** Just relocating + drawing what's already in the JS placement table.
- **No expansion beyond 60×30.** The map size stays.
- **No procedural town gen.** Hand-authored, tile-by-tile.
- **No replacing the existing structure system.** The S/F tile codes for stone wall + floor stay; we just lay them out per the plan.

## How the change actually lands

1. **Edit `map.txt`** to draw the 7 buildings + roads + hedgerows
2. **Update the TILE constants in `main.js`** to point at the new coordinates of each NPC (table above)
3. **Verify**: spawn the world, walk a quick orientation pass, ensure pathfinding still works (no NPC tile inside a wall)

Estimated cost: 1.5 hours. Most of it is map.txt rework — buildings need to be wall-floor patterns matching the existing Maud's hut style. Tile-constant updates are 10 lines.

## Open questions for sign-off

1. **Tone — should the town feel cozy or hardy?** Current sketch leans cozy (lots of buildings, narrow paths, dense). An alternative is hardier (fewer buildings, more open green, NPCs as outdoor workers). Tradeoff: cozy feels like Stardew, hardy feels like OSRS Lumbridge.
2. **Maud's hut relocation.** She's been at the NW corner the whole project. Do players have an emotional anchor there? If yes, KEEP her there and adjust the rest of the layout around it instead.
3. **Cloister visibility.** Do Pell and Onywyn need to be visible from spawn, or are they intentionally tucked away as discoverables?
4. **Eastern gate.** Should there be a literal stone arch at the village's east edge, or just the path opening into the wolds?

Sign-off on those, and I lay out the new map.txt + retune the constants.
