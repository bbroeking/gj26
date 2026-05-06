// Base affix weights per chart tier + bias-roll engine.
// Inks dropped into a chart's ink-slots multiply matching weights;
// after normalization, each affix slot is rolled independently.

import { AFFIXES } from './affixes.js';
import { ITEMS } from './items.js';

// Base weights — relative likelihood for each affix to land in a slot,
// before any ink bias is applied. Higher = more likely. Tier-gated:
// affixes with reqCarto > tier × 10 get weight 0.
const BASE_WEIGHTS = {
  // Bias (resource layer)
  mineral_vein:    10,
  bramble_bloom:    8,
  tinder_cache:     8,
  ink_spring:       4,
  wood_grove:       8,
  herbal_patch:     8,
  gem_seam:         3,
  // Modifier (combat math)
  tyrannical:       8,
  bursting:         6,
  frenzied:         5,
  quiver:           4,
  // Boss
  hedgemother_den:  3,
  burrow_boar_den:  3,
  wolf_alpha_den:   3,
  // Pacing
  festival_pace:    7,
  sprinter:         3,
  // Atmosphere
  fog_of_hedge:     6,
};

/**
 * Compute the weight table for a chart given its tier + the inks slotted
 * into its ink-slots. Returns { affixId: weight } normalized to sum 100.
 * Affixes whose reqCarto exceeds the player's level are dropped to 0.
 *
 * @param {number} tier        — chart tier (1..5)
 * @param {string[]} inkIds    — items in ink-slots, in order
 * @param {number} cartoLv
 * @returns {Record<string,number>}  affix-id → percent
 */
export function computeWeights(tier, inkIds, cartoLv) {
  const weights = {};
  for (const id of Object.keys(BASE_WEIGHTS)) {
    const aff = AFFIXES[id];
    if (!aff) continue;
    if (aff.reqCarto > cartoLv) continue;     // gated by carto level
    weights[id] = BASE_WEIGHTS[id];
  }
  // Apply ink biases (multiplicative)
  for (const inkId of inkIds) {
    const ink = ITEMS[inkId]?.ink;
    if (!ink?.bias) continue;
    for (const [affixId, mult] of Object.entries(ink.bias)) {
      if (affixId.startsWith('_')) continue;   // _stability is handled elsewhere
      if (weights[affixId] != null) weights[affixId] *= mult;
    }
  }
  // Normalize to percent
  const total = Object.values(weights).reduce((s, w) => s + w, 0) || 1;
  const out = {};
  for (const [id, w] of Object.entries(weights)) {
    out[id] = (w / total) * 100;
  }
  return out;
}

/**
 * Roll N affixes from a weight table. Each roll is independent — the
 * same affix can land twice in different slots (rare but possible). For
 * Phase 1 we'll dedupe: if a duplicate rolls, re-roll once.
 */
export function rollAffixes(weights, count) {
  const picks = [];
  const remaining = { ...weights };
  for (let i = 0; i < count; i++) {
    const id = weightedPick(remaining);
    if (!id) break;
    picks.push(id);
    delete remaining[id];   // avoid duplicate affix in the same chart
  }
  return picks;
}

function weightedPick(weights) {
  const total = Object.values(weights).reduce((s, w) => s + w, 0);
  if (total <= 0) return null;
  let r = Math.random() * total;
  for (const [id, w] of Object.entries(weights)) {
    r -= w;
    if (r <= 0) return id;
  }
  return Object.keys(weights).pop();
}

/**
 * Total stability bonus from inks that contribute `_stability` (Charcoal
 * Bind etc.). Returns a flat percent added to every affix's good-twin
 * roll.
 */
export function inkStabilityBonus(inkIds) {
  let bonus = 0;
  for (const inkId of inkIds) {
    const b = ITEMS[inkId]?.ink?.bias?._stability || 0;
    bonus += b;
  }
  return Math.min(0.5, bonus);   // cap at +50% so Charcoal Bind stacks aren't broken
}
