export const ITEMS = {
  raw_brindle:    { name: 'Raw Brindle',    icon: '🥩', stack: true,
    desc: 'A slab of raw beef. Cook it on a fire to make it edible.' },
  brindle_roast: { name: 'Brindle Roast', icon: '🍖', stack: true, food: { heal: 5 },
    desc: 'A nicely cooked piece of beef. Heals 5 HP when eaten.' },
  charred_brindle:  { name: 'Charred Brindle',  icon: '⬛', stack: true,
    desc: 'You burnt it. Inedible.' },
  wool_flank:     { name: 'Wool Flank',     icon: '🟫', stack: true,
    desc: 'A panel of brindle wool-flank. Useful for crafting leather goods.' },
  brindle_sword: {
    name: 'Brindle Sword', icon: '🗡', stack: false,
    slot: 'weapon', equipBonus: { atk: 1, str: 2, def: 0 },
    weaponClass: 'sword', cdMul: 1.0, dmgMul: 1.0,
    desc: 'A sturdy brindle-alloy sword. +1 Attack, +2 Strength.',
  },
  leather_body: {
    name: 'Leather Body', icon: '🦺', stack: false,
    slot: 'body', equipBonus: { atk: 0, str: 0, def: 2 },
    desc: 'A leather chest piece. +2 Defence.',
  },
  wooden_shield: {
    name: 'Wooden Shield', icon: '🛡', stack: false,
    slot: 'shield', equipBonus: { atk: 0, str: 0, def: 1 },
    desc: 'A simple wooden shield. +1 Defence.',
  },

  // ---- gathering tools ----
  brindle_axe: {
    name: 'Brindle Axe', icon: '🪓', stack: false,
    tool: 'axe',
    desc: 'A brindle-alloy axe for felling trees.',
  },
  brindle_pickaxe: {
    name: 'Brindle Pickaxe', icon: '⛏', stack: false,
    tool: 'pickaxe',
    desc: 'A brindle-alloy pickaxe for mining ore.',
  },
  fishing_rod: {
    name: 'Fishing Rod', icon: '🎣', stack: false,
    tool: 'rod',
    desc: 'A wooden rod for fishing in still waters.',
  },

  // ---- gathered raw materials ----
  logs: { name: 'Logs', icon: '🪵', stack: true,
    desc: 'Oak logs. Burn for fuel, refine for planks.' },
  whitleberry: { name: 'Whitleberry', icon: '🫐', stack: true, food: { heal: 1 },
    desc: 'A handful of foraged berries. Heals 1 HP.' },
  hedgecap: { name: 'Hedgecap', icon: '🍄', stack: true,
    desc: 'A bright red mushroom. Edible? Try at your own risk.' },
  wishrose: { name: 'Wishrose', icon: '🌿', stack: true,
    desc: 'A common wild herb. Useful for brewing.' },
  raw_sardine: { name: 'Raw Sardine', icon: '🐟', stack: true,
    desc: 'A small raw fish. Cook it for a snack.' },
  mosswort_ore: { name: 'Mosswort Ore', icon: '🟤', stack: true,
    desc: 'Soft mossy-green ore. Alloys with palechalk into brindle.' },
  palechalk_ore: { name: 'Palechalk Ore', icon: '⬜', stack: true,
    desc: 'White-grey chalkstone. Alloys with mosswort into brindle.' },
  brindle_bar: { name: 'Brindle Bar', icon: '🟧', stack: true,
    desc: 'A smelted brindle bar. Can be smithed.' },
  brindle_dagger: {
    name: 'Brindle Dagger', icon: '🗡', stack: false,
    slot: 'weapon', equipBonus: { atk: 2, str: 1, def: 0 },
    weaponClass: 'dagger', cdMul: 0.75, dmgMul: 0.80,
    desc: 'A smithed brindle-alloy dagger. +2 Attack, +1 Strength. Faster swings, lower damage.',
  },
  cooked_sardine: { name: 'Cooked Sardine', icon: '🐠', stack: true, food: { heal: 3 },
    desc: 'A cooked sardine. Heals 3 HP.' },
  burnt_sardine: { name: 'Burnt Sardine', icon: '⬛', stack: true,
    desc: 'You burnt it.' },

  // ---- chicken drops (Bramblewood farmstead critter) ----
  raw_pippin:    { name: 'Raw Pippin',    icon: '🍗', stack: true,
    desc: 'A plump chicken, plucked. Cook it on a fire.' },
  pippin_spit: { name: 'Pippin Spit', icon: '🍗', stack: true, food: { heal: 4 },
    desc: 'A cooked chicken. Heals 4 HP.' },
  charred_pippin:  { name: 'Charred Pippin',  icon: '⬛', stack: true,
    desc: 'Charcoal in the shape of a bird.' },
  downfeather:        { name: 'Downfeather',        icon: '🪶', stack: true,
    desc: 'A soft white downfeather. Useful for fletching.' },

  // ---- hare drops ----
  raw_whicker:    { name: 'Raw Whicker',    icon: '🐰', stack: true,
    desc: 'A field-dressed hare. Cook it on a fire.' },
  whicker_stew: { name: 'Whicker Stew', icon: '🍖', stack: true, food: { heal: 4 },
    desc: 'A cooked hare. Heals 4 HP. Lean meat, good for the road.' },
  charred_whicker:  { name: 'Charred Whicker',  icon: '⬛', stack: true,
    desc: 'You burnt it.' },
  whicker_pelt:   { name: 'Whicker Pelt',   icon: '🟫', stack: true,
    desc: 'A soft hare pelt. Could be tanned for trim work.' },

  // ---- bramble-cap drops (mid-tier bramble-imp variant) ----
  thorn_essence: { name: 'Thorn Essence', icon: '🟢', stack: true,
    desc: 'A globule of green sap from a bramble-cap. Faintly hums.' },

  // ---- Wild boar drops ----
  raw_tusker: { name: 'Raw Tusker', icon: '🥩', stack: true,
    desc: 'A heavy cut of wild boar. Cook it on a fire — slowly.' },
  tusker_crackling: { name: 'Tusker Crackling', icon: '🍖', stack: true, food: { heal: 7 },
    desc: 'Slow-roasted wild boar. Restores 7 HP. Smoky, faintly bitter.',
    reqSkill: 'cook', reqLevel: 15 },
  charred_tusker: { name: 'Charred Tusker', icon: '⬛', stack: true,
    desc: 'Charred to leather.' },
  tusker_tusk: { name: 'Tusker Tusk', icon: '🦷', stack: true,
    desc: 'A curved yellow tusk. Useful for tools, charms, or starting fights.' },

  // ============================================================
  // IRON TIER — level 15-30. Weapon budget 6 (atk+str). Body 4. Shield 2.
  // ============================================================
  bogiron_ore: {
    name: 'Bogiron Ore', icon: '🟫', stack: true,
    desc: 'Heavier than mosswort, with a dull red rust where it sat in damp earth.',
    source:  { skill: 'earth',  level: 15 },
    refines: { skill: 'earth', level: 15, into: 'bogiron_bar' },
  },
  bogiron_bar: {
    name: 'Bogiron Bar', icon: '⬛', stack: true,
    desc: 'A black-grey ingot, smelted clean. The weight settles into your hand.',
  },
  bogiron_sword: {
    name: 'Bogiron Sword', icon: '🗡', stack: false,
    slot: 'weapon',
    equipBonus: { atk: 2, str: 4, def: 0 },
    weaponClass: 'sword', cdMul: 1.0, dmgMul: 1.0,
    reqSkill: 'atk', reqLevel: 15,
    tier: 'iron',
    desc: 'A workmanlike blade. The hilt is wrapped in someone else\'s leather.',
  },
  bogiron_dagger: {
    name: 'Bogiron Dagger', icon: '🗡', stack: false,
    slot: 'weapon',
    equipBonus: { atk: 4, str: 2, def: 0 },
    weaponClass: 'dagger', cdMul: 0.75, dmgMul: 0.80,
    reqSkill: 'atk', reqLevel: 15,
    tier: 'iron',
    desc: 'Short and quick, favoured by hedge-walkers and orchard-thieves.',
  },
  bogiron_axe: {
    name: 'Bogiron Axe', icon: '🪓', stack: false,
    tool: 'axe',
    reqSkill: 'wilds', reqLevel: 15,
    tier: 'iron',
    desc: 'Cuts oak twice as quick as brindle. The grip smells of pine sap.',
  },
  bogiron_pickaxe: {
    name: 'Bogiron Pickaxe', icon: '⛏', stack: false,
    tool: 'pickaxe',
    reqSkill: 'earth', reqLevel: 15,
    tier: 'iron',
    desc: 'A blunt iron head set into ash. Strikes harder than it looks.',
  },
  bogiron_cuirass: {
    name: 'Bogiron Cuirass', icon: '🦺', stack: false,
    slot: 'body',
    equipBonus: { atk: 0, str: 0, def: 4 },
    reqSkill: 'def', reqLevel: 15,
    tier: 'iron',
    desc: 'A hammered iron breastplate. Heavier than it looks; warmer in winter than you\'d expect.',
  },
  bogiron_shield: {
    name: 'Bogiron Shield', icon: '🛡', stack: false,
    slot: 'shield',
    equipBonus: { atk: 0, str: 0, def: 2 },
    reqSkill: 'def', reqLevel: 15,
    tier: 'iron',
    desc: 'Plain ironwork on a wooden core. Dented in three places already.',
  },

  // ---- Hedge wolf drops ----
  raw_hedgewight:    { name: 'Raw Hedgewight', icon: '🥩', stack: true,
    desc: 'Stringy and dark. Cook it well or risk the fever.' },
  hedgewight_strip: { name: 'Hedgewight Strip', icon: '🍖', stack: true, food: { heal: 9 },
    desc: 'Stringy but filling. Restores 9 HP. Tastes faintly of pine.',
    reqSkill: 'cook', reqLevel: 25 },
  charred_hedgewight:  { name: 'Charred Hedgewight', icon: '⬛', stack: true,
    desc: 'You over-cooked it. Smells worse than the live one.' },
  wightpelt:   { name: 'Wightpelt', icon: '🟫', stack: true,
    desc: 'Coarse grey fur, still smelling of the hedge. Warm in winter.' },

  // ============================================================
  // STEEL TIER — level 30-45. Weapon budget 9 (atk+str). Body 6. Shield 3. Helm 3.
  // Smelting: 1 bogiron_ore + 2 coalrose → 1 cinderbloom_bar at smithing 30.
  // ============================================================
  coalrose: {
    name: 'Coalrose', icon: '⬛', stack: true,
    desc: 'Black and brittle. Burns hotter than wood — needed to forge steel.',
    source: { skill: 'earth', level: 25 },
  },
  cinderbloom_bar: {
    name: 'Cinderbloom Bar', icon: '⬜', stack: true,
    desc: 'Mottled grey, struck cold to test the ring. Twice the work of iron.',
  },
  cinderbloom_sword: {
    name: 'Cinderbloom Sword', icon: '🗡', stack: false,
    slot: 'weapon',
    equipBonus: { atk: 3, str: 6, def: 0 },
    weaponClass: 'sword', cdMul: 1.0, dmgMul: 1.0,
    reqSkill: 'atk', reqLevel: 30,
    tier: 'steel',
    desc: 'A long, balanced blade. The crossguard is etched with someone\'s initials, badly.',
  },
  cinderbloom_dagger: {
    name: 'Cinderbloom Dagger', icon: '🗡', stack: false,
    slot: 'weapon',
    equipBonus: { atk: 6, str: 3, def: 0 },
    weaponClass: 'dagger', cdMul: 0.75, dmgMul: 0.80,
    reqSkill: 'atk', reqLevel: 30,
    tier: 'steel',
    desc: 'Quick steel, half the weight of an iron blade. Slips through coats.',
  },
  cinderbloom_axe: {
    name: 'Cinderbloom Axe', icon: '🪓', stack: false,
    tool: 'axe',
    reqSkill: 'wilds', reqLevel: 30,
    tier: 'steel',
    desc: 'A keen edge. Fells a yew in fewer strokes than any iron axe.',
  },
  cinderbloom_pickaxe: {
    name: 'Cinderbloom Pickaxe', icon: '⛏', stack: false,
    tool: 'pickaxe',
    reqSkill: 'earth', reqLevel: 30,
    tier: 'steel',
    desc: 'Heavy steel head, ash haft. Bites coal seams without complaint.',
  },
  cinderbloom_plate: {
    name: 'Cinderbloom Plate', icon: '🦺', stack: false,
    slot: 'body',
    equipBonus: { atk: 0, str: 0, def: 6 },
    reqSkill: 'def', reqLevel: 30,
    tier: 'steel',
    desc: 'A proper plate, fitted at the shoulder. Squeaks when you breathe deep.',
  },
  cinderbloom_shield: {
    name: 'Cinderbloom Shield', icon: '🛡', stack: false,
    slot: 'shield',
    equipBonus: { atk: 0, str: 0, def: 3 },
    reqSkill: 'def', reqLevel: 30,
    tier: 'steel',
    desc: 'A round steel-bound shield with a bronze boss. Heavier than it looks.',
  },
  // ============================================================
  // CHARTS — Bramblewood Charters dungeon system. Each chart is a
  // single-use map item that opens a procedural dungeon. Tier gates
  // by Wayfinding level. Affixes come post-V1.
  // ============================================================
  // ============================================================
  // CARTOGRAPHY — the map-making craft. See docs/cartography-skill-design.md
  // ============================================================
  field_journal: {
    name: 'Field Journal', icon: '📓', stack: false,
    desc: 'A leather-bound notebook for sketches. Cannot be dropped — every cartographer carries one.',
    bound: true,
  },
  // ---- Inscribing-table reagents (essence + tier; recipes in inkRecipes.js) ----
  wild_herb: {
    name: 'Wild Herb', icon: '🌿', stack: true,
    desc: 'A clipped sprig of meadow herb. Faint green smell.',
    essence: 'verdant', tier: 1,
  },
  mossvine: {
    name: 'Mossvine', icon: '🪴', stack: true,
    desc: 'A coiled vine that grows where stone meets water. Pliant, slightly bitter to taste.',
    essence: 'verdant', tier: 2,
  },
  pond_water: {
    name: 'Pond Water', icon: '💧', stack: true,
    desc: 'A dipped flask of still water. Holds a sky-image when calm.',
    essence: 'lumen', tier: 1,
  },
  rivermud: {
    name: 'Rivermud', icon: '🟫', stack: true,
    desc: 'Wet clay scooped from a sand bank. Smells of root and rain.',
    essence: 'lumen', tier: 1,
  },
  ore_dust: {
    name: 'Ore Dust', icon: '🟤', stack: true,
    desc: 'Smithing scrap — heavy iron-grit that catches the light.',
    essence: 'earthen', tier: 1,
  },
  salt_chip: {
    name: 'Salt Chip', icon: '🧂', stack: true,
    desc: 'A flake of rock salt prised from a cave wall. Brittle.',
    essence: 'earthen', tier: 1,
  },
  crow_feather: {
    name: 'Crow Feather', icon: '🪶', stack: true,
    desc: 'A black feather, indigo at the tip. Rare to find unbroken.',
    essence: 'sanguine', tier: 1,
  },
  morning_dew: {
    name: 'Morning Dew', icon: '✨', stack: true,
    desc: 'Three beads of dawn-water. Catches the first light of day.',
    essence: 'lumen', tier: 2,
  },
  foxfire_glow: {
    name: 'Foxfire Glow', icon: '💚', stack: true,
    desc: 'A pinched seedhead of ghost-light fungus. Glows faintly when shaken.',
    essence: 'lumen', tier: 2,
  },
  aurora_shard: {
    name: 'Aurora Shard', icon: '🌌', stack: true,
    desc: 'A hard splinter that fell from the night sky during the aurora. Cold to touch.',
    essence: 'lumen', tier: 3,
  },
  // Tag existing items with their essence / tier so recipes can match them.
  // (These are the already-existing item ids; we only add metadata here.)
  surveyors_pole: {
    name: "Surveyor's Pole", icon: '🪧', stack: true,
    desc: 'A striped pole and plumb-bob. Plant on a vista to fix every visible landmark.',
  },
  vellum: {
    name: 'Vellum', icon: '📃', stack: true,
    desc: 'A sheet of fine calf-skin paper, ready to take ink. The substrate of every chart.',
  },
  charcoal_stick: {
    name: 'Charcoal Stick', icon: '✏', stack: true,
    desc: 'A snapped twig of hearth-charcoal. Sketches into a journal page in a steady hand.',
  },
  // ---- Orbs (formerly charts). Slot one into a Plinth socket to spawn
  // a dungeon. The `chart` property is kept as the data identifier so
  // every existing reference (enterDungeon, inscribingTable, etc.) still
  // works — only the display name + icon change.
  chart_blank: {
    name: 'Hollow Orb', icon: '⚪', stack: true,
    desc: 'A clear, unwritten orb. Forge it on the Plinth with materials to lock in a path.',
  },
  chart_tier_1: {
    name: 'Pale Orb', icon: '🔮', stack: false,
    desc: 'A small orb humming with a Wolds hollow inside. Slot it to step in.',
    chart: { tier: 1, affixes: [] },
  },
  chart_snug: {
    name: 'Hearth Orb', icon: '🟡', stack: false,
    desc: 'A pocket-warm orb — one cellar, in and out.',
    chart: { tier: 1, affixes: [], scope: 'snug' },
  },
  chart_delve: {
    name: 'Stone Orb', icon: '🟤', stack: false,
    desc: 'A heavy orb veined with chalk. Slot it for the deep stone-rooms.',
    chart: { tier: 3, affixes: [], scope: 'delve' },
  },
  chart_hollow: {
    name: 'Deep Orb', icon: '⚫', stack: false,
    desc: 'A long, dim orb. Multi-room hollow. More floors, more chest.',
    chart: { tier: 2, affixes: [], scope: 'hollow' },
  },
  chart_briar_maze: {
    name: 'Briar Orb', icon: '🟢', stack: false,
    desc: 'A green-knotted orb that pulses with thorn-light. Corridors outnumber rooms.',
    chart: { tier: 2, affixes: [], scope: 'briar_maze' },
  },
  chart_sunken_hut: {
    name: 'Bog Orb', icon: '🔵', stack: false,
    desc: 'A water-cool orb threaded with mist. Wet rooms, old stone.',
    chart: { tier: 3, affixes: [], scope: 'sunken_hut' },
  },

  // ---- Inkwell vessels (Wayfinding Depth #13) ----
  // Tier-3 inks need a vessel: each NPC crafts one tied to their skill.
  // Hod (forge → clay), Quill (herbalist → bound parchment), Cricket
  // (cooper → glass vial). The vessel sits beside the 3×3 grid in the
  // Inscribing Table and is consumed alongside the ingredients.
  clay_flask: {
    name: 'Clay Flask', icon: '🏺', stack: true,
    desc: "A fire-glazed clay vessel from Hod's kiln. Holds heavy inks.",
    vessel: { essence: 'earthen', tier: 3 },
  },
  bound_parchment: {
    name: 'Bound Parchment', icon: '📜', stack: true,
    desc: "A folded sheaf of vellum stitched with Quill's reed-twine. Drinks pigment.",
    vessel: { essence: 'verdant', tier: 3 },
  },
  glass_vial: {
    name: 'Glass Vial', icon: '🧪', stack: true,
    desc: "A spun-glass tube from Cricket's cooperage. Holds the lightest inks.",
    vessel: { essence: 'lumen', tier: 3 },
  },

  // ---- Tier-3 inks (require vessels) ----
  // These don't yet have a chart that uses them — they're the next-tier
  // ink layer that rewards investment in the cross-skill loop.
  forge_brand_ink: {
    name: 'Forge-Brand Ink', icon: '🔥', stack: true,
    desc: 'A black ink shot through with embers. Pressed in clay; locks tyrannical lines.',
    ink: true, essence: 'ink', tier: 3,
  },
  aurora_ink: {
    name: 'Aurora Ink', icon: '🌅', stack: true,
    desc: 'A green-gold ink that shifts in lamplight. Bound in parchment; coaxes bloom.',
    ink: true, essence: 'ink', tier: 3,
  },
  tidewater_ink: {
    name: 'Tidewater Ink', icon: '💎', stack: true,
    desc: 'A clear ink with a slow inner shimmer. Sealed in glass; brightens veins.',
    ink: true, essence: 'ink', tier: 3,
  },

  // ---- Echo charts (Wayfinding Depth #3) ----
  // Echoes copy a region of the live overworld and turn its peaceful
  // residents into hostiles. The same layout you walk every day, run by
  // a different cast.
  chart_echo_village: {
    name: 'Echo Chart: Bramblewood Square', icon: '🌀', stack: false,
    desc: 'Vellum smudged with the village square. Step inside and the residents are gone.',
    chart: { tier: 2, affixes: [], scope: 'echo_village' },
  },
  chart_echo_forge: {
    name: "Echo Chart: Hod's Forge", icon: '🌀', stack: false,
    desc: 'Vellum scorched with the forge yard. The bellows are cold; iron-shod feet ring.',
    chart: { tier: 3, affixes: [], scope: 'echo_forge' },
  },
  chart_echo_perch: {
    name: "Echo Chart: Withering's Perch", icon: '🌀', stack: false,
    desc: 'Vellum stitched with feathers. The perch is empty, the hawks are hungry.',
    chart: { tier: 3, affixes: [], scope: 'echo_perch' },
  },

  // ---- Wayfinding crafting reagents ----
  // ---- Currency ----
  coin: {
    name: 'Bramblewood Coin', icon: '🪙', stack: true,
    desc: 'A small copper coin stamped with a hedge-rose. Universal trade in the Wolds.',
    archetype: 'currency',
  },

  hedge_ink: {
    name: 'Hedge Ink', icon: '🟢', stack: true,
    desc: 'A vial of green-black ink pressed from bramble-imp pulp. Stains anything it touches.',
    ink: { tier: 1, bias: {} },
  },
  lantern_oil: {
    name: 'Lantern Oil', icon: '🪔', stack: true,
    desc: 'Eldra\'s slow-burn oil. One bottle holds four good charges; useful when the dark gets heavy.',
  },

  // ---- Dungeon door keys --------------------------------------------
  // Drop from chest loot or quest givers. Consumed when used on a
  // matching locked door (color-coded). Stack so you can carry several.
  iron_key: {
    name: 'Iron Key', icon: '🗝', stack: true,
    desc: 'A blackened iron key, simple and heavy. Opens iron-bound doors.',
  },
  gold_key: {
    name: 'Gold Key', icon: '🗝', stack: true,
    desc: 'A bright brass key with cherry-blossom etching. Opens gilded doors — usually treasure.',
  },
  thorn_key: {
    name: 'Thorn Key', icon: '🗝', stack: true,
    desc: 'A briar-wrapped key that pricks the palm. Opens thorn-locked doors deep in the bramble.',
  },
  foxglove_sprig: {
    name: 'Foxglove Sprig', icon: '💐', stack: true,
    desc: 'A bell-shaped flower with a purple throat. Mother Onywyn grinds them for the bitter draught.',
    source: { skill: 'wilds', level: 5 },
  },

  // ---- Whispered legends — rare findables surfaced as in-world parchments.
  // Click to read; not consumed. Body text mirrors docs/WORLD_LORE.md.
  parchment_well_man: {
    name: 'A Child\'s Drawing', icon: '📜', stack: true,
    desc: 'A child\'s drawing of a sleeping man, folded into a stub of parchment.',
    lore: {
      title: 'The Man at the Bottom of Old Mother Well',
      body: 'Children claim there\'s a man asleep down there, breathing. Adults laugh. (There isn\'t. The village laughs because there is.)',
    },
  },
  parchment_seventh_cottage: {
    name: 'Old Wagon-Road Tally', icon: '📜', stack: true,
    desc: 'A scrap of vellum with cottages scratched in charcoal. Six are crossed through; a seventh is circled.',
    lore: {
      title: 'The Seventh Cottage',
      body: 'Old Wagon Road has a bend where you can see seven cottages along it. Walk it and count: there are six. Always six. Some say the seventh is for whoever was supposed to come and didn\'t.',
    },
  },
  parchment_bramble_bargain: {
    name: 'Hedgemother\'s Margin Note', icon: '📜', stack: true,
    desc: 'A torn corner from a herbalist\'s ledger. The handwriting is not Mother Onywyn\'s — it is older, and slower.',
    lore: {
      title: 'The Bramble Bargain',
      body: 'Onywyn the elder did not bind herself for nothing. She bargained with the hedge: my thinking, slower than yours, in exchange for one winter. The winter was bought; the rest is what we live in. (Mother Onywyn does not confirm this. She does not deny it either.)',
    },
  },
  parchment_sallow_tide: {
    name: 'Tide-Table Fragment', icon: '📜', stack: true,
    desc: 'A page from a coastguard\'s tide table. The night the wreck happened is circled — and the column for that night is empty.',
    lore: {
      title: 'Sallow\'s Tide',
      body: 'The shipwreck at Sallow\'s End was killed by a tide that didn\'t happen. The tide-tables for that night are clean. The wreck is wedged into the cliff at an angle no real wave makes. Nobody has been down to it in fifty years.',
    },
  },
  parchment_linnet_vow: {
    name: 'Falconer\'s Note', icon: '📜', stack: true,
    desc: 'A page in a knight\'s hand. Two names share the page; one has been crossed through, then traced over again, faintly.',
    lore: {
      title: 'Linnet\'s Vow',
      body: 'Sir Withering\'s falcon is named Linnet. The villagers know there used to be another Linnet — a person, not a bird. Withering says the bird\'s name first. They are kind enough not to ask.',
    },
  },
  stoneground_ink: {
    name: 'Stoneground Ink', icon: '⚫', stack: true,
    desc: 'A flat grey ink ground from ore dust. Reads even on damp vellum.',
    ink: { tier: 1, bias: { mineral_vein: 1.30 } },
  },
  bramblepress_ink: {
    name: 'Bramblepress Ink', icon: '🔴', stack: true,
    desc: 'A red-black ink that smells faintly of iron. Quivers when first applied.',
    ink: { tier: 1, bias: { tyrannical: 1.30 } },
  },
  wellspring_ink: {
    name: 'Wellspring Ink', icon: '🔵', stack: true,
    desc: 'A pale blue ink that holds shimmer. Used for charts that should bloom.',
    ink: { tier: 1, bias: { bramble_bloom: 1.30 } },
  },
  charcoal_bind: {
    name: 'Charcoal Bind', icon: '⚫️', stack: true,
    desc: 'A pinch of pure charcoal binding. Steadies the line of any ink it joins.',
    ink: { tier: 1, bias: { _stability: 0.05 } },
  },
  refined_ink: {
    name: 'Refined Ink', icon: '⚫', stack: true,
    desc: 'Hedge ink boiled down with copper salts. Steadies any roll it touches.',
    ink: { tier: 2, bias: { _stability: 0.05 } },
  },
  bog_ink: {
    name: 'Bog Ink', icon: '🟦', stack: true,
    desc: 'A pale blue ink dipped from still water, with a faint mineral shimmer.',
    ink: { tier: 2, bias: { fog_of_hedge: 1.30, bramble_bloom: 1.30 } },
  },
  ember_ink: {
    name: 'Ember Ink', icon: '🟠', stack: true,
    desc: 'A red-orange ink that holds a warmth long after the press. Smells of smoke.',
    ink: { tier: 2, bias: { tyrannical: 1.30, bursting: 1.30 } },
  },
  lustrous_ink: {
    name: 'Lustrous Ink', icon: '✨', stack: true,
    desc: 'A grey ink shot through with golden flecks of refined ore.',
    ink: { tier: 2, bias: { mineral_vein: 1.30, gilded_seam: 1.10, gem_seam: 1.10 } },
  },

  // ============================================================
  // RUNE MAGIC — see docs/rune-magic-design.md
  // Runes are stackable consumables; spells spend specific combos.
  // ============================================================
  rune_stone: {
    name: 'Rune Stone', icon: '🪨', stack: true,
    desc: 'A small carved blank, ready to take a chant. Pressed at a Runestone Pedestal.',
  },
  rune_air: {
    name: 'Air Rune', icon: '🌬', stack: true,
    desc: 'A pale stone humming with quiet wind. Used in air-element spells.',
    rune: { element: 'air', tier: 1 },
  },
  rune_earth: {
    name: 'Earth Rune', icon: '🪨', stack: true,
    desc: 'A heavy ochre stone. Used in earth-element spells.',
    rune: { element: 'earth', tier: 1 },
  },
  rune_fire: {
    name: 'Fire Rune', icon: '🔥', stack: true,
    desc: 'A warm carmine stone. Used in fire-element spells.',
    rune: { element: 'fire', tier: 1 },
  },
  rune_mind: {
    name: 'Mind Rune', icon: '🧠', stack: true,
    desc: 'A pale grey stone. Catalyst for elemental strikes.',
    rune: { element: 'mind', tier: 1 },
  },
  rune_water: {
    name: 'Water Rune', icon: '💧', stack: true,
    desc: 'A cool blue stone, slick to the touch. Used in water-element spells.',
    rune: { element: 'water', tier: 1 },
  },
  rune_body: {
    name: 'Body Rune', icon: '💪', stack: true,
    desc: 'A flesh-warm stone. Catalyst for body and binding spells.',
    rune: { element: 'body', tier: 1 },
  },
  // Catalyst (Lv 30+ to press)
  rune_chaos: {
    name: 'Chaos Rune', icon: '🌀', stack: true,
    desc: 'A roiling stone, never quite still. Catalyst for tier-2 attack spells.',
    rune: { element: 'chaos', tier: 2 },
  },
  rune_cosmic: {
    name: 'Cosmic Rune', icon: '⚖', stack: true,
    desc: 'A still grey stone with a single white star carved at its center. Travel + utility magic.',
    rune: { element: 'cosmic', tier: 2 },
  },
  rune_law: {
    name: 'Law Rune', icon: '🚪', stack: true,
    desc: 'A weighty stone, edges true and clean. Locks and binds; teleports and seals.',
    rune: { element: 'law', tier: 2 },
  },
  rune_nature: {
    name: 'Nature Rune', icon: '🌫', stack: true,
    desc: 'A vine-bound stone with fresh green at its core. Plant + animal magic.',
    rune: { element: 'nature', tier: 2 },
  },
  // Rare (Lv 60+)
  rune_death: {
    name: 'Death Rune', icon: '☠', stack: true,
    desc: 'A dark stone that drinks the warmth from your hand. Necrotic spells.',
    rune: { element: 'death', tier: 3 },
  },
  rune_blood: {
    name: 'Blood Rune', icon: '🩸', stack: true,
    desc: 'A red-flecked stone, faintly pulsing. Self-fuel spells (HP-cost casts).',
    rune: { element: 'blood', tier: 3 },
  },
  rune_soul: {
    name: 'Soul Rune', icon: '✨', stack: true,
    desc: 'A still, bright stone. Endgame: unique-named spells.',
    rune: { element: 'soul', tier: 3 },
  },

  cinderbloom_helm: {
    name: 'Cinderbloom Helm', icon: '⛑', stack: false,
    slot: 'helm',
    equipBonus: { atk: 0, str: 0, def: 3 },
    reqSkill: 'def', reqLevel: 30,
    tier: 'steel',
    desc: 'A brimmed helm with a riveted nose-bar. The padding still smells of someone else.',
  },

  // ============================================================
  // TOWN QUEST ITEMS — given out by Hod, Quill, Withering, Maud.
  // Each is referenced by src/data/npcs.js dialog and tracked on
  // player.quest.flags. Models are listed in docs/quest-items-models.md.
  // ============================================================

  // Hod's "First Hammer" reward
  apprentices_hammer: {
    name: "Apprentice's Hammer", icon: '🔨', stack: false,
    archetype: 'tool', tool: 'hammer',
    desc: "Hod hammered this from your first ore-strike. The grip's wrapped in his own old apron leather.",
    questGift: 'hod',
  },
  // Hod's quest goal item — handed in
  hods_anvil_token: {
    name: "Hod's Anvil Token", icon: '⚒', stack: false,
    archetype: 'token',
    desc: 'A small bronze token shaped like an anvil. Bring it back when the work is done.',
    questGoal: 'hod',
  },

  // Quill's "Withering Bramble" reward
  healing_draught: {
    name: 'Healing Draught', icon: '🍶', stack: true,
    food: { heal: 12 },
    archetype: 'reagent',
    desc: 'A cloudy green tincture that smells faintly of moss and copper. Restores 12 HP.',
    questGift: 'quill',
  },
  // Quill's intermediate gathered item
  bramble_resin: {
    name: 'Bramble Resin', icon: '🟢', stack: true,
    archetype: 'reagent',
    desc: 'Sticky amber sap from withering bramble vines. Quill needs three.',
    questGoal: 'quill',
  },

  // Withering's "Pernel's Errand" reward — falconry tool
  falcons_whistle: {
    name: "Falcon's Whistle", icon: '🪈', stack: false,
    archetype: 'tool', tool: 'whistle',
    desc: 'A bone whistle Sir Withering carved for Pernel. Calls a falcon to scout overhead.',
    questGift: 'withering',
  },
  // Withering's quest goal — find this rare drop
  whickerhares_foot: {
    name: "Whickerhare's Foot Charm", icon: '🐾', stack: false,
    archetype: 'token',
    desc: 'Velvet foot of a swift wold-hare. Withering says Pernel will follow its scent.',
    questGoal: 'withering',
  },

  // Withering's long-term lore reward (Hedgemother victory)
  thorn_crown: {
    name: 'Thorn-Crown of the Hedgemother', icon: '👑', stack: false,
    archetype: 'token',
    desc: 'A diadem of black bramble, still warm. Sir Withering bows when you wear it.',
    questGift: 'withering',
  },

  // Maud's follow-up: pantry stew
  pantry_stew: {
    name: "Maud's Pantry Stew", icon: '🥘', stack: true,
    food: { heal: 15 },
    desc: 'Slow-simmered with hedgecap, whitleberry, and a bone for marrow. Restores 15 HP.',
    reqSkill: 'cook', reqLevel: 10,
    questGift: 'cook',
  },

  // ===========================================================
  // MATERIALS — tier-2 reagents (one-step refinement of raw)
  // ===========================================================
  // Each is a single-input refinement of one raw material, produced at
  // a workstation (mortar / grindstone / vessel / curing rack / kiln).
  // Used as ingredients for tier-2b inks, cores, and tier-3 orbs.
  crushed_herb:   { name: 'Crushed Herb',   icon: '🌱', stack: true,
    desc: 'Wild herb pounded in a mortar. The base reagent for green-tinted inks.' },
  fox_dust:       { name: 'Foxglove Dust',  icon: '🟪', stack: true,
    desc: 'Foxglove petals dried and ground. Bitter, used in tinctures and inks.' },
  rose_powder:    { name: 'Wishrose Powder', icon: '🌸', stack: true,
    desc: 'Wishrose petals reduced to a sweet powder. Lumen-bias reagent.' },
  ore_powder:     { name: 'Ore Powder',     icon: '🟫', stack: true,
    desc: 'Mosswort ore ground at the grindstone. The earthen reagent for gray ink.' },
  chalk_powder:   { name: 'Chalk Powder',   icon: '⬜', stack: true,
    desc: 'Palechalk reduced to soft white powder. Brightens stone-bias inks.' },
  iron_grit:      { name: 'Iron Grit',      icon: '⚫', stack: true,
    desc: 'Coarse bogiron filings. Heavy, used in black inks and tusker cores.' },
  ash_powder:     { name: 'Ash Powder',     icon: '◼', stack: true,
    desc: 'Charcoal sticks ground fine. The binder in most multi-flavor inks.' },
  bottled_water:  { name: 'Bottled Water',  icon: '💧', stack: true,
    desc: 'Pond water in a clay vessel. Lumen reagent; carries a note of the source.' },
  bottled_dew:    { name: 'Bottled Dew',    icon: '✨', stack: true,
    desc: 'Dawn-only dewdrops, sealed before sunrise. Rare lumen reagent.' },
  soft_leather:   { name: 'Soft Leather',   icon: '🟫', stack: true,
    desc: 'Hare pelt cured to a workable hide. Used in pouches and binding.' },
  wight_leather:  { name: 'Wight Leather',  icon: '🟪', stack: true,
    desc: 'Wightpelt cured cold. Holds a faint blue glow. Echo reagent.' },
  fired_clay:     { name: 'Fired Clay',     icon: '🟤', stack: true,
    desc: 'River clay fired in the kiln. Used as vessel material for tier-3 inks.' },
  mosspepper:     { name: 'Mosspepper',     icon: '🌿', stack: true,
    desc: 'A small spice-bud from the deep wolds. Sharpens any cooked dish by one step.' },
  dewdrop:        { name: 'Dewdrop',        icon: '💎', stack: true,
    desc: 'A single dawn-bound dewdrop. Bottled before the sun lands on it.' },
  river_clay:     { name: 'River Clay',     icon: '🟫', stack: true,
    desc: 'Plastic gray clay from the river bend. Forms the body of fired vessels.' },

  // ===========================================================
  // CORES — concentrated single-flavor materials for orbs
  // ===========================================================
  // Cores echo the dungeon scope they bias — bramble_core nudges briar
  // outcomes, tusker_core nudges sunken-hut, etc. Crafted from rare
  // echo materials at the orb forge bench.
  bramble_core: { name: 'Bramble Core', icon: '🟢', stack: true,
    desc: 'A pulsing knot of thorn-essence. Steers an orb toward briar-maze biomes.' },
  resin_core:   { name: 'Resin Core',   icon: '🟡', stack: true,
    desc: 'Bramble resin condensed to a sticky bead. Steers toward forage-rich orbs.' },
  tusker_core:  { name: 'Tusker Core',  icon: '🦷', stack: true,
    desc: 'Tusker tusk fused with iron grit. Steers toward sunken-hut orbs.' },
  wight_core:   { name: 'Wight Core',   icon: '🔵', stack: true,
    desc: 'Wight leather and ash, bound cold. Steers toward delve / hedgewight orbs.' },

  // ===========================================================
  // CATALYSTS — found-not-crafted, nudge orb properties
  // ===========================================================
  // Catalysts are rare drops or discoveries that shift one rolled
  // property of an orb. Players collect them passively; they can't be
  // farmed at a workstation.
  old_key:       { name: 'Old Key',       icon: '🗝', stack: true,
    desc: 'A wrought iron key of unknown origin. Slotted into an orb, it adds a secret-room affix.' },
  fey_blossom:   { name: 'Fey Blossom',   icon: '🌺', stack: true,
    desc: 'A midnight bloom that closes by sunrise. Slot to bias one property toward its highest tier.' },
  owl_feather:   { name: 'Owl Feather',   icon: '🪶', stack: true,
    desc: 'A long charcoal feather, still warm. Slot to add a "night" modifier (dim light, more loot).' },
  cracked_tile:  { name: 'Cracked Tile',  icon: '🧱', stack: true,
    desc: 'A glazed tile from some ruined floor. Slot to add a "decay" modifier (fewer mobs, more chests).' },
  sealed_letter: { name: 'Sealed Letter', icon: '✉', stack: true,
    desc: 'Wax-sealed parchment, wax not yet broken. Slot to spawn a memory-vignette room.' },
  hags_tooth:    { name: "Hag's Tooth",   icon: '🦷', stack: true,
    desc: 'A long cracked canine, bone-white. Slot to force a boss-tier orb.' },
  glass_shard:   { name: 'Glass Shard',   icon: '🔷', stack: true,
    desc: 'A jagged piece of leaded glass from a broken urn. Slot to re-roll one property next forge.' },
};

export function isFood(id) { return ITEMS[id] && ITEMS[id].food; }
export function equipSlot(id) { return ITEMS[id] && ITEMS[id].slot; }

// Findable lore parchments — derived once so new lore items auto-include.
// Used by chest loot, forage bonuses, and enemy drops to surface
// whispered-legend content from items.js.
export const LORE_PARCHMENTS = Object.keys(ITEMS).filter(k => ITEMS[k].lore);
export function pickRandomLoreParchment() {
  if (!LORE_PARCHMENTS.length) return null;
  return LORE_PARCHMENTS[Math.floor(Math.random() * LORE_PARCHMENTS.length)];
}
