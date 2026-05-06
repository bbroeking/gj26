#!/usr/bin/env node
// Pure filter: pulls every prompt for an id in _missing-ids.json out of
// prompts.json. generate_icon_prompts.mjs now owns the whole catalog
// (items + skills), so this script is just a missing-id projection.
//
// Output: docs/research/icons/_resubmit-batch.json
//   { master_stem, count, prompts: [{id, prompt}, ...] }
//
// Usage:  node scripts/research/build_resubmit_batch.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const ROOT = new URL('../..', import.meta.url).pathname;
const PROMPTS = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/prompts.json`, 'utf8'));
const MISSING = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/_missing-ids.json`, 'utf8'));

const byId = Object.fromEntries(PROMPTS.items.map(p => [p.id, p.prompt]));
const out = [];
const skipped = [];
for (const id of MISSING) {
  if (byId[id]) out.push({ id, prompt: byId[id] });
  else skipped.push(id);
}

writeFileSync(
  `${ROOT}/docs/research/icons/_resubmit-batch.json`,
  JSON.stringify({ master_stem: PROMPTS.master_stem, count: out.length, prompts: out }, null, 2),
);
console.log(`Wrote ${out.length} prompts → docs/research/icons/_resubmit-batch.json`);
console.log(`(${out.filter(o => !o.id.startsWith('skill_')).length} item + ${out.filter(o => o.id.startsWith('skill_')).length} skill)`);
if (skipped.length) {
  console.log(`\nSkipped ${skipped.length} ids (not in prompts.json — needs catalog update):`);
  for (const id of skipped) console.log(`  ${id}`);
}
