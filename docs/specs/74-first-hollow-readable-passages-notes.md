# Spec 74 implementation notes — First Hollow readable passages

## 2026-07-21 — checkpoint opened

- Replayed the exact shipped 0.1.13 Bold Road, moved and rolled through the
  generated rooms, and rotated the continuous FATE camera.
- The accepted larder now breathes. The next room-level weakness is the thick,
  bulbous living-wall shoulder between adjacent rooms: it reads as a hedge
  barricade and can dominate the center of the frame during yaw.
- The approved First Hollow concept keeps a dense surround but makes its top
  passage unmistakable with low, concave foliage shoulders and uninterrupted
  floor direction.
- Chosen seam: specialize only boundary presentation beside actual generated
  room connections. Preserve the graph, wall cells, collision, navigation,
  screen-space cutaway, and all ongoing user-owned Chest/creature work.

## Validation ledger

- The one-cell shoulder was structurally correct but too subtle in the matched
  native render. The accepted two-cell taper frames the full 1–3-wide corridor
  and remains bounded to real room mouths.
- Focused production gate: 7/7. Same-seed passage ownership reproduces; every
  room mouth is framed; passage profiles remain real wall cells; landmarks stay
  off the opening; compact meshes remain under `WallMesh`; full 1×3.6×1 wall
  collision remains unchanged; later biomes remain isolated.
- Existing living-edge, forest-continuity, open-canopy, room-composition,
  room-breathing, setpiece-breathing, and camera-cutaway suites all pass.
- Canonical native gate: 911/911 assertions across 18 suites. The first
  movement sample hit its documented 30-frame timing edge; the immediate repeat
  passed 12/12. This checkpoint changes no movement or creature source.
- Strict persistence-disabled retained sweep: 120/128. Four fixtures exceeded
  the 30-second watchdog and the same four historical driver/repro failures
  remained. The additional marginal Golden Wallow timeout passed an immediate
  isolated watchdog rerun in 29 seconds; every changed-seam entrypoint passed.
- Native rendered comparison accepted at 1280×720 at the default FATE angle and
  after yaw. The connected floor now reads through a low concave bank without
  exposing void or flattening ordinary room edges.
- Web resource audit: 112/112 from a 105,927,600-byte PCK; SHA-256
  `646d6db35b5bdcf299907ac399b8ee04bfbe8f82bd273cd94aa94dad4e14d82f`.
- Exact browser route: title → town → world → complete in 29.841 seconds;
  diagnostic ledger empty.
- Companion-site version 14 was saved from exact pushed source
  `a7900d5bd8bcc6a69b284cd09ffc0b821bfd8d6c`, deployed owner-only, and visually
  verified at
  `https://wayfinder-field-journal.iamactuallyinthearen.chatgpt.site`.
