# Spec 71 implementation notes — First Hollow room composition

## 2026-07-20 — checkpoint opened

- Exact 0.1.10 native replay confirmed Open Canopy holds: the wider corridor
  opening reads cleanly under the continuous FATE camera.
- The leading visible weakness moved to room identity. The shipped Bold Road
  still exposed generic `root_cellar`, `wine_rack`, and `ossuary` composition
  beneath its forest asset remapping.
- Chosen seam: bind arrival/combat room `theme` to the archetype already selected
  by the generator. This keeps composition data in the existing inspectable
  room-theme path instead of adding a parallel room-decoration system.
- Typed interaction rooms retain their existing focal themes so the Chest,
  Shrine, and Hearth realization contract is not disturbed.
- The fallen-log tint moved from grey-green to bark brown because the shipped
  prop read as pale crypt stone at FATE distance.

## Validation ledger

- Focused composition test: 5/5.
- Canonical gate: 893/893 across fifteen suites.
- Existing decor-placement, living-edge, cutaway/restoration, production scene,
  and procgen suites remain green; the stale procgen expectation was updated
  from old snug theme names to the new explicit `first_*` contract.
- Strict retained audit: 118/125 under a 30-second-per-entrypoint watchdog.
  Three long driver fixtures exceeded that artificial limit; the documented
  driver/repro and old movement exceptions remained. Every test loading the
  changed composition path passes.
- Native play: moved and fought through the shipped Bold seed at 1280×720. The
  central stage and route stayed readable while stump, mushroom, bramble,
  boulder, and log rhythms changed between rooms.
- Web play: exact export completed title → town → generated road → return in
  106.566 seconds with ordered history and an empty diagnostic ledger.
- Export audit: 112/112 resources; 105,924,736-byte PCK; SHA-256
  `f3ea722c0a716db7615d83250e9dacb305ff5fa81759445c8ea7ea9ca6f62509`.
- Render evidence:
  `docs/playtests/first-hollow-room-composition/`.
