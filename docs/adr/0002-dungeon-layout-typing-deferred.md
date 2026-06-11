# DungeonLayout typing deferred

The `improve-codebase-architecture` review on 2026-05-26 (candidate #7) proposed replacing the Dictionary returned by `DungeonGen.generate()` with a typed `DungeonLayout` RefCounted (~10 typed properties: `grid`, `rooms`, `entry`, `exit`, `boss_room`, `decor`, `room_depths`, `room_edges`, `seed`, `score`). We deferred — the deletion test on a hypothetical `DungeonLayout` doesn't surface hidden complexity, it just keeps the dict contract implicit. Pure clarity deepening with zero behaviour change isn't worth the migration cost while the dict has a single consumer (`layout_loader._ready`).

## Considered options

- **Type the layout now.** Rejected — one consumer = hypothetical seam; the dict shape already works and every existing field becomes a typed property a future field would have to chase the dict-to-class translation.
- **Partial: type just `Room` (the most-nested + most-accessed structure).** Rejected — half the work for a third of the clarity; doesn't address the outer contract.
- **Defer entirely.** Accepted — the dict works, and the trigger to revisit is well-defined (a second consumer of layouts appears).

## When to revisit

Re-open this decision when:
- A second consumer of `DungeonGen.generate()` lands (dungeon editor, multiplayer state sync, layout serialization to/from disk for testing).
- A new field is added that has a complex shape (nested dict, optional dict) and the dict-key contract becomes harder to keep straight than a typed property would be.
- The eval harness needs to assert on layout properties more heavily than today.
