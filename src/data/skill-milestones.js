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
    { lv: 1,  label: 'First swings',     desc: 'Bare-fisted strikes count. Every successful hit feeds the Combat-style XP routes.' },
    { lv: 5,  label: 'Cleave',           desc: 'Slot 1 ability: cleave swings hit two tiles ahead.' },
    { lv: 8,  label: 'Bronze weapons',   desc: 'Confident with brindle daggers, swords, and axes — the smith will sell to you now.' },
    { lv: 12, label: 'Leap',             desc: 'Slot 2 ability: leap to a clicked tile + AoE on landing.' },
    { lv: 18, label: 'Rend',             desc: 'Slot 3 ability: rend opens a bleed on the target.' },
    { lv: 25, label: 'Whirlwind',        desc: 'Slot 4 ability: spin attack hitting all adjacent enemies.' },
    { lv: 30, label: 'Aimed Shot',       desc: 'Bow-only ability: a charged shot that snaps to the back-tile of any enemy in line.' },
    { lv: 40, label: 'Backstab bonus',   desc: '+25% damage when striking an enemy from their facing-arrow tile.' },
    { lv: 55, label: 'Steel access',     desc: 'Wield cinderbloom-grade weapons without the off-balance penalty.' },
    { lv: 70, label: 'Master Strike',    desc: 'One swing in twenty rolls a guaranteed crit. Reads as "the wrist chooses."' },
    { lv: 99, label: "Atlas's Edge",     desc: 'Endgame title + a unique-tier weapon affix when smithing tideink-quenched blades.' },
  ],
  str: [
    { lv: 1,  label: 'Honest weight',    desc: 'Damage rolls have a +Str floor. Every level pulls the floor up by one.' },
    { lv: 5,  label: 'Tighter grip',     desc: 'Two-handed swings stop slipping at low stamina — small but felt.' },
    { lv: 10, label: 'Bull Rush',        desc: 'Charge through enemies, knocking them back one tile.' },
    { lv: 15, label: 'Sunder',           desc: "Heavy strike that lowers the target's defence for 6s." },
    { lv: 20, label: 'Stun on hit',      desc: 'Tier-3 maces have a 10% chance to stun on hit. The shield is no longer mandatory.' },
    { lv: 25, label: 'Bogiron weapons',  desc: 'Wield Bogiron tier-2 swords, daggers, axes, and the iron sledge.' },
    { lv: 35, label: 'Sunder + Bleed',   desc: 'Sunder also applies a bleed when you Rend the same target within 4s.' },
    { lv: 50, label: 'Cinderbloom',      desc: 'Tier-3 cinderbloom weapons unlock — heaviest swing in the game.' },
    { lv: 65, label: 'Crushing Blow',    desc: 'Heavy attacks ignore 30% of the target armor.' },
    { lv: 80, label: 'Iron will',        desc: 'Knockback / displacement effects are halved against you.' },
    { lv: 99, label: 'Bramble-breaker',  desc: 'Endgame title. Enemies you crit get a 0.5s window where they take +50% damage.' },
  ],
  def: [
    { lv: 1,  label: 'Fundamentals',     desc: 'Each level reduces incoming melee by 1 (down to a 1-damage minimum).' },
    { lv: 5,  label: 'Pickaxe + smith strikes', desc: 'Wearing armor no longer slows pickaxe swings. (Cooldown reads light again.)' },
    { lv: 8,  label: 'Shield Bash',      desc: 'Stun a target briefly with your shield. Slot-able into the action bar.' },
    { lv: 12, label: 'Leather Body',     desc: 'Wear the tier-1 leather body without a Strength penalty.' },
    { lv: 14, label: 'Defensive Stance', desc: '+30% defence buff for 25s. Cooldown 60s.' },
    { lv: 18, label: 'Bogiron Shield',   desc: 'Wield the tier-2 bogiron shield — blocks tusker dashes outright.' },
    { lv: 22, label: 'Riposte',          desc: 'Parry-window counter — negates an incoming hit and reflects 50% damage.' },
    { lv: 30, label: 'Bogiron Cuirass',  desc: 'Wear tier-2 cuirass — most easy-tier enemies stop hurting you noticeably.' },
    { lv: 45, label: 'Cinderbloom Plate', desc: 'Tier-3 plate armor. Caps physical damage taken at 8 per swing.' },
    { lv: 60, label: 'Wightwall',        desc: 'Iframes during Defensive Stance also dodge AoE telegraphs.' },
    { lv: 99, label: 'Bramblewall',      desc: "Endgame title. Riposte's reflect window doubles. The shield never breaks." },
  ],
  hp: [
    { lv: 1,  label: '10 HP starting',   desc: 'Boot value. HP scales to {hp_lv * 2} as you level.' },
    { lv: 5,  label: 'Quick recover',    desc: 'Out-of-combat regen kicks in 2s sooner.' },
    { lv: 10, label: '20 HP cap',        desc: "Reach hp 10. Each level adds 2 max HP. You'll feel the buffer." },
    { lv: 15, label: 'Heal+ on food',    desc: '+1 HP per food eaten. Whicker Stew now heals 5 instead of 4.' },
    { lv: 25, label: 'Last Stand',       desc: 'Slot 4 ability: 5s of damage immunity below 20% HP. Cooldown 90s.' },
    { lv: 35, label: 'Second Wind',      desc: 'Once per dungeon, recover 30% HP on landing a kill below 20% HP.' },
    { lv: 50, label: '100 HP cap',       desc: 'Mid-game survivability — most tier-2 enemies stop one-shotting you.' },
    { lv: 65, label: 'Rugged',           desc: '5% damage-taken reduction layered on top of armor.' },
    { lv: 80, label: 'Rooted in earth',  desc: 'Knockbacks resisted. Status durations against you halved.' },
    { lv: 99, label: 'Hedgemother\'s breath', desc: 'Endgame title. Last Stand recharges twice as fast and grants 30% lifesteal.' },
  ],

  // ---- Gathering (after the Wilds + Earth + Cooking consolidation;
  //      see docs/design/skills-consolidation.md) ----
  wilds: [
    { lv: 1,  label: 'Forager / Angler', desc: 'Pick berries, mushrooms, herbs from forage spots. Fish at any water tile.' },
    { lv: 5,  label: 'Catch chance up',  desc: 'Fishing catch rate climbs faster — fewer empty rod-pulls.' },
    { lv: 8,  label: 'Faster forage',    desc: 'Forage cooldowns drop ~10%. Stacks with the Wayfinding "Catch up" milestone.' },
    { lv: 12, label: 'Mid-tier herbs',   desc: 'Wishrose and Mossvine forageables unlock for inscribing inks.' },
    { lv: 15, label: 'Coalrose chunks',  desc: 'Harvest coalrose deposits at higher Wolds elevations.' },
    { lv: 20, label: 'Larger yield',     desc: 'Forage rolls 1-2 instead of always 1. Mushrooms occasionally roll 3.' },
    { lv: 25, label: 'Foxfire Glow',     desc: 'Rare night-only forageable for endgame charts.' },
    { lv: 35, label: 'Endgame fish + ash', desc: 'Briarcoast fish + Hard Ash logs for tier-3 crafting.' },
    { lv: 50, label: 'Hedge-walk',       desc: 'Walk through hedgerows without aggro. Hedgewolves don\'t hear your steps in grass.' },
    { lv: 70, label: 'Sunken Springs',   desc: 'Bog-only fishing pools open. The water is fishable from a single ledge.' },
    { lv: 99, label: 'Wilds-keeper',     desc: 'Endgame title. Every forage roll is at least the second-best outcome.' },
  ],
  earth: [
    { lv: 1,  label: 'Pickaxe basics',   desc: 'Mosswort + palechalk ore mineable from common nodes.' },
    { lv: 5,  label: 'Pickaxe + smith strikes', desc: 'Faster mine + smelt cooldowns — about 10% reduction.' },
    { lv: 10, label: 'Bronze smithing',  desc: 'Smelt brindle bars and smith bronze daggers / swords / axes.' },
    { lv: 15, label: 'Bogiron tier',     desc: 'Bogiron ore mineable + tier-2 weapons/armor smithable.' },
    { lv: 22, label: 'Bogiron cuirass',  desc: 'Heavy tier-2 chest armor — top of the iron ladder.' },
    { lv: 25, label: 'Twin strike',      desc: 'Smithing now occasionally produces 2 outputs from a single bar (~10%).' },
    { lv: 30, label: 'Cinderbloom tier', desc: 'Coalrose alloy + tier-3 smithing — sword/dagger/axe/helm/shield.' },
    { lv: 38, label: 'Cinderbloom plate', desc: 'Tier-3 endgame plate armor — top of the metal ladder.' },
    { lv: 50, label: 'Mosspepper saving', desc: 'Tier-3 smithing has a 15% chance to refund 1 ore (good for long benches).' },
    { lv: 70, label: 'Hag-iron',         desc: 'After defeating the Hedgemother once, "Hag-iron" alloy unlocks at the forge.' },
    { lv: 99, label: 'Master smith',     desc: 'Endgame title. Crafted gear has a small chance to roll a free unique-tier affix.' },
  ],
  cook: [
    { lv: 1,  label: 'Cook beef',        desc: 'Cook raw_brindle on any fire. The first heal-on-food.' },
    { lv: 5,  label: 'Fewer burns',      desc: 'Burn-on-cook chance starts dropping noticeably. Pippin and sardine become reliable.' },
    { lv: 8,  label: 'Cook hare',        desc: 'Whicker Stew is reliable above this level — burn rate drops below 25%.' },
    { lv: 12, label: 'Cook tusker',      desc: 'Tusker Crackling cookable. Heals 7. The first endgame-portable food.' },
    { lv: 15, label: 'Tier-2 stews',     desc: 'Cook Whicker Stew and Hedgewight Strip for bigger heals.' },
    { lv: 18, label: 'Cook hedgewight',  desc: 'Hedgewight Strip — heals 9. Cook anywhere; never burns above this level.' },
    { lv: 25, label: 'Pantry Stew',      desc: "Cook Maud's 15-HP signature dish. Multi-input recipe (raw_brindle + hedgecap + whitleberry + mosspepper)." },
    { lv: 35, label: 'Sharpened palate', desc: 'Cooked food restores +1 HP overheal for 30s.' },
    { lv: 50, label: 'Banquet',          desc: 'Once per dungeon, prep a meal that buffs party stats for the run.' },
    { lv: 70, label: 'Heart-stew',       desc: 'Hedgemother Heart cookable into a once-per-day full-restore stew.' },
    { lv: 99, label: 'Old Maud',         desc: 'Endgame title. Every meal you cook can never burn. Tip your hat.' },
  ],

  // ---- Crafting / utility ----
  // carto entries here are starter beats only; the full 30-row Wayfinding
  // progression lives in CARTO_UNLOCKS (src/ui/worldMap.js) and the codex
  // Skills tab pulls from there for this skill specifically.
  carto: [
    { lv: 1,  label: 'Hedge ink',        desc: 'Mix the basic ink for low-tier charts.' },
    { lv: 14, label: 'Bog ink hint',     desc: 'A new ink recipe surfaces in the Inscribing Table.' },
    { lv: 25, label: 'Ember ink hint',   desc: 'Tier-3 ink — produces charts with stronger affixes.' },
  ],
  falconry: [
    { lv: 1,  label: 'Pernel',           desc: "Sir Withering's falcon scouts for you. Press R to dispatch on a tile." },
    { lv: 5,  label: 'Faster recall',    desc: 'Falcon return time halved. Less downtime between scouts.' },
    { lv: 10, label: 'Wider scout',      desc: 'Falcon reveals a 5-tile radius (was 3) when dispatched.' },
    { lv: 15, label: 'Sight range +2',   desc: 'Falcon reveals a wider radius around the player passively.' },
    { lv: 22, label: 'Tag enemies',      desc: 'Scouted enemies stay on your minimap for 30s.' },
    { lv: 30, label: 'Combat assist',    desc: "Falcon swoops on aggro'd enemies for chip damage." },
    { lv: 45, label: 'Hawk-eye',         desc: '+5% bow attack accuracy while Pernel is in the air.' },
    { lv: 60, label: 'Cache spotter',    desc: 'Falcon now flags hidden ore + forage caches in scouted tiles.' },
    { lv: 99, label: 'Wing-bound',       desc: 'Endgame title. Pernel is permanent — no recall, no cooldown.' },
  ],
  magic: [
    { lv: 1,  label: 'Wind Strike',      desc: 'Tier-1 air-element damage spell. Costs 1 rune_air.' },
    { lv: 5,  label: 'Earth Strike',     desc: 'Tier-1 earth-element. Hits harder than wind, slower cast.' },
    { lv: 9,  label: 'Water Strike',     desc: 'Tier-1 water-element. Slows the target briefly.' },
    { lv: 13, label: 'Fire Strike',      desc: 'Strongest tier-1 elemental. Costs 1 rune_fire + 1 rune_air.' },
    { lv: 18, label: 'Mind Heal',        desc: 'Tier-2 self-heal. Restores 5 HP. Costs 2 rune_mind.' },
    { lv: 24, label: 'Wind Wave',        desc: 'Tier-2 AoE damage spell, 4-tile range.' },
    { lv: 33, label: 'Earth Bolt',       desc: 'Tier-2 earth — heaviest single-target spell pre-tier-3.' },
    { lv: 45, label: 'Stone Skin',       desc: 'Tier-3 buff — +30% defence for 30s. Costs 3 rune_earth.' },
    { lv: 60, label: 'Tideink Bolt',     desc: 'Tier-3 water — slow + chip damage AoE.' },
    { lv: 75, label: 'Aurora Burst',     desc: 'Tier-3 air — long range, hits 3 targets.' },
    { lv: 99, label: 'Lampwright',       desc: 'Endgame title. All spell costs reduced by 1 rune. Eldra would approve.' },
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
