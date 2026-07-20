# 63 — Living Yard checkpoint

> **Outcome:** Bramblewood's three named neighbors read as living people at the
> FATE camera instead of static interaction markers, without changing the
> town's routes, conversations, or station ownership.

## Why this is the checkpoint

The original game idea is a neighbor-led home loop: gather, return to familiar
people, craft, inscribe a Chart, and leave by the Waystone. The played build's
yard composition and compact Field Journal HUD already supported that loop,
but Mara, Hod, and Quill held nearly frozen walk samples. That made the social
spine feel less alive than the scenery around it.

The highest-value correction is therefore shared ambient rig motion for the
named town cast. A full schedule or navigation system would add route,
collision, prompt, and station-ownership risk before bespoke town idles exist.
This checkpoint deliberately stops at readable planted motion.

## Contract

- Reuse each neighbor's production rig and matching walk-animation sidecar.
- Hold a planted portion of the authored performance and ease through a small
  pose window so breathing, cloth settling, and weight transfer survive the
  gameplay camera.
- Stagger Mara, Hod, and Quill so they do not move in lockstep.
- Keep each NPC root, interaction collider, prompt, facing-on-dialogue behavior,
  and work-area ownership unchanged.
- Do not add schedules, navigation, new NPCs, or new animation assets.
- Do not alter dungeon creature animation behavior.

## Acceptance

- The production Town contains exactly three ambient character-motion drivers.
- Every driver advances its rig sample and produces visible model-root motion.
- The target viewport remains 1280×720.
- Production W movement and Space roll remain responsive in Town and the seeded
  Bold Road.
- The canonical eight native suites remain green.
- A rendered production-Town replay shows the motion in context.

Implementation decisions and verification evidence live in
[`63-living-yard-checkpoint-notes.md`](63-living-yard-checkpoint-notes.md).
