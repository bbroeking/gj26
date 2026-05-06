// Field Journal — the cartographer's personal Pokédex of sketches.
// Bound to the 5th HUD tool button (📓). Reads player.sketches[].
//
// Public API:
//   showFieldJournal(player)
//   closeFieldJournal()
//   isFieldJournalOpen()

import { nextUnlock } from './worldMap.js';

let _open = false;

const CATEGORY_ORDER = ['vista', 'creature', 'curiosity', 'settlement', 'flora', 'terrain'];
const CATEGORY_LABEL = {
  vista:      'Vistas',
  creature:   'Creatures',
  curiosity:  'Curiosities',
  settlement: 'Settlements',
  flora:      'Flora',
  terrain:    'Terrain',
};
const CATEGORY_GLYPH = {
  vista:      '🏔',
  creature:   '🐺',
  curiosity:  '✨',
  settlement: '🏠',
  flora:      '🌿',
  terrain:    '⛰',
};

export function isFieldJournalOpen() { return _open; }

export function closeFieldJournal() {
  document.getElementById('field-journal-backdrop')?.classList.remove('open');
  _open = false;
}

export function showFieldJournal(player) {
  const backdrop = document.getElementById('field-journal-backdrop');
  if (!backdrop) return;
  const body = document.getElementById('fj-body');
  const totalEl = document.getElementById('fj-total');
  const categoriesEl = document.getElementById('fj-cat-summary');
  if (!body || !totalEl) return;

  const sketches = player.sketches || [];
  const byCat = new Map();
  for (const s of sketches) {
    if (!byCat.has(s.category)) byCat.set(s.category, []);
    byCat.get(s.category).push(s);
  }

  totalEl.textContent = String(sketches.length);
  // Next-unlock footer — same data the world map uses.
  const lvEl = document.getElementById('fj-carto-lv');
  const nextEl = document.getElementById('fj-next-unlock');
  if (lvEl) lvEl.textContent = String(player.skills?.carto?.lv || 1);
  if (nextEl) {
    const next = nextUnlock(player.skills?.carto?.lv || 1);
    nextEl.textContent = next
      ? `Next: Lv ${next.lv} · ${next.name} — ${next.text || ''}`
      : 'All Wayfinding unlocks earned.';
  }
  // Build a one-line category summary at the top
  if (categoriesEl) {
    categoriesEl.innerHTML = CATEGORY_ORDER
      .filter(c => byCat.has(c))
      .map(c => `<span class="fj-cat-pill">${CATEGORY_GLYPH[c]} ${byCat.get(c).length} ${CATEGORY_LABEL[c]}</span>`)
      .join('');
  }

  // Render category sections
  body.innerHTML = '';
  if (sketches.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'fj-empty';
    empty.innerHTML = `
      <p><b>The journal is bound but blank.</b></p>
      <p>Walk close to a tree, a creature, or a named landmark and press <kbd>N</kbd> to sketch it.</p>
      <p>Each first sketch is worth Wayfinding XP. Re-sketches are worth less, but they keep the page fresh.</p>
    `;
    body.appendChild(empty);
  } else {
    for (const cat of CATEGORY_ORDER) {
      const list = byCat.get(cat);
      if (!list || !list.length) continue;
      const sec = document.createElement('section');
      sec.className = 'fj-section';
      sec.innerHTML = `<h3 class="fj-section-title">${CATEGORY_GLYPH[cat]} ${CATEGORY_LABEL[cat]} <span class="fj-count">${list.length}</span></h3>`;
      const grid = document.createElement('div');
      grid.className = 'fj-grid';
      // Sort: most recent first
      list.sort((a, b) => (b.sketchedAt || 0) - (a.sketchedAt || 0));
      for (const s of list) {
        const card = document.createElement('div');
        card.className = 'fj-card';
        const date = s.sketchedAt ? new Date(s.sketchedAt) : null;
        const stamp = date ? `${date.getMonth() + 1}/${date.getDate()}` : '—';
        card.innerHTML = `
          <div class="fj-card-name">${escapeHTML(s.name)}</div>
          <div class="fj-card-meta">×${s.count || 1}  ·  ${stamp}</div>
        `;
        grid.appendChild(card);
      }
      sec.appendChild(grid);
      body.appendChild(sec);
    }
  }

  backdrop.classList.add('open');
  _open = true;
}

function escapeHTML(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
}
