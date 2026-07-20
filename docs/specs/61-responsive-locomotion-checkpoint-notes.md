# Spec 61 implementation notes

## Diagnosis

The red baseline reproduced five movement failures using production input and
rendering seams: 11 frames to 90% speed, 3.73 m travelled in the first second,
30 frames of roll commitment, 4.99 cm generic creature lift, and no bounded
creature-turn seam.

The causal hypothesis was the shared locomotion response, not encounter
density or camera composition. The tuning history confirmed the player and
camera had intentionally been slowed for “cozy weight,” while enemy facing was
written as an exact per-frame assignment.

## Result

The same test is green at 1280×720 using production W and Space actions, then
repeats inside the seeded Bold Road with a real player, camera, NavigationAgent,
and creature body. The rendered capture is
`docs/playtests/movement-checkpoint/responsive-locomotion.gif`.

The unrelated Basic Shot/breakable arity error surfaced when an early version
of the movement harness fired F into scenery. It was removed from this focused
checkpoint rather than expanding scope; the existing 75-check Skill gate remains
the Basic Shot regression owner.

