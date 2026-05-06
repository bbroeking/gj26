# Boss model specs — Hedgemother, Pale Hag, Chartmaker's Echo

A self-contained brief for the three boss-tier models the bestiary
calls for. Designed so a focused Blender session can knock them out
without the spec wandering between threads.

Read alongside:
- `docs/BLENDER_PIPELINE.md` — Blender → glTF pipeline + bevel/toon recipe
- `docs/ASSET_PIPELINE.md` — full concept → in-game flow
- `feedback_blender_bevel_pipeline.md` — bevel + Principled BSDF recipe
- `docs/ART_BIBLE.md` — palette + silhouette guidance
- `src/data/enemy-defs.js` — engine-side stats already authored
- `docs/animations.md` (if added) — existing procedural rigs

---

## Hedgemother — `kind: hedgemother`

> **Status:** v2 GLB exists (`models/hedgemother_v2.glb`), but the user
> flagged it for iteration. This entry is a **rebuild brief**, not a
> green-field author.

| Field | Value |
|---|---|
| Tier / role | boss · main bramble queen |
| heightM | 2.40 |
| Footprint | 1.5 × 1.5 (one tile + spillover) |
| Concept art | `docs/concept-art/hedgemother.png` |
| Existing rig | named groups: Body, Head, Arm_L, Arm_R, Leg_L, Leg_R |

### Silhouette

A bramble-queen towering 2.4 meters. Crowned in living thorns. Long
robe of woven vine that reads from above as a green column with a
pale bone-white face. **Read at top-down camera distance:**
- Crown of curved thorns radiating outward — primary readable mark
- Vertical green-brown body (the robe)
- Pale face (smaller mark, but the only warm tone)
- Two long sleeve arms ending in clawed hands (smaller secondary mark)

### Materials (Principled BSDF, named for export)

| Material | Color | Roughness | Notes |
|---|---|---|---|
| `Bramble`  | `#3a5a28` (deep moss) | 0.9 | Robe / main body |
| `Thorn`    | `#7a4a2a` (dark wood) | 0.8 | Crown spikes + arm thorns |
| `Bone`     | `#e8dcc4` (pale bone) | 0.7 | Face / hands — only warm material |
| `BloomEye` | `#ffd060` (gold) + emissive 0.4 | 0.5 | Eyes — small but glowing |

### Rig structure (named groups)

```
Hedgemother (root)
├── Body                     # vine-robe column
│   ├── Crown                # thorny crown — sub-part, parented to Head
│   └── (decorative thorn rings — also under Head)
├── Head                     # cabbage-pale face + Crown + ThornRings
│   ├── Crown
│   ├── ThornRing_a
│   ├── ThornRing_b
│   ├── Eye_L (BloomEye)
│   └── Eye_R (BloomEye)
├── Arm_L                    # sleeve + claw
│   └── Claw_L
├── Arm_R
│   └── Claw_R
├── Leg_L                    # short — robe hides most of it
└── Leg_R
```

**Critical:** sub-parts (Crown, ThornRing_*, Eye_*, Claw_*) MUST be
re-parented to their named parent group in Blender. The procedural
animation in `src/anim/goblin.js` (which drives this kind) rotates
`Head` and expects the crown + thorn rings + eyes to follow.

### Bevel + dimensions

- Apply scale + rotation before bevel.
- `bpy.ops.mesh.remove_doubles` on every part before adding the bevel
  modifier (gltf imports faces with split verts, bevel is a no-op
  without this).
- Bevel modifier: `limit_method='ANGLE'`, 30°, `width = min(0.025, dim * 0.08)`,
  segments=2.

### Animations the engine drives (no clip authoring needed)

- `goblin_walk` — `animateGoblin` rotates Head + arms + legs
- `tusker_slam` (renamed for boss) — slow windup → AoE; main loop
  flags telegraph 0.85s in advance via `telegraph.js`
- `enemy_dissolve` — `spawnDissolve` on death

### Export

```python
bpy.ops.export_scene.gltf(
  filepath="models/hedgemother_v3.glb",
  export_yup=True,
  export_apply=True,
  export_animations=False,
  export_skins=False,
)
```

---

## Pale Hag — `kind: pale_hag`

> **Status:** new. No GLB or concept art yet. Designed as the
> alternate / harder Hedgemother, surfaced only on hag-toothed orbs
> (see `src/data/orb-recipes.js → forge_orb_boss`).

| Field | Value |
|---|---|
| Tier / role | boss · alternate Hedgemother (chase / pact) |
| heightM | 2.50 |
| Footprint | 1.5 × 1.5 |
| Concept art | TBD — generate via the master prompt stem in `docs/concept-art-prompts-master.md` |
| Existing rig | none — author from scratch |

### Silhouette

She is the wash-pale shadow of the Hedgemother. Where the Hedgemother
is a crowned queen of brambles, the Pale Hag is the ghost of one —
**bone-white, robed in bone-rags, eyes hollowed out**. The crown of
thorns becomes a crown of bone teeth. From above:
- Skull-pale ovoid head, no foliage
- Bone-tooth crown (smaller, less radiating)
- White-gray robe (no green)
- Long bony hands instead of vine claws

The visual relation should be: same silhouette, **inverted palette + sharper contrast**.

### Materials

| Material | Color | Roughness |
|---|---|---|
| `BoneRag`     | `#e8e4d8` (washed cream) | 0.85 |
| `BoneCrown`   | `#dccbab` (yellowed bone) | 0.9 |
| `BoneFlesh`   | `#f4ead8` (pale skin)     | 0.7 |
| `EyeHollow`   | `#1a1410` (deep shadow)   | 0.95 |

No emissive — she should read **uncanny / silent** rather than glowing.

### Rig

Same named-group structure as Hedgemother (Body/Head/Arm_L/Arm_R/Leg_L/Leg_R)
so `animateGoblin` and the procedural sliders all work without code change.
The only addition is `Crown_BoneTooth` (parent: Head).

### Mechanic note for animator

Boss has a "wail" telegraph (one-shot 0.6s windup, AoE 5×5 silence
zone). Reuses the existing `telegraph.js` ring + `tusker_slam` rig
hooks. No new clip required.

---

## Chartmaker's Echo — `kind: chartmaker_echo`

> **Status:** new. The chartmaker tile uses `chartmaker_stone.glb`
> already — the **boss is the stone, awakened**. Build the echo as
> a *taller* variant of the stone with arms / face / fold-legs that
> only emerge when the encounter starts.

| Field | Value |
|---|---|
| Tier / role | boss · meta encounter — folds rooms behind you mid-fight |
| heightM | 1.90 |
| Footprint | 1 × 1 (humanoid stone form) |
| Concept art | TBD — base on `docs/concept-art/chartmaker-stone.png` |
| Existing rig | none — but the stone GLB shape is canonical |

### Silhouette

A standing stone come alive. Carved with ink-glyphs. Two arms emerge
from the slab, the head rises out of the cap, and stubby legs fold
down from the base. **Always reads as a moving stone**, never a
person.
- Vertical chunky stone column (matches existing `chartmaker_stone.glb`)
- Glowing rune disc at the base (matches the existing in-world
  decoration)
- Gold rune-glyphs etched into the body — these *light up sequentially*
  during the room-fold telegraph

### Materials

| Material | Color | Roughness | Notes |
|---|---|---|---|
| `RuneStone`  | `#7a7268` (warm gray) | 0.9 | Body |
| `RuneGlyph`  | `#b58637` (gold) emissive 0.6 | 0.4 | Etched glyphs |
| `RuneEye`    | `#ffd078` emissive 1.0 | 0.3 | Single rune-eye on the cap |

### Rig

One unusual structure — fewer named groups, since legs are stubby:

```
ChartmakerEcho (root)
├── Body                # column
│   ├── Glyph_a … Glyph_h  (8 glyphs, parented to Body, sequenced via animation)
│   └── RuneEye
├── Head                # rises +0.4u when the fight begins
├── Arm_L
├── Arm_R
└── Leg_L / Leg_R       # bandy stubs, hidden by base when idle
```

### Mechanic note for animator

The boss's signature is a **room-fold** — every 12s, three glyphs
light up around its body, the camera flashes white, and the room's
walls visually rotate 90°. The model just needs the glyphs as
distinct named groups; the engine drives the light-sequence + flash.

---

## Common notes for the session

### Concept art — generate first

For Pale Hag and Chartmaker's Echo, run the master concept-art prompt
stem (`docs/concept-art-prompts-master.md`) with these subjects
**before opening Blender**. A reference image cuts modeling time in
half.

```
Pale Hag concept prompt:
  "[stem]. Bone-white wraith of a bramble queen. Skull-ovoid head,
   crown of bone teeth, robes of woven bone-rags, hollowed eyes.
   Top-down 3/4 view. Stylized cozy RuneScape-flavor."

Chartmaker's Echo prompt:
  "[stem]. Standing stone come alive. Tall granite column with
   glowing gold rune-glyphs along its body, single rune-eye on the
   cap, two stone arms emerged. Stubby fold-down legs at the base.
   Top-down 3/4 view."
```

Drop both into `docs/concept-art/` once done.

### Pipeline checklist (per boss)

1. [ ] Generate / find concept art → `docs/concept-art/<id>.png`
2. [ ] Open Blender, import the reference as background image
3. [ ] Block out with primitives at the heightM (one Blender unit = one meter)
4. [ ] Name every group + sub-part per the rig structure above
5. [ ] Re-parent sub-parts (eyes, crown, glyphs) to their parent group
6. [ ] Apply scale + rotation
7. [ ] Add Principled BSDF materials with the names + colors above
8. [ ] `bpy.ops.mesh.remove_doubles` on every mesh
9. [ ] Add bevel modifier (`ANGLE`, 30°, scale-aware width, 2 segments)
10. [ ] `Toonify` colors slightly (cap saturation, lift mid-tones)
11. [ ] Export with the glTF settings above to `models/<id>.glb`
12. [ ] In `src/scene/characters.js`, add a `loadXGLB()` + `buildXMesh()` pair following the cow / goblin pattern; preload in main.js's `loadAllArchetypes()`-equivalent block
13. [ ] Wire the spawn factory in `src/game/enemies.js` to use the new mesh
14. [ ] Verify in-game: walk to the boss spawn, confirm the silhouette reads at top-down camera distance, dissolve animation fires on death
15. [ ] Update `src/data/enemy-defs.js` `model:` field

### Time estimate

| Step | Hedgemother (rebuild) | Pale Hag (new) | Chartmaker's Echo (new) |
|---|---|---|---|
| Concept art | 0 (have) | 15 min | 15 min |
| Blockout + rig | 30 min | 60 min | 60 min |
| Materials + bevel | 15 min | 15 min | 15 min |
| Export + wire | 15 min | 20 min | 20 min |
| **Total** | ~1h | ~1h 50m | ~1h 50m |

Plan a single ~5h session for all three, or split each across days.

### What NOT to do

- Don't skin the rig with bones — the engine uses procedural
  rotation of named groups. Skinned animation breaks the existing
  `animateGoblin` pipeline.
- Don't author idle / walk / attack clips inside the GLB — those
  are procedural in `src/anim/*.js`.
- Don't share materials across instances at clone time without
  cloning first (see `varyInstance` in characters.js + the
  `feedback_blender_bevel_pipeline.md` material-clone note).
- Don't add textures unless you also bake the UV. PBR colors via
  Principled BSDF base color are sufficient at this style scale.
