// Abilities Book — unified registry of melee + magic + ranged actions.
// Click an action → bind to next empty action-bar slot (1..8).
// Click an action-bar slot in the header → unbind it.
//
// Public API:
//   showSpellbook(player)   (named for legacy compat with main.js)
//   closeSpellbook()
//   isSpellbookOpen()

import { ALL_ACTION_IDS, getAction, actionUnlocked, actionCanAfford } from '../game/actions.js';
import { ITEMS } from '../data/items.js';
import { getSlotKey, setSlotKey } from '../core/input.js';

let _open = false;

export function isSpellbookOpen() { return _open; }

export function closeSpellbook() {
  document.getElementById('spellbook-backdrop')?.classList.remove('open');
  _open = false;
}

export function showSpellbook(player) {
  const backdrop = document.getElementById('spellbook-backdrop');
  if (!backdrop) return;
  player.actionBar ||= ['cleave', 'leap', 'rend', 'whirlwind', null, null, null, null];
  bindOnce(player);
  render(player);
  backdrop.classList.add('open');
  _open = true;
}

let _bound = false;
function bindOnce(player) {
  if (_bound) return;
  _bound = true;
  document.getElementById('sb-close')?.addEventListener('click', closeSpellbook);
  document.getElementById('spellbook-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'spellbook-backdrop') closeSpellbook();
  });
  // Click an action-bar slot pip in the header → unbind it
  document.getElementById('sb-bar')?.addEventListener('click', e => {
    const pip = e.target.closest('.sb-bar-pip');
    if (!pip) return;
    const slot = +pip.dataset.slot;
    if (player.actionBar[slot - 1]) {
      player.actionBar[slot - 1] = null;
      persist(player);
      render(player);
    }
  });
  // Right-click a pip → enter "press a key" mode to rebind that slot's key
  document.getElementById('sb-bar')?.addEventListener('contextmenu', e => {
    e.preventDefault();
    const pip = e.target.closest('.sb-bar-pip');
    if (!pip) return;
    const slot = +pip.dataset.slot;
    pip.classList.add('sb-bar-rebinding');
    pip.querySelector('.sb-bar-key').textContent = '?';
    const onKey = (ev) => {
      ev.preventDefault();
      ev.stopPropagation();
      const k = ev.key.toLowerCase();
      // Skip if it's a modifier-only or whitespace press
      if (!k || k.length !== 1) {
        pip.classList.remove('sb-bar-rebinding');
        render(player);
        window.removeEventListener('keydown', onKey, true);
        return;
      }
      setSlotKey(slot, k);
      pip.classList.remove('sb-bar-rebinding');
      render(player);
      window.removeEventListener('keydown', onKey, true);
    };
    window.addEventListener('keydown', onKey, true);
  });
  // Tab buttons
  document.querySelectorAll('.sb-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      _state.tab = btn.dataset.tab;
      document.querySelectorAll('.sb-tab').forEach(b => b.classList.toggle('sb-tab-active', b === btn));
      renderList(player);
    });
  });
  // Action click → bind to next empty slot
  document.getElementById('sb-body')?.addEventListener('click', e => {
    const row = e.target.closest('.sb-row');
    if (!row || row.classList.contains('sb-locked')) return;
    const id = row.dataset.action;
    bindToNextSlot(player, id);
  });
}

const _state = { tab: 'all' };

function bindToNextSlot(player, id) {
  // If this action is already bound, do nothing.
  if (player.actionBar.includes(id)) return;
  for (let i = 0; i < player.actionBar.length; i++) {
    if (!player.actionBar[i]) {
      player.actionBar[i] = id;
      persist(player);
      render(player);
      return;
    }
  }
  // No empty slot — overwrite slot 8
  player.actionBar[7] = id;
  persist(player);
  render(player);
}

/** Drag-drop landing — bind a specific id to a specific slot, even if it
 *  was already bound elsewhere (move, not duplicate). */
function bindToSpecificSlot(player, id, slot) {
  const idx = slot - 1;
  // If this id is already in another slot, clear it (move semantics)
  for (let i = 0; i < player.actionBar.length; i++) {
    if (player.actionBar[i] === id && i !== idx) player.actionBar[i] = null;
  }
  player.actionBar[idx] = id;
  persist(player);
  render(player);
}

function persist(player) {
  try { localStorage.setItem('gj26.actionBar', JSON.stringify(player.actionBar)); } catch (_) {}
}

function render(player) {
  renderHeader(player);
  renderList(player);
}

function renderHeader(player) {
  const bar = document.getElementById('sb-bar');
  if (!bar) return;
  bar.innerHTML = player.actionBar.map((id, i) => {
    const a = id ? getAction(id) : null;
    const key = getSlotKey(i + 1) || (i + 1);
    const tip = a
      ? `${a.name} — slot ${i + 1}, key [${key.toUpperCase()}]. Click to unbind. Right-click to rebind key.`
      : `Empty slot ${i + 1} — key [${key.toUpperCase()}]. Drop an action here, or right-click to rebind the key.`;
    return `<div class="sb-bar-pip ${a ? '' : 'sb-bar-empty'}" data-slot="${i + 1}" data-drop="1" title="${tip}">
      <span class="sb-bar-key">${String(key).toUpperCase()}</span>
      <span class="sb-bar-icon">${a ? a.icon : '·'}</span>
    </div>`;
  }).join('');
  // Wire drag-drop targets
  bar.querySelectorAll('.sb-bar-pip').forEach(pip => {
    pip.addEventListener('dragover', e => {
      e.preventDefault();
      pip.classList.add('sb-bar-pip-dragover');
    });
    pip.addEventListener('dragleave', () => pip.classList.remove('sb-bar-pip-dragover'));
    pip.addEventListener('drop', e => {
      e.preventDefault();
      pip.classList.remove('sb-bar-pip-dragover');
      const id = e.dataTransfer.getData('text/plain');
      if (!id) return;
      const slot = +pip.dataset.slot;
      bindToSpecificSlot(player, id, slot);
    });
  });
}

function renderList(player) {
  const body = document.getElementById('sb-body');
  if (!body) return;
  const lv = player.skills.magic?.lv || 1;
  const tab = _state.tab || 'all';
  const ids = ALL_ACTION_IDS();
  body.innerHTML = '';
  for (const id of ids) {
    const a = getAction(id);
    if (!a) continue;
    if (tab !== 'all' && a.kind !== tab) continue;
    const locked = !actionUnlocked(player, id);
    const stub = !!a.stub;
    const affordable = actionCanAfford(player, id);
    const isBound = player.actionBar.includes(id);
    const costStr = formatCost(a, player);
    const row = document.createElement('div');
    // Stubs get the locked styling so binding/dragging is suppressed and the
    // row visually reads as "not yet available" — same semantics as level-locked.
    row.className = `sb-row sb-row-${a.kind} ${locked || stub ? 'sb-locked' : ''} ${stub ? 'sb-stub' : ''} ${isBound ? 'sb-bound-row' : ''}`;
    row.dataset.action = id;
    if (!locked && !stub) {
      row.draggable = true;
      row.addEventListener('dragstart', e => {
        e.dataTransfer.setData('text/plain', id);
        e.dataTransfer.effectAllowed = 'move';
        row.classList.add('sb-row-dragging');
      });
      row.addEventListener('dragend', () => row.classList.remove('sb-row-dragging'));
    }
    const stubTag = stub ? ' · <span class="sb-stub-badge">COMING SOON</span>' : '';
    row.innerHTML = `
      <div class="sb-row-head">
        <div class="sb-name"><span class="sb-row-icon">${a.icon}</span> ${escapeHTML(a.name)}</div>
        <div class="sb-tag">${a.kind.toUpperCase()} · ${a.reqSkill.toUpperCase()} ${a.reqLevel}${isBound ? ' · BOUND' : ''}${stubTag}</div>
      </div>
      <div class="sb-desc">${escapeHTML(a.desc)}</div>
      <div class="sb-pros">
        <span class="sb-benefit">+ ${escapeHTML(a.benefit || '')}</span>
        <span class="sb-drawback">− ${escapeHTML(a.drawback || '')}</span>
      </div>
      <div class="sb-cost">${stub
        ? '<span class="sb-cost-low">Not yet implemented — listed for the v2 catalog.</span>'
        : (locked ? `<span class="sb-cost-low">Locked — needs ${a.reqSkill.toUpperCase()} ${a.reqLevel}.</span>` : costStr)}</div>
    `;
    body.appendChild(row);
  }
}

function formatCost(a, player) {
  const parts = [];
  if (a.cost?.stamina) {
    const have = Math.floor(player.stamina ?? 0);
    const ok = have >= a.cost.stamina;
    parts.push(`<span class="${ok ? 'sb-cost-ok' : 'sb-cost-low'}">⚡ ${a.cost.stamina} stamina</span>`);
  }
  if (a.cost?.runes) {
    for (const [k, n] of Object.entries(a.cost.runes)) {
      const have = player.inventory.count(k);
      const ok = have >= n;
      const def = ITEMS[k];
      parts.push(`<span class="${ok ? 'sb-cost-ok' : 'sb-cost-low'}">${def?.icon || '·'} ${n}× ${def?.name || k}</span>`);
    }
  }
  if (a.cost?.ammo) {
    for (const [k, n] of Object.entries(a.cost.ammo)) {
      const have = player.inventory.count(k);
      const ok = have >= n;
      const def = ITEMS[k];
      parts.push(`<span class="${ok ? 'sb-cost-ok' : 'sb-cost-low'}">${def?.icon || '·'} ${n}× ${def?.name || k}</span>`);
    }
  }
  parts.push(`<span class="sb-cost-meta">⏱ ${a.cooldown}s cooldown</span>`);
  return parts.join(' · ');
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
