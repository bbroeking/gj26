// 28-slot inventory + 4-slot equipment. Stackable items combine into one slot.
import { CONFIG } from '../data/config.js';
import { ITEMS, equipSlot } from '../data/items.js';

export class Inventory {
  constructor() {
    this.slots = new Array(CONFIG.inventory.slots).fill(null);
    this.equipped = { weapon: null, body: null, helm: null, shield: null };
  }

  add(id, qty = 1) {
    const def = ITEMS[id];
    if (!def) throw new Error('Unknown item: ' + id);
    if (def.stack) {
      for (const s of this.slots) if (s && s.id === id) { s.qty += qty; return true; }
    }
    const free = this.slots.indexOf(null);
    if (free === -1) return false;
    this.slots[free] = { id, qty: def.stack ? qty : 1 };
    return true;
  }

  /** Remove `qty` from the first stack of `id`. Returns actual removed count. */
  remove(id, qty = 1) {
    let removed = 0;
    for (let i = 0; i < this.slots.length; i++) {
      const s = this.slots[i];
      if (!s || s.id !== id) continue;
      const take = Math.min(qty - removed, s.qty);
      s.qty -= take;
      removed += take;
      if (s.qty <= 0) this.slots[i] = null;
      if (removed >= qty) break;
    }
    return removed;
  }

  count(id) {
    let n = 0;
    for (const s of this.slots) if (s && s.id === id) n += s.qty;
    return n;
  }

  /** Click a slot: equip/unequip if equippable, eat if food, else nothing. */
  use(slotIdx, player) {
    const s = this.slots[slotIdx];
    if (!s) return null;
    const slot = equipSlot(s.id);
    if (slot) {
      // swap with whatever's currently equipped
      const prev = this.equipped[slot];
      this.equipped[slot] = s.id;
      this.slots[slotIdx] = prev ? { id: prev, qty: 1 } : null;
      return { kind: 'equip', slot, id: this.equipped[slot] };
    }
    if (ITEMS[s.id].food) {
      const heal = ITEMS[s.id].food.heal;
      if (player.hp >= player.hpMax) return { kind: 'full_hp' };
      player.hp = Math.min(player.hpMax, player.hp + heal);
      this.remove(s.id, 1);
      return { kind: 'eat', heal, id: s.id };
    }
    return { kind: 'noop' };
  }

  totalEquipBonus(stat) {
    let total = 0;
    for (const slot of CONFIG.equipment) {
      const id = this.equipped[slot];
      if (!id) continue;
      const b = ITEMS[id].equipBonus;
      if (b && b[stat]) total += b[stat];
    }
    return total;
  }
}
