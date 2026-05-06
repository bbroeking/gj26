---
tags: [research, implementation, fate, arpg, reference]
---

# Fate (2005) — Implementation Summary

**Implementation-focused summary of *Fate* by Travis Baldree.** This doc is for *building* a Fate-like — schemas, numbers, formulas, loops, and decision trees. The companion [[fate-2005-deep-dive]] covers narrative, lore, and design philosophy; this doc tells you what to ship.

> [!tip] How to read this
> Each section maps roughly to a code module. Numbers in **bold** are concrete values pulled from primary sources — implement these.

---

## 1. The shipping checklist

A minimum-viable Fate clone needs:

- [ ] **Procgen dungeon** — randomized layouts, monsters, treasure per floor; depth-tiered difficulty
- [ ] **Class-free progression** — 4 attributes, 15 skills, level-up = 5 attr + 1 skill point
- [ ] **Dual XP + Fame system** — XP from kills, Fame from bosses & quests
- [ ] **Pet** — combat companion + inventory mule + town-runner
- [ ] **Fishing → pet transmutation** — 4 fish tiers, 4 transformation durations
- [ ] **Town hub** — Grove with ~10 NPCs, 4 vendors, 1 healer, 1 enchanter
- [ ] **Dungeon-roaming vendors** — Pikko + Getts spawning rarely
- [ ] **Random end-boss** — spawns on floor **40–50** (random per save)
- [ ] **Retirement system** — heirloom passes with **+25% all numeric stats per generation**
- [ ] **4 difficulty levels** — Easy / Normal / Hardest, plus Hardcore (permadeath)
- [ ] **8 weapon classes**, **3 spell categories** with capacity 6 each in spellbook

---

## 2. Player state schema

```ts
type PlayerState = {
  // Identity
  id: string;
  name: string;
  generation: number;        // increments on retirement, drives heirloom buff
  fame: number;              // accumulated across generations
  
  // Stats
  level: number;             // 1..99 (base game), 1..199 (Undiscovered Realms), uncapped (Traitor Soul+)
  xp: number;
  attributes: {              // 5 points per level-up to distribute
    strength: number;        // weapon damage, str-gated gear
    dexterity: number;       // hit chance, evasion
    vitality: number;        // hp, stamina
    magic: number;           // spell power, magic-gated gear
  };
  unspentAttrPoints: number;
  
  // Skills (15 total, 1 point per level-up)
  skills: {
    swordSkill: number;
    axeSkill: number;
    clubSkill: number;
    hammerSkill: number;
    bowSkill: number;        // covers crossbow too
    polearmSkill: number;
    spearSkill: number;
    staffSkill: number;
    attackMagic: number;
    defenseMagic: number;
    charmMagic: number;
    criticalStrike: number;
    dualWielding: number;
    shieldMastery: number;
    identification: number;
  };
  unspentSkillPoints: number;
  
  // Health & combat
  hp: number;
  hpMax: number;
  stamina: number;
  staminaMax: number;
  
  // Inventory & gear
  inventory: ItemStack[];    // 28 slots typical
  equipped: {
    weapon?: ItemId;
    weapon2?: ItemId;        // dual-wield
    body?: ItemId;
    head?: ItemId;
    shield?: ItemId;
    boots?: ItemId;
    cape?: ItemId;           // sequels onward
    amulet?: ItemId;
    ring1?: ItemId;
    ring2?: ItemId;
    earring?: ItemId;        // Traitor Soul onward
  };
  gold: number;
  
  // Spellbook (max 6 per category)
  spellbook: {
    attack: SpellId[];       // ≤6
    defense: SpellId[];      // ≤6
    charm: SpellId[];        // ≤6
  };
  
  // Heirlooms (passed from prior generation)
  heirlooms: ItemStack[];
};
```

---

## 3. Pet state schema

```ts
type PetState = {
  baseSpecies: 'dog_terrier' | 'cat';   // cosmetic-only at start
  currentForm: PetForm;                  // changed via fish
  formDuration: number;                  // seconds remaining (0 = permanent)
  
  level: number;
  xp: number;                            // shared with player or independent? primary sources unclear
  
  hp: number;
  hpMax: number;
  
  attributes: { /* same shape as player, scaled */ };
  
  inventory: ItemStack[];                // ~doubles player storage
  equipped: { collar?: ItemId };         // gear: collars/bands
  
  // AI state
  state: 'follow' | 'attacking' | 'fleeing' | 'sentToTown' | 'returning';
  target?: EntityId;
  position: Vec3;
  
  // Town-run state (when sentToTown)
  carriedItemsForSale?: ItemStack[];
  arrivalTime?: number;                  // when it'll be back
};

type PetForm = 
  | 'dog' | 'cat' | 'wolf' | 'bear' | 'scorpion' | 'hellhound' 
  | 'dragon' | 'ent' | 'spider' | /* ...many more, ~30 forms */;
```

### Pet behavior rules (confirmed from sources)

- **Pet cannot be permanently killed.** When HP reaches 0, **flees** rather than dies. Cannot be attacked while fleeing.
- **Auto-attacks** any enemy within range when player is in combat.
- **Carries inventory** independently — gives effectively double storage.
- **Send-to-town**: player issues command, pet leaves with chosen items, walks back to town autonomously, sells, returns.
- **Combat-AI priority**: closest hostile, switches if owner attacked.

---

## 4. Combat formula

Fate uses a **subtractive damage model** with **multiplicative magic scaling**. Implementation:

```js
function rollMeleeDamage(attacker, defender, weapon) {
  // Base damage from weapon + str/dex bonuses
  const base = weapon.baseDamage 
    + Math.floor(attacker.strength / 2)            // for melee
    + Math.floor(attacker.dexterity / 4);          // light bonus
  
  // Skill bonus (linear scaling)
  const skillBonus = base * (attacker.skills[weapon.skillKey] * 0.02);
  
  // Subtract armor reduction (subtractive)
  const armor = defender.armorTotal;
  let dmg = Math.max(1, base + skillBonus - armor);
  
  // Critical strike (% chance from skill, doubles damage)
  if (Math.random() < attacker.skills.criticalStrike * 0.005) {
    dmg *= 2;
  }
  
  // Random ±10% jitter for feel
  dmg *= (0.9 + Math.random() * 0.2);
  
  return Math.floor(dmg);
}

function rollHitChance(attacker, defender, weaponSpeed) {
  const attackRating = attacker.dexterity * 2 + attacker.skills[weaponSkill] * 3;
  const evasion = defender.dexterity * 2;
  // 50% base, ± from rating differential
  const chance = 0.5 + (attackRating - evasion) * 0.005;
  return Math.max(0.05, Math.min(0.95, chance));  // clamp [5%, 95%]
}

function rollSpellDamage(attacker, spell, defender) {
  // Multiplicative scaling — magic skill multiplies damage
  const base = spell.baseDamage 
    + Math.floor(attacker.magic * spell.magicScale);
  const skillMult = 1 + attacker.skills[spell.schoolSkill] * 0.01;
  let dmg = base * skillMult;
  
  // Elemental resistance (subtractive % reduction)
  const resist = defender.resistances[spell.element] || 0;
  dmg *= (1 - resist);
  
  return Math.max(1, Math.floor(dmg));
}
```

**Damage class** affects how armor reduces it (similar to Diablo II's physical/magical split):

| Class | Reduced by |
|---|---|
| Slashing (sword) | Physical armor |
| Piercing (bow, spear, polearm) | Physical armor (less) |
| Crushing (axe, club, hammer, staff) | Physical armor (heavily) |
| Elemental (fire / cold / lightning spells) | Element-specific resistance |

---

## 5. XP and progression formulas

### XP curve

Fate's XP curve is approximately **quadratic** — not OSRS-exponential:

```js
function xpForLevel(L) {
  // Approximate; exact constants from datamining
  return Math.floor(100 * L * L * 1.15);
}
```

| Level | XP needed (cumulative) |
|---|---|
| 1 | 0 |
| 5 | ~2,875 |
| 10 | ~11,500 |
| 25 | ~71,875 |
| 50 | ~287,500 |
| 99 | ~1,127,000 |

### Per-kill XP

XP from kills scales with **monster level** vs **player level**:

```js
function killXp(monster, player) {
  const baseXp = monster.level * 10;
  const diff = monster.level - player.level;
  // Higher-level monsters give more XP, lower-level give less
  return Math.floor(baseXp * (1 + diff * 0.1));
}
```

### Fame (the second progression bar)

**Fame is earned only from**:
- Defeating the random end-boss (huge chunk)
- Completing quests (~50-200 fame each)
- Defeating named "elite" monsters (small)

**Fame gates**:
- Skill point allocation past certain caps (you can't max critical strike on day 1)
- Higher-tier gear drops (gear pool widens with Fame)
- Some quest unlocks

This dual-progression solves the "skill point cap" problem cleanly: player can't beeline one skill — they have to accumulate Fame, which means doing varied content.

### Heirloom system

Per retirement:
- Player picks **one piece of equipment** from final character
- That piece is passed to next generation
- The heirloom gets **+25% to all numeric stats** per generation
- Cumulative: gen 5 heirloom has +125% total
- Fame transfers entirely to next character (not reset)

---

## 6. Difficulty system

**4 difficulty levels** + a hardcore mode:

| Difficulty | Monster level relative to floor | Notes |
|---|---|---|
| **Easy** | Slightly *behind* dungeon floor | Forgiving; XP rate moderate |
| **Normal (Hero)** | At or slightly above floor | "Moderate" |
| **Hardest (Legend)** | **6–12 levels above** player on most floors | Brutal; better drops |
| **Hardcore** | Same as Legend | **Permadeath** — character is gone forever on death |

### The "speed-dive penalty" (a clever design lever)

> *"Diving 5 floors without combat increases enemy difficulty."*

Mechanically: an internal "stress" counter increases with each unfought floor. Reaching threshold bumps the floor's monster levels up 1-2 tiers. **Can be relieved by killing monsters or returning to town.**

Implementation:
```js
// Pseudo-track on the world state
function onFloorEntered(world, floor) {
  if (floor.lastCombatFloor && floor.depth - floor.lastCombatFloor >= 5) {
    floor.difficultyBonus += 1;     // bump monster level
    spawnAlertMessage('The dungeon grows wary of you...');
  }
}

function onMonsterKilled(world) {
  world.lastCombatFloor = world.currentFloor;
  world.floorDifficultyBonus = Math.max(0, world.floorDifficultyBonus - 1);
}
```

This is a **soft mechanic that punishes town-portal-grinding without explicitly penalizing**. Cozy-RPG-flavor in a tough-game shell.

---

## 7. Dungeon generation

### Floor structure

- **2D grid-based** procgen (despite 3D rendering)
- **Rooms + corridors** model: random rectangular rooms placed on a grid; corridors connect them
- Sources note "giant square rooms with holes" critique — implies room sizes can be very large; later sequels and Torchlight reduced this

### Per-floor generation

```js
function generateFloor(depth, seed, difficulty) {
  // Deterministic from seed
  const rng = makeRng(seed);
  
  // Room count scales with depth (more rooms deeper)
  const roomCount = 8 + Math.floor(depth / 5) + rng.range(0, 4);
  
  // Place rectangular rooms randomly, no overlap
  const rooms = placeRooms(roomCount, rng);
  
  // Connect with corridors (MST or spanning tree)
  const corridors = connectRooms(rooms, rng);
  
  // Stairs: always 1 down (or end-of-quest at random floor 40-50)
  const stairsDown = pickRandomRoom(rooms, rng).center;
  
  // Place spawn point in first room
  const playerSpawn = rooms[0].center;
  
  // Place monsters according to depth/difficulty
  const monsters = spawnMonsters(rooms, depth, difficulty, rng);
  
  // Place treasure chests
  const treasure = scatterTreasure(rooms, depth, rng);
  
  // 5-10% chance per floor: spawn fishing pool (firefly cluster over water tile)
  if (rng.chance(0.08)) {
    const pool = placeFishingPool(rooms, rng);
  }
  
  // Rare (~2-5%): dungeon-roaming vendor (Pikko or Getts)
  if (rng.chance(0.04)) {
    spawnRoamingVendor(rooms, rng);
  }
  
  return { rooms, corridors, monsters, treasure, stairsDown };
}
```

### Final boss spawn

- Random per-save floor between **40–50** (legacy game)
- The boss is also chosen randomly from a pool of named bosses
- Once defeated → infinite scaling kicks in (floors continue indefinitely, depth ~2 billion theoretically)

---

## 8. Quest system

### Quest constraints

- **Up to 5 quests available** in town at any time
- **Player can hold up to 3** simultaneously
- Quests target floors **below the player's deepest** floor only (no backtracking-needed quests)
- Defeated quest target enemies **don't respawn**

### Quest templates (3 main types)

```ts
type Quest =
  | { type: 'kill_rare', targetMonsterId: MonsterId, targetFloor: number, fameReward: number }
  | { type: 'fetch_item', targetItemId: ItemId, targetFloor: number, fameReward: number }
  | { type: 'kill_pack', targetMonsterId: MonsterId, targetFloor: number, count: number, fameReward: number };
```

Reward typically: gold + Fame + occasional gear. Fame is the *meaningful* reward; gold is procgen-scaled.

### Quest givers

Townspeople: Beregor, Dimo Nor (south), Gimbo Tel (graveyard zombie), Seever, Torvus, Mayor. Each rotates through the templates.

---

## 9. Fishing minigame

```js
function tryFish(pool, player) {
  // Time pool to deplete: ~30 seconds of standing-and-fishing
  // Player clicks rod over fishing pool with `!` indicator
  
  // Roll outcome
  const roll = Math.random();
  if (roll < 0.40) {
    return spawnFish(rollFishTier(pool.depth));  // 40% fish
  } else if (roll < 0.50) {
    return spawnGear(rollGearTier(pool.depth));  // 10% gear
  } else if (roll < 0.55) {
    return spawnTrash();                         // 5% trash
  } else {
    return null;                                 // 45% nothing
  }
}

function rollFishTier(poolDepth) {
  // Higher floor = better fish
  const r = Math.random();
  if (poolDepth < 10) {
    return r < 0.7 ? 'fingerling' : 'small';
  } else if (poolDepth < 25) {
    return r < 0.5 ? 'fingerling' : r < 0.85 ? 'small' : 'lunker';
  } else {
    return r < 0.3 ? 'fingerling' : r < 0.6 ? 'small' : r < 0.9 ? 'lunker' : 'flawless';
  }
}
```

### Fish → pet transformation table

| Fish tier | Duration | Notes |
|---|---|---|
| Fingerling | **120 sec** | Common; cheap experimentation |
| Small | **300 sec** (5 min) | Tactical pre-fight buff |
| Lunker | **600 sec** (10 min) | Strategic — covers a full floor |
| Flawless | **Permanent** | Lock-in until next fish overrides |

### Pet form catalog (~30 forms)

Forms grant different stat profiles. Examples:
- **Wolf** — fast, modest hp, claw attack
- **Bear** — slow, high hp, heavy hit
- **Hellhound** — moderate hp, **fire damage**
- **Spider** — fast, **poison damage**
- **Scorpion** — moderate, **poison + critical**
- **Dragon** (rare flawless) — high hp, **fire breath ranged attack**
- **Ent** — high hp, low speed, area attack
- **Direwolf** — like wolf but stronger
- (...others)

Each form should have:
```ts
type PetForm = {
  id: string;
  name: string;
  hpMod: number;       // multiplier on base pet HP
  speedMod: number;
  damageMod: number;
  damageType: 'physical' | 'fire' | 'cold' | 'poison' | 'lightning';
  attackRange: 'melee' | 'short' | 'ranged';
  specialAbility?: string;  // 'fire breath', 'aoe', etc.
};
```

---

## 10. Town & NPC implementation

### Grove layout (rough zones)

- **Center plaza** — fountain, Dreya the Healer
- **South** — Dell Arness's blacksmith
- **East** — Bartleby's potion shop
- **West** — Jin the Seer's spell shop
- **North** — graveyard with Gimbo Tel
- **Edge** — banker, Rikko the Enchanter
- **Outskirts** — Beregor & Dimo Nor at the dog kennel
- **Inn** — Tavernkeeper, The Stranger (prologue)

### NPC schema

```ts
type NpcDef = {
  id: string;
  name: string;
  role: 'vendor' | 'service' | 'quest' | 'lore';
  position: Vec3;          // fixed location in town
  inventory?: { itemId: ItemId, restock: number, price: number }[];
  service?: 'heal' | 'enchant' | 'bank' | 'storage';
  quests?: QuestTemplate[];
  dialog: { greeting: string[], topic: { [key: string]: string[] } };
};
```

### Critical service NPCs

- **Dreya the Healer** — `service: 'heal'`. Free full heal of player + pet on click.
- **Rikko the Enchanter** — `service: 'enchant'`. Costs scale with successful enchant count on the same item: `cost = baseCost * (2 ^ priorAttempts)`.
- **Banker** — persistent storage chest, slot count expands with Fame.

---

## 11. Save system

### Save format (estimated; reverse-engineered from community discussion)

```ts
type SaveFile = {
  version: string;
  difficulty: Difficulty;
  hardcore: boolean;
  
  player: PlayerState;
  pet: PetState;
  
  // World
  currentFloor: number;
  deepestFloor: number;
  worldSeed: number;
  
  // Town state
  bankerStorage: ItemStack[];
  shopRestockTimers: Record<string, number>;
  questsAvailable: Quest[];
  questsActive: Quest[];
  
  // Lineage
  generation: number;
  ancestors: { name: string, deepestFloor: number, fameAtRetirement: number }[];
};
```

### Save events

- On floor change (autosave)
- On town entry (autosave)
- On level up (autosave)
- Manual save anytime in town
- **No save in dungeon on Hardcore** — death = file deletion

---

## 12. The hourly gameplay loop (for tuning)

```
[ Enter floor N+1 ]
  → Walk through new procgen layout (~30 sec sightseeing)
  → Engage 1-3 monster groups (~2-3 min combat)
  → Pick up loot, manage inventory (~30 sec)
  → If pool spotted, fish (~1-2 min)
  → If vendor spotted, browse (~30 sec)
  → Find stairs, descend
[ Repeat for ~8-10 floors per hour casual play ]
  → Inventory full → send pet to town
  → Pet returns next floor or two later with gold
  → Continue
[ Every ~30 floors: town visit ]
  → Sell, restock, pick up quests, heal, enchant
  → Bank excess
[ Every ~50 floors: face boss ]
  → Major fight, big XP/Fame reward
  → Decide: continue infinite, or retire?
```

**Target session length**: 30–60 minutes per dungeon dive. Retirement is a choice point at end of session.

---

## 13. Implementation order (suggested)

If building this from scratch, ship in this order:

1. **Town hub** with healer + 1 vendor + stairs to dungeon (skip everything else)
2. **One floor of procgen dungeon** with 5 enemy types
3. **Combat** with 1 weapon and 1 spell
4. **Inventory + gear equipping**
5. **Pet** that follows + auto-attacks + cannot die (just flees)
6. **Send-pet-to-town** mechanic (delay, then gold appears)
7. **Multiple floors** with descending stairs + level scaling
8. **Fishing pool** with 1 fish tier + 1 pet form transform
9. **All 4 attributes + 6 skills** (sample of 15)
10. **Quest system** with 1 template
11. **Random end-boss** at floor 40
12. **Retirement + heirloom**

That's a 12-step path from blank repo to "Fate-shaped game." Each step is shippable — you'd have a playable thing at step 5.

---

## 14. Direct gj26 mapping

For your toon RuneScape × Harvest Moon project, the most copy-worthy implementation pieces:

| Fate impl piece | gj26 form | Priority |
|---|---|---|
| Pet that flees rather than dies | Cottage cat that runs home if HP hits 0 | High — cozy-aligned |
| Send-pet-to-town as time-cost | Trained falcon takes logs to cottage shop overnight | High — set-and-forget rhythm |
| Fishing → animal transformation | Forage → familiar form change (cat into wisp / fox / owl) | Medium — distinctive |
| Heirloom retirement +25%/gen | Year-end heirloom passes to next "season's" character | Medium — meta-loop |
| Random end-boss at fixed floor range | Goblin chief of one of 3 named variants at goblin field | Low — variety, jam scope |
| Speed-dive penalty (5 floors w/o combat) | If you skip combat, mobs on this zone are tougher next visit | Low — too punishing for cozy |
| Procgen quest templates (3 types × N givers) | "Bring 5 fish to Cynthia" / "Defeat 3 goblins" / "Forage 8 herbs" | High — cheap content |
| Fame as second-progression gate | Village reputation / festival access | High — natural cozy fit |
| Free healer in hub | Cottage rest already does this | Already done |

The pieces that fit cozy without modification: **send-pet-to-town**, **heirloom retirement**, **procgen quests**, **fame-as-gate**. The pieces that need softening: **speed-dive penalty** is too aggressive; just remove for cozy.

---

## 15. Concrete numbers cheat sheet

| Mechanic | Number |
|---|---|
| Attribute points per level | **5** |
| Skill points per level | **1** |
| Total skills | **15** |
| Weapon classes | **8** |
| Spell categories | **3** |
| Spells per category in book | **6** |
| Quests available in town | **≤5** |
| Quests active simultaneously | **≤3** |
| Final boss floor (random) | **40–50** |
| Heirloom buff per generation | **+25% all numeric stats** |
| Speed-dive penalty trigger | **5 floors w/o combat** |
| Fish tiers | **4** (fingerling/small/lunker/flawless) |
| Pet transform durations | **120s / 300s / 600s / permanent** |
| Difficulty levels | **4** + Hardcore |
| Hardest difficulty monster level | **+6 to +12** above player |
| Inventory slots (estimated) | **~28** |
| Pet inventory | **~doubles player capacity** |
| Post-victory infinite floors | **~2 billion theoretical** |

---

## 16. References & sources

### Primary
- [void fox — Fate in a Nutshell (deep technical breakdown — most quantitative source)](https://voidfox.com/blog/fate_in_nutshell/)
- [Wikipedia — Fate (video game)](https://en.wikipedia.org/wiki/Fate_(video_game))
- [Fate Wiki — Pet, Fishing, Story, NPCs](https://fate.fandom.com/)
- [GameFAQs — CodeZebra Walkthrough](https://gamefaqs.gamespot.com/pc/927041-fate/faqs/49010)
- [GameFAQs — JesterTBP Unique Weapon/Armor Guide](https://gamefaqs.gamespot.com/pc/927041-fate/faqs/55425)
- [GameFAQs — blackeyebattery Spell Guide](https://gamefaqs.gamespot.com/pc/927041-fate/faqs/49541)

### Related vault docs
- [[fate-2005-deep-dive]] — narrative / lore / design philosophy companion
- [[content-generation-playbook]] — for generating items / monsters per these schemas
- [[game-balance-playbook]] — for tuning the combat formulas
- [[mmo-game-design-playbook]] — for broader RPG theory
- [[cozy-life-sim-design-playbook]] — for which pieces translate to cozy
- [[evoke-online-game-feel|evoke-online-game-feel skill]] — for soul-checking each piece

### gj26 cross-references
- [[DESIGN_VISION]] — current genre call
- [[ONBOARDING]] — tutorial flow
- [[content-generation-playbook]] — schemas for items/enemies/NPCs
- [[game-balance-playbook]] — combat formula reference
