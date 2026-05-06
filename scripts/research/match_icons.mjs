#!/usr/bin/env node
// Match scraped MJ jobs to item/skill ids by comparing their prompts
// against docs/research/icons/prompts.json (the full catalog produced by
// generate_icon_prompts.mjs — items + skills).
//
// This used to also curl each match's CDN URL, but Cloudflare gates the
// CDN and 403s anything without a live MJ session cookie. The actual
// download path is now the in-browser canvas+archive flow (see the
// Skill tool comments in conversation history) → unpack_mj_archive.mjs.
//
// Output:
//   docs/research/icons/_unmatched.json   — scraped jobs we couldn't
//                                           place (debug input)
//   docs/research/icons/_missing-ids.json — every id (item + skill)
//                                           without a PNG on disk
//
// Usage:  node scripts/research/match_icons.mjs
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { ITEMS } from '../../src/data/items.js';

const ROOT = new URL('../..', import.meta.url).pathname;
const SCRAPED = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/scraped-manifest.json`, 'utf8'));
const PROMPTS = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/prompts.json`, 'utf8'));

// Build {prompt-prefix → id} from prompts.json. The first ~80 chars of
// each prompt are the unique descriptor; everything after is the shared
// master stem, so a prefix match is enough.
const PREFIX_TO_ID = {};
for (const item of PROMPTS.items) {
  PREFIX_TO_ID[item.prompt.slice(0, 80)] = item.id;
}

function matchPrompt(scraped) {
  const key = scraped.slice(0, 80);
  if (PREFIX_TO_ID[key]) return PREFIX_TO_ID[key];
  // Fuzzy fallback at 60 chars catches scrapes that were truncated or had
  // a stray whitespace difference.
  for (const [p, id] of Object.entries(PREFIX_TO_ID)) {
    if (scraped.startsWith(p.slice(0, 60))) return id;
  }
  return null;
}

const matched = [];
const unmatched = [];
for (const job of SCRAPED) {
  const id = matchPrompt(job.prompt);
  if (id) matched.push({ id, ...job });
  else unmatched.push(job);
}
console.log(`Matched: ${matched.length}/${SCRAPED.length}, unmatched: ${unmatched.length}`);

// Missing = every catalog id (items + skills) without a PNG on disk.
const allIds = [
  ...Object.keys(ITEMS),
  ...PROMPTS.items.filter(p => p.id.startsWith('skill_')).map(p => p.id),
];
const missingIds = allIds.filter(id => {
  const fileName = id.replace(/^skill_/, '') + '.png';
  return !existsSync(`${ROOT}/assets/icons/${fileName}`);
});

console.log(`\nMissing PNGs (${missingIds.length} of ${allIds.length}):`);
for (const id of missingIds.slice(0, 20)) console.log(`  ${id}`);
if (missingIds.length > 20) console.log(`  …and ${missingIds.length - 20} more`);

writeFileSync(`${ROOT}/docs/research/icons/_unmatched.json`,
  JSON.stringify(unmatched, null, 2));
writeFileSync(`${ROOT}/docs/research/icons/_missing-ids.json`,
  JSON.stringify(missingIds, null, 2));
console.log(`\nWrote _unmatched.json + _missing-ids.json. Resubmit with build_resubmit_batch.mjs.`);
