# Shaded Road rendered verification

Exact `0.1.6-living-edge` before and `0.1.7-shaded-road` after captures from the
same clean checkpoint lineage, reviewed beside
`docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`.

## Evidence

- `before-native.png` / `after-native.png` — Forward+ production First Road.
- `before-web.png` / `after-web.png` — real WebGL Compatibility production
  First Road captured through the compact exported journey.
- Native full-frame mean and percentile distributions match to five decimal
  places before/after.
- Normalized playfield crop:
  - native before mean/p95: `0.260 / 0.388`
  - Web before mean/p95: `0.371 / 0.616`
  - Web after mean/p95: `0.316 / 0.526`
  - approved concept mean/p95: `0.328 / 0.461`

The Web after frame restores distinct foliage, ground, and wall planes while
keeping the player and Waystone as high-value accents. UI is unchanged because
the grade mutates only the duplicated 3D `Environment`.

## Runtime receipt

- Browser: WebGL 2 Compatibility renderer.
- Ordered log: `[web-smoke] title`, `town`, `world`, `complete`.
- Diagnostics: zero warnings, zero errors.
- Export audit: 112/112 release resources.
- PCK: 105,922,096 bytes.
- SHA-256: `072bf30f73776a01ea0b896cd02774e1e3503e2e5f1382e3758d98a414985879`.
