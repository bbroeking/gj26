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
  if (k === 'e' || k === 'enter') pendingInteract = true;
  // Space queues BOTH interact and dodge — main loop drains interact first
  // (gated on a target tile), then falls through to dodge if nothing was
  // available. V is a dedicated dodge key for players who'd rather keep
  // them separate.
  if (k === ' ') { pendingInteract = true; pendingDodge = true; }
  if (k === 'v') pendingDodge = true;
  if (k === 'tab') pendingTargetSwap = true;
  if (k === 'q') pendingPotion = true;
  if (k === 'j') pendingJournal = true;
  if (k === 'n') pendingSketch  = true;
  if (k === 'r') pendingCast    = true;
  // Look up the remappable slot key (defaults to '1'..'8')
  const _slot = slotForKeyChar(k);
  if (_slot >= 1 && _slot <= 8) pendingAbility[_slot - 1] = true;
});

window.addEventListener('keyup', e => {
  keys[e.key.toLowerCase()] = false;
});
