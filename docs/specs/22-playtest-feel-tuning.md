# 22 — Playtest + feel-tuning pass

> **Outcome**: the combat that the eval harness proved *functions* gets confirmed (or corrected) for *feel* — a structured playtest of the browser build, then a tuning pass on the constants that came back wrong.

## Why

Every spec from 14 on has the same standing followup: "nobody has played it." The eval harness checks that hits register, hitstop fires, enemies aggro — but not whether the aggro radius *feels* right, the telegraph is *readable*, the knockback has *weight*, the fire cadence is *satisfying*. Those are human judgements. This spec makes that judgement structured and turns it into concrete constant changes.

## Scope

**In:**
- A **playtest checklist** — `docs/PLAYTEST.md` — one line per feel dimension, each with: what to check, the constant(s) that control it, the current value, and a rating field. Dimensions:
  - aggro radius — do enemies wake at a fair distance? (`AGGRO_RADIUS`)
  - telegraph readability — can you see an attack coming and react? (`TELEGRAPH_SEC`)
  - knockback weight — player + enemy (`KNOCKBACK`, `HIT_KNOCKBACK`)
  - hitstop — impact, not jarring? (`HITSTOP_SEC`)
  - fire cadence + input buffer (`FIRE_COOLDOWN`, `INPUT_BUFFER_SEC`)
  - move speed — player vs enemy (`SPEED`, `MOVE_SPEED`)
  - camera — distance/angle for the calibrated sizing (`ZOOM_DEFAULT`, `PITCH_DEFAULT`)
  - wall-occlusion — is the player ever lost behind a wall?
  - i-frames — fair, not exploitable? (`IFRAMES_SEC`)
  - difficulty — `ENEMY_HP`, `ENEMY_DAMAGE`, `PLAYER_HP`
- The **user plays** the browser build against the checklist and records ratings / notes.
- A **tuning pass** — apply the constant changes the playtest calls for. One round; re-playtest only if something is clearly still off.
- Re-run `test_combat.gd` after tuning — thresholds may need adjusting if a tunable moved materially.

**Out:**
- New mechanics or content — this is tuning only.
- Rewriting systems — if the playtest exposes a *structural* problem (not a constant), that becomes its own spec, not this one.
- Automated "feel" evals — feel stays a human call.

## Files

| Path | Action |
|---|---|
| `docs/PLAYTEST.md` | new — the checklist + recorded ratings |
| `godot/scripts/combatant.gd` | modify — tuned constants |
| `godot/scripts/player_controller.gd` | modify — tuned constants |
| `godot/scripts/camera_rig.gd` | modify — tuned constants (if needed) |
| `godot/test_combat.gd` | modify — threshold updates if a tunable moved |

## Acceptance criteria

1. `docs/PLAYTEST.md` exists, every dimension rated by the user.
2. Every constant the playtest flagged is adjusted.
3. `test_combat.gd` still passes after tuning.
4. The user signs off that combat *feels* right (or the remaining issues are filed as their own specs).

## Open decisions

- **Who plays** — this is inherently the user; the agent prepares the checklist + the build and applies the changes. The agent cannot self-assess feel.
- **How many rounds** — recommend **one** tuning pass; a second only if something is glaringly still off. Avoid endless tweak loops.
- **Structural vs tuning** — if a problem isn't fixable by a constant (e.g. "the camera occlusion approach is wrong"), file a new spec rather than forcing it here.

## ARPG inspiration

The feel bar is FATE / Diablo: movement and hits have **weight**, attacks
are **readable**, the camera sits at a comfortable ARPG distance, and the
moment-to-moment loop is satisfying before it's hard. Rate each dimension
against that bar.

## References

- Specs 14/15 — the combat systems + their tunables (the eval harness lists most)
- All the `const` blocks: `combatant.gd`, `player_controller.gd`, `camera_rig.gd`
- The browser build (spec 16) — what the user plays

## Done check

- [ ] `docs/PLAYTEST.md` checklist written
- [ ] User played + rated every dimension
- [ ] Tuning pass applied
- [ ] `test_combat.gd` passes post-tuning
- [ ] User sign-off on feel (or follow-up specs filed)
