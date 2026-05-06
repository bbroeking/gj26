// Layer 2 — tier conformance. Code-based.
//
// Validates that gear stat totals match the locked tier budget from
// content-generation-playbook.md §2. Linear scaling: bronze=3, iron=6, etc.
import { ITEMS } from '../src/data/items.js';

const WEAPON_BUDGET   = { bronze: 3,  iron: 6,  steel: 9,  mithril: 12, adamant: 15, rune: 18 };
const BODY_BUDGET     = { bronze: 2,  iron: 4,  steel: 6,  mithril: 8,  adamant: 10, rune: 12 };
const SHIELD_BUDGET   = { bronze: 1,  iron: 2,  steel: 3,  mithril: 4,  adamant: 5,  rune: 6  };
const HELMET_BUDGET   = { bronze: 1,  iron: 2,  steel: 3,  mithril: 4,  adamant: 5,  rune: 6  };

const TIER_LEVEL_RANGE = {
  bronze:  [1, 15],
  iron:    [15, 30],
  steel:   [30, 45],
  mithril: [45, 60],
  adamant: [60, 75],
  rune:    [75, 99],
};

export function evalTierBudget() {
  const errors = [];

  for (const [id, item] of Object.entries(ITEMS)) {
    if (!item.tier) continue;
    const e = item.equipBonus || { atk: 0, str: 0, def: 0 };

    if (item.slot === 'weapon') {
      const total = e.atk + e.str;
      const budget = WEAPON_BUDGET[item.tier];
      if (total !== budget) {
        errors.push(`${id}: weapon tier "${item.tier}" expects atk+str=${budget}, got ${total} (atk:${e.atk} str:${e.str})`);
      }
    }
    if (item.slot === 'body') {
      const budget = BODY_BUDGET[item.tier];
      if (e.def !== budget) {
        errors.push(`${id}: body tier "${item.tier}" expects def=${budget}, got def=${e.def}`);
      }
    }
    if (item.slot === 'shield') {
      const budget = SHIELD_BUDGET[item.tier];
      if (e.def !== budget) {
        errors.push(`${id}: shield tier "${item.tier}" expects def=${budget}, got def=${e.def}`);
      }
    }
    if (item.slot === 'helm') {
      const budget = HELMET_BUDGET[item.tier];
      if (e.def !== budget) {
        errors.push(`${id}: helm tier "${item.tier}" expects def=${budget}, got def=${e.def}`);
      }
    }

    if (item.reqLevel !== undefined) {
      const range = TIER_LEVEL_RANGE[item.tier];
      if (range && (item.reqLevel < range[0] || item.reqLevel > range[1])) {
        errors.push(`${id}: reqLevel ${item.reqLevel} outside tier "${item.tier}" range [${range[0]}, ${range[1]}]`);
      }
    }
  }

  return errors;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const errors = evalTierBudget();
  if (errors.length) {
    console.error(`✗ ${errors.length} tier-budget errors:`);
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }
  console.log('✓ tier budget OK');
}
