// Procedural animation on a hierarchy of named Object3D parts.
// All techniques here are "stateless" except for the small object passed in
// (walkPhase, plumeVel, swingT, hurtT, deathT) so the same module animates
// the actual player AND demo-pad copies.
import * as THREE from 'three';

/** Step a numeric spring (1D damped harmonic oscillator) toward a target. */
export function spring1D(state, target, dt, stiffness = 90, damping = 12) {
  const x = state.x ?? 0;
  const v = state.v ?? 0;
  const a = (target - x) * stiffness - v * damping;
  state.v = v + a * dt;
  state.x = x + state.v * dt;
  return state.x;
}

/**
 * Apply a continuous walk cycle when `moving` is true, otherwise an idle
 * breath. `state` carries phase/spring values across frames.
 *
 * Convention: limb pivots in our knight rotate around X to swing forward/back.
 *
 * @param mesh   THREE.Group with named children (lLeg, rLeg, lArm, rArm, body,
 *               head, plume, sword)
 * @param state  { walkPhase, plumeSpring, breathT, swingT, hurtT, deathT }
 * @param input  { moving, speed (0..1), facingY (radians), swinging, hurt }
 * @param dt     seconds since last frame
 */
export function animateKnight(mesh, state, input, dt) {
  const lLeg = mesh.getObjectByName('lLeg');
  const rLeg = mesh.getObjectByName('rLeg');
  const lArm = mesh.getObjectByName('lArm');
  const rArm = mesh.getObjectByName('rArm');
  const body = mesh.getObjectByName('body');
  const head = mesh.getObjectByName('head');
  const plume = mesh.getObjectByName('plume');
  const sword = mesh.getObjectByName('sword');

  // ---------- DEATH ----------
  if (state.deathT > 0) {
    state.deathT = Math.min(1, state.deathT + dt * 2);
    mesh.rotation.z = THREE.MathUtils.lerp(0, Math.PI / 2, state.deathT);
    return;
  }

  // ---------- LOCOMOTION ----------
  const speed = input.speed ?? (input.moving ? 1 : 0);
  state.walkPhase = (state.walkPhase ?? 0) + dt * 5 * speed;
  state.breathT = (state.breathT ?? 0) + dt;

  if (input.moving) {
    const swing = Math.sin(state.walkPhase) * 0.7 * speed;
    if (lLeg) lLeg.rotation.x =  swing;
    if (rLeg) rLeg.rotation.x = -swing;
    if (lArm) lArm.rotation.x = -swing * 0.8;
    if (rArm) rArm.rotation.x =  swing * 0.8;
    // body bob with each footfall (twice per stride)
    if (body) body.position.y = 0.65 + Math.abs(Math.sin(state.walkPhase * 2)) * 0.05;
    if (head) head.position.y = 1.04 + Math.abs(Math.sin(state.walkPhase * 2)) * 0.05;
    if (plume) plume.position.y = 1.45 + Math.abs(Math.sin(state.walkPhase * 2)) * 0.05;
  } else {
    // idle breath — gentle chest expand + head micro-rotation
    const b = Math.sin(state.breathT * 1.4) * 0.02;
    if (body) {
      body.scale.y = 1 + b;
      body.position.y = 0.65 + b * 0.5;
    }
    if (head) head.rotation.x = Math.sin(state.breathT * 1.1) * 0.04;
    // settle limbs
    for (const limb of [lLeg, rLeg, lArm, rArm]) {
      if (limb) limb.rotation.x = THREE.MathUtils.lerp(limb.rotation.x, 0, Math.min(1, dt * 6));
    }
  }

  // ---------- PLUME SPRING — lags behind direction changes ----------
  if (plume) {
    state.plumeSpring = state.plumeSpring ?? { x: 0, v: 0, target: 0 };
    state.plumeSpring.target = input.moving ? -speed * 0.25 : 0;
    spring1D(state.plumeSpring, state.plumeSpring.target, dt, 60, 7);
    plume.rotation.x = state.plumeSpring.x;
  }

  // ---------- CAPE — drags during walk, settles when idle ----------
  const cape = mesh.getObjectByName('cape');
  if (cape) {
    state.capeSpring = state.capeSpring ?? { x: 0, v: 0 };
    // When walking forward, cape lifts back (positive rotation.x)
    // because the pivot is behind the shoulders and the cape hangs
    // down — rotation.x lifts it up-and-back.
    const target = input.moving ? -0.4 * speed : 0;
    spring1D(state.capeSpring, target, dt, 35, 5);
    cape.rotation.x = state.capeSpring.x;
    // gentle horizontal flutter when walking
    if (input.moving) {
      cape.rotation.z = Math.sin((state.walkPhase ?? 0) * 0.7) * 0.08 * speed;
    } else {
      cape.rotation.z = THREE.MathUtils.lerp(cape.rotation.z, 0, Math.min(1, dt * 4));
    }
  }

  // ---------- ATTACK SWING (sword arc) ----------
  // state.swingPower: when truthy, the active swing uses a longer arc
  // and a slower ease so the third-hit power swing reads visibly heavier.
  if (input.swinging && state.swingT === undefined) state.swingT = 0;
  if (state.swingT !== undefined) {
    const isPower = !!state.swingPower;
    state.swingT += dt * (isPower ? 3.2 : 5);   // power = ~0.31s; normal = ~0.20s
    const u = Math.min(1, state.swingT);
    const ease = 1 - Math.pow(1 - u, 3);        // cubic ease-out
    if (sword) {
      // Power swings wind further back and follow through past the
      // resting position — the extra arc reads as a committed strike.
      const back    = isPower ? -1.8 : -1.4;
      const through = isPower ?  2.7 :  2.2;
      const arc = back + (through - back) * ease;
      sword.rotation.z = 0.1 + arc;
    }
    if (rArm) rArm.rotation.x = -0.2 + ((isPower ? 1.7 : 1.4) * ease);
    // Weapon trail — sample the sword tip's world position each frame
    // during the swing window and emit small white-gold sparks. Spaced
    // by a small accumulator so we don't over-spawn at high frame rates.
    if (sword) {
      state._trailAcc = (state._trailAcc || 0) + dt;
      if (state._trailAcc >= 0.022) {
        state._trailAcc = 0;
        // local +Y ≈ 0.55 is roughly the tip on the procedural knight
        const tip = new THREE.Vector3(0, 0.55, 0);
        sword.localToWorld(tip);
        // dynamic import keeps this module cheap on load
        import('../scene/sparks.js').then(m => m.spawnHitSparks(tip, {
          count: 2,
          spread: 0.5,
          color: isPower ? 0xfff2c0 : 0xffe096,
          size: 5,
          life: 0.22,
        }));
      }
    }
    // Body lean — torso tips forward through the swing, peaks ~60% in,
    // returns to rest by the end. Reads as a committed strike instead
    // of a floating arm rotation. Power swings lean further.
    if (body) {
      const peak = isPower ? 0.30 : 0.18;
      // sin(πx) makes a smooth 0→peak→0 curve over u∈[0,1]
      const lean = Math.sin(Math.PI * u) * peak;
      body.rotation.x = lean;
    }
    // Step-into-attack lunge — the whole mesh shifts forward in the
    // facing direction, peaks at ~0.5 then returns to rest. Tile-grid
    // logic is unaffected; only the rendered mesh moves.
    if (input.dir) {
      const lungePeak = isPower ? 0.18 : 0.10;
      const lungeOff  = Math.sin(Math.PI * u) * lungePeak;
      const dx = input.dir === 'left'  ? -1 : input.dir === 'right' ? 1 : 0;
      const dz = input.dir === 'up'    ? -1 : input.dir === 'down'  ? 1 : 0;
      mesh.position.x += dx * lungeOff;
      mesh.position.z += dz * lungeOff;
    }
    if (u >= 1) {
      state.swingT = undefined;
      state.swingPower = false;
      // Hand off to the post-swing settle below — capture last positions
      // so it can spring back instead of snap.
      state.swingSettleT = 0;
    }
  } else if (sword) {
    // Post-swing settle — spring sword/arm back with a tiny overshoot
    // so the recoil reads. Runs for ~0.18s after swingT clears.
    if (state.swingSettleT !== undefined) {
      state.swingSettleT += dt;
      const u = Math.min(1, state.swingSettleT / 0.18);
      // damped bounce: e^(-3u) * cos(8u)
      const damp = Math.exp(-u * 3);
      const wobble = damp * Math.cos(u * 8) * 0.06;
      sword.rotation.z = 0.1 + wobble;
      if (rArm) rArm.rotation.x = wobble * 0.5;
      if (body && Math.abs(body.rotation.x) > 0.001) {
        body.rotation.x *= 1 - Math.min(1, dt * 8);
      }
      if (u >= 1) state.swingSettleT = undefined;
    } else {
      // Idle: gently hold rest pose (tiny lerp covers any drift)
      sword.rotation.z = THREE.MathUtils.lerp(sword.rotation.z, 0.1, Math.min(1, dt * 8));
      if (body && Math.abs(body.rotation.x) > 0.001) {
        body.rotation.x = THREE.MathUtils.lerp(body.rotation.x, 0, Math.min(1, dt * 8));
      }
    }
  }

  // ---------- HURT RECOIL ----------
  if (state.hurtT > 0) {
    state.hurtT = Math.max(0, state.hurtT - dt);
    const u = state.hurtT / 0.25;
    if (body) body.position.z = -u * 0.08;
  } else if (body) {
    body.position.z = 0;
  }
}

/** Trigger a swing — call once per attack input. */
export function triggerSwing(state) { state.swingT = 0; state.swingPower = false; }
export function triggerPowerSwing(state) { state.swingT = 0; state.swingPower = true; }
/** Trigger a hurt flash — call once when player takes a hit. */
export function triggerHurt(state) { state.hurtT = 0.25; }
/** Trigger death — call once on HP=0; mesh tilts over 0.5s. */
export function triggerDeath(state) { state.deathT = 0.001; }
/** Reset death (after respawn). */
export function clearDeath(mesh, state) {
  state.deathT = 0;
  mesh.rotation.z = 0;
}
