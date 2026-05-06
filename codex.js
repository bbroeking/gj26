// Bramblewood Codex
// ---------------------------------------------------------------------------
// One static page documenting every item, NPC, enemy, and 3D model in the
// project. Pulls live from src/data/items.js and src/data/npcs.js so updates
// to those files reflect here on reload. Enemies are catalogued inline (the
// spawn factories in src/game/enemies.js carry their stats inside JS, so a
// hand-rolled table is simpler than parsing source).
//
// The Models tab is a three.js viewer for every GLB in /models, with the
// option to toggle the same toon shading the live game uses. That's the
// quickest way to see whether a "white blob" silhouette is the model itself
// or the in-game shading washing the colors out.

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { ITEMS } from './src/data/items.js';
import { NPC_DEFS } from './src/data/npcs.js';
import { ABILITIES } from './src/game/abilities.js';
import { SKILL_MILESTONES } from './src/data/skill-milestones.js';
import { CARTO_UNLOCKS } from './src/ui/worldMap.js';
import { animateGLBKnight } from './src/anim/knight.js';
import { animateQuadruped } from './src/anim/quadruped.js';
import { phongifyMaterials } from './src/scene/characters.js';

// ---------------------------------------------------------------------------
// Tab switching
// ---------------------------------------------------------------------------
const tabsEl = document.getElementById('tabs');
tabsEl.addEventListener('click', (ev) => {
  const btn = ev.target.closest('button[data-tab]');
  if (!btn) return;
  const which = btn.dataset.tab;
  for (const b of tabsEl.querySelectorAll('button')) b.classList.toggle('on', b === btn);
  for (const p of document.querySelectorAll('section.tab-pane')) p.classList.toggle('on', p.dataset.tab === which);
  if (which === 'models') ensureViewerStarted();
  if (which === 'research') ensureResearchGalleryLoaded();
  if (which === 'skills') ensureSkillsLoaded();
  // Sync the global search box into the active tab's filter input so
  // the search persists visually when switching tabs.
  _syncGlobalSearchToActiveTab();
});

// Global search box — forwards keystrokes to the active tab's per-tab
// filter input so each tab's existing renderer handles the actual
// filtering (we don't have a unified document model to cross-search).
const globalSearchEl = document.getElementById('filter-global');
const TAB_FILTER_IDS = {
  items: 'filter-items', npcs: 'filter-npcs',
  enemies: 'filter-enemies', abilities: 'filter-abilities',
};
function activeTab() {
  const on = tabsEl.querySelector('button.on');
  return on ? on.dataset.tab : 'items';
}
function _syncGlobalSearchToActiveTab() {
  const id = TAB_FILTER_IDS[activeTab()];
  if (!id) return;
  const input = document.getElementById(id);
  if (!input) return;
  if (input.value !== globalSearchEl.value) {
    input.value = globalSearchEl.value;
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }
}
if (globalSearchEl) {
  globalSearchEl.addEventListener('input', _syncGlobalSearchToActiveTab);
}

// Badge counts — show how many entries each section has.
function refreshNavBadges() {
  const set = (id, n) => {
    const el = document.getElementById(id);
    if (el) el.textContent = String(n);
  };
  set('badge-items',     Object.keys(ITEMS || {}).length);
  set('badge-npcs',      document.querySelectorAll('#grid-npcs .card').length);
  set('badge-enemies',   document.querySelectorAll('#grid-enemies .card').length);
  set('badge-abilities', document.querySelectorAll('#grid-abilities .card').length);
}

// ---------------------------------------------------------------------------
// Items tab
// ---------------------------------------------------------------------------
function tierFromItem(it) {
  // Inferred tier label for filter / visual: prefer explicit `tier` field,
  // fall back to slot-aware heuristics.
  if (it.tier) return it.tier;
  if (it.slot) return 'gear';
  if (it.tool) return 'tool';
  if (it.food) return 'food';
  return 'misc';
}
function itemBonusLine(b) {
  if (!b) return '';
  const parts = [];
  if (b.atk) parts.push(`+${b.atk} atk`);
  if (b.str) parts.push(`+${b.str} str`);
  if (b.def) parts.push(`+${b.def} def`);
  return parts.join(' · ');
}
// Item icon paths — rendered PNGs live in assets/icons/<id>.png. We always
// try the <img> first; the onerror handler swaps in the emoji glyph when
// the file is missing, so coverage gaps degrade cleanly per-item.

// Concept-art portraits for NPCs + enemies. Keys match NPC_DEFS ids and
// ENEMIES `kind` strings. Files live in docs/concept-art/ at 1024×1024 — we
// scale them down via CSS in the .portrait class.
const NPC_PORTRAITS = {
  cook:      'npc-maud-pennycress.png',
  hod:       'npc-hod-tenter.png',
  quill:     'npc-quill.png',
  withering: 'npc-sir-withering.png',
  eldra:     'npc-eldra-lampwright.png',
  cricket:   'npc-cricket-letter-carrier.png',
  pell:      'npc-brother-pell.png',
  onywyn:    'npc-mother-onywyn.png',
};
const ENEMY_PORTRAITS = {
  cow:             'brindlecow.png',
  goblin:          'bramble-imp.png',
  boar:            'burrow-boar.png',
  hedgewolf:       'hedgewight.png',
  hedgemother:     'hedgemother.png',
  wolf_alpha:      'wolf-alpha.png',
  burrow_boar:     'burrow-boar.png',
  hedgewight:      'hedgewight.png',
  skitterling:     'enemy-skitterling.png',
  marsh_rat:       'enemy-marsh-rat.png',
  iron_gob:        'enemy-iron-gob.png',
  tusker_sow:      'enemy-tusker-sow.png',
  bramble_archer:  'enemy-bramble-archer.png',
  bramble_charger: 'enemy-bramble-charger.png',
  archer:          'enemy-bramble-archer.png',
  charger:         'enemy-bramble-charger.png',
};
function portraitHtml(filename) {
  if (!filename) return '';
  return `<img class="portrait" src="docs/concept-art/${filename}" alt="" loading="lazy" />`;
}

// Lore quotes pulled from docs/WORLD_LORE.md. Keys match NPC ids and enemy
// kinds. Each quote is short — <30 words — and shows in italic on the card.
const NPC_QUOTES = {
  cook:      '"We don\'t tame the brambles. We tend them. There\'s a difference."',
  hod:       'A forgotten war, on the wrong side. He has not used a weapon in twenty years, only hammers.',
  quill:     'Hod\'s late wife Bramwen was Quill\'s aunt. Raised partly at the smithy.',
  withering: 'His falcon is named Linnet. The villagers know there used to be another Linnet — a person, not a bird.',
  eldra:     'Has tea with Maud every Threnday. Burns extra wicks during the Quickening.',
  cricket:   'Sixteen, an orphan, lives in a loft above the cooperage. Sir Withering taught him to read.',
  pell:      'Keeps the Marked Pages — the cloister\'s slow index of which herbs are safe and which are not for use.',
  onywyn:    '"Brother Pell would prefer I sleep at night. I prefer Brother Pell prefer that."',
};
const ENEMY_QUOTES = {
  hedgemother:     '"Some kindnesses are too big to carry. So we plant them, and let the kindness be the place." — Mother Onywyn',
  goblin:          'Garden nuisance, not existential. Bites if cornered.',
  bramble_charger: 'Black-bristled, mid-charge. Sidestep the line — back-pedaling never works.',
  bramble_archer:  'Crow-like proportions. Perches above. Drawn shortbow of woven vine.',
  iron_gob:        'Patchwork iron plate, asymmetric pauldron. Slow but heavy.',
  tusker_sow:      'Bog-mud caked. The leaf-mantle isn\'t armor — it\'s something the bramble does to her, slowly, while she sleeps.',
  marsh_rat:       'Wet-furred, algae-streaked. Hates the road; loves the road\'s puddles.',
  skitterling:     'Knee-high. Glassy black eyes. The leaf-cap is real — they keep it on indoors and out.',
};

function iconHtml(id, it) {
  const fallback = escapeHtml(it.icon || '·');
  return `<img src="assets/icons/${escapeHtml(id)}.png" alt="${fallback}" class="icon-img"
    onerror="this.outerHTML=this.alt" />`;
}

// Item categories — each id is bucketed once, in priority order. Charts +
// lore + runes win over weapon/armor classification because their gameplay
// role is more specific. Order in this list also drives section-header
// order when the player is on the All chip.
const ITEM_CATEGORIES = [
  ['weapon',   'Weapons',   ([id, it]) => it.slot === 'weapon' || !!it.weaponClass],
  ['armor',    'Armor',     ([id, it]) => ['body','legs','head','shield','cloak','boots','gloves'].includes(it.slot)],
  ['tool',     'Tools',     ([id, it]) => !!it.tool],
  ['food',     'Food',      ([id, it]) => !!it.food],
  ['rune',     'Runes',     ([id])     => id.startsWith('rune_')],
  ['ink',      'Inks',      ([id])     => id.endsWith('_ink') || id === 'charcoal_bind' || id === 'lustrous_ink'],
  ['chart',    'Charts',    ([id, it]) => !!it.chart || id.startsWith('chart_')],
  ['parchment','Lore',      ([id, it]) => !!it.lore || id.startsWith('parchment_')],
  ['key',      'Keys',      ([id])     => id.endsWith('_key')],
  ['ore',      'Ores & Bars', ([id])   => id.endsWith('_ore') || id.endsWith('_bar') || id === 'ore_dust'],
  ['drop',     'Monster Drops', ([id]) => /(_pelt|_tusk|_strip|_crackling|tusker_|hedgewight|whicker|raw_|charred_)/.test(id)],
  ['misc',     'Sundries',  ()         => true],   // catch-all
];
function categorizeItem(entry) {
  for (const [key, label, test] of ITEM_CATEGORIES) {
    if (test(entry)) return key;
  }
  return 'misc';
}
let _itemFilterCategory = 'all';
function renderItems() {
  const grid = document.getElementById('grid-items');
  const count = document.getElementById('count-items');
  const filter = document.getElementById('filter-items').value.trim().toLowerCase();
  const entries = Object.entries(ITEMS).filter((entry) => {
    const [id, it] = entry;
    if (filter) {
      const blob = `${id} ${it.name || ''} ${it.slot || ''} ${it.tool || ''} ${it.desc || ''}`.toLowerCase();
      if (!blob.includes(filter)) return false;
    }
    if (_itemFilterCategory !== 'all') {
      return categorizeItem(entry) === _itemFilterCategory;
    }
    return true;
  });
  count.textContent = `${entries.length} of ${Object.keys(ITEMS).length}`;

  // Render the chip row (idempotent — wires once on first call).
  renderItemChips();

  // Group by category when on All; otherwise flat list (the chip already
  // tells the player what they're looking at).
  const cardHTML = (entry) => {
    const [id, it] = entry;
    const meta = [it.slot, it.tool, it.tier, it.food && `heals ${it.food.heal}`].filter(Boolean).join(' · ');
    const bonus = itemBonusLine(it.equipBonus);
    const req = it.reqSkill ? `req ${it.reqSkill} ${it.reqLevel ?? '?'}` : '';
    const stats = [bonus, req].filter(Boolean).join(' · ');
    const treeAffinity = abilityTreeAffinity(it);
    return `<div class="card">
      <h3>${iconHtml(id, it)}${escapeHtml(it.name || id)}</h3>
      <div class="meta">${escapeHtml(id)}${meta ? ' · ' + escapeHtml(meta) : ''}</div>
      ${stats ? `<div class="stats">${escapeHtml(stats)}</div>` : ''}
      <div class="desc">${escapeHtml(it.desc || '')}</div>
      ${treeAffinity ? `<div class="drops" style="margin-top:4px;color:#7a6a4a">pairs with: ${escapeHtml(treeAffinity)}</div>` : ''}
    </div>`;
  };

  if (entries.length === 0) {
    grid.innerHTML = '<div class="codex-empty">No items match this filter. Try clearing the search or picking another category.</div>';
    return;
  }
  if (_itemFilterCategory !== 'all') {
    grid.innerHTML = entries.map(cardHTML).join('');
    return;
  }
  // Sectioned layout. Group entries by their category, render a section
  // header before each non-empty bucket. Categories follow the declared order.
  // Within each section sort by reqLevel ascending so the player reads
  // bronze → iron → steel rather than alphabetic chaos. Items without a
  // reqLevel sort first (mostly cosmetic / stack items).
  const buckets = {};
  for (const e of entries) {
    const k = categorizeItem(e);
    (buckets[k] ||= []).push(e);
  }
  const sortByTier = (a, b) => {
    const ra = a[1].reqLevel ?? -1;
    const rb = b[1].reqLevel ?? -1;
    if (ra !== rb) return ra - rb;
    return (a[1].name || a[0]).localeCompare(b[1].name || b[0]);
  };
  let html = '';
  for (const [key, label] of ITEM_CATEGORIES) {
    const bucket = buckets[key];
    if (!bucket || bucket.length === 0) continue;
    bucket.sort(sortByTier);
    html += `<h2 class="codex-section">${escapeHtml(label)} <span class="codex-section-count">${bucket.length}</span></h2>`;
    html += `<div class="codex-section-grid">${bucket.map(cardHTML).join('')}</div>`;
  }
  grid.innerHTML = html;
}
function renderItemChips() {
  let row = document.getElementById('item-chips');
  if (!row) {
    // First call — inject the row above the grid.
    const pane = document.querySelector('.tab-pane[data-tab="items"]');
    const grid = document.getElementById('grid-items');
    row = document.createElement('div');
    row.id = 'item-chips';
    row.className = 'codex-chip-row';
    pane.insertBefore(row, grid);
  }
  // Build the chip list lazily each render so counts stay accurate (filter
  // text or category change recomputes everything).
  const allEntries = Object.entries(ITEMS);
  const counts = { all: allEntries.length };
  for (const e of allEntries) {
    const k = categorizeItem(e);
    counts[k] = (counts[k] || 0) + 1;
  }
  const chip = (key, label, n) => {
    const active = (_itemFilterCategory === key) ? ' codex-chip-active' : '';
    return `<button class="codex-chip${active}" data-cat="${key}">${escapeHtml(label)} <span class="codex-chip-count">${n}</span></button>`;
  };
  let html = chip('all', 'All', counts.all);
  for (const [key, label] of ITEM_CATEGORIES) {
    if (!counts[key]) continue;
    html += chip(key, label, counts[key]);
  }
  row.innerHTML = html;
  row.querySelectorAll('.codex-chip').forEach(btn => {
    btn.addEventListener('click', () => {
      _itemFilterCategory = btn.dataset.cat;
      renderItems();
    });
  });
}

/** Tell the player which ability tree this item pairs with, by reading
 *  equipBonus highest-stat. Weapons → Atk or Str, shields → Def, etc. */
function abilityTreeAffinity(it) {
  const eb = it.equipBonus;
  if (!eb) return null;
  const atk = eb.atk || 0, str = eb.str || 0, def = eb.def || 0;
  if (atk + str + def === 0) return null;
  if (atk >= str && atk >= def && atk > 0) return 'Atk tree (Cleave / Aimed Shot / Backstab)';
  if (str >= atk && str >= def && str > 0) return 'Str tree (Bull Rush / Sunder)';
  if (def >= atk && def >= str && def > 0) return 'Def tree (Shield Bash / Riposte / Defensive Stance)';
  return null;
}
document.getElementById('filter-items').addEventListener('input', renderItems);

// ---------------------------------------------------------------------------
// NPCs tab — pulls from NPC_DEFS, shows the first dialog line as flavor preview
// ---------------------------------------------------------------------------
function previewDialog(def) {
  // dialog(quest, state) — synth a stub state and call once. If it throws, return ''.
  const fakeQuest = { flags: {}, cookedBeefDelivered: 0, cowKilled: 0 };
  try {
    const lines = def.dialog?.(fakeQuest, 'offer');
    if (Array.isArray(lines) && lines.length) return lines[0];
  } catch { /* ignore */ }
  return '';
}
function renderNpcs() {
  const grid = document.getElementById('grid-npcs');
  const count = document.getElementById('count-npcs');
  const filter = document.getElementById('filter-npcs').value.trim().toLowerCase();
  const entries = Object.entries(NPC_DEFS).filter(([id, n]) => {
    if (!filter) return true;
    const blob = `${id} ${n.name || ''}`.toLowerCase();
    return blob.includes(filter);
  });
  count.textContent = `${entries.length} of ${Object.keys(NPC_DEFS).length}`;
  grid.innerHTML = entries.map(([id, n]) => {
    const preview = previewDialog(n);
    const portrait = portraitHtml(NPC_PORTRAITS[id]);
    const lore = NPC_QUOTES[id];
    const heightStr = (n.heightM != null) ? ` · ${n.heightM.toFixed(2)}m` : '';
    return `<div class="card has-portrait">
      ${portrait}
      <div class="card-body">
        <h3>${escapeHtml(n.name || id)}</h3>
        <div class="meta">id · ${escapeHtml(id)}${heightStr}</div>
        ${preview ? `<div class="desc"><em>"${escapeHtml(preview)}"</em></div>` : ''}
        ${lore ? `<div class="lore">${escapeHtml(lore)}</div>` : ''}
      </div>
    </div>`;
  }).join('');
}
document.getElementById('filter-npcs').addEventListener('input', renderNpcs);

// ---------------------------------------------------------------------------
// Enemies tab — hand-rolled catalog (kept in sync with src/game/enemies.js).
// If you add a new spawn factory, mirror its tier + stats here.
// ---------------------------------------------------------------------------
// heightM is shoulder/withers height for quadrupeds, total height for upright
// creatures. Used by the codex card and (eventually) the renderer's
// `_scaleGLBToHeight` so all in-world models share one ruler.
const ENEMIES = [
  { kind: 'cow',          name: 'Brindlecow',    tier: 'trivial', hp: 8,   atk: 1,  def: 1,  maxHit: 1, heightM: 1.40,
    drops: ['raw_brindle', 'wool_flank', 'coin'],
    desc: 'Passive dairy beast of the south pasture. Cross when bramble-imps stir them.',
    model: 'cow.glb' },
  { kind: 'chicken',      name: 'Pippin Hen',    tier: 'trivial', hp: 2,   atk: 1,  def: 1,  maxHit: 0, heightM: 0.45,
    drops: ['raw_pippin', 'downfeather'],
    desc: 'Pecks the village paths. Easy XP for the freshly-arrived.',
    model: 'chicken.glb' },
  { kind: 'hare',         name: 'Whicker Hare',  tier: 'trivial', hp: 4,   atk: 1,  def: 1,  maxHit: 1, heightM: 0.40,
    drops: ['hare_pelt', 'whickerhares_foot'],
    desc: 'Skittish meadow hare. Bolts on first hit.',
    model: 'hare.glb' },
  { kind: 'skitterling',  name: 'Skitterling',   tier: 'trivial', hp: 4,   atk: 2,  def: 1,  maxHit: 1, heightM: 0.50,
    drops: ['thorn_essence', 'hedge_ink', 'coin'],
    desc: 'Tiny thorn-fae. Hops in twos and threes — a whisper of the bramblewolds.',
    model: 'goblin_v2.glb',
    scope: 'briar_maze, delve' },
  { kind: 'marsh_rat',    name: 'Marsh Rat',     tier: 'easy',    hp: 8,   atk: 4,  def: 2,  maxHit: 2, heightM: 0.55,
    drops: ['rivermud', 'whickerhares_foot', 'coin'],
    desc: 'Bog-soaked rodent with sharp teeth. Darts in to bite, then retreats 3 tiles. Hard to corner.',
    model: 'hare_v2.glb',
    scope: 'sunken_hut' },
  { kind: 'goblin',       name: 'Goblin',        tier: 'easy',    hp: 12,  atk: 4,  def: 2,  maxHit: 2, heightM: 1.20,
    drops: ['rusty_dagger', 'coin'],
    desc: 'Camp scavengers in the southeast. Nasty in numbers.',
    model: 'goblin.glb' },
  { kind: 'archer',       name: 'Bramble Archer', tier: 'easy',   hp: 14,  atk: 6,  def: 2,  maxHit: 3, heightM: 1.70,
    drops: ['crow_feather', 'hedge_ink', 'coin'],
    desc: 'Falcon-perched at the back of the room. Fires telegraphed shots from 3-6 tiles. Dodge or step off the marked tile.',
    model: 'falcon_v2.glb' },
  { kind: 'bramble_imp',  name: 'Bramble-Imp',   tier: 'easy',    hp: 10,  atk: 4,  def: 2,  maxHit: 2, heightM: 0.95,
    drops: ['bramble_resin'],
    desc: 'Thorn-fae goading the dairy herd. Drops bramble resin.',
    model: 'bramble_imp.glb' },
  { kind: 'iron_gob',     name: 'Iron Gob',      tier: 'medium',  hp: 28,  atk: 7,  def: 6,  maxHit: 3, heightM: 1.55,
    drops: ['bogiron_ore', 'bogiron_bar', 'hedge_ink', 'coin'],
    desc: 'Goblin in scavenged plate. Heavy as a sack of nails. Slow but punishing.',
    model: 'goblin_v2.glb',
    scope: 'delve' },
  { kind: 'bramble_cap',  name: 'Bramble-Cap',   tier: 'medium',  hp: 35,  atk: 7,  def: 4,  maxHit: 3, heightM: 1.40,
    drops: ['bramble_resin', 'thorn_crown', 'coin'],
    desc: 'Champion variant in the goblin camp. Slower, harder hitting.',
    model: 'bramble_imp.glb' },
  { kind: 'boar',         name: 'Wild Boar',     tier: 'medium',  hp: 40,  atk: 8,  def: 5,  maxHit: 3, heightM: 1.05,
    drops: ['raw_boar', 'tusk', 'coin'],
    desc: 'Wood-edge brute. Charges if you stare too long.',
    model: 'boar.glb' },
  { kind: 'charger',      name: 'Bramble Charger', tier: 'medium', hp: 36,  atk: 10, def: 5,  maxHit: 5, heightM: 1.20,
    drops: ['raw_tusker', 'tusker_tusk', 'bogiron_ore', 'coin'],
    desc: 'Dark-tinted boar that paints a yellow line and DASHES. Sidestep out of the lane — back-pedaling stays in the line.',
    model: 'boar_v2.glb' },
  { kind: 'tusker_sow',   name: 'Tusker Sow',    tier: 'hard',    hp: 70,  atk: 12, def: 8,  maxHit: 4, heightM: 1.45,
    drops: ['raw_tusker', 'tusker_tusk', 'bogiron_bar', 'coin'],
    desc: 'A matriarch boar. Long 0.85s windup → 3×3 amber AoE slam. Step off the marked tile or eat the full hit.',
    model: 'boar_v2.glb',
    scope: 'sunken_hut' },
  { kind: 'hedge_wolf',   name: 'Hedgewolf',     tier: 'hard',    hp: 80,  atk: 14, def: 9,  maxHit: 5, heightM: 1.10,
    drops: ['raw_hedgewight', 'wightpelt', 'coalrose', 'bogiron_bar', 'coin'],
    desc: 'Twilight hunter of the deep wolds. Fast, mean — actually a hedgewight in motion.',
    model: 'hedgewight_v2.glb' },
  { kind: 'burrow_boar',  name: 'Burrow Boar',   tier: 'hard',    hp: 110, atk: 16, def: 10, maxHit: 5, heightM: 1.50,
    drops: ['raw_boar', 'tusk', 'coin'],
    desc: 'Bigger cousin of the wood boar, lives in earth-warrens.',
    model: 'burrow_boar.glb' },
  { kind: 'wolf_alpha',   name: 'Alpha Hedgewolf', tier: 'elite', hp: 220, atk: 22, def: 14, maxHit: 7, heightM: 1.35,
    drops: ['wolf_alpha_pelt', 'fang', 'coin'],
    desc: 'Pack leader. Calls in two hedgewolves at half-HP.',
    model: 'wolf_alpha.glb' },
  { kind: 'hedgemother',  name: 'The Hedgemother', tier: 'boss',  hp: 480, atk: 32, def: 22, maxHit: 10, heightM: 2.40,
    drops: ['hedgemother_heart', 'thorn_crown', 'coin'],
    desc: 'Bramblewood matriarch. Quest-locked spawn. Drops the Heart for the late game.',
    model: 'hedgemother.glb' },
];
// Tier order — drives section ordering on the Enemies tab.
const ENEMY_TIERS = [
  { key: 'trivial', label: 'Trivial' },
  { key: 'easy',    label: 'Easy' },
  { key: 'medium',  label: 'Medium' },
  { key: 'hard',    label: 'Hard' },
  { key: 'elite',   label: 'Elite' },
  { key: 'boss',    label: 'Boss' },
];

function renderEnemies() {
  const grid = document.getElementById('grid-enemies');
  const count = document.getElementById('count-enemies');
  const filter = document.getElementById('filter-enemies').value.trim().toLowerCase();
  const entries = ENEMIES.filter(e => {
    if (!filter) return true;
    const blob = `${e.kind} ${e.name} ${e.tier} ${e.desc}`.toLowerCase();
    return blob.includes(filter);
  });
  count.textContent = `${entries.length} of ${ENEMIES.length}`;

  if (entries.length === 0) {
    grid.innerHTML = '<div class="codex-empty">No enemies match this filter.</div>';
    return;
  }

  const cardHTML = (e) => {
    const portrait = portraitHtml(ENEMY_PORTRAITS[e.kind]);
    const lore = ENEMY_QUOTES[e.kind];
    return `<div class="card has-portrait tier-${e.tier}">
      ${portrait}
      <div class="card-body">
        <h3>${escapeHtml(e.name)}</h3>
        <div class="meta">${escapeHtml(e.kind)} · ${escapeHtml(e.tier)}-tier${e.heightM != null ? ` · ${e.heightM.toFixed(2)}m` : ''}</div>
        <div class="stats">
          <span>HP <b>${e.hp}</b></span>
          <span>ATK <b>${e.atk}</b></span>
          <span>DEF <b>${e.def}</b></span>
          <span>max-hit <b>${e.maxHit}</b></span>
        </div>
        <div class="desc">${escapeHtml(e.desc)}</div>
        ${lore ? `<div class="lore">${escapeHtml(lore)}</div>` : ''}
        <div class="drops">drops: ${e.drops.map(escapeHtml).join(', ')}</div>
        ${e.scope ? `<div class="drops" style="margin-top:4px;color:#7a6a4a">found in: ${escapeHtml(e.scope)}</div>` : ''}
      </div>
    </div>`;
  };

  // Section by tier — trivial → boss. Skip empty tiers. Within each tier
  // sort by HP ascending so the section reads from softest to hardest.
  const buckets = {};
  for (const e of entries) (buckets[e.tier] ||= []).push(e);
  for (const k of Object.keys(buckets)) buckets[k].sort((a, b) => a.hp - b.hp);

  let html = '';
  for (const { key, label } of ENEMY_TIERS) {
    const bucket = buckets[key];
    if (!bucket || bucket.length === 0) continue;
    html += `<h2 class="codex-section">${escapeHtml(label)} <span class="codex-section-count">${bucket.length}</span></h2>`;
    html += `<div class="codex-section-grid">${bucket.map(cardHTML).join('')}</div>`;
  }
  // Any tiers we didn't recognize fall through into a misc bucket so we
  // never silently drop entries.
  const known = new Set(ENEMY_TIERS.map(t => t.key));
  const misc = entries.filter(e => !known.has(e.tier));
  if (misc.length) {
    html += `<h2 class="codex-section">Other <span class="codex-section-count">${misc.length}</span></h2>`;
    html += `<div class="codex-section-grid">${misc.map(cardHTML).join('')}</div>`;
  }
  grid.innerHTML = html;
}
document.getElementById('filter-enemies').addEventListener('input', renderEnemies);

// ---------------------------------------------------------------------------
// Lore tab — discoverable Bramblewood legends, festivals, places.
// Source: docs/WORLD_LORE.md (the codex is the in-game surface for it).
// ---------------------------------------------------------------------------
const LORE = {
  festivals: [
    { name: 'The Quickening', when: 'First week of First-Spring',
      body: 'Bramble-imps grow bold. Pies vanish, washing-lines untie themselves, the cows are cross. Pell rings the cloister bell at sundown for seven nights running. Most player combat happens during a Quickening — or close enough.' },
    { name: "Lampwright's Eve", when: 'Three nights mid-Last-Spring',
      body: "Eldra's lanterns are lit at dusk village-wide. The night sky is deliberately dark between lit lanterns. Children stay home." },
    { name: 'Pieday', when: 'Last Sevenday of High-Summer',
      body: "Maud's pie contest at the well. Hod judges. Withering brings a cake every year and is gently disqualified." },
    { name: 'Last Light', when: 'Winter solstice',
      body: "The whole village gathers at Old Mother Well after dusk. Each family lights a candle. No one speaks until the candles burn down. Onywyn's bramble-mother once lit hers from inside the hedge." },
  ],
  legends: [
    { name: 'The Man at the Bottom of Old Mother Well', body: "Children claim there's a man asleep down there, breathing. Adults laugh. (There isn't. The village laughs because there is.)" },
    { name: 'The Seventh Cottage', body: "Old Wagon Road has a bend where you can see seven cottages along it. Walk it and count: there are six. Always six. Some say the seventh is for whoever was supposed to come and didn't." },
    { name: 'The Bramble Bargain', body: "Onywyn the elder did not bind herself for nothing. She bargained with the hedge: my thinking, slower than yours, in exchange for one winter. The winter was bought; the rest is what we live in. (Mother Onywyn does not confirm this. She does not deny it either.)" },
    { name: "Sallow's Tide", body: "The shipwreck at Sallow's End was killed by a tide that didn't happen. The tide-tables for that night are clean. The wreck is wedged into the cliff at an angle no real wave makes. Nobody has been down to it in fifty years." },
    { name: "Linnet's Vow", body: "Sir Withering's falcon is named Linnet. The villagers know there used to be another Linnet — a person, not a bird. Withering says the bird's name first. They are kind enough not to ask." },
  ],
  places: [
    { name: 'Trelliswick', meta: 'four-day ride, north-east', body: "Withering's homeland. He won't talk about it." },
    { name: "Sallow's End", meta: 'three hours\' walk, south-west', body: 'The tidal flats. The shipwreck. The cousins.' },
    { name: "Hag's Furrow", meta: 'wild hedge-line, east', body: "Where Onywyn forages. Cricket won't deliver there." },
    { name: 'The Marl', meta: 'far end of letter route', body: "The marshy basin Cricket hates. Letters take three days; he goes anyway." },
    { name: "Coopers' Hold (the place)", meta: 'abandoned farm', body: "The original Cooper family farm. The bank uses the family name out of respect." },
    { name: 'The Pale Veins', meta: 'Hod\'s ore quarries (delve scope)', body: "Underground passages that branch into other things. He stops his stories halfway through." },
  ],
  factions: [
    { name: 'Two old soldiers', body: "Hod and Sir Withering both fought wars. Not the same war. Withering's was named, Hod's was forgotten and probably wrong-sided. They drink at the well on Pieday and don't speak. The village finds this comforting." },
    { name: 'Two herb-tenders', body: "Brother Pell keeps the Marked Pages — the cloister's slow index of which herbs are safe. Mother Onywyn ignores it. They are unfailingly polite. Cricket carries weekly letters between them. The letters are mostly about weather." },
  ],
  founding: [
    { name: 'Bramblewood, the early years', body: "A hedge-trimmer's hamlet before it was a village. The first families came up from Sallow's End three or four winters after the tide receded — hedge-cutters and a wool-comber and one widowed cooper. They cleared a clearing in the old enclosure, built nine cottages, dug Old Mother Well, and began trimming the hedge instead of fighting it. The trimming has continued every spring since." },
    { name: 'The Hedgemother', body: "A long-ago hedge-witch named Onywyn — yes, the same name — bound herself into the bramble during the Hard Frost of the Long Winter to keep the village from freezing. She is not malevolent. She is not asleep. She is thinking very slowly, and when she thinks too hard the bramble wakes. Defeating her is not killing her — it's quieting her thinking for a season, which is enough." },
  ],
};

function renderLore() {
  const root = document.getElementById('lore-sections');
  const count = document.getElementById('count-lore');
  const filter = document.getElementById('filter-lore').value.trim().toLowerCase();
  const sections = [
    { key: 'founding',  title: 'Founding & the Hedgemother' },
    { key: 'festivals', title: 'Festivals' },
    { key: 'factions',  title: 'Quiet Tensions' },
    { key: 'legends',   title: 'Whispered Legends' },
    { key: 'places',    title: 'The Wolds Beyond' },
  ];
  let total = 0, shown = 0;
  const html = sections.map(s => {
    const items = (LORE[s.key] || []).filter(it => {
      total++;
      if (!filter) { shown++; return true; }
      const blob = `${it.name} ${it.meta || ''} ${it.body}`.toLowerCase();
      const match = blob.includes(filter);
      if (match) shown++;
      return match;
    });
    if (!items.length) return '';
    return `<div class="lore-section">
      <h2>${escapeHtml(s.title)}</h2>
      <div class="grid">
        ${items.map(it => `<div class="card lore-card">
          <h3>${escapeHtml(it.name)}</h3>
          ${(it.meta || it.when) ? `<div class="meta">${escapeHtml(it.meta || it.when)}</div>` : ''}
          <div class="body">${escapeHtml(it.body)}</div>
        </div>`).join('')}
      </div>
    </div>`;
  }).join('');
  root.innerHTML = html;
  count.textContent = `${shown} of ${total}`;
}
document.getElementById('filter-lore').addEventListener('input', renderLore);

// ---------------------------------------------------------------------------
// Abilities tab — pulls live from src/game/abilities.js so adding a new
// ability shows up in the codex automatically.
// ---------------------------------------------------------------------------
function renderAbilities() {
  const grid = document.getElementById('grid-abilities');
  const count = document.getElementById('count-abilities');
  const filter = document.getElementById('filter-abilities').value.trim().toLowerCase();
  const entries = Object.values(ABILITIES).filter(a => {
    if (!filter) return true;
    const blob = `${a.id} ${a.name} ${a.reqSkill} ${a.desc}`.toLowerCase();
    return blob.includes(filter);
  });
  // Sort by tree (atk → def → str → hp → magic) then by reqLevel
  const TREE_ORDER = { atk: 0, def: 1, str: 2, hp: 3, magic: 4 };
  entries.sort((a, b) => {
    const ta = TREE_ORDER[a.reqSkill] ?? 99;
    const tb = TREE_ORDER[b.reqSkill] ?? 99;
    if (ta !== tb) return ta - tb;
    return (a.reqLevel || 0) - (b.reqLevel || 0);
  });
  count.textContent = `${entries.length} of ${Object.keys(ABILITIES).length}`;
  grid.innerHTML = entries.map(a => `<div class="card tier-${a.reqSkill}">
    <h3><span class="icon">${escapeHtml(a.icon || '·')}</span>${escapeHtml(a.name)}</h3>
    <div class="meta">${escapeHtml(a.reqSkill.toUpperCase())} ${a.reqLevel} · ${a.cooldown}s CD · ${a.staminaCost ?? 0} stamina</div>
    <div class="desc">${escapeHtml(a.desc || '')}</div>
  </div>`).join('');
}
document.getElementById('filter-abilities').addEventListener('input', renderAbilities);

// ---------------------------------------------------------------------------
// Models tab — three.js viewer for every GLB in /models. Sidebar is grouped:
// characters / enemies / village / equipment / props. Click a name to load.
// ---------------------------------------------------------------------------
const MODEL_GROUPS = [
  { label: 'Walk lab — rig comparison', files: [
    '__walk_lab__',
    '_validation_soldier.glb',
    'npc_eldra_v2_s.glb',
  ]},
  { label: 'Eldra iterations — A/B/C/E/S variants', files: [
    'npc_eldra_v2.glb',
    'npc_eldra_v2_a.glb',
    'npc_eldra_v2_b.glb',
    'npc_eldra_v2_c.glb',
    'npc_eldra_v2_e.glb',
    'npc_eldra_v2_s.glb',
  ]},
  { label: 'NPC v2 — head-height template (NEW)', files: [
    'npc_eldra_v2.glb', 'npc_hod_v2.glb', 'npc_cricket_v2.glb',
    'npc_pell_v2.glb', 'npc_onywyn_v2.glb', 'npc_maud_v2.glb',
    'npc_withering_v2.glb', 'npc_quill_v2.glb',
  ]},
  { label: 'Archetype Iterations', files: [
    'druid_v1.glb', 'druid_v2_redesign.glb', 'druid_v3.glb', 'druid_dark.glb',
    'wanderer_v1.glb', 'wanderer_v2.glb', 'wanderer_v3.glb', 'wanderer_bard.glb', 'archer.glb',
    'knight_v3.glb', 'knight_v4.glb', 'knight_v5.glb', 'knight_gold.glb',
    'goblin_v2.glb', 'goblin_v3.glb', 'goblin_v4.glb',
    'bramble_imp_v3.glb',
    'chicken_v2.glb', 'hare_v2.glb', 'boar_v2.glb',
    'hedgewolf_v2.glb', 'falcon_v2.glb',
    'hedgemother_v2.glb', 'wolf_alpha_v2.glb',
    'hedgewight_v2.glb', 'burrow_boar_v2.glb',
    'memorial_lantern_v2.glb', 'falconer_perch_v2.glb', 'withered_bramble_v2.glb',
    'practice_dummy_v2.glb', 'chartmaker_stone_v2.glb', 'drying_rack_v2.glb',
    'signpost_v2.glb', 'oak_v4.glb', 'well_v2.glb',
    'cottage_v3.glb', 'bank_v2.glb', 'forge_v2.glb',
  ]},
  { label: 'Characters', files: [
    'knight.glb', 'knight_base.glb', 'knight_v2.glb', 'druid_v2.glb', 'wanderer_v2.glb',
    'cook.glb', 'npc_maud.glb', 'npc_hod.glb', 'npc_quill.glb', 'npc_withering.glb',
  ]},
  { label: 'Enemies / Animals', files: [
    'cow.glb', 'goblin.glb', 'chicken.glb', 'hare.glb', 'boar.glb',
    'bramble_imp.glb', 'bramble_imp_v2.glb',
    'hedgewight.glb', 'burrow_boar.glb', 'wolf_alpha.glb', 'hedgemother.glb',
  ]},
  { label: 'Village', files: [
    'cottage.glb', 'cottage_v2.glb', 'castle.glb', 'bank.glb', 'forge.glb',
    'well.glb', 'signpost.glb', 'oak.glb', 'practice_dummy.glb',
    'memorial_lantern.glb', 'drying_rack.glb', 'falconer_perch.glb',
    'chartmaker_stone.glb', 'withered_bramble.glb',
  ]},
  { label: 'Items / Quest', files: [
    'apprentices_hammer.glb', 'falcons_whistle.glb', 'healing_draught.glb',
    'pantry_stew.glb', 'thorn_crown.glb', 'bramble_resin.glb',
    'whickerhares_foot.glb', 'hods_anvil_token.glb',
  ]},
  { label: 'Equipment (worn pieces)', files: [
    'equipment/helmet_centurion.glb',
    'equipment/breastplate_olive.glb',
    'equipment/pauldrons_gold.glb',
    'equipment/belt_leather.glb',
    'equipment/tunic_skirt_cream.glb',
    'equipment/boots_brown.glb',
    'equipment/sword_short.glb',
    'equipment/shield_laurel.glb',
    'equipment/cape_red.glb',
  ]},
];

function buildModelList() {
  const aside = document.getElementById('model-list');
  aside.innerHTML = '';
  for (const group of MODEL_GROUPS) {
    const h = document.createElement('h4');
    h.textContent = group.label;
    aside.appendChild(h);
    for (const file of group.files) {
      const btn = document.createElement('button');
      btn.dataset.file = file;
      // Sentinel filenames (start with __) load a multi-model preset
      // instead of a single GLB. The walk lab loads three characters
      // side-by-side so their walks can be eyeballed live.
      if (file === '__walk_lab__') {
        btn.textContent = '▶ Walk lab — rigid · skinned · reference';
        btn.style.fontWeight = 'bold';
        btn.addEventListener('click', () => loadWalkLab(btn));
      } else {
        btn.textContent = file.replace(/\.glb$/, '').replace(/^equipment\//, '');
        btn.addEventListener('click', () => loadModel(file, btn));
      }
      aside.appendChild(btn);
    }
  }
}
buildModelList();

// --- viewer state ---
let viewerStarted = false;
let renderer, scene, camera, controls, currentModel = null;
let toonGradient = null;
let gridHelper = null;
let autoRotate = true;
// Shading mode for the Models viewer. 'toon' (cel, 4-band) is the
// shipping look; 'phong' is the tinyskies-style spike (flat shading + soft
// specular + Fresnel rim); 'pbr' leaves the GLB's original PBR materials
// untouched for raw asset inspection.
let shadingMode = 'toon';

function makeToonGradient() {
  // Same gradient as src/scene/characters.js: 4 steps, 110→255 floor.
  const colors = new Uint8Array([
    110, 110, 110, 255,
    175, 175, 175, 255,
    225, 225, 225, 255,
    255, 255, 255, 255,
  ]);
  const tex = new THREE.DataTexture(colors, 4, 1, THREE.RGBAFormat);
  tex.minFilter = THREE.NearestFilter;
  tex.magFilter = THREE.NearestFilter;
  tex.generateMipmaps = false;
  tex.needsUpdate = true;
  return tex;
}

function ensureViewerStarted() {
  if (viewerStarted) return;
  viewerStarted = true;

  toonGradient = makeToonGradient();

  const canvas = document.getElementById('model-canvas');
  renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1a1f17);

  camera = new THREE.PerspectiveCamera(35, 1, 0.05, 100);
  camera.position.set(2.2, 1.6, 2.6);

  // Match the in-game lighting roughly: hemisphere sky/ground + warm sun.
  scene.add(new THREE.HemisphereLight(0xcfe8ff, 0x3a2c20, 0.55));
  const sun = new THREE.DirectionalLight(0xfff5e0, 1.6);
  sun.position.set(2, 4, 2);
  scene.add(sun);

  controls = new OrbitControls(camera, canvas);
  controls.enableDamping = true;
  controls.target.set(0, 0.8, 0);

  gridHelper = new THREE.GridHelper(8, 8, 0x664a2a, 0x402a18);
  gridHelper.position.y = 0;
  scene.add(gridHelper);

  // toggles — shading is now a 3-way radio (toon / flat-phong / raw PBR).
  // Each radio reloads the active model so the swap shows immediately.
  const onShadingPicked = () => {
    if (document.getElementById('opt-flat-phong').checked) shadingMode = 'phong';
    else if (document.getElementById('opt-pbr').checked)   shadingMode = 'pbr';
    else                                                   shadingMode = 'toon';
    if (currentModel) reapplyShading(currentModel);
  };
  document.getElementById('opt-toon').addEventListener('change', onShadingPicked);
  document.getElementById('opt-flat-phong').addEventListener('change', onShadingPicked);
  document.getElementById('opt-pbr').addEventListener('change', onShadingPicked);
  document.getElementById('opt-spin').addEventListener('change', (ev) => {
    autoRotate = ev.target.checked;
  });
  document.getElementById('opt-grid').addEventListener('change', (ev) => {
    gridHelper.visible = ev.target.checked;
  });
  document.getElementById('opt-outline').addEventListener('change', (ev) => {
    useOutline = ev.target.checked;
    for (const rig of _activeRigs) {
      if (useOutline) addOutlineToModel(rig.model);
      else            removeOutlineFromModel(rig.model);
    }
  });

  // Expose for in-browser debugging.
  window.__codex = { scene, camera, renderer, _activeRigs };

  resizeViewer();
  window.addEventListener('resize', resizeViewer);
  tick();
}

// ----- ink outline (inverted-hull / backface-extruded) -----
// Reference-style storybook outlines without post-processing. For each
// mesh in the model, build a CLONED GEOMETRY whose vertices are pushed
// outward along their normals — this bakes the expansion into the bind
// pose so SkinnedMesh's bone-driven deformation preserves it (a uniform
// `mesh.scale = 1.04` does NOT survive skinning because the bone
// matrices override the mesh's local transform). Render that expanded
// geometry with a BackSide solid material so only the silhouette shows.
let useOutline = false;
const OUTLINE_COLOR  = 0x140a06;     // warm dark brown — feels inked, not pure black
const OUTLINE_OFFSET = 0.012;        // world-units pushed along each normal
const _outlineGeomCache = new WeakMap();   // src geometry → expanded clone

function expandedOutlineGeometry(srcGeom, offset) {
  const cached = _outlineGeomCache.get(srcGeom);
  if (cached) return cached;
  const out = srcGeom.clone();
  const pos = out.attributes.position;
  const norm = out.attributes.normal;
  if (norm) {
    const p = pos.array, n = norm.array;
    for (let i = 0; i < pos.count; i++) {
      p[i*3]   += n[i*3]   * offset;
      p[i*3+1] += n[i*3+1] * offset;
      p[i*3+2] += n[i*3+2] * offset;
    }
    pos.needsUpdate = true;
  }
  _outlineGeomCache.set(srcGeom, out);
  return out;
}

function addOutlineToModel(root) {
  const matSolid = new THREE.MeshBasicMaterial({
    color: OUTLINE_COLOR, side: THREE.BackSide,
  });
  const cloneList = [];
  root.traverse(o => {
    if (!o.isMesh) return;
    if (o.userData._isOutline) return;
    cloneList.push(o);
  });
  for (const o of cloneList) {
    const expanded = expandedOutlineGeometry(o.geometry, OUTLINE_OFFSET);
    let outline;
    if (o.isSkinnedMesh && o.skeleton) {
      outline = new THREE.SkinnedMesh(expanded, matSolid);
      outline.bind(o.skeleton, o.bindMatrix);
    } else {
      outline = new THREE.Mesh(expanded, matSolid);
    }
    outline.userData._isOutline = true;
    outline.name = (o.name || 'mesh') + '_outline';
    outline.scale.copy(o.scale);
    outline.position.copy(o.position);
    outline.rotation.copy(o.rotation);
    outline.castShadow = false;
    outline.receiveShadow = false;
    o.parent.add(outline);
  }
}
function removeOutlineFromModel(root) {
  const toRemove = [];
  root.traverse(o => { if (o.userData._isOutline) toRemove.push(o); });
  for (const o of toRemove) o.parent?.remove(o);
}

function resizeViewer() {
  if (!renderer) return;
  const canvas = renderer.domElement;
  const rect = canvas.parentElement.getBoundingClientRect();
  const w = Math.max(320, Math.floor(rect.width));
  const h = Math.max(240, Math.floor(rect.height));
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}

let _lastFrameMs = 0;
// _activeRigs holds every model currently in the viewer. Each entry is:
//   { model, file, animator?, entity?, mixer? }
// — animator+entity is the procedural path (rotates named groups);
// — mixer is the skinned path (drives bones from clip data).
// Single-model loads end up with a 1-element list; the walk lab loads 3.
const _activeRigs = [];

function tick() {
  if (!renderer) return;
  requestAnimationFrame(tick);
  const now = performance.now();
  const dt = _lastFrameMs ? Math.min(0.05, (now - _lastFrameMs) / 1000) : 0.016;
  _lastFrameMs = now;

  for (const rig of _activeRigs) {
    if (autoRotate && _activeRigs.length === 1) rig.model.rotation.y += 0.005;
    if (!animPlaying) continue;
    if (rig.mixer) rig.mixer.update(dt);
    else if (rig.animator) rig.animator(rig.model, rig.entity, dt);
  }

  controls.update();
  renderer.render(scene, camera);
}

let animPlaying = true;

const RIG_BIPED = ['Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'];
// Optional secondary joints — picked up only if the GLB has them. The
// animator handles missing ones gracefully (no-op via `if (p.Knee_L)`).
const RIG_BIPED_SECONDARY = ['Knee_L', 'Knee_R', 'Elbow_L', 'Elbow_R'];
const RIG_QUADRUPED = ['Body', 'Head', 'Tail', 'Leg_FL', 'Leg_FR', 'Leg_BL', 'Leg_BR'];

// Per-character animation config — mirrors src/scene/characters.js so the
// codex preview shows the same gait/lock the game does.
const NPC_ANIM_CONFIG = {
  'npc_eldra':     { lockArm: 'R',    cadenceMul: 0.7,  leanMul: 1.6 },
  'npc_cricket':   { lockArm: 'R',    cadenceMul: 1.2 },
  'npc_pell':      { lockArm: 'L',    cadenceMul: 0.85, leanMul: 1.2 },
  'npc_onywyn':    { lockArm: 'R',    cadenceMul: 0.7,  leanMul: 1.8 },
  'npc_hod':       { lockArm: 'R' },
  'npc_maud':      { lockArm: 'R',    cadenceMul: 0.9,  leanMul: 1.2 },
  'npc_quill':     { lockArm: 'both' },
  'npc_withering': { lockArm: 'L',    cadenceMul: 0.85, leanMul: 1.1 },
};

// Returns a rig record describing how to drive this model:
//   { model, file, kind, animator?, entity?, mixer? }
//   - kind 'skinned'    — gltf has a SkinnedMesh + animation clips → use mixer
//   - kind 'biped'      — named empty rig (Body/Arm_L/Knee_L/...) → procedural
//   - kind 'quadruped'  — quad named rig                          → procedural
//   - kind null         — static model, no animation
function buildRig(root, file, gltf) {
  // 1. Skinned-GLB detection — if the GLB ships an Armature + SkinnedMesh +
  //    at least one AnimationClip, drive it via THREE.AnimationMixer. This
  //    is the path skinned Eldra (variant 's') and the Soldier take.
  let hasSkinned = false;
  root.traverse(o => { if (o.isSkinnedMesh) hasSkinned = true; });
  if (hasSkinned && gltf?.animations?.length) {
    const clip = gltf.animations.find(c => /walk/i.test(c.name)) || gltf.animations[0];
    const mixer = new THREE.AnimationMixer(root);
    if (clip) mixer.clipAction(clip).play();
    return { model: root, file, kind: 'skinned', mixer, clipName: clip?.name };
  }

  // 2. Procedural — discover named rig empties on the loaded GLB.
  const found = {};
  root.traverse(o => {
    if (RIG_BIPED.includes(o.name)
        || RIG_BIPED_SECONDARY.includes(o.name)
        || RIG_QUADRUPED.includes(o.name)) {
      found[o.name] = o;
    }
  });
  root.userData.parts = found;
  const baseKey = (file || '').replace(/\.glb$/, '').replace(/_v\d+$/, '');
  const cfg = NPC_ANIM_CONFIG[baseKey];
  if (cfg) Object.assign(root.userData, cfg);
  const isBiped = RIG_BIPED.every(k => found[k]);
  const isQuadruped = RIG_QUADRUPED.every(k => found[k]);
  if (isBiped) {
    return {
      model: root, file, kind: 'biped',
      animator: animateGLBKnight,
      entity: { moving: true, running: false, attackPhase: null, hurtT: 0, combatStyle: 'accurate' },
    };
  }
  if (isQuadruped) {
    return {
      model: root, file, kind: 'quadruped',
      animator: animateQuadruped,
      entity: { moving: true, attackAnimT: 0 },
    };
  }
  return { model: root, file, kind: null };
}

function clearActive() {
  for (const rig of _activeRigs) {
    if (rig.mixer) rig.mixer.stopAllAction();
    if (rig.model.parent) scene.remove(rig.model);
  }
  _activeRigs.length = 0;
  currentModel = null;
}

const loader = new GLTFLoader();
const _modelCache = new Map();

async function loadModel(file, btn) {
  for (const b of document.querySelectorAll('#model-list button')) b.classList.toggle('on', b === btn);
  setInfo(`<b>${file}</b><br>loading…`);

  try {
    let gltf = _modelCache.get(file);
    if (!gltf) {
      gltf = await loader.loadAsync('models/' + file);
      _modelCache.set(file, gltf);
    }
    // Note: cloning a SkinnedMesh + Armature with .clone(true) historically
    // doesn't rebind weights to the cloned skeleton — but we don't clone
    // the skinned scene; we use it directly and track via _modelCache so
    // a re-click reuses the same gltf.scene. For non-skinned glbs we still
    // clone to avoid scaling/positioning mutations on the cached scene.
    const root = gltf.scene.clone(true);
    clearActive();
    applyShading(root);
    scene.add(root);
    const rig = buildRig(root, file, gltf);
    _activeRigs.push(rig);
    if (useOutline) addOutlineToModel(root);
    currentModel = root;
    frameModel(root);
    setInfo(modelStatsHtml(file, root, rig.kind, rig));
    setConceptOverlay(file);
  } catch (err) {
    setInfo(`<b>${file}</b><br><em style="color:#c94c4c">load failed: ${escapeHtml(err.message || String(err))}</em>`);
    console.warn('codex: model load failed', file, err);
  }
}

// ---- Walk lab — three rigs side by side ----
// rigid Eldra (procedural empty rig) · skinned Eldra (real armature, baked
// Walk) · Soldier (the canonical three.js skinned-walk reference). All
// three play continuously so the rig types can be eyeballed against each
// other without booting the full game.
const _WALK_LAB_ENTRIES = [
  { file: 'npc_eldra_v2_e.glb',         label: 'rigid Eldra',    x: -1.6, scale: 1.0  },
  { file: 'npc_eldra_v2_s.glb',         label: 'skinned Eldra',  x:  0.0, scale: 1.0  },
  { file: '_validation_soldier.glb',    label: 'Soldier (ref)',  x:  1.6, scale: 0.55 },
];

async function loadWalkLab(btn) {
  for (const b of document.querySelectorAll('#model-list button')) b.classList.toggle('on', b === btn);
  setInfo('<b>Walk lab</b><br>loading 3 models…');
  // Hide the concept overlay — there's no single concept to show.
  setConceptOverlay(null);

  try {
    clearActive();
    // Load all three GLBs in parallel for fast TTI on hot-cached files.
    const gltfs = await Promise.all(_WALK_LAB_ENTRIES.map(async e => {
      let g = _modelCache.get(e.file);
      if (!g) { g = await loader.loadAsync('models/' + e.file); _modelCache.set(e.file, g); }
      return { entry: e, gltf: g };
    }));

    const summaryRows = [];
    for (const { entry, gltf } of gltfs) {
      // For skinned scenes we use the gltf.scene directly (clone(true)
      // breaks SkinnedMesh→Skeleton bindings), otherwise we clone so
      // positioning doesn't mutate the cached scene.
      const hasSkin = (() => {
        let s = false; gltf.scene.traverse(o => { if (o.isSkinnedMesh) s = true; }); return s;
      })();
      const root = hasSkin ? gltf.scene : gltf.scene.clone(true);
      root.position.set(entry.x, 0, 0);
      root.scale.setScalar(entry.scale);
      applyShading(root);
      scene.add(root);

      const rig = buildRig(root, entry.file, gltf);
      _activeRigs.push(rig);
      if (useOutline) addOutlineToModel(root);
      summaryRows.push(`<div><b>${entry.label}</b> — ${rig.kind || 'static'}${rig.clipName ? ` · clip: ${rig.clipName}` : ''}</div>`);
    }

    currentModel = _activeRigs[1]?.model || _activeRigs[0]?.model;   // center model for framing/info
    if (currentModel) frameWalkLab();
    setInfo(`<b>Walk lab</b><br>${summaryRows.join('')}<br><em style="opacity:0.7">left → right · all play continuously · same toon material</em>`);
  } catch (err) {
    setInfo(`<b>Walk lab</b><br><em style="color:#c94c4c">load failed: ${escapeHtml(err.message || String(err))}</em>`);
    console.warn('codex: walk lab load failed', err);
  }
}

function frameWalkLab() {
  // Frame all three side-by-side characters: span ~3.5m across X, ~1.5m
  // tall, push the camera back to fit them all without OrbitControls
  // having to zoom out manually.
  const target = new THREE.Vector3(0, 0.85, 0);
  controls.target.copy(target);
  camera.position.set(0, 1.4, 5.0);
  camera.lookAt(target);
  controls.update();
}

// ---- concept-art silhouette overlay -----------------------------------
// Behind the rotating GLB at 30% opacity (when toggled on). Maps a model
// filename to the most-likely concept-art image via a list of suffix
// rewrites. Tries each candidate in order; first .png that loads wins.
let _conceptOn = false;
let _conceptCurrentSrc = null;

// NPC concept-art uses descriptive titles ("npc-eldra-lampwright.png")
// that don't match the glb's stem. Override these explicitly so the
// silhouette overlay lights up for the cast.
const _CONCEPT_OVERRIDES = {
  'npc_eldra.glb':     'npc-eldra-lampwright.png',
  'npc_cricket.glb':   'npc-cricket-letter-carrier.png',
  'npc_pell.glb':      'npc-brother-pell.png',
  'npc_onywyn.glb':    'npc-mother-onywyn.png',
  'npc_maud.glb':      'npc-maud-pennycress.png',
  'npc_hod.glb':       'npc-hod-tenter.png',
  'npc_withering.glb': 'npc-sir-withering.png',
};

function _conceptCandidatesFor(file) {
  if (_CONCEPT_OVERRIDES[file]) return [_CONCEPT_OVERRIDES[file]];
  // Versioned variants reuse the base GLB's override (e.g. npc_eldra_v2.glb
  // points at the same concept-art image as npc_eldra.glb).
  const stripVer = file.replace(/_v\d+\.glb$/, '.glb');
  if (stripVer !== file && _CONCEPT_OVERRIDES[stripVer]) return [_CONCEPT_OVERRIDES[stripVer]];
  const base = file.replace(/\.glb$/, '');
  const dashed   = base.replace(/_/g, '-');
  const noVer    = base.replace(/_v\d+$/, '').replace(/_/g, '-');
  const noNpcPfx = base.replace(/^npc_/, '').replace(/_v\d+$/, '').replace(/_/g, '-');
  return [...new Set([
    dashed + '.png',
    noVer + '.png',
    'enemy-' + noVer + '.png',
    noNpcPfx + '.png',
  ])];
}

function setConceptOverlay(file) {
  const img = document.getElementById('concept-overlay');
  if (!img) return;
  // Multi-model previews (walk lab) don't have a single concept-art image
  // to overlay — clear any existing src and bail.
  if (!file) {
    img.removeAttribute('src');
    _conceptCurrentSrc = null;
    return;
  }
  const tries = _conceptCandidatesFor(file);
  let i = 0;
  function tryNext() {
    if (i >= tries.length) {
      img.removeAttribute('src');
      _conceptCurrentSrc = null;
      return;
    }
    _conceptCurrentSrc = 'docs/concept-art/' + tries[i++];
    img.src = _conceptCurrentSrc;
  }
  img.onerror = tryNext;
  img.onload = () => {
    img.classList.toggle('on', _conceptOn);
  };
  // Don't show until a candidate resolves; classList stays off until onload.
  img.classList.remove('on');
  tryNext();
}

// Wire the controls checkbox once.
{
  const cb = document.getElementById('opt-concept');
  if (cb) {
    cb.addEventListener('change', () => {
      _conceptOn = cb.checked;
      const img = document.getElementById('concept-overlay');
      if (img && img.src) img.classList.toggle('on', _conceptOn);
    });
  }
}

// Dispatch on the current shading mode. PBR = leave the GLB untouched.
function applyShading(root) {
  if (shadingMode === 'phong') {
    // Cranked params for the spike: high specular + bright rim so the
    // tinyskies-style is unmistakable next to toon's flat cel banding.
    phongifyMaterials(root, {
      shininess: 60,
      rim: { color: 0xffeebb, intensity: 0.55, power: 2.6 },
    });
  } else if (shadingMode === 'toon') {
    toonifyForViewer(root);
  }
  // 'pbr' mode: do nothing — display the GLB's original PhysicallyBased mats.
}

function toonifyForViewer(root) {
  root.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const orig = Array.isArray(o.material) ? o.material : [o.material];
    const next = orig.map(m => {
      if (!m || m.isMeshToonMaterial) return m;
      if (m.isMeshBasicMaterial) return m;
      const tm = new THREE.MeshToonMaterial({
        color: m.color || new THREE.Color(0xffffff),
        map: m.map || null,
        gradientMap: toonGradient,
        side: m.side,
        transparent: !!m.transparent,
        opacity: m.opacity ?? 1,
        alphaTest: m.alphaTest ?? 0,
        vertexColors: m.vertexColors === true,
      });
      if (m.emissive && (m.emissive.r || m.emissive.g || m.emissive.b)) {
        tm.emissive = m.emissive.clone();
      }
      return tm;
    });
    o.material = Array.isArray(o.material) ? next : next[0];
  });
}

function reapplyShading(root) {
  // Quickest path: re-load from cache and re-traverse with the new toon flag.
  const file = [...document.querySelectorAll('#model-list button')].find(b => b.classList.contains('on'))?.dataset.file;
  if (!file) return;
  loadModel(file);
}

function frameModel(root) {
  // Compute bounding box, recentre on origin, and scale camera distance to fit.
  const box = new THREE.Box3().setFromObject(root);
  if (!isFinite(box.min.x)) return;
  const size = new THREE.Vector3(); box.getSize(size);
  const center = new THREE.Vector3(); box.getCenter(center);
  // Move the model so its feet sit on the grid (y=0)
  root.position.sub(new THREE.Vector3(center.x, box.min.y, center.z));

  // Distance derived from vertical FOV so the head never clips. The v2 NPCs
  // are taller than the original cubes (head_center_z bumped from 0.92 to
  // 1.00 of total height) and aux parts (coronets, hats, lanterns) extend
  // higher still, so we need a real fov-based fit, not a fixed multiplier.
  const fovRad = camera.fov * Math.PI / 180;
  const aspect = camera.aspect || 1;
  const fitH = size.y / (2 * Math.tan(fovRad / 2));
  const fitW = size.x / (2 * Math.tan(fovRad / 2) * aspect);
  const dist = Math.max(2.0, Math.max(fitH, fitW) * 1.4);   // 40% margin
  camera.position.set(dist * 0.6, size.y * 0.65, dist);
  controls.target.set(0, size.y * 0.5, 0);
}

function modelStatsHtml(file, root, rig, rigInfo) {
  let meshes = 0, mats = new Set(), tris = 0, namedParts = new Set();
  let bones = 0, skinnedMeshes = 0;
  root.traverse(o => {
    if (o.isSkinnedMesh) skinnedMeshes++;
    if (o.isBone) bones++;
    if (o.isMesh) {
      meshes++;
      const m = Array.isArray(o.material) ? o.material[0] : o.material;
      if (m) mats.add(m);
      const idx = o.geometry?.index;
      const pos = o.geometry?.attributes?.position;
      tris += idx ? idx.count / 3 : (pos ? pos.count / 3 : 0);
      if (o.name && /^(Body|Head|Arm_[LR]|Leg_[LR]|Leg_[FB][LR]|Tail|Neck|Wing_[LR])$/.test(o.name)) namedParts.add(o.name);
    } else if (o.name && /^(Body|Head|Arm_[LR]|Leg_[LR]|Leg_[FB][LR]|Tail|Neck|Wing_[LR])$/.test(o.name)) {
      namedParts.add(o.name);
    }
  });
  const parts = [...namedParts].sort().join(', ') || '<em>none</em>';
  let animLine, rigLine;
  if (rig === 'skinned') {
    animLine = `<span style="color:#7fc7e8">▶ skinned · clip "${rigInfo?.clipName || '?'}" via AnimationMixer</span>`;
    rigLine = `armature: ${bones} bones · ${skinnedMeshes} skinned meshes`;
  } else if (rig === 'biped') {
    animLine = '<span style="color:#7fb37f">▶ animated · walking biped (procedural empty rig)</span>';
    rigLine = `rig parts: ${parts}`;
  } else if (rig === 'quadruped') {
    animLine = '<span style="color:#7fb37f">▶ animated · walking quadruped (procedural empty rig)</span>';
    rigLine = `rig parts: ${parts}`;
  } else {
    animLine = '<span style="color:#888">— static (no rig)</span>';
    rigLine = `rig parts: ${parts}`;
  }
  return `<b>${escapeHtml(file)}</b><br>
    ${meshes} meshes · ${mats.size} materials · ${Math.round(tris)} tris<br>
    ${rigLine}<br>
    ${animLine}
    ${rig === 'biped' || rig === 'quadruped' ? `<br><label style="font-size:11px;cursor:pointer"><input type="checkbox" id="cc-anim-running" /> run</label>
            <label style="font-size:11px;cursor:pointer;margin-left:10px"><input type="checkbox" id="cc-anim-pause" /> pause</label>` : ''}`;
}

function setInfo(html) {
  const el = document.getElementById('model-info');
  el.innerHTML = html;
  // Run toggle drives every procedural rig in the active set — for the
  // single-model case that's just one entity; in the walk lab we'd
  // toggle multiple at once if any of them were procedural.
  const runCb = el.querySelector('#cc-anim-running');
  if (runCb) runCb.addEventListener('change', () => {
    for (const rig of _activeRigs) {
      if (rig.entity) rig.entity.running = runCb.checked;
    }
  });
  const pauseCb = el.querySelector('#cc-anim-pause');
  if (pauseCb) pauseCb.addEventListener('change', () => {
    animPlaying = !pauseCb.checked;
  });
}

// ---------------------------------------------------------------------------
// Skills tab — fetches docs/skills/<id>.md and renders via marked
// ---------------------------------------------------------------------------
// Post-consolidation (docs/design/skills-consolidation.md): 13 → 10 skills.
// Wilds absorbs forage + fish + wc; Earth absorbs mine + smith.
const SKILL_GROUPS = [
  { label: 'Combat',                  ids: ['atk', 'str', 'def', 'hp'] },
  { label: 'Gathering & Crafting',    ids: ['wilds', 'earth', 'cook'] },
  { label: 'Wayfinding',             ids: ['carto'] },
  { label: 'Companion',               ids: ['falconry'] },
  { label: 'Magic',                   ids: ['magic'] },
];
const SKILL_LABELS = {
  atk: 'Attack', str: 'Strength', def: 'Defence', hp: 'Hit Points',
  wilds: 'Wilds', earth: 'Earth', cook: 'Cooking',
  carto: 'Wayfinding', falconry: 'Falconry', magic: 'Magic',
};
let _skillsLoaded = false;
function ensureSkillsLoaded() {
  if (_skillsLoaded) return;
  _skillsLoaded = true;
  const list = document.getElementById('skill-list');
  if (!list) return;
  list.innerHTML = '';
  for (const group of SKILL_GROUPS) {
    const h = document.createElement('h5');
    h.textContent = group.label;
    list.appendChild(h);
    for (const id of group.ids) {
      const btn = document.createElement('button');
      btn.dataset.skill = id;
      btn.textContent = SKILL_LABELS[id] || id;
      btn.addEventListener('click', () => loadSkillDoc(id, btn));
      list.appendChild(btn);
    }
  }
  const count = document.getElementById('count-skills');
  if (count) count.textContent = `${Object.keys(SKILL_LABELS).length} skills`;
  const badge = document.getElementById('badge-skills');
  if (badge) badge.textContent = String(Object.keys(SKILL_LABELS).length);
  // Auto-load the first skill so the pane isn't empty.
  loadSkillDoc('atk', list.querySelector('button[data-skill="atk"]'));
}
// Build a level-by-level progression timeline for a skill. Pulls from
// SKILL_MILESTONES (canonical 3-5 beats per skill) and, for Wayfinding,
// the much richer CARTO_UNLOCKS (~30 entries across vision / recipes /
// affixes / templates / specialty / endgame tracks).
function _milestonesForSkill(id) {
  if (id === 'carto') {
    return CARTO_UNLOCKS.map(u => ({
      lv: u.lv,
      label: u.name,
      desc: u.text,
      track: u.track,
    }));
  }
  return (SKILL_MILESTONES[id] || []).map(m => ({
    lv: m.lv, label: m.label, desc: m.desc, track: null,
  }));
}

const _TRACK_BADGES = {
  vision:    { label: 'Vision',    color: '#3a6b8a' },
  recipes:   { label: 'Recipe',    color: '#7b4a9c' },
  affixes:   { label: 'Affix',     color: '#a8632a' },
  templates: { label: 'Template',  color: '#5a7a3a' },
  specialty: { label: 'Specialty', color: '#a8413a' },
  endgame:   { label: 'Endgame',   color: '#3a3a3a' },
};

function loadSkillDoc(id, btn) {
  for (const b of document.querySelectorAll('#skill-list button'))
    b.classList.toggle('on', b === btn);
  const content = document.getElementById('skill-content');
  if (!content) return;

  const name = SKILL_LABELS[id] || id;
  const rows = _milestonesForSkill(id);
  if (rows.length === 0) {
    content.innerHTML = `<h2 style="margin-top:0">${escapeHtml(name)}</h2>
      <em style="opacity:0.6">No milestones authored yet for this skill.</em>`;
    return;
  }

  // Sort by level so the timeline reads top-down 1 → 99.
  rows.sort((a, b) => a.lv - b.lv);
  const minLv = rows[0].lv;
  const maxLv = rows[rows.length - 1].lv;

  // Track filter chips (Wayfinding only — others have no track field).
  const tracks = Array.from(new Set(rows.map(r => r.track).filter(Boolean)));
  const chipRow = tracks.length > 0
    ? `<div class="skill-tracks">
         <button class="skill-track-chip on" data-track="all">All <span>${rows.length}</span></button>
         ${tracks.map(t => {
           const cnt = rows.filter(r => r.track === t).length;
           const cfg = _TRACK_BADGES[t] || { label: t, color: '#666' };
           return `<button class="skill-track-chip" data-track="${escapeHtml(t)}" style="--chip-color:${cfg.color}">${escapeHtml(cfg.label)} <span>${cnt}</span></button>`;
         }).join('')}
       </div>`
    : '';

  const rowHTML = (r) => {
    const trackBadge = r.track && _TRACK_BADGES[r.track]
      ? `<span class="milestone-track" style="--track-color:${_TRACK_BADGES[r.track].color}">${escapeHtml(_TRACK_BADGES[r.track].label)}</span>`
      : '';
    return `<div class="milestone-row" data-track="${escapeHtml(r.track || '')}">
      <div class="milestone-lv">Lv ${r.lv}</div>
      <div class="milestone-body">
        <div class="milestone-label">${escapeHtml(r.label)} ${trackBadge}</div>
        <div class="milestone-desc">${escapeHtml(r.desc || '')}</div>
      </div>
    </div>`;
  };

  content.innerHTML = `
    <h2 class="skill-doc-title">${escapeHtml(name)}</h2>
    <div class="skill-doc-meta">${rows.length} milestone${rows.length === 1 ? '' : 's'} · Lv ${minLv} → ${maxLv}</div>
    ${chipRow}
    <div class="milestone-timeline">${rows.map(rowHTML).join('')}</div>
  `;

  // Wire track chips (Wayfinding only).
  if (tracks.length > 0) {
    content.querySelectorAll('.skill-track-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const t = chip.dataset.track;
        content.querySelectorAll('.skill-track-chip').forEach(c => c.classList.toggle('on', c === chip));
        content.querySelectorAll('.milestone-row').forEach(row => {
          row.style.display = (t === 'all' || row.dataset.track === t) ? '' : 'none';
        });
      });
    });
  }
}

// ---------------------------------------------------------------------------
// Research Gallery — Eldra autoresearch loop
// ---------------------------------------------------------------------------
// Reads docs/research/eldra/manifest.json and renders one card per
// experiment: thumbnail, title, hypothesis, params chips, parent link,
// and a "Load in walk lab" button that drops the variant's GLB into the
// Models-tab viewer next to the stable rigid Eldra and Soldier reference.
let _researchLoaded = false;
async function ensureResearchGalleryLoaded() {
  if (_researchLoaded) return;
  _researchLoaded = true;
  const grid = document.getElementById('research-grid');
  const count = document.getElementById('count-research');
  grid.innerHTML = '<em style="opacity:0.6">loading manifest…</em>';
  try {
    const res = await fetch('docs/research/eldra/manifest.json?cb=' + Date.now());
    const manifest = await res.json();
    if (count) count.textContent = `${manifest.count} runs`;
    grid.innerHTML = '';
    for (const run of manifest.runs) renderResearchCard(grid, run);
  } catch (err) {
    grid.innerHTML = `<em style="color:#c94c4c">manifest load failed: ${escapeHtml(err.message)}</em>`;
    console.warn('research: manifest load failed', err);
  }
}

function renderResearchCard(grid, run) {
  const card = document.createElement('div');
  card.style.cssText = 'background:var(--paper, #f4eecf);color:var(--ink, #2a1d12);padding:12px;border-radius:6px;display:flex;flex-direction:column;gap:8px;font-size:13px;line-height:1.4';
  const paramChips = Object.entries(run.params || {})
    .map(([k, v]) => `<span style="background:rgba(0,0,0,0.08);padding:2px 6px;border-radius:3px;font-family:monospace;font-size:11px">${escapeHtml(k.replace(/^ELDRA_/, ''))}=${escapeHtml(v)}</span>`)
    .join(' ');
  const parent = run.parent
    ? `<span style="opacity:0.6;font-size:11px">parent: ${escapeHtml(run.parent)}</span>`
    : `<span style="opacity:0.6;font-size:11px">root</span>`;
  const thumbSrc = run.outputs?.thumb || `docs/research/eldra/runs/${run.id}/thumb.png`;
  const glbPath = run.outputs?.glb || `models/npc_eldra_v2_${run.id}.glb`;
  card.innerHTML = `
    <div style="display:flex;align-items:flex-start;gap:10px">
      <img src="${escapeHtml(thumbSrc)}" alt="${escapeHtml(run.id)}"
           style="width:120px;height:auto;background:#1a1f17;border-radius:4px;cursor:pointer"
           data-glb="${escapeHtml(glbPath)}" data-run="${escapeHtml(run.id)}">
      <div style="flex:1;min-width:0">
        <div style="font-family:monospace;font-size:11px;opacity:0.6">${escapeHtml(run.id)}</div>
        <div style="font-weight:bold;margin:2px 0">${escapeHtml(run.title || run.id)}</div>
        ${parent}
      </div>
    </div>
    <div style="font-size:12px;opacity:0.85">${escapeHtml(run.hypothesis || '')}</div>
    <div style="display:flex;flex-wrap:wrap;gap:4px">${paramChips}</div>
    <div style="display:flex;gap:6px;align-items:center;font-size:11px;opacity:0.75">
      <button data-load-run="${escapeHtml(run.id)}" data-glb="${escapeHtml(glbPath)}"
              style="background:rgba(0,0,0,0.08);border:none;padding:4px 8px;border-radius:3px;font-size:11px;cursor:pointer">
        ▶ Load in viewer
      </button>
      ${run.rating ? `<span style="color:#c98000">★ ${escapeHtml(run.rating)}</span>` : ''}
      ${run.notes ? `<span style="opacity:0.6">— ${escapeHtml(run.notes.slice(0, 60))}${run.notes.length > 60 ? '…' : ''}</span>` : ''}
    </div>
  `;
  grid.appendChild(card);
  // Wire click handlers — both the thumbnail and the explicit button
  // drop the variant's GLB into the Models-tab viewer.
  const onLoad = () => loadResearchRun(run);
  card.querySelector('img').addEventListener('click', onLoad);
  card.querySelector('button[data-load-run]').addEventListener('click', onLoad);
}

async function loadResearchRun(run) {
  // Switch to the Models tab.
  const modelsBtn = tabsEl.querySelector('button[data-tab="models"]');
  if (modelsBtn) modelsBtn.click();
  // Load the GLB by its bare filename (loadModel prefixes 'models/').
  const glbPath = run.outputs?.glb || `models/npc_eldra_v2_${run.id}.glb`;
  const file = glbPath.replace(/^models\//, '');
  await loadModel(file, null);
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------
function escapeHtml(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// Initial paints
renderItems();
renderNpcs();
renderEnemies();
renderAbilities();
renderLore();
refreshNavBadges();
