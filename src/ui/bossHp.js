// Boss HP overlay — DOM bar at the top of the canvas.
//
// Spec 05: visible only while a boss is alive in the current room. Updates
// from the boss enemy's hp/hpMax each frame the boss is engaged.

let _root = null;
let _name = null;
let _fill = null;

function _grab() {
  if (_root) return;
  _root = document.getElementById('boss-hp');
  _name = document.getElementById('boss-hp-name');
  _fill = document.getElementById('boss-hp-fill');
}

/** Show the boss bar and label it. Call once when a boss is spawned. */
export function showBossHp(displayName) {
  _grab();
  if (!_root) return;
  if (_name) _name.textContent = displayName || 'Boss';
  if (_fill) _fill.style.width = '100%';
  _root.classList.add('active');
}

/** Update the fill width to match hp/hpMax. Call each frame the boss is alive. */
export function updateBossHp(hp, hpMax) {
  _grab();
  if (!_fill || !hpMax) return;
  const pct = Math.max(0, Math.min(1, hp / hpMax));
  _fill.style.width = (pct * 100).toFixed(1) + '%';
}

/** Hide the bar. Call on boss death or dungeon exit. */
export function hideBossHp() {
  _grab();
  if (!_root) return;
  _root.classList.remove('active');
}
