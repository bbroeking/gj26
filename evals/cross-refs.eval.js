// Layer 3 — referential integrity. Code-based.
//
// Catches the silent killer: an NPC gives you a quest to find an item that
// doesn't exist. Validates all cross-registry references.
import { ITEMS } from '../src/data/items.js';
// Add other registries as they exist:
// import { NPCS } from '../src/data/npcs.js';
// import { ENEMIES } from '../src/game/enemies.js';

export function evalCrossRefs() {
  const errors = [];
  const itemIds = new Set(Object.keys(ITEMS));

  // Cooking recipes: cooked_X and burnt_X imply raw_X exists
  for (const id of itemIds) {
    if (id.startsWith('cooked_')) {
      const rawId = id.replace('cooked_', 'raw_');
      if (!itemIds.has(rawId)) {
        errors.push(`item ${id}: implied raw "${rawId}" doesn't exist`);
      }
    }
    if (id.startsWith('burnt_')) {
      const rawId = id.replace('burnt_', 'raw_');
      if (!itemIds.has(rawId)) {
        errors.push(`item ${id}: implied raw "${rawId}" doesn't exist`);
      }
    }
  }

  // Material refines.into must exist
  for (const [id, item] of Object.entries(ITEMS)) {
    if (item.refines?.into) {
      if (!itemIds.has(item.refines.into)) {
        errors.push(`item ${id}: refines.into "${item.refines.into}" doesn't exist`);
      }
    }
  }

  // (Extend when NPCs/enemies exist as registries:)
  //
  // for (const [npcId, npc] of Object.entries(NPCS)) {
  //   for (const giftId of [...npc.dialog?.gifts?.loved || [], ...]) {
  //     if (!itemIds.has(giftId)) errors.push(`npc ${npcId}: gift "${giftId}" missing`);
  //   }
  // }
  //
  // for (const [kind, def] of Object.entries(ENEMIES)) {
  //   for (const drop of (def.drops || [])) {
  //     if (!itemIds.has(drop.item)) errors.push(`enemy ${kind}: drop "${drop.item}" missing`);
  //   }
  // }

  return errors;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const errors = evalCrossRefs();
  if (errors.length) {
    console.error(`✗ ${errors.length} cross-ref errors:`);
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }
  console.log('✓ cross-refs OK');
}
