// Keyboard state + interact queue. The interact queue is consumed by the
// archetype controller exactly once per "press" to avoid lost-input races.
export const keys = {};
let pendingInteract = false;

export function isPressed(...names) {
  return names.some(n => keys[n]);
}

export function takeInteract() {
  if (!pendingInteract) return false;
  pendingInteract = false;
  return true;
}

window.addEventListener('keydown', e => {
  const k = e.key.toLowerCase();
  keys[k] = true;
  if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) {
    e.preventDefault();
  }
  if (k === ' ' || k === 'e' || k === 'enter') pendingInteract = true;
});

window.addEventListener('keyup', e => {
  keys[e.key.toLowerCase()] = false;
});
