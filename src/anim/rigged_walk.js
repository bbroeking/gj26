// Procedural walk-cycle driver for a Meshy auto-rigged GLB.
// The rig uses generic bone names (Bone_000..Bone_027 + neutral_bone). The
// mapping below was derived from the rest-pose world positions of the
// Mosscloak Ranger test rig — see the joint dump that produced this table.
//
//   Bone_000 = pelvis
//     Bone_003 / 002 / 001 = spine (low → high), Bone_013 = neck, Bone_012 = head
//     Bone_020 / 019 / 018 / 017 / 016 / 015 / 014 = LEFT  arm (shoulder → fingertip)
//     Bone_027 / 026 / 025 / 024 / 023 / 022 / 021 = RIGHT arm
//   Bone_007 / 006 / 005 / 004 = LEFT  leg (hip → toe)
//   Bone_011 / 010 / 009 / 008 = RIGHT leg
//
// Animation strategy: capture the bind-pose quaternion of every bone on
// first call, then each frame set `bone.quaternion = rest * deltaEuler`.
// Multiplying *on top* of rest preserves whatever twist/orientation the
// rigger baked in, so swing math stays in the bone's local frame.

import * as THREE from 'three';

const REST_KEY = '__riggedWalkRest';
const BONES_KEY = '__riggedWalkBones';
const T_KEY = '__riggedWalkT';

const _e = new THREE.Euler();
const _q = new THREE.Quaternion();

function ensureCaches(root) {
  if (root[BONES_KEY]) return root[BONES_KEY];
  const bones = {};
  const rest = {};
  root.traverse(o => {
    if (o.isBone) {
      bones[o.name] = o;
      rest[o.name] = o.quaternion.clone();
    }
  });
  root[BONES_KEY] = bones;
  root[REST_KEY] = rest;
  return bones;
}

function rotate(bones, rest, name, ex, ey, ez) {
  const b = bones[name];
  if (!b) return;
  _e.set(ex, ey, ez, 'XYZ');
  _q.setFromEuler(_e);
  b.quaternion.copy(rest[name]).multiply(_q);
}

/**
 * Drive a walk cycle on a Meshy-rigged biped. Call each frame with dt
 * in seconds. `cadenceHz` is full strides per second (default 1.5).
 */
export function animateRiggedWalk(root, dt, cadenceHz = 1.5) {
  const bones = ensureCaches(root);
  const rest = root[REST_KEY];
  root[T_KEY] = (root[T_KEY] || 0) + dt;
  const phase = root[T_KEY] * 2 * Math.PI * cadenceHz;
  const sp = Math.sin(phase);
  // Knee bend: only during the back-swing half of each leg's cycle. Peaks
  // when sin is most negative (foot lifting), eases back to 0 at footstrike.
  const lKneeBend = Math.max(0, -sp) * 0.9;
  const rKneeBend = Math.max(0,  sp) * 0.9;

  // Legs swing fore/aft (rotation around bone local X — Meshy / UniRig
  // convention uses Y-along-bone, so X-axis rotation tilts the bone in
  // the sagittal plane).
  rotate(bones, rest, 'Bone_007',  sp * 0.55, 0, 0);   // L hip
  rotate(bones, rest, 'Bone_011', -sp * 0.55, 0, 0);   // R hip
  rotate(bones, rest, 'Bone_006',  lKneeBend, 0, 0);   // L knee
  rotate(bones, rest, 'Bone_010',  rKneeBend, 0, 0);   // R knee

  // Arms counter-swing. Smaller amplitude than legs and OPPOSITE phase
  // (left arm forward when right leg forward).
  rotate(bones, rest, 'Bone_020', -sp * 0.45, 0, 0);   // L shoulder
  rotate(bones, rest, 'Bone_027',  sp * 0.45, 0, 0);   // R shoulder
  // Slight elbow flex, constant.
  rotate(bones, rest, 'Bone_018',  0.15, 0, 0);        // L elbow
  rotate(bones, rest, 'Bone_025',  0.15, 0, 0);        // R elbow

  // Spine: tiny counter-twist so shoulders rotate against hips.
  rotate(bones, rest, 'Bone_001', 0,  sp * 0.06, 0);   // chest
}

/** Hold T-pose / rest. Useful for static spawns before animation kicks in. */
export function resetRiggedPose(root) {
  ensureCaches(root);
  const rest = root[REST_KEY];
  const bones = root[BONES_KEY];
  for (const name in bones) bones[name].quaternion.copy(rest[name]);
}
