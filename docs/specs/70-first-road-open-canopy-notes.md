# Implementation notes — 70-first-road-open-canopy

## Decision

- The shipped replay selected foreground canopy bulk over corridor mouths and
  landmark identity: the route remained readable, but the nearest forest
  shoulder consumed too much projected screen area under the preserved camera.
- Tune only the existing `RearFoliage0/1` geometry envelope. This keeps Deep
  Wood's continuity model intact and avoids a parallel obstruction system.
- The first geometry-only render showed that adjacent real wall crowns—not
  only the rear shoulder—still bracketed the ranger. Widen the accepted opaque
  cutaway aperture rather than changing the FATE camera or wall collision.

## Render loop

- Before: `/tmp/soft-ground-next-cycle-native-2.png` from exact shipped
  `0.1.9-soft-ground` native play.
- Native v1: `/tmp/open-canopy-after-native.png`. Rejected: the center opened,
  but the lower foreground still consumed about one quarter of the frame. The
  second pass settles and tightens the same presentation-only masses further.
- Native v2: `/tmp/open-canopy-after-native-v2.png`. Rejected as final: the
  depth masses became quieter, but neighboring foreground crowns still formed
  tall shoulders beside the low center cut. The next render widens that same
  solid cutaway stage.
- Native v3 and the exact exported Web frame are accepted. Moving and firing
  through the low foreground opening kept the corridor mouth, ranger, enemy,
  and Waystone readable while the continuous dark forest still framed the room.

## Validation

- Focused gate: 5/5.
- Canonical gate: 888/888 across fourteen suites.
- Retained corpus: 120/124. One movement-feel sample landed a single float
  epsilon above its yaw bound and reran 12/12; only the four documented
  driver/repro and old movement exceptions remain.
- Exact export: 112/112 audited resources; 105,923,952-byte PCK, SHA-256
  `add43de81df0b0416608d86d02a6356b804e69f9a7149aae644cf98f5c363bb8`.
- Clean browser route: title → town → generated First Road → return, harness
  passed, no warning/error diagnostics. Accumulated WebGL test tabs initially
  throttled a healthy route beyond the old watchdog; closing them restored the
  normal pass, and the compact probe now shares the robust 15-minute ceiling.
- Companion deployment pending.
