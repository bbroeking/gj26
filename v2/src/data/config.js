// Centralized tunables. Anything you might want to tweak for balance lives
// here, not buried in a system file.
export const CONFIG = {
  tile: 32,
  world: { cols: 40, rows: 28 },
  player: {
    hpMax: 10,
    moveSpeed: 4,           // pixels per frame during grid tween
    attackCdFrames: 60,     // ~1 second
    cookCdFrames: 50,
    spawnFacing: 'down',
  },
  combat: {
    // Hit chance: clamp(base + atkContrib*(atkLv+atkBonus) - defContrib*defLv, lo, hi)
    hitBase: 0.30,
    atkContrib: 0.04,
    defContrib: 0.02,
    hitLo: 0.10,
    hitHi: 0.95,
    // Max hit: floor(strBase + strContrib * (strLv + strBonus))
    strBase: 0.5,
    strContrib: 0.25,        // 4 str per damage, OSRS-ish
    minMaxHit: 1,
    xpSplit: { att: 4, str: 4, def: 0, hp: 1.33 }, // controlled
  },
  cooking: {
    burnChanceLv1: 0.40,
    burnDecayPerLv: 0.07,
    healPerCookedFish: 4,    // not used in v2 MVP — kept for parity with v1
    cookedBeefHeal: 5,
    cookXpPerSuccess: 6,
    cookXpPerBurn: 1,
  },
  inventory: { slots: 28 },
  equipment: ['weapon', 'body', 'helm', 'shield'],
};

export function xpForLevel(n) {
  return (n - 1) * (n - 1) * 8;
}
