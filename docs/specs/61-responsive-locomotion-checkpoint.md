# Spec 61 — Responsive locomotion checkpoint

Status: playable checkpoint (2026-07-20)

## Feedback interpreted

The First Road felt sluggish, while creature movement felt chunky and lacked
flow. Against Wayfinder's original direction, the largest mismatch was that
“cozy” had been expressed as controller and camera latency. A FATE-style ARPG
with combat-as-one-verb needs immediate traversal; warmth belongs in the world,
pace between encounters, and forgiving readability.

## One checkpoint

Restore a responsive locomotion cadence across the player, camera, and existing
creature presentation without changing combat rules or adding content.

- Run: 4.0 → 5.2 m/s; acceleration: 12 → 28.
- Stop/reversal: 20/28 → 34/44.
- Roll: the same ~2.9 m displacement in 0.32 s instead of 0.45 s; recovery and
  invulnerability scale down with it.
- Camera follow: 6 → 12 with less predictive lead, keeping the player anchored.
- Player/rigged-creature crossfades: 0.15–0.20 s → 0.08 s.
- Generic creature stride: 5 cm at rate 9 → 10 cm at rate 12.
- Creature facing: instantaneous snap → bounded 12 rad/s steering.

## Preserved

- FATE camera angle, FOV, zoom, and visual language.
- WASD, Shift, Space, F, and controller bindings.
- Chart choices, room layout, enemy counts, stats, attack telegraphs, hit
  feedback, rewards, and village payoff.
- Roll distance and its punishable recovery proportion.

## Target acceptance

At the production 1280×720 desktop viewport:

- W reaches 90% run speed within seven physics frames.
- First-second W travel is at least 4.7 m.
- Space completes within 22 physics frames while travelling 2.7–3.2 m.
- Generic creature travel shows at least 9 cm of readable lift.
- Creature turns are bounded per frame instead of snapping.
- The same assertions pass inside the real seeded Bold Road.

```bash
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_movement_feel.gd
```

