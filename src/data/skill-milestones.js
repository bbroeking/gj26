// Per-skill milestones — the "next thing to chase" for each skill, used by:
//   - the Skills popup (shows next-up milestone with countdown to it)
//   - the level-up modal (calls out unlocks when the player crosses a milestone)
//   - skill-gate tooltips on hovered tiles / recipes / crafting stations
//
// Each entry is { lv: <unlock level>, label, desc }. Level numbers were
// chosen to align with existing reqLevel values in items.js / abilities.js
// / spells.js where they exist; otherwise placed at "natural" beats
// (10 / 20 / 40 for skills with no explicit gates).
//
// Per docs/design/07-skill-level-pacing.md §3 — "3-5 milestone unlocks
// per skill (instead of one feature unlock per level)". We pick 3 per
// skill: an early-game beat, a mid-game beat, an endgame beat.

export const SKILL_MILESTONES = {
  // ---- Combat triple ----
  atk: [
    { lv: 5,  label: 'Cleave',          desc: 'Slot 1 ability: cleave swings hit two tiles ahead.' },
    { lv: 12, label: 'Leap',            desc: 'Slot 2 ability: leap to a clicked tile + AoE on landing.' },
    { lv: 18, label: 'Rend',            desc: 'Slot 3 ability: rend opens a bleed on the target.' },
    { lv: 25, label: 'Whirlwind',       desc: 'Slot 4 ability: spin attack hitting all adjacent enemies.' },
  ],
  str: [
    { lv: 10, label: 'Bull Rush',       desc: 'Charge through enemies, knocking them back.' },
    { lv: 15, label: 'Sunder',          desc: 'Heavy strike that lowers the target\'s defence.' },
    { lv: 25, label: 'Bogiron weapons', desc: 'Wield Bogiron tier-2 swords, daggers and axes.' },
  ],
  def: [
    { lv: 8,  label: 'Shield Bash',     desc: 'Stun a target briefly with your shield.' },
    { lv: 14, label: 'Defensive Stance',desc: '+30% defence buff for 25s.' },
    { lv: 22, label: 'Riposte',         desc: 'Parry-window counter — negates an incoming hit.' },
  ],
  hp: [
    { lv: 10, label: '20 HP cap',       desc: 'Default starting cap. Each HP level adds 2 max HP.' },
    { lv: 25, label: 'Last Stand',      desc: 'Slot 4 ability: 5s of damage immunity below 20% HP.' },
    { lv: 50, label: '100 HP cap',      desc: 'Mid-game survivability — most tier-2 enemies stop one-shotting you.' },
  ],

  // ---- Gathering (after the Wilds + Earth + Cooking consolidation;
  //      see docs/design/skills-consolidation.md) ----
  wilds: [
    { lv: 5,  label: 'Catch chance up',   desc: 'Fishing catch rate climbs faster — fewer empty rod-pulls.' },
    { lv: 12, label: 'Mid-tier herbs',    desc: 'Wishrose and Mossvine forageables unlock for inscribing.' },
    { lv: 15, label: 'Coalrose chunks',   desc: 'Harvest coalrose deposits at higher Wolds elevations.' },
    { lv: 25, label: 'Foxfire Glow',      desc: 'Rare night-only forageable for endgame charts.' },
    { lv: 35, label: 'Endgame fish + ash', desc: 'Briarcoast fish + Hard Ash logs for tier-3 crafting.' },
  ],
  earth: [
    { lv: 5,  label: 'Pickaxe + smith strikes', desc: 'Faster mine + smelt cooldowns — about 10% reduction.' },
    { lv: 15, label: 'Bogiron tier',      desc: 'Bogiron ore mineable + tier-2 weapons/armor smithable.' },
    { lv: 22, label: 'Bogiron cuirass',   desc: 'Heavy tier-2 chest armor.' },
    { lv: 30, label: 'Cinderbloom tier',  desc: 'Coalrose alloy + tier-3 smithing — sword/dagger/axe/helm/shield.' },
    { lv: 38, label: 'Cinderbloom plate', desc: 'Tier-3 endgame plate armor — top of the metal ladder.' },
  ],
  cook: [
    { lv: 5,  label: 'Fewer burns',     desc: 'Burn-on-cook chance starts dropping noticeably.' },
    { lv: 15, label: 'Tier-2 stews',    desc: 'Cook Whicker Stew and Hedgewight Strip for bigger heals.' },
    { lv: 25, label: 'Pantry Stew',     desc: 'Cook Maud\'s 15-HP signature dish.' },
  ],

  // ---- Crafting / utility ----
  carto: [
    { lv: 1,  label: 'Hedge ink',       desc: 'Mix the basic ink for low-tier charts.' },
    { lv: 14, label: 'Bog ink hint',    desc: 'A new ink recipe surfaces in the Inscribing Table.' },
    { lv: 25, label: 'Ember ink hint',  desc: 'Tier-3 ink — produces charts with stronger affixes.' },
  ],
  falconry: [
    { lv: 1,  label: 'Pernel',          desc: 'Sir Withering\'s falcon scouts for you.' },
    { lv: 15, label: 'Sight range +2',  desc: 'Falcon reveals a wider radius around the player.' },
    { lv: 30, label: 'Combat assist',   desc: 'Falcon swoops on aggro\'d enemies for chip damage.' },
  ],
  magic: [
    { lv: 1,  label: 'Wind Strike',     desc: 'Tier-1 air-element damage spell.' },
    { lv: 13, label: 'Fire Strike',     desc: 'Strongest tier-1 elemental.' },
    { lv: 24, label: 'Wind Wave',       desc: 'Tier-2 AoE damage spell, 4-tile range.' },
  ],
};

/** Return the next milestone for a given skill at a given level, or null
 *  if the player has cleared all milestones for that skill. */
export function nextMilestone(skill, lv) {
  const list = SKILL_MILESTONES[skill];
  if (!list) return null;
  for (const m of list) if (m.lv > lv) return m;
  return null;
}

/** Return the milestone (if any) that the player just *crossed* by leveling
 *  from `prevLv` to `newLv`. Used by the level-up modal in main.js. */
export function crossedMilestone(skill, prevLv, newLv) {
  const list = SKILL_MILESTONES[skill];
  if (!list) return null;
  for (const m of list) {
    if (m.lv > prevLv && m.lv <= newLv) return m;
  }
  return null;
}
