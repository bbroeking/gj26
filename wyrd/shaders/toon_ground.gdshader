// Wayfinder — unified procedural TOON ground floor.
// res://shaders/toon_ground.gdshader   (Godot 4.6)
//
// ONE shader, FIVE biomes, ONE merged-surface draw call. The whole floor look is
// computed from WORLD XZ (sampled via MODEL_MATRIX * VERTEX in a varying), so the
// merged walkable mesh is seam-free with NO tile period to read top-down.
//
// WHY ENGINE-TOON LIGHTING (not a custom light()): the floor is seen from a
// telephoto top-down lens, so its normal is ~constant and lighting can't carry
// the detail — the cel read lives in the ALBEDO (flat posterized cells + grout +
// mottle). Lighting is `diffuse_toon, specular_toon`, the SAME model the
// props/walls/enemies already use, so the floor speaks one cel language AND the
// many warm torch OmniLights stay soft-banded warm pools (their smooth distance
// attenuation prevents the additive hard-ring "mush" a custom per-light band
// would create). The cool env AMBIENT_LIGHT fills the unlit value automatically.
//
// THREE worldspace primitives compose the look, morphed per-biome by uniforms:
//   1. Worley/Voronoi cells -> cobble/flagstone plates; F2-F1 ~ 0 inks the GROUT
//      seam (the floor's interior linework, since an inverted hull cannot ink a
//      flat plane). The vector-to-cell-centre domes each plate via a gentle
//      NORMAL tilt so torches glint across the cobbles top-down.
//   2. value-noise FBM -> macro mottle (no two cells share a palette) + carves
//      wet puddle pools (bog) and snow-drift coverage (summit).
//   3. stylized response -> glossy wet sheen, glowing mineral veins in cracks,
//      view-dependent snow sparkle, RIM/RIM_TINT to match the old floor.
//
// ANTI-TILING (so a square lattice never reads as an axis-aligned grid from
// above): an off-axis `domain_rotation` (different per biome) turns the lattice
// off the world X/Z axes, an FBM `domain_warp` bends any straight cell rows, and
// the macro mottle guarantees regional drift. hash-without-sine (Dave Hoskins)
// = stable across GPUs, no precision cliff at dungeon coords.
//
// The inverted-hull ink shell rides as this material's next_pass (set in GDScript).
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

// ---- palette (set per-biome from FLOOR_BIOME; pass Color -> source_color) ----
uniform vec4  base_col   : source_color = vec4(0.55, 0.48, 0.40, 1.0);
uniform vec4  accent_col : source_color = vec4(0.40, 0.34, 0.28, 1.0);
uniform vec4  mortar_col : source_color = vec4(0.20, 0.16, 0.13, 1.0);
uniform vec4  snow_col   : source_color = vec4(0.96, 0.98, 1.00, 1.0);
uniform vec4  wet_tint   : source_color = vec4(0.26, 0.34, 0.38, 1.0);

// ---- structure / biome morph dials ----
uniform float cell_scale    : hint_range(0.2, 3.0)  = 0.55; // metres per cobble/clump
uniform float cell_strength : hint_range(0.0, 1.0)  = 0.85; // cobble contrast + grout depth (1 stone .. 0 soft dirt)
uniform float mortar_width  : hint_range(0.0, 0.35) = 0.06; // grout / crack thickness
uniform float noise_amt     : hint_range(0.0, 1.0)  = 0.35; // macro mottle amount (dirt/leaf high)
uniform float mottle_scale  : hint_range(0.02, 1.0) = 0.16; // macro mottle frequency (1/metres)
uniform float snow_blend    : hint_range(0.0, 1.0)  = 0.0;  // snow fill + brighten + sparkle (summit)
uniform float wet_blend     : hint_range(0.0, 1.0)  = 0.0;  // puddle coverage + sheen (bog)
uniform float puddle_thresh : hint_range(0.0, 1.0)  = 0.55; // higher = rarer/smaller pools

// ---- anti-tiling ----
uniform float warp_amount    : hint_range(0.0, 2.0)    = 0.45; // domain warp (bend cell rows)
uniform float warp_freq      : hint_range(0.05, 1.0)   = 0.35; // warp frequency
uniform float domain_rotation: hint_range(0.0, 1.5708) = 0.40; // off-axis lattice angle (per biome)

// ---- surface response ----
uniform float base_rough  : hint_range(0.0, 1.0) = 0.90;
uniform float bevel       : hint_range(0.0, 1.5) = 0.45; // cobble doming (keep low; strong = noise)
uniform float vein_glow   : hint_range(0.0, 3.0) = 0.0;  // emissive cracks (mineral_seam)
uniform float sparkle_amt : hint_range(0.0, 4.0) = 0.0;  // snow glint energy (summit)
uniform float rim_amt     : hint_range(0.0, 1.0) = 0.25;
uniform float rim_tint    : hint_range(0.0, 1.0) = 0.40;
uniform float detail_fade : hint_range(4.0, 80.0) = 28.0; // camera dist where micro detail calms (anti-moire)

varying vec3 v_world;

// ---- hashing (no sin: stable across GPUs, no large-coord precision cliff) ----
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.02;          // irrational-ish lacunarity -> no visible repeat
		a *= 0.5;
	}
	return v;
}
// Worley/Voronoi over a 3x3 neighbourhood. Returns nearest (f1) + second (f2)
// distances, the vector to the nearest feature point (cobble doming) and a
// per-cell random id (per-cell tone/hue).
void voronoi(vec2 x, out float f1, out float f2, out vec2 to_center, out float cid) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	f1 = 8.0;
	f2 = 8.0;
	to_center = vec2(0.0);
	cid = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash22(n + g);
			vec2 r = g + o - f;                 // fragment -> feature point
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				to_center = r;
				cid = hash12(n + g);
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	f1 = sqrt(f1);
	f2 = sqrt(f2);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w0 = v_world.xz;
	float dist = length(VERTEX);                                 // view-space pos = camera distance
	float detail = 1.0 - smoothstep(detail_fade * 0.55, detail_fade, dist);

	// off-axis rotation -> lattice never aligns to world X/Z (no grid read top-down)
	float cr = cos(domain_rotation);
	float sr = sin(domain_rotation);
	vec2 w = mat2(vec2(cr, -sr), vec2(sr, cr)) * w0;

	// domain warp -> straight cell rows bend, no straight repeating seam
	w += (vec2(fbm(w * warp_freq + 17.0), fbm(w * warp_freq + 43.0)) - 0.5) * warp_amount;

	// cobble/clump field (seamless across every merged tile)
	float f1;
	float f2;
	float cid;
	vec2 toc;
	voronoi(w / max(cell_scale, 0.05), f1, f2, toc, cid);
	float edge = f2 - f1;                                        // small at cell borders = grout
	float aa = fwidth(edge) * 1.5 + 0.0001;                      // analytic AA -> kills top-down shimmer
	float mortar_mask = 1.0 - smoothstep(mortar_width - aa, mortar_width + aa, edge);

	// per-cell + macro + micro variation -> no two patches read alike
	float macro = fbm(w * mottle_scale);
	float micro = fbm(w * mottle_scale * 6.0) * detail;

	// ---- albedo ----
	vec3 col = base_col.rgb;
	col *= 1.0 + (cid - 0.5) * 0.30 * cell_strength;                     // per-cobble value
	col = mix(col, accent_col.rgb, clamp(macro * noise_amt, 0.0, 1.0));  // macro mottle
	col = mix(col, accent_col.rgb, cid * cell_strength * 0.20);          // per-cell hue drift
	col += (micro - 0.5) * 0.06 * noise_amt;                             // fine grit
	col = mix(col, mortar_col.rgb, mortar_mask * cell_strength);         // grout / cracks

	// snow packs the cracks, brightens (summit)
	float snow = clamp(snow_blend * (0.55 + 0.9 * macro), 0.0, 1.0);
	mortar_mask *= (1.0 - snow * 0.85);
	col = mix(col, snow_col.rgb, snow);

	// FBM-carved puddle pools darken + go glossy + sky-tinted (bog)
	float pud = smoothstep(puddle_thresh, puddle_thresh + 0.12, fbm(w * 0.22 + 7.3)) * wet_blend;
	col = mix(col, col * 0.40 + wet_tint.rgb * 0.18, pud);

	// ---- cobble doming NORMAL (reuse the voronoi we already computed) ----
	vec2 slope = -toc * bevel * detail * (1.0 - mortar_mask * 0.6);
	vec3 nrm_w = normalize(vec3(slope.x, 1.0, slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm_w, 0.0)).xyz);

	// ---- toon surface response ----
	ALBEDO    = max(col, vec3(0.0));
	ROUGHNESS = mix(base_rough, 0.12, pud);                  // puddles -> glossy sheen
	SPECULAR  = mix(0.20, 0.85, max(pud, snow * 0.4));       // wet / ice toon highlight
	METALLIC  = 0.0;
	RIM       = rim_amt;
	RIM_TINT  = rim_tint;

	// glowing mineral veins in the cracks + view-dependent snow sparkle
	vec3 emit = accent_col.rgb * mortar_mask * vein_glow;
	float spk = step(0.86, hash12(floor(w * 22.0))) * detail;
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	emit += snow_col.rgb * spk * fres * sparkle_amt * snow;
	EMISSION = emit;
}
