// Procedural animation for the GLB cow. Each named child has its origin at
// the right pivot (legs at hip, head at neck-base, tail at base), so we just
// rotate them around the right local axis.
//
// Cow facing: local +X is the head direction (built that way in Blender).
// Local axes after glTF Y-up: +X forward, +Y up, +Z left.
// → Walking swings legs around their local Z axis (forward/back in XY).
// → Tail wags around its local Y axis (side-to-side around vertical).
// → Headbutt nods the head around its local Z axis: +Z rears the head up/back,
//   -Z drives the head forward/down (the strike).

const TWO_PI = Math.PI * 2;
const ATTACK_DUR = 0.35;     // matches enemies.js attackAnimT
const HEADBUTT_REAR  = 0.65; // wind-up rotation (head pulls back/up)
const HEADBUTT_DRIVE = -0.85; // strike rotation (head drives forward/down)

export function animateCow(mesh, e, dt) {
  const parts = mesh.userData.parts;
  if (!parts) return;

  // Walk phase advances faster while moving, idles forward slowly otherwise.
  // moveBlend smooths start/stop transitions over ~250ms so the cow's
  // legs don't snap from 0 to 0.55 swing in one frame.
  const moving = !!e.moving;
  const target = moving ? 1 : 0;
  e._cowMoveBlend = (e._cowMoveBlend ?? target) +
    (target - (e._cowMoveBlend ?? target)) * Math.min(1, dt * 8);
  const blend = e._cowMoveBlend;

  const phaseSpeed = 1.6 + (12.0 - 1.6) * blend;
  e._cowPhase = ((e._cowPhase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t = e._idleT = (e._idleT ?? 0) + dt;

  const phase = e._cowPhase;
  const swing = 0.55 * blend;     // leg swing amplitude (rad)

  // Diagonal-pair gait: FL+BR forward while FR+BL back.
  if (parts.Leg_FL) parts.Leg_FL.rotation.z =  Math.sin(phase) * swing;
  if (parts.Leg_BR) parts.Leg_BR.rotation.z =  Math.sin(phase) * swing;
  if (parts.Leg_FR) parts.Leg_FR.rotation.z = -Math.sin(phase) * swing;
  if (parts.Leg_BL) parts.Leg_BL.rotation.z = -Math.sin(phase) * swing;

  // Body bob — crossfade walk-bob and idle-bob by blend.
  if (parts.Body) {
    if (e._cowBodyRestY === undefined) e._cowBodyRestY = parts.Body.position.y;
    const walkBob = Math.abs(Math.sin(phase * 2)) * 0.025;
    const idleBob = Math.sin(t * 1.4) * 0.008;
    parts.Body.position.y = e._cowBodyRestY + walkBob * blend + idleBob * (1 - blend);
  }

  // Tail wags faster while moving.
  if (parts.Tail) {
    const tailRate = 1.7 + (4.0 - 1.7) * blend;
    parts.Tail.rotation.y = Math.sin(t * tailRate) * 0.32;
  }

  // Head subtle nod + tiny side glance — overridden by headbutt below.
  if (parts.Head) {
    parts.Head.rotation.z = Math.sin(t * 0.9) * 0.04;
    parts.Head.rotation.y = Math.sin(t * 0.6) * 0.05;
  }

  // HEADBUTT: while attackAnimT > 0, drive Head rotation through wind-up →
  // strike → recover. enemies.js sets attackAnimT = 0.35 on attack start.
  if (e.attackAnimT > 0 && parts.Head) {
    const u = 1 - e.attackAnimT / ATTACK_DUR;   // 0 → 1
    let r;
    if      (u < 0.3) r = (u / 0.3) * HEADBUTT_REAR;                              // rear up/back
    else if (u < 0.6) r = HEADBUTT_REAR + ((u - 0.3) / 0.3) * (HEADBUTT_DRIVE - HEADBUTT_REAR); // snap forward/down
    else              r = HEADBUTT_DRIVE + ((u - 0.6) / 0.4) * (-HEADBUTT_DRIVE); // recover to 0
    parts.Head.rotation.z = r;
    // Also kill idle leg swing during attack so legs plant
    if (parts.Leg_FL) parts.Leg_FL.rotation.z = 0;
    if (parts.Leg_FR) parts.Leg_FR.rotation.z = 0;
    if (parts.Leg_BL) parts.Leg_BL.rotation.z = 0;
    if (parts.Leg_BR) parts.Leg_BR.rotation.z = 0;
  }
}
