# Spec 73 implementation notes — First Hollow setpiece breathing

## 2026-07-20 — checkpoint opened

- The first exact 0.1.12 replay showed a tall grey U-shape in the chamber next
  to Lantern Landing despite the accepted room-support rules.
- Generator inspection identified that chamber as the seeded `larder`
  setpiece: eight legacy `pottery` marks remap to full-size wood-grove boulders
  after ordinary room dressing has finished.
- Chosen seam: retain the authored template, but tag its First Road supports
  with the established scale and filter them through the same directional
  landing contract. Chest and creature work remains untouched.
- The first implementation removed three decor records entirely. The production
  movement gate caught that this changed later enemy-cell selection. The
  accepted seam keeps those cells as non-rendered reservations, preserving
  encounter determinism while removing only the visible obstruction.

## Validation ledger

- Focused gate: `test_first_hollow_setpiece_breathing.gd` passes 6/6.
- Canonical native gate: 904/904 assertions across 17 suites.
- Retained direct-entrypoint audit: 120/127 under the established strict
  30-second watchdog. The same three long-running fixtures timed out and the
  same four historical driver/repro exceptions failed; every entrypoint that
  loads the changed generator/rendering seam passed.
- Repeated production movement sampling established that its marginal
  30-physics-frame timing assertion is pre-existing variance: exact 0.1.12
  passed 4/8 samples, while this candidate passed 6/8. A green canonical sample
  is retained; no movement source or expectation changed.
- Native rendered comparison accepted at 1280×720. The larder keeps low
  perimeter supports while the former U-shaped boulder barricade and room-mouth
  pinch are absent under the continuous FATE camera.
- Web resource audit: 112/112 from a 105,926,096-byte PCK; SHA-256
  `53e32814f232d775355572878864935f0c1d54812fa3feba929f4c32cb38efac`.
- Exact browser route: title → town → world → complete in 25.701 seconds;
  diagnostic ledger empty.
- Companion-site publication receipt pending the source commit.
