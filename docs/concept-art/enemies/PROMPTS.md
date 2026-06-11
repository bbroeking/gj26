# Crypt enemies — niji 6 prompts + Meshy recipe

Four hostile creatures that populate the crypt biome (spec 04). Same
pipeline as the crypt tiles: niji 6 → save PNG → Meshy Image-to-3D →
`clean_ai_mesh.py --rig <biped|quadruped|static>` → drop in `models/`.

Mid-boss is `wolf_alpha` (reskinned "crypt hound" — no new model needed,
per the foundation Q9 grill). Final boss is `hedgemother` (spec 05).

## Conventions

- **Concept art PNGs** → save here as
  `enemy-<name>-v<0..3>.png` (e.g. `enemy-skeleton-v0.png`).
- **Final GLBs** → `models/enemy_<name>_v1.glb`.
- **1-character-per-tile** in combat; sized so the head sits roughly at
  player-eye height (≈ 1.6 m) for biped enemies. Rat is low-slung; ghost
  floats at chest height (animator y-bobs).

## Master prompt stem

Every prompt below is the same stem with the per-enemy `<SUBJECT>` swapped
in. Same style locks as the crypt tiles so the biome reads as one place.

```
<SUBJECT>, cute exaggerated chunky cartoon proportions, super simple geometric shapes, plain pale cream background, one object only, three-quarter view --niji 6 --ar 3:4 --stylize 400 --no photoreal, realistic, PBR, gradient shading, watercolor, dark, gritty, multiple characters, scenery, UI, text
```

`--ar 3:4` so the character has vertical room for full-body silhouette
(rat is the exception — could go 1:1 but 3:4 still works).

## Per-enemy prompts

Plug each `<SUBJECT>` into the stem above.

### 1. Skeleton (`enemy-skeleton-v[0-3].png`)

```
chunky cartoon skeleton warrior, slightly hunched, bone-white body with darker grey shadow nooks, simple ribcage shape, oversized round skull with hollow eye sockets, no weapon (clenched fists), standing pose, kept-simple low-poly look
```

Rig: **biped**. Target tris: 5000. Stat-block target: HP 18 · dmg 4 · spd 2.0.

### 2. Crypt Rat (`enemy-rat-v[0-3].png`)

```
chunky cartoon dungeon rat, low-slung quadruped, dark grey-brown fur with soft pink ears and tail, beady red eyes, slightly menacing but cute, mid-stride pose, kept-simple low-poly look
```

Rig: **quadruped**. Target tris: 3000. Stat-block target: HP 8 · dmg 2 · spd 3.0.

### 3. Ghost (`enemy-ghost-v[0-3].png`)

```
chunky cartoon dungeon ghost, translucent pale-blue tear-drop body floating with wispy tail trailing below, simple round eyes, faint open mouth, no arms (or stubby vestigial wisp-arms), serene-creepy mood, kept-simple low-poly look
```

Rig: **static** (floats; animator handles bob + sway). Target tris: 3000.
Stat-block target: HP 14 · dmg 5 · spd 1.5.

### 4. Hedge-Sprite (`enemy-hedge-sprite-v[0-3].png`)

```
chunky cartoon hedge-sprite, small humanoid figure made of tangled twigs and dark moss with two red berry eyes, leafy bramble crown, soft green-brown palette, mischievous stance with thorny twig-arms half-raised, kept-simple low-poly look
```

Rig: **biped**. Target tris: 5000. Stat-block target: HP 22 · dmg 6 · spd 1.8.

## Meshy settings (same for every enemy)

- Image-to-3D · Standard · `topology: triangle`
- `pose_mode: A-pose` for biped, leave empty for ghost/rat
- `target_polycount`: see per-enemy budget above (Meshy default is fine — `clean_ai_mesh.py` decimates to the budget on the way in)
- `should_texture: yes` · `ai_model: meshy-6` (pinned)
- Cleanup: `clean_ai_mesh.py --rig <biped|quadruped|static> --tris <budget>`

## Output filename pattern

| PNG (this folder) | GLB (`models/`) |
|---|---|
| `enemy-skeleton-v[0-3].png` | `models/enemy_skeleton_v1.glb` |
| `enemy-rat-v[0-3].png` | `models/enemy_rat_v1.glb` |
| `enemy-ghost-v[0-3].png` | `models/enemy_ghost_v1.glb` |
| `enemy-hedge-sprite-v[0-3].png` | `models/enemy_hedge_sprite_v1.glb` |

After the 4 GLBs land, code-side work is:
- `src/data/enemies.js` — stat registry entries
- `src/anim/<name>.js` × 4 — per-frame rotation rigs (mirror goblin.js)
- `src/data/dungeonSpawns.js` — populate `MOB_CRYPT` + add `GUARD_CRYPT`
- `src/main.js` — `_DUNGEON_SPAWN_FNS` map adds skeleton/rat/ghost/hedge_sprite
