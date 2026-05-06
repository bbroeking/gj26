// Camera follows a target (entity with px/py world coords), clamped to world.
import { VIEW_W, VIEW_H, WORLD_W, WORLD_H } from './canvas.js';

export const camera = { x: 0, y: 0 };

export function updateCamera(target) {
  const tx = target.px + 16 - VIEW_W / 2;
  const ty = target.py + 16 - VIEW_H / 2;
  camera.x = Math.max(0, Math.min(WORLD_W - VIEW_W, tx));
  camera.y = Math.max(0, Math.min(WORLD_H - VIEW_H, ty));
}
