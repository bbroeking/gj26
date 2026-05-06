// Mouse → world tile via raycaster against an invisible ground plane.
// Tracks left and right click separately so callers can route them
// (left = walk, right = walk + interact).
import * as THREE from 'three';
import { CONFIG } from '../data/config.js';

const COLS = CONFIG.world.cols;
const ROWS = CONFIG.world.rows;

const raycaster = new THREE.Raycaster();
const ndc = new THREE.Vector2();
const groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0); // y = 0

let lastLeft = null;
let lastRight = null;
// Continuous hover NDC — updated on mousemove regardless of click state.
const hoverNdc = new THREE.Vector2();
let hoverTracked = false;

// Camera orbit input — accumulated deltas drained each frame by the camera.
const cameraInput = { yaw: 0, pitch: 0, zoom: 0 };

// Drag state. ANY mouse button (left / middle / right) hold-and-drag rotates
// the camera. A click without dragging fires its normal action (left=walk,
// right=interact).
const DRAG_THRESHOLD = 5;     // pixels of total movement before "tap" → "drag"
const downState = {
  // per-button: { active, total, dragged }
  0: { active: false, total: 0, dragged: false },
  1: { active: false, total: 0, dragged: false },
  2: { active: false, total: 0, dragged: false },
};

function setRect(canvasEl, e) {
  const r = canvasEl.getBoundingClientRect();
  ndc.x = ((e.clientX - r.left) / r.width) * 2 - 1;
  ndc.y = -((e.clientY - r.top) / r.height) * 2 + 1;
}

export function attachMouse(canvasEl) {
  // Suppress the browser context menu always — we drive right-click ourselves.
  canvasEl.addEventListener('contextmenu', e => e.preventDefault());
  // suppress middle-click open-in-tab
  canvasEl.addEventListener('auxclick', e => { if (e.button === 1) e.preventDefault(); });

  // Mousedown — start tracking ANY button for drag-vs-tap detection
  canvasEl.addEventListener('mousedown', e => {
    const s = downState[e.button];
    if (!s) return;
    if (e.button !== 0) e.preventDefault();   // suppress middle/right defaults
    s.active = true;
    s.total = 0;
    s.dragged = false;
  });
  // Cursor: 'grabbing' once any button drags the orbit; cleared on
  // mouseup. Set on the canvas element so it doesn't bleed into UI.
  function _refreshCursor() {
    const dragging = downState[0].dragged || downState[1].dragged || downState[2].dragged;
    canvasEl.style.cursor = dragging ? 'grabbing' : '';
  }

  // Mouseup — fire tap action if it wasn't a drag
  window.addEventListener('mouseup', e => {
    const s = downState[e.button];
    if (!s || !s.active) return;
    s.active = false;
    if (!s.dragged) {
      setRect(canvasEl, e);
      if (e.button === 0)      lastLeft  = { ndc: ndc.clone() };
      else if (e.button === 2) lastRight = { ndc: ndc.clone(), screenX: e.clientX, screenY: e.clientY };
      // middle tap: no action
    }
    s.total = 0;
    s.dragged = false;
    _refreshCursor();
  });

  // Mousemove — accumulate per-button movement; while ANY is dragging, feed
  // orbit deltas. Also track continuous NDC for hover-tile lookup.
  window.addEventListener('mousemove', e => {
    setRect(canvasEl, e);
    hoverNdc.copy(ndc);
    hoverTracked = true;
    const moved = Math.hypot(e.movementX, e.movementY);
    let anyDragging = false;
    for (const k of [0, 1, 2]) {
      const s = downState[k];
      if (!s.active) continue;
      s.total += moved;
      if (s.total > DRAG_THRESHOLD) s.dragged = true;
      if (s.dragged) anyDragging = true;
    }
    if (anyDragging) {
      cameraInput.yaw   += e.movementX * 0.005;
      cameraInput.pitch += e.movementY * 0.005;
    }
    _refreshCursor();
  });
  canvasEl.addEventListener('mouseleave', () => { hoverTracked = false; });

  // Wheel zooms
  canvasEl.addEventListener('wheel', e => {
    e.preventDefault();
    cameraInput.zoom += e.deltaY * 0.01;
  }, { passive: false });

  // Keyboard fallback: brackets yaw, R/F pitch, +/- zoom.
  // (Q/E used to yaw the camera but Q is now Quick-quaff and E is
  // Interact, so we remap to []/{} for orbit nudge.)
  window.addEventListener('keydown', e => {
    const k = e.key.toLowerCase();
    const STEP = 0.05;
    if (k === '[')      cameraInput.yaw   -= STEP;
    else if (k === ']') cameraInput.yaw   += STEP;
    else if (k === 'r') cameraInput.pitch -= STEP;
    else if (k === 'f') cameraInput.pitch += STEP;
    else if (k === '=' || k === '+') cameraInput.zoom -= 0.5;
    else if (k === '-' || k === '_') cameraInput.zoom += 0.5;
  });
}

export function consumeCameraInput() {
  const r = { yaw: cameraInput.yaw, pitch: cameraInput.pitch, zoom: cameraInput.zoom };
  cameraInput.yaw = 0; cameraInput.pitch = 0; cameraInput.zoom = 0;
  return r;
}

export function isDraggingCamera() {
  return downState[0].dragged || downState[1].dragged || downState[2].dragged;
}

function project(record, camera) {
  if (!record) return null;
  raycaster.setFromCamera(record.ndc, camera);
  const hit = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(groundPlane, hit)) return null;
  const tx = Math.floor(hit.x);
  const ty = Math.floor(hit.z);
  if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) return null;
  return {
    x: tx, y: ty, world: hit,
    screenX: record.screenX, screenY: record.screenY,
  };
}

export function takeLeftClick(camera) {
  const r = lastLeft; lastLeft = null;
  return project(r, camera);
}
export function takeRightClick(camera) {
  const r = lastRight; lastRight = null;
  return project(r, camera);
}

/** Return the tile under the cursor right now, or null if the mouse
 *  isn't over the canvas. Doesn't drain — call freely each frame. */
export function getHoverTile(camera) {
  if (!hoverTracked) return null;
  return project({ ndc: hoverNdc }, camera);
}
