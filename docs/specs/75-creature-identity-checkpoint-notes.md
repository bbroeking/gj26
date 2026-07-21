# Spec 75 implementation notes — Creature identity checkpoint

## Decisions

- Began from the mixed post-0.1.14 worktree without discarding its Creature
  Codex, projectile renderer, Pause integration, combat changes, or authored
  Wayfinder chest.
- Public acceptance seams are the Codex/Pause interaction, production creature
  spawn and attack behavior, the Interactable chest contract, the canonical
  native gate, and a real exported browser journey.
- Initial health check: Creature Codex 21/21, boot smoke 148/148, movement feel
  12/12. Core loop exposed the intended Gilded density change at 425/426; the
  generator still scattered two bonus chests.
- First red/green slice: reduced the Gilded scatter contract from two bonus
  chests to one. Core loop returned to 426/426.
- Audit finding: the renderer accepts a projectile color, but production spawn
  data does not yet assign kind-owned colors, leaving the cast on the magenta
  fallback. Every boss currently inherits the same every-third-attack cast,
  including the Boar, Wolf, and Knot-Eater whose authored signatures should
  remain uninterrupted.

## Deviations

- No gameplay deviation from Spec 75 remains. The release reconciliation adds
  no new content or behavior; it only makes the accepted checkpoint's version,
  changelog, devlog, roadmap, README, and publication history truthful.

## Tradeoffs

- Kept one readable projectile opening on every common creature instead of
  giving each a second bespoke authored attack. This preserves the bounded
  checkpoint while the original kiting, healing, heavy-ring, pursuit, and
  melee rhythms provide the longer encounter identity.
- Kept the Wayfinder chest on the existing Interactable and two-roll treasure
  contract. A bespoke chest system would add a parallel reward path without
  improving what the player can read.

## Surprises

- The first export attempt correctly failed because the explicit release list
  did not contain the new chest GLB. The export preset and PCK audit were made
  authoritative before retaining any Web evidence.
- The accepted local checkpoint still advertised `0.1.14` in `project.godot`
  and had no changelog or devlog entry. Those provenance gaps are part of the
  release work, not evidence against the accepted gameplay implementation.

## Followups

- Replay the exact shipped `0.1.15` build before selecting another checkpoint.
  The fresh Web audit observed severe yard highlight clipping and foreground
  foliage obscuring the arrival route; compare that state with the approved
  Arrival concept if it remains the leading player-visible weakness.
- The Knot-Eater still uses the bounded Barrow Jarl placeholder model. It
  remains a later visual checkpoint, not part of Creature Identity.

## Validation ledger

- The completed canonical native gate is green: 19 suites, 986 assertions.
  After the final UI-copy adjustment, the changed seams were rerun directly:
  Creature Codex 71/71, boot smoke 148/148, and movement feel 14/14. The
  production movement check then passed five consecutive runs after its sample
  window was made independent of the spawned creature's 0.6–0.9 s tell.
- Representative production chapter gates are green: Golden Wallow runtime
  15/15, Seventh Road runtime 9/9, Queen's Summit world 9/9, Pale Oath world
  17/17, Fire in the Bough world 10/10, and Knot-Eater encounter 21/21. The
  canonical First Road/First Hollow suites cover the opening chapter.
- The final Web resource audit loaded 118 required resources from a
  96,119,632-byte PCK with SHA-256
  `41e4db15838ce053a8cc0a3486688210f99da32ead1019724373e9656fa5d2d2`.
  The release export omits only unreferenced UI source/reference sheets; the
  editable originals remain in the repository.
- A fresh Chromium tab completed the compact title → town → generated road →
  return route with ordered observations `title`, `town`, `world`, `complete`.
  The warning/error ledger was empty. Pause → Creature Codex then rendered at
  1280×720 with readable ink-on-paper detail and plain-text input hints.
- The final versioned release rerun passed the fail-closed enhanced sequence
  `title → town → chart_table → codex → chart_table_closed → world → complete`.
  Its harness reported PASS and its warning/error ledger remained empty.
- Evidence is retained in `docs/playtests/creature-identity/`.
