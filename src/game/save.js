// Save / load — serialize the parts of game state that should survive
// page reloads. Character appearance + name was already saved separately;
// this module covers everything else (skills, inventory, equipment,
// quest progress, discovered tiles, hp).

import { hpMaxForLv } from './skills.js';

const SAVE_KEY = 'gj26.state';

/** Serialize the live player + world into a plain object. */
export function serialize(player, world) {
  return {
    v: 1,
    saved: Date.now(),
    player: {
      x: player.x, y: player.y, dir: player.dir,
      hp: player.hp, hpMax: player.hpMax,
      skills: structuredClone(player.skills),
      inventory: {
        slots: structuredClone(player.inventory.slots),
        equipped: structuredClone(player.inventory.equipped),
      },
      bank: structuredClone(player.bank || {}),
      quest: structuredClone(player.quest),
      combatStyle: player.combatStyle,
    },
    world: {
      discovered: world.discovered ? [...world.discovered] : [],
      timeOfDay: world.timeOfDay ?? 0.5,
    },
  };
}

/** Apply a saved object back onto the live player + world. Skips fields
 *  that aren't present (forward-compatible with future schema bumps). */
export function applySave(state, player, world) {
  if (!state || state.v !== 1) return false;
  const ps = state.player || {};
  if (typeof ps.x === 'number' && typeof ps.y === 'number') {
    player.x = ps.x; player.y = ps.y;
    player.pos.x = ps.x + 0.5;
    player.pos.z = ps.y + 0.5;
    player.mesh.position.set(ps.x + 0.5, player.mesh.position.y, ps.y + 0.5);
  }
  if (ps.dir) player.dir = ps.dir;
  if (ps.skills) Object.assign(player.skills, ps.skills);
  // Always re-derive hpMax from the (possibly migrated) HP level rather
  // than trusting the saved cap — old saves under the OSRS 1:1 formula
  // shouldn't permanently lock the player at hpMax=10 when they reload
  // under the new 2× formula.
  player.hpMax = hpMaxForLv(player.skills.hp?.lv ?? 10);
  if (typeof ps.hp === 'number') player.hp = Math.min(ps.hp, player.hpMax);
  else                           player.hp = player.hpMax;
  if (ps.inventory?.slots)    player.inventory.slots    = ps.inventory.slots;
  if (ps.inventory?.equipped) player.inventory.equipped = ps.inventory.equipped;
  if (ps.bank && typeof ps.bank === 'object') player.bank = ps.bank;
  if (ps.quest) Object.assign(player.quest, ps.quest);
  if (ps.combatStyle) player.combatStyle = ps.combatStyle;
  const ws = state.world || {};
  if (Array.isArray(ws.discovered)) world.discovered = new Set(ws.discovered);
  if (typeof ws.timeOfDay === 'number') world.timeOfDay = ws.timeOfDay;
  return true;
}

export function writeSave(player, world) {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(serialize(player, world)));
  } catch (_) {}
}

export function readSave() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

export function clearSave() {
  try { localStorage.removeItem(SAVE_KEY); } catch (_) {}
}

/** Tick-driven autosave. Call from the main loop with the current dt; the
 *  helper writes once every `intervalSec` seconds. */
let _autosaveAccum = 0;
export function tickAutosave(dt, player, world, intervalSec = 10) {
  _autosaveAccum += dt;
  if (_autosaveAccum >= intervalSec) {
    _autosaveAccum = 0;
    writeSave(player, world);
  }
}
