// Procedural animation for the GLB knight base + equipment.
// The knight is a rig of named children parented to a root: Body, Head,
// Arm_L, Arm_R, Leg_L, Leg_R. Each has its origin at a sensible pivot
// (shoulder, hip, neck), so a simple rotation around the local X axis
// drives the swing. Equipment is parented under slot empties on the rig
// groups, so it follows the swing automatically.
//
// Axis convention: GLB Y-up. The figure faces +Z. Limbs hang down (-Y).
// Forward swing on a hanging limb = NEGATIVE rotation around the local X.
//
// State on `e`:
//   e.moving        — bool, currently mid-step
//   e.running       — bool, holding shift OR auto-running (chase combat target)
//   e.attackPhase   — null when idle, 0→1 over ATTACK_DUR when swinging
//   e.hurtT         — frames remaining of hurt flash (engine ticks down)
//   e.combatStyle   — 'accurate'/'aggressive'/'defensive'/'controlled'

import * as THREE from 'three';

const TWO_PI = Math.PI * 2;
const ATTACK_DUR = 0.45;            // seconds for full swing
const BLOCK_RAISE = 1.05;           // rad — Arm_L rotation when shield-blocking
const DEFENSIVE_HOLD = 0.45;        // rad — passive raise while in defensive style

export function animateGLBKnight(mesh, e, dt) {
  const p = mesh.userData.parts;
  if (!p) return;

  const moving  = !!e.moving;
  const running = moving && !!e.running;

  // Per-character overrides (stamped on mesh.userData by the spawn code).
  // - lockArm: 'L' / 'R' / 'both' — the arm holding an item shouldn't swing.
  // - cadenceMul: 0.7 (slow elder) … 1.2 (teen). 1.0 default.
  // - leanMul: how much forward stoop while moving. Elder NPCs use 1.5+.
  const ud         = mesh.userData;
  const lockL      = ud.lockArm === 'L' || ud.lockArm === 'both';
  const lockR      = ud.lockArm === 'R' || ud.lockArm === 'both';
  const cadenceMul = ud.cadenceMul ?? 1.0;
  const leanMul    = ud.leanMul    ?? 1.0;

  // Cadence + amplitude: idle / walk / run.
  // moveBlend smooths the start/stop transition over ~250ms so legs
  // ramp into and out of their stride instead of snapping. Without this
  // blend, the moment moving flips to false, legSwing drops 0.55→0 in
  // one frame and the character looked "frozen mid-step." k = 1−exp(−dt×8)
  // ramps to 95% over ~370ms, which is the well-tested feel for
  // walk-cycle blends in third-person games (Last Epoch + Hades use
  // similar windows).
  const target = moving ? 1 : 0;
  e._moveBlend = (e._moveBlend ?? target) +
    (target - (e._moveBlend ?? target)) * Math.min(1, dt * 8);
  const blend = e._moveBlend;

  const speed       = (running ? 8.5 : 5.5) * cadenceMul;
  // Idle phase ticks slowly even when stopped so the carryover of leg
  // motion feels alive; legSwing × blend collapses the visible motion to 0.
  const idleSpeed   = 1.6;
  const phaseSpeed  = THREE.MathUtils.lerp(idleSpeed, speed, blend);
  const legSwing    = (running ? 0.85 : 0.55) * blend;
  const armSwingMul = (running ? 0.95 : 0.6) * blend;
  e._phase = ((e._phase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t  = e._t = (e._t ?? 0) + dt;
  const ph = e._phase;

  // Legs swing forward/back. Add a vertical foot lift on the swinging leg
  // so the foot clears the ground in mid-swing instead of dragging — the
  // single biggest "looks alive" upgrade vs pure rotation.
  // All amplitudes multiplied by blend so the foot-lift, knee bend, and
  // elbow bend all settle to neutral over the same 250ms window.
  if (p.Leg_L) {
    if (e._legLRestY === undefined) e._legLRestY = p.Leg_L.position.y;
    p.Leg_L.rotation.x = -Math.sin(ph) * legSwing;
    const liftL = Math.max(0, -Math.sin(ph)) * 0.06 * (running ? 1.4 : 1);
    p.Leg_L.position.y = e._legLRestY + liftL * blend;
  }
  if (p.Leg_R) {
    if (e._legRRestY === undefined) e._legRRestY = p.Leg_R.position.y;
    p.Leg_R.rotation.x =  Math.sin(ph) * legSwing;
    const liftR = Math.max(0, Math.sin(ph)) * 0.06 * (running ? 1.4 : 1);
    p.Leg_R.position.y = e._legRRestY + liftR * blend;
  }

  const kneeMax = (running ? 1.20 : 0.85) * blend;
  if (p.Knee_L) p.Knee_L.rotation.x = Math.max(0, -Math.sin(ph)) * kneeMax;
  if (p.Knee_R) p.Knee_R.rotation.x = Math.max(0,  Math.sin(ph)) * kneeMax;
  // Elbow bend — counter-phase to the same arm's swing, so it swings the
  // forearm forward at the front of the stride. Held-item arms lerp to
  // neutral; otherwise blend × sin gives the gentle ramp.
  const elbowMax = (running ? 0.55 : 0.35) * blend;
  if (p.Elbow_L) {
    if (lockL) p.Elbow_L.rotation.x = THREE.MathUtils.lerp(p.Elbow_L.rotation.x, 0, Math.min(1, dt * 6));
    else       p.Elbow_L.rotation.x = Math.max(0, -Math.sin(ph)) * elbowMax;
  }
  if (p.Elbow_R) {
    if (lockR) p.Elbow_R.rotation.x = THREE.MathUtils.lerp(p.Elbow_R.rotation.x, 0, Math.min(1, dt * 6));
    else       p.Elbow_R.rotation.x = Math.max(0,  Math.sin(ph)) * elbowMax;
  }

  // Arms counter-swing legs, with optional lock-out for NPCs holding items.
  // Arms not held also get a small lateral sway on rotation.z so the
  // shoulders read as twisting with the gait.
  if (p.Arm_L) {
    if (lockL) {
      // Lerp toward neutral if previously swinging.
      p.Arm_L.rotation.x = THREE.MathUtils.lerp(p.Arm_L.rotation.x, 0, Math.min(1, dt * 6));
      p.Arm_L.rotation.z = THREE.MathUtils.lerp(p.Arm_L.rotation.z, 0, Math.min(1, dt * 6));
    } else {
      p.Arm_L.rotation.x =  Math.sin(ph) * legSwing * armSwingMul;
      p.Arm_L.rotation.z =  Math.sin(ph) * 0.05 * (moving ? 1 : 0);
    }
  }
  if (p.Arm_R) {
    if (lockR) {
      p.Arm_R.rotation.x = THREE.MathUtils.lerp(p.Arm_R.rotation.x, 0, Math.min(1, dt * 6));
      p.Arm_R.rotation.z = THREE.MathUtils.lerp(p.Arm_R.rotation.z, 0, Math.min(1, dt * 6));
    } else {
      p.Arm_R.rotation.x = -Math.sin(ph) * legSwing * armSwingMul;
      p.Arm_R.rotation.z = -Math.sin(ph) * 0.05 * (moving ? 1 : 0);
    }
  }

  // Body — vertical bob (twice per stride), side sway, forward lean.
  if (p.Body) {
    if (e._bodyRestY === undefined) e._bodyRestY = p.Body.position.y;
    const bobAmp = running ? 0.045 : 0.025;
    const bob = moving
      ? Math.abs(Math.sin(ph * 2)) * bobAmp
      : Math.sin(t * 1.4) * 0.008;
    p.Body.position.y = e._bodyRestY + bob;
    // Side sway — torso shifts opposite the planted foot. Subtle (~0.03 rad).
    p.Body.rotation.z = moving ? Math.sin(ph) * 0.03 : 0;
    // Forward lean — slight while walking, more while running. Elder NPCs
    // amplify via leanMul so they read as stooped.
    const leanBase = !moving ? 0 : (running ? 0.10 : 0.04);
    p.Body.rotation.x = leanBase * leanMul;
  }

  // Head — bob trails the body bob by ~one frame's worth (mass-damping
  // illusion via a stored prev value), micro-nod with each step, idle sway.
  if (p.Head) {
    if (e._headRestY === undefined) e._headRestY = p.Head.position.y;
    if (e._prevBodyBob === undefined) e._prevBodyBob = 0;
    const bodyBob = p.Body ? (p.Body.position.y - e._bodyRestY) : 0;
    // Trail by mixing prev sample (head lags body).
    const headBob = e._prevBodyBob * 0.8 + bodyBob * 0.2;
    e._prevBodyBob = headBob;
    p.Head.position.y = e._headRestY + headBob;
    // Combat-only running lean (knight only — NPCs without combatStyle skip).
    const combatLean = (running && e.combatStyle) ? -0.18 : 0;
    p.Head.rotation.x = combatLean + Math.sin(t * 0.8) * 0.04
                        + (moving ? Math.sin(ph) * 0.02 : 0);
    p.Head.rotation.y = Math.sin(t * 0.5) * 0.05;
  }

  // Attack: triggered single-shot, overrides Arm_R rotation.
  if (e.attackPhase != null && p.Arm_R) {
    e.attackPhase += dt / ATTACK_DUR;
    const a = Math.min(1, e.attackPhase);
    // 0.0 → 0.3   wind-up: arm rotates back/up to +1.4 rad
    // 0.3 → 0.6   strike : sweeps forward-down to -0.6 rad
    // 0.6 → 1.0   recover: returns to 0
    let r;
    if      (a < 0.3) r = (a / 0.3) * 1.4;
    else if (a < 0.6) r = 1.4 + ((a - 0.3) / 0.3) * (-2.0);
    else              r = -0.6 + ((a - 0.6) / 0.4) * 0.6;
    p.Arm_R.rotation.x = r;
    if (a >= 1) e.attackPhase = null;
  }

  // Shield block: raise Arm_L when hurt; hold partial raise in defensive style.
  // Overrides the walk-cycle arm swing for Arm_L.
  if (p.Arm_L) {
    const defensive = e.combatStyle === 'defensive';
    let target = defensive ? DEFENSIVE_HOLD : 0;
    if (e.hurtT > 0) {
      // Strong block raise that decays back as hurtT counts down. hurtT is
      // in frames (configured at ~15 in player.js), so normalize to 0..1.
      const k = Math.min(1, e.hurtT / 15);
      target = BLOCK_RAISE * k + DEFENSIVE_HOLD * (1 - k) * (defensive ? 1 : 0);
    }
    if (target > 0) {
      // Override walk swing on the shield arm with the block pose.
      p.Arm_L.rotation.x = target;
    }
  }
}

/** Trigger an attack swing on a knight mesh. Call from combat code. */
export function triggerAttack(e) {
  e.attackPhase = 0;
}
