// Materials taxonomy — overlays a crafting-tree shape on top of the
// raw-by-id ITEMS dict. The codex Materials tab reads this to render
// the raw → reagent → ink/core/catalyst → orb pipeline. The Wayfinding
// orb forge (and future smithing/cooking refactors) reads it to walk
// the tree at craft-time.
//
// This file is *only metadata*. The items themselves live in items.js.
// If an entry's id isn't in ITEMS, the codex will skip it gracefully.
//
// Tiers:
//   raw       — gathered from the world (forage, mine, drop, fish)
//   reagent   — single-input refinement of one raw at a workstation
//   ink       — multi-reagent compound, color-tagged for orb scope
//   core      — concentrated single-flavor focusing material
//   catalyst  — found-not-crafted; nudges one orb property
//   orb       — final socketable artefact (chart_*)
//
// Groups (flavor, not gameplay-mechanical):
//   verdant   — life / herbs / berries
//   earthen   — stone / metal / charcoal
//   lumen     — water / light / dew
//   gristle   — animal / drop / pelt
//   echo      — rare / strange / fae

export const MATERIAL_TIERS = [
  { key: 'raw',      label: 'Raw',      desc: 'Gathered from the world via forage, mining, fishing, or drops.' },
  { key: 'reagent',  label: 'Reagent',  desc: 'Single-input refinement of one raw material at a workstation.' },
  { key: 'ink',      label: 'Ink',      desc: 'Compound of three reagents. Color sets an orb\'s scope.' },
  { key: 'core',     label: 'Core',     desc: 'Concentrated single-flavor focus. Steers orb properties.' },
  { key: 'catalyst', label: 'Catalyst', desc: 'Found, not crafted. Each shifts one rolled orb property.' },
  { key: 'orb',      label: 'Orb',      desc: 'Final artefact. Slot into the Plinth to spawn a dungeon.' },
];

export const MATERIAL_GROUPS = [
  { key: 'verdant', label: 'Verdant', color: '#7a9656' },
  { key: 'earthen', label: 'Earthen', color: '#8a7250' },
  { key: 'lumen',   label: 'Lumen',   color: '#6a9cc8' },
  { key: 'gristle', label: 'Gristle', color: '#a8633a' },
  { key: 'echo',    label: 'Echo',    color: '#8a4a8a' },
];

// One row per material. `id` matches the items.js key.
export const MATERIAL_DEFS = [
  // ---------- Tier 1: RAW ----------
  // Verdant
  { id: 'wild_herb',      tier: 'raw', group: 'verdant', source: 'forage' },
  { id: 'foxglove_sprig', tier: 'raw', group: 'verdant', source: 'forage' },
  { id: 'wishrose',       tier: 'raw', group: 'verdant', source: 'forage' },
  { id: 'hedgecap',       tier: 'raw', group: 'verdant', source: 'forage' },
  { id: 'whitleberry',    tier: 'raw', group: 'verdant', source: 'forage' },
  { id: 'mosspepper',     tier: 'raw', group: 'verdant', source: 'forage' },
  // Earthen
  { id: 'mosswort_ore',   tier: 'raw', group: 'earthen', source: 'mine' },
  { id: 'palechalk_ore',  tier: 'raw', group: 'earthen', source: 'mine' },
  { id: 'bogiron_ore',    tier: 'raw', group: 'earthen', source: 'mine' },
  { id: 'coalrose',       tier: 'raw', group: 'earthen', source: 'mine' },
  { id: 'charcoal_stick', tier: 'raw', group: 'earthen', source: 'forage' },
  { id: 'river_clay',     tier: 'raw', group: 'earthen', source: 'mine' },
  // Lumen
  { id: 'pond_water',     tier: 'raw', group: 'lumen',   source: 'water' },
  { id: 'dewdrop',        tier: 'raw', group: 'lumen',   source: 'dawn' },
  // Gristle
  { id: 'whicker_pelt',   tier: 'raw', group: 'gristle', source: 'drop' },
  { id: 'wightpelt',      tier: 'raw', group: 'gristle', source: 'drop' },
  { id: 'tusker_tusk',    tier: 'raw', group: 'gristle', source: 'drop' },
  { id: 'wool_flank',     tier: 'raw', group: 'gristle', source: 'drop' },
  { id: 'downfeather',    tier: 'raw', group: 'gristle', source: 'drop' },
  // Echo
  { id: 'thorn_essence',  tier: 'raw', group: 'echo',    source: 'drop' },
  { id: 'bramble_resin',  tier: 'raw', group: 'echo',    source: 'forage' },
  { id: 'rivermud',       tier: 'raw', group: 'echo',    source: 'drop' },

  // ---------- Tier 2A: REAGENT ----------
  { id: 'crushed_herb',   tier: 'reagent', group: 'verdant', station: 'mortar',     refines: 'wild_herb' },
  { id: 'fox_dust',       tier: 'reagent', group: 'verdant', station: 'mortar',     refines: 'foxglove_sprig' },
  { id: 'rose_powder',    tier: 'reagent', group: 'verdant', station: 'mortar',     refines: 'wishrose' },
  { id: 'ore_powder',     tier: 'reagent', group: 'earthen', station: 'grindstone', refines: 'mosswort_ore' },
  { id: 'chalk_powder',   tier: 'reagent', group: 'earthen', station: 'grindstone', refines: 'palechalk_ore' },
  { id: 'iron_grit',      tier: 'reagent', group: 'earthen', station: 'grindstone', refines: 'bogiron_ore' },
  { id: 'ash_powder',     tier: 'reagent', group: 'earthen', station: 'kiln',       refines: 'charcoal_stick' },
  { id: 'fired_clay',     tier: 'reagent', group: 'earthen', station: 'kiln',       refines: 'river_clay' },
  { id: 'bottled_water',  tier: 'reagent', group: 'lumen',   station: 'vessel',     refines: 'pond_water' },
  { id: 'bottled_dew',    tier: 'reagent', group: 'lumen',   station: 'vessel',     refines: 'dewdrop' },
  { id: 'soft_leather',   tier: 'reagent', group: 'gristle', station: 'curing',     refines: 'whicker_pelt' },
  { id: 'wight_leather',  tier: 'reagent', group: 'gristle', station: 'curing',     refines: 'wightpelt' },

  // ---------- Tier 2B: INK ----------
  // Each ink is a compound of three reagents from one (or two) groups.
  // The orb forge reads the ink color to set the spawned dungeon's scope.
  { id: 'hedge_ink',       tier: 'ink', group: 'verdant', orbScope: 'briar_maze',
    inputs: { crushed_herb: 3 } },
  { id: 'stoneground_ink', tier: 'ink', group: 'earthen', orbScope: 'delve',
    inputs: { ore_powder: 2, ash_powder: 1 } },
  { id: 'wellspring_ink',  tier: 'ink', group: 'lumen',   orbScope: 'sunken_hut',
    inputs: { bottled_water: 2, rose_powder: 1 } },
  { id: 'bramblepress_ink',tier: 'ink', group: 'echo',    orbScope: 'briar_maze',
    inputs: { thorn_essence: 2, bramble_resin: 1 } },
  { id: 'refined_ink',     tier: 'ink', group: 'lumen',   orbScope: null,  // multi-scope booster
    inputs: { hedge_ink: 1, stoneground_ink: 1, wellspring_ink: 1 } },

  // ---------- Tier 2C: CORE ----------
  { id: 'bramble_core', tier: 'core', group: 'echo',    orbBias: 'bramble_bloom',
    inputs: { thorn_essence: 5 } },
  { id: 'resin_core',   tier: 'core', group: 'echo',    orbBias: 'herbal_patch',
    inputs: { bramble_resin: 5 } },
  { id: 'tusker_core',  tier: 'core', group: 'gristle', orbBias: 'mineral_vein',
    inputs: { tusker_tusk: 1, iron_grit: 2 } },
  { id: 'wight_core',   tier: 'core', group: 'gristle', orbBias: 'mineral_vein',
    inputs: { wightpelt: 1, ash_powder: 2 } },

  // ---------- Tier 3: CATALYST ----------
  { id: 'old_key',       tier: 'catalyst', group: 'echo',    catalystEffect: 'secret_room' },
  { id: 'fey_blossom',   tier: 'catalyst', group: 'verdant', catalystEffect: 'tier_up_one_property' },
  { id: 'owl_feather',   tier: 'catalyst', group: 'gristle', catalystEffect: 'night_modifier' },
  { id: 'cracked_tile',  tier: 'catalyst', group: 'earthen', catalystEffect: 'decay_modifier' },
  { id: 'sealed_letter', tier: 'catalyst', group: 'echo',    catalystEffect: 'memory_vignette_room' },
  { id: 'hags_tooth',    tier: 'catalyst', group: 'gristle', catalystEffect: 'force_boss_tier' },
  { id: 'glass_shard',   tier: 'catalyst', group: 'earthen', catalystEffect: 'reroll_one_property' },

  // ---------- Tier 4: ORB ----------
  { id: 'chart_blank',      tier: 'orb', group: 'lumen',   orbScope: null },
  { id: 'chart_tier_1',     tier: 'orb', group: 'lumen',   orbScope: 'hollow' },
  { id: 'chart_snug',       tier: 'orb', group: 'verdant', orbScope: 'snug' },
  { id: 'chart_hollow',     tier: 'orb', group: 'echo',    orbScope: 'hollow' },
  { id: 'chart_briar_maze', tier: 'orb', group: 'verdant', orbScope: 'briar_maze' },
  { id: 'chart_sunken_hut', tier: 'orb', group: 'lumen',   orbScope: 'sunken_hut' },
  { id: 'chart_delve',      tier: 'orb', group: 'earthen', orbScope: 'delve' },
];

/** Look up a single material def by id. Returns null if not found. */
export function materialDef(id) {
  for (const m of MATERIAL_DEFS) if (m.id === id) return m;
  return null;
}

/** Find the recipe(s) that produce `id` (i.e. `id` appears as `refines`
 *  target on a reagent, or as a key in any compound's `inputs`). Useful
 *  for the codex tooltip that shows "what makes this." */
export function recipesProducing(id) {
  const out = [];
  for (const m of MATERIAL_DEFS) {
    if (m.refines === id || m.id === id && m.inputs) {
      // (We also treat the entry itself if it has inputs as a "recipe.")
      if (m.id === id && m.inputs) out.push({ kind: m.tier, output: m.id, inputs: m.inputs });
    }
  }
  // For id == reagent target, find which reagent refines from it
  for (const m of MATERIAL_DEFS) {
    if (m.tier === 'reagent' && m.refines === id) {
      out.push({ kind: 'refine', output: m.id, inputs: { [id]: 1 }, station: m.station });
    }
  }
  return out;
}
