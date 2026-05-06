// Procedural animation for ground-bird rigs (chicken, falcon-perched).
// Rig: Body, Head, Wing_L, Wing_R, Leg_L, Leg_R, Tail.
//
// Idle: head bob + occasional wing rustle + tail twitch.
// Walking: alternating leg swing + body bob + brief wing-out balance flap.

const TWO_PI = Math.PI * 2;

export function animateBird(mesh, e, dt) {
  const p = mesh.userData.parts;
  if (!p) return;

  const moving = !!e.moving;
  // moveBlend smooths start/stop transitions over ~250ms.
  const target = moving ? 1 : 0;
  e._bMoveBlend = (e._bMoveBlend ?? target) +
    (target - (e._bMoveBlend ?? target)) * Math.min(1, dt * 8);
  const blend = e._bMoveBlend;

  const phaseSpeed = 1.8 + (9.0 - 1.8) * blend;
  e._bPhase = ((e._bPhase ?? 0) + dt * phaseSpeed) % TWO_PI;
  const t = e._bIdleT = (e._bIdleT ?? 0) + dt;
  const ph = e._bPhase;
  const swing = 0.45 * blend;

  // Legs alternate (left forward while right back).
  if (p.Leg_L) p.Leg_L.rotation.x =  Math.sin(ph) * swing;
  if (p.Leg_R) p.Leg_R.rotation.x = -Math.sin(ph) * swing;

  // Body bob — crossfade walk-bob and idle-bob by blend.
  if (p.Body) {
    if (e._bBodyRestY === undefined) e._bBodyRestY = p.Body.position.y;
    const walkBob = Math.abs(Math.sin(ph * 2)) * 0.04;
    const idleBob = Math.sin(t * 1.4) * 0.012;
    p.Body.position.y = e._bBodyRestY + walkBob * blend + idleBob * (1 - blend);
  }

  // Head — crossfade peck (walking) and idle sway by blend.
  if (p.Head) {
    const peck = Math.max(0, Math.sin(ph * 2)) * 0.35;
    const idleX = Math.sin(t * 1.1) * 0.07;
    const idleY = Math.sin(t * 0.7) * 0.10;
    p.Head.rotation.x = peck * blend + idleX * (1 - blend);
    p.Head.rotation.y = idleY * (1 - blend);
  }

  // Wing rustle — crossfade balance-flap (walking) and idle rustle.
  if (p.Wing_L && p.Wing_R) {
    const balanceFlap = Math.abs(Math.sin(ph * 2)) * 0.20;
    const rustle = Math.max(0, Math.sin(t * 0.6) - 0.85) * 7;
    const idleFlap = rustle * 0.5 + Math.sin(t * 2.4) * 0.03;
    const flap = balanceFlap * blend + idleFlap * (1 - blend);
    p.Wing_L.rotation.z =  flap;
    p.Wing_R.rotation.z = -flap;
  }

  // Tail twitch — crossfade whip (walking) and idle.
  if (p.Tail) {
    const whip = Math.sin(ph * 1.2) * 0.25;
    const idleSway = Math.sin(t * 1.7) * 0.10;
    p.Tail.rotation.y = whip * blend + idleSway * (1 - blend);
  }
}
