// Boot — wires modules, loads world, starts the loop.
import { ctx, TILE } from './core/canvas.js';
import { camera, updateCamera } from './core/camera.js';
import { drawSprite, render } from './core/render.js';
import { updateParticles, spawnSparks, spawnText } from './core/particles.js';
import { CONFIG } from './data/config.js';
import { ITEMS } from './data/items.js';
import { NPC_DEFS } from './data/npcs.js';
import { World } from './game/world.js';
import { createPlayer } from './game/player.js';
import { spawnCow, updateEnemy } from './game/enemies.js';
import { attackEnemy } from './game/combat.js';
import { talkToNpc } from './game/npcs.js';
import { updatePlayerController } from './archetypes/topdown/controller.js';
import { questSummary } from './game/quest.js';
import { xpProgress, awardXp, SKILL_KEYS } from './game/skills.js';

// ---------- LOAD WORLD ----------
const mapText = await fetch('src/data/map.txt').then(r => r.text());
const world = new World(mapText);
const player = createPlayer(world.spawn.x, world.spawn.y);
const enemies = world.cowSpawns.map(p => spawnCow(p.x, p.y));

// give player a basic body so they're not naked at level 1
player.inventory.add('leather_body', 1);
player.inventory.add('wooden_shield', 1);
player.inventory.equipped.body = 'leather_body';
player.inventory.equipped.shield = 'wooden_shield';
player.inventory.remove('leather_body', 1);
player.inventory.remove('wooden_shield', 1);

// ---------- LOG / HUD ----------
const logEl = document.getElementById('log');
const logEntries = [];
function log(kind, msg) {
  logEntries.push({ kind, msg });
  if (logEntries.length > 18) logEntries.shift();
  logEl.innerHTML = logEntries.map(e =>
    `<div class="entry ${e.kind}">${escape(e.msg)}</div>`).join('');
}
function escape(s) {
  return s.replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
}

const SKILL_LABELS = { atk: 'Attack', str: 'Strength', def: 'Defence', hp: 'HP', cook: 'Cooking' };

function renderStats() {
  const skillsEl = document.getElementById('skills');
  if (skillsEl) {
    skillsEl.innerHTML = SKILL_KEYS.map(k => {
      const lv = player.skills[k].lv;
      const pct = xpProgress(player, k);
      return `<div class="sk">
        <div class="row"><span>${SKILL_LABELS[k]}</span><span class="lv">Lv ${lv}</span></div>
        <div class="bar tiny"><div class="bar-fill xp" style="width:${pct}%"></div></div>
      </div>`;
    }).join('');
  }
  document.getElementById('hp-num').textContent = Math.max(0, player.hp);
  document.getElementById('hp-max').textContent = player.hpMax;
  document.getElementById('hp-bar').style.width = (100 * player.hp / player.hpMax) + '%';
}

function renderInv() {
  const el = document.getElementById('inv');
  let html = '';
  for (let i = 0; i < CONFIG.inventory.slots; i++) {
    const s = player.inventory.slots[i];
    if (s) {
      const def = ITEMS[s.id];
      const equipped = Object.values(player.inventory.equipped).includes(s.id) ? ' ★' : '';
      html += `<div class="slot" data-idx="${i}" title="${def.name}${equipped}">
        <div class="icon">${def.icon}</div>${s.qty > 1 ? s.qty : ''}</div>`;
    } else {
      html += '<div class="slot"></div>';
    }
  }
  el.innerHTML = html;
  el.querySelectorAll('.slot[data-idx]').forEach(slot => {
    slot.addEventListener('click', () => {
      const idx = +slot.dataset.idx;
      const r = player.inventory.use(idx, player);
      if (r) {
        if (r.kind === 'equip') log('hint', `Equipped ${ITEMS[r.id].name}.`);
        else if (r.kind === 'eat') log('hint', `Ate ${ITEMS[r.id].name}: +${r.heal} HP.`);
        else if (r.kind === 'full_hp') log('hint', 'You are at full health.');
        renderEquipped(); renderInv(); renderStats();
      }
    });
  });
}

function renderEquipped() {
  const el = document.getElementById('equipped');
  if (!el) return;
  const slots = ['weapon', 'body', 'helm', 'shield'];
  el.innerHTML = slots.map(s => {
    const id = player.inventory.equipped[s];
    if (!id) return `<div class="eq-slot"><span>${s}</span><span class="empty">—</span></div>`;
    return `<div class="eq-slot"><span>${s}</span><span>${ITEMS[id].icon} ${ITEMS[id].name}</span></div>`;
  }).join('');
}

function renderQuest() {
  const el = document.getElementById('quest');
  const summary = questSummary(player.quest);
  el.innerHTML = summary.map(s => {
    const mark = s.state === 'done' ? '✓' : (s.state === 'active' ? '▶' : '·');
    return `<div class="step ${s.state}">${mark} ${escape(s.text)}</div>`;
  }).join('');
}

// ---------- INTERACT DISPATCH ----------
function isBlocked(tx, ty, exclude) {
  if (world.isTerrainBlocked(tx, ty)) return true;
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) return true;
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) return true;
  for (const t of world.treePositions) if (t.x === tx && t.y === ty) return true;
  for (const e of enemies) if (e !== exclude && e.alive && e.x === tx && e.y === ty) return true;
  return false;
}

function tryCookFish() {
  if (player.attackCd > 0) return true;
  if (player.inventory.count('raw_beef') === 0) {
    log('hint', 'You need Raw Beef to cook here.');
    return true;
  }
  player.attackCd = CONFIG.cooking.cookCdFrames;
  player.inventory.remove('raw_beef', 1);
  const burnChance = Math.max(0,
    CONFIG.cooking.burnChanceLv1 - CONFIG.cooking.burnDecayPerLv * (player.skills.cook.lv - 1));
  if (Math.random() < burnChance) {
    player.inventory.add('burnt_beef', 1);
    awardXp(player, 'cook', CONFIG.cooking.cookXpPerBurn, log);
    log('skill', '🔥 Burnt Beef. Try again with higher Cooking.');
  } else {
    player.inventory.add('cooked_beef', 1);
    awardXp(player, 'cook', CONFIG.cooking.cookXpPerSuccess, log);
    log('skill', '🍖 Cooked Beef. (+6 Cooking XP)');
    spawnSparks(world.firePos.x * TILE + 16, world.firePos.y * TILE + 16, 8);
    spawnText(world.firePos.x * TILE + 16, world.firePos.y * TILE + 4, '+6 Cook', '#ffaa55');
  }
  renderInv();
  return true;
}

function interactAt(tx, ty) {
  // Cook NPC?
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) {
    talkToNpc('cook', player, log);
    renderQuest(); renderInv(); renderStats(); renderEquipped();
    return true;
  }
  // Fire?
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) {
    return tryCookFish();
  }
  // Cow?
  for (const e of enemies) {
    if (e.alive && e.x === tx && e.y === ty) {
      const before = player.skills.atk.lv;
      attackEnemy(player, e, log);
      renderStats(); renderInv();
      return true;
    }
  }
  return false;
}

// ---------- PROMPT ABOVE FACING TILE ----------
function interactLabel(tx, ty) {
  if (world.cookSpawn && world.cookSpawn.x === tx && world.cookSpawn.y === ty) return `Talk to Cook`;
  if (world.firePos && world.firePos.x === tx && world.firePos.y === ty) return `Cook`;
  for (const e of enemies) if (e.alive && e.x === tx && e.y === ty) return `Attack Cow`;
  return null;
}

// ---------- LOOP ----------
function buildDrawables() {
  const drawables = [];

  // shadows
  for (const t of world.treePositions) {
    drawables.push({
      y: t.y * TILE + 24,
      draw: () => {
        ctx.fillStyle = 'rgba(0,0,0,0.18)';
        ctx.beginPath();
        ctx.ellipse(t.x * TILE + 16, t.y * TILE + 28, 10, 4, 0, 0, Math.PI * 2);
        ctx.fill();
        drawSprite('tree', t.x * TILE, t.y * TILE);
      },
    });
  }

  if (world.firePos) {
    drawables.push({
      y: world.firePos.y * TILE + 24,
      draw: () => {
        drawSprite('fire', world.firePos.x * TILE, world.firePos.y * TILE);
        const t = Date.now() / 100;
        const a = 0.3 + Math.sin(t) * 0.2;
        ctx.fillStyle = `rgba(255,180,60,${a})`;
        ctx.fillRect(world.firePos.x * TILE + 13, world.firePos.y * TILE + 18, 6, 4);
      },
    });
  }

  if (world.cookSpawn) {
    drawables.push({
      y: world.cookSpawn.y * TILE + 24,
      draw: () => {
        drawSprite('cook', world.cookSpawn.x * TILE, world.cookSpawn.y * TILE);
        // ! marker if quest available
        if (!player.quest.flags.cookTalked || player.inventory.count('cooked_beef') > 0) {
          if (!player.quest.flags.finished) {
            const my = world.cookSpawn.y * TILE - 10 + Math.sin(Date.now() / 250) * 2;
            ctx.fillStyle = '#ecc94b';
            ctx.font = 'bold 14px monospace';
            ctx.textAlign = 'center';
            ctx.fillText('!', world.cookSpawn.x * TILE + 16, my);
          }
        }
      },
    });
  }

  for (const e of enemies) {
    if (!e.alive) continue;
    drawables.push({
      y: e.py + 24,
      draw: () => {
        ctx.fillStyle = 'rgba(0,0,0,0.18)';
        ctx.beginPath();
        ctx.ellipse(e.px + 16, e.py + 28, 9, 3, 0, 0, Math.PI * 2);
        ctx.fill();
        drawSprite('cow', e.px, e.py, { flash: e.hurtT > 0 });
        if (e.hp < e.hpMax) {
          ctx.fillStyle = '#000';
          ctx.fillRect(e.px + 6, e.py + 2, 20, 4);
          ctx.fillStyle = '#c0392b';
          ctx.fillRect(e.px + 7, e.py + 3, Math.max(0, 18 * e.hp / e.hpMax), 2);
        }
      },
    });
  }

  drawables.push({
    y: player.py + 24,
    draw: () => {
      ctx.fillStyle = 'rgba(0,0,0,0.18)';
      ctx.beginPath();
      ctx.ellipse(player.px + 16, player.py + 28, 9, 3, 0, 0, Math.PI * 2);
      ctx.fill();
      const stepFrame = player.moving && (Math.floor(player.bobT / 8) % 2) === 1;
      const sprite = 'player_' + player.dir + (stepFrame ? '_walk' : '');
      const bob = player.moving ? Math.floor(Math.sin(player.bobT * 0.4) * 1) : 0;
      drawSprite(sprite, player.px, player.py, { bob, flash: player.hurtT > 0 });
    },
  });

  // facing-tile prompt (drawn last, on top)
  if (!player.moving) {
    const FACING = { down: [0, 1], up: [0, -1], left: [-1, 0], right: [1, 0] };
    const [dx, dy] = FACING[player.dir];
    const tx = player.x + dx;
    const ty = player.y + dy;
    const label = interactLabel(tx, ty);
    if (label) {
      drawables.push({
        y: ty * TILE + 999, // always last
        draw: () => {
          const px = tx * TILE + 16;
          const py = ty * TILE + 32;
          ctx.font = 'bold 10px monospace';
          ctx.textAlign = 'center';
          ctx.lineWidth = 3;
          ctx.strokeStyle = 'rgba(0,0,0,0.85)';
          ctx.strokeText('[Space] ' + label, px, py);
          ctx.fillStyle = '#ffd84a';
          ctx.fillText('[Space] ' + label, px, py);
        },
      });
    }
  }
  return drawables;
}

function loop() {
  updatePlayerController(player, isBlocked, interactAt, log);
  for (const e of enemies) updateEnemy(e, player, world, isBlocked, log);
  updateParticles();
  updateCamera(player);
  render(world, buildDrawables());

  // passive HP regen out of combat (every ~10s, +1)
  if (player.hp < player.hpMax && player.attackCd === 0 && Math.random() < 0.003) {
    player.hp = Math.min(player.hpMax, player.hp + 1);
    renderStats();
  }
  requestAnimationFrame(loop);
}

// ---------- BOOT ----------
log('hint', 'Welcome to Lumbridge.');
log('hint', 'WASD/arrows to move. Space/E to interact.');
log('hint', 'Find the Cook (gold !) — start the quest.');
renderStats();
renderInv();
renderEquipped();
renderQuest();
requestAnimationFrame(loop);
