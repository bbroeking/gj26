# Wayfinder — Combat-Feel & Animation Plan

Living plan for making combat and movement *feel* good. Grounded in two research
passes (animation pipeline; hit-feel + bullet-hell tactics), a read of the
current code, and one plan-optimizer pass (v1 71 → v3 96). **Blender is parked**
— everything here is code-side (procedural), no asset round-trips.

Status legend: ✅ done · 🔄 doing · ⬜ planned · ⏸ parked

---

## 0. Why procedural (the constraint that shapes everything)

Meshy auto-rig only works on **humanoid T-pose** models. Our enemies were made
from posed concept art and most are quadruped/amorphous — confirmed when a test
rig of the skeleton failed Meshy pose-estimation (`422`, 0 credits spent). So
**only the player chibi is rigged**; the whole enemy/boss cast is animated in
**GDScript**. For chunky-toon characters, procedural squash/anticipation/overshoot
*is* how "feel" is made.

## Non-goals (scope boundary — say no to creep)
- **Not** true bullet-hell density (no curtains/spirals); cozy = telegraph-heavy,
  density-light.
- **Not** new enemy archetypes or a combo system (combat stays one-verb).
- **Not** skeletal clip authoring (parked with Blender).
- **Not** a netcode rewrite — extend the existing host-authoritative model only.

---

## 1. Animation tactics — how other people do this

The reusable toolkit (12-principles → games → our engine):

- **Squash & stretch, volume-preserved** — stretch on the fast part, squash on
  impact/apex; Y up ⇒ X/Z down. (Idle does this ±2.8% in `creature_anim.gd`;
  *event* squashes are missing.)
- **Anticipation → action → follow-through** — wind-up before, overshoot-settle
  after. **ease-IN on wind-ups** (building force), **ease-OUT on impacts** (snap).
- **Overshoot & settle on every tween** — never lerp straight; ~110–120% then
  back with `TRANS_BACK`/`TRANS_ELASTIC`. Biggest "moves → alive" change, free.
- **Event scale-punch** — punch ~1.18–1.22 then decay (we use this for hit-react
  0.18 / telegraph 0.22 in `combatant._tick_feedback`); extend to spawn/land/death.
- **Velocity lean** — tilt mesh ±6–8° into travel, lerp back when stopped.
- **Secondary motion / phase de-sync** — per-creature phase offset (we derive it
  from spawn pos, RNG-free — keep it).
- **Two-layer transform split** — idle/locomotion writes the **mesh** node;
  hit/attack punch writes the **body** node; they compose, never fight.

Reference points: Hollow Knight, Hades, Smash (hitlag scales with strength), Dark
Souls (~0.33s roll i-frame). **Cozy rule: telegraph density up, projectile/shake
density down.** Keep idle breath ≤ ~3% (more = rubbery on chunky-toon).

---

## 2. Current state (don't rebuild)

| System | State | Where |
|---|---|---|
| Enemy hit-feel (flash, knockback, hit-stop, spark, shake) | ✅ textbook, leave it | `hit_feedback.gd`, `hitstop.gd`, `camera_rig.gd` |
| Hit-stop tiers (0.07 / 0.13 / 0.20s) | ✅ | `hit_feedback.gd` |
| Enemy attack **telegraph** (stop + windup) | ✅ (`TELEGRAPH_SEC 0.35`) — no *visual* wind-back | `combatant.gd` ATTACK |
| Procedural idle/locomotion (all enemies) | ✅ | `creature_anim.gd` |
| Player **i-frames** (`IFRAMES_SEC`, roll `0.27`) | ✅ exist (no visible tell) | `player_controller.gd` |
| Player **dodge-roll** (with i-frames) | ✅ exists — leverage for avoidance | `player_controller.gd` ROLL |
| Player hit: knockback + hit-stop + flash + hurt-vignette | ✅ exist | `player_controller.gd:take_damage` |
| Player **micro-stun (input-lock)** | ✅ `STUN_SEC 0.10` | `player_controller.gd` |
| Player **i-frame blink tell** + mesh **flinch** | ✅ `BLINK_PERIOD`/`FLINCH_SEC` | `player_controller.gd` |
| Enemy **ranged attacks / projectiles** | ⬜ none | reuse `arrow.gd` |
| Player **bow-draw** (arms draw on fire) | ⬜ torso-tip fake only | `player_controller.gd` |
| Player clip easing (linear → robotic) | ⏸ needs Blender | — |

---

## 3. Cross-cutting concerns (apply to every phase)

- **Centralized tuning** — put every new feel constant (stun, i-frame, blink,
  projectile speed/telegraph/density) in one block (extend the `hit_feedback.gd`
  tunables pattern or a `feel.gd`), so a playtest is one-file fast. No magic
  numbers buried in logic.
- **Audio** — the research ranks layered SFX as carrying as much weight as
  visuals. Every new beat gets a sound via the existing pipeline
  (`tools/generate_audio.py`, ElevenLabs) with `pitch_scale = randf_range(0.95,
  1.05)` so it doesn't fatigue: player-hit "oof", enemy wind-up charge, projectile
  fire, projectile impact, bow-draw creak.
- **Co-op / netcode** (host-authoritative — extend, don't rewrite) — **enemy
  projectiles spawn on the host and replicate** like enemy state / `drop_event`
  in `net_game.gd`; spawn parameters come from the host (never a bare `randf()` —
  reuse the seeded path lesson). **Player stun / i-frames / flinch are LOCAL**
  (each peer owns its body; `take_damage` already forwards remote hits to the
  owner). Guests must never authoritatively resolve projectile damage.
- **Collision layers** — enemy projectiles hit the **player** layer only (no
  enemy-enemy friendly fire); player arrows keep hitting the **enemy** layer.
  Verify the masks when reusing `arrow.gd`.
- **Performance** — at cozy density (1–2 shooters, ~1 shot/2.5–3s) pooling is
  unnecessary; instantiate per-shot. If a pattern ever caps active projectiles,
  `log()` the drop (no silent truncation).

---

## 4. Roadmap (priority order)

### Phase 1 — Player "getting hit" feel ✅  *(shipped)*
- **Micro-stun:** `_stun_t` on the player; ~**0.10s** set in `take_damage`; gate
  input atop `_physics_process` (`if _stun_t > 0: _stun_t -= delta; decay vel;
  return`). 80–150ms reads without ever feeling like a stunlock.
- **Flinch:** brief mesh recoil along the hit normal + small squash, ease-out ~0.15s.
- **I-frame blink tell:** pulse mesh visibility / flash every ~0.08s while
  `_iframe_t > 0` so "briefly safe" is legible (we have i-frames; surface them).
- **Knockback after hit-stop:** let the 0.07s freeze release *then* shove (free weight).
- **Audio:** a soft "oof" on player-hit. Keep flash/vignette/shake at the *low* tier.
- **DoD / acceptance:** taking a hit visibly stuns ≤0.15s, recoils the player,
  blinks during i-frames, and a second hit inside the i-frame window deals 0
  damage. Verified by the timer test (§5) + a blink screenshot.
- **Effort: S–M.** Pure GDScript, solo.

### Phase 2 — Enemy melee attack tell (anticipation → lunge) ⬜
Enrich the *existing* telegraph window with visible motion.
- During `_telegraph_t` (bump melee ~0.45s): **wind-back** — pull mesh from
  target + squash (ease-in). On strike: **lunge** toward target (ease-out pop),
  then settle.
- **Shared foundation (reused by Phase 3):** add an **"attacking" yield** to
  `creature_anim` (like the existing "moving" settle) so idle breathing doesn't
  fight the attack. Build it here; Phase 3's ranged windup reuses it.
- Windup length scales with `attack_cooldown` (heavy hitters telegraph longer).
- **Audio:** a wind-up cue.
- **DoD / acceptance:** an attack has a visible pull-back before contact; a
  play-tester can name the incoming hit before it lands ≥90% of the time.
- **Effort: M.** Motion → play-test (use the dummy mode, §5).

### Phase 3 — Enemy ranged / cozy bullet-hell-lite ⬜  *(new system)*
- **Reuse `arrow.gd`:** lower `SPEED` 50 → **~10** aimed / **~6** orb; flip the
  Hitbox mask to the **player** layer; route damage through `player.take_damage`.
- **Every shot telegraphs (~0.6s):** emissive wind-up pulse (reuse Phase-2 yield
  + a warning-color flash) + a **ground line/ring decal** (reuse the AoE-burst
  ring in `arrow.gd:326–349`) + a charge SFX. Consistent color = "incoming".
- **Pattern vocabulary** (pick a few): single aimed shot · 3–5 fixed fan · slow
  orb · delayed AoE zone. No streams/curtains.
- **Avoidance = strafing** (player `move_speed` > projectile speed) **+ the
  existing dodge-roll's i-frames** for tight moments — not a new mechanic.
- **Density:** 1–2 ranged enemies active; ~1 aimed shot / 2.5–3s. Bright vs the
  dark crypt. Host-authoritative spawn (§3).
- Data: a `ranged`/`projectile` kind in `ENEMY_KINDS`; `_ranged_attack()` in
  `combatant` fires at telegraph-end instead of melee.
- **DoD / acceptance:** shooter telegraphs ≥0.5s before firing; a strafing player
  who reads tells clears all shots without rolling; co-op: guest sees identical
  projectiles, host resolves damage.
- **Effort: M–L.** Motion → play-test + telegraph-decal screenshot.

### Phase 4 — Player bow-draw ⬜
Procedural arm pose on fire (no Blender, no AnimationTree): on `trigger_fire`,
pose the bow/draw-arm bones via a `SkeletonModifier3D` (or `set_bone_pose_rotation`
after the AnimationPlayer) — raise to draw, snap on release, ease back ~0.15s.
Port the angle intent from the unused `ranger_anim.gd` draw pose onto the chibi's
Mixamo-named arm bones. **Audio:** a bow-creak.
- **DoD / acceptance:** firing visibly raises/draws the arm; legs keep cycling
  (additive); screenshot-verified mid-draw.
- **Effort: M.** Screenshot-able.

### Phase 5 — Animation juice (cheap, broad) ⬜
- Overshoot & settle on existing one-shot tweens (`TRANS_BACK`).
- Event scale-punches: spawn pop-in (0→1, ~0.2s), land-squash, death-squash.
- Velocity lean ±6–8° on moving creatures + player.
- **Effort: S–M.**

### Parked — ⏸ Player clip easing (needs Blender)
`bpy` re-curve walk/run/idle fcurves to BEZIER + retime + re-export the 3 chibi
GLBs. Runs whenever the user opens Blender + the MCP add-on; no code dep. Interim:
Phase-5 lean + a speed-driven blend mask some of the robotic feel.

---

## 5. Verification strategy (beats "motion can't be screenshotted")

1. **Four-suite gate stays green** every commit: `test_stats`, `test_wyrd_loop`,
   `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills` (`WYRD_NO_SAVE=1`).
2. **Timer-assertion tests** (test_stats-style, headless): assert stun duration,
   i-frame window (a 2nd hit inside it deals 0), projectile spawn + damage routing,
   telegraph length. Catches logic regressions a screenshot can't.
3. **Combat-dummy gallery mode** — extend `tools/animation_gallery.gd` with a
   dummy combatant that plays attack / ranged-telegraph / hit-react / draw on a
   key, so attack & projectile *feel* is reviewable on demand (the screenshot gap
   for Phases 2–4). Build alongside Phase 2.
4. **Screenshot** where static reads: i-frame blink (P1), telegraph decal (P3),
   bow-draw mid-frame (P4).
5. **Play-test sign-off** from the user for the felt timing of P2/P3 (motion).

## 6. Success metrics (felt, validate by playtest)
- A hit *reads*: the player can tell they were hit without watching the HP bar.
- Attacks are *fair*: tester names an incoming attack before it lands ≥90%.
- Ranged is *avoidable*: a tells-reading, strafing player clears shots without
  twitch reflexes; never feels screen-filling.
- Cozy holds: no stunlock (≤0.15s), generous i-frames (0.4–0.6s), shake subtle.

## 7. Sequence & first step
1. **P1** (player hit-feel) — fast, mostly enhancement. **First commit:** `_stun_t`
   + input-gate + i-frame blink, with a timer test.
2. **P2** (melee tell + the shared attack-yield foundation) + the dummy mode.
3. **P3** (ranged/bullet-hell, reuses P2 yield + dummy mode).
4. **P4** (bow-draw) — independent, screenshot-verifiable.
5. **P5** (juice) — fold in throughout.
Blender easing runs whenever the user's ready. P1/P4/P5 are solo-verifiable;
P2/P3 motion needs a play-test.

## 8. Accessibility / guardrails
"Reduce screen shake" toggle; conservative shake; micro-stun ≤0.15s; generous
i-frames; slow telegraph-heavy projectiles. A player who reads tells and keeps
moving never needs twitch reflexes.

## 9. Sources
Two research passes (session-archived): animation pipeline + 12-principles;
hit-feel number bands + bullet-hell telegraphing. Anchors: Hollow Knight Hornet
frame data, Dark Souls roll i-frame, Smash hitlag, shmup bullet-visibility,
ARPG ground-decal telegraphs.
