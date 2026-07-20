# Implementation notes — 67-web-tonal-separation

## Decisions

- Keep the correction in `_apply_biome_env()`, where every generated run
  already receives its own duplicated `Environment`. This is the smallest seam
  that changes world rendering without touching Canvas UI or shared scene
  resources.
- Treat native Forward+ as the protected reference implementation. Apply the
  adjustment only when `OS.has_feature("web")` is true; expose a test/dev force
  switch solely so the production path can be verified under native headless
  and captured quickly before a full Web export.
- Begin with measured highlight compression rather than new lights, materials,
  fog substitutes, or an additional screen-space pass.

## Measurements

- Exact `0.1.6-living-edge` playfield crop (linearized only by the PNG output,
  same normalized crop rule): native mean/p95 `0.260/0.388`; Web
  `0.371/0.616`; approved concept `0.328/0.461`.
- The Web crop also has roughly twice the luminance standard deviation because
  the visible black void remains dark while the authored room clips bright.
  The correction therefore targets the environment's bright world values, not
  the UI or void backdrop.

## Deviations

- None.

## Tradeoffs

- Use post-tonemap brightness `0.82` and a modest minimum contrast of `1.08`
  rather than rebuilding Web lighting or emulating unsupported volumetric fog.
  This is effectively free, retains focal glow and readable routes, and stays
  inside the established environment seam.

## Surprises

- The first corrected browser frame landed very close to the concept in mean
  brightness (`0.316` versus `0.328`) while retaining a broader highlight range
  for the ranger and Waystone. Native before/after distributions matched to
  five decimal places, stronger evidence than visual inspection alone that the
  renderer guard is honest.
- The exact compact browser route logged title, town, world, and complete with
  no warnings or errors. The export audited all 112 release resources; its PCK
  is 105,922,096 bytes with SHA-256
  `072bf30f73776a01ea0b896cd02774e1e3503e2e5f1382e3758d98a414985879`.
- The retained direct corpus remains 116/121. Its driver-required failures and
  historical movement timing behavior remain; the standalone 12/12 production
  movement gate passed, and no new checkpoint-caused failure appeared.

## Followups

- The next concept comparison should address the black void and isolated-ring
  read beyond First Road boundaries. It must add non-obstructive forest depth,
  not restore colliding wall fields or interrupt the continuous FATE camera.
