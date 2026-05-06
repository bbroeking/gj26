// Wayfinding Workshop — the unified status-and-launcher panel for the
// keystone progression skill. Replaces the chartmaker-stone 4-choice
// dialog and the scattered "open this modal, then that one" flow with
// a single surface that shows:
//
//   - carto level + XP bar + next milestone
//   - materials, inks, runes, charts (live counts)
//   - 4 action launchers: Mix Inks / Press Runes / Inscribe Chart / Field Journal
//   - sketches-this-session counter
//
// The 4 action buttons open the existing modals; closing one of those
// modals reopens the workshop (breadcrumb pattern) — the workshop is
// the single source of "where am I in the carto flow."
//
// Public API:
//   showWayfindingWorkshop(player, log, deps)
//     deps = { onChange, openInscribingTable, openCharting, openPedestal, openFieldJournal }
//   closeWayfindingWorkshop()
//   isWayfindingWorkshopOpen()
//   noteSketchThisSession(name)  — called from sketch handler

import { ITEMS } from '../data/items.js';
import { xpForLevel } from '../data/config.js';
import { nextMilestone } from '../data/skill-milestones.js';
import { INK_RECIPES } from '../data/inkRecipes.js';
import { summarizeMaterials, recipeStatus, essenceLabel } from '../game/materials.js';

let _state = null;
let _sketchesThisSession = [];   // array of { name, t } for live counter

const RUNE_IDS = [
  'rune_air', 'rune_water', 'rune_earth', 'rune_fire',
  'rune_mind', 'rune_body', 'rune_chaos',
];
const CHART_IDS = [
  'chart_blank', 'chart_snug', 'chart_tier_1',
  'chart_hollow', 'chart_briar_maze',
  'chart_sunken_hut', 'chart_delve',
];

export function isWayfindingWorkshopOpen() { return !!_state; }

export function showWayfindingWorkshop(player, log, deps = {}) {
  const backdrop = document.getElementById('cartography-workshop-backdrop');
  if (!backdrop) return;
  _state = { player, log, deps, target: null };
  bindOnce();
  render();
  backdrop.classList.add('open');
}

/** Shopping-list mode — call from another modal (e.g. the Materials
 *  Browser when the player clicks a recipe) to set the workshop's
 *  next-target. The Materials section then highlights everything the
 *  recipe wants with checks. Pass null to clear. */
export function setWorkshopTarget(recipe) {
  if (!_state) return;
  _state.target = recipe;
  render();
}

export function closeWayfindingWorkshop() {
  document.getElementById('cartography-workshop-backdrop')?.classList.remove('open');
  _state = null;
}

export function noteSketchThisSession(name) {
  _sketchesThisSession.push({ name, t: Date.now() });
  // If the workshop happens to be open while sketching (unlikely), refresh.
  if (_state) renderSketches();
}

let _bound = false;
function bindOnce() {
  if (_bound) return;
  _bound = true;
  document.getElementById('cw-close')?.addEventListener('click', closeWayfindingWorkshop);
  document.getElementById('cartography-workshop-backdrop')?.addEventListener('click', e => {
    if (e.target.id === 'cartography-workshop-backdrop') closeWayfindingWorkshop();
  });
  document.getElementById('cw-act-ink')?.addEventListener('click', () => launch('ink'));
  document.getElementById('cw-act-rune')?.addEventListener('click', () => launch('rune'));
  document.getElementById('cw-act-chart')?.addEventListener('click', () => launch('chart'));
  document.getElementById('cw-act-journal')?.addEventListener('click', () => launch('journal'));
  document.getElementById('cw-atlas-link')?.addEventListener('click', () => launch('atlas'));
  document.getElementById('cw-materials-browse')?.addEventListener('click', () => launch('browse'));
  document.getElementById('cw-target-clear')?.addEventListener('click', () => {
    if (!_state) return;
    _state.target = null;
    render();
  });
}

function launch(which) {
  if (!_state) return;
  const { deps } = _state;
  // Hide the workshop without clearing _state — the modal close handlers
  // call reopenIfWasOpen() which checks _state.
  document.getElementById('cartography-workshop-backdrop')?.classList.remove('open');
  if (which === 'ink' && deps.openInscribingTable)   deps.openInscribingTable();
  else if (which === 'rune' && deps.openPedestal)    deps.openPedestal();
  else if (which === 'chart' && deps.openCharting)   deps.openCharting();
  else if (which === 'journal' && deps.openFieldJournal) deps.openFieldJournal();
  else if (which === 'atlas' && deps.openAtlas)      deps.openAtlas();
  else if (which === 'browse' && deps.openMaterialsBrowser) deps.openMaterialsBrowser();
}

// Called by main.js when one of the launched modals closes — if the
// workshop was its parent, reopen it so the player lands back here.
export function reopenIfWasOpen() {
  if (!_state) return;
  const backdrop = document.getElementById('cartography-workshop-backdrop');
  if (!backdrop) return;
  // Already visible? skip.
  if (backdrop.classList.contains('open')) return;
  render();
  backdrop.classList.add('open');
}

// ---- render ----

function render() {
  if (!_state) return;
  renderHeader();
  renderMaterials();
  renderInks();
  renderRunes();
  renderCharts();
  renderSketches();
  // Show/hide the "× clear target" button based on shopping-list mode.
  const clearBtn = document.getElementById('cw-target-clear');
  if (clearBtn) clearBtn.style.display = _state.target ? '' : 'none';
}

function renderHeader() {
  const player = _state.player;
  const carto = player.skills.carto || { lv: 1, xp: 0 };
  const lv = carto.lv;
  const cur = xpForLevel(lv);
  const nxt = xpForLevel(lv + 1);
  const into = Math.max(0, carto.xp - cur);
  const span = Math.max(1, nxt - cur);
  const pct  = Math.max(0, Math.min(100, (into / span) * 100));
  const lvEl = document.getElementById('cw-lv');
  const xpEl = document.getElementById('cw-xp');
  const barEl = document.getElementById('cw-xp-fill');
  const msEl = document.getElementById('cw-milestone');
  if (lvEl) lvEl.textContent = `Lv ${lv}`;
  if (xpEl) xpEl.textContent = `${into} / ${span} XP`;
  if (barEl) barEl.style.width = `${pct.toFixed(1)}%`;
  if (msEl) {
    const m = nextMilestone('carto', lv);
    msEl.textContent = m
      ? `Next: Lv ${m.lv} — ${m.label}: ${m.desc}`
      : 'Every milestone earned. The chart is yours.';
  }
}

function renderMaterials() {
  const root = document.getElementById('cw-materials');
  if (!root) return;
  const summary = summarizeMaterials(_state.player, ITEMS, INK_RECIPES);
  const target = _state.target;     // optional recipe being shopping-list'd

  // Pre-compute "needed" set if we're in shopping mode — pill rendering
  // adds a check/cross next to each item the recipe wants.
  let needSet = null;
  if (target) {
    needSet = new Set();
    for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
      const want = target.pattern[y][x];
      if (want?.id) needSet.add(want.id);
    }
    if (target.vessel) needSet.add(target.vessel);
  }

  // Build essence sections — only render groups that have at least one item.
  const sections = [];
  for (const ess of summary.essenceOrder) {
    const items = summary.byEssence[ess];
    if (!items?.length) continue;
    if (ess === 'ink') continue;     // inks have their own section in the workshop
    const pills = items.map(m => pillFor(m, needSet)).join('');
    sections.push(`<div class="cw-mat-group">
      <div class="cw-mat-group-title">${escapeHTML(essenceLabel(ess))}</div>
      <div class="cw-pill-list">${pills}</div>
    </div>`);
  }

  // Vessels group (only if any in bag)
  if (summary.vessels.length) {
    const pills = summary.vessels.map(v => pillFor({
      id: v.id, qty: v.qty, def: v.def,
    }, needSet)).join('');
    sections.push(`<div class="cw-mat-group">
      <div class="cw-mat-group-title">Vessels</div>
      <div class="cw-pill-list">${pills}</div>
    </div>`);
  }

  // Status hint — what's craftable RIGHT NOW + what's almost ready.
  const hints = [];
  if (target) {
    const st = recipeStatus(target, _state.player.inventory, ITEMS);
    if (st.canCraft) {
      hints.push(`<span class="cw-hint cw-hint-good">✓ Ready to mix ${escapeHTML(target.name)}</span>`);
    } else {
      hints.push(`<span class="cw-hint cw-hint-warn">Need: ${st.missing.map(m => escapeHTML(m.label)).join(', ')}</span>`);
    }
  } else {
    if (summary.canMix.length) {
      const names = summary.canMix.slice(0, 3).map(c => escapeHTML(c.recipe.name)).join(', ');
      const more = summary.canMix.length > 3 ? ` (+${summary.canMix.length - 3})` : '';
      hints.push(`<span class="cw-hint cw-hint-good">✓ Can mix: ${names}${more}</span>`);
    }
    if (summary.almostCan.length) {
      const top = summary.almostCan[0];
      const need = top.status.missing.map(m => escapeHTML(m.label)).join(', ');
      hints.push(`<span class="cw-hint cw-hint-warn">Almost ${escapeHTML(top.recipe.name)}: short ${need}</span>`);
    }
  }
  const hintHtml = hints.length
    ? `<div class="cw-mat-hints">${hints.join('')}</div>`
    : '';

  if (!sections.length) {
    root.innerHTML = '<div class="cw-empty">No raw materials yet — chop, mine, or forage to begin.</div>';
    return;
  }
  root.innerHTML = sections.join('') + hintHtml;
}

function pillFor(m, needSet) {
  const def = m.def || ITEMS[m.id];
  if (!def) return '';
  const need = needSet && needSet.has(m.id);
  const cls = need ? 'cw-pill cw-pill-needed' : 'cw-pill';
  const tick = need ? '<span class="cw-pill-tick">✓</span>' : '';
  return `<div class="${cls}">${tick}<span class="cw-pill-icon">${def.icon || '·'}</span>
    <span class="cw-pill-name">${escapeHTML(def.name)}</span>
    <span class="cw-pill-qty">×${m.qty}</span></div>`;
}

function renderInks() {
  const root = document.getElementById('cw-inks');
  if (!root) return;
  const inv = _state.player.inventory;
  const known = _state.player.knownRecipes || new Set();
  const rows = [];
  for (const recipe of INK_RECIPES) {
    const qty = inv.count(recipe.output.id);
    const isKnown = known.has(recipe.id);
    if (qty <= 0 && !isKnown) continue;
    const def = ITEMS[recipe.output.id];
    if (!def) continue;
    const cls = qty > 0 ? 'cw-pill' : 'cw-pill cw-pill-empty';
    rows.push(`<div class="${cls}"><span class="cw-pill-icon">${def.icon || '·'}</span>
      <span class="cw-pill-name">${escapeHTML(def.name)}</span>
      <span class="cw-pill-qty">×${qty}</span></div>`);
  }
  root.innerHTML = rows.length ? rows.join('') : '<div class="cw-empty">No inks. Mix some at the table to get started.</div>';
}

function renderRunes() {
  const root = document.getElementById('cw-runes');
  if (!root) return;
  const inv = _state.player.inventory;
  const rows = [];
  for (const id of RUNE_IDS) {
    const def = ITEMS[id];
    if (!def) continue;
    const qty = inv.count(id);
    if (qty <= 0) continue;
    rows.push(`<div class="cw-pill"><span class="cw-pill-icon">${def.icon || '✦'}</span>
      <span class="cw-pill-name">${escapeHTML(def.name)}</span>
      <span class="cw-pill-qty">×${qty}</span></div>`);
  }
  root.innerHTML = rows.length ? rows.join('') : '<div class="cw-empty">No runes. Press an ink onto a Rune Stone at the Pedestal.</div>';
}

function renderCharts() {
  const root = document.getElementById('cw-charts');
  if (!root) return;
  const inv = _state.player.inventory;
  const rows = [];
  for (const id of CHART_IDS) {
    const def = ITEMS[id];
    if (!def) continue;
    const qty = inv.count(id);
    if (qty <= 0) continue;
    rows.push(`<div class="cw-pill"><span class="cw-pill-icon">${def.icon || '▤'}</span>
      <span class="cw-pill-name">${escapeHTML(def.name)}</span>
      <span class="cw-pill-qty">×${qty}</span></div>`);
  }
  root.innerHTML = rows.length ? rows.join('') : '<div class="cw-empty">No charts yet. Inscribe one once you have ink.</div>';
}

function renderSketches() {
  const root = document.getElementById('cw-sketches');
  if (!root) return;
  const n = _sketchesThisSession.length;
  if (n === 0) {
    root.textContent = 'No sketches this session. Press N near a feature to add one.';
    return;
  }
  // Show count + last 3 names so the player sees what they captured.
  const tail = _sketchesThisSession.slice(-3).map(s => s.name).join(', ');
  root.textContent = `Sketches this session: ${n} · ${tail}`;
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
