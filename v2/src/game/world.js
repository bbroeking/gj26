// Build the world from data/map.txt: tilegrid, blocked mask, entity spawns.
import { COLS, ROWS } from '../core/canvas.js';

export class World {
  constructor(mapText) {
    this.tileGrid = [];
    this.blocked = [];
    this.spawn = { x: 12, y: 11 };
    this.cookSpawn = null;
    this.firePos = null;
    this.cowSpawns = [];
    this.treePositions = [];

    const rows = mapText.split('\n').filter(r => r.length);
    for (let y = 0; y < ROWS; y++) {
      this.tileGrid.push([]);
      this.blocked.push([]);
      const row = rows[y];
      for (let x = 0; x < COLS; x++) {
        const ch = row[x];
        let tile = 'grass';
        let walk = true;
        switch (ch) {
          case 'W': tile = 'water'; walk = false; break;
          case 'S': tile = 'stone'; walk = false; break;
          case 'F': tile = 'floor'; break;
          case 'P': tile = 'path'; break;
          case '_': tile = 'sand'; break;
          case 'T': tile = 'grass'; walk = false; this.treePositions.push({ x, y }); break;
          case 'N': this.cookSpawn = { x, y }; break;
          case 'f': this.firePos = { x, y }; break;
          case 'c': this.cowSpawns.push({ x, y }); break;
          case 'X': this.spawn = { x, y }; break;
        }
        this.tileGrid[y].push(tile);
        this.blocked[y].push(!walk);
      }
    }
  }

  /** Returns true if (tx, ty) is unwalkable (terrain only — entities checked separately). */
  isTerrainBlocked(tx, ty) {
    if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) return true;
    return this.blocked[ty][tx];
  }
}
