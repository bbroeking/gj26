# 26 — MapleStory combat juice + snappier projectiles

> **Outcome**: combat *hits*. Damage numbers become a big, popping, colour-tiered spectacle; arrows crit; every hit throws a spark, a shake, and a sound; projectiles are snappier. The reference is MapleStory's "fireworks show" damage feel — full maximalism, consciously louder than Bramblewood's cozy framing.

## Why

gj26's hit feedback is a flat `Label3D` that drifts up and fades — informational, not satisfying. A grill (this conversation) chose **full MapleStory maximalism**: the damage number is the *hero* of the feedback. Research on why MapleStory's combat is so satisfying — bright flashy hits, aggressive audio, screen-filling numbers, a dopamine loop firing hundreds of times a session. ([Parkzer on MapleStory](https://parkzer.com/2024/01/09/maplestory-one-month/))

## Scope

### A. Crit system
- `combatant.take_damage()` rolls a crit on every hit: **~20%** chance → **×2** damage; a rarer **~4%** "super-crit" → **×3**.
- The crit tier (`normal` / `crit` / `super`) is passed through to the damage number + the feedback (spark, shake, sound all scale with it).
- Crits apply to **player → enemy** hits (arrows). Enemy → player stays flat for v1.
- Crit chance / multipliers are tunable consts.

### B. Damage-number rework — the maximalist number
Rework `DamageNumber` (`damage_number.gd` + `.tscn`):
- **Pop** — spawns with a hard scale-punch (0 → ~1.3 → 1.0 over ~0.12s), not a fade-in.
- **Scatter** — then bursts up + outward on a slight random arc, fading fast (~0.6s).
- **Colour tiers** — `normal` cream-white · `crit` gold · `super` purple. Chunky bold numerals with a thick dark outline so they read against any background.
- **Crit scale** — crit numbers spawn bigger; super-crits bigger again + a brief hang.
- The cascade is free: rapid fire already throws numbers in sequence (grill Q4=B); each is now individually juicy.

### C. Hit spark + screen shake
- **Hit spark** — a short particle burst at the contact point on every hit (a puff of bright motes — gold for crits). A reusable `GPUParticles3D`-based one-shot.
- **Screen shake** — `camera_rig` gets a shake impulse on hits; amplitude scales with crit tier (normal small, super big). Decays fast.

### D. Audio — ElevenLabs-generated SFX
- Generate 4–5 SFX via the **ElevenLabs text-to-sound-effects API** (`POST /v1/sound-generation`), key from `.env` (`ELEVENLABS_API_KEY`):
  - `fire` — a bow loose / arrow whoosh
  - `hit` — an arrow thunk into an enemy
  - `crit` — a bigger, juicier impact
  - `enemy_death` — a defeat sound
- Save to `godot/audio/*.mp3`; a small `sfx` autoload plays them via pooled `AudioStreamPlayer`s.
- Wire: fire → on `_fire_arrow`; hit/crit → on `take_damage` by tier; enemy_death → on `_die`.
- **Cost gate:** ElevenLabs SFX generation costs credits — confirm the count with the user before generating.

### E. Snappier projectiles
- Arrow `SPEED` **20 → 34** m/s.
- Player `FIRE_COOLDOWN` **0.4 → 0.28** s (also densifies the number cascade).

### F. Verify
- `test_combat` 20/20, `test_movement` 6/6 still pass (add eval coverage: a crit eventually rolls; the damage number carries a tier).
- Boots clean; a play-test confirms the feel.

## Out of scope
- Multi-hit attacks (grill Q4=B — cascade comes from fire rate, not multi-hit).
- Enemy → player crits.
- A full game-audio pass (music, ambience, footsteps) — this spec is *combat* SFX only.
- Damage-number font *art* beyond a styled built-in font + outline.

## Files

| Path | Action |
|---|---|
| `godot/scripts/combatant.gd` | crit roll in `take_damage`; tier → feedback |
| `godot/scripts/damage_number.gd` + `scenes/DamageNumber.tscn` | pop/scatter/colour-tier rework |
| `godot/scripts/arrow.gd` | `SPEED` 34 |
| `godot/scripts/player_controller.gd` | `FIRE_COOLDOWN` 0.28; fire SFX |
| `godot/scripts/camera_rig.gd` | screen-shake impulse + decay |
| `godot/scripts/sfx.gd` + autoload | new — pooled SFX player |
| `godot/scripts/hit_spark.gd` + scene | new — one-shot particle burst |
| `godot/audio/*.mp3` | new — ElevenLabs-generated SFX |
| `godot/test_combat.gd` | crit + tier eval coverage |
| `docs/GODOT_PIPELINE.md` | update |

## Acceptance criteria
1. Hitting an enemy throws a number that *pops* (scale-punch) and scatters, not a gentle drift.
2. Crits visibly read bigger + gold; super-crits bigger + purple.
3. Every hit fires a spark + a screen shake + a sound, scaled by crit tier.
4. Arrows travel noticeably faster; the fire cadence is snappier.
5. ElevenLabs SFX play on fire / hit / crit / enemy-death.
6. `test_combat` 20/20 · `test_movement` 6/6 · boots clean.

## Open decisions
- **Crit values** — 20%/×2, 4%/×3 are starting points; tune by feel.
- **Number font** — a bold Godot built-in font + thick outline for v1; a bespoke hand-drawn numeral set is a followup.
- **SFX prompts** — I'll draft the ElevenLabs prompts; the user can react before generating (and approves the credit cost).
- **Shake budget** — screen shake on *every* hit can nauseate; normal-hit shake stays subtle, crits punch.

## References
- The grill that produced this plan (this conversation)
- Research: [MapleStory damage feel](https://parkzer.com/2024/01/09/maplestory-one-month/)
- Spec 14 — the existing hitstop / flash / knockback / damage-number layer this builds on
- `combatant.gd`, `damage_number.gd`, `arrow.gd`, `camera_rig.gd`

## Done check
- [ ] Crit system in `take_damage` (chance, multipliers, tier)
- [ ] Damage number — pop + scatter + colour tiers + crit scale
- [ ] Hit spark particle burst
- [ ] Screen shake, crit-scaled
- [ ] ElevenLabs SFX generated + wired (fire/hit/crit/death)
- [ ] Arrow speed 34 · fire cooldown 0.28
- [ ] Evals green · boots clean · play-tested
- [ ] `GODOT_PIPELINE.md` updated
