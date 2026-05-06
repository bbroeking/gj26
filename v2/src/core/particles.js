// Damage numbers, dust puffs, hit-splats. Particles live in world coords;
// they are drawn inside the camera-translated render block.
const particles = [];

export function spawnText(wx, wy, text, color) {
  particles.push({
    kind: 'text', x: wx, y: wy,
    vx: (Math.random() - 0.5) * 0.6, vy: -1.4,
    text, color,
    life: 50, maxLife: 50,
  });
}

export function spawnPuff(wx, wy, color, count = 5) {
  for (let i = 0; i < count; i++) {
    particles.push({
      kind: 'rect',
      x: wx + (Math.random() - 0.5) * 8,
      y: wy + (Math.random() - 0.5) * 4,
      vx: (Math.random() - 0.5) * 2.4,
      vy: -0.8 - Math.random() * 1.6,
      gravity: 0.18,
      size: 2,
      color,
      life: 22 + Math.random() * 12,
      maxLife: 32,
    });
  }
}

export function spawnSparks(wx, wy, count = 6) {
  for (let i = 0; i < count; i++) {
    particles.push({
      kind: 'rect', x: wx, y: wy,
      vx: (Math.random() - 0.5) * 4,
      vy: (Math.random() - 0.5) * 3 - 1,
      gravity: 0.22,
      size: 1,
      color: Math.random() < 0.5 ? '#ffd84a' : '#fff8c8',
      life: 14 + Math.random() * 10,
      maxLife: 24,
    });
  }
}

// OSRS-style hit-splat: a colored square with a number inside.
export function spawnHitSplat(wx, wy, value, kind) {
  const colors = { hit: '#c63', miss: '#3a6', heal: '#3c5', max: '#f33' };
  particles.push({
    kind: 'splat',
    x: wx, y: wy,
    vx: 0, vy: -0.7,
    text: String(value),
    bg: colors[kind] || colors.hit,
    life: 36, maxLife: 36,
  });
}

export function updateParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;
    if (p.gravity) p.vy += p.gravity;
    p.life--;
    if (p.life <= 0) particles.splice(i, 1);
  }
}

export function renderParticles(ctx) {
  for (const p of particles) {
    const a = Math.min(1, p.life / 18);
    ctx.globalAlpha = a;
    if (p.kind === 'text') {
      ctx.font = 'bold 12px monospace';
      ctx.textAlign = 'center';
      ctx.lineWidth = 3;
      ctx.strokeStyle = '#000';
      ctx.strokeText(p.text, p.x, p.y);
      ctx.fillStyle = p.color;
      ctx.fillText(p.text, p.x, p.y);
    } else if (p.kind === 'splat') {
      ctx.fillStyle = p.bg;
      ctx.fillRect(p.x - 9, p.y - 9, 18, 18);
      ctx.fillStyle = '#000';
      ctx.fillRect(p.x - 9, p.y - 9, 18, 1);
      ctx.fillRect(p.x - 9, p.y - 9, 1, 18);
      ctx.font = 'bold 11px monospace';
      ctx.textAlign = 'center';
      ctx.fillStyle = '#fff';
      ctx.fillText(p.text, p.x, p.y + 4);
    } else {
      ctx.fillStyle = p.color;
      ctx.fillRect(Math.floor(p.x), Math.floor(p.y), p.size, p.size);
    }
  }
  ctx.globalAlpha = 1;
}
