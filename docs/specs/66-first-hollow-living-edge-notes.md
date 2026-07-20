# Implementation notes — 66-first-hollow-living-edge

## Decisions

- Keep the checkpoint inside the accepted `snug` room-grammar seam. The
  generator will emit inspectable perimeter profile data; the loader will only
  realize that data on existing boundary wall bodies.
- Treat one landmark per generated room as the minimum compositional promise.
  More scatter would increase density, but it would not make room identities
  legible or reproducible.
- Attach trunks, canopies, roots, stones, and understory to the same
  `WallMesh` root already owned by the camera cutaway. A tall landmark cannot
  become a second untracked obstruction system.
- Reuse the existing Wood Grove fern, log, and boulder meshes inside the new
  profile kit where their authored silhouettes outperform primitives. They are
  pass-through children of the existing wall body and inherit the same cutaway.
- Derive an inward direction from adjacent generated floor for every boundary
  profile, then place a dark rear foliage shoulder outward from it. This hides
  the immediate void as forest depth without restoring deep exterior walls or
  any extra collision.

## Deviations

- None.

## Tradeoffs

- Use a compact procedural low-poly kit and existing palette/material language
  rather than a new paid or generated asset pass. This can establish layering,
  rhythm, and composition now; bespoke foliage meshes remain eligible only if
  rendered review shows the kit cannot carry the art direction.
- Preserve the full-tile wall collider while varying visuals inside it. This
  keeps route and projectile truth identical to the accepted checkpoint.
- Reduce First Road leaf-confetti and replace its pale cubic seam rubble with a
  darker, sparser moss-stone scatter. The protected center should be visually
  quiet as well as physically clear.

## Surprises

- The first procedural profile pass was too bright and evenly spaced, reading
  as beads around a board. Darker banks, a rear forest shoulder, fewer floor
  flecks, and larger landmark silhouettes produced the accepted composition.
- The shared worktree acquired unrelated creature-codex and chest work during
  release verification. Its Web export correctly exposed the unlisted chest
  dependency. The checkpoint release is therefore verified from its exact
  scoped commit in a clean worktree, preserving the unrelated work untouched.
- The retained direct corpus is 116/121. Its four documented driver/repro
  exceptions remain, while `test_combat.gd` repeats a pre-checkpoint chase/nav
  fixture anomaly and does not load either changed production script. All ten
  canonical production gates pass.

## Followups

- Reassess Web color and tonal separation as its own checkpoint after the
  living edge is proven in both renderers.
