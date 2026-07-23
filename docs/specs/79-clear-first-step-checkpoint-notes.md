# Spec 79 implementation notes — Clear First Step checkpoint

## Decisions

- Resume from the exact hosted `0.1.18-working-edge` build. Its normal fresh
  journey, not a QA query, exposed the missing immediate control line.
- Reuse the existing objective hint and recovery stages. The checkpoint changes
  one string-selection branch rather than creating another guidance surface.

## Deviations

- None.

## Tradeoffs

- Keep the compact keyboard line visible until Mara's conversation. The
  established site explicitly presents the current Web build as keyboard and
  mouse; introducing a new last-device prompt service would turn this bounded
  clarity fix into a controls-system checkpoint.

## Surprises

- The current First Road slice is already substantially simpler than the older
  seven-step tutorial: Mara gives one Kind/Bold Chart directly, then the player
  crosses, learns bow and roll, and returns. The clearest gap was disclosure of
  existing controls, not another reduction in systems.

## Followups

- Complete the existing Spec 55 cold-human gate with three native first-time
  participants and one Web participant. Automated rendered play can validate
  delivery and timing logic, but not unaided comprehension.

## Validation ledger

- Shipped baseline: public `0.1.18-working-edge` normal fresh journey.
- The baseline first-controllable frame showed the Mara objective with no
  control line. Waiting through the recovery clock exposed the landmark line at
  20 seconds and `WASD` / `E` plus the gold needle at 35 seconds.
- Focused First Road gate: 17/17 assertions, including immediate, contextual,
  and direct-recovery guidance stages.
- Canonical checkpoint gate: 1,019/1,019 across 22 suites. The two
  timing-sensitive suites passed serially: movement feel 14/14 and Hollow
  readability 9/9.
- Guarded save roundtrip: 120/120.
- Native Forward+ and real Chromium evidence:
  `docs/playtests/clear-first-step/after-native.png` and
  `docs/playtests/clear-first-step/after-web.png`.
- Real local browser enhanced journey: title → town → chart table → codex →
  chart table closed → world → complete, with no reported error.
- Web release-resource audit: 118/118 resources from a 96,120,912-byte PCK
  with SHA-256
  `57fa0f9601b4c6e13f82e47cf5fff0819fe9e316d134cbc76541f856e6808fa7`.
