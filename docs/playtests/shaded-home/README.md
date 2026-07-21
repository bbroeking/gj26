# Shaded Home checkpoint evidence

Accepted locally on 2026-07-21 against Spec 76.

- `before-native.png` — exact settled `0.1.15` Town presentation with the new
  grade disabled: grass, route, ranger, Mara, and props share a pale band.
- `after-native.png` — final Forward+ Town grade at the same camera, state, and
  1280×720 viewport.
- `after-compatibility.png` — final Compatibility renderer with the production
  Web override forced, matching the visually inspected browser result.
- Approved reference:
  `../../concept-art/gameplay-direction/wayfinder-state-01-arrival.png`.

Whole-frame luminance mean / p95 / standard deviation at a normalized sample:

- approved concept: `0.336 / 0.542 / 0.136`
- before native: `0.723 / 0.772 / 0.053`
- after native: `0.447 / 0.478 / 0.069`
- after Compatibility: `0.536 / 0.557 / 0.060`

The comparison is directional, not a demand to match whole-frame means: the
concept includes a dense dark building and treeline frame that this bounded
grade does not fabricate. Acceptance rests on materially restored route/actor
separation, unchanged Canvas UI, the 996-assertion native gate, the 118-resource
export audit, and the passed rendered browser journey.

The final versioned export is 96,120,576 bytes with SHA-256
`7499e80d380ba0a6b82d392ffd7db17787bf90f81fbaad1e4a5d625cca7987ce`.
