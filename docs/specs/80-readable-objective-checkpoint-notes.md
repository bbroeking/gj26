# Spec 80 implementation notes — Readable Objective checkpoint

## Decisions

- Limited the first pass to the objective component. The screenshot establishes
  a concrete readability problem there; a global HUD scale change would alter
  unrelated accepted surfaces without equivalent evidence.
- Targeted a 372-pixel plate, 18-pixel objective, and 16-pixel guidance line:
  approximately one visual step above the shipped 320/16/14 treatment.

## Deviations

- None.

## Tradeoffs

- Kept the existing single-card information model for this pass. Separating
  objective, input chips, and recovery whispers may still improve composition,
  but it is a different design decision from the requested size and visibility
  correction.

## Surprises

- The content-hug calculation used fixed line increments tuned to the old type
  sizes, so increasing fonts without retuning height would clip or crowd the
  bottom guidance line.

## Followups

- Compare the rendered first-control, 20-second, and 35-second states before
  deciding whether guidance should become a separate attached component.

## Validation ledger

- Player-supplied baseline:
  `docs/playtests/readable-objective/before.png`.
- Native immediate frame:
  `docs/playtests/readable-objective/after-native.png`.
- Real Web immediate, 20-second, and 35-second frames:
  `docs/playtests/readable-objective/after-web-immediate.png`,
  `after-web-recovery.png`, and `after-web-direct.png`.
- Focused semantic/readability contract: 36/36.
- Canonical checkpoint gate: 1,055/1,055 across 23 suites, with movement feel
  14/14 and Hollow readability 9/9 confirmed serially.
- Guarded save roundtrip: 120/120.
- Web release audit: 118/118 resources from a 96,120,928-byte PCK with SHA-256
  `619b5db4494e1abd2bac1db740da7f0c6cb0072b8e52ccbd7f6ba8c0bd77c555`.
- Real Web immediate and timed recovery states produced no warning or error.
