# Implementation notes — 68-first-hollow-forest-continuity

## Decisions

- Reuse the existing `RearFoliage0/1` children rather than add a parallel
  exterior-scatter system. They already inherit the authoritative wall visual's
  local cutaway and coordinate-derived seed.
- Use one oversized, unoutlined plane below the generated grid as a visual
  forest matte. It fills unavoidable gaps cheaply but owns no physics, route,
  or interaction truth.
- Keep the underlay and deep shoulder specific to `snug` until rendered First
  Road proof passes; later biomes retain their accepted treatment.

## Deviations

- None.

## Tradeoffs

- Prefer larger, more strongly offset versions of the two existing low-poly
  rear masses over adding more per-wall meshes. This deepens the silhouette
  without increasing the living edge's already substantial draw-object count.

## Surprises

- The shipped Web crop contains `0.273` near-black pixels versus effectively
  zero in the approved concept. Native's dark checker/void is less absolute but
  still occupies `0.084` below the same luminance threshold.
- The first implementation pass was the accepted visual pass. Deepening the
  two existing shoulder masses hid the matte's rectangular extent, so the bed
  reads as distant forest floor rather than a larger playable platform.
- The matched Web crop moved from `0.2684` near-black coverage to `0.0000`; the
  approved concept measured `0.0001` under the same crop and threshold.
- All 878 canonical assertions pass, including the existing complete-profile
  restoration and sub-1.5 ms cutaway budget. The retained corpus improved to
  118/122 in this run because its intermittent combat fixture did not reproduce;
  the four remaining failures are the documented driver/repro and old movement
  fixture exceptions, none of which load the changed presentation seam.
- The clean exported build audited all 112 resources. A fresh browser tab
  completed title → town → World → return with an empty warning/error ledger.
  Its 105,923,504-byte PCK has SHA-256
  `1b77869a37ec656e664e4d0b4212667812c0808ff47b35377b0f501472d06ce7`.
- Companion-site version 7 ships the same playable export, Deep Wood evidence,
  878-assertion receipt, and next-replay priority. Source commit
  `f0c5fa39e72c4a8437303b9bdc22345ee636d37a` built, rendered, and deployed
  owner-only at `https://wayfinder-field-journal.iamactuallyinthearen.chatgpt.site`.

## Followups

- Begin the next cycle from the shipped rendered build. Compare foreground
  canopy bulk, interior ground sameness, and room landmark identity before
  choosing another bounded checkpoint.
