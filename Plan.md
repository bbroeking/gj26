# Wayfinder — Combat-Feel & Animation Plan

Living plan for making combat and movement *feel* good. Grounded in two research
passes (animation pipeline; hit-feel + bullet-hell tactics) and a read of the
current code. **Blender is parked for now** — everything here is code-side
(procedural), no asset round-trips.

Status legend: ✅ done · �doing · ⬜ planned · ⏸ parked

---

## 0. Why procedural (the constraint that shapes everything)

Meshy auto-rig only works on **humanoid T-pose** models. Our enemies were made
from posed concept art and most are quadruped/amorphous — confirmed when a test
rig of the skeleton failed Meshy pose-estimation (`422`, 0 credits spent). So
**only the player chibi is rigged**; the whole enemy/boss cast is animated in
**GDScript**, not skeletal clips. That's not a workaround — for chunky-toon
characters, procedural squash/anticipation/overshoot *is* how "feel" is made.

---

## 1. Animation tactics — how other people do this

The reusable toolkit (12-principles → games → our engine). These are the levers;
the roadmap below applies them.

- **Squash & stretch, volume-preserved** — stretch on the fast part, squash on
  impact/apex; scale Y up ⇒ scale X/Z down so volume reads constant. (We do this
  at idle in `creature_anim.gd` ±2.8% — good; the *event* squashes are missing.)
- **Anticipation → action → follow-through** — a wind-up *before* the move, an
  overshoot-and-settle *after*. Easing carries weight: **ease-IN for wind-ups**
  (building force), **ease-OUT for impacts/snaps** (decisive).
- **Overshoot & settle on every tween** — never lerp straight to target; go to
  ~110–120% then back with `TRANS_BACK`/`TRANS_ELASTIC`. Single biggest "moves →
  alive" change, and it's free.
- **Event scale-punch** — punch scale to ~1.18–1.22 then decay. We already use
  this for hit-react (0.18) and attack telegraph (0.22) in `combatant._tick_feedback`;
  extend the same primitive to spawn pop-in, land, death, pickups.
- **Velocity lean** — tilt the mesh ±6–8° into the direction of travel, lerp back
  when stopped. ~3 lines, big weight gain.
- **Secondary motion / phase de-sync** — offset each creature's phase so a room
  doesn't breathe in lockstep (we derive it from spawn pos, RNG-free — keep it).
- **Two-layer transform split** — idle/locomotion writes the **mesh** node;
  hit/attack punch writes the **body** node; they compose (child×parent) and
  never fight. `creature_anim.gd` documents this — preserve it.

**Game-feel reference points:** Hollow Knight (clean hit-stop + flash + small
knockback, cozy-adjacent severity), Hades (dash i-frames with a visual darken
tell), Smash (hit-stop scales with strength), Dark Souls (~0.33s roll i-frame as
the fairness anchor).

**Cozy tuning rule:** telegraph density *up*, projectile/shake density *down*.
Keep idle breath ≤ ~3% (more looks rubbery on chunky-toon).

---

## 2. Current state (what already exists — don't rebuild)

| System | State | Where |
|---|---|---|
| Enemy hit-feel (flash, knockback, hit-stop, spark, shake) | ✅ well-tuned, leave it | `hit_feedback.gd`, `hitstop.gd`, `camera_rig.gd` |
| Hit-stop tiers (normal 0.07 / crit 0.13 / super 0.20s) | ✅ textbook | `hit_feedback.gd` |
| Enemy attack **telegraph** (stop + windup before strike) | ✅ exists (`TELEGRAPH_SEC 0.35`) — but no *visual* wind-back | `combatant.gd` ATTACK state |
| Procedural idle/locomotion (breathe/sway/bob, all enemies) | ✅ done | `creature_anim.gd` |
| Player i-frames (`IFRAMES_SEC`, roll `0.27`) | ✅ exist | `player_controller.gd` |
| Player hit: knockback + hit-stop + red flash + hurt-vignette | ✅ exist | `player_controller.gd:take_damage` |
| Player **micro-stun (input-lock)** | ⬜ missing | — |
| Player **i-frame blink tell** (you can't see you're safe) | ⬜ missing | — |
| Player **flinch** (mesh recoil on hit) | ⬜ missing | — |
| Enemy **ranged attacks / projectiles** | ⬜ none | (reuse `arrow.gd`) |
| Player **bow-draw** (arms draw on fire) | ⬜ missing (torso-tip fake only) | `player_controller.gd` |
| Player walk/run **clip easing** (linear → robotic) | ⏸ needs Blender | — |

---

## 3. Roadmap (priority order)

### Phase 1 — Player "getting hit" feel ⬜  *(highest priority; the user's ask)*
Make taking a hit read as a fair "oof," not a silent HP tick.
- **Micro-stun:** add `_stun_t` on the player; set ~**0.10s** in `take_damage`;
  gate input at the top of `player_controller._physics_process`
  (`if _stun_t > 0: _stun_t -= delta; (decay velocity); return`). 80–150ms is the
  sweet spot — registers without ever feeling like a stunlock. (~10 lines)
- **Flinch:** a brief mesh recoil — punch the player mesh back along the hit
  normal + a small squash, eased out over ~0.15s (reuse the scale-punch idea on
  the player mesh node).
- **I-frame blink tell:** we *have* i-frames (`IFRAMES_SEC`) but the player can't
  see them — pulse mesh visibility / a flash every ~0.08s while `_iframe_t > 0`
  so "I'm briefly safe" is legible (Hades-style).
- **Knockback after hit-stop:** let the 0.07s freeze release *then* apply the
  shove so the freeze "loads" it (free weight).
- Keep flash + vignette + shake at the *low* tier (cozy "oof", not a brawler slam).
- **Verify:** play-test + a screenshot of the blink. **Effort: S–M.**

### Phase 2 — Enemy melee attack tell (anticipation → lunge) ⬜
Enrich the *existing* telegraph window with visible motion so attacks read.
- During `_telegraph_t` (bump melee to ~0.45s): **wind-back** — pull the mesh
  away from the target + squash (anticipation, ease-in).
- On strike: a **lunge** toward the target (eased forward pop — reuse/retune the
  scale-punch as a position pop), then settle.
- Windup length scales with `attack_cooldown` (heavy hitters telegraph longer).
- `creature_anim` must **yield** during the attack (add an "attacking" flag like
  the existing "moving" settle) so idle breathing doesn't fight it.
- **Verify:** play-test (motion — not screenshot-able). **Effort: M.**

### Phase 3 — Enemy ranged attacks / cozy bullet-hell-lite ⬜  *(new system)*
Enemies that shoot avoidable projectiles. **Telegraph-heavy, density-light.**
- **Reuse `arrow.gd` as the projectile base:** lower `SPEED` (50 → **~10** aimed,
  **~6** slow orb — deliberately sluggish vs the player so they read as
  dodgeable), flip the Hitbox collision mask to hit the **player** layer, route
  damage through `player.take_damage`. Near-zero new projectile code.
- **Every shot telegraphs (0.6s):** emissive wind-up pulse on the shooter +
  a **ground line/ring decal** (reuse the AoE-burst ring in `arrow.gd:326–349`) +
  a charge SFX. Consistent color = "incoming."
- **Fair pattern vocabulary** (pick a few, no curtains): single aimed shot · 3–5
  fixed fan spread (strafe the gaps) · slow orb (walk around) · delayed AoE zone
  (ground marker → boom, rewards repositioning).
- **Avoidance = positioning/strafe** (player `move_speed` must exceed projectile
  speed). A dodge-roll with i-frames is optional flavor, not mandatory.
- **Cozy density spec:** 1–2 ranged enemies active at once; 1 aimed shot every
  ~2.5–3s (or a fan on a longer cd); bright saturated projectiles vs the dark
  crypt; no homing (or weak, hard-capped turn rate).
- New: a `ranged` flag/`projectile` kind in `ENEMY_KINDS`; a `_ranged_attack()`
  in `combatant` that fires the projectile at telegraph-end instead of melee.
- **Verify:** play-test + screenshot the telegraph decal. **Effort: M–L.**

### Phase 4 — Player bow-draw ⬜
Arms that actually draw the bow on fire (the player is what you stare at).
- Procedural first (no Blender, no AnimationTree): on `trigger_fire`, pose the
  bow/draw-arm bones via a `SkeletonModifier3D` (or `set_bone_pose_rotation`
  after the AnimationPlayer) — raise to draw, snap on release, ease back ~0.15s.
  Port the angle intent from the unused `ranger_anim.gd` draw pose onto the
  chibi's Mixamo-named arm bones.
- **Verify:** screenshot-able (a frame mid-draw). **Effort: M.**

### Phase 5 — Animation juice (cheap, broad) ⬜
Apply the Section-1 levers everywhere.
- **Overshoot & settle** on existing one-shot tweens (`TRANS_BACK`).
- **Event scale-punches:** spawn pop-in (0→1, `TRANS_BACK`, ~0.2s), land-squash
  on hop-bob valleys, death-squash (enhance the existing crumple).
- **Velocity lean** ±6–8° on moving creatures + the player.
- **Effort: S–M.**

### Parked — ⏸ Player clip easing (needs Blender)
Walk/run/idle are linear-interpolated Meshy mocap → robotic. Real fix: `bpy`
re-curve fcurves to BEZIER + slight retime + re-export the 3 chibi GLBs. I script
it once Blender + the MCP add-on are running. *(Interim: Phase 5 lean + a
speed-driven blend mask some of it.)*

---

## 4. Sequence & dependencies
1. **Phase 1** (player hit-feel) — highest priority, mostly enhancement, fast.
2. **Phase 2** (enemy melee tell) — builds on the existing telegraph.
3. **Phase 3** (enemy ranged/bullet-hell) — the big new system; reuses `arrow.gd`.
4. **Phase 4** (player bow-draw) — independent, screenshot-verifiable.
5. **Phase 5** (juice) — cheap polish, fold in throughout.
- Parked Blender easing runs whenever the user opens Blender (no code dep).
- Phases 1, 2, 4, 5 are pure GDScript I can do solo + gate-verify. Phase 2/3
  motion needs a play-test to confirm feel (can't screenshot movement).

## 5. Accessibility / cozy guardrails
- Ship a **"reduce screen shake"** toggle (and keep all shake conservative).
- Keep micro-stun ≤ 0.15s, i-frames generous (0.4–0.6s), projectiles slow +
  telegraph-heavy. The design goal: a player who reads the tells and keeps moving
  never needs twitch reflexes.

## 6. Sources / provenance
Two research passes (archived in session): animation pipeline + 12-principles;
hit-feel number bands + bullet-hell telegraphing. Anchors: Hollow Knight Hornet
frame data (0.5–0.67s windups), Dark Souls ~0.33s roll i-frame, Smash hitlag
scaling, shmup bullet-visibility rules, ARPG ground-decal telegraphs.
