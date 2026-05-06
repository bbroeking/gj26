# Asset pipeline — concept → model → game

The end-to-end workflow for getting a new character / enemy / prop from idea to in-game. There are two entry paths: the **concept-art-driven** path (full quality pass) and the **dummy-procedural** path (when there's no concept yet but the game needs *something* to spawn).

Phases are the same for both — the difference is how phase 2 starts.

---

## Phase 0 — Decide what to build

Before anything else, write down a one-liner that fixes:

- **Slug** (snake_case, used everywhere — `bog_stag`, `briar_lurker`)
- **Kind** (player archetype / enemy / NPC / prop / quest item)
- **Rig type** if applicable (biped / quadruped / static)
- **Behavior** (for enemies — melee / ranged / kiter / slammer / charger / boss)
- **Why it earns its slot** — what feeling, fight, or story does it serve?

If you can't answer the last bullet, don't build it. Add it to a "future" list.

---

## Phase 1 — Concept-art prompt (skip if going dummy-first)

1. Open `docs/concept-art-prompts-next.md` (or one of the existing batch files) and append a new entry **using the locked stem at the top**. The stem is non-negotiable — it's what keeps the storybook tone consistent across batches.
2. Run the prompt through Midjourney / Imagen / Flux. Generate ~4 variations.
3. Pick the favorite. Save it as `docs/concept-art/<slug>.png`. Save the runner-up as `docs/art-refs/<slug>_v2.png` for later A/B reference.
4. Append one line to `docs/concept-art/INDEX.md`: `- <slug> — one-sentence what's special about this take`.
5. Hand the slug back to the engineer.

**Lock rule:** never change the locked stem mid-batch. If you want a new style, start a new prompt batch file with a new stem and document why.

---

## Phase 2A — Blender model from concept art

Prerequisite: `docs/concept-art/<slug>.png` exists.

Follow the recipe in **`docs/BLENDER_PIPELINE.md`** (this is the authoritative Blender doc). Quick summary:

1. New file → wipe scene → `Add → Image → Reference` the concept PNG
2. Build with **size=2 cubes** scaled by `(sx/2, sy/2, sz/2)` (the size=1 cube halves dimensions when scaled this way — see the bevel-pipeline memory)
3. **Author each mesh at its TRUE world position before parenting** — never at origin. The parent_inverse trap silently cancels rig motion when meshes are placed at origin and then parented.
4. Create the rig empties (see Phase 2C below for the canonical names per rig type)
5. Parent each mesh to its rig empty (or weld decorations onto the body mesh — see "spots on cow" pattern)
6. Materials: Principled BSDF only (`diffuse_color` alone gets dropped by glTF)
7. Bevel modifier with `limit_method='ANGLE'` at 30°, 2 segments, `width = min(0.025, dim * 0.08)`
8. `bpy.ops.mesh.remove_doubles` before bevel — glTF imports faces with split verts
9. Export: `export_yup=True, export_apply=True, export_animations=False, export_skins=False`
10. Save as `models/<slug>.glb`

Validation render: import the saved GLB into a fresh scene and render front + 3/4 + back. Each part must be touching the next (no floaters), at the right scale, and reading as the concept art.

---

## Phase 2B — Dummy procedural model (no concept art yet)

When you need to spawn the thing **now** and concept art is days away.

1. Pick the closest existing model that shares the silhouette (e.g. `boar_v2.glb` for any quadruped boss; `goblin_v2.glb` for any humanoid mob; `chicken_v2.glb` for small avians).
2. In Blender, import the base GLB and run `varyInstance(...)` style tinting in `src/scene/characters.js` to recolor — pick a hue + saturation that makes it visually distinct from the parent at a glance.
3. Stamp the dummy with a **`_dummy` suffix in the slug** so the asset audit knows to upgrade it later: `bog_stag_dummy.glb`. **Required.**
4. Add a one-line note in `docs/concept-art/INDEX.md` under a "Dummy models awaiting concept art" section: `- bog_stag_dummy — placeholder boar variant; concept art TODO`.

A dummy must still pass the floater audit (every part touches at least one other part). It can have wrong proportions, wrong color, wrong details — just no floating bits.

When concept art lands later, follow Phase 2A and replace the dummy. Update the loader to point at the new file. Keep the dummy `.glb` for one version cycle in case of regression — delete after that.

---

## Phase 2C — Rig conventions

Required empty names per kind. The animation router in `src/main.js` reads these flags + parts to pick the right animator.

### Biped (player, NPC, goblin, knight, archer)
```
Body, Head, Arm_L, Arm_R, Leg_L, Leg_R
```
Animator: `animateGLBKnight` (also drives goblin via `isGLBGoblin` flag)

### Quadruped (cow, boar, wolf, hedgewight, hedgemother, hare)
```
Body, Head, Tail, Leg_FL, Leg_FR, Leg_BL, Leg_BR
```
Animator: `animateQuadruped` (driven by `isGLBBoar/Hedgewolf/WolfAlpha/BurrowBoar/Hedgewight/Hedgemother/Hare`)

### Bird / chicken-style biped
```
Body, Head, Wing_L, Wing_R, Leg_L, Leg_R, Tail
```
Animator: `animateBird`

### Static (props, decorations)
No rig empties needed. Single mesh or a few static children of a root group.

**Rule:** every named empty has its origin at the *pivot of motion* (Arm_L origin at the shoulder, Leg_FL origin at the hip joint, Tail origin at the base). If the pivot is wrong, animation will look like a marionette with detached parts.

---

## Phase 3 — Wire the model into the game

For every new GLB:

1. **Loader** in `src/scene/characters.js`:
   ```js
   export function loadXxxGLB(url = 'models/<slug>.glb') {
     return _loadOnce('xxx', 'xxxPromise', url);
   }
   ```
2. Add to the appropriate parallel-load list (e.g. `loadAllArchetypes()` for player meshes, or directly in `main.js` boot Promise.all)

3. **Builder** in `src/scene/characters.js`:
   ```js
   export function buildXxxMesh() {
     const g = new THREE.Group();
     if (_glb.xxx) {
       const inst = _glb.xxx.clone(true);
       inst.scale.setScalar(0.55);   // standard player scale
       g.add(inst);
       const parts = {};
       inst.traverse(o => { if (RIG_NAMES.includes(o.name)) parts[o.name] = o; });
       g.userData.parts = parts;
       g.userData.isGLBXxx = true;
     }
     return shadowizeAll(g);
   }
   ```

4. **Spawn factory** in `src/game/enemies.js` (for enemies):
   - Returns the standard enemy schema (`{kind, x, y, hp, hpMax, atkLv, defLv, maxHit, alive, aggro, hpBar, ...}`)
   - Includes `behavior` if non-default (`'ranged' | 'kiter' | 'charger'`)
   - Includes `slam: true`, `parryOnly: true`, or `isBoss: true` flags as appropriate

5. **Animation routing** in `src/main.js` enemy update loop:
   - Add the new `isGLBXxx` flag to the existing `animateQuadruped` / `animateBird` dispatch (probably no change needed — flag-driven)

6. **Dungeon spawn table** in `src/data/dungeonSpawns.js`:
   - Add weighted entry to `MOB_DEFAULT[tier]` and any scope-specific tables that fit

7. **Dev console** in `src/ui/devConsole.js`:
   - Add to the `ENEMY_KINDS` array so it's spawnable from the cheats panel

8. **Codex** in `codex.js`:
   - Add an entry to `ENEMIES` (or `ITEMS_WITH_PNG_ICON` for items)
   - Include scope hint, drops, and one-line "what's special about this fight"

---

## Phase 4 — Validate before merging

Walk the checklist:

- [ ] No floating parts (audit via the Blender bbox-distance script in earlier `audit_*.png` renders)
- [ ] Every named rig empty has its origin at the pivot of motion (test by rotating each empty 30° in Blender and seeing the right child rotates with it)
- [ ] Animation pipeline routes correctly — spawn one and walk; legs should swing
- [ ] Dev console can spawn it and you can fight it without errors
- [ ] Codex page shows it with correct stats + drops
- [ ] If it has a unique mechanic (parry-only, charger lane, kiter retreat), test the player can read the telegraph

Only ship after all six are green.

---

## Maintenance — when to revisit

A model graduates from "shipped" to "needs another pass" when:
- Concept art replaces a dummy → rebuild via Phase 2A, retire the dummy
- Player audits show consistent feedback ("the X looks weird") → re-examine that one part
- A new mechanic needs an animation cue the model doesn't telegraph → add the part + re-rig
- The bevel/material pipeline gets updated in `BLENDER_PIPELINE.md` → run a versioned rebuild on hero models (player archetypes, bosses)

Keep the version chain visible in the codex Models tab so you can compare iterations side-by-side.
