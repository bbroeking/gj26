// Player factory. State is plain — controllers and combat mutate it.
import { TILE } from '../core/canvas.js';
import { CONFIG } from '../data/config.js';
import { Inventory } from './inventory.js';
import { makeSkills } from './skills.js';
import { makeQuest } from './quest.js';

export function createPlayer(spawnX, spawnY) {
  return {
    x: spawnX, y: spawnY,
    spawnX, spawnY,
    px: spawnX * TILE, py: spawnY * TILE,
    dir: CONFIG.player.spawnFacing,
    moving: false,
    bobT: 0,
    hp: CONFIG.player.hpMax,
    hpMax: CONFIG.player.hpMax,
    attackCd: 0,
    hurtT: 0,
    skills: makeSkills(),
    inventory: new Inventory(),
    quest: makeQuest(),
  };
}
