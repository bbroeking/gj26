// Cook Fire — recipe browser surfaced when the player interacts with
// a fire tile. Lists every COOK_RECIPES entry; dims the locked /
// unaffordable rows; click a forgeable row to actually cook. Mirrors
// plinthForge.js in shape so the patterns stay consistent.
//
// Engine API consumed:
//   deps.cookRecipe(recipeId) → fires the engine handler that consumes
//     inputs, rolls burn/success, awards XP, and adds outputs.

import { COOK_RECIPES } from '../data/cook-recipes.js';
import { ITEMS } from '../data/items.js';

let _state = null;

export function showCookFire(player, log, deps = {}) {
  const backdrop = document.getElementById('cook-fire-backdrop');
  if (!backdrop) return;
  _state = { player, log, deps };
  render();
  backdrop.classList.add('open');
  document.getElementById('cook-fire-close')?.addEventListener('click', closeCookFire, { once: true });
  backdrop.addEventListener('click', _onBackdropClick);
  window.addEventListener('keydown', _onKey);
}

export function closeCookFire() {
  const backdrop = document.getElementById('cook-fire-backdrop');
  if (!backdrop) return;
  backdrop.classList.remove('open');
  backdrop.removeEventListener('click', _onBackdropClick);
  window.removeEventListener('keydown', _onKey);
  _state = null;
}

export function isCookFireOpen() {
  return !!_state;
}

function _onBackdropClick(e) {
  if (e.target.id === 'cook-fire-backdrop') closeCookFire();
}
function _onKey(e) {
  if (e.key === 'Escape' && isCookFireOpen()) {
    e.preventDefault();
    e.stopPropagation();
    closeCookFire();
  }
}

function render() {
  const body = document.getElementById('cook-fire-body');
  if (!body || !_state) return;
  const { player } = _state;
  const lv = player.skills.cook?.lv || 1;
  const entries = Object.entries(COOK_RECIPES)
    .map(([id, r]) => ({ id, r, status: _statusFor(player, id, r) }))
    .sort((a, b) => (a.r.reqLevel || 1) - (b.r.reqLevel || 1));
  const cookableCount = entries.filter(e => e.status.ok).length;
  const head = `<div class="pf-headline">Cooking ${lv} · ${cookableCount} of ${entries.length} cookable now</div>`;
  body.innerHTML = head + entries.map(_recipeRowHTML).join('');
  body.querySelectorAll('.pf-row').forEach(row => {
    row.addEventListener('click', () => _onCookClick(row.dataset.id));
  });
}

function _statusFor(player, id, r) {
  const lv = player.skills.cook?.lv || 1;
  if (r.reqLevel && lv < r.reqLevel) return { ok: false, reason: `Need Cooking ${r.reqLevel}.` };
  const inputs = r.inputs ?? { [r.input]: 1 };
  for (const [iid, n] of Object.entries(inputs)) {
    if (player.inventory.count(iid) < n) {
      const def = ITEMS[iid];
      return { ok: false, reason: `Missing ${n}× ${def?.name || iid}.` };
    }
  }
  return { ok: true };
}

function _recipeRowHTML({ id, r, status }) {
  const out = ITEMS[r.output];
  const inputs = r.inputs ?? { [r.input]: 1 };
  const pills = Object.entries(inputs).map(([iid, n]) => {
    const def = ITEMS[iid];
    const have = _state.player.inventory.count(iid);
    const ok = have >= n;
    return `<span class="pf-pill ${ok ? 'ok' : 'missing'}">${n}× ${escapeHtml(def?.name || iid)}<span class="pf-have">${have}/${n}</span></span>`;
  }).join('');
  const lockClass = status.ok ? 'pf-row-ok' : 'pf-row-locked';
  // Burn rate hint for single-input recipes, since the engine rolls one;
  // compound recipes skip the burn roll.
  const burnHint = (r.input && r.burnBase != null)
    ? `<span class="cf-burn">burn at lv 1: ${Math.round(r.burnBase * 100)}%</span>`
    : (r.inputs ? `<span class="cf-burn">no burn</span>` : '');
  return `<div class="pf-row ${lockClass}" data-id="${escapeHtml(id)}">
    <div class="pf-row-head">
      <div class="pf-row-name">${escapeHtml(r.label || id)}</div>
      <div class="pf-row-req">Cooking ${r.reqLevel || 1} · ${r.xp || 0} XP ${burnHint}</div>
    </div>
    <div class="pf-row-flow">
      <div class="pf-pills">${pills}</div>
      <div class="pf-arrow">→</div>
      <div class="pf-output">
        <span class="pf-output-name">${escapeHtml(out?.name || r.output)}</span>
        ${out?.food ? `<span class="pf-rolls">heals ${out.food.heal}</span>` : ''}
      </div>
    </div>
    ${!status.ok ? `<div class="pf-locked-reason">${escapeHtml(status.reason)}</div>` : ''}
  </div>`;
}

function _onCookClick(id) {
  if (!_state) return;
  const cook = _state.deps?.cookRecipe;
  if (typeof cook !== 'function') return;
  cook(id);
  // Re-render so the consumed-counts and burn outcome show.
  render();
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
