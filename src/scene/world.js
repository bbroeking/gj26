// World: parses map.txt, builds the 3D scene (terrain + obstacles),
// exposes spawn coords + a tile-grid for collision.
import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { terrainHeightAt, colorNoise } from './terrain.js';
import {
  buildStoneWallTile, buildWoodFloorTile,
  buildWaterTile,
  buildOakMesh, buildPineMesh, buildDeadTreeMesh,
  buildRockCluster, buildMushroom, buildHutRoof, buildBush,
  makeFlowerAssets, buildFenceSegment, buildLilyPad, buildLantern,
} from './characters.js';

const COLS = CONFIG.world.cols;
const ROWS = CONFIG.world.rows;

export class World {
  constructor(mapText, scene) {
    this.scene = scene;
    this.tileGrid = [];   // ['grass', 'stone', ...] per cell
    this.blocked = [];    // bool per cell
    this.spawn = { x: 12, y: 11 };
    this.cookSpawn = null;
    this.firePos = null;
    this.cowSpawns = [];
    this.goblinSpawns = [];
    this.treePositions = [];
    this.trees = [];          // [{x,y,mesh,kind,chops,respawn}] populated in _build3D
    this.forageSpawns = [];   // [{x,y,mesh,kind,respawn}] populated in _build3D
    this.oreNodes = [];       // [{x,y,mesh,kind,item,depleted,respawn}]

    // ---- Wayfinding: discovered-tile tracking. The player's primary
    // distinguishing verb (per docs/WORLD_BIBLE.md and the recent design
    // pivot away from OSRS-clone). Walking onto a tile for the first
    // time awards Wayfinding XP and reveals the tile. `chartable` is
    // the denominator — only walkable terrain counts toward 100%.
    this.discovered = new Set();   // 'x,y' keys
    this.chartable = 0;            // total walkable tiles

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
          case 'g': this.goblinSpawns.push({ x, y }); break;
          case 'X': this.spawn = { x, y }; break;
        }
        this.tileGrid[y].push(tile);
        this.blocked[y].push(!walk);
        if (walk) this.chartable++;
      }
    }

    // Seed the ring around spawn as already-discovered (you arrived; you
    // can see the immediate surroundings). Does NOT award XP.
    this.revealAround(this.spawn.x, this.spawn.y, 3, /*awardOwner*/ null);

    this._build3D();
  }

  /** Mark tiles in `radius` around (cx,cy) as discovered. Returns the
   *  number of *newly* discovered tiles (caller can award XP per tile). */
  revealAround(cx, cy, radius = 5) {
    let newly = 0;
    const r2 = radius * radius;
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        if (dx*dx + dy*dy > r2) continue;
        const x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= COLS || y >= ROWS) continue;
        // Only walkable tiles count toward chartability; un-walkable tiles
        // (water, stone, trees) get revealed too but don't gate progress.
        const key = x + ',' + y;
        if (this.discovered.has(key)) continue;
        this.discovered.add(key);
        if (!this.blocked[y][x]) newly++;
      }
    }
    return newly;
  }

  /** Lookup: is this tile in the player's known map? */
  isCharted(x, y) {
    return this.discovered.has(x + ',' + y);
  }

  // 3D world coordinate from grid (col, row)
  static toWorld(x, y) {
    return new THREE.Vector3(x + 0.5, 0, y + 0.5);
  }

  _build3D() {
    // ---- HEIGHTMAP TERRAIN ----
    // One mesh covers the entire map. Vertices are displaced by the noise
    // function in terrain.js; entity placement uses the same function so
    // everything sits on the actual surface.
    const terrain = this._buildTerrainMesh();
    this.scene.add(terrain);
    this.terrain = terrain;

    // Vertical grass blades — InstancedMesh w/ wind sway via shader injection.
    const bladeGeo = new THREE.PlaneGeometry(0.08, 0.22);
    bladeGeo.translate(0, 0.11, 0);
    const bladeMat = new THREE.MeshStandardMaterial({
      color: 0x4a7a2f, side: THREE.DoubleSide, flatShading: true,
      roughness: 1.0, metalness: 0,
    });
    bladeMat.onBeforeCompile = (shader) => {
      shader.uniforms.uTime = { value: 0 };
      shader.vertexShader = 'uniform float uTime;\n' + shader.vertexShader;
      shader.vertexShader = shader.vertexShader.replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
         vec4 wp = instanceMatrix * vec4(transformed, 1.0);
         float swayAmt = step(0.05, position.y);
         float swayPhase = uTime * 1.6 + wp.x * 0.5 + wp.z * 0.4;
         transformed.x += sin(swayPhase) * 0.05 * swayAmt;
         transformed.z += cos(swayPhase * 0.7) * 0.03 * swayAmt;`
      );
      bladeMat.userData.shader = shader;
    };
    const bladeCount = Math.min(1200, COLS * ROWS / 2);
    const blades = new THREE.InstancedMesh(bladeGeo, bladeMat, bladeCount);
    const tmp = new THREE.Object3D();
    let placed = 0;
    for (let i = 0; placed < bladeCount && i < bladeCount * 4; i++) {
      const x = Math.random() * COLS;
      const z = Math.random() * ROWS;
      const tx = Math.floor(x), ty = Math.floor(z);
      if (this.tileGrid[ty]?.[tx] !== 'grass' || this.blocked[ty]?.[tx]) continue;
      tmp.position.set(x, terrainHeightAt(x, z), z);
      tmp.rotation.y = Math.random() * Math.PI;
      tmp.scale.setScalar(0.7 + Math.random() * 0.6);
      tmp.updateMatrix();
      blades.setMatrixAt(placed++, tmp.matrix);
    }
    blades.count = placed;
    blades.castShadow = false;
    blades.receiveShadow = false;
    this.scene.add(blades);
    this.blades = blades;
    this.bladeMat = bladeMat;

    // Detect rectangular building footprints (connected S+F tiles). Stone
    // tiles inside a building footprint are NOT rendered as individual
    // gray cubes — main.js places a cottage GLB over each footprint
    // instead. Floors still render so the building has a wood floor.
    this.buildings = this._detectBuildings();
    const inBuilding = new Set();
    for (const b of this.buildings) {
      for (let y = b.y; y < b.y + b.h; y++) {
        for (let x = b.x; x < b.x + b.w; x++) inBuilding.add(`${x},${y}`);
      }
    }

    // Tile-specific solid meshes (path + sand are now baked into terrain
    // vertex colors, so they don't appear here).
    for (let y = 0; y < ROWS; y++) {
      for (let x = 0; x < COLS; x++) {
        const t = this.tileGrid[y][x];
        let m;
        if (t === 'stone') {
          if (inBuilding.has(`${x},${y}`)) continue;   // cottage GLB will cover it
          m = buildStoneWallTile();
        }
        else if (t === 'floor') m = buildWoodFloorTile();
        else if (t === 'water') m = buildWaterTile();
        if (m) {
          m.position.x += x + 0.5;
          m.position.z += y + 0.5;
          // walls and floor sit on the terrain surface
          m.position.y += terrainHeightAt(x + 0.5, y + 0.5);
          this.scene.add(m);
        }
      }
    }

    // trees — pick variant by stable hash so map looks intentional, not random
    for (const t of this.treePositions) {
      const hash = (t.x * 374761393 + t.y * 668265263) >>> 0;
      const r = hash / 4294967295;
      let mesh, kind;
      if (t.y <= 6 && r < 0.55)       { mesh = buildPineMesh();    kind = 'pine'; }
      else if (r < 0.05)              { mesh = buildDeadTreeMesh(); kind = 'dead'; }
      else if (r < 0.55)              { mesh = buildOakMesh();     kind = 'oak';  }
      else                            { mesh = buildPineMesh();    kind = 'pine'; }
      mesh.position.set(t.x + 0.5, terrainHeightAt(t.x + 0.5, t.y + 0.5), t.y + 0.5);
      mesh.rotation.y = r * Math.PI * 2;
      mesh.scale.setScalar(0.85 + (r * 7919 % 1) * 0.4);
      this.scene.add(mesh);
      this.trees.push({
        x: t.x, y: t.y, mesh, kind,
        chopsRemaining: kind === 'oak' ? 3 : 0,  // only oaks chop-able for now
        respawn: 0,
        depleted: false,
      });
    }

    // ---- FORAGING SPAWNS ----
    // Sprinkle 14 foragable nodes on grass tiles. Each cycles through
    // {berry / mushroom / herb} types with respawn timers.
    this._scatterForageSpawns(14);

    // ---- ORE NODES ----
    // Scatter 10 mining nodes (copper + tin alternating) on grass tiles.
    this._scatterOreNodes(10);

    // hut roof disabled — top-down camera can't see indoors when a roof
    // closes the building. Cottage GLBs have their thatch hidden in
    // main.js for the same reason.

    // decorative props — rocks + mushrooms + bushes scattered on grass tiles
    this._scatterDecorations();

    // distant mountain ring beyond the playable map for sense of scale
    this._buildDistantMountains();

    // detail props
    this._scatterFlowers();
    this._buildFenceAlongPath();
    this._addLilyPads();
    this._addHutLantern();
  }

  _scatterFlowers() {
    const FA = makeFlowerAssets();
    // Three colored variants — group flowers per color into one InstancedMesh
    const variants = [
      { mat: FA.headMatRed,    target: 36 },
      { mat: FA.headMatYellow, target: 36 },
      { mat: FA.headMatPink,   target: 24 },
    ];
    const total = variants.reduce((s, v) => s + v.target, 0);
    // shared stem instanced mesh
    const stems = new THREE.InstancedMesh(FA.stemGeo, FA.stemMat, total);
    const heads = variants.map(v => new THREE.InstancedMesh(FA.headGeo, v.mat, v.target));
    const tmp = new THREE.Object3D();
    let stemI = 0;
    for (const variant of variants) {
      let placed = 0;
      for (let attempts = 0; placed < variant.target && attempts < variant.target * 8; attempts++) {
        const x = Math.random() * COLS;
        const z = Math.random() * ROWS;
        const tx = Math.floor(x), ty = Math.floor(z);
        if (this.tileGrid[ty]?.[tx] !== 'grass' || this.blocked[ty]?.[tx]) continue;
        const y = terrainHeightAt(x, z);
        tmp.position.set(x, y, z);
        tmp.rotation.y = Math.random() * Math.PI * 2;
        tmp.scale.setScalar(0.85 + Math.random() * 0.4);
        tmp.updateMatrix();
        stems.setMatrixAt(stemI++, tmp.matrix);
        heads[variants.indexOf(variant)].setMatrixAt(placed++, tmp.matrix);
      }
      heads[variants.indexOf(variant)].count = placed;
    }
    stems.count = stemI;
    this.scene.add(stems);
    for (const h of heads) this.scene.add(h);
  }

  _buildFenceAlongPath() {
    // Find the long horizontal path row, fence both sides of it where the
    // adjacent tile is grass.
    const pathTiles = [];
    for (let y = 0; y < ROWS; y++) {
      for (let x = 0; x < COLS; x++) {
        if (this.tileGrid[y][x] === 'path') pathTiles.push({ x, y });
      }
    }
    if (pathTiles.length === 0) return;
    // Figure out the dominant path row
    const yCounts = new Map();
    for (const p of pathTiles) yCounts.set(p.y, (yCounts.get(p.y) || 0) + 1);
    let bestRow = 0, bestCount = 0;
    for (const [y, c] of yCounts) if (c > bestCount) { bestRow = y; bestCount = c; }
    const xs = pathTiles.filter(p => p.y === bestRow).map(p => p.x).sort((a, b) => a - b);
    const minX = xs[0], maxX = xs[xs.length - 1];
    // Place fence segments every other tile, both sides
    for (let x = minX; x < maxX; x += 1) {
      for (const sideY of [bestRow - 1, bestRow + 1]) {
        if (sideY < 0 || sideY >= ROWS) continue;
        if (this.tileGrid[sideY][x] !== 'grass') continue;
        if (Math.random() < 0.4) continue; // skip some for variety
        const seg = buildFenceSegment();
        seg.position.set(x + 0.5, terrainHeightAt(x + 0.5, sideY + 0.5), sideY + 0.5);
        seg.rotation.y = 0;
        this.scene.add(seg);
      }
    }
  }

  _addLilyPads() {
    // Place 8-12 lily pads along the inner edge of the south water border
    // so they're visible from the playable area.
    const placed = new Set();
    let n = 0;
    for (let attempts = 0; n < 12 && attempts < 200; attempts++) {
      const tx = 5 + Math.floor(Math.random() * (COLS - 10));
      const ty = ROWS - 1;  // bottom water row
      const k = tx + ',' + ty;
      if (placed.has(k)) continue;
      placed.add(k);
      const pad = buildLilyPad();
      pad.position.set(tx + 0.5 + (Math.random() - 0.5) * 0.4, 0.05,
                       ty + 0.5 + (Math.random() - 0.5) * 0.4);
      pad.rotation.y = Math.random() * Math.PI * 2;
      pad.scale.setScalar(0.8 + Math.random() * 0.4);
      // hide flower on most
      if (Math.random() > 0.4) pad.getObjectByName('flower').visible = false;
      this.scene.add(pad);
      n++;
    }
  }

  _addHutLantern() {
    // Find the floor tile just south of the wall row (door area) and place
    // a lantern there as a visible welcome light.
    if (!this.cookSpawn) return;
    // Place a few tiles east of the cook, on grass
    const lx = this.cookSpawn.x + 4;
    const ly = this.cookSpawn.y + 3;
    if (lx >= COLS || ly >= ROWS) return;
    const lantern = buildLantern();
    lantern.position.set(lx + 0.5, terrainHeightAt(lx + 0.5, ly + 0.5), ly + 0.5);
    this.scene.add(lantern);
    // attach a small warm point light to it (subtler than the fire's)
    const light = new THREE.PointLight(0xffd884, 0.8, 5, 1.6);
    light.position.set(lx + 0.5 + 0.32, terrainHeightAt(lx + 0.5, ly + 0.5) + 1.18, ly + 0.5);
    this.scene.add(light);
    this.lanternLight = light;
  }

  _buildDistantMountains() {
    // Hazy, fog-tinted cones placed in a ring well past the water border.
    // Use MeshBasicMaterial so they don't react to lighting (look distant).
    const ringR = Math.max(COLS, ROWS) * 1.3;
    const cx = COLS / 2, cz = ROWS / 2;
    const peakColor = 0x9bb1c4;
    const baseColor = 0x6f8aa0;
    const peaks = 22;
    for (let i = 0; i < peaks; i++) {
      const angle = (i / peaks) * Math.PI * 2 + Math.random() * 0.18;
      const r = ringR + Math.random() * 8;
      const px = cx + Math.cos(angle) * r;
      const pz = cz + Math.sin(angle) * r;
      const h = 8 + Math.random() * 14;
      const w = 6 + Math.random() * 6;
      const mtn = new THREE.Mesh(
        new THREE.ConeGeometry(w, h, 6),
        new THREE.MeshBasicMaterial({
          color: Math.random() < 0.6 ? baseColor : peakColor,
          fog: true,
        })
      );
      mtn.position.set(px, h / 2 - 1, pz);
      mtn.rotation.y = Math.random() * Math.PI;
      this.scene.add(mtn);
    }
    // Snow caps on a few of the tallest — separate small white cones.
    for (let i = 0; i < 6; i++) {
      const angle = Math.random() * Math.PI * 2;
      const r = ringR + Math.random() * 6;
      const px = cx + Math.cos(angle) * r;
      const pz = cz + Math.sin(angle) * r;
      const cap = new THREE.Mesh(
        new THREE.ConeGeometry(2.2, 3, 6),
        new THREE.MeshBasicMaterial({ color: 0xf2f4f8, fog: true })
      );
      cap.position.set(px, 14, pz);
      this.scene.add(cap);
    }
  }

  /**
   * Flood-fill connected groups of stone+floor tiles and return their
   * axis-aligned bounding rects. Each rect is one building. We require
   * a minimum 3×3 footprint so a single stray 'S' decoration doesn't
   * become a cottage. Walls (S) without an adjacent floor (F) are not
   * treated as buildings — they may be decorative pillars.
   */
  _detectBuildings() {
    const visited = new Uint8Array(COLS * ROWS);
    const buildings = [];
    const isPart = (x, y) => {
      if (x < 0 || y < 0 || x >= COLS || y >= ROWS) return false;
      const t = this.tileGrid[y][x];
      return t === 'stone' || t === 'floor';
    };
    for (let y = 0; y < ROWS; y++) {
      for (let x = 0; x < COLS; x++) {
        if (visited[y * COLS + x]) continue;
        if (!isPart(x, y)) continue;
        // BFS this connected component
        const stack = [[x, y]];
        let minX = x, maxX = x, minY = y, maxY = y;
        let hasFloor = false;
        while (stack.length) {
          const [cx, cy] = stack.pop();
          if (visited[cy * COLS + cx]) continue;
          visited[cy * COLS + cx] = 1;
          if (this.tileGrid[cy][cx] === 'floor') hasFloor = true;
          if (cx < minX) minX = cx;
          if (cx > maxX) maxX = cx;
          if (cy < minY) minY = cy;
          if (cy > maxY) maxY = cy;
          for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
            const nx = cx + dx, ny = cy + dy;
            if (isPart(nx, ny) && !visited[ny * COLS + nx]) stack.push([nx, ny]);
          }
        }
        const w = maxX - minX + 1;
        const h = maxY - minY + 1;
        if (hasFloor && w >= 3 && h >= 3) {
          buildings.push({ x: minX, y: minY, w, h });
        }
      }
    }
    return buildings;
  }

  _placeHutRoof() {
    // find the stone-wall bounding box (NW castle)
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    for (let y = 0; y < ROWS; y++) {
      for (let x = 0; x < COLS; x++) {
        if (this.tileGrid[y][x] === 'stone') {
          if (x < minX) minX = x;  if (y < minY) minY = y;
          if (x > maxX) maxX = x;  if (y > maxY) maxY = y;
        }
      }
    }
    if (minX === Infinity) return;
    const fw = maxX - minX + 1;
    const fh = maxY - minY + 1;
    const cx = (minX + maxX) / 2 + 0.5;
    const cz = (minY + maxY) / 2 + 0.5;
    const roof = buildHutRoof(fw, fh);
    roof.position.set(cx, 0, cz);
    this.scene.add(roof);
  }

  _scatterForageSpawns(target) {
    // Build a small "berry bush" mesh: 3-cluster of small icospheres on a stem.
    // We use scene primitives directly (cheaper than another asset import) and
    // tag mesh.userData so click-handling can identify them.
    const variants = [
      { kind: 'berry',    item: 'whitleberry',   color: 0x6633aa, scale: 1.0 },
      { kind: 'mushroom', item: 'hedgecap', color: 0xc0392b, scale: 0.95 },
      { kind: 'herb',     item: 'wishrose',   color: 0x4a7a2f, scale: 1.05 },
    ];
    const placed = new Set();
    let n = 0;
    for (let attempt = 0; n < target && attempt < target * 30; attempt++) {
      const tx = 1 + Math.floor(Math.random() * (CONFIG.world.cols - 2));
      const ty = 1 + Math.floor(Math.random() * (CONFIG.world.rows - 2));
      const key = tx + ',' + ty;
      if (placed.has(key)) continue;
      if (this.tileGrid[ty]?.[tx] !== 'grass' || this.blocked[ty]?.[tx]) continue;
      // avoid spawn / cook / fire
      if (tx === this.spawn.x && ty === this.spawn.y) continue;
      if (this.cookSpawn && tx === this.cookSpawn.x && ty === this.cookSpawn.y) continue;
      if (this.firePos && tx === this.firePos.x && ty === this.firePos.y) continue;
      placed.add(key);
      const v = variants[n % variants.length];
      const mesh = this._buildForageNode(v.color, v.scale);
      mesh.position.set(tx + 0.5, terrainHeightAt(tx + 0.5, ty + 0.5), ty + 0.5);
      mesh.rotation.y = Math.random() * Math.PI * 2;
      this.scene.add(mesh);
      this.forageSpawns.push({
        x: tx, y: ty, mesh,
        kind: v.kind, item: v.item,
        depleted: false, respawn: 0,
      });
      n++;
    }
  }

  _buildForageNode(color, scale) {
    const grp = new THREE.Group();
    const stemMat = new THREE.MeshStandardMaterial({
      color: 0x4a7a2f, roughness: 1, metalness: 0, flatShading: true,
    });
    const headMat = new THREE.MeshStandardMaterial({
      color, roughness: 0.85, metalness: 0, flatShading: true,
    });
    // stem (small green cube)
    const stem = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.12, 0.06), stemMat);
    stem.position.y = 0.06;
    grp.add(stem);
    // 3 head icos clustered
    for (const off of [[-0.06, 0.18, 0], [0.06, 0.20, 0.05], [0, 0.22, -0.05]]) {
      const head = new THREE.Mesh(new THREE.IcosahedronGeometry(0.07, 0), headMat);
      head.position.set(off[0], off[1], off[2]);
      grp.add(head);
    }
    grp.scale.setScalar(scale);
    return grp;
  }

  _scatterOreNodes(target) {
    // Variant rotation = round-robin so the player sees each ore type. Iron
    // rocks are slightly rarer and darker, sit alongside copper + tin.
    const variants = [
      { kind: 'copper', item: 'mosswort_ore', color: 0xb8722e },
      { kind: 'tin',    item: 'palechalk_ore',    color: 0xa8a8b0 },
      { kind: 'copper', item: 'mosswort_ore', color: 0xb8722e },   // bias toward copper
      { kind: 'iron',   item: 'bogiron_ore',   color: 0x6b3e2a },
      { kind: 'coal',   item: 'coalrose',   color: 0x1c1c20 },   // glossy black
    ];
    const placed = new Set();
    let n = 0;
    for (let attempt = 0; n < target && attempt < target * 30; attempt++) {
      const tx = 1 + Math.floor(Math.random() * (CONFIG.world.cols - 2));
      const ty = 1 + Math.floor(Math.random() * (CONFIG.world.rows - 2));
      const key = tx + ',' + ty;
      if (placed.has(key)) continue;
      if (this.tileGrid[ty]?.[tx] !== 'grass' || this.blocked[ty]?.[tx]) continue;
      if (tx === this.spawn.x && ty === this.spawn.y) continue;
      // Avoid colliding with forage spawns
      if (this.forageSpawns.some(s => s.x === tx && s.y === ty)) continue;
      // Avoid trees
      if (this.treePositions.some(t => t.x === tx && t.y === ty)) continue;
      placed.add(key);
      const v = variants[n % variants.length];
      const mesh = this._buildOreNode(v.color);
      mesh.position.set(tx + 0.5, terrainHeightAt(tx + 0.5, ty + 0.5), ty + 0.5);
      mesh.rotation.y = Math.random() * Math.PI * 2;
      this.scene.add(mesh);
      this.oreNodes.push({
        x: tx, y: ty, mesh,
        kind: v.kind, item: v.item,
        chopsRemaining: 3,
        depleted: false, respawn: 0,
      });
      n++;
    }
  }

  _buildOreNode(color) {
    const grp = new THREE.Group();
    const oreMat = new THREE.MeshStandardMaterial({
      color, roughness: 0.85, metalness: 0.3, flatShading: true,
    });
    const stoneMat = new THREE.MeshStandardMaterial({
      color: 0x6e6e76, roughness: 1, metalness: 0, flatShading: true,
    });
    // 3 stacked dodecahedrons (rocks) + 2 small ore icospheres on top
    const sizes = [0.32, 0.24, 0.18];
    const offsets = [[0, 0, 0], [0.28, 0, -0.12], [-0.18, 0, 0.18]];
    for (let i = 0; i < 3; i++) {
      const r = sizes[i];
      const rock = new THREE.Mesh(new THREE.DodecahedronGeometry(r, 0), stoneMat);
      rock.position.set(offsets[i][0], r * 0.5, offsets[i][2]);
      rock.rotation.set(Math.random(), Math.random(), Math.random());
      grp.add(rock);
    }
    // Ore lumps showing color
    for (const o of [[0.05, 0.45, -0.05], [-0.10, 0.35, 0.12]]) {
      const lump = new THREE.Mesh(new THREE.IcosahedronGeometry(0.08, 0), oreMat);
      lump.position.set(o[0], o[1], o[2]);
      grp.add(lump);
    }
    grp.traverse(o => { o.castShadow = true; o.receiveShadow = true; });
    return grp;
  }

  /** Mine an ore node at (x,y). Returns the node if depleted. */
  mineOreAt(x, y) {
    const node = this.oreNodes.find(n => n.x === x && n.y === y && !n.depleted);
    if (!node) return null;
    node.chopsRemaining = Math.max(0, node.chopsRemaining - 1);
    if (node.chopsRemaining <= 0) {
      node.depleted = true;
      node.mesh.visible = false;
      node.respawn = 60 * 30;
      return node;
    }
    return null;
  }

  /** Mark a tree at (x,y) chopped. Returns the tree if depleted. */
  chopTreeAt(x, y) {
    const tree = this.trees.find(t => t.x === x && t.y === y && !t.depleted);
    if (!tree) return null;
    tree.chopsRemaining = Math.max(0, tree.chopsRemaining - 1);
    if (tree.chopsRemaining <= 0) {
      tree.depleted = true;
      tree.mesh.visible = false;
      tree.respawn = 60 * 30;  // ~30 seconds @ 60fps frame budget
      return tree;
    }
    return null;
  }

  /** Mark a forage spawn picked. Returns the picked spawn. */
  pickForageAt(x, y) {
    const f = this.forageSpawns.find(s => s.x === x && s.y === y && !s.depleted);
    if (!f) return null;
    f.depleted = true;
    f.mesh.visible = false;
    f.respawn = 60 * 25;       // 25s respawn
    return f;
  }

  /** Per-frame tick for tree + forage respawns. */
  tickRespawns() {
    for (const t of this.trees) {
      if (!t.depleted) continue;
      t.respawn--;
      if (t.respawn <= 0) {
        t.depleted = false;
        t.chopsRemaining = t.kind === 'oak' ? 3 : 0;
        t.mesh.visible = true;
      }
    }
    for (const s of this.forageSpawns) {
      if (!s.depleted) continue;
      s.respawn--;
      if (s.respawn <= 0) {
        s.depleted = false;
        s.mesh.visible = true;
      }
    }
    for (const n of this.oreNodes) {
      if (!n.depleted) continue;
      n.respawn--;
      if (n.respawn <= 0) {
        n.depleted = false;
        n.chopsRemaining = 3;
        n.mesh.visible = true;
      }
    }
  }

  _scatterDecorations() {
    let rocks = 0, shrooms = 0, bushes = 0;
    const TARGET_ROCKS = 25, TARGET_SHROOMS = 18, TARGET_BUSHES = 60;
    for (let i = 0; i < 4000 && (rocks < TARGET_ROCKS || shrooms < TARGET_SHROOMS || bushes < TARGET_BUSHES); i++) {
      const x = Math.random() * COLS;
      const z = Math.random() * ROWS;
      const tx = Math.floor(x), ty = Math.floor(z);
      if (this.tileGrid[ty]?.[tx] !== 'grass' || this.blocked[ty]?.[tx]) continue;
      if (tx === this.spawn.x && ty === this.spawn.y) continue;
      const r = Math.random();
      const y = terrainHeightAt(x, z);
      if (r < 0.20 && rocks < TARGET_ROCKS) {
        const rock = buildRockCluster();
        rock.position.set(x, y, z);
        rock.rotation.y = Math.random() * Math.PI * 2;
        rock.scale.setScalar(0.8 + Math.random() * 0.5);
        this.scene.add(rock);
        rocks++;
      } else if (r < 0.30 && shrooms < TARGET_SHROOMS) {
        const m = buildMushroom();
        m.position.set(x, y, z);
        m.rotation.y = Math.random() * Math.PI * 2;
        this.scene.add(m);
        shrooms++;
      } else if (bushes < TARGET_BUSHES) {
        const b = buildBush();
        b.position.set(x, y, z);
        b.rotation.y = Math.random() * Math.PI * 2;
        b.scale.setScalar(0.85 + Math.random() * 0.35);
        this.scene.add(b);
        bushes++;
      }
    }
  }

  isTerrainBlocked(tx, ty) {
    if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) return true;
    return this.blocked[ty][tx];
  }

  /**
   * Surface height matching the rendered terrain (terrain noise lerped
   * toward -0.4 near water tiles). Use for entity y-placement.
   */
  surfaceHeightAt(x, z) {
    const tx = Math.floor(x), ty = Math.floor(z);
    let n = 0, total = 0;
    for (const [dx, dz] of [[-1,-1],[0,-1],[-1,0],[0,0]]) {
      const ax = tx + dx, ay = ty + dz;
      if (ax < 0 || ay < 0 || ax >= COLS || ay >= ROWS) continue;
      total++;
      if (this.tileGrid[ay][ax] === 'water') n++;
    }
    let y = terrainHeightAt(x, z);
    const w = total ? n / total : 0;
    if (w > 0) y = y * (1 - w) + (-0.4) * w;
    return y;
  }

  /**
   * Build the displaced + vertex-colored ground mesh. Generates a
   * (COLS+1)×(ROWS+1) grid of vertices so each grid intersection has its own
   * height + color. Color at a vertex is the average of the (up to four)
   * adjacent tile colors with deterministic noise variation, giving soft
   * blends between grass / path / sand.
   */
  _buildTerrainMesh() {
    const positions = [];
    const colors = [];
    const indices = [];
    const grassA = [0.27, 0.46, 0.18];
    const grassB = [0.41, 0.62, 0.25];
    const pathC  = [0.78, 0.62, 0.46];
    const sandC  = [0.85, 0.74, 0.56];
    const stoneC = [0.45, 0.45, 0.50];

    const tileColor = (t) => {
      switch (t) {
        case 'path':  return pathC;
        case 'sand':  return sandC;
        case 'stone': return stoneC;     // mostly hidden under wall mesh
        case 'floor': return [0.40, 0.27, 0.13];
        case 'water': return [0.27, 0.42, 0.66];
        default:      return null;        // grass — chosen per-vertex
      }
    };

    const vertexColor = (vx, vz) => {
      // average colors of up-to-4 surrounding tiles
      let r = 0, g = 0, b = 0, n = 0;
      for (const [dx, dz] of [[-1,-1],[0,-1],[-1,0],[0,0]]) {
        const tx = vx + dx, ty = vz + dz;
        if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) continue;
        const t = this.tileGrid[ty][tx];
        const c = tileColor(t);
        if (c) {
          r += c[0]; g += c[1]; b += c[2]; n++;
        } else {
          // grass: pick A or B by per-tile noise for inherent variation
          const u = colorNoise(tx + 0.5, ty + 0.5) - 0.85; // 0..0.30
          const f = u / 0.30;                              // 0..1
          r += grassA[0] + (grassB[0] - grassA[0]) * f;
          g += grassA[1] + (grassB[1] - grassA[1]) * f;
          b += grassA[2] + (grassB[2] - grassA[2]) * f;
          n++;
        }
      }
      if (n === 0) { r = grassA[0]; g = grassA[1]; b = grassA[2]; n = 1; }
      r /= n; g /= n; b /= n;
      // tiny per-vertex tint variation
      const tint = 0.94 + colorNoise(vx * 1.31, vz * 1.31) * 0.12 * 0.5;
      return [r * tint, g * tint, b * tint];
    };

    const waterFraction = (vx, vz) => {
      let n = 0, total = 0;
      for (const [dx, dz] of [[-1,-1],[0,-1],[-1,0],[0,0]]) {
        const tx = vx + dx, ty = vz + dz;
        if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) continue;
        total++;
        if (this.tileGrid[ty][tx] === 'water') n++;
      }
      return total ? n / total : 0;
    };

    for (let z = 0; z <= ROWS; z++) {
      for (let x = 0; x <= COLS; x++) {
        let y = terrainHeightAt(x, z);
        // Sink terrain under water so water plane (y=0.02) covers it cleanly.
        const w = waterFraction(x, z);
        if (w > 0) y = THREE.MathUtils.lerp(y, -0.4, w);
        positions.push(x, y, z);
        const [r, g, b] = vertexColor(x, z);
        colors.push(r, g, b);
      }
    }
    for (let z = 0; z < ROWS; z++) {
      for (let x = 0; x < COLS; x++) {
        const a = z * (COLS + 1) + x;
        const b = a + 1;
        const c = (z + 1) * (COLS + 1) + x;
        const d = c + 1;
        indices.push(a, c, b,   b, c, d);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geo.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
    geo.setIndex(indices);
    geo.computeVertexNormals();

    const mat = new THREE.MeshStandardMaterial({
      vertexColors: true,
      flatShading: false,
      roughness: 0.95, metalness: 0,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.receiveShadow = true;
    return mesh;
  }
}
