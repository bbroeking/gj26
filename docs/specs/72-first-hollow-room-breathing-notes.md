# Spec 72 implementation notes — First Hollow room breathing

## 2026-07-20 — checkpoint opened

- Exact 0.1.11 native replay confirmed that archetype-specific stump,
  fairy-ring, bramble-arch, and fallen-log compositions hold under movement.
- The leading independent weakness was interior support bulk: the forest fern,
  toadstool, and boulder meshes each measured roughly 1.9 floor tiles across at
  native scale, creating barricade-like clusters around entrances.
- The separate in-progress replacement Chest and creature work in the primary
  worktree remains user-owned and untouched.
- Chosen seam: authored satellite rules carry explicit visual scale into decor
  data, and satellite placement protects a directional landing just inside
  each actual corridor mouth. Landmarks remain full-size; later biomes retain
  their existing composition contract.

## Validation ledger

- Focused room-breathing test: 5/5; existing composition, placement, and room
  grammar suites remain green.
- Canonical gate: 898/898 across sixteen suites.
- Strict retained audit: 119/126 under a 30-second-per-entrypoint watchdog. The
  same three known long driver fixtures timed out and four documented
  driver/repro/legacy-movement fixtures failed as in the preceding 118/125
  corpus; every test loading the changed seam passes.
- Native play: moved and fought through the exact Bold seed at the continuous
  FATE angle. Full-size landmarks held while support clusters and entrance
  landings opened visibly beside the approved concept.
- Web play: the exact export completed title → town → generated road → return
  in ordered history with an empty diagnostic ledger.
- Export audit: 112/112 resources; 105,925,552-byte PCK; SHA-256
  `097269870847107143037a5fd35054fe2937616ea65f04a26a6225c7b5a70a66`.
- Render evidence: `docs/playtests/first-hollow-room-breathing/`.
- Companion Field Journal publication is pending the game commit and exact
  release receipt.
