// Top-down grid-tween movement + interact dispatch.
// Re-usable across any top-down game; the dispatch table is injected.
import { TILE } from '../../core/canvas.js';
import { CONFIG } from '../../data/config.js';
import { isPressed, takeInteract } from '../../core/input.js';

const FACING = {
  down:  [0,  1],
  up:    [0, -1],
  left:  [-1, 0],
  right: [1,  0],
};

/**
 * @param {Object} player    state with x,y,px,py,dir,moving,bobT,attackCd,hurtT
 * @param {Function} isBlocked  (tx,ty,exclude?) => bool
 * @param {Function} interactAt (tx,ty) => bool — returns true if it found something
 * @param {Function} log         logger
 */
export function updatePlayerController(player, isBlocked, interactAt, log) {
  if (player.attackCd > 0) player.attackCd--;
  if (player.hurtT > 0) player.hurtT--;

  const tx = player.x * TILE;
  const ty = player.y * TILE;
  if (player.px !== tx || player.py !== ty) {
    const dx = Math.sign(tx - player.px);
    const dy = Math.sign(ty - player.py);
    player.px += dx * CONFIG.player.moveSpeed;
    player.py += dy * CONFIG.player.moveSpeed;
    if (Math.abs(player.px - tx) < CONFIG.player.moveSpeed) player.px = tx;
    if (Math.abs(player.py - ty) < CONFIG.player.moveSpeed) player.py = ty;
    player.moving = true;
    player.bobT++;
  } else {
    player.moving = false;
    player.bobT = 0;

    let dx = 0, dy = 0;
    if (isPressed('arrowup', 'w'))    { dy = -1; player.dir = 'up'; }
    else if (isPressed('arrowdown', 's')) { dy = 1; player.dir = 'down'; }
    else if (isPressed('arrowleft', 'a')) { dx = -1; player.dir = 'left'; }
    else if (isPressed('arrowright', 'd')) { dx = 1; player.dir = 'right'; }
    if (dx || dy) {
      const nx = player.x + dx;
      const ny = player.y + dy;
      if (!isBlocked(nx, ny)) {
        player.x = nx; player.y = ny;
      }
    }
  }

  if (!player.moving && takeInteract()) {
    const [dx, dy] = FACING[player.dir];
    const tx = player.x + dx;
    const ty = player.y + dy;
    if (!interactAt(tx, ty)) {
      // also try standing tile, then log a hint
      if (!interactAt(player.x, player.y)) log('hint', 'Nothing in front of you.');
    }
  }
}
