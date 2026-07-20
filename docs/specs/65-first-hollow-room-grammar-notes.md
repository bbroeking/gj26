# Implementation notes — 65-first-hollow-room-grammar

## Decisions

- Locked the user-approved product boundary: seeded procedural Chart graphs,
  randomized authored room archetypes, and the continuous FATE camera remain.
- Treat natural wall shape and obstruction readability as one spatial contract.
  Improving only the cutaway would preserve the exposed rectangular room
  silhouette; changing only the silhouette would leave the same combat
  obstruction failure.
- Keep the proof scoped to `snug`/First Road presentation. Other scopes retain
  their existing shapes and wall visuals until this checkpoint survives native
  and Web release play.
- Represent archetypes as compact data plus normalized carving functions. This
  keeps role pools and identities inspectable while allowing the existing
  scatter, Delaunay, MST, loop, corridor, encounter, and Affix pipeline to own
  the run.
- Derive wall variation from Chart seed plus cell coordinates rather than wall
  iteration order. Removing deep exterior cells therefore cannot reshuffle the
  silhouette or downstream spawn RNG.

## Deviations

- The camera code needed no change. Its existing group-based local cutaway
  already treats `WallMesh` as a transformable `Node3D`, so a compound natural
  wall root preserves the accepted continuous behavior and tests.

## Tradeoffs

- The first checkpoint is limited to the First Road/Green Hollow proof. Later
  biome propagation is intentionally withheld until the native and Web visual
  comparison proves that the grammar is worth standardizing.
- The wall collision remains a simple full tile even though the visual is a
  lower compound mass. This keeps navigation and projectile truth robust; a
  future checkpoint may lower collision only if play exposes an invisible-hit
  problem near the top edge.
- The First Road boundary uses procedural low-poly masses rather than new paid
  assets. It establishes composition and obstruction truth now, while richer
  authored foliage remains a later art-production checkpoint.

## Surprises

- The current loader builds a wall node for every non-floor grid cell, including
  deep unused exterior space. The visual plateau is therefore a construction
  artifact, not an unavoidable consequence of the procedural room graph.
- The existing generator already carries role, theme, varied-shape, setpiece,
  and room-bound metadata. The new grammar can deepen this seam without
  replacing campaign, Affix, resource, or graph ownership.
- The July working tree is substantially ahead of its last commit: 108 tracked
  files changed plus 895 untracked files. The canonical eight suites pass
  845/845, the current Web export passes its 112-resource audit, and an
  exhaustive direct invocation found 114 passing `test_*.gd` entrypoints.
  Four remaining direct invocations are not equivalent test cases: the D7
  prior-saga handoff requires one of three explicit scenario variables, the D8
  ENet process requires a coordinated host/guest driver, the D7 late-world
  probe encodes the historical browser failure and now fails because harvest
  succeeds, and `test_movement.gd` still assumes the pre-loadout fire path.
  This classification is part of the provenance boundary and must not be
  reported as an undifferentiated green 118/118 suite.
- The first natural-wall render was structurally correct but visually wrong:
  tapered columns with round crowns read as a capped palisade. Rendered review,
  not a test, rejected it. Overlapping lower hedge/rootstone masses produced
  the accepted perimeter language.

## Followups

- Encounter staging, biome-wide propagation, and late boss-room composition
  remain separate candidate checkpoints after this spatial foundation passes.
- Revisit the invisible upper collision extent only if real play shows arrows
  or movement reacting above the shorter First Road wall silhouette.
