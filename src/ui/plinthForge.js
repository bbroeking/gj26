// Plinth Forge — the orb-forging UI surfaced from the Wayfinding Workshop.
// Lists every ORB_RECIPES entry, dimming the locked / unaffordable rows
// with a clear "missing X" label so the player knows what to gather next.
// Click an affordable row → fires window.__game.forgeOrb(id) → orb lands
// in inventory with rolled properties.
//
// Engine API consumed:
//   window.__game.forgeOrb(recipeId)         → { ok, output, rolls }
//   window.__game.canForgeOrb(recipeId)      → { ok, reason?, recipe? }
//   window.__game.listForgeableOrbs()        → string[] of forgeable ids

import { ORB_RECIPES } from '../data/orb-recipes.js';
import { ITEMS } from '../data/items.js';

let _state = null;

/** Show the Plinth Forge modal. `deps.onChange` is fired after every
 *  successful forge so the bag/HUD can refresh. `deps.onClose` is
 *  called when the modal is dismissed (used by the workshop to reopen
 *  the parent panel). */
export function showPlinthForge(player, log, deps = {}) {
  const backdrop = document.getElementById('plinth-forge-backdrop');
  if (!backdrop) return;
  _state = { player, log, deps };
  render();
  backdrop.classList.add('open');
  // Wire close handlers (idempotent — re-add on each show so we don't leak).
  document.getElementById('plinth-forge-close')?.addEventListener('click', closePlinthForge, { once: true });
  backdrop.addEventListener('click', _onBackdropClick);
  window.addEventListener('keydown', _onKey);
}

export function closePlinthForge() {
  const backdrop = document.getElementById('plinth-forge-backdrop');
  if (!backdrop) return;
  backdrop.classList.remove('open');
  backdrop.removeEventListener('click', _onBackdropClick);
  window.removeEventListener('keydown', _onKey);
  const onClose = _state?.deps?.onClose;
  _state = null;
  if (typeof onClose === 'function') onClose();
}

export function isPlinthForgeOpen() {
  return !!_state;
}

function _onBackdropClick(e) {
  if (e.target.id === 'plinth-forge-backdrop') closePlinthForge();
}
function _onKey(e) {
  if (e.key === 'Escape' && isPlinthForgeOpen()) {
    e.preventDefault();
    e.stopPropagation();
    closePlinthForge();
  }
}

function render() {
  const body = document.getElementById('plinth-forge-body');
  if (!body || !_state) return;
  const { player } = _state;
  const lv = player.skills.carto?.lv || 1;

  // Sort by reqLevel ascending so the player reads the ladder.
  const entries = Object.entries(ORB_RECIPES)
    .map(([id, r]) => ({ id, r, status: _statusFor(player, id, r) }))
    .sort((a, b) => (a.r.reqLevel || 1) - (b.r.reqLevel || 1));

  const forgeableCount = entries.filter(e => e.status.ok).length;
  const headLine = `<div class="pf-headline">Wayfinding ${lv} · ${forgeableCount} of ${entries.length} forgeable now</div>`;
  body.innerHTML = headLine + entries.map(_recipeRowHTML).join('');
  // Wire row clicks.
  body.querySelectorAll('.pf-row').forEach(row => {
    row.addEventListener('click', () => _onForgeClick(row.dataset.id));
  });
}

function _statusFor(player, id, r) {
  // Prefer the engine's canonical check when it's exposed; falls back
  // to a local replication so this module stays useful without it.
  const can = (typeof window !== 'undefined' && window.__game?.canForgeOrb)
    ? window.__game.canForgeOrb(id)
    : _localCanForge(player, r);
  return can;
}

function _localCanForge(player, r) {
  const lv = player.skills.carto?.lv || 1;
  if (r.reqLevel && lv < r.reqLevel) return { ok: false, reason: `Need Wayfinding ${r.reqLevel}.` };
  const inputs = _flatInputs(r);
  for (const [id, n] of Object.entries(inputs)) {
    if (player.inventory.count(id) < n) {
      const def = ITEMS[id];
      return { ok: false, reason: `Missing ${n}× ${def?.name || id}.` };
    }
  }
  return { ok: true };
}

function _flatInputs(r) {
  const inputs = { ...(r.inks || {}) };
  if (r.core)     inputs[r.core] = (inputs[r.core] || 0) + 1;
  if (r.catalyst) inputs[r.catalyst] = (inputs[r.catalyst] || 0) + 1;
  if (r.blank)    inputs[r.blank] = (inputs[r.blank] || 0) + 1;
  return inputs;
}

function _ingredientPill(player, id, n) {
  const def = ITEMS[id];
  const have = player.inventory.count(id);
  const ok = have >= n;
  return `<span class="pf-pill ${ok ? 'ok' : 'missing'}">${n}× ${escapeHtml(def?.name || id)}<span class="pf-have">${have}/${n}</span></span>`;
}

function _recipeRowHTML({ id, r, status }) {
  const out = ITEMS[r.output];
  const inputs = _flatInputs(r);
  const pills = Object.entries(inputs)
    .map(([iid, n]) => _ingredientPill(_state.player, iid, n)).join('');
  const rollList = (r.rolls || []).map(p => `<span class="pf-roll">${escapeHtml(p)}</span>`).join(' ');
  const lockClass = status.ok ? 'pf-row-ok' : 'pf-row-locked';
  return `<div class="pf-row ${lockClass}" data-id="${escapeHtml(id)}">
    <div class="pf-row-head">
      <div class="pf-row-name">${escapeHtml(r.label || id)}</div>
      <div class="pf-row-req">Wayfinding ${r.reqLevel || 1} · ${r.xp || 0} XP</div>
    </div>
    <div class="pf-row-flow">
      <div class="pf-pills">${pills}</div>
      <div class="pf-arrow">→</div>
      <div class="pf-output">
        <span class="pf-output-name">${escapeHtml(out?.name || r.output)}</span>
        ${rollList ? `<span class="pf-rolls">rolls ${rollList}</span>` : ''}
      </div>
    </div>
    ${!status.ok ? `<div class="pf-locked-reason">${escapeHtml(status.reason || 'Locked')}</div>` : ''}
  </div>`;
}

function _onForgeClick(id) {
  if (!_state) return;
  const { log, deps } = _state;
  const forge = window.__game?.forgeOrb;
  if (typeof forge !== 'function') {
    log('hint', 'The Plinth is cold — orb-forge handler missing.');
    return;
  }
  const result = forge(id);
  if (!result?.ok) {
    // The handler logs its own reason — just re-render to refresh
    // the ingredient counters in case the player partially consumed.
    render();
    return;
  }
  // Successful forge — re-render so consumed inputs show, fire onChange.
  render();
  if (typeof deps.onChange === 'function') deps.onChange();
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
