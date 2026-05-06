import { readFileSync, existsSync } from 'node:fs';
import { ITEMS } from '../../src/data/items.js';

const ROOT = new URL('../..', import.meta.url).pathname;
const SCRAPED = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/scraped-manifest.json`, 'utf8'));
const ITEM_PROMPTS = JSON.parse(readFileSync(`${ROOT}/docs/research/icons/prompts.json`, 'utf8'));

const SKILL_PROMPT_FRAGMENTS = {
  'a stylized crossed-swords symbol':                'skill_atk',
  'a stylized flexed muscular arm in profile':       'skill_str',
  'a stylized heater shield with a single metal':    'skill_def',
  'a stylized red heart with a soft glow':           'skill_hp',
  'a stylized leaf wreath, three leaves':            'skill_wilds',
  'a stylized pickaxe crossed with a smelted':       'skill_earth',
  'a stylized iron cooking pot with two wisps':      'skill_cook',
  'a stylized rolled paper scroll with a wax seal':  'skill_carto',
  'a stylized perched falcon silhouette':            'skill_falconry',
  'a stylized rune stone with a single carved sigil':'skill_magic',
};

const ITEM_DESC_TO_ID = {};
for (const item of ITEM_PROMPTS.items) {
  const key = item.prompt.slice(0, 80);
  ITEM_DESC_TO_ID[key] = item.id;
}

function matchPrompt(scraped) {
  for (const [frag, id] of Object.entries(SKILL_PROMPT_FRAGMENTS)) {
    if (scraped.startsWith(frag)) return id;
  }
  const key = scraped.slice(0, 80);
  if (ITEM_DESC_TO_ID[key]) return ITEM_DESC_TO_ID[key];
  for (const [key2, id] of Object.entries(ITEM_DESC_TO_ID)) {
    if (scraped.startsWith(key2.slice(0, 60))) return id;
  }
  return null;
}

const matched = [];
for (const job of SCRAPED) {
  const id = matchPrompt(job.prompt);
  if (id) matched.push({ id, url: job.url });
}

const missing = matched.filter(m => {
  const savePath = `${ROOT}/assets/icons/${m.id.replace(/^skill_/, '')}.png`;
  return !existsSync(savePath);
});

console.log(JSON.stringify({
  total_matched: matched.length,
  already_have: matched.length - missing.length,
  to_fetch: missing.length,
  list: missing,
}));
