// Ghost — static-rig float. clean_ai_mesh.py --rig static gives only
// Body + Head parented to a root. Animator bobs the whole mesh vertically
// and gently sways the head + body on idle; on attack, the body lunges
// forward briefly. No legs to swing.

const TWO_PI = Math.PI * 2;
const ATTACK_DUR = 0.35;

export function animateGhost(mesh, e, dt) {
  const p = mesh.userData.parts;
  if (!p) return;

  const t = e._gT = (e._gT ?? 0) + dt;

  // Whole-mesh vertical bob — sinusoid centered on rest Y. Captured the
  // first time so subsequent runs use the placed-Y, not the original.
  if (e._gRestY === undefined) e._gRestY = mesh.position.y;
  const bob = Math.sin(t * 2.2) * 0.10;
  mesh.position.y = e._gRestY + bob;

  // Body sway — slight rock so it doesn't read as a frozen sprite.
  if (p.Body) {
    p.Body.rotation.z = Math.sin(t * 1.1) * 0.06;
  }

  // Head — drifts opposite the body sway.
  if (p.Head) {
    p.Head.rotation.x = Math.sin(t * 0.7) * 0.05;
    p.Head.rotation.y = Math.sin(t * 0.5) * 0.08;
    p.Head.rotation.z = -Math.sin(t * 1.1) * 0.04;
  }

  // Attack lunge — push body forward + slight head dip.
  if (e.attackAnimT > 0) {
    const u = 1 - e.attackAnimT / ATTACK_DUR;
    let r;
    if      (u < 0.3) r = (u / 0.3) * 0.6;                       // wind back
    else if (u < 0.6) r = 0.6 + ((u - 0.3) / 0.3) * -1.2;        // strike forward
    else              r = -0.6 + ((u - 0.6) / 0.4) * 0.6;        // recover
    if (p.Body) p.Body.rotation.x = r * 0.6;
    if (p.Head) p.Head.rotation.x = r * 0.4;
  }
}
