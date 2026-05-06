// Cooking recipes — fired on a campfire / hearth tile. Engine-side
// `tryCook()` in main.js currently only handles raw_brindle; this data
// is the canonical ladder for every cookable item, surfaced in the
// codex Recipes tab and consumed once the cook handler is generalized.
//
// Fields:
//   input    — raw item id consumed
//   output   — cooked item id produced
//   burnt    — charred fallback item id (rolled on burn)
//   xp       — cook XP on success
//   xpBurn   — cook XP on burn (smaller; learning)
//   cd       — cooldown in frames (~60 fps)
//   reqLevel — cooking level required (omitted = level 1)
//   burnBase — base burn chance at level 1 (decays with skill)
//   label    — display string

export const COOK_RECIPES = {
  cook_beef: {
    input: 'raw_brindle', output: 'brindle_roast', burnt: 'charred_brindle',
    xp: 24, xpBurn: 4, cd: 60, burnBase: 0.40,
    label: 'Cook Beef (Brindle Roast)',
  },
  cook_pippin: {
    input: 'raw_pippin', output: 'pippin_spit', burnt: 'charred_pippin',
    xp: 16, xpBurn: 3, cd: 50, burnBase: 0.25,
    label: 'Cook Pippin Spit',
  },
  cook_whicker: {
    input: 'raw_whicker', output: 'whicker_stew', burnt: 'charred_whicker',
    xp: 22, xpBurn: 4, cd: 60, reqLevel: 5, burnBase: 0.35,
    label: 'Cook Whicker Stew',
  },
  cook_sardine: {
    input: 'raw_sardine', output: 'cooked_sardine', burnt: 'burnt_sardine',
    xp: 14, xpBurn: 3, cd: 45, burnBase: 0.30,
    label: 'Cook Sardine',
  },
  cook_tusker: {
    input: 'raw_tusker', output: 'tusker_crackling', burnt: 'charred_tusker',
    xp: 36, xpBurn: 6, cd: 80, reqLevel: 12, burnBase: 0.40,
    label: 'Cook Tusker Crackling',
  },
  cook_hedgewight: {
    input: 'raw_hedgewight', output: 'hedgewight_strip', burnt: 'charred_hedgewight',
    xp: 48, xpBurn: 8, cd: 90, reqLevel: 18, burnBase: 0.45,
    label: 'Cook Hedgewight Strip',
  },
  // Multi-ingredient signature dishes (commissioned by NPCs / quest-gift).
  // Treated as "compound" recipes — engine wiring will read the inputs
  // map rather than the single `input` field.
  cook_pantry_stew: {
    inputs: { raw_brindle: 1, hedgecap: 2, whitleberry: 1, mosspepper: 1 },
    output: 'pantry_stew', xp: 120, cd: 180, reqLevel: 10, burnBase: 0.10,
    label: "Cook Maud's Pantry Stew",
  },
};
