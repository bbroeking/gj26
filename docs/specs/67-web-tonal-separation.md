# 67 — Shaded Road

> **Outcome:** Browser play preserves the First Hollow's readable stage while
> restoring the shadow, midtone, and highlight separation already present in
> native play and the approved gameplay concept.

## Why

The `0.1.6-living-edge` checkpoint proves the new procedural room grammar and
layered boundary in native and Web play. Its exact shipped Web render exposes
the next highest-leverage player-visible weakness: Compatibility rendering
lifts and clips the Wood Grove floor, foliage, and wall faces into one bright
yellow-green band. The same content has materially better plane separation in
native Forward+ rendering, and the approved First Hollow concept keeps its lit
stage without bleaching its enclosing forest.

This checkpoint corrects the renderer mismatch. It does not redesign rooms,
walls, camera, gameplay, UI, or the native art direction.

## Scope

**In:**

- Apply a small Web-only post-tonemap adjustment to generated exploration
  environments through the existing duplicated biome `Environment` resource.
- Lower clipped highlights and restore readable foliage/floor/wall separation
  without placing a dark overlay over the HUD.
- Keep the correction deterministic, centralized, and inspectable.
- Compare exact native and Web captures against the approved First Hollow
  concept and validate the real browser build through its complete smoke route.

**Out:**

- Changing native lighting, palette, materials, fog, or post-processing.
- Changing procedural Chart graphs, room masks, archetypes, edge profiles,
  collision, navigation, camera behavior, controls, encounters, or rewards.
- Adding a full-screen UI filter, a new rendering system, new assets, or paid
  services.
- General visual parity work for every later biome before it becomes the
  highest-leverage rendered weakness.

## Player-visible contract

1. The Web First Road retains a warmly lit central stage, but leaf banks,
   stones, ground, and wall shoulders no longer collapse into one clipped band.
2. The HUD, quest parchment, labels, and input feedback are not darkened or
   recolored by the 3D correction.
3. Native Forward+ play is pixel-behaviorally unchanged by this checkpoint.
4. Procedural layout, room archetype ownership, living-edge variation, wall
   obstruction behavior, and continuous FATE camera are unchanged.

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/layout_loader.gd` | apply centralized Web-only biome grading |
| `wyrd/test_web_tonal_separation.gd` | prove grade constants, native no-op, and production application seam |
| `docs/playtests/web-tonal-separation/` | native/Web/concept evidence and measurements |
| `docs/wyrd-roadmap.md` | record checkpoint state |
| `docs/CHANGELOG.md` | record shipped version |
| `docs/devlog.md` | record weakness, decision, evidence, and result |
| `docs/test-manifest.md` | register the focused canonical gate |

## Acceptance criteria

1. Web grading changes only the duplicated 3D biome `Environment`; Canvas UI
   receives no overlay or material change.
2. Production Web brightness is lowered enough that the central playfield's
   high tones approach the approved concept without crushing route-legibility
   shadows or dulling the Waystone/player focal accents.
3. A production test proves native is a no-op and a forced Web path applies the
   centralized adjustment values.
4. Exact native before/after captures remain visually unchanged.
5. Browser before/after captures show clearer floor/foliage/wall plane
   separation beside the approved concept.
6. Canonical native gates remain green, retained tests add no new regression,
   and the exact Web export completes title → town → First Road →
   return with an empty warning/error ledger.
7. Roadmap, notes, changelog, devlog, version, and test manifest are current;
   game and companion site are committed, pushed, deployed, and verified.

## References

- `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`
- `docs/specs/66-first-hollow-living-edge.md`
- `docs/specs/65-first-hollow-room-grammar.md`

## Done check

- [x] Web-only 3D grading is centralized and renderer-aware.
- [x] Native rendering and accepted gameplay contracts are unchanged.
- [x] Browser comparison materially improves tonal separation.
- [x] Native, Web, diagnostic, canonical, and retained-corpus gates pass.
- [ ] Documentation, version history, game release, and companion site are current.
