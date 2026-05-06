// Inscribing-table recipe data. See docs/cartography-inscribing-table-design.md.
//
// A recipe is a 3×3 pattern. Each cell is either:
//   null               — must be empty for the recipe to match
//   { ess, tier }      — must hold an item of that essence + tier
//   { id }             — must hold this exact item id (rare, "preferred" reagents)
//
// Multiple ingredient items can satisfy { ess, tier }. The lookup table below
// maps already-existing item ids to their essence/tier so recipe-matching
// works without modifying every entry in src/data/items.js.

// ---- Essence map for existing items ----
// Items in items.js with native `essence` + `tier` fields don't need to be
// repeated here. This catches the legacy items that pre-date this system.
export const ESSENCE_OVERRIDES = {
  raw_mushroom:    { essence: 'verdant',  tier: 1 },
  bramble_resin:   { essence: 'verdant',  tier: 1 },
  downfeather:     { essence: 'verdant',  tier: 2 },
  charcoal_stick:  { essence: 'earthen',  tier: 1 },
  logs:            { essence: 'earthen',  tier: 1 },
  bogiron_ore:     { essence: 'earthen',  tier: 2 },
  thorn_essence:   { essence: 'sanguine', tier: 1 },
  boar_tusk:       { essence: 'sanguine', tier: 2 },
  wightpelt:       { essence: 'sanguine', tier: 2 },
  whickerhares_foot:{essence: 'sanguine', tier: 3 },
  hedge_ink:       { essence: 'ink',      tier: 1 },
  refined_ink:     { essence: 'ink',      tier: 2 },
  bog_ink:         { essence: 'ink',      tier: 2 },
  ember_ink:       { essence: 'ink',      tier: 2 },
  lustrous_ink:    { essence: 'ink',      tier: 2 },
  charcoal_bind:   { essence: 'ink',      tier: 1 },
  stoneground_ink: { essence: 'ink',      tier: 1 },
  bramblepress_ink:{ essence: 'ink',      tier: 1 },
  wellspring_ink:  { essence: 'ink',      tier: 1 },
  forge_brand_ink: { essence: 'ink',      tier: 3 },
  aurora_ink:      { essence: 'ink',      tier: 3 },
  tidewater_ink:   { essence: 'ink',      tier: 3 },
};

/** Resolve essence + tier for an item id. Falls back to the item def's own
 *  essence/tier fields if no override is set. */
export function essenceOf(itemId, ITEMS) {
  if (ESSENCE_OVERRIDES[itemId]) return ESSENCE_OVERRIDES[itemId];
  const def = ITEMS[itemId];
  if (def?.essence) return { essence: def.essence, tier: def.tier ?? 1 };
  return null;
}

// ---- Pattern shorthands ----
const _ = null;
function vert(ess, tier)  { return [[_, {ess,tier}, _], [_, {ess,tier}, _], [_, {ess,tier}, _]]; }
function tcross(c, arm)   { return [[arm, arm, arm], [_, c, _], [_, c, _]]; }
function plus(c, arm)     { return [[_, arm, _], [arm, c, arm], [_, arm, _]]; }
function xCorners(c, arm) { return [[arm, _, arm], [_, c, _], [arm, _, arm]]; }
function singleton(c)     { return [[_, _, _], [_, c, _], [_, _, _]]; }

// ---- Recipe table ----
// Each entry: { id, name, tier (recipe tier 1-3), pattern, output, bias,
// reqCarto, xpFirst, xpRepeat, desc, rotationInvariant, hint }

/** @type {InkRecipe[]} */
export const INK_RECIPES = [
  // ----------- Tier 1 (Common) -----------
  {
    id: 'hedge_ink',
    name: 'Hedge Ink',
    tier: 1,
    pattern: vert('verdant', 1),
    output: { id: 'hedge_ink', qty: 1 },
    bias: {},                              // baseline; no special bias
    reqCarto: 1,
    xpFirst: 50, xpRepeat: 5,
    rotationInvariant: true,
    hint: 'Pressed from three of the same green essence in a steady column.',
    desc: 'A vial of green-black ink pressed from bramble pulp. Stains anything it touches.',
  },
  {
    id: 'stoneground_ink',
    name: 'Stoneground Ink',
    tier: 1,
    pattern: vert('earthen', 1),
    output: { id: 'stoneground_ink', qty: 1 },
    bias: { mineral_vein: 1.30 },
    reqCarto: 4,
    xpFirst: 75, xpRepeat: 7,
    rotationInvariant: true,
    hint: 'Hod said the smith\'s grit makes the heaviest line.',
    desc: 'A flat grey ink ground from ore dust. Settles thick and reads even on damp vellum.',
  },
  {
    id: 'bramblepress_ink',
    name: 'Bramblepress Ink',
    tier: 1,
    pattern: vert('sanguine', 1),
    output: { id: 'bramblepress_ink', qty: 1 },
    bias: { tyrannical: 1.30 },
    reqCarto: 6,
    xpFirst: 75, xpRepeat: 7,
    rotationInvariant: true,
    hint: 'A thorny line of like-from-like, pressed under weight.',
    desc: 'A red-black ink that smells faintly of iron. Quivers when first applied.',
  },
  {
    id: 'wellspring_ink',
    name: 'Wellspring Ink',
    tier: 1,
    pattern: vert('lumen', 1),
    output: { id: 'wellspring_ink', qty: 1 },
    bias: { bramble_bloom: 1.30 },
    reqCarto: 8,
    xpFirst: 80, xpRepeat: 8,
    rotationInvariant: true,
    hint: 'Three drops of the same clear water, drawn out like a thread.',
    desc: 'A pale blue ink that holds shimmer. Used for charts that should bloom.',
  },
  {
    id: 'charcoal_bind',
    name: 'Charcoal Bind',
    tier: 1,
    pattern: singleton({ id: 'charcoal_stick' }),
    output: { id: 'charcoal_bind', qty: 1 },
    bias: { _stability: 0.05 },            // +5% stability on every roll
    reqCarto: 1,
    xpFirst: 25, xpRepeat: 3,
    rotationInvariant: true,
    hint: 'A single charcoal stub at the heart, untouched by anything else.',
    desc: 'A pinch of pure charcoal binding. Steadies the line of any ink it joins.',
  },

  // ----------- Tier 2 (Refined) -----------
  {
    id: 'refined_ink',
    name: 'Refined Ink',
    tier: 2,
    // T-shape: top row of earthen T2 + middle column down. Player needs
    // 3 ore_dust (earthen T1 if no T2 yet) + 1 hedge_ink in center.
    pattern: [
      [{ess:'earthen',tier:1}, {ess:'earthen',tier:1}, {ess:'earthen',tier:1}],
      [_,                       {id:'hedge_ink'},      _                      ],
      [_,                       {ess:'earthen',tier:1},_                      ],
    ],
    output: { id: 'refined_ink', qty: 1 },
    bias: { _stability: 0.05 },
    reqCarto: 12,
    xpFirst: 100, xpRepeat: 12,
    rotationInvariant: true,
    hint: 'A T of stone-grit pressed down into a heart of hedge.',
    desc: 'A grey-black ink steadied with mineral grit. Locks an extra step of confidence into every chart.',
  },
  {
    id: 'bog_ink',
    name: 'Bog Ink',
    tier: 2,
    // Cross (+): lumen center, verdant arms.
    pattern: plus({ess:'lumen',tier:1}, {ess:'verdant',tier:1}),
    output: { id: 'bog_ink', qty: 1 },
    bias: { fog_of_hedge: 1.30, bramble_bloom: 1.30 },
    reqCarto: 16,
    xpFirst: 120, xpRepeat: 14,
    rotationInvariant: true,
    hint: 'A drop of still water at the heart, leaves at every cardinal arm.',
    desc: 'A pale blue ink with a faint shimmer. Coaxes fog and bloom in equal measure.',
  },
  {
    id: 'ember_ink',
    name: 'Ember Ink',
    tier: 2,
    // X-corners: 4 sanguine corners + 1 charcoal center.
    pattern: xCorners({id:'charcoal_stick'}, {ess:'sanguine',tier:1}),
    output: { id: 'ember_ink', qty: 1 },
    bias: { tyrannical: 1.30, bursting: 1.30 },
    reqCarto: 28,
    xpFirst: 160, xpRepeat: 18,
    rotationInvariant: true,
    hint: 'Four red corners pinned around a single coal.',
    desc: 'A red-orange ink that holds a warmth long after the press. Pushes enemies fierce.',
  },
  {
    id: 'lustrous_ink',
    name: 'Lustrous Ink',
    tier: 2,
    // Cross (+): refined ink center, ore_dust arms.
    pattern: plus({id:'refined_ink'}, {id:'ore_dust'}),
    output: { id: 'lustrous_ink', qty: 1 },
    bias: { mineral_vein: 1.30, gilded_seam: 1.10, gem_seam: 1.10 },
    reqCarto: 18,
    xpFirst: 140, xpRepeat: 16,
    rotationInvariant: true,
    hint: 'Refined ink at the heart, four points of ore-dust radiating.',
    desc: 'A grey ink shot through with golden flecks. Pulls metal from the rooms.',
  },

  // ----------- Tier 3 (Vessel-bound) -----------
  // Each requires a vessel slotted alongside the 3×3 grid. Vessels are
  // crafted by NPCs (Hod / Quill / Cricket) and consumed on inscribe.
  {
    id: 'forge_brand_ink',
    name: 'Forge-Brand Ink',
    tier: 3,
    // X-corners: 4 sanguine corners + ember ink center.
    pattern: xCorners({id:'ember_ink'}, {ess:'sanguine',tier:1}),
    vessel: 'clay_flask',
    output: { id: 'forge_brand_ink', qty: 1 },
    bias: { tyrannical: 1.50, bursting: 1.30, _stability: 0.10 },
    reqCarto: 32,
    xpFirst: 220, xpRepeat: 24,
    rotationInvariant: true,
    hint: "Sanguine corners around an ember heart, sealed in Hod's clay.",
    desc: 'A red-black ink that shimmers with heat. Forces a sharp, tyrannical line.',
  },
  {
    id: 'aurora_ink',
    name: 'Aurora Ink',
    tier: 3,
    // Plus: bog_ink center, verdant tier-2 arms.
    pattern: plus({id:'bog_ink'}, {ess:'verdant',tier:2}),
    vessel: 'bound_parchment',
    output: { id: 'aurora_ink', qty: 1 },
    bias: { bramble_bloom: 1.50, fog_of_hedge: 1.30, _stability: 0.10 },
    reqCarto: 36,
    xpFirst: 240, xpRepeat: 26,
    rotationInvariant: true,
    hint: "Bog at the heart, mid-tier verdant arms, bound in Quill's parchment.",
    desc: 'A green-gold ink that shifts when held to the light. Coaxes the bloom that hides the line.',
  },
  {
    id: 'tidewater_ink',
    name: 'Tidewater Ink',
    tier: 3,
    // Plus: lustrous_ink center, lumen tier-1 arms.
    pattern: plus({id:'lustrous_ink'}, {ess:'lumen',tier:1}),
    vessel: 'glass_vial',
    output: { id: 'tidewater_ink', qty: 1 },
    bias: { mineral_vein: 1.30, gilded_seam: 1.30, bramble_bloom: 1.20, _stability: 0.10 },
    reqCarto: 40,
    xpFirst: 260, xpRepeat: 28,
    rotationInvariant: true,
    hint: "Lustrous at the heart, lumen drops at every cardinal arm, sealed in Cricket's glass.",
    desc: 'A clear ink with a slow inner light. Strokes pull metal and bloom in equal measure.',
  },
];

/**
 * Match the player's current 3×3 grid against the recipe table.
 * `grid` is a 3×3 array of either null (empty) or { id } objects pointing at
 * an inventory item id. ITEMS is the items.js dict (passed in to keep this
 * file pure-data).
 *
 * `vesselId` is the id of the item slotted in the vessel slot (or null).
 * Recipes that declare `vessel: '<id>'` only match when that exact vessel
 * is provided. Recipes without a `vessel` field match either with or
 * without a vessel — the slot is "informational" in that case.
 *
 * Returns:
 *   { match: recipe }                     — exact named recipe matched
 *   { match: null, ingredients: [...] }   — no recipe; for the smudge / wild path
 */
export function matchRecipe(grid, ITEMS, vesselId = null) {
  const flat = grid.flat();
  if (flat.every(c => c == null)) return { match: null, ingredients: [] };

  for (const recipe of INK_RECIPES) {
    // Vessel gate: tier-3 recipes require an exact vessel match. Skip
    // recipes whose vessel requirement isn't met; fall through to wild/
    // smudge if nothing else matches.
    if (recipe.vessel && recipe.vessel !== vesselId) continue;
    if (gridMatches(grid, recipe.pattern, ITEMS)) return { match: recipe };
    if (recipe.rotationInvariant) {
      let p = recipe.pattern;
      for (let r = 0; r < 3; r++) {
        p = rotate90(p);
        if (gridMatches(grid, p, ITEMS)) return { match: recipe };
      }
    }
  }
  const ingredients = flat.filter(Boolean).map(c => c.id);
  return { match: null, ingredients };
}

function gridMatches(grid, pattern, ITEMS) {
  for (let y = 0; y < 3; y++) {
    for (let x = 0; x < 3; x++) {
      const cell = grid[y][x];
      const want = pattern[y][x];
      if (want == null) {
        if (cell != null) return false;
        continue;
      }
      if (cell == null) return false;
      if (want.id) {
        if (cell.id !== want.id) return false;
      } else if (want.ess) {
        const e = essenceOf(cell.id, ITEMS);
        if (!e) return false;
        if (e.essence !== want.ess) return false;
        if (e.tier < (want.tier ?? 1)) return false;
      }
    }
  }
  return true;
}

function rotate90(p) {
  return [
    [p[2][0], p[1][0], p[0][0]],
    [p[2][1], p[1][1], p[0][1]],
    [p[2][2], p[1][2], p[0][2]],
  ];
}
