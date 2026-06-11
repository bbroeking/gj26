// Crypt rat — small quadruped. Reuses the generic quadruped animator
// (Body / Head / Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR from
// clean_ai_mesh.py --rig quadruped). Higher idle/move speeds + a small
// swing amplitude so the gait reads as skitter-y.

import { animateQuadruped } from './quadruped.js';

export function animateRat(mesh, e, dt) {
  animateQuadruped(mesh, e, dt, {
    swingAmp: 0.65,
    moveSpeed: 18.0,
    idleSpeed: 2.4,
    bobAmp: 0.018,
    tailRest: 0.28,
  });
}
