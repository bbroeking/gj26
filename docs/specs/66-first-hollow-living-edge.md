# 66 — First Hollow living edge

> **Outcome:** First Road clearings keep their procedural room graph, varied
> footprints, continuous FATE camera, and readable central stage, while their
> perimeter becomes a layered Bramblewood composition rather than a repeated
> ring of identical green masses.

## Why

Natural Hollows removed deep wall fields and proved authored clearing shapes,
but rendered play beside the approved First Hollow concept exposes the next
largest gap. The released boundary has one repeated oval silhouette, sparse
ground scatter, and no archetype-owned edge landmark. It reads as a procedural
barrier rather than the dense, asymmetrical living edge that makes the concept
feel like a place.

This checkpoint deepens the accepted room grammar. It does not add a new map,
system, encounter, reward, input, or camera mode.

## Scope

**In:**

- Give every First Road boundary cell deterministic room ownership where it
  touches an authored room footprint; corridor-only boundary remains a safe
  neutral bank.
- Resolve each owned cell to a compact archetype-aware visual profile such as
  leaf bank, root bank, fern bank, stone bank, or a focal tree/log profile.
- Give every First Road room one seeded, readable perimeter landmark selected
  from its archetype and role, while retaining variation across seeds.
- Build the profiles from a small low-poly Bramblewood kit with layered height,
  hue, trunk/root/stone rhythm, and clustered foliage instead of repeating one
  vertical oval.
- Keep every profile on the existing wall body and under its `WallMesh` root so
  collision, navigation, camera cutaway, restoration, and projectile truth do
  not fork.
- Keep corridor mouths and the central combat aperture visually readable.
- Add deterministic data and production-scene gates, then compare native and
  Web renders with the approved First Hollow concept.

**Out:**

- Handcrafting complete maps or replacing procedural Chart graphs.
- Propagating this kit to Mire, Summit, Rootroads, or later roads.
- New collision shapes, invisible navigation blockers, sealed arenas, camera
  snaps, room locks, or transparency holes.
- New enemies, resources, rewards, Skills, Affixes, campaign content, audio, or
  paid/generated asset production.
- Solving the separate Web grading mismatch unless it prevents verification of
  this checkpoint.

## Player-visible contract

1. A First Road clearing has a quiet playable center and a dense edge with
   visible foreground, middle, and landmark layers.
2. Adjacent boundary pieces no longer repeat one silhouette: foliage banks,
   roots, stones, ferns, logs, and occasional trees create controlled rhythm.
3. Every room carries one edge landmark that supports its generated archetype,
   so a round glade and crooked bower are not only different masks.
4. Entrances remain open and readable; landmarks sit on colliding wall cells,
   never in the route or protected combat aperture.
5. The continuous FATE camera behaves exactly as before. A full compound edge
   profile lowers and restores as one local obstruction unit.
6. The same Chart seed reproduces profile identity, room ownership, landmark
   placement, and variation; different seeds visibly remix the edge.

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/dungeon_gen.gd` | emit deterministic archetype-owned perimeter profile data |
| `wyrd/scripts/layout_loader.gd` | realize the layered low-poly living-edge kit under existing wall roots |
| `wyrd/test_first_hollow_living_edge.gd` | prove ownership, landmark, determinism, and seed variation |
| `wyrd/test_hollow_readability.gd` | prove the production scene realizes and cuts complete profiles |
| `docs/playtests/first-hollow-living-edge/` | native/Web comparison and observation evidence |
| `docs/wyrd-roadmap.md` | record checkpoint state |
| `docs/CHANGELOG.md` | record shipped version |
| `docs/devlog.md` | explain player-visible problem, decision, evidence, and result |
| `docs/test-manifest.md` | add the focused canonical gate |

## Acceptance criteria

1. Identical seeds reproduce the full perimeter profile manifest. A fixed
   multi-seed sample realizes multiple base and landmark profiles.
2. Every perimeter manifest entry names a real boundary cell. Every owned room
   id names a room whose footprint touches that boundary cell.
3. Every First Road room owns exactly one landmark profile; corridor-only banks
   remain valid but cannot invent room ownership.
4. Landmark visuals remain children of the matching colliding wall's
   `WallMesh`; no new floor collider or navigation blocker is introduced.
5. The rendered Bold Road visibly contains at least three edge profile families
   and at least two room landmarks in a normal continuous-camera traversal.
6. Player, foes, aiming lane, and an opening remain readable. The full layered
   profile lowers and restores through the existing local cutaway.
7. The canonical native gate remains green, the retained corpus adds no new
   failure, and the Web export audits and completes title → town → First Road →
   return with an empty diagnostic ledger.
8. Native and Web evidence reviewed beside the approved concept shows a more
   layered, asymmetrical, place-like perimeter without sacrificing the clear
   central stage.

## References

- `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`
- `docs/specs/65-first-hollow-room-grammar.md`
- `docs/specs/62-readable-hollow-checkpoint.md`
- `docs/adr/0018-authored-charts-single-player-focus.md`

## Done check

- [x] Perimeter ownership and profiles are deterministic.
- [x] Every First Road room owns one archetype-aware landmark.
- [x] The production scene realizes layered profiles only on existing walls.
- [x] Openings, combat aperture, collision, navigation, and FATE cutaway remain intact.
- [x] Native and Web comparison materially closes the living-edge concept gap.
- [x] Native, Web, resource, diagnostic, and retained-corpus gates pass.
- [x] Roadmap, notes, changelog, devlog, version, and test manifest are current.
- [x] Game and companion website are committed, pushed, deployed, and verified.
