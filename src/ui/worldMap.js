// Full-screen world map (Wayfinding). The map's behavior tiers up with
// the player's Wayfinding skill — each milestone unlocks a layer of
// information or a new verb (fast-travel, waypoints, full reveal).
//
// Public API:
//   showWorldMap(opts)     — open; opts = { player, world, landmarks, enemies, onTravel, log }
//   closeWorldMap()        — close
//   isWorldMapOpen()       — bool
//   CARTO_MILESTONES       — exported so HUD can read upcoming unlocks

let _state = null;

// What unlocks at each Wayfinding level. The map UI gates each layer on
// the player's current `player.skills.carto.lv`. See
// docs/cartography-progression.md for the source-of-truth design table.
export const CARTO_UNLOCKS = [
  { lv: 1,  name: 'Apprentice Wayfarer', track: 'vision',   text: 'World map opens with explored-tile memory. Mix Hedge Ink + Charcoal Bind.' },
  { lv: 4,  name: 'Greengather',             track: 'recipes',  text: 'Mix Stoneground Ink (earthen bias).' },
  { lv: 5,  name: 'Field Surveyor',          track: 'vision',   text: 'Enemies in sight appear on the map.' },
  { lv: 6,  name: 'Tinder Press',            track: 'recipes',  text: 'Mix Bramblepress Ink (sanguine, +30% tyrannical).' },
  { lv: 7,  name: 'Branch Walker',           track: 'affixes',  text: 'New affix: Wood Grove (+3–5 log piles in chart).' },
  { lv: 8,  name: 'Wellspring Stage',        track: 'recipes',  text: 'Mix Wellspring Ink (lumen, +30% bramble bloom).' },
  { lv: 10, name: 'Hedgewalker',             track: 'vision',   text: 'Inscribe chart_hollow. Forage stays marked on memory tiles.' },
  { lv: 12, name: 'Press Master',            track: 'recipes',  text: 'Mix Refined Ink (+5% stability on every roll).' },
  { lv: 13, name: 'Hush Walker',             track: 'recipes',  text: 'Mix Hush Ink (biases lockstep enemy patrols).' },
  { lv: 14, name: 'Herbal Walker',           track: 'affixes',  text: 'New affix: Herbal Patch (+4–6 forage spawns).' },
  { lv: 15, name: 'Pathfinder',              track: 'vision',   text: 'Fast-travel between known landmarks (1× chart_blank).' },
  { lv: 16, name: 'Bog Ink Press',           track: 'recipes',  text: 'Mix Bog Ink (biases Fog of Hedge or Bramble Bloom).' },
  { lv: 18, name: 'Lustrous Press',          track: 'recipes',  text: 'Mix Lustrous Ink (+30% mineral_vein, +10% gilded_seam).' },
  { lv: 20, name: 'Marker',                  track: 'recipes',  text: 'Inscribe treasure_map (clue-chain to a hidden cache).' },
  { lv: 22, name: 'Sunken Press',            track: 'templates',text: 'Inscribe chart_sunken_hut (tier 3, atmospheric bias).' },
  { lv: 25, name: 'Surveyor',                track: 'vision',   text: 'Right-click to place named waypoints. Auto-arrange known recipes.' },
  { lv: 28, name: 'Ember Press',             track: 'recipes',  text: 'Mix Ember Ink (+30% tyrannical or bursting).' },
  { lv: 30, name: 'Delve Press',             track: 'templates',text: 'Inscribe chart_delve. New affix: Gem Seam (rare gemstones).' },
  { lv: 32, name: 'Survey Map',              track: 'recipes',  text: 'Inscribe survey_map (regional XP boost for 1 game-day).' },
  { lv: 35, name: 'Hydrographer',            track: 'specialty',text: 'Inscribe hydrographic_chart — water-room bias.' },
  { lv: 40, name: 'Geologist',               track: 'specialty',text: 'Inscribe geological_chart — +50% mineral_vein landing.' },
  { lv: 45, name: 'Biologist',               track: 'specialty',text: 'Inscribe biological_chart — +30% boss-room rate.' },
  { lv: 50, name: 'Master Charter',          track: 'vision',   text: 'Walking the map perimeter reveals the full chart.' },
  { lv: 55, name: 'Wightblood Press',        track: 'recipes',  text: 'Mix Wightblood Ink (rare; unlocks wolf_alpha_den bias).' },
  { lv: 60, name: 'Tideink Press',           track: 'templates',text: 'Mix Tideink. Unlock chart_summit (tier 5, 5 affix slots).' },
  { lv: 60, name: 'Falconer-Wayfarer',   track: 'specialty',text: 'Borrow Sir Withering’s falcon for remote sketching.' },
  { lv: 65, name: 'Aurora Press',            track: 'recipes',  text: 'Mix Aurora Ink (+50% on rare boss affixes).' },
  { lv: 70, name: 'Coalrose Press',          track: 'recipes',  text: 'Mix Coalrose Ink (+40% sprinter affix).' },
  { lv: 75, name: 'Grand Charter',           track: 'endgame',  text: 'Inscribe master_chart_bramblewood — full overworld reveal.' },
  { lv: 80, name: 'Atlas Press',             track: 'recipes',  text: 'Mix Atlas Ink — re-roll one affix on any chart.' },
  { lv: 90, name: 'Atlas-bearer',            track: 'endgame',  text: 'Begin the Atlas of Bramblewood commission chain.' },
  { lv: 99, name: 'Grand Wayfarer',      track: 'endgame',  text: 'Wayfarer’s Cape: +5% MS, +10% sketch XP, +1 affix slot, title.' },
];

// Backward-compat alias (older callers used CARTO_MILESTONES).
export const CARTO_MILESTONES = CARTO_UNLOCKS;

export function nextMilestone(level) {
  for (const u of CARTO_UNLOCKS) if (u.lv > level) return u;
  return null;
}
export const nextUnlock = nextMilestone;

// Glyphs for landmarks — looked up by lower-cased name keyword.
const LANDMARK_GLYPH = {
  hearth:        '🔥',
  cook:          '🍳',
  hod:           '🔨',
  smith:         '🔨',
  quill:         '🌿',
  herbalist:     '🌿',
  withering:     '🦅',
  chartmaker:    '🪨',
  stone:         '🪨',
  glass:         '🪞',
  mirror:        '🪞',
  castle:        '🏰',
};
function glyphFor(name) {
  const n = name.toLowerCase();
  for (const k of Object.keys(LANDMARK_GLYPH)) if (n.includes(k)) return LANDMARK_GLYPH[k];
  return '✦';
}

export function isWorldMapOpen() {
  return !!_state;
}

export function closeWorldMap() {
  if (!_state) return;
  document.getElementById('world-map-backdrop')?.classList.remove('open');
  document.getElementById('wm-name-form')?.classList.remove('open');
  window.removeEventListener('mousemove', _state.onHover);
  document.getElementById('wm-canvas')?.removeEventListener('click', _state.onClick);
  document.getElementById('wm-canvas')?.removeEventListener('contextmenu', _state.onContext);
  _state = null;
}

export function showWorldMap(opts) {
  const backdrop = document.getElementById('world-map-backdrop');
  if (!backdrop) return;
  const canvas   = document.getElementById('wm-canvas');
  const cartoEl  = document.getElementById('wm-carto-lv');
  const exploredEl = document.getElementById('wm-explored');
  const tooltip  = document.getElementById('wm-tooltip');
  const milestoneEl = document.getElementById('wm-milestone');
  if (!canvas || !cartoEl || !exploredEl) return;

  const ctx = canvas.getContext('2d');
  const COLS = opts.world.tileGrid?.[0]?.length || 60;
  const ROWS = opts.world.tileGrid?.length || 30;

  const maxW = Math.min(window.innerWidth - 80, 1100);
  const maxH = Math.min(window.innerHeight - 240, 540);
  const cellW = Math.floor(Math.min(maxW / COLS, maxH / ROWS));
  const W = cellW * COLS;
  const H = cellW * ROWS;
  canvas.width = W;
  canvas.height = H;

  const cartoLv = opts.player.skills.carto?.lv || 1;
  const cap = {
    enemies:     cartoLv >= 5,
    forageMemo:  cartoLv >= 10,
    fastTravel:  cartoLv >= 15,
    waypoints:   cartoLv >= 25,
    fullReveal:  cartoLv >= 50 && hasWalkedPerimeter(opts.player, COLS, ROWS),
    freeTravel:  cartoLv >= 99,
  };

  function tileVisibility(tx, ty, player) {
    if (cap.fullReveal) return 0.7;
    const dx = tx - player.x, dy = ty - player.y;
    const live = 5;
    if (dx*dx + dy*dy <= live * live) return 1.0;
    if (player.exploredTiles?.has(`${tx},${ty}`)) return 0.55;
    return 0;
  }

  function draw() {
    const { player, world, landmarks } = opts;
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = '#f0e3c4';
    ctx.fillRect(0, 0, W, H);

    // Tiles
    for (let y = 0; y < ROWS; y++) {
      for (let x = 0; x < COLS; x++) {
        const vis = tileVisibility(x, y, player);
        if (vis <= 0) continue;
        const t = world.tileGrid[y][x];
        let col = '#8aa05a';
        if (t === 'water')      col = '#5b8caf';
        else if (t === 'stone') col = '#8a8270';
        else if (t === 'path')  col = '#b59568';
        else if (t === 'sand')  col = '#d8c08a';
        else if (t === 'floor') col = '#8a6e4a';
        ctx.globalAlpha = vis;
        ctx.fillStyle = col;
        ctx.fillRect(x * cellW, y * cellW, cellW, cellW);
      }
    }
    ctx.globalAlpha = 1;

    // Trees — live vis only
    if (world.trees) {
      ctx.fillStyle = '#3a5d28';
      for (const tr of world.trees) {
        if (tr.depleted) continue;
        if (tileVisibility(tr.x, tr.y, player) < 1) continue;
        const px = tr.x * cellW + cellW / 2;
        const py = tr.y * cellW + cellW / 2;
        ctx.beginPath(); ctx.arc(px, py, cellW * 0.30, 0, Math.PI * 2); ctx.fill();
      }
    }

    // Forage — Lv 10 keeps them visible on memory tiles too
    if (world.forageSpawns) {
      ctx.fillStyle = '#c2497a';
      for (const f of world.forageSpawns) {
        if (f.depleted) continue;
        const vis = tileVisibility(f.x, f.y, player);
        if (vis <= 0) continue;
        if (vis < 1 && !cap.forageMemo) continue;
        const px = f.x * cellW + cellW / 2;
        const py = f.y * cellW + cellW / 2;
        ctx.globalAlpha = Math.min(1, vis);
        ctx.fillRect(px - cellW * 0.18, py - cellW * 0.18, cellW * 0.36, cellW * 0.36);
      }
    }
    ctx.globalAlpha = 1;

    // Enemies — Lv 5 reveals enemies in sight
    if (cap.enemies && Array.isArray(opts.enemies)) {
      ctx.fillStyle = '#7a1f1f';
      for (const e of opts.enemies) {
        if (!e.alive) continue;
        const dx = e.x - player.x, dy = e.y - player.y;
        if (dx*dx + dy*dy > 25) continue;       // 5-tile sight
        const px = e.x * cellW + cellW / 2;
        const py = e.y * cellW + cellW / 2;
        ctx.beginPath();
        ctx.moveTo(px, py - cellW * 0.4);
        ctx.lineTo(px + cellW * 0.4, py + cellW * 0.4);
        ctx.lineTo(px - cellW * 0.4, py + cellW * 0.4);
        ctx.closePath();
        ctx.fill();
      }
    }

    // Landmarks — labels on explored locations only, with role glyphs
    const glyphPx = Math.max(11, Math.floor(cellW * 1.6));
    ctx.font = `bold ${glyphPx}px "Apple Color Emoji", "Segoe UI Emoji", serif`;
    for (const lm of landmarks) {
      const vis = tileVisibility(lm.x, lm.y, player);
      if (vis <= 0) continue;
      const px = lm.x * cellW + cellW / 2;
      const py = lm.y * cellW + cellW / 2;
      // Halo
      ctx.fillStyle = 'rgba(184, 165, 106, 0.85)';
      ctx.beginPath();
      ctx.arc(px, py, cellW * 0.65, 0, Math.PI * 2);
      ctx.fill();
      // Glyph
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#3a2f1f';
      ctx.fillText(glyphFor(lm.name), px, py);
      // Label (smaller font)
      ctx.font = 'bold 11px "EB Garamond", serif';
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = '#3a2f1f';
      ctx.fillText(lm.name, px + cellW * 0.85, py + 4);
      ctx.font = `bold ${glyphPx}px "Apple Color Emoji", "Segoe UI Emoji", serif`;
    }

    // Player waypoints — Lv 25
    if (cap.waypoints && Array.isArray(opts.player.waypoints)) {
      ctx.font = 'bold 12px "EB Garamond", serif';
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      for (const w of opts.player.waypoints) {
        const vis = tileVisibility(w.x, w.y, opts.player);
        if (vis <= 0) continue;
        const px = w.x * cellW + cellW / 2;
        const py = w.y * cellW + cellW / 2;
        ctx.fillStyle = '#7a99a8';
        ctx.beginPath(); ctx.arc(px, py, cellW * 0.40, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#3a2f1f';
        ctx.fillText('· ' + w.name, px + cellW * 0.55, py + 4);
      }
    }

    // Player position
    const ppx = player.pos.x * cellW;
    const ppy = player.pos.z * cellW;
    ctx.fillStyle = '#c94c4c';
    ctx.beginPath();
    ctx.arc(ppx, ppy, cellW * 0.45, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#3a2f1f';
    ctx.lineWidth = 1.5;
    ctx.stroke();

    // Compass
    ctx.font = 'bold 14px "Cinzel", serif';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'alphabetic';
    ctx.fillStyle = '#6b5a3a';
    ctx.fillText('N', W - 30, 20);
    ctx.fillText('S', W - 30, H - 8);
  }

  // Find the landmark / waypoint at a tile, if any. Returns { kind, target }.
  function pickAt(tx, ty) {
    for (const lm of opts.landmarks) if (lm.x === tx && lm.y === ty) return { kind: 'landmark', target: lm };
    for (const w of (opts.player.waypoints || [])) if (w.x === tx && w.y === ty) return { kind: 'waypoint', target: w };
    return null;
  }

  function onHover(e) {
    const rect = canvas.getBoundingClientRect();
    const cx = e.clientX - rect.left;
    const cy = e.clientY - rect.top;
    if (cx < 0 || cy < 0 || cx > W || cy > H) {
      tooltip.style.opacity = 0;
      return;
    }
    const tx = Math.floor(cx / cellW);
    const ty = Math.floor(cy / cellW);
    const vis = tileVisibility(tx, ty, opts.player);
    if (vis <= 0) {
      tooltip.style.opacity = 0;
      return;
    }
    const tile = opts.world.tileGrid[ty]?.[tx] || 'unknown';
    let label = tile.charAt(0).toUpperCase() + tile.slice(1);
    const hit = pickAt(tx, ty);
    if (hit) label = hit.target.name;
    let suffix = '';
    if (hit && hit.kind === 'landmark' && cap.fastTravel) suffix = ' — click to travel';
    else if (cap.waypoints) suffix = ' — right-click to mark';
    tooltip.textContent = `${label} · (${tx}, ${ty})${suffix}`;
    tooltip.style.left = (e.clientX + 12) + 'px';
    tooltip.style.top  = (e.clientY + 12) + 'px';
    tooltip.style.opacity = 1;
  }

  function onClick(e) {
    if (!cap.fastTravel) return;
    const rect = canvas.getBoundingClientRect();
    const tx = Math.floor((e.clientX - rect.left) / cellW);
    const ty = Math.floor((e.clientY - rect.top) / cellW);
    const hit = pickAt(tx, ty);
    if (!hit) return;
    if (typeof opts.onTravel !== 'function') return;
    const ok = opts.onTravel(hit.target);
    if (ok) closeWorldMap();
  }

  function onContext(e) {
    e.preventDefault();
    if (!cap.waypoints) return;
    const rect = canvas.getBoundingClientRect();
    const tx = Math.floor((e.clientX - rect.left) / cellW);
    const ty = Math.floor((e.clientY - rect.top) / cellW);
    const vis = tileVisibility(tx, ty, opts.player);
    if (vis <= 0) return;
    const existing = (opts.player.waypoints || []).findIndex(w => w.x === tx && w.y === ty);
    if (existing >= 0) {
      opts.player.waypoints.splice(existing, 1);
      if (typeof opts.onWaypointsChanged === 'function') opts.onWaypointsChanged();
      draw();
      return;
    }
    openWaypointNamer(tx, ty, e.clientX, e.clientY);
  }

  function openWaypointNamer(tx, ty, clientX, clientY) {
    const form  = document.getElementById('wm-name-form');
    const input = document.getElementById('wm-name-input');
    const cancel = document.getElementById('wm-name-cancel');
    if (!form || !input) return;
    const wrapRect = form.parentElement.getBoundingClientRect();
    form.style.left = Math.max(8, clientX - wrapRect.left - 90) + 'px';
    form.style.top  = Math.max(8, clientY - wrapRect.top + 8) + 'px';
    input.value = `Mark ${(opts.player.waypoints?.length || 0) + 1}`;
    form.classList.add('open');
    setTimeout(() => { input.focus(); input.select(); }, 0);

    const finish = (commit) => {
      form.classList.remove('open');
      form.onsubmit = null;
      input.onkeydown = null;
      cancel.onclick = null;
      if (commit) {
        const name = input.value.trim();
        if (!name) return;
        (opts.player.waypoints ||= []).push({ x: tx, y: ty, name });
        if (typeof opts.onWaypointsChanged === 'function') opts.onWaypointsChanged();
        draw();
      }
    };
    form.onsubmit = (ev) => { ev.preventDefault(); finish(true); };
    cancel.onclick = () => finish(false);
    input.onkeydown = (ev) => {
      if (ev.key === 'Escape') { ev.preventDefault(); ev.stopPropagation(); finish(false); }
    };
  }

  // Update HUD
  cartoEl.textContent = String(cartoLv);
  exploredEl.textContent = String(opts.player.exploredTiles?.size || 0) + ' / ' + (COLS * ROWS);
  if (milestoneEl) {
    const next = nextMilestone(cartoLv);
    if (next) milestoneEl.textContent = `Next: Lv ${next.lv} · ${next.name} — ${next.text || next.unlock || ''}`;
    else milestoneEl.textContent = 'All unlocks earned. The chart is yours.';
  }

  draw();
  backdrop.classList.add('open');
  window.addEventListener('mousemove', onHover);
  canvas.addEventListener('click', onClick);
  canvas.addEventListener('contextmenu', onContext);
  _state = { redraw: draw, onHover, onClick, onContext };
}

// "Walked the perimeter" — true when the player has visited at least one
// tile on each of the four edges of the map. Cheap check, called only on
// open.
function hasWalkedPerimeter(player, cols, rows) {
  if (!player.exploredTiles) return false;
  let n=false, s=false, w=false, e=false;
  for (const k of player.exploredTiles) {
    const [xs, ys] = k.split(',');
    const x = +xs, y = +ys;
    if (y === 0) n = true;
    if (y === rows - 1) s = true;
    if (x === 0) w = true;
    if (x === cols - 1) e = true;
    if (n && s && w && e) return true;
  }
  return false;
}
