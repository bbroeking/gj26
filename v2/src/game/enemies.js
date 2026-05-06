// Enemy entities (cows). Wander idle, aggro when player swings, attack adjacent.
import { TILE } from '../core/canvas.js';
import { rollEnemySwing, damagePlayer } from './combat.js';

function manhattan(a, b) { return Math.abs(a.x - b.x) + Math.abs(a.y - b.y); }

export function spawnCow(x, y) {
  return {
    kind: 'cow',
    x, y, homeX: x, homeY: y,
    px: x * TILE, py: y * TILE,
    hp: 8, hpMax: 8,
    atkLv: 1, defLv: 1, maxHit: 1,
    alive: true,
    aggro: false,
    hurtT: 0,
    attackCd: 0,
    moveT: Math.floor(Math.random() * 60),
    bobT: Math.random() * 100,
    respawn: 0,
    onDeath: (player, log) => {
      player.inventory.add('raw_beef', 1);
      player.inventory.add('cowhide', 1);
      log('combat', '+ Raw Beef, + Cowhide');
      if (player.quest) player.quest.cowKilled++;
    },
  };
}

export function updateEnemy(e, player, world, isBlocked, log) {
  if (!e.alive) {
    e.respawn--;
    if (e.respawn <= 0) {
      // re-place if home tile is free; else wait
      if (!isBlocked(e.homeX, e.homeY, e)) {
        e.x = e.homeX; e.y = e.homeY;
        e.px = e.x * TILE; e.py = e.y * TILE;
        e.hp = e.hpMax;
        e.alive = true; e.aggro = false;
      }
    }
    return;
  }

  if (e.hurtT > 0) e.hurtT--;
  if (e.attackCd > 0) e.attackCd--;

  // smooth tween to grid
  const tx = e.x * TILE, ty = e.y * TILE;
  if (e.px !== tx || e.py !== ty) {
    e.px += Math.sign(tx - e.px) * Math.min(2, Math.abs(tx - e.px));
    e.py += Math.sign(ty - e.py) * Math.min(2, Math.abs(ty - e.py));
    return;
  }

  e.bobT++;
  const d = manhattan(e, player);
  if (d <= 3) e.aggro = true;
  if (d > 7) e.aggro = false;

  if (e.aggro && d > 1) {
    e.moveT++;
    if (e.moveT < 35) return;
    e.moveT = 0;
    const dx = Math.sign(player.x - e.x);
    const dy = Math.sign(player.y - e.y);
    if (dx !== 0 && !isBlocked(e.x + dx, e.y, e)) e.x += dx;
    else if (dy !== 0 && !isBlocked(e.x, e.y + dy, e)) e.y += dy;
  } else if (e.aggro && d === 1) {
    if (e.attackCd <= 0) {
      e.attackCd = 75;
      const dmg = rollEnemySwing(e, player);
      damagePlayer(player, dmg, log, 'Cow');
    }
  } else {
    e.moveT++;
    if (e.moveT > 100 + Math.random() * 80) {
      e.moveT = 0;
      const choices = [[1, 0], [-1, 0], [0, 1], [0, -1]];
      const [dx, dy] = choices[Math.floor(Math.random() * 4)];
      const nx = e.x + dx, ny = e.y + dy;
      if (Math.abs(nx - e.homeX) <= 3 && Math.abs(ny - e.homeY) <= 3 && !isBlocked(nx, ny, e)) {
        e.x = nx; e.y = ny;
      }
    }
  }
}
