#!/usr/bin/env node
// Builds a visual style-audit page for all icons in assets/icons/,
// grouped by the same category buckets the codex's items tab uses.
// Eyeball it to decide whether per-category srefs are needed (if each
// row reads as internally consistent but the rows diverge from each
// other) or whether a single moodboard sref would fix everything (if
// the inconsistency is random across rows).
//
// Output: docs/research/icons/_audit.html
//   Open with a browser. Each row is a category. Within a row, icons
//   are side-by-side at 80px so style differences are visible.
//
// Usage:  node scripts/research/build_icon_audit.mjs

import { readdirSync, writeFileSync, existsSync } from 'node:fs';
import { ITEMS } from '../../src/data/items.js';

const ROOT = new URL('../..', import.meta.url).pathname;
const ICON_DIR = `${ROOT}/assets/icons`;

// Same category table as codex.js — kept identical so the audit shows
// what the player sees in the items grid.
// Same shape as codex.js ITEM_CATEGORIES — predicates take the [id, item]
// tuple and destructure inside. First-match-wins.
const CATEGORIES = [
  ['weapon',     'Weapons',         ([id, it]) => it.slot === 'weapon' || !!it.weaponClass],
  ['armor',      'Armor',           ([id, it]) => ['body','legs','head','shield','cloak','boots','gloves'].includes(it.slot)],
  ['tool',       'Tools',           ([id, it]) => !!it.tool],
  ['food',       'Food',            ([id, it]) => !!it.food],
  ['rune',       'Runes',           ([id])     => id.startsWith('rune_')],
  ['ink',        'Inks',            ([id])     => id.endsWith('_ink') || id === 'charcoal_bind' || id === 'lustrous_ink'],
  ['chart',      'Charts',          ([id, it]) => !!it.chart || id.startsWith('chart_')],
  ['parchment',  'Lore',            ([id, it]) => !!it.lore || id.startsWith('parchment_')],
  ['key',        'Keys',            ([id])     => id.endsWith('_key')],
  ['ore',        'Ores & Bars',     ([id])     => id.endsWith('_ore') || id.endsWith('_bar') || id === 'ore_dust'],
  ['drop',       'Monster Drops',   ([id])     => /(_pelt|_tusk|_strip|_crackling|tusker_|hedgewight|whicker|raw_|charred_)/.test(id)],
  ['skill',      'Skill Icons',     ([id])     => id.startsWith('skill_')],
  ['misc',       'Sundries',        ()         => true],
];

function categorize(entry) {
  for (const [key, , test] of CATEGORIES) {
    if (test(entry)) return key;
  }
  return 'misc';
}

// Inventory the on-disk PNGs (some may be hand-curated, some MJ-generated).
const onDisk = new Set(readdirSync(ICON_DIR).filter(f => f.endsWith('.png')));

// For each catalog item that has a PNG, place it in its category bucket.
const buckets = {};
for (const [id, item] of Object.entries(ITEMS)) {
  if (!item.name) continue;
  const file = `${id}.png`;
  if (!onDisk.has(file)) continue;
  const k = categorize([id, item]);
  (buckets[k] ||= []).push({ id, name: item.name, file });
}
// Skill icons live by stripped name (atk.png, str.png, …) — add them too.
const SKILLS = ['atk', 'str', 'def', 'hp', 'cook', 'wilds', 'earth', 'carto', 'falconry', 'magic'];
for (const k of SKILLS) {
  if (!onDisk.has(`${k}.png`)) continue;
  (buckets.skill ||= []).push({ id: `skill_${k}`, name: `Skill — ${k}`, file: `${k}.png` });
}

// Sort buckets alphabetically within for predictability across audits.
for (const k of Object.keys(buckets)) buckets[k].sort((a, b) => a.id.localeCompare(b.id));

// Render the HTML.
let total = 0;
for (const arr of Object.values(buckets)) total += arr.length;
const headerHTML = `<header>
  <h1>Bramblewood Icon Style Audit</h1>
  <p class="sub">${total} icons grouped by category. Each row should read as internally consistent — outliers stand out. If all rows look uniform but distinct from each other, per-category srefs are the right fix. If outliers are scattered randomly within rows, a single moodboard sref is the fix.</p>
</header>`;

const rowsHTML = CATEGORIES.map(([key, label]) => {
  const items = buckets[key] || [];
  if (items.length === 0) return '';
  return `<section class="cat">
    <h2>${label} <span class="count">${items.length}</span></h2>
    <div class="strip">
      ${items.map(it => `<figure>
        <img src="../../../assets/icons/${it.file}" alt="${it.id}" />
        <figcaption>${it.id}</figcaption>
      </figure>`).join('')}
    </div>
  </section>`;
}).join('');

const html = `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<title>Icon style audit — Bramblewood</title>
<style>
  body { background: #1a1410; color: #f0d8a8; font: 14px/1.4 system-ui, sans-serif; padding: 24px; max-width: 1900px; margin: 0 auto; }
  header h1 { color: #ffe6b0; font-family: 'IM Fell English SC', serif; margin: 0 0 6px; }
  header .sub { color: #b8a47a; max-width: 720px; }
  section.cat { margin: 30px 0 18px; }
  section.cat h2 { color: #d4af37; border-bottom: 1px solid #5a4a3a; padding-bottom: 4px; font-family: 'IM Fell English SC', serif; }
  section.cat .count { color: #8a7a52; font-size: 12px; margin-left: 6px; }
  .strip { display: flex; flex-wrap: wrap; gap: 6px; }
  figure { margin: 0; width: 90px; text-align: center; background: #2a201a; padding: 4px; border-radius: 3px; }
  figure img { width: 80px; height: 80px; image-rendering: crisp-edges; background: #f4ecd8; border-radius: 2px; display: block; }
  figcaption { font-size: 9px; color: #8a7a5a; margin-top: 3px; word-break: break-all; line-height: 1.1; }
</style>
</head><body>
  ${headerHTML}
  ${rowsHTML}
  <p style="color:#5a4a3a;font-size:11px;margin-top:40px">Generated by scripts/research/build_icon_audit.mjs · ${new Date().toISOString().slice(0, 10)}</p>
</body></html>`;

const outPath = `${ROOT}/docs/research/icons/_audit.html`;
writeFileSync(outPath, html);
console.log(`Wrote audit page → ${outPath}`);
console.log(`\nCategory breakdown:`);
let unaccounted = total;
for (const [key, label] of CATEGORIES) {
  const n = (buckets[key] || []).length;
  if (n) {
    console.log(`  ${label.padEnd(18)} ${n}`);
    unaccounted -= n;
  }
}
console.log(`\nOpen with: open ${outPath}`);
console.log(`Or via dev server: http://127.0.0.1:8765/docs/research/icons/_audit.html`);
