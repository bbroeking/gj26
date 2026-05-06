# Lumbridge — GDD v2

**Codename:** `gj26-v2`
**Archetype:** `top-down` (4-direction movement, tile-based, free roam)
**Engine:** vanilla canvas + ES modules, no build step
**Status:** scaffolding (Phase 2 of OpenGame's 6-phase workflow)

---

## 1. Pitch (one line)

A bite-sized OSRS tribute — kill cows, cook beef, deliver a quest, level up — entirely in the browser, no install.

## 2. Hook
- **Familiar OSRS rhythm** — combat triangle (Att / Str / Def / HP), 28-slot inventory, equipment slots, hit-splats, miss splats
- **Five-minute play loop** — clear quest in under 5 min, replay-able
- **Procedural pixel art** — every sprite is data, baked at runtime (carried over from v1)

## 3. Core loop (30-second player experience)
1. **Walk** through Lumbridge, find a cow
2. **Press Space** to attack — see hit/miss splats, watch HP bars tick
3. **Kill** → loot raw beef + cowhide
4. **Cook** raw beef on fire → cooked beef → eat = +heal
5. **Repeat / level up** Att/Str/Def/HP/Cooking
6. **Hand quest items** to Cook → reward

## 4. Design pillars
1. **OSRS-faithful feel** — combat splats, level-up ding, click-or-keypress interactions
2. **Vanilla canvas, no build** — modern browsers, ES modules, instant edit-reload
3. **Modular architecture** — adopt OpenGame's separation: `core/` (engine), `archetypes/` (genre-shared), `game/` (specific), `data/` (config + assets)
4. **Skill > grind** — XP per action is generous; the demo shows level-ups in 5 min

## 5. MVP scope
- ✅ Top-down 4-direction movement, scrolling camera, ASCII tilemap loader
- ✅ 4 combat skills + 1 production skill (Cooking)
- ✅ One enemy type (Cow), one NPC (Cook), one quest
- ✅ 28-slot inventory + 4 equipment slots (weapon, body, helm, shield)
- ✅ Hit-splats (red number on hit, blue "0" on miss/block, green on heal)
- ✅ Particle FX — death puff, level-up burst, cooking sparks
- ❌ Mining, Smithing, Fishing, Woodcutting (defer to v2.1)
- ❌ Banking, multiple zones, magic, ranged (defer)

## 6. Skills

| # | Skill | Verb | XP source |
|---|---|---|---|
| 1 | Attack | swing | melee hit lands |
| 2 | Strength | swing (auto) | melee hit lands (split share) |
| 3 | Defence | take hit (auto) | enemy hit lands on you |
| 4 | Hitpoints | passive | both dealing & taking damage |
| 5 | Cooking | cook | raw → cooked at fire tile |

OSRS-style XP curve: `xpForLevel(n) = (n-1)² × 8` — level 2 at 8 xp, level 5 at 128 xp.

## 7. Combat formula (loose OSRS)

```
hit_chance  = clamp(0.30 + 0.04 * (atkLv + weaponBonus) - 0.02 * defLv, 0.10, 0.95)
max_hit     = floor(0.5 + 1.0 * (strLv + weaponStrBonus) / 4)   // ≥1
on_swing    = roll(hit_chance) ? roll(0..max_hit) : 0           // 0 = miss/blue
```

Bronze sword: +1 atk, +2 str. Leather body: +0 atk, +0 str, +2 def.

## 8. World
- **Single zone** — Lumbridge village + cow field + forest
- **40 × 28 tiles** (1280 × 896 px), camera follows player, clamped at edges
- **Tile types:** grass, dirt path, water, stone, sand, wood plank, fire (cooking)
- **Entities:** player (spawn middle), 4 cows (south field), 1 NPC Cook (in hut), 1 fire (next to Cook)

## 9. Quest — "Cook's Assistant" (mini)

| Step | Trigger | Reward |
|---|---|---|
| 1. Talk to Cook | face Cook + Space | quest started |
| 2. Kill 3 cows | each cow death | quest counter ticks |
| 3. Cook 3 raw beef | cook at fire | (uses cooking skill) |
| 4. Hand 3 cooked beef to Cook | face Cook + Space | +50 atk xp + bronze sword |

## 10. Architecture (OpenGame's pattern, vanilla flavor)

```
gj26-v2/
├── index.html              # entry, mounts canvas + HUD
├── docs/
│   ├── GDD.md              # this file
│   ├── asset_protocol.md   # sprite registry / palette / sizing rules
│   └── debug_protocol.md   # Debug Skill — running list of fixes
├── src/
│   ├── main.js             # boot — wires modules, starts loop
│   ├── core/               # engine-agnostic
│   │   ├── canvas.js       # canvas + ctx + tile/view constants
│   │   ├── input.js        # keyboard state + interact queue
│   │   ├── camera.js       # follow + clamp
│   │   ├── render.js       # tile + entity draw, y-sort
│   │   ├── sprite.js       # bake char-grid → canvas
│   │   └── particles.js    # damage numbers, dust puffs
│   ├── archetypes/topdown/
│   │   └── controller.js   # grid-tween movement, facing, interact dispatch
│   ├── game/
│   │   ├── world.js        # tilemap + entity spawn from data/map.txt
│   │   ├── player.js       # state, equipment, skills
│   │   ├── enemies.js      # cow AI, spawning, death
│   │   ├── npcs.js         # NPC dispatch (talk dialogs)
│   │   ├── inventory.js    # 28-slot grid + equipment
│   │   ├── combat.js       # attack roll, damage, splat spawn
│   │   ├── skills.js       # XP, levels, combat-style XP split
│   │   └── quest.js        # quest steps, flag tracking
│   └── data/
│       ├── config.js       # tunables (HP, XP, costs, sizes)
│       ├── map.txt         # ASCII tilemap
│       ├── sprites.js      # SPR.* char-grid library
│       ├── items.js        # item registry (icons, names, equip stats)
│       └── npcs.js         # NPC defs (sprite, name, dialog)
└── v1/                     # archived previous build
```

Modules use ES `import` / `export`. No bundler. `<script type="module" src="src/main.js">` boots.

## 11. OpenGame patterns we're adopting

- **Template Skill (compressed):** `archetypes/topdown/controller.js` is our genre template — anything top-down reuses its movement + interact dispatch
- **Debug Skill:** `docs/debug_protocol.md` — every observed bug + verified fix appended; consult before debugging similar issues
- **Asset registry:** `docs/asset_protocol.md` + `data/sprites.js` together — palette + sprite list are the source of truth
- **Three-Layer Reading:** when adding a feature, read order is `(1) module API summary → (2) target file → (3) GDD section that motivates the change`
- **Phase discipline:** classify → scaffold → GDD → assets → code → verify (no skipping)

## 12. Open questions
- [ ] Save game state to `localStorage`?
- [ ] Add hit-splash screen-shake (subtle), or skip?
- [ ] Attack animation: swing arc (current) or weapon sprite swap (heavier)?
