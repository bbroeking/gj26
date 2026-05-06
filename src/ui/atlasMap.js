// Living Atlas — region overview modal.
//
// Shows the four atlas regions as parchment cards. Each card has lore,
// a progress bar (X / threshold completions), and either a locked badge
// or a "Walk to <biome>" button when the region is unlocked.
//
// Public API:
//   showAtlasMap(player, log, opts)
//     opts = { onEnterBiome(biomeId) }
//   closeAtlasMap()
//   isAtlasMapOpen()

import { ATLAS_REGIONS } from '../data/atlas-regions.js';
import { ensureAtlasLoaded, getRegionState, isBiomeUnlocked } from '../game/atlas.js';

let _state = null;

export function isAtlasMapOpen() { return !!_state; }

export function showAtlasMap(player, log, opts = {}) {
  const backdrop = document.getElementById('atlas-map-backdrop');
  if (!backdrop) return;
  ensureAtlasLoaded(player);
  _state = { player, log, onEnterBiome: opts.onEnterBiome };
  bindOnce();
  render();
  backdrop.classList.add('open');
}

export function closeAtlasMap() {
  document.getElementById('atlas-map-backdrop')?.classList.remove('open');
  _state = null;
}

let _bound = false;
function bindOnce() {
  if (_bound) return;
  _bound = true;
  document.getElementById('am-close')?.addEventListener('click', closeAtlasMap);
  document.getElementById('atlas-map-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'atlas-map-backdrop') closeAtlasMap();
  });
  document.getElementById('am-grid')?.addEventListener('click', e => {
    const btn = e.target.closest('.am-walk');
    if (!btn) return;
    const biomeId = btn.dataset.biome;
    if (!biomeId) return;
    // Capture the callback before closeAtlasMap nulls _state.
    const onEnterBiome = _state?.onEnterBiome;
    closeAtlasMap();
    onEnterBiome?.(biomeId);
  });
}

function render() {
  const grid = document.getElementById('am-grid');
  const summary = document.getElementById('am-summary');
  if (!grid || !_state) return;
  const player = _state.player;
  let unlockedCount = 0;
  const cards = ATLAS_REGIONS.map(r => {
    const st = getRegionState(player, r.id);
    if (st.unlocked) unlockedCount++;
    const pct = Math.min(100, (st.count / st.threshold) * 100);
    const ledger = `${st.count} / ${st.threshold}`;
    const cls = st.unlocked ? 'am-card am-card-unlocked' : 'am-card';
    const action = st.unlocked
      ? `<button class="am-walk" data-biome="${r.biomeUnlock}">→ Walk to ${escapeHTML(r.biomeName)}</button>`
      : `<div class="am-locked">Locked · clear ${st.threshold - st.count} more chart${(st.threshold - st.count) === 1 ? '' : 's'}</div>`;
    return `<div class="${cls}">
      <div class="am-card-head">
        <div class="am-card-name">${escapeHTML(r.name)}</div>
        <div class="am-card-ledger">${ledger}</div>
      </div>
      <div class="am-bar"><div class="am-bar-fill" style="width:${pct.toFixed(1)}%"></div></div>
      <div class="am-lore">${escapeHTML(r.lore)}</div>
      <div class="am-biome">
        <span class="am-biome-icon">${st.unlocked ? '◉' : '◯'}</span>
        <span class="am-biome-name">${escapeHTML(r.biomeName)}</span>
        <span class="am-biome-desc">— ${escapeHTML(r.biomeDesc)}</span>
      </div>
      <div class="am-action">${action}</div>
    </div>`;
  });
  grid.innerHTML = cards.join('');
  if (summary) {
    summary.textContent = unlockedCount === 0
      ? 'No regions unlocked yet. Complete charts to fill the atlas.'
      : `${unlockedCount} of ${ATLAS_REGIONS.length} regions unlocked.`;
  }
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
