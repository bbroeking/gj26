# Spec 60 — First Road vertical slice

Status: playable acceptance build (2026-07-20)

## Question

Does choosing the temper of a Chart make the next 5–10 minutes feel
meaningfully different while preserving Wayfinder's cozy, readable opening?

## Player path

1. Begin a New Journey and walk to Mara.
2. Choose one authored three-Affix Chart:
   - **Kind Road:** Paper-Thin Foes, Quiet Halls, Bramble Bloom.
   - **Bold Road:** Tyrannical, Marked Company, Gilded Hollow.
3. Socket the Chart at the Waystone.
4. Learn Basic Shot and roll against one normalized teaching rat.
5. Cross a seeded four-to-five-room road. The deepest eligible room is the
   pressure beat: an ordinary pack on Kind, a guaranteed elite company on Bold.
6. Reach the far Waystone and return.
7. Read the debrief, receive Power Shot, and see the First Road lamp physically
   added beside Mara.

## Rails and exclusions

- One player, one road, one layer, one return.
- Layout randomness remains deterministic from the Chart seed.
- No broad progression, content catalog, additional mode, co-op surface,
  crafting expansion, boss, or second branch.
- Existing saved journeys keep their current onboarding. New Journey owns this
  slice path.

## Acceptance

- Exactly one meaningful choice with exactly three presentable Affixes.
- The two choices differ in enemy vigor and elite frequency.
- Camera, movement, Basic Shot, roll, hit feedback, loot, and Waystones use the
  production implementations.
- One safe lesson target, one later pressure state, one physical return payoff.
- `test_first_road_slice.gd` passes alongside the five established gates.

## Debug routes

```bash
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=choice godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=kind godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=bold godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=returned godot --path wyrd
```
