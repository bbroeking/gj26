// DOM-overlay floating text/splats anchored to 3D world positions.
// Cheaper than 3D text; sits on top of canvas.
import * as THREE from 'three';

const layer = document.getElementById('floaters');
const _v = new THREE.Vector3();

const floaters = []; // { el, world: Vector3, life, maxLife, vy, vx }

// Pre-stagger an arrival point with a small random offset so consecutive
// floaters at the same world position fan out instead of stacking. Also
// gives each floater a slight horizontal drift direction so multi-hit
// AoE swings (cleave, leap, whirlwind) read as a burst.
function _staggered(worldPos) {
  const out = worldPos.clone();
  out.x += (Math.random() - 0.5) * 0.20;
  out.z += (Math.random() - 0.5) * 0.10;
  return out;
}

export function spawnFloat(worldPos, text, kind = 'hit') {
  const el = document.createElement('div');
  el.className = 'floater';
  el.textContent = text;
  el.style.color = (
    kind === 'miss'   ? '#9ad' :
    kind === 'heal'   ? '#7e7' :
    kind === 'xp'     ? '#fc6' :
    kind === 'level'  ? '#ffd84a' :
    kind === 'pickup' ? '#d4af37' :   // warm gold for loot pickup
                        '#f66'   // hit
  );
  // Tag the kind so CSS can react (XP gets a scale-up + glow pulse).
  el.classList.add('floater-' + kind);
  layer.appendChild(el);
  floaters.push({
    el,
    world: _staggered(worldPos),
    vy: -0.012,
    vx: (Math.random() - 0.5) * 0.006,
    life: 60,
    maxLife: 60,
  });
}

/** kind: 'hit' (default brown) | 'miss' (green) | 'heal' (green) |
 *        'crit' (yellow + 1.4× larger) | 'kill' (red + 1.6× largest) */
export function spawnSplat(worldPos, value, kind = 'hit') {
  const el = document.createElement('div');
  el.className = 'floater';
  // Color & weight by kind. Crits and kills get bigger fonts so the
  // player's eye locks onto them across a busy battlefield.
  let bg, scale = 1, fontWeight = 'normal';
  if      (kind === 'miss') { bg = '#3a6'; }
  else if (kind === 'heal') { bg = '#3c5'; }
  else if (kind === 'crit') { bg = '#d4a020'; scale = 1.4; fontWeight = 'bold'; }
  else if (kind === 'kill') { bg = '#c4302a'; scale = 1.6; fontWeight = 'bold'; }
  else                       { bg = '#c63'; }
  const fontSize = `${Math.round(13 * scale)}px`;
  el.innerHTML = `<span style="display:inline-block; padding:1px 5px;
    background:${bg}; color:#fff; border:1px solid #000;
    border-radius:2px; font-size:${fontSize}; font-weight:${fontWeight};
    text-shadow: 0 1px 0 rgba(0,0,0,0.6);">${value}</span>`;
  layer.appendChild(el);
  floaters.push({
    el,
    world: _staggered(worldPos),
    // Crits / kills rise faster and live longer so the bigger number
    // has time to be read.
    vy: -(0.014 * (kind === 'crit' ? 1.2 : kind === 'kill' ? 1.3 : 1)),
    vx: (Math.random() - 0.5) * 0.005,
    life: kind === 'kill' ? 70 : kind === 'crit' ? 60 : 50,
    maxLife: 70,
  });
}

export function updateFloaters(camera, viewW, viewH) {
  for (let i = floaters.length - 1; i >= 0; i--) {
    const f = floaters[i];
    f.world.y += -f.vy; // text rises in screen space → world Y up
    f.world.x += f.vx;
    f.life--;
    // project to screen
    _v.copy(f.world).project(camera);
    const sx = (_v.x * 0.5 + 0.5) * viewW;
    const sy = (-_v.y * 0.5 + 0.5) * viewH;
    f.el.style.left = sx + 'px';
    f.el.style.top = sy + 'px';
    f.el.style.opacity = Math.min(1, f.life / 18);
    if (f.life <= 0) {
      f.el.remove();
      floaters.splice(i, 1);
    }
  }
}
