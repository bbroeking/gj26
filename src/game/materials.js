// Materials inspector — pure data, no DOM.
//
// Powers the workshop's enriched Materials section and the standalone
// Materials Browser modal. Two outputs:
//
//   summarizeMaterials(player, ITEMS, INK_RECIPES)
//     → { byEssence, vessels, canMix, almostCan }
//
//   recipeStatus(recipe, inv, ITEMS)
//     → { cellsTotal, cellsSatisfied, vesselOK, canCraft, missing }
//
// The status walker greedily allocates inventory items to recipe cells
// (specific-id cells first, then essence/tier cells) so a missing
// hedge_ink shows as missing instead of being satisfied by a verdant
// herb (which has the same essence but isn't the *specific* ingredient
// the recipe wants).

import { essenceOf } from '../data/inkRecipes.js';

const ESSENCE_ORDER = ['verdant', 'earthen', 'sanguine', 'lumen', 'ink', 'other'];
const ESSENCE_LABEL = {
  verdant:  'Verdant',
  earthen:  'Earthen',
  sanguine: 'Sanguine',
  lumen:    'Lumen',
  ink:      'Inks',
  other:    'Other',
};

export function essenceLabel(key) { return ESSENCE_LABEL[key] || key; }

/** Bucket every craftable material in the player's bag by essence. */
export function summarizeMaterials(player, ITEMS, INK_RECIPES) {
  const inv = player.inventory;
  const byEssence = Object.fromEntries(ESSENCE_ORDER.map(k => [k, []]));
  const vessels = [];

  for (let i = 0; i < inv.slots.length; i++) {
    const slot = inv.slots[i];
    if (!slot) continue;
    const def = ITEMS[slot.id];
    if (!def) continue;
    if (def.vessel) {
      vessels.push({ id: slot.id, qty: slot.qty || 1, def, vessel: def.vessel });
      continue;
    }
    const e = essenceOf(slot.id, ITEMS);
    if (!e) continue;
    const bucket = byEssence[e.essence] || byEssence.other;
    bucket.push({
      id: slot.id, qty: slot.qty || 1, def,
      essence: e.essence, tier: e.tier ?? 1,
    });
  }

  // Sort each bucket: tier asc, then name.
  for (const k of Object.keys(byEssence)) {
    byEssence[k].sort((a, b) => (a.tier - b.tier) || a.def.name.localeCompare(b.def.name));
  }

  // Walk recipes — bucket by craftability.
  const canMix = [];
  const almostCan = [];
  for (const recipe of INK_RECIPES) {
    const status = recipeStatus(recipe, inv, ITEMS);
    if (status.canCraft) {
      canMix.push({ recipe, status });
    } else if (status.missing.length > 0 && status.missing.length <= 2) {
      // "Almost" = within 2 missing pieces total. Counts vessel missing too.
      almostCan.push({ recipe, status });
    }
  }

  // Sort: known recipes first within each bucket, then by tier asc.
  const known = player.knownRecipes || new Set();
  const byKnownThenTier = (a, b) => {
    const ak = known.has(a.recipe.id) ? 0 : 1;
    const bk = known.has(b.recipe.id) ? 0 : 1;
    if (ak !== bk) return ak - bk;
    return (a.recipe.tier - b.recipe.tier);
  };
  canMix.sort(byKnownThenTier);
  almostCan.sort(byKnownThenTier);

  return { byEssence, vessels, canMix, almostCan, essenceOrder: ESSENCE_ORDER };
}

/** For a given recipe, walk its 3×3 pattern and figure out:
 *  - how many cells are satisfied by the player's bag
 *  - which specific ingredients are missing
 *  - whether the vessel slot (if any) is satisfied
 *  Returns canCraft = true only when *every* cell + vessel is met. */
export function recipeStatus(recipe, inv, ITEMS) {
  const cells = [];
  for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
    const want = recipe.pattern[y][x];
    if (want) cells.push(want);
  }

  // Allocate id-cells first (specific item required), then essence-cells
  // (any matching essence/tier). This avoids consuming a hedge_ink to
  // satisfy a "verdant tier-1" cell when the recipe also has a
  // specifically-id'd hedge_ink cell.
  const idCells  = cells.filter(c => c.id);
  const essCells = cells.filter(c => c.ess);
  const used = new Map();

  let satisfied = 0;
  const missing = [];

  for (const cell of idCells) {
    const need = (used.get(cell.id) || 0) + 1;
    if (inv.count(cell.id) >= need) {
      used.set(cell.id, need);
      satisfied++;
    } else {
      missing.push({
        id: cell.id,
        label: ITEMS[cell.id]?.name || cell.id,
        haveQty: inv.count(cell.id),
        needQty: need,
      });
    }
  }
  for (const cell of essCells) {
    const picked = pickEssenceItem(cell.ess, cell.tier ?? 1, used, inv, ITEMS);
    if (picked) {
      used.set(picked, (used.get(picked) || 0) + 1);
      satisfied++;
    } else {
      missing.push({
        ess: cell.ess, tier: cell.tier ?? 1,
        label: `any ${cell.ess} (tier ${cell.tier ?? 1}+)`,
      });
    }
  }

  // Vessel
  let vesselOK = true;
  if (recipe.vessel) {
    vesselOK = inv.count(recipe.vessel) >= 1;
    if (!vesselOK) {
      missing.push({
        id: recipe.vessel,
        label: ITEMS[recipe.vessel]?.name || recipe.vessel,
        haveQty: inv.count(recipe.vessel),
        needQty: 1,
        vessel: true,
      });
    }
  }

  return {
    cellsTotal: cells.length,
    cellsSatisfied: satisfied,
    canCraft: satisfied === cells.length && vesselOK,
    vesselOK,
    missing,
    used,
  };
}

function pickEssenceItem(essence, tierMin, usedSoFar, inv, ITEMS) {
  for (const slot of inv.slots) {
    if (!slot) continue;
    const e = essenceOf(slot.id, ITEMS);
    if (!e) continue;
    if (e.essence !== essence) continue;
    if ((e.tier ?? 1) < tierMin) continue;
    const taken = usedSoFar.get(slot.id) || 0;
    if ((slot.qty || 1) - taken > 0) return slot.id;
  }
  return null;
}

/** Source hint for a material — hand-curated for the most common ones,
 *  generic fallback otherwise. Used by the Materials Browser modal. */
export function sourceHint(itemId) {
  return MATERIAL_SOURCES[itemId] || ['Found across Bramblewood.'];
}

const MATERIAL_SOURCES = {
  // Verdant
  hedgecap:        ['Forage on grass tiles', 'Chest loot'],
  whitleberry:     ['Forage on bushes near the village'],
  wishrose:        ['Forage at Wayfinding 12+', 'Quill sells bundles'],
  raw_mushroom:    ['Forage in shaded tiles'],
  bramble_resin:   ['Drops from bramble enemies'],
  thorn_essence:   ['Drops from thorn-types (Quill quest reward)'],
  wild_herb:       ['Forage anywhere in the wilds'],
  // Earthen
  charcoal_stick:  ['Chop logs + cook them on a fire'],
  logs:            ['Chop trees with an axe'],
  ore_dust:        ['Salvage from mining + smelting'],
  bogiron_ore:     ['Mine bogiron veins (Earth Lv 15+)'],
  bog_silt:        ['Gather in mire tiles', 'Sunken Hut chest loot'],
  stone_chip:      ['Mine ore + chest loot in earthroot drifts'],
  // Sanguine
  boar_tusk:       ['Drops from boars'],
  wightpelt:       ['Drops from hedgewights'],
  whickerhares_foot:['Drops from whickerhares (rare)'],
  // Lumen
  pond_water:      ['Gather at water tiles'],
  vellum:          ['Quill sells', 'Chest loot in tier-2 charts'],
  rune_stone:      ['Cricket carries a few', 'Drops in Earthroot Drifts'],
  // Inks
  hedge_ink:       ['Mix at the Inscribing Table', 'Cricket reward'],
  charcoal_bind:   ['Mix at the table — single charcoal in center'],
  stoneground_ink: ['Mix at the table (Hod hint)'],
  bramblepress_ink:['Mix at the table'],
  wellspring_ink:  ['Mix at the table (Quill hint)'],
  refined_ink:     ['Mix at the table (Hod hint)'],
  bog_ink:         ['Mix at the table (Quill hint)'],
  ember_ink:       ['Mix at the table'],
  lustrous_ink:    ['Mix at the table'],
  forge_brand_ink: ['Mix at the table — needs Clay Flask'],
  aurora_ink:      ['Mix at the table — needs Bound Parchment'],
  tidewater_ink:   ['Mix at the table — needs Glass Vial'],
  // Vessels
  clay_flask:      ['Commission from Hod (30 gp + materials)'],
  bound_parchment: ['Commission from Quill (40 gp + materials)'],
  glass_vial:      ['Commission from Cricket (50 gp + materials)'],
};
