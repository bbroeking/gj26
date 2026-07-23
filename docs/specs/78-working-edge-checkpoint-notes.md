# Spec 78 implementation notes — Working Edge checkpoint

## Decisions

- Resume from shipped `0.1.17-gathered-arrival`; its exact public native/Web
  frame is the baseline.
- Hold the accepted camera and grade fixed. This checkpoint tests landmark
  staging as its single visual authority.
- Keep the buildings as the supporting band and Mara/ranger as the saturation
  and silhouette priorities; no landmark may claim the central crossing.
- Accepted cottage `(10.5, 10.0)`, tower `(20.5, 8.5)`, and smithy
  `(31.5, 10.0)` on the yard's X/Z plane. The cottage and smithy doors now
  enter the frame while the taller tower stays slightly recessed.
- Re-expressed the drying rack, practice dummy, Atlas board, two cottage log
  piles, and forge ore cluster from their owning landmark positions. Their
  actual roles and relative arrangements are unchanged.

## Deviations

- None.

## Tradeoffs

- A first smithy trial at `(30.5, 10.5)` looked balanced but left only 0.51 m
  between its broad collider and the Waystone center. Moving it one metre east
  and half a metre north retains the visible door with 1.62 m of approach
  clearance. Recessing the tower by half a metre similarly preserves more than
  one metre around the later practice space.
- Roofs remain partly cropped at the top of the established FATE frame. The
  accepted checkpoint prioritizes doors, lower facades, and working clusters;
  changing camera composition again would erase the single-authority test.

## Surprises

- The new camera did not reveal missing assets. It revealed that existing
  building-owned NPCs and props were authored through mixed relative and fixed
  coordinates, weakening the visual cluster and making future moves risky.
- The first save-roundtrip invocation omitted its required `WYRD_NO_SAVE=1`
  guard and overwrote the local developer profile plus its backup with a test
  fixture. Both resulting files were preserved under dated
  `wayfinder_save.test-overwrite-*` names; no older recoverable copy was found.
  The suite now refuses to start without the guard, and its guarded and
  unguarded paths both prove the live-profile hash is unchanged. Profile
  disposition remained an explicit release blocker rather than being guessed.
- On 2026-07-23 the owner resumed publication and onboarding work, resolving
  the overwritten profile as disposable development state. The dated recovery
  copies remain untouched for provenance; they are not part of the release.

## Followups

- Judge foreground cover only after the accepted working edge ships; it is not
  a substitute for coherent landmark placement.

## Validation ledger

- Approved comparison:
  `docs/concept-art/gameplay-direction/wayfinder-state-01-arrival.png`.
- Shipped baseline:
  `docs/playtests/gathered-arrival/after-web.png`.
- Shipped 0.1.17 native rendered movement and Web first-arrival replays were
  completed before implementation. The strongest shared gap was the separated,
  clipped north-landmark band.
- Accepted local native evidence: `docs/playtests/working-edge/after-native.png`.
- Accepted local Web evidence: `docs/playtests/working-edge/after-web.png`.
- New composition contract: 12/12 assertions.
- Full canonical gate: 1,016/1,016 assertions across 22 suites; the movement
  and Hollow-readability timing suites passed serially.
- Save compatibility: 120/120 with `WYRD_NO_SAVE=1`; live-profile SHA-256
  remained `b580012d539d05afd069a50267aa583af0ef69abfbd5f789881415343e1b6f51`.
- Browser smoke: title → town → chart table → world → complete, status
  `passed`, with the accepted first-arrival frame visually inspected.
- Export audit: 118/118 release resources from a 96,122,864-byte PCK; SHA-256
  `434e77f85b76b5ae900766188055ae95971cbb38d5648eca19b01919956ef521`.
- Publication and companion-site verification are the remaining gates.
