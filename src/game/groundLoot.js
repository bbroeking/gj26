// Ground loot — items pop out of enemies / chests as 3D meshes, fall under
// gravity, settle on the floor, and get picked up when the player walks over.
// Cozy variant: items NEVER expire. If your bag is full, they wait.
//
// Public API:
//   spawnGroundLoot(scene, worldPos, itemId, qty)   — drop one stack
//   spawnArc(scene, originPos, drops)               — chest pop: arc multiple
//   updateGroundLoot(dt, player, log, renderInv)    — call every frame
//   clearGroundLoot(scene)                          — call when leaving dungeon

import * as THREE from 'three';
import { ITEMS } from '../data/items.js';
import { spawnFloat } from '../core/floaters.js';

// Color-key by archetype so a glance at a loot pile reads at a distance.
// Archetype drives the BLOB color (the item-itself color); rarity (below)
// drives the GLOW + RIM so a player can scan a battlefield and tell what's
// dropped vs what's just trash.
const ARCHETYPE_COLORS = {
  weapon:   0xb58637,
  body:     0x8a6438,
  shield:   0x8a6438,
  tool:     0x6e4a2a,
  food:     0x9a5a3a,
  ore:      0x6b3e2a,
  bar:      0x5a4830,
  hide:     0x8a6438,
  wood:     0x6e4a2a,
  reagent:  0x6f8a3f,
  currency: 0xd4b143,
  specimen: 0xc63030,
  chart:    0xa08770,
  default:  0x6e4a2a,
};

// 4-tier rarity — ARPG standard. Drives loot glow color, rim color,
// drop-time chime, and pickup-floater style.
const RARITY_COLORS = {
  common:   0xc8c8c0,   // cool off-white — minimal glow, sometimes none
  uncommon: 0x4ec96a,   // green — common-quality finds
  rare:     0x4a8ae0,   // blue — gear-tier, charts, refined inks
  unique:   0xffd864,   // gold — endgame, quest items, named drops
};
const RARITY_GLOW = {
  common:   { intensity: 0.35, range: 1.4 },
  uncommon: { intensity: 0.70, range: 2.0 },
  rare:     { intensity: 1.10, range: 2.8 },
  unique:   { intensity: 1.60, range: 3.6 },
};
// Hand-tagged uniques — quest items, named drops, anything that should
// FANFARE on drop.
const _UNIQUES = new Set([
  'thorn_crown', 'falcons_whistle', 'apprentices_hammer',
  'hods_anvil_token', 'whickerhares_foot', 'aurora_shard',
]);
function rarityOf(itemId) {
  if (_UNIQUES.has(itemId)) return 'unique';
  const def = ITEMS[itemId];
  if (!def) return 'common';
  // Steel-tier (cinderbloom) = unique. Iron-tier (bogiron) = rare.
  if (def.tier === 'steel') return 'unique';
  if (def.tier === 'iron')  return 'rare';
  // Tier-1 weapons / armor / tools = uncommon.
  if (def.slot === 'weapon' || def.slot === 'shield' ||
      def.slot === 'body' || def.tool) return 'uncommon';
  // Charts → rare; parchment lore → uncommon; runes → uncommon; bars → uncommon
  if (def.chart || itemId.startsWith('chart_')) return 'rare';
  if (def.lore || itemId.startsWith('parchment_')) return 'uncommon';
  if (itemId.startsWith('rune_')) return 'uncommon';
  if (itemId.endsWith('_bar') || itemId === 'lustrous_ink' || itemId === 'refined_ink') return 'uncommon';
  // Everything else (ores, raw food, hides, coin) is common.
  return 'common';
}

function archetypeOf(itemId) {
  const def = ITEMS[itemId];
  if (!def) return 'default';
  if (def.archetype) return def.archetype;
  if (def.slot === 'weapon') return 'weapon';
  if (def.slot === 'shield') return 'shield';
  if (def.slot)     return 'body';
  if (def.tool)     return 'tool';
  if (def.food)     return 'food';
  if (def.chart)    return 'chart';
  if (itemId === 'coin')                  return 'currency';
  if (/_ore$/.test(itemId) || itemId === 'coalrose') return 'ore';
  if (/_bar$/.test(itemId))               return 'bar';
  if (/_pelt$|_flank$|_tusk$|downfeather/.test(itemId)) return 'hide';
  if (/_ink$|essence|glyph/.test(itemId)) return 'reagent';
  if (itemId === 'logs')                  return 'wood';
  return 'default';
}

const _drops = [];   // active ground-item Object3Ds
const _G = 9.8;      // gravity for arc

export function spawnGroundLoot(scene, position, itemId, qty = 1, opts = {}) {
  const color = ARCHETYPE_COLORS[archetypeOf(itemId)] || ARCHETYPE_COLORS.default;
  const rarity = rarityOf(itemId);
  const rarityColor = RARITY_COLORS[rarity];
  const group = new THREE.Group();

  // Prefer a real GLB model for this item id if one was loaded.
  // Fall back to the default colored box otherwise.
  let usedGLB = false;
  try {
    // Avoid a hard import cycle by reaching through window. characters.js
    // exposes the lookup helper.
    const glbBuilder = (typeof window !== 'undefined') ? window.__gj26_buildItemGLB : null;
    if (glbBuilder) {
      const inst = glbBuilder(itemId);
      if (inst) {
        inst.position.y = 0.10;
        group.add(inst);
        usedGLB = true;
      }
    }
  } catch (_) { /* fall through to box */ }

  if (!usedGLB) {
    // Slightly rounded, soft-toon item blob. Rare archetypes (gear,
    // chart, refined ink) get a slightly larger blob so they stand out
    // against floor at a glance.
    const arche = archetypeOf(itemId);
    const isRare = arche === 'weapon' || arche === 'body' || arche === 'shield' ||
                   arche === 'chart'  || itemId === 'refined_ink';
    const size = isRare ? 0.22 : 0.18;
    const blob = new THREE.Mesh(
      new THREE.BoxGeometry(size, size, size),
      new THREE.MeshToonMaterial({ color })
    );
    blob.position.y = 0.10;
    group.add(blob);

    // Rarity-tinted rim — every drop above 'common' gets a colored rim
    // beneath the blob. Common items skip the rim so coins + ores read
    // as "trash" at a glance.
    if (rarity !== 'common' || arche === 'currency') {
      const rim = new THREE.Mesh(
        new THREE.BoxGeometry(size + 0.04, 0.02, size + 0.04),
        new THREE.MeshToonMaterial({
          color: arche === 'currency' ? 0xd4af37 : rarityColor,
        }),
      );
      rim.position.y = 0.03;
      group.add(rim);
    }
  }

  // Point-light glow — color + brightness + range all driven by rarity.
  // Common drops still glow weakly so they're visible on dim dungeon
  // floors; uniques throw a 3.6-tile gold pool that catches the eye
  // across a room.
  const glowSpec = RARITY_GLOW[rarity];
  const glow = new THREE.PointLight(rarityColor, glowSpec.intensity, glowSpec.range);
  glow.position.y = 0.30;
  group.add(glow);

  // Drop-time fanfare — tier-matched chime so the player HEARS what
  // dropped before they look down. Uniques get the full 4-note ascend.
  if (rarity !== 'common') {
    import('../core/sfx.js').then(m => m.sfx.lootDrop(rarity)).catch(() => {});
  }

  group.position.copy(position);
  group.userData = {
    isGroundLoot: true,
    itemId, qty, rarity,
    bornAt: performance.now(),
    vy: opts.vy ?? (1 + Math.random() * 1.5),
    vx: opts.vx ?? (Math.random() - 0.5) * 1.0,
    vz: opts.vz ?? (Math.random() - 0.5) * 1.0,
    settled: false,
    floorY: position.y,
    bobPhase: Math.random() * Math.PI * 2,
  };
  scene.add(group);
  _drops.push(group);
  return group;
}

/** Chest pop: spawn N drops bursting out of one origin. */
export function spawnArc(scene, originPos, drops) {
  drops.forEach((d, i) => {
    const angle = (i / drops.length) * Math.PI * 2 + Math.random() * 0.4;
    const speed = 1.2 + Math.random() * 0.8;
    spawnGroundLoot(scene, originPos, d.id, d.qty, {
      vy: 2.2 + Math.random() * 0.8,
      vx: Math.cos(angle) * speed,
      vz: Math.sin(angle) * speed,
    });
  });
}

const PICKUP_RADIUS = 0.55;
const MAGNET_RADIUS = 1.60;     // start drifting toward the player at this range
const MAGNET_PULL   = 4.5;      // m/s toward player when in magnet zone

export function updateGroundLoot(dt, player, log, renderInv) {
  for (let i = _drops.length - 1; i >= 0; i--) {
    const drop = _drops[i];
    const ud = drop.userData;

    if (!ud.settled) {
      ud.vy -= _G * dt;
      drop.position.x += ud.vx * dt;
      drop.position.y += ud.vy * dt;
      drop.position.z += ud.vz * dt;
      if (drop.position.y <= ud.floorY) {
        drop.position.y = ud.floorY;
        ud.vy = ud.vx = ud.vz = 0;
        ud.settled = true;
      }
    } else {
      // Lazy idle bob + spin
      const t = (performance.now() - ud.bornAt) / 1000;
      drop.children[0].position.y = 0.10 + Math.sin(t * 1.5 + ud.bobPhase) * 0.04;
      drop.children[0].rotation.y = t * 0.8;
    }

    // Distance to player (XZ plane only; ignore vertical).
    const dx = drop.position.x - player.pos.x;
    const dz = drop.position.z - player.pos.z;
    const distSq = dx * dx + dz * dz;

    // Magnet pull — drops within MAGNET_RADIUS drift toward the player so
    // sweeping past a pile collects it without precise alignment. Skip if
    // the bag is full (tracked via bagFullNoticed) so unreachable drops
    // don't follow the player around.
    if (ud.settled && !ud.bagFullThisFrame && distSq < MAGNET_RADIUS * MAGNET_RADIUS) {
      const dist = Math.sqrt(distSq) || 0.0001;
      const pull = Math.min(MAGNET_PULL * dt, dist);   // never overshoot
      drop.position.x -= (dx / dist) * pull;
      drop.position.z -= (dz / dist) * pull;
    }

    // Walk-over pickup
    if (ud.settled && distSq < PICKUP_RADIUS * PICKUP_RADIUS) {
      const ok = player.inventory.add(ud.itemId, ud.qty);
      if (ok) {
        const def = ITEMS[ud.itemId];
        const name = def?.name || ud.itemId;
        // Pickup log line escalates with rarity so the chronicle reads
        // the find as a moment when it's something special.
        const prefix = ud.rarity === 'unique' ? '★ '
                     : ud.rarity === 'rare'   ? '◆ '
                     :                          '+ ';
        log('skill', `${prefix}${ud.qty}× ${name}`);
        // Visible pickup feedback — floater with the item glyph + qty,
        // anchored above the player. Floater kind escalates with rarity:
        // unique → 'level' (gold, large), rare → 'pickup' (warm-gold),
        // others → 'pickup' (still warm). The drop-time chime already
        // told the player a unique landed; this is the confirmation.
        const px = player.pos.x, pz = player.pos.z;
        const tip = new THREE.Vector3(px, 1.4, pz);
        const label = `+${ud.qty} ${def?.icon ? def.icon + ' ' : ''}${name}`;
        spawnFloat(tip, label, ud.rarity === 'unique' ? 'level' : 'pickup');
        scene_remove(drop);
        _drops.splice(i, 1);
        renderInv?.();
        ud.bagFullThisFrame = false;
        // Tier-matched pickup chime — common stays as the original 2-note
        // bling; rare/unique replay the louder drop fanfare so picking
        // up a gold drop feels like the same moment as seeing it land.
        import('../core/sfx.js').then(m => {
          if (ud.rarity === 'unique' || ud.rarity === 'rare') m.sfx.lootDrop(ud.rarity);
          else m.sfx.pickup();
        });
      } else {
        // Bag full → leave it. Throttle the "Bag full" floater (every 4s
        // per drop) so we don't spam. Also flag bagFullThisFrame so the
        // magnet doesn't keep yanking unreachable drops.
        ud.bagFullThisFrame = true;
        if (!ud.bagFullNoticed || performance.now() - ud.bagFullNoticed > 4000) {
          ud.bagFullNoticed = performance.now();
          const tip = new THREE.Vector3(drop.position.x, drop.position.y + 0.6, drop.position.z);
          spawnFloat(tip, 'Bag full', 'miss');
        }
      }
    } else {
      ud.bagFullThisFrame = false;
    }
  }
}

export function clearGroundLoot(scene) {
  for (const drop of _drops) scene_remove(drop);
  _drops.length = 0;
}

function scene_remove(obj) {
  // Walk up to find the scene root and remove the whole drop group
  let p = obj;
  while (p.parent && p.parent.parent) p = p.parent;
  obj.parent?.remove(obj);
}
