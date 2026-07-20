# Spec 63 implementation notes — Living Yard

## Mismatch

The original idea makes Bramblewood an intimate, neighbor-led home base, and
the opening asks the player to notice and trust Mara before learning any other
system. In the played build, the village composition and tone already worked,
but Mara, Hod, and Quill held an almost static mid-stride sample. They read as
interaction props rather than people inhabiting their work areas.

## Focused decision

Use the three existing Meshy rigs and walk sidecars as a shared ambient motion
layer. Each neighbor eases through a planted pose window, with a restrained
root breath and weight shift that remains visible at the FATE camera. The
timings are staggered per character.

This checkpoint does not add schedules, navigation, new NPCs, new creatures,
or new animation assets. It deliberately preserves station positions, solid
collision, prompts, dialog facing, and the procedural idle/stride/attack layer
already used by dungeon creatures.

## Verification

- `test_movement_feel.gd`: 12/12 in the production Town and seeded Bold Road.
- Canonical eight-suite native gate: 844/844.
- Target viewport: 1280×720.
- Target production input gate retained: W movement and Space roll.
- Rendered replay: `docs/playtests/living-yard/living-yard.gif`.
