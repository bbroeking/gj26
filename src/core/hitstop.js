// Hit-stop — brief frame-time scaling on big impacts so the hit lands
// before time resumes. Souls / Hades / Lost Ark all use a variant of
// this (~30-100ms at 5-15% speed) and it sells the weight of a strike.
//
// Public API:
//   triggerHitStop(amount = 0.06, scale = 0.05)   — duration in seconds
//   sampleHitStop(rawDt)                           — returns scaled dt

let _remaining = 0;
let _scale = 0.05;
let _lastTriggerWall = 0;          // wall-clock ms of last accepted trigger
const _COOLDOWN_MS = 350;          // throttle: ignore subsequent triggers within this window

export function triggerHitStop(duration = 0.06, scale = 0.05) {
  // Throttle — without this, fighting 5+ enemies stacks hit-stop on every
  // power-swing kill and the screen judders. Only honor a new trigger when
  // the previous one has had ~350ms of recovery time.
  const now = (typeof performance !== 'undefined' ? performance.now() : Date.now());
  if (now - _lastTriggerWall < _COOLDOWN_MS) return;
  _lastTriggerWall = now;
  if (duration > _remaining) {
    _remaining = duration;
    _scale = scale;
  }
}

/** Apply hit-stop scaling to a dt value. Decrements remaining time using
 *  the *raw* dt (so the pause length is in real time). Returns the
 *  scaled dt for game systems to consume. */
export function sampleHitStop(rawDt) {
  if (_remaining <= 0) return rawDt;
  _remaining = Math.max(0, _remaining - rawDt);
  return rawDt * _scale;
}
