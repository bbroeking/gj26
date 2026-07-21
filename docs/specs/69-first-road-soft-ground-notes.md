# Implementation notes — 69-first-road-soft-ground

## Decisions

- Use only existing toon-ground shader parameters. The visual problem does not
  justify another mesh, texture, shader, or scatter system.
- Scope the override to `snug`; `wood_grove` is shared by later Charts whose
  ground has not been selected as this cycle's weakness.

## Tradeoffs

- This pass establishes the large material read, not authored footpaths. If
  room flow later becomes the highest visible weakness, paths require their own
  rendered checkpoint rather than arriving here as decorative scope creep.

## Surprises

- Deep Wood's canopy held up under native movement, roll, and bow fire. With the
  black surround gone, the same floor pattern across room and corridor became
  the strongest remaining board-like signal.
- The first soft-ground render removed the cobble read but collapsed into one
  flat olive sheet under the First Road's green lighting. It was rejected. The
  second pass restored warmer soil, but its stronger cell value brought back a
  field of large polygons. The third combines that warmer palette with low cell
  strength so broad macro mottle—not grout or plates—carries the variation.
- Web preserved the quiet surface but shifted it toward yellow-green. The final
  palette counterbalances that Compatibility lighting with a redder soil base;
  the moss stays green and the native result remains inside warm forest earth.
- All 883 canonical assertions pass. The retained corpus is 119/123: only the
  four documented driver/repro and old movement exceptions remain, and none
  loads the snug material seam changed here.
- The exact release export audited 112/112 resources and completed a fresh
  title → town → generated First Road → return route with an empty diagnostic
  ledger. Its 105,923,984-byte PCK has SHA-256
  `372e3d0c71b3f732beaa9b4f2f8564782af3f5e3a649ce8fc62aa11bc70a467f`.

## Followups

- Accepted native and Web renders preserve the quiet combat stage while moving
  the floor from green-lit stone toward warm soil. Begin the next cycle from
  replay rather than extending this material into paths or other biomes.
