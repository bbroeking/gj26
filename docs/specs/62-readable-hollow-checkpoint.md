# Spec 62 — Readable Hollow checkpoint

Status: accepted locally; publication pending repository provenance (2026-07-20)

## Player-visible mismatch

The responsive Bold Road still lets opaque procedural wall blocks consume most
of the 1280×720 frame and hide the player, enemies, and combat lane. The
approved First Hollow concept keeps enclosure at the perimeter while reserving
a clear play aperture around the ranger.

## One checkpoint

Replace the camera's pencil-thin wall ray with a small, bounded screen-space
cutaway aperture around the player. Overlapping wall visuals lower to a solid
boundary instead of becoming transparent over floorless cells. Preserve the
FATE camera, layout, collision, encounter, palette, controls, and physical wall
height.

## Acceptance

- The production Bold Road lowers multiple near-camera wall tiles when needed.
- Cut walls retain a low solid boundary while player and enemy silhouettes read.
- The cutaway restores immediately when the camera/player relationship clears.
- Native rendered evidence at 1280×720 shows the same seeded pressure position.
- The canonical gameplay gates and the new readability gate pass.

## Acceptance result

- 841/841 assertions pass across the eight canonical suites.
- The focused Bold Road gate lowers five occluding walls, restores them after a
  camera reversal, and stays below its 1.5 ms average update budget.
- The clean Chromium export route completed title → town → world → complete in
  11.4 seconds with no warnings, errors, assertions, or exceptions.
- Evidence: [before](../playtests/readable-hollow/before-native.png),
  [native after](../playtests/readable-hollow/after-native.png), and
  [Web after](../playtests/readable-hollow/after-web.png).
