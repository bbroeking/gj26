// Generic procedural animation for any GLB built with the standard quadruped rig:
//   Body, Head, Tail, Leg_FL, Leg_FR, Leg_BL, Leg_BR
// Used by boar, hedgewolf, wolf_alpha, burrow_boar, hedgewight, hedgemother, hare.
// Same gait pattern as cow.js: diagonal-pair (FL+BR vs FR+BL) leg swing,
// body bob synced to stride, tail sway, optional bite/lunge attack.

const TWO_PI = Math.PI * 2;
const ATTACK_DUR = 0.35;
const LUNGE_REAR  = -0.55;
const LUNGE_DRIVE =  0.75;

export function animateQuadruped(mesh, e, dt, opts = {}) {
  const parts = mesh.userData.parts;
  if (!parts) return;

  const swingAmp = opts.swingAmp ?? 0.55;
  const moveSpeed = opts.moveSpeed ?? 12.0;
  const idleSpeed = opts.idleSpeed ?? 1.6;
  const bobAmp = opts.bobAmp ?? 0.025;
  const tailRest = opts.tailRest ?? 0.32;

  const moving = !!e.moving;
  // moveBlend smooths the start/stop transition for legs + body bob +
  // tail rate over ~250ms. Without it the cow's legs snap from 0 to
  // 0.55 swing in one frame when it starts a step, which reads as
  // "the cow teleports between poses." Same fix as knight.js.
  const target = moving ? 1 : 0;
  e._qMoveBlend = (e._qMoveBlend ?? target) +
    (target - (e._qMoveBlend ?? target)) * Math.min(1, dt * 8);
  const blend = e._qMoveBlend;

  const phaseSpeed = idleSpeed + (moveSpeed - idleSpeed) * blend;
  e._qPhase = ((e._qPhase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t = e._qIdleT = (e._qIdleT ?? 0) + dt;
  const phase = e._qPhase;
  const swing = swingAmp * blend;

  if (parts.Leg_FL) parts.Leg_FL.rotation.z =  Math.sin(phase) * swing;
  if (parts.Leg_BR) parts.Leg_BR.rotation.z =  Math.sin(phase) * swing;
  if (parts.Leg_FR) parts.Leg_FR.rotation.z = -Math.sin(phase) * swing;
  if (parts.Leg_BL) parts.Leg_BL.rotation.z = -Math.sin(phase) * swing;

  if (parts.Body) {
    if (e._qBodyRestY === undefined) e._qBodyRestY = parts.Body.position.y;
    // Walk-bob and idle-bob crossfade by blend so the cow's torso
    // slides between the two amplitudes instead of swapping mid-step.
    const walkBob = Math.abs(Math.sin(phase * 2)) * bobAmp;
    const idleBob = Math.sin(t * 1.4) * (bobAmp * 0.32);
    parts.Body.position.y = e._qBodyRestY +
      walkBob * blend + idleBob * (1 - blend);
  }

  if (parts.Tail) {
    // Tail wags faster while moving; rate eases between idle and gallop.
    const tailRate = 1.7 + (4.0 - 1.7) * blend;
    parts.Tail.rotation.y = Math.sin(t * tailRate) * tailRest;
  }

  if (parts.Head) {
    parts.Head.rotation.z = Math.sin(t * 0.9) * 0.04;
    parts.Head.rotation.y = Math.sin(t * 0.6) * 0.05;
  }

  if (e.attackAnimT > 0 && parts.Head) {
    const u = 1 - e.attackAnimT / ATTACK_DUR;
    let r;
    if      (u < 0.3) r = (u / 0.3) * LUNGE_REAR;
    else if (u < 0.6) r = LUNGE_REAR + ((u - 0.3) / 0.3) * (LUNGE_DRIVE - LUNGE_REAR);
    else              r = LUNGE_DRIVE + ((u - 0.6) / 0.4) * (-LUNGE_DRIVE);
    parts.Head.rotation.z = r;
    if (parts.Leg_FL) parts.Leg_FL.rotation.z = 0;
    if (parts.Leg_FR) parts.Leg_FR.rotation.z = 0;
    if (parts.Leg_BL) parts.Leg_BL.rotation.z = 0;
    if (parts.Leg_BR) parts.Leg_BR.rotation.z = 0;
  }
}
