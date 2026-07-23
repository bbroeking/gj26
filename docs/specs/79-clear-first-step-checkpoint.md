# Spec 79 — Clear First Step checkpoint

## Player-visible problem

The exact hosted `0.1.18-working-edge` fresh journey gives the player one clear
destination—Mara—but no movement or interaction control. The first contextual
line appears only after 20 seconds, and `WASD` / `E` only after a 35-second
stall. This contradicts the accepted first-session storyboard, which asks the
opening to teach movement immediately and reserve the gold needle for recovery.

## Promise

A fresh player sees the two controls needed for the first objective as soon as
Town returns control: move with `WASD`, talk with `E`. The line remains part of
the existing objective plate, while the contextual landmark and gold needle
retain their current timed escalation.

## Scope

- Give tutorial step 0 one immediate, compact `WASD move · E talk` hint.
- Preserve the 20-second Mara landmark nudge.
- Preserve the 35-second direct destination plus gold-needle recovery.
- Extend the First Road acceptance gate across all three guidance stages.
- Replay the exact fresh opening in native and Web builds.

## Boundaries

- Add no modal, tooltip system, quest, marker, destination, tutorial mode,
  telemetry field, input binding, or content.
- Do not change the arrival vignette, camera, Town staging, Mara dialog, the
  Kind/Bold choice, Chart contents, Waystone flow, combat lesson, or return.
- Do not reveal the gold needle before a prolonged stall.
- Do not add combat, inventory, Trade, Affix, or crafting instructions to the
  first objective.

## Acceptance

- On the first controllable 1280×720 Town frame, the objective plate shows
  `WASD move · E talk`.
- Before 20 seconds, no compass is present.
- At 20 seconds, the line changes to the existing Mara landmark nudge without
  revealing the compass.
- At 35 seconds, the existing direct control/destination line and compass
  appear.
- The canonical gate, guarded save roundtrip, release-resource audit, native
  rendered play, real browser play, diagnostic ledger, and release chain pass.
