# 50 — Procedural toon ground floor — implementation notes

2026-06-29. Owner: "the floor tiles don't look good — rethink from first
principles." Ran a diverse-attempts + judge workflow (4 shader approaches:
voronoi-cobble / FBM-organic / anti-tiling-stochastic / unified-biome → a
rendering-lead judge synthesized the final).

## The problem
The old floor was ONE crypt-brick `PlaneMesh` per walkable tile (N draw calls),
`uv1_triplanar` + per-biome albedo tint. A literal repeating brick lattice that
read as "crypt brick" in every biome — the #1 procedural-box tell.

## First principles (why stylized floors read well top-down)
1. **Value hierarchy** — the floor is a stage, not an actor; it sits a notch
   below walls/props/player in value+saturation so the eye never stops on it.
2. **Low-frequency variation** beats high-frequency detail under a telephoto
   top-down lens — big shapes + slow macro drift, not grain (grain shimmers/moires).
3. **Readable, not noisy** — structure (cell/grout lattice) says "stone you walk
   on"; each cell is ONE flat color = inherently posterized = on-style.
4. **Palette discipline** — every cell is a controlled base↔accent mix nudged by
   a shared macro tint; a tight 2-color-plus-drift ramp, never a rainbow.

## What shipped
`shaders/toon_ground.gdshader` — worldspace procedural ground sampled from world
XZ (seamless across the merged mesh, no repeat):
- **Voronoi cell plates** with dark **grout seams** = the floor's own interior
  linework (an inverted hull inks nothing on a flat interior, so the grout *is*
  the line). Per-cell flat-posterized color via hash.
- **Anti-tiling:** per-biome `domain_rotation` (off-axis lattice) + FBM
  `domain_warp` + macro mottle drift → no axis-aligned grid read.
- **No-sin Dave-Hoskins hash** (GPU-stable), `fwidth` analytic AA on grout,
  `detail_fade` distance calm (anti-moire), fake cobble-dome normal so torches
  glint, optional emissive crystal **veins** / **snow sparkle** / **water pools**.
- **Engine `diffuse_toon`/`specular_toon` lighting** (NOT a custom `light()`):
  bands N·L (clean Sun cel band) while leaving each torch's distance attenuation
  smooth, so overlapping torch pools stay soft — never additive hard rings, and
  it matches the props' house cel model. This was the decisive call.

**Mesh:** one merged `ArrayMesh` via `SurfaceTool.append_from(PlaneMesh)` over the
exact walkable footprint = ONE draw call, seamless, honest silhouette (non-rect
rooms just work). Collision/navmesh stay separate passes. Inverted-hull ink chains
as `next_pass`.

**Per biome** (`FLOOR_BIOME` table, keys 1:1 with shader uniforms) the STRUCTURE
morphs, not just tint: hard warm flagstone (crypt), cool rock plates + glowing
crystal veins (mineral_seam), soft warped dirt+leaf with no grout grid
(wood_grove), mud + glossy water pools (bog), packed snow filling the cracks +
sparkle + blue seams (summit).

## Integration (scripts/layout_loader.gd)
`_floor_mat` is now a `ShaderMaterial` built per-run by `_make_floor_material(
_biome_id)` after `_resolve_biome`. `_build_grid` places walls only; the new
`_build_floor_mesh` builds the merged surface. `_apply_biome_palette` is wall-only
now; the floor_tex override and `_place_floor` are gone. All suites green
(boot 93/0, dungeon 25/0, transitions 59/0).

## Tuning knobs
`cell_scale` (m per cobble; ≥0.5 to avoid shimmer), `cell_strength` (0 dirt → 1
stone plates), `noise_amt`/`mottle_scale` (macro mottle), `wet_blend`/`snow_blend`/
`vein_glow`/`sparkle_amt` (biome features), `domain_rotation` (unique per biome).
Keep base/accent ≤ ~0.96 so Filmic+glow doesn't halo (summit snow is the exception).
