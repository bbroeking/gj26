// Approach B — three.js AnimationMixer driven by programmatically-authored
// AnimationClips. We build KeyframeTracks targeting our named knight parts,
// wrap them in AnimationClip, and crossfade between idle and walk.
//
// This works on plain Object3D hierarchies (no skeleton needed). It's the
// "official three.js" way to drive procedural-style motion, with the bonus
// that the AnimationMixer handles crossfade, weight, and timeScale for free.
import * as THREE from 'three';

// Helper: build a quaternion track that rotates a named child around X
// through the given keyframe samples.
function rotXTrack(targetName, times, anglesRad) {
  const q = new THREE.Quaternion();
  const values = new Float32Array(anglesRad.length * 4);
  for (let i = 0; i < anglesRad.length; i++) {
    q.setFromAxisAngle(new THREE.Vector3(1, 0, 0), anglesRad[i]);
    values[i * 4]     = q.x;
    values[i * 4 + 1] = q.y;
    values[i * 4 + 2] = q.z;
    values[i * 4 + 3] = q.w;
  }
  return new THREE.QuaternionKeyframeTrack(targetName + '.quaternion', times, values);
}

function posYTrack(targetName, times, ysRel, baseY) {
  // Outputs Vector3 (x, y, z) where x and z stay at 0 (the part's local origin).
  // baseY is the rest position; ysRel are deltas applied to it.
  const values = new Float32Array(ysRel.length * 3);
  for (let i = 0; i < ysRel.length; i++) {
    values[i * 3]     = 0;
    values[i * 3 + 1] = baseY + ysRel[i];
    values[i * 3 + 2] = 0;
  }
  return new THREE.VectorKeyframeTrack(targetName + '.position', times, values);
}

function scaleYTrack(targetName, times, scales) {
  const values = new Float32Array(scales.length * 3);
  for (let i = 0; i < scales.length; i++) {
    values[i * 3]     = 1;
    values[i * 3 + 1] = scales[i];
    values[i * 3 + 2] = 1;
  }
  return new THREE.VectorKeyframeTrack(targetName + '.scale', times, values);
}

/** Build an idle AnimationClip — gentle breath + head bob. ~2.4s loop. */
export function buildIdleClip() {
  const t = [0, 0.6, 1.2, 1.8, 2.4];
  return new THREE.AnimationClip('idle', 2.4, [
    scaleYTrack('body', t, [1.0, 1.02, 1.0, 0.98, 1.0]),
    posYTrack('body', t, [0, 0.01, 0, -0.01, 0], 0.65),
    rotXTrack('head', t, [0, 0.04, 0, -0.04, 0]),
  ]);
}

/** Build a walk AnimationClip — leg/arm swing + body bob. ~0.7s loop. */
export function buildWalkClip() {
  const t = [0, 0.175, 0.35, 0.525, 0.7];
  return new THREE.AnimationClip('walk', 0.7, [
    rotXTrack('lLeg', t, [ 0,  0.7, 0, -0.7, 0]),
    rotXTrack('rLeg', t, [ 0, -0.7, 0,  0.7, 0]),
    rotXTrack('lArm', t, [ 0, -0.5, 0,  0.5, 0]),
    rotXTrack('rArm', t, [ 0,  0.5, 0, -0.5, 0]),
    posYTrack('body', t, [0, 0.05, 0, 0.05, 0], 0.65),
    posYTrack('head', t, [0, 0.05, 0, 0.05, 0], 1.04),
  ]);
}

/** Build an attack-swing AnimationClip — sword arc + arm follow. ~0.45s, no loop. */
export function buildAttackClip() {
  const t = [0, 0.15, 0.3, 0.45];
  // Sword rotation Z (axis is Z because that's how the sword is oriented).
  const q = new THREE.Quaternion();
  const swordAngles = [0.1, 0.1 - 1.4, 0.1 + 2.2, 0.1];   // rest → wind-up → swing through → rest
  const swordVals = new Float32Array(swordAngles.length * 4);
  for (let i = 0; i < swordAngles.length; i++) {
    q.setFromAxisAngle(new THREE.Vector3(0, 0, 1), swordAngles[i]);
    swordVals[i * 4]     = q.x;
    swordVals[i * 4 + 1] = q.y;
    swordVals[i * 4 + 2] = q.z;
    swordVals[i * 4 + 3] = q.w;
  }
  return new THREE.AnimationClip('attack', 0.45, [
    new THREE.QuaternionKeyframeTrack('sword.quaternion', t, swordVals),
    rotXTrack('rArm', t, [0, -0.4, 1.2, 0]),
  ]);
}

/**
 * Wire a knight mesh to a mixer with idle/walk/attack actions.
 * Returns { mixer, actions: {idle, walk, attack}, setSpeed(speed) }.
 *
 * setSpeed(0..1) crossfades idle ↔ walk based on movement speed.
 */
export function setupKnightMixer(mesh) {
  const mixer = new THREE.AnimationMixer(mesh);
  const idle = mixer.clipAction(buildIdleClip());
  const walk = mixer.clipAction(buildWalkClip());
  const attack = mixer.clipAction(buildAttackClip());
  attack.setLoop(THREE.LoopOnce, 1);
  attack.clampWhenFinished = true;
  idle.play();
  walk.play();
  walk.setEffectiveWeight(0);

  let curSpeed = 0;
  const setSpeed = (target) => {
    // smooth weight blending so we don't need a separate crossfade call
    curSpeed = THREE.MathUtils.lerp(curSpeed, target, 0.2);
    walk.setEffectiveWeight(curSpeed);
    idle.setEffectiveWeight(1 - curSpeed);
    walk.setEffectiveTimeScale(0.6 + curSpeed * 0.6);
  };

  const triggerAttack = () => {
    attack.reset().fadeIn(0.05).play();
  };

  return { mixer, actions: { idle, walk, attack }, setSpeed, triggerAttack };
}
