// Hedge-sprite — small bramble biped. Same Body / Head / Arm_L / Arm_R /
// Leg_L / Leg_R rig from clean_ai_mesh.py --rig biped. Faster phase +
// snappy arm swings so it reads as mischievous rather than lumbering.

import { animateGoblin } from './goblin.js';

export function animateHedgeSprite(mesh, e, dt) {
  // Mark for any future per-creature tuning; for now we share the goblin
  // biped pattern verbatim — feels right for the small-and-twitchy read.
  animateGoblin(mesh, e, dt);
}
