// Item registry. Each entry: id, name, icon, slot (if equippable), bonuses.
export const ITEMS = {
  raw_beef:    { name: 'Raw Beef',    icon: '🥩', stack: true },
  cooked_beef: { name: 'Cooked Beef', icon: '🍖', stack: true, food: { heal: 5 } },
  burnt_beef:  { name: 'Burnt Beef',  icon: '⬛', stack: true },
  cowhide:     { name: 'Cowhide',     icon: '🟫', stack: true },
  bronze_sword: {
    name: 'Bronze Sword', icon: '🗡', stack: false,
    slot: 'weapon', equipBonus: { atk: 1, str: 2, def: 0 },
  },
  leather_body: {
    name: 'Leather Body', icon: '🦺', stack: false,
    slot: 'body', equipBonus: { atk: 0, str: 0, def: 2 },
  },
  wooden_shield: {
    name: 'Wooden Shield', icon: '🛡', stack: false,
    slot: 'shield', equipBonus: { atk: 0, str: 0, def: 1 },
  },
  bucket:      { name: 'Bucket', icon: '🪣', stack: false },
};

export function isFood(id) {
  return ITEMS[id] && ITEMS[id].food;
}
export function equipSlot(id) {
  return ITEMS[id] && ITEMS[id].slot;
}
