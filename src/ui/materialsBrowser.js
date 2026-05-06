// Materials Browser — full-fat materials catalog modal.
//
// Shows every material the player has (or might find) as a card with:
//   icon · name · count · essence/tier badge · sources · used in
//
// Click a "used in" recipe → fires the onPickRecipe callback so the
// workshop can shopping-list-mode that recipe.
//
// Public API:
//   showMaterialsBrowser(player, log, opts)
//     opts = { onPickRecipe(recipe) }
//   closeMaterialsBrowser()
//   isMaterialsBrowserOpen()

import { ITEMS } from '../data/items.js';
import { INK_RECIPES, essenceOf } from '../data/inkRecipes.js';
import { sourceHint, recipeStatus, essenceLabel } from '../game/materials.js';

let _state = null;

export function isMaterialsBrowserOpen() { return !!_state; }

export function showMaterialsBrowser(player, log, opts = {}) {
  const backdrop = document.getElementById('materials-browser-backdrop');
  if (!backdrop) return;
  _state = { player, log, onPickRecipe: opts.onPickRecipe, activeTab: 'materials' };
  bindOnce();
  render();
  backdrop.classList.add('open');
}

export function closeMaterialsBrowser() {
  document.getElementById('materials-browser-backdrop')?.classList.remove('open');
  _state = null;
}

let _bound = false;
function bindOnce() {
  if (_bound) return;
  _bound = true;
  document.getElementById('mb-close')?.addEventListener('click', closeMaterialsBrowser);
  document.getElementById('materials-browser-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'materials-browser-backdrop') closeMaterialsBrowser();
  });
  document.querySelectorAll('.mb-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!_state) return;
      _state.activeTab = btn.dataset.tab;
      document.querySelectorAll('.mb-tab').forEach(b => b.classList.toggle('mb-tab-active', b === btn));
      renderBody();
    });
  });
  // Recipe-card click → forward to caller and close.
  document.getElementById('mb-body')?.addEventListener('click', e => {
    const link = e.target.closest('[data-recipe]');
    if (!link) return;
    const recipeId = link.dataset.recipe;
    const recipe = INK_RECIPES.find(r => r.id === recipeId);
    if (!recipe) return;
    const cb = _state?.onPickRecipe;
    closeMaterialsBrowser();
    cb?.(recipe);
  });
}

function render() {
  // Tab bar — set the active class to match _state.
  document.querySelectorAll('.mb-tab').forEach(b => {
    b.classList.toggle('mb-tab-active', b.dataset.tab === _state.activeTab);
  });
  renderBody();
}

function renderBody() {
  const root = document.getElementById('mb-body');
  if (!root || !_state) return;
  switch (_state.activeTab) {
    case 'materials': return root.innerHTML = renderMaterialsTab();
    case 'inks':      return root.innerHTML = renderInksTab();
    case 'vessels':   return root.innerHTML = renderVesselsTab();
    case 'recipes':   return root.innerHTML = renderRecipesTab();
  }
}

// ---- Materials tab: every essence-tagged item the player has ----

function renderMaterialsTab() {
  const inv = _state.player.inventory;
  const cards = [];
  // Iterate ITEMS so we list materials even if the player has 0 (greyed).
  const seen = new Set();
  // First, items currently in the bag.
  for (const slot of inv.slots) {
    if (!slot) continue;
    const e = essenceOf(slot.id, ITEMS);
    if (!e) continue;
    if (seen.has(slot.id)) continue;
    seen.add(slot.id);
    cards.push(materialCard(slot.id, slot.qty || 1, e));
  }
  // Then, well-known materials the player doesn't have yet.
  for (const id of WELL_KNOWN_MATERIALS) {
    if (seen.has(id)) continue;
    const e = essenceOf(id, ITEMS);
    if (!e) continue;
    seen.add(id);
    cards.push(materialCard(id, 0, e));
  }
  if (!cards.length) return '<div class="mb-empty">No materials seen yet.</div>';
  return `<div class="mb-grid">${cards.join('')}</div>`;
}

function materialCard(id, qty, ess) {
  const def = ITEMS[id];
  if (!def) return '';
  const greyed = qty <= 0 ? 'mb-card-empty' : '';
  const usedIn = INK_RECIPES.filter(r => recipeUsesMaterial(r, id, ess.essence, ess.tier ?? 1));
  const usedHtml = usedIn.length
    ? usedIn.map(r => `<a class="mb-recipe-link" data-recipe="${r.id}">${escapeHTML(r.name)}</a>`).join(', ')
    : '<span class="mb-dim">(no known recipes)</span>';
  const sources = sourceHint(id).map(s => `<li>${escapeHTML(s)}</li>`).join('');
  return `<div class="mb-card ${greyed}">
    <div class="mb-card-head">
      <span class="mb-card-icon">${def.icon || '·'}</span>
      <span class="mb-card-name">${escapeHTML(def.name)}</span>
      <span class="mb-card-qty">${qty > 0 ? `×${qty}` : '<span class="mb-dim">none</span>'}</span>
    </div>
    <div class="mb-card-meta">${escapeHTML(essenceLabel(ess.essence))} · tier ${ess.tier ?? 1}</div>
    <div class="mb-card-sources"><b>Sources</b><ul>${sources}</ul></div>
    <div class="mb-card-usedin"><b>Used in</b><div>${usedHtml}</div></div>
  </div>`;
}

// Match a material against a recipe's pattern. Used for the "Used in" list.
function recipeUsesMaterial(recipe, id, essence, tier) {
  for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
    const want = recipe.pattern[y][x];
    if (!want) continue;
    if (want.id === id) return true;
    if (want.ess === essence && (want.tier ?? 1) <= tier) return true;
  }
  return false;
}

// Curated list of materials shown even at 0 — gives the player a "what
// to chase" surface. Authored set; keeps card-grid tight rather than
// dumping every essence-tagged item in items.js.
const WELL_KNOWN_MATERIALS = [
  'hedgecap', 'whitleberry', 'wishrose', 'raw_mushroom', 'thorn_essence',
  'charcoal_stick', 'logs', 'ore_dust', 'bogiron_ore', 'bog_silt',
  'pond_water', 'vellum', 'rune_stone',
];

// ---- Inks tab ----

function renderInksTab() {
  const inv = _state.player.inventory;
  const cards = [];
  const seen = new Set();
  // Show ink items the player has.
  for (const slot of inv.slots) {
    if (!slot) continue;
    const def = ITEMS[slot.id];
    if (!def?.ink) continue;
    seen.add(slot.id);
    cards.push(inkCard(slot.id, slot.qty || 1));
  }
  // Plus every recipe's output as a "discoverable" card for inks the
  // player hasn't mixed yet.
  for (const r of INK_RECIPES) {
    if (seen.has(r.output.id)) continue;
    seen.add(r.output.id);
    const known = _state.player.knownRecipes?.has(r.id);
    cards.push(inkCard(r.output.id, 0, !known));
  }
  if (!cards.length) return '<div class="mb-empty">No inks discovered yet.</div>';
  return `<div class="mb-grid">${cards.join('')}</div>`;
}

function inkCard(id, qty, undiscovered = false) {
  const def = ITEMS[id];
  if (!def) return '';
  const greyed = qty <= 0 ? 'mb-card-empty' : '';
  const recipe = INK_RECIPES.find(r => r.output.id === id);
  const tier = recipe?.tier || def?.ink?.tier || 1;
  if (undiscovered) {
    return `<div class="mb-card mb-card-empty">
      <div class="mb-card-head">
        <span class="mb-card-icon">?</span>
        <span class="mb-card-name">??? <span class="mb-card-qty"><span class="mb-dim">undiscovered</span></span></span>
      </div>
      <div class="mb-card-meta">Tier ${tier} ink</div>
      <div class="mb-card-sources mb-dim">${escapeHTML(recipe?.hint || 'A recipe a friend may share.')}</div>
    </div>`;
  }
  // Status shows whether the player can mix MORE right now.
  let canMixHtml = '';
  if (recipe) {
    const st = recipeStatus(recipe, _state.player.inventory, ITEMS);
    if (st.canCraft) canMixHtml = `<div class="mb-mix-good"><a class="mb-recipe-link" data-recipe="${recipe.id}">✓ Mix more →</a></div>`;
    else canMixHtml = `<div class="mb-mix-warn"><a class="mb-recipe-link" data-recipe="${recipe.id}">Need ${st.missing.map(m => escapeHTML(m.label)).join(', ')}</a></div>`;
  }
  return `<div class="mb-card ${greyed}">
    <div class="mb-card-head">
      <span class="mb-card-icon">${def.icon || '·'}</span>
      <span class="mb-card-name">${escapeHTML(def.name)}</span>
      <span class="mb-card-qty">${qty > 0 ? `×${qty}` : '<span class="mb-dim">none</span>'}</span>
    </div>
    <div class="mb-card-meta">Tier ${tier} ink</div>
    ${canMixHtml}
  </div>`;
}

// ---- Vessels tab ----

function renderVesselsTab() {
  const inv = _state.player.inventory;
  const cards = [];
  for (const id of ['clay_flask', 'bound_parchment', 'glass_vial']) {
    const def = ITEMS[id];
    if (!def) continue;
    const qty = inv.count(id);
    const sources = sourceHint(id).map(s => `<li>${escapeHTML(s)}</li>`).join('');
    cards.push(`<div class="mb-card ${qty <= 0 ? 'mb-card-empty' : ''}">
      <div class="mb-card-head">
        <span class="mb-card-icon">${def.icon || '·'}</span>
        <span class="mb-card-name">${escapeHTML(def.name)}</span>
        <span class="mb-card-qty">${qty > 0 ? `×${qty}` : '<span class="mb-dim">none</span>'}</span>
      </div>
      <div class="mb-card-meta">${escapeHTML(essenceLabel(def.vessel.essence))} vessel · tier ${def.vessel.tier}</div>
      <div class="mb-card-sources"><b>How to get</b><ul>${sources}</ul></div>
    </div>`);
  }
  return `<div class="mb-grid">${cards.join('')}</div>`;
}

// ---- Recipes tab — every ink recipe with live craft status ----

function renderRecipesTab() {
  const inv = _state.player.inventory;
  const cards = [];
  for (const r of INK_RECIPES) {
    const known = _state.player.knownRecipes?.has(r.id);
    const st = recipeStatus(r, inv, ITEMS);
    let badge, badgeCls;
    if (st.canCraft) { badge = '✓ Ready'; badgeCls = 'mb-badge-good'; }
    else if (st.missing.length <= 2) { badge = `Almost — short ${st.missing.length}`; badgeCls = 'mb-badge-warn'; }
    else { badge = `Need ${st.missing.length}`; badgeCls = 'mb-badge-locked'; }
    if (!known) badge += ' · ???';
    const need = st.missing.map(m => `<li>${escapeHTML(m.label)}${m.needQty ? ` (have ${m.haveQty}/${m.needQty})` : ''}</li>`).join('');
    cards.push(`<div class="mb-card mb-card-recipe">
      <div class="mb-card-head">
        <span class="mb-card-name">${known ? escapeHTML(r.name) : `??? <span class="mb-dim">tier ${r.tier}</span>`}</span>
        <span class="mb-badge ${badgeCls}">${badge}</span>
      </div>
      <div class="mb-card-meta">Tier ${r.tier}${r.vessel ? ` · vessel: ${ITEMS[r.vessel]?.name || r.vessel}` : ''}</div>
      ${need ? `<div class="mb-card-need"><b>Missing</b><ul>${need}</ul></div>` : ''}
      <div class="mb-card-jump">
        <a class="mb-recipe-link" data-recipe="${r.id}">→ Show in workshop</a>
      </div>
    </div>`);
  }
  return `<div class="mb-grid">${cards.join('')}</div>`;
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
