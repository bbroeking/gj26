# Spec 77 implementation notes — Gathered Arrival checkpoint

## Decisions

- Resume from shipped `0.1.16-shaded-home`; its exact public versioned build is
  the visual and technical baseline.
- Treat framing as the next single authority. The yard's content and layout are
  held fixed so rendered play can show whether camera composition alone closes
  enough of the approved Arrival gap.

## Deviations

- None.

## Tradeoffs

- Accepted 38° pitch, 20.5 m distance, and 3.5 m forward framing. Pulling back
  farther weakened the ranger's authored scale; a larger forward offset made
  the south road feel detached from the player. The accepted frame shows the
  north-landmark bases without turning Town into a top-down map.
- Camera composition cannot supply the concept's dense landmark staging. It
  now exposes that gap honestly for a later checkpoint.

## Surprises

- The clearer Shaded Home replay made the layout gap look larger because value
  separation no longer disguised how little architecture enters the first
  controllable frame.

## Followups

- Judge landmark staging and foreground cover only after the accepted camera
  profile is replayed; do not bundle either into this checkpoint.

## Validation ledger

- Approved comparison:
  `docs/concept-art/gameplay-direction/wayfinder-state-01-arrival.png`.
- Baseline Web comparison:
  `docs/playtests/shaded-home/after-compatibility.png`.
- Focused Town framing contract passes 8/8 against the real 1280×720 Camera3D
  projection. Tonal grade 10/10, boot 148/148, movement 14/14, transitions
  125/125, and save roundtrip 120/120 pass after the accepted frame.
- The complete canonical gate passes 21 suites and 1,004 assertions. A highly
  concurrent stress run caused the existing movement and cutaway timing budgets
  to miss under CPU contention; both suites passed immediately when rerun
  serially, which is the canonical invocation.
- The Web export audits all 118 required resources. Native Forward+ and a real
  1280×720 browser arrival agree on composition, and the enhanced fail-closed
  route passed `title → town → chart_table → codex → chart_table_closed → world
  → complete`. The exact PCK is 96,121,600 bytes with SHA-256
  `af1d1ff69fb2c47dd2e71a38816ff1b1c52b5552c80b05e9b8aa68d738edc9bd`.
- Source checkpoint `ea09704d099269a62782070d88e8e1fbd7aad206` and GitHub
  Pages deployment `9bcd14278c8c552fc62f5cfc892ec2a9ad3f7d17` are pushed.
  Stable `/play/` redirected to `v0.1.17`, and the exact hosted route passed.
- Owner-only companion Field Journal version 17 deployed successfully from
  source `f13148e22aa4ab1379ead73e7fb0e1418dabb8a8`; its page, rendered
  arrival, playable export, assertion receipt, and fingerprint were verified.
