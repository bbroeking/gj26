// Inscribing Table — Tier 1 of the Wayfinding crafting loop.
// 3×3 grid → ingredients → recipe match → ink output.
//
// Verb shape:
//   place   — click an ingredient → drops into next empty grid slot
//   remove  — right-click a grid cell → returns ingredient to bag
//   recall  — click a known recipe → grid auto-fills from bag
//   hover   — hover a known recipe → ghost-preview the pattern on the grid
//   tab     — switch between Known / Hints / History
//   inscribe — click the state-aware button → resolves to ink, smudge, or wild
//
// All interactions render through the helpers below; they read live from
// _state and the player's inventory.

import { ITEMS } from '../data/items.js';
import { INK_RECIPES, matchRecipe, essenceOf } from '../data/inkRecipes.js';

let _state = null;

const HISTORY_KEY = 'gj26.inkHistory';
const HISTORY_MAX = 20;

// ---- public API ----

export function isInscribingTableOpen() { return !!_state; }

export function showInscribingTable(opts) {
  const backdrop = document.getElementById('inscribing-table-backdrop');
  if (!backdrop) return;
  ensureKnownLoaded(opts.player);
  ensureHistoryLoaded();
  _state = {
    player: opts.player,
    log: opts.log,
    onChange: opts.onChange,
    grid: empty3x3(),
    activeTab: 'known',
    ghost: null,           // recipe being hovered for ghost preview
    vessel: null,          // item id of the slotted vessel, or null
  };
  bindOnce();
  render();
  backdrop.classList.add('open');
}

export function closeInscribingTable() {
  document.getElementById('inscribing-table-backdrop')?.classList.remove('open');
  _state = null;
}

// ---- one-time DOM bindings ----

let _bound = false;
function bindOnce() {
  if (_bound) return;
  _bound = true;

  // Tabs
  document.querySelectorAll('.it-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!_state) return;
      _state.activeTab = btn.dataset.tab;
      document.querySelectorAll('.it-tab').forEach(b => b.classList.toggle('it-tab-active', b === btn));
      renderTabBody();
    });
  });

  // Inscribe button
  document.getElementById('it-inscribe-btn')?.addEventListener('click', inscribe);

  // Click an ingredient → place in first empty cell, OR slot the vessel
  // if the clicked item is one. Vessels are tagged via ITEMS[id].vessel.
  document.getElementById('it-ingredient-list')?.addEventListener('click', e => {
    const btn = e.target.closest('.it-ingredient');
    if (!btn || btn.classList.contains('disabled')) return;
    const id = btn.dataset.item;
    if (ITEMS[id]?.vessel) {
      _state.vessel = id;
      render();
      return;
    }
    placeInFirstEmpty(id);
  });

  // Click the vessel slot → unslot the vessel.
  document.getElementById('it-vessel-slot')?.addEventListener('click', () => {
    if (!_state) return;
    if (_state.vessel) {
      _state.vessel = null;
      render();
    }
  });

  // Click cell → return to bag. Right-click also (in case left-click is reserved).
  const grid = document.getElementById('it-grid');
  grid?.addEventListener('click', e => {
    const cell = e.target.closest('.it-cell');
    if (!cell) return;
    const x = +cell.dataset.x, y = +cell.dataset.y;
    if (_state.grid[y][x]) returnToBag(x, y);
  });
  grid?.addEventListener('contextmenu', e => {
    e.preventDefault();
    const cell = e.target.closest('.it-cell');
    if (!cell) return;
    const x = +cell.dataset.x, y = +cell.dataset.y;
    if (_state.grid[y][x]) returnToBag(x, y);
  });
}

// ---- render ----

function render() {
  if (!_state) return;
  renderHint();
  renderIngredients();
  renderGrid();
  renderVessel();
  renderTabBody();
  renderOutput(null);
  renderInscribeBtn();
}

function renderVessel() {
  const slot = document.getElementById('it-vessel-slot');
  const icon = document.getElementById('it-vessel-icon');
  const label = document.getElementById('it-vessel-label');
  if (!slot || !icon || !label) return;
  if (_state.vessel) {
    const def = ITEMS[_state.vessel];
    slot.classList.add('it-vessel-filled');
    icon.textContent = def?.icon || '·';
    label.textContent = def?.name?.split(' ')[0] || 'Vessel';
  } else {
    slot.classList.remove('it-vessel-filled');
    icon.textContent = '·';
    label.textContent = 'Vessel';
  }
}

function renderHint() {
  const el = document.getElementById('it-hint');
  if (!el) return;
  const filled = _state.grid.flat().filter(Boolean).length;
  if (filled === 0)        el.textContent = 'Click an ingredient on the left to place it. Click a known recipe to auto-fill.';
  else if (filled < 9)     el.textContent = 'Right-click a placed ingredient to return it to the bag.';
  else                     el.textContent = 'Grid is full. Press Inscribe to resolve.';
}

function renderIngredients() {
  const root = document.getElementById('it-ingredient-list');
  if (!root) return;
  const inv = _state.player.inventory;
  // Aggregate all stackable ingredients from inventory (essence-tagged items only).
  // Vessels (clay flask, bound parchment, glass vial) are also surfaced
  // here so the player can drag them to the vessel slot — they're tagged
  // with `vessel: { ... }` rather than `essence`.
  const counts = new Map();
  for (let i = 0; i < inv.slots.length; i++) {
    const slot = inv.slots[i];
    if (!slot) continue;
    const def = ITEMS[slot.id];
    const e = essenceOf(slot.id, ITEMS);
    if (!e && !def?.vessel) continue;
    counts.set(slot.id, (counts.get(slot.id) || 0) + (slot.qty || 1));
  }
  if (counts.size === 0) {
    root.innerHTML = '<div class="it-empty">No ingredients in your bag.</div>';
    return;
  }
  const rows = [];
  for (const [id, qty] of counts) {
    const def = ITEMS[id];
    if (!def) continue;
    const placed = countInGrid(id);
    // For vessels, also subtract the slotted one (so the count reflects
    // remaining-in-bag).
    const slottedAsVessel = (_state.vessel === id) ? 1 : 0;
    const remain = qty - placed - slottedAsVessel;
    const isVessel = !!def.vessel;
    rows.push(`
      <button class="it-ingredient ${isVessel ? 'it-ingredient-vessel' : ''} ${remain <= 0 ? 'disabled' : ''}" data-item="${id}">
        <span class="it-icon">${def.icon || '·'}</span>
        <span class="it-name">${escapeHTML(def.name)}${isVessel ? ' <em>(vessel)</em>' : ''}</span>
        <span class="it-qty">×${remain}</span>
      </button>
    `);
  }
  root.innerHTML = rows.join('');
}

function renderGrid() {
  const root = document.getElementById('it-grid');
  if (!root) return;
  let html = '';
  for (let y = 0; y < 3; y++) {
    for (let x = 0; x < 3; x++) {
      const cell = _state.grid[y][x];
      const def = cell ? ITEMS[cell.id] : null;
      // Ghost preview
      let ghostIcon = '';
      let ghostClass = '';
      if (!cell && _state.ghost) {
        const want = _state.ghost.pattern[y]?.[x];
        if (want) {
          ghostClass = 'it-cell-ghost';
          ghostIcon = ghostIconFor(want);
        }
      }
      html += `
        <div class="it-cell ${ghostClass}" data-x="${x}" data-y="${y}" ${ghostClass ? `data-ghost="${ghostIcon}"` : ''}>
          ${def ? `<span class="it-icon">${def.icon || '·'}</span>` : ''}
        </div>
      `;
    }
  }
  root.innerHTML = html;
}

function ghostIconFor(want) {
  if (want.id) return ITEMS[want.id]?.icon || '·';
  if (want.ess === 'verdant')  return '🌿';
  if (want.ess === 'earthen')  return '🪨';
  if (want.ess === 'sanguine') return '🩸';
  if (want.ess === 'lumen')    return '💧';
  return '·';
}

function renderOutput(result) {
  const root = document.getElementById('it-output');
  const bottle = document.getElementById('it-output-bottle');
  const label = document.getElementById('it-output-label');
  if (!root || !bottle || !label) return;
  root.classList.remove('it-output-success', 'it-output-fail', 'it-output-wild');
  if (!result) { bottle.textContent = ''; label.textContent = 'Ink Well'; return; }
  if (result.match) {
    root.classList.add('it-output-success');
    bottle.textContent = ITEMS[result.match.output.id]?.icon || '✦';
    label.textContent = result.match.name;
  } else if (result.wild) {
    root.classList.add('it-output-wild');
    bottle.textContent = '~';
    label.textContent = 'Wild Ink';
  } else {
    root.classList.add('it-output-fail');
    bottle.textContent = '·';
    label.textContent = 'Smudge';
  }
}

function renderInscribeBtn() {
  const btn = document.getElementById('it-inscribe-btn');
  if (!btn) return;
  const filled = _state.grid.flat().filter(Boolean).length;
  btn.classList.remove('it-btn-known', 'it-btn-unknown');
  if (filled === 0) {
    btn.disabled = true;
    btn.textContent = 'Inscribe';
    return;
  }
  btn.disabled = false;
  // Look for a recipe match — pass the slotted vessel id so tier-3
  // recipes only match when their required vessel is present.
  const result = matchRecipe(_state.grid, ITEMS, _state.vessel);
  if (result.match) {
    const known = _state.player.knownRecipes.has(result.match.id);
    if (known) {
      btn.classList.add('it-btn-known');
      btn.textContent = `Inscribe ${result.match.name}`;
    } else {
      btn.classList.add('it-btn-unknown');
      btn.textContent = `Inscribe (Discovery!)`;
    }
  } else {
    btn.classList.add('it-btn-unknown');
    btn.textContent = 'Inscribe (Unknown)';
  }
}

// ---- tabs ----

function renderTabBody() {
  const root = document.getElementById('it-tab-body');
  if (!root) return;
  if (_state.activeTab === 'known')   return renderKnown(root);
  if (_state.activeTab === 'hints')   return renderHints(root);
  if (_state.activeTab === 'history') return renderHistory(root);
}

function renderKnown(root) {
  const known = _state.player.knownRecipes;
  const rows = INK_RECIPES.map(r => {
    if (!known.has(r.id)) {
      return `<div class="it-codex-row it-codex-unknown">
        <div class="it-codex-name">??? <span class="it-codex-tag">tier ${r.tier}</span></div>
        <div class="it-codex-meta">undiscovered</div>
      </div>`;
    }
    return `<div class="it-codex-row" data-recipe="${r.id}">
      <div class="it-codex-name">${escapeHTML(r.name)} <span class="it-codex-tag">tier ${r.tier}</span></div>
      <div class="it-codex-meta">${escapeHTML(r.desc)}</div>
    </div>`;
  });
  root.innerHTML = rows.join('');
  // Bind click + hover for known rows
  root.querySelectorAll('.it-codex-row[data-recipe]').forEach(row => {
    const recipe = INK_RECIPES.find(r => r.id === row.dataset.recipe);
    row.addEventListener('click', () => autoFill(recipe));
    row.addEventListener('mouseenter', () => { _state.ghost = recipe; renderGrid(); });
    row.addEventListener('mouseleave', () => { _state.ghost = null;   renderGrid(); });
  });
}

function renderHints(root) {
  // Hints are recipes NPCs have told the player about. They show until
  // the recipe is actually crafted (then move to Known). Without any
  // hints, prompt the player to talk to people.
  const known = _state.player.knownRecipes || new Set();
  const hinted = _state.player.hintedRecipes || new Set();
  const hintEntries = INK_RECIPES.filter(r => hinted.has(r.id) && !known.has(r.id));
  if (hintEntries.length === 0) {
    root.innerHTML = '<div class="it-empty">No hints yet. Talk to Hod, Quill, or Sir Withering — they each know a few ink recipes.</div>';
    return;
  }
  root.innerHTML = hintEntries.map(r => `
    <div class="it-codex-row it-codex-unknown">
      <div class="it-codex-name">${escapeHTML(r.name)} <span class="it-codex-tag">rumored · tier ${r.tier}</span></div>
      <div class="it-codex-meta">${escapeHTML(r.hint || 'A recipe a friend told you about.')}</div>
    </div>
  `).join('');
}

function renderHistory(root) {
  const hist = _historyCache;
  if (hist.length === 0) {
    root.innerHTML = '<div class="it-empty">No attempts yet. Your history will appear here.</div>';
    return;
  }
  root.innerHTML = hist.slice().reverse().map(h => {
    let cls = 'it-history-success', label = h.name || 'Ink';
    if (h.outcome === 'smudge') { cls = 'it-history-smudge'; label = 'Smudge'; }
    else if (h.outcome === 'wild') { cls = 'it-history-wild'; label = `Wild · ${h.name || 'Ink'}`; }
    return `<div class="it-history-row ${cls}">
      <span class="it-history-time">${h.time}</span>
      <span>${escapeHTML(label)} (${h.ingredients.join(', ')})</span>
    </div>`;
  }).join('');
}

// ---- mutators ----

// Center-first placement order. Cells fill in this sequence:
// center → middle column ends → middle row ends → corners. Most recipes
// have a centered shape, so this lets click-to-place naturally form
// patterns like Hedge Ink (middle column) and Charcoal Bind (center).
const PLACE_ORDER = [
  [1, 1],            // center
  [1, 0], [1, 2],    // middle column ends
  [0, 1], [2, 1],    // middle row ends
  [0, 0], [2, 0],    // top corners
  [0, 2], [2, 2],    // bottom corners
];

function placeInFirstEmpty(itemId) {
  // Skip if every copy already in grid
  const inv = _state.player.inventory;
  const have = inv.count(itemId);
  if (have <= countInGrid(itemId)) return;
  for (const [x, y] of PLACE_ORDER) {
    if (!_state.grid[y][x]) {
      _state.grid[y][x] = { id: itemId };
      render();
      return;
    }
  }
}

function returnToBag(x, y) {
  const cell = _state.grid[y][x];
  if (!cell) return;
  _state.grid[y][x] = null;
  render();
}

function autoFill(recipe) {
  // Clear current grid, return everything to "bag" (which is just clearing
  // the cells — ingredients in the bag never moved, since we don't actually
  // remove them until Inscribe).
  _state.grid = empty3x3();
  // Place from pattern
  const inv = _state.player.inventory;
  const used = new Map();          // id → count needed so far
  for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
    const want = recipe.pattern[y][x];
    if (!want) continue;
    const id = want.id || pickIngredientForEssence(want.ess, want.tier, used, inv);
    if (!id) continue;
    used.set(id, (used.get(id) || 0) + 1);
    if (inv.count(id) >= used.get(id)) {
      _state.grid[y][x] = { id };
    } else {
      // Bag is short — leave the cell empty. Player sees what's missing.
    }
  }
  render();
}

function pickIngredientForEssence(ess, tierMin, usedSoFar, inv) {
  // Find any item the player has whose essence matches and tier ≥ wanted.
  for (const slot of inv.slots) {
    if (!slot) continue;
    const e = essenceOf(slot.id, ITEMS);
    if (!e) continue;
    if (e.essence !== ess) continue;
    if (e.tier < (tierMin ?? 1)) continue;
    const taken = usedSoFar.get(slot.id) || 0;
    if (slot.qty - taken > 0) return slot.id;
  }
  return null;
}

function countInGrid(id) {
  let n = 0;
  for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
    if (_state.grid[y][x]?.id === id) n++;
  }
  return n;
}

function empty3x3() { return [[null,null,null],[null,null,null],[null,null,null]]; }

// ---- inscribe ----

export function inscribe() {
  if (!_state) return;
  const grid = _state.grid;
  const ingredientIds = grid.flat().filter(Boolean).map(c => c.id);
  if (ingredientIds.length === 0) return;

  // Spend the ingredients up front
  for (const id of ingredientIds) _state.player.inventory.remove(id, 1);

  // Match the recipe (vessel-aware). If a tier-3 recipe matches its
  // required vessel, also consume the vessel — wild/smudge paths leave
  // the vessel in the bag so a misclick isn't catastrophic.
  const result = matchRecipe(grid, ITEMS, _state.vessel);
  if (result.match?.vessel && _state.vessel === result.match.vessel) {
    _state.player.inventory.remove(_state.vessel, 1);
    _state.vessel = null;
  }
  let outcome;
  if (result.match) {
    const r = result.match;
    _state.player.inventory.add(r.output.id, r.output.qty || 1);
    const first = !_state.player.knownRecipes.has(r.id);
    _state.player.knownRecipes.add(r.id);
    persistKnownRecipes(_state.player);
    outcome = { match: r, first };
    // No Wayfinding XP — inks are sub-craft. The XP comes when the ink
    // becomes a chart (chart inscription) or when the chart is run.
    _state.log('skill', `${first ? '★ Discovered' : '✦'} ${r.name} — ink in your bag.`);
  } else {
    // Unknown pattern: 60% smudge (with breadcrumb), 40% wild ink (random
    // tier-1 named ink, but doesn't add to the codex — you got lucky, not
    // smart). This keeps experimentation non-punishing.
    if (Math.random() < 0.40) {
      const tier1 = INK_RECIPES.filter(r => r.tier === 1);
      const wild  = tier1[Math.floor(Math.random() * tier1.length)];
      _state.player.inventory.add(wild.output.id, wild.output.qty || 1);
      outcome = { wild: true, name: wild.name };
      _state.log('hint', `~ Wild ink — looks like ${wild.name}, but you couldn't tell you why.`);
    } else {
      _state.player.inventory.add('charcoal_stick', 1);
      outcome = { smudge: true };
      _state.log('hint', '— Smudge. The ingredients run together. You salvage one charcoal.');
    }
  }

  // History entry — captures three kinds: success, wild, smudge.
  pushHistory({
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    outcome: outcome.match ? 'success' : (outcome.wild ? 'wild' : 'smudge'),
    name: outcome.match?.name || outcome.name || null,
    ingredients: ingredientIds.map(id => ITEMS[id]?.name || id),
  });

  renderOutput(outcome);
  // Clear grid + repaint after a short pause so the player sees the result
  setTimeout(() => {
    if (!_state) return;
    _state.grid = empty3x3();
    render();
  }, 1500);
  _state.onChange?.();
}

// ---- history (in-memory cache, persisted to localStorage) ----

let _historyCache = [];
function ensureHistoryLoaded() {
  try {
    const raw = localStorage.getItem(HISTORY_KEY);
    if (raw) {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr)) _historyCache = arr;
    }
  } catch (_) {}
}
function pushHistory(entry) {
  _historyCache.push(entry);
  if (_historyCache.length > HISTORY_MAX) _historyCache.shift();
  try { localStorage.setItem(HISTORY_KEY, JSON.stringify(_historyCache)); } catch (_) {}
}

// ---- known-recipes persistence ----

function ensureKnownLoaded(player) {
  if (player.knownRecipes instanceof Set) return;
  try {
    const raw = localStorage.getItem('gj26.knownRecipes');
    if (raw) {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr)) player.knownRecipes = new Set(arr);
    }
  } catch (_) {}
  player.knownRecipes ||= new Set();
}
function persistKnownRecipes(player) {
  try {
    localStorage.setItem('gj26.knownRecipes', JSON.stringify(Array.from(player.knownRecipes)));
  } catch (_) {}
}

export function loadKnownRecipes(player) { ensureKnownLoaded(player); }

// ---- exports kept for the existing main.js wiring ----

export function placeIngredient(x, y, itemId) {
  if (!_state) return;
  if (_state.grid[y][x]) {
    // Cell already holds something — leave it
    return;
  }
  _state.grid[y][x] = { id: itemId };
  render();
}
export function removeIngredient(x, y) { if (_state) returnToBag(x, y); }

// ---- util ----

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
