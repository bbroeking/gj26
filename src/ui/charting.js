// Chart Inscription (Tier 2 of Wayfinding).
// Player picks a template, drops inks into ink-slots, and the bias-roll
// engine produces a chart with N affixes. Ink choice shapes the roll
// distribution; randomness still drives the actual outcome.
//
// Public API:
//   showCharting(player, log, onCommit)
//     onCommit({ template, affixes }) — caller adds chart to inventory.

import { ITEMS } from '../data/items.js';
import { AFFIXES, effectiveStability, rollAffix } from '../data/affixes.js';
import { computeWeights, rollAffixes, inkStabilityBonus } from '../data/affixWeights.js';

const backdrop      = document.getElementById('charting-backdrop');
const root          = document.getElementById('charting');
const templateList  = document.getElementById('ch-template-list');
const slotList      = document.getElementById('ch-slot-list');
const inkList       = document.getElementById('ch-ink-list');
const previewBody   = document.getElementById('ch-preview-body');
const rollBtn       = document.getElementById('ch-roll-btn');

// Chart templates. affixSlots = how many affix slots roll. inkSlots =
// how many ink slots the player can drop inks into to bias rolls.
const TEMPLATES = [
  { id: 'snug',       tier: 1, name: 'Snug',          desc: 'A pocket cellar — no affixes. Quick run.', reqCarto: 1,  baseItem: 'chart_snug',       affixSlots: 0, inkSlots: 1, baseCost: { hedge_ink: 1 } },
  { id: 'tier_1',     tier: 1, name: 'Tier 1 Hollow', desc: 'A small, single-floor chart.',              reqCarto: 1,  baseItem: 'chart_tier_1',     affixSlots: 1, inkSlots: 2, baseCost: { hedge_ink: 2 } },
  { id: 'hollow',     tier: 2, name: 'Hollow',        desc: 'Multi-room. Larger, richer chest.',         reqCarto: 10, baseItem: 'chart_hollow',     affixSlots: 2, inkSlots: 3, baseCost: { hedge_ink: 3 } },
  { id: 'briar_maze', tier: 2, name: 'Briar Maze',    desc: 'Twisted layout — corridors over rooms.',    reqCarto: 15, baseItem: 'chart_briar_maze', affixSlots: 2, inkSlots: 3, baseCost: { hedge_ink: 3 } },
  { id: 'sunken_hut', tier: 3, name: 'Sunken Hut',    desc: 'Half-flooded rooms; atmospheric.',          reqCarto: 22, baseItem: 'chart_sunken_hut', affixSlots: 3, inkSlots: 4, baseCost: { hedge_ink: 4, refined_ink: 1 } },
  { id: 'delve',      tier: 3, name: 'Delve',         desc: 'A deeper hollow. Longer, richer, harder.',  reqCarto: 30, baseItem: 'chart_delve',      affixSlots: 3, inkSlots: 4, baseCost: { hedge_ink: 5, refined_ink: 1 } },

  // Echo charts — copy a region of the live overworld and turn its
  // peaceful residents into hostiles. Carto knowledge of the village
  // gives you a real edge: same layout, hostile cast.
  { id: 'echo_village', tier: 2, name: 'Echo: Bramblewood Square', desc: 'Echo the village square. Same layout, hostile residents.',         reqCarto: 35, baseItem: 'chart_echo_village', affixSlots: 1, inkSlots: 2, baseCost: { hedge_ink: 1, refined_ink: 1 } },
  { id: 'echo_forge',   tier: 3, name: "Echo: Hod's Forge",        desc: 'Echo the forge yard. Iron-shod hostiles patrol the anvil.',         reqCarto: 40, baseItem: 'chart_echo_forge',   affixSlots: 2, inkSlots: 3, baseCost: { stoneground_ink: 1, refined_ink: 1, ember_ink: 1 } },
  { id: 'echo_perch',   tier: 3, name: "Echo: Withering's Perch",  desc: 'Echo the falconer\'s perch. Empty roost, hungry hawks.',            reqCarto: 45, baseItem: 'chart_echo_perch',   affixSlots: 2, inkSlots: 3, baseCost: { wellspring_ink: 1, refined_ink: 1, lustrous_ink: 1 } },
];

let _state = null;
let _onCommit = null;

// Rune slot is unlocked at Wayfinding 50 + Magic 30. The slotted rune
// bakes a passive effect into the dungeon (air → enemies -1 dmg,
// fire → +30% chest loot, earth → +3 stone_chip in chest).
const RUNE_SLOT_CARTO = 50;
const RUNE_SLOT_MAGIC = 30;
const RUNE_EFFECTS = {
  rune_air:    { id: 'air',    desc: 'Enemies inside hit for 1 less.' },
  rune_fire:   { id: 'fire',   desc: 'Chest loot quantity +30%.' },
  rune_earth:  { id: 'earth',  desc: '+3 stone-chip drops on completion.' },
  rune_water:  { id: 'water',  desc: 'Stamina regen +20% during the run.' },
  rune_mind:   { id: 'mind',   desc: 'Minimap stays clear regardless of fog.' },
  rune_body:   { id: 'body',   desc: 'Player HP regenerates +1/min in this chart.' },
  rune_chaos:  { id: 'chaos',  desc: 'Random affix slot rolls re-rolled once.' },
};

function runeSlotUnlocked(player) {
  return (player.skills.carto?.lv || 1) >= RUNE_SLOT_CARTO
      && (player.skills.magic?.lv || 1) >= RUNE_SLOT_MAGIC;
}

export function showCharting(player, log, onCommit) {
  _onCommit = onCommit;
  _state = {
    player,
    log,
    selectedTemplate: TEMPLATES[0],
    inkSlots: [null, null, null, null],   // up to 4
    runeSlot: null,                         // optional rune item id
  };
  render();
  backdrop.classList.add('open');
  root.focus();
}

export function closeCharting() {
  backdrop.classList.remove('open');
  _state = null;
  _onCommit = null;
}

// ---- render ----

function render() {
  if (!_state) return;
  renderTemplates();
  renderSlots();
  renderInkBag();
  renderPreview();
}

function renderTemplates() {
  const cartoLv = _state.player.skills.carto.lv;
  templateList.innerHTML = '';
  for (const t of TEMPLATES) {
    const locked = cartoLv < t.reqCarto;
    const div = document.createElement('div');
    div.className = 'ch-template' + (t === _state.selectedTemplate ? ' selected' : '') + (locked ? ' disabled' : '');
    div.innerHTML = `
      <div class="name">${t.name}</div>
      <div class="meta">${locked ? `(Wayfinding ${t.reqCarto})` : t.desc}</div>
    `;
    if (!locked) {
      div.addEventListener('click', () => {
        _state.selectedTemplate = t;
        _state.inkSlots = [null, null, null, null];
        render();
      });
    }
    templateList.appendChild(div);
  }
}

function renderSlots() {
  const t = _state.selectedTemplate;
  slotList.innerHTML = '';
  for (let i = 0; i < t.inkSlots; i++) {
    const inkId = _state.inkSlots[i];
    const def = inkId ? ITEMS[inkId] : null;
    const slot = document.createElement('div');
    slot.className = 'ch-slot ' + (inkId ? 'filled' : 'empty');
    slot.innerHTML = inkId
      ? `<div><b>${escapeHTML(def.name)}</b><div style="font-size:11px;color:var(--text-mid)">click to remove</div></div>
         <div class="stab">${def.icon}</div>`
      : `<div>Slot ${i + 1} — click an ink below</div><div class="stab">·</div>`;
    if (inkId) {
      slot.addEventListener('click', () => {
        _state.inkSlots[i] = null;
        render();
      });
    }
    slotList.appendChild(slot);
  }
  // Rune slot (Lv 50 carto + Lv 30 magic)
  if (runeSlotUnlocked(_state.player)) {
    const rid = _state.runeSlot;
    const def = rid ? ITEMS[rid] : null;
    const fx = rid ? RUNE_EFFECTS[rid] : null;
    const rs = document.createElement('div');
    rs.className = 'ch-slot ch-rune-slot ' + (rid ? 'filled' : 'empty');
    rs.innerHTML = rid
      ? `<div><b>${escapeHTML(def.name)}</b><div style="font-size:11px;color:var(--text-mid)">${escapeHTML(fx?.desc || '')}</div></div>
         <div class="stab">${def.icon}</div>`
      : `<div>Rune slot — click a rune below to bake an effect into the chart</div><div class="stab">✦</div>`;
    if (rid) rs.addEventListener('click', () => { _state.runeSlot = null; render(); });
    slotList.appendChild(rs);
  }
}

function renderInkBag() {
  // Show all stackable inks + (if rune slot unlocked) all runes. Click an
  // ink → drops into next empty ink slot. Click a rune → drops into the
  // rune slot.
  const inv = _state.player.inventory;
  const used = new Map();
  for (const id of _state.inkSlots) if (id) used.set(id, (used.get(id) || 0) + 1);
  if (_state.runeSlot) used.set(_state.runeSlot, (used.get(_state.runeSlot) || 0) + 1);

  inkList.innerHTML = '';
  let anyInk = false, anyRune = false;
  // Inks first
  for (let i = 0; i < inv.slots.length; i++) {
    const slot = inv.slots[i];
    if (!slot) continue;
    const def = ITEMS[slot.id];
    if (!def?.ink) continue;
    const remain = (slot.qty || 1) - (used.get(slot.id) || 0);
    if (remain <= 0) continue;
    anyInk = true;
    const btn = document.createElement('button');
    btn.className = 'ch-ink';
    btn.innerHTML = `<span class="ch-ink-icon">${def.icon || '·'}</span>
                     <span class="ch-ink-name">${escapeHTML(def.name)}</span>
                     <span class="ch-ink-qty">×${remain}</span>`;
    btn.addEventListener('click', () => placeInkInFirstEmpty(slot.id));
    inkList.appendChild(btn);
  }
  // Runes (only if slot is unlocked + player has any)
  if (runeSlotUnlocked(_state.player)) {
    for (let i = 0; i < inv.slots.length; i++) {
      const slot = inv.slots[i];
      if (!slot) continue;
      const def = ITEMS[slot.id];
      if (!def?.rune) continue;
      if (!RUNE_EFFECTS[slot.id]) continue;
      const remain = (slot.qty || 1) - (used.get(slot.id) || 0);
      if (remain <= 0) continue;
      anyRune = true;
      const btn = document.createElement('button');
      btn.className = 'ch-ink ch-rune';
      btn.innerHTML = `<span class="ch-ink-icon">${def.icon || '·'}</span>
                       <span class="ch-ink-name">${escapeHTML(def.name)}</span>
                       <span class="ch-ink-qty">×${remain}</span>`;
      btn.addEventListener('click', () => { _state.runeSlot = slot.id; render(); });
      inkList.appendChild(btn);
    }
  }
  if (!anyInk && !anyRune) {
    inkList.innerHTML = '<div class="ch-ink-empty">No inks in your bag. Mix some at the Inscribing Table first.</div>';
  }
}

function placeInkInFirstEmpty(itemId) {
  const t = _state.selectedTemplate;
  for (let i = 0; i < t.inkSlots; i++) {
    if (!_state.inkSlots[i]) { _state.inkSlots[i] = itemId; render(); return; }
  }
}

function renderPreview() {
  const t = _state.selectedTemplate;
  const inks = _state.inkSlots.slice(0, t.inkSlots).filter(Boolean);
  const cartoLv = _state.player.skills.carto.lv;

  previewBody.innerHTML = '';
  const intro = document.createElement('div');
  intro.innerHTML = `<b>${escapeHTML(t.name)}</b> · Tier ${t.tier} · ${t.affixSlots} affix slot${t.affixSlots !== 1 ? 's' : ''}`;
  previewBody.appendChild(intro);

  if (t.affixSlots === 0) {
    const note = document.createElement('div');
    note.style.cssText = 'margin-top:6px;color:var(--text-mid);font-size:11px;font-style:italic;';
    note.textContent = 'Snug — guaranteed clean run with no affixes.';
    previewBody.appendChild(note);
  } else {
    // Compute live weights and show top 5 most-likely affixes.
    const weights = computeWeights(t.tier, inks, cartoLv);
    const sorted = Object.entries(weights).sort((a, b) => b[1] - a[1]).slice(0, 5);
    const stab = inkStabilityBonus(inks);
    const list = document.createElement('div');
    list.className = 'ch-pred-list';
    for (const [affixId, pct] of sorted) {
      const aff = AFFIXES[affixId];
      if (!aff || pct < 0.1) continue;
      const stabilityPct = Math.min(95, Math.round((aff.baseStab || 50) + cartoLv * 0.6 + stab * 100));
      const row = document.createElement('div');
      row.className = 'ch-pred-row';
      row.innerHTML = `
        <div class="ch-pred-name">${escapeHTML(aff.name)}</div>
        <div class="ch-pred-bar"><div class="ch-pred-fill" style="width:${pct.toFixed(0)}%"></div></div>
        <div class="ch-pred-pct">${pct.toFixed(0)}%</div>
        <div class="ch-pred-stab">${stabilityPct}% good</div>
      `;
      list.appendChild(row);
    }
    previewBody.appendChild(list);
    const summary = document.createElement('div');
    summary.style.cssText = 'margin-top:6px;color:var(--text-mid);font-size:11px;font-style:italic;';
    summary.textContent = `${t.affixSlots} of these will land. Inks shape the odds — they don't guarantee.`;
    previewBody.appendChild(summary);
  }

  // Cost
  const cost = computeCost(t, inks);
  const costEl = document.createElement('div');
  costEl.style.cssText = 'margin-top:8px;font-size:12px;';
  costEl.innerHTML = '<b>Cost:</b> ' + Object.entries(cost).map(([k, n]) => {
    const have = _state.player.inventory.count(k);
    const ok = have >= n;
    return `<span style="color:${ok ? 'var(--text)' : 'var(--hp)'}">${n}× ${ITEMS[k]?.name || k} (${have})</span>`;
  }).join(', ');
  previewBody.appendChild(costEl);

  rollBtn.disabled = !canAfford(cost, _state.player.inventory);
}

function computeCost(template, inks) {
  const cost = { ...(template.baseCost || {}) };
  for (const inkId of inks) {
    cost[inkId] = (cost[inkId] || 0) + 1;
  }
  return cost;
}

function canAfford(cost, inv) {
  for (const [k, n] of Object.entries(cost)) {
    if (inv.count(k) < n) return false;
  }
  return true;
}

// ---- roll ----

rollBtn?.addEventListener('click', () => {
  if (!_state) return;
  const t = _state.selectedTemplate;
  const inks = _state.inkSlots.slice(0, t.inkSlots).filter(Boolean);
  const cartoLv = _state.player.skills.carto.lv;
  const inv = _state.player.inventory;

  // Spend ingredients (template base + inks)
  const cost = computeCost(t, inks);
  if (!canAfford(cost, inv)) return;
  for (const [k, n] of Object.entries(cost)) inv.remove(k, n);
  // Spend the rune in the rune slot (if any)
  if (_state.runeSlot) inv.remove(_state.runeSlot, 1);

  // Roll affixes weighted by inks
  const resolved = [];
  if (t.affixSlots > 0) {
    const weights = computeWeights(t.tier, inks, cartoLv);
    const stab = inkStabilityBonus(inks);
    const picks = rollAffixes(weights, t.affixSlots);
    for (const affixId of picks) {
      const aff = AFFIXES[affixId];
      if (!aff) continue;
      // Resolve good/bad twin via stability%, plus ink stability bonus.
      const baseStab = aff.baseStab || 50;
      const effective = Math.min(95, baseStab + cartoLv * 0.6 + stab * 100);
      const good = Math.random() * 100 < effective;
      resolved.push({ id: affixId, good, resolvedId: good ? affixId : `${affixId}__bad` });
    }
  }

  // Bake rune effect into the chart's extra data
  const runeEffect = _state.runeSlot ? RUNE_EFFECTS[_state.runeSlot]?.id : null;

  if (_onCommit) _onCommit({
    template: t,
    affixes: resolved,
    runeEffect,
  });

  closeCharting();
});

// Esc + click-out close
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && backdrop.classList.contains('open')) {
    closeCharting();
    e.stopPropagation();
  }
});
backdrop?.addEventListener('click', (e) => {
  if (e.target === backdrop) closeCharting();
});

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
