// Spec 05 — Hedgemother attack pattern table.
//
// Each entry describes a single attack the phase machine can fire:
//   - cooldown:    seconds between attempts (after telegraph + recovery)
//   - telegraph:   seconds the ground decal sits before the hit lands
//   - radius:      meters; hit zone for AoE attacks
//   - damage:      raw damage on hit (0 = effect-only, e.g. root)
//   - effect:      'damage' | 'root' | 'summon' (read by the dispatcher)
//   - effectArgs:  effect-specific tuning (root duration, summon count)
//
// Phase availability is decided by the phase machine in
// src/game/bosses.js — not here. This file just describes the moves.

export const HEDGEMOTHER_ATTACKS = {
  thorn_sweep: {
    cooldown: 4.0,
    telegraph: 1.0,
    radius: 2.8,              // half a small room
    angle: Math.PI,           // 180° forward arc
    damage: 8,
    effect: 'damage',
    decalColor: 0x8a2a2a,     // red ring for damage
  },
  root_stomp: {
    cooldown: 5.0,
    telegraph: 1.0,
    radius: 1.4,              // small ground circle, must dodge by stepping out
    damage: 0,
    effect: 'root',
    effectArgs: { duration: 2.0 },
    decalColor: 0x4a7030,     // green ring for root
  },
  summon: {
    cooldown: 8.0,
    telegraph: 0.0,           // no telegraph; sprites just appear
    damage: 0,
    effect: 'summon',
    effectArgs: { kind: 'hedge_sprite', count: 2, max: 4 },
  },
};

/** Phases: HP% gates which attacks are available. */
export const HEDGEMOTHER_PHASES = [
  { hpFrac: 0.60, attacks: ['thorn_sweep'] },
  { hpFrac: 0.30, attacks: ['thorn_sweep', 'root_stomp'] },
  { hpFrac: 0.00, attacks: ['thorn_sweep', 'root_stomp', 'summon'] },
];

/** Return the attack-name set available at a given HP fraction (0..1). */
export function phaseForHpFrac(frac) {
  for (const p of HEDGEMOTHER_PHASES) {
    if (frac > p.hpFrac) return p.attacks;
  }
  return HEDGEMOTHER_PHASES[HEDGEMOTHER_PHASES.length - 1].attacks;
}
