// Procedural animation for the GLB goblin.
// Same conventions as the knight rig: named children Body, Head, Arm_L,
// Arm_R, Leg_L, Leg_R + Club parented at the root. Limbs hang down (-Y),
// forward swing on a hanging limb = NEGATIVE rotation around local X.
//
// State on `e`:
//   e.moving        — bool, currently walking
//   e.attackAnimT   — seconds remaining of attack swing (set by enemies.js)

const TWO_PI = Math.PI * 2;
const ATTACK_DUR = 0.35;            // matches enemies.js attackAnimT

export function animateGoblin(mesh, e, dt) {
  const p = mesh.userData.parts;
  if (!p) return;

  const moving = !!e.moving;
  // moveBlend smooths start/stop over ~250ms — same fix as knight + quadruped.
  const target = moving ? 1 : 0;
  e._moveBlend = (e._moveBlend ?? target) +
    (target - (e._moveBlend ?? target)) * Math.min(1, dt * 8);
  const blend = e._moveBlend;

  const phaseSpeed = 1.6 + (8.0 - 1.6) * blend;
  e._phase = ((e._phase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t  = e._t = (e._t ?? 0) + dt;
  const ph = e._phase;
  const swing = 0.5 * blend;

  // Walk: legs + counter-arms (lighter swing on the club arm).
  if (p.Leg_L) p.Leg_L.rotation.x = -Math.sin(ph) * swing;
  if (p.Leg_R) p.Leg_R.rotation.x =  Math.sin(ph) * swing;
  if (p.Arm_L) p.Arm_L.rotation.x =  Math.sin(ph) * swing * 0.5;
  if (p.Arm_R) p.Arm_R.rotation.x = -Math.sin(ph) * swing * 0.3;

  // Body bob — crossfade walk-bob and idle-bob by blend.
  if (p.Body) {
    if (e._bodyRestY === undefined) e._bodyRestY = p.Body.position.y;
    const walkBob = Math.abs(Math.sin(ph * 2)) * 0.020;
    const idleBob = Math.sin(t * 1.4) * 0.008;
    p.Body.position.y = e._bodyRestY + walkBob * blend + idleBob * (1 - blend);
  }

  // Idle head sway.
  if (p.Head) {
    p.Head.rotation.x = Math.sin(t * 0.7) * 0.04;
    p.Head.rotation.y = Math.sin(t * 0.5) * 0.05;
  }

  // PLANK SWING: when attackAnimT > 0, drive Arm_R + Club through the swing.
  if (e.attackAnimT > 0) {
    const u = 1 - e.attackAnimT / ATTACK_DUR;   // 0 → 1
    let r;
    if      (u < 0.3) r = (u / 0.3) * 1.2;                              // wind up — arm/club back+up
    else if (u < 0.6) r = 1.2 + ((u - 0.3) / 0.3) * (-1.8);             // strike — sweep forward-down
    else              r = -0.6 + ((u - 0.6) / 0.4) * 0.6;               // recover
    if (p.Arm_R) p.Arm_R.rotation.x = r;
    if (p.Club)  p.Club.rotation.x  = r;       // club tracks the arm
  }
}
