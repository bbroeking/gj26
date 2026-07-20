# 68 — Deep Wood

> **Outcome:** Procedural First Road clearings feel embedded in Bramblewood
> rather than outlined by a hedge ring floating over black void, while the
> playable boundary, collision, camera cutaway, and room graph remain exactly
> the accepted systems.

## Why

`0.1.7-shaded-road` restores browser tonal separation and exposes the next
largest visual gap against the approved First Hollow concept. The concept fills
the frame beyond its playable stage with continuous forest floor and layered
canopy. The shipped clearing still reveals broad black regions immediately
behind its living edge, making authored room archetypes read as isolated game
boards rather than places along one road.

The existing edge already owns a seeded, cutaway-tracked rear foliage shoulder,
but it reaches only roughly half a metre beyond the colliding wall. This
checkpoint deepens that established seam instead of rebuilding the deleted
exterior wall field.

## Scope

**In:**

- Add one dark, non-colliding forest-ground underlay beneath the full First Road
  grid so gaps behind the playable boundary never fall directly to black.
- Extend each existing seeded rear foliage shoulder into two overlapping depth
  tiers with varied height, lateral rhythm, hue, and silhouette.
- Keep the foliage tiers under the owning wall's `WallMesh`, so the existing
  local camera cutaway lowers and restores the complete obstruction unit.
- Keep the deepest layer darker and quieter than the playable boundary, with no
  competing saturation peak, outline noise, prompt, shadow, or interaction.
- Validate native and Web renders against the approved First Hollow concept.

**Out:**

- Restoring colliding exterior wall fields or floor collision outside the
  generated playable graph.
- Hand-authoring complete maps, changing room masks, corridors, archetypes,
  entrances, encounters, resources, rewards, or Chart randomness.
- Camera snaps, room locks, arena framing, fog-of-war, or a new occlusion system.
- New paid/generated assets, new shaders, vegetation simulation, or propagation
  to later biomes before the First Road proof passes.

## Player-visible contract

1. A First Road clearing sits within a continuous dark forest bed; broad black
   wedges no longer touch the playable living edge.
2. The playable wall remains the brighter, readable foreground boundary. A
   darker middle and rear canopy create depth without becoming a second ring of
   equally important objects.
3. The ranger, enemies, aiming lane, entrance, and Waystone retain the same
   readable central stage.
4. Nearby complete edge profiles—including their deeper forest shoulder—lower
   and restore through the existing continuous FATE-camera cutaway.
5. The exterior layer has no collision, navigation, interaction, reward,
   projectile, or encounter authority.
6. Identical seeds reproduce the same depth silhouette; different seeds retain
   the existing variation rhythm.

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/layout_loader.gd` | build the underlay and deepen existing rear shoulders |
| `wyrd/test_first_hollow_forest_continuity.gd` | prove coverage, ownership, and non-authority |
| `wyrd/test_hollow_readability.gd` | retain complete-profile cutaway and budget proof |
| `docs/playtests/first-hollow-forest-continuity/` | native/Web/concept evidence and measurements |
| `docs/wyrd-roadmap.md` | record checkpoint state |
| `docs/CHANGELOG.md` | record shipped version |
| `docs/devlog.md` | explain the visible problem, decision, and evidence |
| `docs/test-manifest.md` | register the focused gate |

## Acceptance criteria

1. The First Road production scene contains one forest underlay larger than the
   generated grid and below the playable floor; it has no collision or
   navigation child and casts no shadow.
2. Every First Road living-wall profile retains two seeded rear foliage masses,
   with its far tier extending at least 1.35 metres outward from the colliding
   boundary root.
3. Rear foliage remains under the matching `WallMesh`; no exterior mesh joins
   the `wall`, `floor`, interaction, enemy, or gather groups.
4. A rendered 1280×720 browser gameplay crop reduces near-black pixels from the
   `0.1.7` baseline of `0.273` to at most `0.08`, without covering the player,
   Waystone, route, or HUD.
5. Native and Web comparison beside the approved concept reads as forest
   continuity, not a larger repeated hedge ring or a flat green rectangle.
6. The complete-profile camera cutaway still restores, its scan stays below
   1.5 ms, the canonical native gate remains green, and the retained corpus adds
   no checkpoint-caused failure.
7. The exact Web export audits every release resource and completes title →
   town → generated First Road → return with an empty warning/error ledger.
8. Roadmap, notes, changelog, devlog, version, evidence, game release, and
   companion site are current.

## References

- `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`
- `docs/specs/66-first-hollow-living-edge.md`
- `docs/specs/67-web-tonal-separation.md`
- `docs/adr/0018-authored-charts-single-player-focus.md`

## Done check

- [x] One non-authoritative forest underlay replaces direct black gaps.
- [x] Existing cutaway-owned rear shoulders create a dark two-tier depth read.
- [x] Procedural layout, collision, navigation, controls, and camera are unchanged.
- [x] Native/Web concept comparison and performance gates pass.
- [x] Canonical, retained, export, diagnostic, documentation, and release gates pass.
