// Orbit follow camera. Player is the orbit center; yaw / pitch / distance
// are controlled by middle-mouse drag + wheel (consumed from mouse.js each
// frame). Movement remains world-aligned (OSRS style).
import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { consumeCameraInput } from './mouse.js';

const PITCH_MIN = 0.18;            // ~10° — looking nearly horizontally
const PITCH_MAX = 1.40;            // ~80° — almost top-down
const DIST_MIN  = 4;
const DIST_MAX  = 22;

const state = {
  yaw:  0,                                 // rotation around world Y (radians)
  pitch: CONFIG.camera.pitch,              // initial RTS angle
  distance: CONFIG.camera.distance + 1,
  // current interpolated position (so rotations smooth out)
  cur: new THREE.Vector3(0, 10, 10),
  // Screen-shake decays linearly to 0 over `shakeDur`. Combat hit calls
  // `shakeCamera(amount)` which spikes shakeAmt; updateCamera samples it.
  shakeAmt: 0,
  shakeDur: 0.25,
  shakeElapsed: 0,
};

/** Trigger a brief camera shake. `amount` is the peak displacement in
 *  world units (typical: 0.06–0.20). Stronger hits → bigger shake. */
export function shakeCamera(amount = 0.10) {
  state.shakeAmt = Math.max(state.shakeAmt, amount);
  state.shakeElapsed = 0;
}

// FOV pulse — brief widen + ease back so big hits read cinematically.
// `amount` is the FOV delta in degrees (typical: 3–6). `dur` is total
// time in seconds.
let _fovBase = null;
let _fovPulseAmt = 0;
let _fovPulseDur = 0.18;
let _fovPulseT   = 0;
export function fovPulse(amount = 4, dur = 0.18) {
  _fovPulseAmt = Math.max(_fovPulseAmt, amount);
  _fovPulseDur = dur;
  _fovPulseT   = dur;
}

export function createCamera(aspect) {
  const cam = new THREE.PerspectiveCamera(CONFIG.camera.fov, aspect, 0.1, 250);
  cam.position.copy(state.cur);
  cam.lookAt(0, 0, 0);
  return cam;
}

const _target = new THREE.Vector3();
const _look = new THREE.Vector3();

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

export function updateCamera(cam, playerPos, dt = 0.016, snap = false) {
  // pull accumulated input from the mouse module
  const inp = consumeCameraInput();
  // User prefs (set in main.js settings panel). Yaw multiplier scales
  // mouse-drag sensitivity; invertPitch flips the pitch sign so mouse-up
  // tilts the camera away (instead of toward) the player.
  const prefs = (typeof window !== 'undefined' && window.__gj26_prefs) || {};
  const yawMul = prefs.camYaw ?? 1.0;
  const pitchSign = prefs.camInvert ? -1 : 1;
  state.yaw   += inp.yaw * yawMul;
  state.pitch  = clamp(state.pitch + inp.pitch * pitchSign, PITCH_MIN, PITCH_MAX);
  state.distance = clamp(state.distance + inp.zoom, DIST_MIN, DIST_MAX);

  // Spherical → cartesian, anchored on the player
  const horiz = Math.cos(state.pitch) * state.distance;
  const yOff  = Math.sin(state.pitch) * state.distance;
  _target.set(
    playerPos.x - Math.sin(state.yaw) * horiz,
    playerPos.y + yOff,
    playerPos.z - Math.cos(state.yaw) * horiz
  );

  if (snap) {
    state.cur.copy(_target);
  } else {
    // Lower constant = slightly more chase-lag, more cinematic.
    // Was 10 (very tight, "stuck-on" feel); 7 reads as a steadicam
    // operator following the player rather than locked to them.
    const k = 1 - Math.exp(-dt * 7);
    state.cur.lerp(_target, k);
  }
  cam.position.copy(state.cur);
  // Screen-shake offset — small random jitter for the duration of the
  // shake, decaying to 0. Applied AFTER lerp so it doesn't get smoothed.
  if (state.shakeAmt > 0) {
    state.shakeElapsed += dt;
    const t = state.shakeElapsed / state.shakeDur;
    if (t >= 1) {
      state.shakeAmt = 0;
    } else {
      const k = state.shakeAmt * (1 - t);
      cam.position.x += (Math.random() - 0.5) * k;
      cam.position.y += (Math.random() - 0.5) * k * 0.5;
      cam.position.z += (Math.random() - 0.5) * k;
    }
  }
  // FOV pulse — capture the original FOV the first time we touch it,
  // then ease it back so the camera doesn't drift cumulatively.
  if (_fovBase === null) _fovBase = cam.fov;
  if (_fovPulseT > 0) {
    _fovPulseT = Math.max(0, _fovPulseT - dt);
    const u = _fovPulseT / _fovPulseDur;       // 1 → 0
    const k = u * u;                           // ease-out (faster snap-back)
    cam.fov = _fovBase + _fovPulseAmt * k;
    cam.updateProjectionMatrix();
    if (_fovPulseT === 0) {
      cam.fov = _fovBase;
      cam.updateProjectionMatrix();
      _fovPulseAmt = 0;
    }
  }
  _look.copy(playerPos);
  cam.lookAt(_look);
}

/** Read-only view of camera orbit state — useful for HUD display / debug. */
export function getCameraState() {
  return { yaw: state.yaw, pitch: state.pitch, distance: state.distance };
}
