// Keyboard state + edge-triggered queues. Combat moved to ARPG flavor:
//   E / Enter / Space  → interact (talk, harvest, fish, mine, etc.)
//                        Space falls back to dodge if there's nothing
//                        adjacent to interact with — main loop checks
//                        first and consumes whichever applies.
//   V                  → dodge (explicit fallback key; Space does it too
//                        when not interacting)
//   1..8               → action-bar slots (remappable via setSlotKey)

export const keys = {};

// Slot-key bindings — which lowercase key strings fire which action-bar
// slot. Default is the digits 1..8. Mutable via setSlotKey(slot, key);
// persisted to localStorage so changes survive reloads.
const _SLOT_KEYS = (() => {
  try {
    const raw = localStorage.getItem('gj26.slotKeys');
    if (raw) {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr) && arr.length === 8) return arr;
    }
  } catch (_) {}
  return ['1', '2', '3', '4', '5', '6', '7', '8'];
})();

/** Look up which slot (1..8) a lowercase key string fires, or 0 if none. */
function slotForKeyChar(k) {
  for (let i = 0; i < _SLOT_KEYS.length; i++) {
    if (_SLOT_KEYS[i] === k) return i + 1;
  }
  return 0;
}

/** Programmatically rebind a slot to a new lowercase key string. */
export function setSlotKey(slot, keyChar) {
  if (slot < 1 || slot > 8) return;
  _SLOT_KEYS[slot - 1] = String(keyChar || '').toLowerCase().slice(0, 1);
  try { localStorage.setItem('gj26.slotKeys', JSON.stringify(_SLOT_KEYS)); } catch (_) {}
}

/** Read the current binding for a slot. */
export function getSlotKey(slot) {
  return _SLOT_KEYS[slot - 1] || '';
}

// ---------- ACTION KEYS ----------
// Action verbs that aren't tied to slot 1-8. Each id maps to one or
// more lowercase keys. The keydown handler iterates this map so adding
// a new action is a one-line edit. localStorage persistence + a
// setActionKey() / getActionKey() pair drives the settings rebind UI.
export const ACTION_IDS = ['interact', 'dodge', 'targetSwap', 'potion', 'journal', 'sketch', 'cast', 'spellbook'];
export const ACTION_LABELS = {
  interact:   'Interact',
  dodge:      'Dodge',
  targetSwap: 'Swap Target',
  potion:     'Quick-quaff Food',
  journal:    'Journal',
  sketch:     'Sketch',
  cast:       'Cast Spell',
  spellbook:  'Spellbook',
};
const ACTION_DEFAULTS = {
  interact:   ['e', 'enter'],
  dodge:      ['v', ' '],
  targetSwap: ['tab'],
  potion:     ['q'],
  journal:    ['j'],
  sketch:     ['n'],
  cast:       ['r'],
  spellbook:  [],   // currently no default — the spellbook tool button covers it
};
const _ACTION_KEYS = (() => {
  const out = {};
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem('gj26.actionKeys') || '{}'); } catch (_) {}
  for (const id of ACTION_IDS) {
    const v = saved[id];
    out[id] = Array.isArray(v) && v.length ? v.map(k => String(k).toLowerCase()) : ACTION_DEFAULTS[id].slice();
  }
  return out;
})();
export function getActionKey(id) {
  return (_ACTION_KEYS[id] || [])[0] || '';
}
export function setActionKey(id, keyChar) {
  if (!ACTION_IDS.includes(id)) return;
  const k = String(keyChar || '').toLowerCase();
  if (!k) return;
  _ACTION_KEYS[id] = [k];
  // Re-include any default secondaries other than the primary so things
  // like Enter for interact / Space for dodge remain reachable. Skip if
  // the default secondary is the primary the user just bound.
  const defaults = ACTION_DEFAULTS[id] || [];
  for (let i = 1; i < defaults.length; i++) {
    if (defaults[i] !== k) _ACTION_KEYS[id].push(defaults[i]);
  }
  try { localStorage.setItem('gj26.actionKeys', JSON.stringify(_ACTION_KEYS)); } catch (_) {}
}
function _actionForKey(k) {
  for (const id of ACTION_IDS) {
    if ((_ACTION_KEYS[id] || []).includes(k)) return id;
  }
  return null;
}

let pendingInteract = false;
let pendingDodge    = false;
let pendingTargetSwap = false;
let pendingPotion = false;
let pendingJournal = false;
let pendingSketch  = false;
let pendingCast    = false;
const pendingAbility = [false, false, false, false, false, false, false, false];

export function isPressed(...names) {
  return names.some(n => keys[n]);
}

export function takeInteract() {
  if (!pendingInteract) return false;
  pendingInteract = false;
  return true;
}

export function takeDodge() {
  if (!pendingDodge) return false;
  pendingDodge = false;
  return true;
}

export function takeTargetSwap() {
  if (!pendingTargetSwap) return false;
  pendingTargetSwap = false;
  return true;
}

export function takePotion() {
  if (!pendingPotion) return false;
  pendingPotion = false;
  return true;
}

export function takeJournal() {
  if (!pendingJournal) return false;
  pendingJournal = false;
  return true;
}

export function takeSketch() {
  if (!pendingSketch) return false;
  pendingSketch = false;
  return true;
}

export function takeCast() {
  if (!pendingCast) return false;
  pendingCast = false;
  return true;
}

/** Returns 1..8 if a hotkey was pressed since last call, else 0. */
export function takeAbility() {
  for (let i = 0; i < pendingAbility.length; i++) {
    if (pendingAbility[i]) { pendingAbility[i] = false; return i + 1; }
  }
  return 0;
}

window.addEventListener('keydown', e => {
  const k = e.key.toLowerCase();
  keys[k] = true;
  if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' ', 'tab'].includes(k)) {
    e.preventDefault();
  }
  // Action lookup — single map drives every non-slot verb. Space stays
  // a special case: it queues BOTH interact and dodge so the main loop
  // can prefer interact when there's a target, fall through to dodge
  // otherwise. (Bound to dodge by default; interact also fires on space.)
  if (k === ' ') pendingInteract = true;
  const action = _actionForKey(k);
  if (action === 'interact')   pendingInteract = true;
  else if (action === 'dodge') pendingDodge = true;
  else if (action === 'targetSwap') pendingTargetSwap = true;
  else if (action === 'potion')  pendingPotion = true;
  else if (action === 'journal') pendingJournal = true;
  else if (action === 'sketch')  pendingSketch = true;
  else if (action === 'cast')    pendingCast = true;
  // Look up the remappable slot key (defaults to '1'..'8')
  const _slot = slotForKeyChar(k);
  if (_slot >= 1 && _slot <= 8) pendingAbility[_slot - 1] = true;
});

window.addEventListener('keyup', e => {
  keys[e.key.toLowerCase()] = false;
});
