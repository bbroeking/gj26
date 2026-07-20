# Spec 60 implementation notes

## Decisions outside the approved direction

- The choice lives in Mara's existing Field Journal dialogue instead of a new
  Chart Table screen. This keeps the opening on rails and proves authorship
  before investing in another UI surface.
- The teaching road reuses the `snug` biome language and production enemy cast,
  but has its own `first_road` template and a strict four-to-five-room budget.
- The compact seed can use its only `combat` tag for the teaching rat. Marked
  Company therefore claims the deepest non-entry/non-boss room when no later
  combat-tagged room exists; the Affix promise outranks decorative room typing.
- First Road-only tuning Affixes are registered for presentation but excluded
  from the stochastic Affix roll order. Later Charts cannot roll tutorial knobs.
- Save version remains v2 because all slice state is stored in existing optional
  `seen_hints` and Chart dictionaries. The playable application version is
  `0.1.0-first-road`.

## Verification record

- Editor/boot parse: green, 146 checks.
- Slice acceptance: green, 14 checks, including both real World builds and the
  returned Town lamp projection.
- Full required gate: green, 827 checks across six suites (426 + 41 + 125 +
  75 + 146 + 14).
- Visual captures live in `docs/playtests/first-road/`.
