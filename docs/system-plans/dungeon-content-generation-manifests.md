---
title: Dungeon Spatial and Content Manifests
domain: Wayfinding & Dungeons
type: system
status: planned
effort: L
tags: [wayfinder, procgen, encounters, gathering, loot]
---

# Dungeon spatial and content manifests

## Outcome

A Chart seed should freeze one complete, authoritative dungeon plan before the
loading screen appears: space, route, room semantics, creature packs, gathering
nodes, treasure sources, and deterministic reward rolls. The loading screen may
summarize that truth without exposing exact tactical spoilers. `LayoutLoader`
should instantiate a plan, not make a second set of generation decisions.

The current 2D review corpus is exported by
`wyrd/tools/export_dungeon_atlas.gd`. It uses representative seeds for Snug,
Tier 1 Hollow, Hollow, Briar Maze, Sallow Mire, Summit, Pale Veins, Ashen Bough,
and Root Below.

## Current state — 2026-07-19

| Layer | Owner now | Deterministic at loading time? | Atlas representation |
|---|---|---:|---|
| Rooms, exact floor raster, graph, loops, critical route, roles | `DungeonGen` | Yes | Exact |
| Entrance, boss arena, rest, shrine, treasure and setpiece rooms | `DungeonGen` | Yes | Exact |
| Herbs, ore, logs and their rolled gathering tier | `DungeonGen` decor | Yes | Exact tile |
| Creature pack count, creature kind, elite and retinue | `LayoutLoader._build_enemies` | Only after scene load | Room ceiling and biome mix |
| Gear, reagent and enchant drops | `Drops` on death/open | No; global RNG at event time | Source only |
| Campaign trophies and authored evidence | Campaign contracts plus loader | Contract is frozen; presentation is late | Contract only |

This split is the main remaining architectural gap. Spatial and gathering
generation can already be previewed and reproduced from a Chart seed. Creature
and ordinary reward truth cannot yet be inspected from the pending layout,
because the scene loader and death callbacks still roll it later.

## 2D map grammar

The dungeon atlas uses the actual floor raster and the following overlay:

```text
E  entrance       B  boss arena      H  Hearth/rest
C  combat         T  treasure        S  shrine
★  setpiece       numbered circle    creature pack ceiling
◇  herb           ■  ore             ▲  logs/choppable resource
●  chest/item source

thick route = critical path (3 tiles wide)
ordinary route = 2 tiles wide
treasure spur = 1 tile wide
```

The critical route is guidance and pacing metadata, not a corridor centerline
promise; the raster remains the exact walkable geometry.

## Target layout schema

```gdscript
{
  # Existing spatial truth
  seed, grid, rooms, room_edges, corridor_widths,
  entry_room_id, boss_room_id, critical_room_ids,

  # Unified content truth
  enemy_manifest: [{
    id, pack_id, room_id, x, y, kind, role, depth,
    elite_modifier, retinue_of, drop_seed, trophy_sigil
  }],
  resource_manifest: [{
    id, room_id, x, y, kind, item, tier_key,
    source, source_affix, guaranteed
  }],
  reward_manifest: [{
    source_id, source_kind, room_id, drop_seed,
    reward_pool, guaranteed_items, campaign_owned
  }]
}
```

`drop_seed` is part of the frozen plan but is not player-visible. Exact rewards
can remain a surprise while host, guest, replay, loading preview, and runtime
all agree on the same outcome.

## Implementation plan

### Phase 1 — shared dungeon-content data

- Move `ENEMY_KINDS` and `SPAWN_TABLES` out of `layout_loader.gd` into a pure
  `wyrd/data/dungeon_content.gd` module.
- Add seeded helpers for weighted creature selection and room pack budgets.
- Preserve the current scope mixes and the Snug lesson override exactly.
- Use named RNG stream salts (`space`, `encounters`, `resources`, `rewards`) so
  adding a decor roll cannot reshuffle every creature or reward.

### Phase 2 — exact creature manifest

- Plan packs after rooms, roles, depth, critical path, and Affix modifiers are
  frozen.
- Reserve valid room-floor tiles with doorway and interactable clearance.
- Generate creature kind, pack ID, elite modifier, retinue relation, and any
  seeded trophy sigil in `DungeonGen`.
- Change `LayoutLoader._build_enemies` to instantiate `enemy_manifest` only.
- Keep authored bosses as campaign/encounter contracts; the manifest should
  reference the boss source but must not mint campaign truth.

### Phase 3 — unified resource manifest

- Promote existing Affix gather decor and biome guarantees into one
  `resource_manifest` instead of maintaining separate partial channels.
- Preserve exact tier rolls, Trade requirements, native biome guarantees, and
  source attribution.
- Let decor continue to carry visual props, but make gatherable gameplay read
  from the manifest.

### Phase 4 — deterministic item and reward manifest

- Add seeded overloads to `Drops.roll_drop`, `roll_reagents`, and enchant
  discovery rather than using global `randf()`/`randi()`.
- Give every enemy, chest, elite, and boss reward source a stable `drop_seed`.
- Pre-plan guaranteed chest and campaign rewards; ordinary kill rewards may be
  stored as hidden seeds plus pools to avoid spoilers.
- Make the host authoritative for collection while guests reproduce the same
  visible drop from the manifest event.

### Phase 5 — loading and debugging views

- Loading art shows qualitative summaries: expected creature families, pack
  pressure, number and families of harvest nodes, and treasure opportunities.
- Debug atlas may show exact room/tile overlays, creature kinds, and reward
  sources.
- Never show exact item rolls, elite position, or the full critical route in the
  normal player loading screen unless an Affix explicitly grants that knowledge.

## Verification

- Fixed-seed corpus across all nine representative Charts deep-compares all
  three manifests.
- Every enemy/resource/reward source references a reachable, valid room.
- No creature or gather node occupies entry, exit, doorway clearance, or another
  manifest reservation.
- Creature totals remain within current room-role and density formulas.
- Native biome resources and campaign contracts remain exact guarantees.
- Host and guest instantiate identical source IDs and reward results.
- All canonical project gates plus `test_procgen.gd` remain green.

