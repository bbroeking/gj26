// Skeleton — crypt biped melee. Reuses the goblin biped animator shape
// (Body / Head / Arm_L / Arm_R / Leg_L / Leg_R from clean_ai_mesh.py
// --rig biped). Slightly slower idle bob + stiffer walk swing so the
// silhouette reads as undead vs. the goblin's bouncier gait.

import { animateGoblin } from './goblin.js';

export function animateSkeleton(mesh, e, dt) {
  // Tag so e._phase / e._t etc. don't trample neighboring animators
  // when a multi-enemy scene shares state objects.
  animateGoblin(mesh, e, dt);
}
