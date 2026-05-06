// Refinement Station — single modal that surfaces every reagent from
// materials.js. Each reagent declares its source raw material + station
// (mortar / grindstone / vessel / curing / kiln). The modal groups by
// station and dims rows the player can't refine. Click an affordable
// row → engine consumes the raw, mints the reagent, awards XP.
//
// Engine API consumed:
//   deps.refineRecipe(reagentId) → consumes raw + adds reagent

import { MATERIAL_DEFS } from '../data/materials.js';
import { ITEMS } from '../data/items.js';

const STATION_LABELS = {
  mortar:     { label: 'Mortar',     desc: 'Pound herbs and roots into reagent powder.' },
  grindstone: { label: 'Grindstone', desc: 'Grind ore + bone into a fine grit or powder.' },
  vessel:     { label: 'Vessel',     desc: 'Bottle water + dew before sunrise.' },
  curing:     { label: 'Curing',     desc: 'Tan pelts into workable leather.' },
  kiln:       { label: 'Kiln',       desc: 'Fire charcoal sticks into ash; clay into vessels.' },
};
const STATION_ORDER = ['mortar', 'grindstone', 'vessel', 'curing', 'kiln'];

let _state = null;

export function showRefineStation(player, log, deps = {}) {
  const backdrop = document.getElementById('refine-station-backdrop');
  if (!backdrop) return;
  _state = { player, log, deps };
  render();
  backdrop.classList.add('open');
  document.getElementById('refine-station-close')?.addEventListener('click', closeRefineStation, { once: true });
  backdrop.addEventListener('click', _onBackdropClick);
  window.addEventListener('keydown', _onKey);
}

export function closeRefineStation() {
  const backdrop = document.getElementById('refine-station-backdrop');
  if (!backdrop) return;
  backdrop.classList.remove('open');
  backdrop.removeEventListener('click', _onBackdropClick);
  window.removeEventListener('keydown', _onKey);
  _state = null;
}

export function isRefineStationOpen() { return !!_state; }

function _onBackdropClick(e) {
  if (e.target.id === 'refine-station-backdrop') closeRefineStation();
}
function _onKey(e) {
  if (e.key === 'Escape' && isRefineStationOpen()) {
    e.preventDefault();
    e.stopPropagation();
    closeRefineStation();
  }
}

function render() {
  const body = document.getElementById('refine-station-body');
  if (!body || !_state) return;
  const { player } = _state;
  // Reagents = MATERIAL_DEFS entries with refines + station fields.
  const reagents = MATERIAL_DEFS.filter(m => m.tier === 'reagent' && m.refines && m.station);
  const buckets = {};
  for (const m of reagents) (buckets[m.station] ||= []).push(m);
  const refinableCount = reagents.filter(m => _statusFor(player, m).ok).length;
  let html = `<div class="pf-headline">${refinableCount} of ${reagents.length} refinable now</div>`;
  for (const stKey of STATION_ORDER) {
    const bucket = buckets[stKey];
    if (!bucket || bucket.length === 0) continue;
    const meta = STATION_LABELS[stKey];
    html += `<div class="rs-section">
      <div class="rs-section-head">${escapeHtml(meta?.label || stKey)} <span class="codex-section-count">${bucket.length}</span></div>
      <div class="rs-section-desc">${escapeHtml(meta?.desc || '')}</div>
      ${bucket.map(_rowHTML).join('')}
    </div>`;
  }
  body.innerHTML = html;
  body.querySelectorAll('.pf-row').forEach(row => {
    row.addEventListener('click', () => _onRefineClick(row.dataset.id));
  });
}

function _statusFor(player, m) {
  const have = player.inventory.count(m.refines);
  if (have < 1) {
    const def = ITEMS[m.refines];
    return { ok: false, reason: `Missing 1× ${def?.name || m.refines}.` };
  }
  return { ok: true };
}

function _rowHTML(m) {
  const def = ITEMS[m.id];
  const src = ITEMS[m.refines];
  const have = _state.player.inventory.count(m.refines);
  const status = _statusFor(_state.player, m);
  const lockClass = status.ok ? 'pf-row-ok' : 'pf-row-locked';
  const okPill = have > 0 ? 'ok' : 'missing';
  return `<div class="pf-row ${lockClass}" data-id="${escapeHtml(m.id)}">
    <div class="pf-row-head">
      <div class="pf-row-name">${escapeHtml(def?.name || m.id)}</div>
      <div class="pf-row-req">${escapeHtml(m.station)}</div>
    </div>
    <div class="pf-row-flow">
      <div class="pf-pills">
        <span class="pf-pill ${okPill}">1× ${escapeHtml(src?.name || m.refines)}<span class="pf-have">${have}/1</span></span>
      </div>
      <div class="pf-arrow">→</div>
      <div class="pf-output"><span class="pf-output-name">${escapeHtml(def?.name || m.id)}</span></div>
    </div>
    ${!status.ok ? `<div class="pf-locked-reason">${escapeHtml(status.reason)}</div>` : ''}
  </div>`;
}

function _onRefineClick(id) {
  if (!_state) return;
  const refine = _state.deps?.refineRecipe;
  if (typeof refine !== 'function') return;
  refine(id);
  render();
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
