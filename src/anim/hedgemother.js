// Spec 05 — Hedgemother boss animator.
//
// The Hedgemother GLB is a quadruped rig (Body, Head, Tail, Leg_FL/FR/BL/BR).
// She's slow + ponderous: lower phase speed, deeper Y-bob, heavy body roll.
// Telegraph poses key off `e.bossState.activeTelegraph.attackName`:
//   thorn_sweep — body twists + lifts (windup), then snaps forward (strike)
//   root_stomp  — body crouches low (front legs braced)
//   summon      — body rises, head tilts up
//
// State expected on `e`:
//   e.moving        — bool
//   e.bossState     — present once initBossState ran; reads activeTelegraph

const TWO_PI = Math.PI * 2;

export function animateHedgemother(mesh, e, dt) {
  const p = mesh.userData.parts;
  if (!p) return;

  const moving = !!e.moving;
  const target = moving ? 1 : 0;
  e._moveBlend = (e._moveBlend ?? target) +
    (target - (e._moveBlend ?? target)) * Math.min(1, dt * 6);
  const blend = e._moveBlend;

  const phaseSpeed = 0.9 + (3.0 - 0.9) * blend;
  e._phase = ((e._phase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t  = e._t = (e._t ?? 0) + dt;
  const ph = e._phase;
  const swing = 0.32 * blend;

  // Walk: diagonal pairs swing (FL+BR vs FR+BL).
  if (p.Leg_FL) p.Leg_FL.rotation.x = -Math.sin(ph) * swing;
  if (p.Leg_BR) p.Leg_BR.rotation.x = -Math.sin(ph) * swing;
  if (p.Leg_FR) p.Leg_FR.rotation.x =  Math.sin(ph) * swing;
  if (p.Leg_BL) p.Leg_BL.rotation.x =  Math.sin(ph) * swing;

  // Body sway + Y-bob.
  if (p.Body) {
    if (e._bodyRestY === undefined) e._bodyRestY = p.Body.position.y;
    const walkBob = Math.abs(Math.sin(ph * 2)) * 0.030;
    const idleBob = Math.sin(t * 0.9) * 0.018;
    p.Body.position.y = e._bodyRestY + walkBob * blend + idleBob * (1 - blend);
    if (e._bodyRestRotZ === undefined) e._bodyRestRotZ = p.Body.rotation.z || 0;
    p.Body.rotation.z = e._bodyRestRotZ + Math.sin(t * 0.6) * 0.05 * (1 - blend);
  }

  // Idle head sway.
  if (p.Head) {
    if (e._headRestRotX === undefined) e._headRestRotX = p.Head.rotation.x || 0;
    if (e._headRestRotY === undefined) e._headRestRotY = p.Head.rotation.y || 0;
    p.Head.rotation.x = e._headRestRotX + Math.sin(t * 0.5) * 0.06;
    p.Head.rotation.y = e._headRestRotY + Math.sin(t * 0.35) * 0.08;
  }

  // Tail idle.
  if (p.Tail) p.Tail.rotation.x = Math.sin(t * 1.1) * 0.10;

  // Telegraph poses override body/head idle.
  const tg = e.bossState && e.bossState.activeTelegraph;
  if (tg) {
    const totalT = tg._totalT || (tg._totalT = Math.max(0.05, tg.t + 0.001));
    const u = Math.max(0, Math.min(1, 1 - tg.t / totalT));
    if (tg.attackName === 'thorn_sweep') {
      // Body twists windup, then snaps forward at the end (u > 0.85).
      const lift  = u < 0.85 ? 0.18 * u : 0.18 - (u - 0.85) * 1.2;
      const twist = u < 0.85 ? -0.45 * u : -0.45 + (u - 0.85) * 3;
      if (p.Body) p.Body.position.y = (e._bodyRestY || 0) + lift;
      if (p.Body) p.Body.rotation.y = twist;
    } else if (tg.attackName === 'root_stomp') {
      // Crouch down.
      if (p.Body) p.Body.position.y = (e._bodyRestY || 0) - 0.14 * u;
      if (p.Head) p.Head.rotation.x = (e._headRestRotX || 0) - 0.25 * u;
    } else if (tg.attackName === 'summon') {
      // Body rises, head tilts up — calling out.
      if (p.Body) p.Body.position.y = (e._bodyRestY || 0) + 0.10 * u;
      if (p.Head) p.Head.rotation.x = (e._headRestRotX || 0) + 0.35 * u;
    }
  } else {
    // No telegraph — clear stale Body.rotation.y back to rest.
    if (p.Body) p.Body.rotation.y = (p.Body.rotation.y || 0) * 0.85;
  }
}
