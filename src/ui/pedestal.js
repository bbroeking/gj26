// Runestone Pedestal — Phase B. Press an ink onto a rune-stone to make
// a rune. 2-slot UI (ink + rune-stone) → output rune item.
//
// Mapping in spells.js INK_TO_RUNE.
//
// Public API:
//   showPedestal(player, log)
//   closePedestal()
//   isPedestalOpen()

import { ITEMS } from '../data/items.js';
import { INK_TO_RUNE } from '../game/spells.js';

let _state = null;

export function isPedestalOpen() { return !!_state; }

export function closePedestal() {
  document.getElementById('pedestal-backdrop')?.classList.remove('open');
  _state = null;
}

export function showPedestal(player, log) {
  const backdrop = document.getElementById('pedestal-backdrop');
  if (!backdrop) return;
  _state = {
    player, log,
    inkSelected: null,        // item id of the ink chosen
  };
  bindOnce();
  render();
  backdrop.classList.add('open');
}

let _bound = false;
function bindOnce() {
  if (_bound) return;
  _bound = true;
  document.getElementById('pd-close')?.addEventListener('click', closePedestal);
  document.getElementById('pedestal-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'pedestal-backdrop') closePedestal();
  });
  document.getElementById('pd-press-btn')?.addEventListener('click', tryPress);
  document.getElementById('pd-ink-list')?.addEventListener('click', e => {
    const btn = e.target.closest('.pd-ink');
    if (!btn) return;
    _state.inkSelected = btn.dataset.item;
    render();
  });
}

function render() {
  if (!_state) return;
  renderInkList();
  renderSelected();
  renderPreview();
}

function renderInkList() {
  const root = document.getElementById('pd-ink-list');
  if (!root) return;
  const inv = _state.player.inventory;
  const rows = [];
  for (let i = 0; i < inv.slots.length; i++) {
    const slot = inv.slots[i];
    if (!slot) continue;
    const def = ITEMS[slot.id];
    if (!def?.ink) continue;
    const runeId = INK_TO_RUNE[slot.id];
    if (!runeId) continue;            // ink with no rune mapping yet
    const isSelected = _state.inkSelected === slot.id;
    rows.push(`
      <button class="pd-ink ${isSelected ? 'pd-ink-active' : ''}" data-item="${slot.id}">
        <span class="pd-icon">${def.icon || '·'}</span>
        <span class="pd-name">${escapeHTML(def.name)}</span>
        <span class="pd-qty">×${slot.qty || 1}</span>
        <span class="pd-arrow">→ ${ITEMS[runeId]?.icon || ''}</span>
      </button>
    `);
  }
  root.innerHTML = rows.join('') || '<div class="pd-empty">No inks in your bag. Mix some at the Inscribing Table first.</div>';
}

function renderSelected() {
  const stoneEl = document.getElementById('pd-stone');
  const inkEl = document.getElementById('pd-ink-pick');
  const inv = _state.player.inventory;
  const stoneCount = inv.count('rune_stone');
  if (stoneEl) {
    stoneEl.innerHTML = `<div class="pd-slot-icon">🪨</div>
      <div class="pd-slot-label">Rune Stone</div>
      <div class="pd-slot-meta">×${stoneCount}</div>`;
    stoneEl.classList.toggle('pd-slot-empty', stoneCount === 0);
  }
  if (inkEl) {
    if (_state.inkSelected) {
      const def = ITEMS[_state.inkSelected];
      inkEl.innerHTML = `<div class="pd-slot-icon">${def?.icon || '·'}</div>
        <div class="pd-slot-label">${escapeHTML(def?.name || '')}</div>
        <div class="pd-slot-meta">click another to swap</div>`;
      inkEl.classList.remove('pd-slot-empty');
    } else {
      inkEl.innerHTML = `<div class="pd-slot-icon">·</div>
        <div class="pd-slot-label">Ink</div>
        <div class="pd-slot-meta">click an ink below</div>`;
      inkEl.classList.add('pd-slot-empty');
    }
  }
}

function renderPreview() {
  const out = document.getElementById('pd-output');
  const btn = document.getElementById('pd-press-btn');
  if (!out || !btn) return;
  const inv = _state.player.inventory;
  if (!_state.inkSelected || inv.count('rune_stone') < 1) {
    out.innerHTML = '<div class="pd-output-empty">Pick an ink and ensure you have a rune stone.</div>';
    btn.disabled = true;
    btn.textContent = 'Press';
    return;
  }
  const runeId = INK_TO_RUNE[_state.inkSelected];
  const runeDef = ITEMS[runeId];
  if (!runeDef) {
    out.innerHTML = '<div class="pd-output-empty">This ink has no rune binding yet.</div>';
    btn.disabled = true;
    return;
  }
  out.innerHTML = `<div class="pd-output-success">
    <div class="pd-icon-big">${runeDef.icon}</div>
    <div class="pd-out-name">${escapeHTML(runeDef.name)}</div>
    <div class="pd-out-meta">${escapeHTML(runeDef.desc || '')}</div>
  </div>`;
  btn.disabled = false;
  btn.textContent = `Press → ${runeDef.name}`;
}

function tryPress() {
  if (!_state || !_state.inkSelected) return;
  const inv = _state.player.inventory;
  if (inv.count('rune_stone') < 1) {
    _state.log('hint', 'You need a Rune Stone to press an ink into.');
    return;
  }
  const runeId = INK_TO_RUNE[_state.inkSelected];
  if (!runeId) return;
  inv.remove(_state.inkSelected, 1);
  inv.remove('rune_stone', 1);
  inv.add(runeId, 1);
  // Magic XP — small grant per press (gathering of magic, not casting)
  import('../game/skills.js').then(m => m.awardXp(_state.player, 'magic', 8, _state.log));
  _state.log('skill', `★ Pressed ${ITEMS[runeId]?.name || runeId}.`);
  // Clear ink selection if depleted
  if (inv.count(_state.inkSelected) === 0) _state.inkSelected = null;
  render();
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
