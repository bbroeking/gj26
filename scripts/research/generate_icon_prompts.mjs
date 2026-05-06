#!/usr/bin/env node
// Read ITEMS from src/data/items.js and emit a Midjourney prompt per item,
// each composed of a shared master stem + an item-specific visual descriptor.
//
// Output: docs/research/icons/prompts.json — array of:
//   { id, name, category, descriptor, prompt }
//
// Usage:  node scripts/research/generate_icon_prompts.mjs
//
// The MASTER_STEM below is the visual contract every icon shares so the
// inventory grid reads as one coherent set. Per-item descriptors fill in
// the {ITEM} slot.
import { ITEMS } from '../../src/data/items.js';
import { writeFileSync } from 'node:fs';

// Master stem — every icon shares this so the inventory reads as a coherent
// set. Iteration 2 (after pilot rev with brindle_sword): dropped realism
// cues ("warm cream parchment background", "soft top-left warm lighting",
// "gentle drop shadow") because Midjourney V8.1 latched onto them as
// PHOTO-realism cues and rendered weathered-artifact-on-stone shots
// instead of storybook icons. Lead with explicit illustration keywords
// instead. Style reference (--sref) goes onto the prompt at submit time
// once we have a code/url for the knight reference image.
const MASTER_STEM = (item) =>
  `storybook illustration of ${item}, ` +
  `single centered object, hand-painted game inventory icon, ` +
  `chunky low-poly fantasy RPG asset, thick warm-brown ink outline, ` +
  `painterly texture with visible brush strokes, no scene, no people, ` +
  `flat plain background, square crop --ar 1:1 --stylize 500`;

// Category inference — every item lands in one of these buckets so we can
// write a more idiomatic visual descriptor than just "icon of <name>".
function categorize(id, item) {
  if (item.slot === 'weapon') return 'weapon';
  if (item.slot === 'shield') return 'shield';
  if (item.slot === 'body' || item.slot === 'helmet'
      || item.slot === 'legs' || item.slot === 'boots'
      || item.slot === 'cape' || item.slot === 'belt'
      || item.slot === 'gloves' || item.slot === 'pauldrons') return 'armor';
  if (item.tool) return 'tool';
  if (item.food) return 'food_cooked';
  if (id.startsWith('raw_')) return 'food_raw';
  if (id.startsWith('charred_') || id.startsWith('burnt_')) return 'food_burnt';
  if (/_ore$|^logs?$|_bar$|_planks?$/.test(id)) return 'raw_material';
  if (/feather|hide|pelt|flank|tusk|fang|claw|horn|wool|down/.test(id)) return 'monster_drop';
  if (/draught|potion|brew|tincture|elixir/.test(id)) return 'potion';
  if (/parchment|scroll|ledger|tome|map/.test(id)) return 'paper';
  if (/seed|herb|berry|mushroom|cap|root|leaf|flower/.test(id)) return 'forageable';
  if (/coin|token|gem|relic|whistle|crown|ring|amulet/.test(id)) return 'trinket';
  return 'misc';
}

// Tier — the game has at least three weapon/armor metal tiers (Brindle =
// tier 1, Bogiron = tier 2, Coalrose+ = tier 3). MJ V8.1 over-elaborates
// by default, so we tell it explicitly that tier-1 items are SIMPLE and
// only tier-3 should look ornate. Maps stat-bonus sum to a complexity
// adjective injected into the descriptor.
function tierAdjective(item) {
  const eb = item.equipBonus;
  if (!eb) return null;
  const sum = (eb.atk||0) + (eb.str||0) + (eb.def||0);
  if (sum <= 3)  return 'simple plain undecorated';
  if (sum <= 6)  return 'sturdy workmanlike riveted';
  if (sum <= 10) return 'fine well-made';
  return 'ornate masterwork engraved';
}

// Visual descriptor — what the single rendered object actually IS, written
// to coax Midjourney into drawing the right thing. Falls back to item.name
// when we don't have a strong category template.
function describe(id, item, category) {
  const name = item.name.toLowerCase();
  const desc = (item.desc || '').replace(/\.\s*\+\d+.*$/, '').trim();
  const hint = desc ? ` (${desc})` : '';
  const tier = tierAdjective(item);
  // For equipment categories, prefix the noun with the tier adjective so
  // "a brindle sword" becomes "a simple plain undecorated brindle sword".
  const T = tier ? `${tier} ` : '';

  // Iteration 2: descriptors are now CONCEPT-only (what the object IS),
  // letting the master stem + style ref carry all the rendering treatment.
  // No "warm light", "parchment", "three-quarter view" — those compete
  // with the sref'd visual treatment.
  switch (category) {
    case 'weapon':
      return `a ${T}${name}${hint}`;
    case 'shield':
      return `a ${T}${name}${hint}, round shield with iron rim and central boss`;
    case 'armor': {
      // Slot-specific noun avoids the "leather body" → leather BAG bug
      // (MJ V8.1 reads "X body" as an object, not as torso armor).
      const slotNoun = {
        'body':      'chest cuirass armor',
        'helmet':    'helmet',
        'legs':      'leg greaves armor',
        'boots':     'boots',
        'gloves':    'gauntlets',
        'cape':      'cape / cloak',
        'belt':      'leather belt',
        'pauldrons': 'shoulder pauldrons',
      }[item.slot] || 'armor piece';
      // Strip the "X body / X helmet" suffix from the name when we have a
      // slot-specific noun, so "Leather Body" becomes just "leather" + "chest cuirass armor".
      const material = item.name.replace(/\s+(Body|Helmet|Legs|Boots|Gloves|Cape|Belt|Pauldrons)$/i, '').toLowerCase();
      return `a ${T}${material} ${slotNoun}${hint}`;
    }
    case 'tool':
      return `a ${name}${hint}, hand tool`;
    case 'food_cooked': {
      const n = name.replace(/^cooked\s+/i, '');
      return `cooked ${n}${hint}, served portion of food`;
    }
    case 'food_raw': {
      const n = name.replace(/^raw\s+/i, '');
      return `raw ${n}${hint}, uncooked ingredient`;
    }
    case 'food_burnt': {
      const n = name.replace(/^(charred|burnt)\s+/i, '');
      return `charred blackened ${n}${hint}, ruined food, scorched and crumbling`;
    }
    case 'raw_material':
      if (id.endsWith('_ore'))    return `a chunk of raw ${name}${hint}, mineral ore`;
      if (id.endsWith('_bar'))    return `a ${name}${hint}, smelted metal ingot`;
      if (id.startsWith('logs'))  return `a stack of ${name}${hint}, chopped wood`;
      if (id.endsWith('_planks')) return `a stack of ${name}${hint}, cut lumber`;
      return `a piece of ${name}${hint}, crafting material`;
    case 'monster_drop':
      return `a ${name}${hint}, monster drop / crafting material`;
    case 'potion':
      return `a vial of ${name}${hint}, magical potion in a glass bottle`;
    case 'paper':
      return `a ${name}${hint}, rolled parchment scroll`;
    case 'forageable':
      if (/berry|whitleberry/.test(id))               return `a cluster of ${name}${hint}, foraged berries`;
      if (/mushroom|cap/.test(id))                    return `a ${name}${hint}, foraged mushroom`;
      if (/herb|wishrose|root|leaf|flower/.test(id))  return `a sprig of ${name}${hint}, foraged herb`;
      return `a handful of ${name}${hint}, foraged ingredient`;
    case 'trinket':
      return `a ${name}${hint}, small treasured object`;
    default:
      return `a ${name}${hint}`;
  }
}

// Skill icon descriptors. Skills aren't in items.js, so they get their own
// table here. Same master stem so they sit visually with the items in the
// inventory grid + skills HUD. Keys match the SKILL_KEYS in src/game/skills.js.
const SKILL_DESCRIPTORS = {
  atk:      'a stylized crossed-swords symbol, fairytale storybook icon',
  str:      'a stylized flexed muscular arm in profile, fairytale storybook icon',
  def:      'a stylized heater shield with a single metal boss at center, slightly battered fairytale shield silhouette',
  hp:       'a stylized red heart with a soft inner glow, fairytale storybook heart symbol',
  cook:     'a stylized iron cooking pot with two wisps of steam, fairytale storybook icon',
  wilds:    'a stylized leaf wreath, three leaves arranged in a tight circle, fairytale storybook icon',
  earth:    'a stylized pickaxe crossed with a smelted metal bar, fairytale storybook icon',
  carto:    'a stylized rolled paper scroll with a wax seal, fairytale storybook icon',
  falconry: 'a stylized perched falcon silhouette on a gauntlet, fairytale storybook icon',
  magic:    'a stylized rune stone with a single carved sigil glowing softly, fairytale storybook icon',
};

const out = [];
for (const [id, item] of Object.entries(ITEMS)) {
  if (!item.name) continue;
  const category = categorize(id, item);
  const descriptor = describe(id, item, category);
  const prompt = MASTER_STEM(descriptor);
  out.push({ id, name: item.name, category, descriptor, prompt });
}
for (const [skill, descriptor] of Object.entries(SKILL_DESCRIPTORS)) {
  out.push({
    id:         `skill_${skill}`,
    name:       `${skill[0].toUpperCase()}${skill.slice(1)} skill icon`,
    category:   'skill',
    descriptor,
    prompt:     MASTER_STEM(descriptor),
  });
}

writeFileSync(
  'docs/research/icons/prompts.json',
  JSON.stringify({ count: out.length, master_stem: MASTER_STEM('{ITEM}'), items: out }, null, 2),
);
console.log(`Generated ${out.length} prompts (${Object.keys(ITEMS).length} items + ${Object.keys(SKILL_DESCRIPTORS).length} skills) → docs/research/icons/prompts.json`);

// Per-category summary so we know the distribution at a glance.
const counts = {};
for (const r of out) counts[r.category] = (counts[r.category] || 0) + 1;
console.log('\nCategory distribution:');
for (const [cat, n] of Object.entries(counts).sort((a, b) => b[1] - a[1])) {
  console.log(`  ${cat.padEnd(16)} ${n}`);
}
