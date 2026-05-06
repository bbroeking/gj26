// Orb-forge recipes. Each entry combines inks (color sets scope) +
// optional core (bias) + optional catalyst (steers a property roll) +
// 1× hollow_orb (chart_blank) → a scoped orb (chart_<scope>).
//
// Forged at the Plinth in Bramblewood. Engine wiring (a generalized
// orb-forge handler that walks this table) is a follow-up; today this
// is the data surface the codex shows so designers can balance.
//
// Fields:
//   inks       — { itemId: count } map of ink ingredients (color majority sets scope)
//   core       — optional core item id; biases one rolled property
//   catalyst   — optional catalyst item id; shifts one rolled property
//   blank      — required orb-blank input (count = 1 always)
//   output     — final orb item id
//   xp         — wayfinding XP awarded on forge
//   reqLevel   — wayfinding level gate
//   label      — display string
//   rolls      — array of rollable property names (e.g. ['mineral_vein'])
//                so the forge knows what spectrum to roll. Each rolled
//                property lands at thin/normal/rich/mother_lode.

export const ORB_RECIPES = {
  forge_orb_briar: {
    inks: { hedge_ink: 2 },
    core: 'bramble_core',
    blank: 'chart_blank',
    output: 'chart_briar_maze',
    xp: 80, reqLevel: 4,
    rolls: ['bramble_bloom'],
    label: 'Forge Briar Orb',
  },
  forge_orb_briar_glory: {
    inks: { hedge_ink: 2, bramblepress_ink: 1 },
    core: 'bramble_core',
    catalyst: 'fey_blossom',
    blank: 'chart_blank',
    output: 'chart_briar_maze',
    xp: 160, reqLevel: 12,
    rolls: ['bramble_bloom', 'herbal_patch'],
    label: 'Forge Briar Orb (Bloomed)',
  },
  forge_orb_delve: {
    inks: { stoneground_ink: 2 },
    core: 'tusker_core',
    blank: 'chart_blank',
    output: 'chart_delve',
    xp: 120, reqLevel: 8,
    rolls: ['mineral_vein'],
    label: 'Forge Delve Orb',
  },
  forge_orb_delve_rich: {
    inks: { stoneground_ink: 3 },
    core: 'wight_core',
    catalyst: 'old_key',
    blank: 'chart_blank',
    output: 'chart_delve',
    xp: 240, reqLevel: 16,
    rolls: ['mineral_vein', 'gem_seam', 'gilded_seam'],
    label: 'Forge Delve Orb (Veined)',
  },
  forge_orb_sunken: {
    inks: { wellspring_ink: 2 },
    core: 'tusker_core',
    blank: 'chart_blank',
    output: 'chart_sunken_hut',
    xp: 100, reqLevel: 6,
    rolls: ['herbal_patch'],
    label: 'Forge Sunken Hut Orb',
  },
  forge_orb_hollow: {
    inks: { hedge_ink: 1, stoneground_ink: 1, wellspring_ink: 1 },
    blank: 'chart_blank',
    output: 'chart_hollow',
    xp: 60, reqLevel: 1,
    rolls: ['mineral_vein', 'bramble_bloom'],
    label: 'Forge Hollow Orb',
  },
  forge_orb_hollow_owl: {
    inks: { hedge_ink: 1, stoneground_ink: 1 },
    catalyst: 'owl_feather',
    blank: 'chart_blank',
    output: 'chart_hollow',
    xp: 120, reqLevel: 10,
    rolls: ['mineral_vein', 'bramble_bloom'],
    label: 'Forge Hollow Orb (Night)',
  },
  forge_orb_snug: {
    inks: { hedge_ink: 1 },
    blank: 'chart_blank',
    output: 'chart_snug',
    xp: 30, reqLevel: 1,
    rolls: ['bramble_bloom'],
    label: 'Forge Hearth Orb',
  },
  forge_orb_boss: {
    inks: { bramblepress_ink: 2, refined_ink: 1 },
    core: 'wight_core',
    catalyst: 'hags_tooth',
    blank: 'chart_blank',
    output: 'chart_briar_maze',  // boss flag set via catalyst
    xp: 480, reqLevel: 20,
    rolls: ['bramble_bloom', 'mineral_vein'],
    label: 'Forge Hag-Toothed Orb (Boss)',
  },
};
