# 49 — Environment quality pass — implementation notes

2026-06-29. Owner: "research what creates high-quality game environments, try to
implement each." Drove an 8-agent research workflow (current-state analysis + 6
quality dimensions: lighting, post-processing, atmosphere, composition, prop
density, materials) → a prioritized, Godot-mapped plan.

## Key finding
Wayfinder already had a competent stack (WorldEnvironment, SSAO, fog, glow,
Filmic tonemap, MSAA 4x, toon ink outlines, triplanar floor, per-biome palette).
The wins are **tuning + varying** what's there, not bolting on realism features
(SDFGI / SSR / SSIL / AgX deliberately stay OFF — they fight the flat cel look).
The keystone was a real **bug**: `ambient_light_source = SKY` made the authored
cool ambient dead, so shadows took a muddy grey sky tint (warm light + grey
shadow = the amateur tell).

## Implemented
**Batch 1 — lighting + surface** (commit `881b26f`):
- ambient SKY→COLOR cool-blue vs warm Sun/torches (temperature split, keystone)
- SSAO 2.4→1.2, tight radius, light_affect 0
- selective glow: glow_bloom→0 + emissive torch flame cores cross the HDR
  threshold so only the fire blooms (no full-frame haze)
- soft PCSS sun shadows (angular_distance 2.0, normal_bias 3.0); Sun 0.95→0.6
- toon diffuse/specular + rim on floor & walls; wall normal bump 5.0→1.3
- torch pooling (range 6, atten 2.0) + `flicker_light.gd` breathing energy;
  hero light 1.6→1.0
- project.godot use_debanding=true

**Batch 2 — per-biome mood** (commit `97ade7f`):
- `BIOME_ENV` table → per-biome ambient/fog color+density/glow/Sun (Environment
  duplicated per run, never mutates the .tscn); applied in `_resolve_biome`
- `ambient_motes.gd` — one camera-following GPUParticles3D per biome: grey dust
  (crypt), blue glints (mineral_seam), blooming fireflies (wood_grove), green
  wisps (bog), falling snow (summit). Mine reads cool, grove warm, summit cold —
  distinct places.

## Pending (ranked, from the research synthesis)
Medium: one-saturation-peak hierarchy (desaturate satellite decor); grounding
blob/decal contact shadows + baked vertex-AO at wall-floor seam; MultiMesh floor
+ micro-clutter scatter chunked per room; edge/corner seam dressing + per-biome
ground-cover carpets; decal grime/cracks/moss layer; lighting-as-wayfinding
emissive beacons (cool exit / warm boss door); subtle radial vignette shader;
height-fog + aerial_perspective + sun_scatter refinement; custom 3-band toon
ramp shader.
Larger: volumetric fog + god rays + boss-altar FogVolume (quality-gated);
per-biome 3D LUT grading; depth-scaled interest curve + boss approach vista;
faked bog-water reflection (single surface, not global SSR).

Full ranked list + Godot steps per item: the research synthesis (run
wf_00f29cd0-428).
