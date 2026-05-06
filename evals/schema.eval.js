// Layer 1 — schema validation. Code-based; cheap; runs on every commit.
//
// Catches: missing required fields, wrong types, duplicate IDs, invalid slot
// names, descriptions that are obviously placeholder.
import { ITEMS } from '../src/data/items.js';

const REQUIRED_ITEM_FIELDS = ['name', 'icon', 'stack', 'desc'];
// Canonical slot names from src/main.js and src/data/config.js.
// Note: the project uses 'helm' (not 'helmet'). Keep this list in sync with
// CONFIG.equipment in src/data/config.js.
const VALID_SLOTS = ['weapon', 'body', 'shield', 'helm', 'boots', 'cape'];
const VALID_TIERS = ['bronze', 'iron', 'steel', 'mithril', 'adamant', 'rune'];

export function evalItemSchema() {
  const errors = [];
  const seenIds = new Set();

  for (const [id, item] of Object.entries(ITEMS)) {
    // ID format
    if (!/^[a-z0-9_]+$/.test(id)) {
      errors.push(`item ${id}: id must be snake_case`);
    }
    if (seenIds.has(id)) errors.push(`item ${id}: duplicate id`);
    seenIds.add(id);

    // Required fields
    for (const field of REQUIRED_ITEM_FIELDS) {
      if (item[field] === undefined) {
        errors.push(`item ${id}: missing field "${field}"`);
      }
    }

    // Type checks
    if (typeof item.name !== 'string') {
      errors.push(`item ${id}: name must be string`);
    }
    if (typeof item.stack !== 'boolean') {
      errors.push(`item ${id}: stack must be boolean`);
    }

    // Slot validity
    if (item.slot && !VALID_SLOTS.includes(item.slot)) {
      errors.push(`item ${id}: invalid slot "${item.slot}"`);
    }

    // Tier validity
    if (item.tier && !VALID_TIERS.includes(item.tier)) {
      errors.push(`item ${id}: invalid tier "${item.tier}"`);
    }

    // equipBonus shape
    if (item.equipBonus) {
      const { atk, str, def } = item.equipBonus;
      if (typeof atk !== 'number' || typeof str !== 'number' || typeof def !== 'number') {
        errors.push(`item ${id}: equipBonus must have atk/str/def numbers`);
      }
    }

    // Description sanity
    if (typeof item.desc === 'string') {
      if (item.desc.length < 10) {
        errors.push(`item ${id}: desc too short (likely placeholder)`);
      }
      if (item.desc.length > 250) {
        errors.push(`item ${id}: desc too long (1-2 sentences expected)`);
      }
    }

    // Food shape
    if (item.food) {
      if (typeof item.food.heal !== 'number' || item.food.heal <= 0) {
        errors.push(`item ${id}: food.heal must be positive number`);
      }
    }
  }

  return errors;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const errors = evalItemSchema();
  if (errors.length) {
    console.error(`✗ ${errors.length} schema errors:`);
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }
  console.log(`✓ schema OK (${Object.keys(await import('../src/data/items.js')).ITEMS ? Object.keys((await import('../src/data/items.js')).ITEMS).length : '?'} items)`);
}
