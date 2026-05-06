// Smithing recipe table. Each entry is one craftable action: smelting
// (raw ore → bar) or smithing (bar(s) → equipment). Engine reads this
// at smith-station click time; codex Recipes tab reads it for display.
//
// Fields:
//   kind     — 'smelt' or 'smith'
//   inputs   — { itemId: count } map (smelt only)
//   bars     — bar item id (smith only); paired with `count` for qty
//   count    — number of bars consumed (smith only)
//   out      — output item id
//   xp       — earth XP awarded on success
//   cd       — cooldown in ticks (~60 fps), gates crafting cadence
//   label    — display string
//   reqLevel — earth level required (omitted = level 1)

export const SMITH_RECIPES = {
  // ---- Bronze tier ----
  smelt_bronze: { kind: 'smelt', inputs: { mosswort_ore: 1, palechalk_ore: 1 }, out: 'brindle_bar', xp: 8,  cd: 60, label: 'Smelt Bronze Bar' },
  smith_bronze_dagger: { kind: 'smith', bars: 'brindle_bar', count: 1, out: 'brindle_dagger', xp: 22, cd: 80, label: 'Smith Bronze Dagger' },
  // ---- Iron tier (level 15+) ----
  smelt_iron:   { kind: 'smelt', inputs: { bogiron_ore: 1 }, out: 'bogiron_bar', xp: 14, cd: 70, label: 'Smelt Iron Bar', reqLevel: 15 },
  smith_iron_dagger:  { kind: 'smith', bars: 'bogiron_bar', count: 1, out: 'bogiron_dagger',  xp: 28, cd: 90, label: 'Smith Iron Dagger',  reqLevel: 15 },
  smith_iron_sword:   { kind: 'smith', bars: 'bogiron_bar', count: 2, out: 'bogiron_sword',   xp: 56, cd: 110,label: 'Smith Iron Sword',   reqLevel: 17 },
  smith_iron_axe:     { kind: 'smith', bars: 'bogiron_bar', count: 1, out: 'bogiron_axe',     xp: 28, cd: 90, label: 'Smith Iron Axe',     reqLevel: 16 },
  smith_iron_pickaxe: { kind: 'smith', bars: 'bogiron_bar', count: 1, out: 'bogiron_pickaxe', xp: 28, cd: 90, label: 'Smith Iron Pickaxe', reqLevel: 16 },
  smith_iron_shield:  { kind: 'smith', bars: 'bogiron_bar', count: 3, out: 'bogiron_shield',  xp: 84, cd: 130,label: 'Smith Iron Shield',  reqLevel: 19 },
  smith_iron_body:    { kind: 'smith', bars: 'bogiron_bar', count: 5, out: 'bogiron_cuirass',    xp: 140,cd: 160,label: 'Smith Iron Cuirass', reqLevel: 22 },
  // ---- Steel tier (smithing 30+, requires coal) ----
  smelt_steel: { kind: 'smelt', inputs: { bogiron_ore: 1, coalrose: 2 }, out: 'cinderbloom_bar', xp: 24, cd: 90, label: 'Smelt Steel Bar', reqLevel: 30 },
  smith_steel_dagger:  { kind: 'smith', bars: 'cinderbloom_bar', count: 1, out: 'cinderbloom_dagger',  xp: 50,  cd: 100, label: 'Smith Steel Dagger',  reqLevel: 30 },
  smith_steel_sword:   { kind: 'smith', bars: 'cinderbloom_bar', count: 2, out: 'cinderbloom_sword',   xp: 100, cd: 120, label: 'Smith Steel Sword',   reqLevel: 32 },
  smith_steel_axe:     { kind: 'smith', bars: 'cinderbloom_bar', count: 1, out: 'cinderbloom_axe',     xp: 50,  cd: 100, label: 'Smith Steel Axe',     reqLevel: 31 },
  smith_steel_pickaxe: { kind: 'smith', bars: 'cinderbloom_bar', count: 1, out: 'cinderbloom_pickaxe', xp: 50,  cd: 100, label: 'Smith Steel Pickaxe', reqLevel: 31 },
  smith_steel_helm:    { kind: 'smith', bars: 'cinderbloom_bar', count: 2, out: 'cinderbloom_helm',    xp: 100, cd: 120, label: 'Smith Steel Helm',    reqLevel: 33 },
  smith_steel_shield:  { kind: 'smith', bars: 'cinderbloom_bar', count: 3, out: 'cinderbloom_shield',  xp: 150, cd: 140, label: 'Smith Steel Shield',  reqLevel: 35 },
  smith_steel_body:    { kind: 'smith', bars: 'cinderbloom_bar', count: 5, out: 'cinderbloom_plate',    xp: 250, cd: 180, label: 'Smith Steel Plate',   reqLevel: 38 },
};
