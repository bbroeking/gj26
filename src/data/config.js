// Tunables — anything you'd want to tweak for balance / feel lives here.
export const CONFIG = {
  tile: 1.0,                 // 1 world unit = 1 tile (3D)
  world: { cols: 60, rows: 30 },

  player: {
    hpMax: 10,
    // Pace dialed back so combat reads as deliberate steps, not flinching.
    moveDuration: 0.26,      // seconds per tile step (walking)
    runMoveDuration: 0.16,   // step duration while running (shift held / chasing)
    // Base swing cooldown in 60-fps frames. 69 ≈ 1.15s — a deliberate
    // "weighted swing" cadence requested in playtest after the 0.40s
    // diablo-fast pass felt twitchy. Dagger (×0.75) ≈ 0.86s; future
    // combat-axe (×1.4) ≈ 1.61s. Recovery is long enough that input
    // buffering (#45) actually matters — pressing during the windup
    // queues the next swing instead of dropping the click.
    attackCdFrames: 69,
    cookCdFrames: 65,
    spawnFacing: 'down',
    height: 1.2,
  },

  combat: {
    // ----- Player swing -----
    // Combat-style pivot: Stardew/Cult-of-the-Lamb floor — every player
    // swing connects (no whiff frustration). hitBase still drives damage
    // QUALITY (skew toward maxHit), but a swing is never zero. Numbers
    // tuned so a level-1 player kills a brindlecow (8 HP) in 4-6 hits at
    // ~1.15s/swing, instead of the old ~50-swing slog.
    hitBase: 0.50,                   // up from 0.30; quality floor
    atkContrib: 0.04,
    defContrib: 0.02,
    hitLo: 0.40,                     // up from 0.10; nothing rolls below 40% quality
    hitHi: 0.98,
    strBase: 1.5,                    // up from 0.5 — wider damage range at low levels
    strContrib: 0.35,                // up from 0.25 — faster scaling
    minMaxHit: 2,                    // up from 1; smallest possible roll is 1-2
    // ----- Enemy swing -----
    // Enemies miss more so the player isn't death-spiraled in pulls.
    enemyHitBase: 0.20,              // (new) lower than the 0.30 it used to share with the player —
                                     // gives players a 60-70% dodge rate against tier-1 grunts so
                                     // pulling 2 brindleboars isn't a death sentence at level 1.
                                     // High-atk enemies still scale up via atkContrib.
    enemyHitLo: 0.10,
    enemyHitHi: 0.85,                // capped down from 0.95 — bosses never auto-hit
    // Per-style XP split. Hp always gets a slice. Total dmg-XP weight ≈ 4.
    styles: {
      accurate:   { att: 4,   str: 0,   def: 0,   hp: 1.33 },
      aggressive: { att: 0,   str: 4,   def: 0,   hp: 1.33 },
      defensive:  { att: 0,   str: 0,   def: 4,   hp: 1.33 },
      controlled: { att: 1.34,str: 1.34,def: 1.34,hp: 1.33 },
    },
    defaultStyle: 'controlled',
  },

  cooking: {
    burnChanceLv1: 0.40,
    burnDecayPerLv: 0.07,
    cookedBeefHeal: 5,
    cookXpPerSuccess: 6,
    cookXpPerBurn: 1,
  },

  inventory: { slots: 28 },
  equipment: ['weapon', 'body', 'helm', 'shield'],

  camera: {
    pitch: Math.PI / 4,      // 45° tilt
    distance: 7,             // pulled in 2 units so the knight reads as a hero
    height: 6,
    fov: 50,
  },

  colors: {
    sky:        0xa0d8ff,
    fog:        0xb6c7d9,
    ground:     0x6ba03d,
    ground2:    0x4a7a2f,
    path:       0xcaa37b,
    water:      0x4a6cba,
    sand:       0xdec295,
    stone:      0x9a9aa2,
    wood:       0x8a5a2a,
    fire_low:   0xff8a3a,
    fire_high:  0xffd84a,
    cow_white:  0xffffff,
    cow_spot:   0x1a1a1a,
    cook_white: 0xffffff,
    cook_skin:  0xfcd1a4,
    cook_apron: 0xc0392b,
    skin:       0xfcd1a4,
    plume:      0xc0392b,
    helmet:     0x9a9aa2,
    tunic:      0xc0392b,
    pants:      0x5a3a1a,
  },
};

// Total XP needed to reach level n. Quadratic with a linear floor so the
// low end takes a few kills instead of one. Pre-fix curve was just
// `(n-1)² × 8`, which made level 2 cost 8 XP — under one kill at 12 xp.
// Linear term raises the floor without bloating the high end:
//   level 2  → 32 XP   (~3 kills)
//   level 5  → 256 XP
//   level 10 → 936 XP
//   level 25 → 5,376 XP
//   level 99 → 79,968 XP (was 76,832; basically unchanged at the cap)
export function xpForLevel(n) {
  const k = n - 1;
  return k * k * 8 + k * 32;
}
