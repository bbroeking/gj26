// Spec-34 AAA Brambles (session 1) — vine-grow dissolve shader.
//
// Mask reveals/hides the mesh along the UV.y axis (base → tip on a thorn
// or tether segment). A bright emissive edge band tracks the dissolve
// front so the eye sees the vine MATERIALIZE rather than scale-pop in.
// Same shader runs in reverse for the wither beat (growth 1 → 0) so vines
// retract from tip → base.
//
// Per AAA VFX research: materialization is the single biggest gap between
// polished-indie and AAA nature spells (Genshin Tighnari, WoW Druid
// Entangling Roots, D4 Pulverize all use mesh-grow not scale-pop).
//
// Usage:
//   var mat := ShaderMaterial.new()
//   mat.shader = preload("res://assets/vfx/vine_grow.gdshader")
//   mat.set_shader_parameter("base_color", THORN_BASE_COLOR)
//   mat.set_shader_parameter("edge_color", Color(0.45, 1.0, 0.35))
//   mat.set_shader_parameter("growth", 0.0)
//   # then tween "shader_parameter/growth" 0.0 -> 1.0 over snap-sec

shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

uniform vec4 base_color : source_color = vec4(0.12, 0.08, 0.05, 1.0);
uniform vec4 edge_color : source_color = vec4(0.45, 1.0, 0.35, 1.0);
// 0.0 = fully hidden, 1.0 = fully grown. Tweened by the spell code.
uniform float growth : hint_range(0.0, 1.0) = 0.0;
// Width of the bright emissive band that follows the dissolve front.
uniform float edge_width : hint_range(0.01, 0.4) = 0.10;
// Emission energy multiplier on the EDGE band (kept separate from the
// body so the front pulses hot while the body stays a warm rim).
uniform float edge_energy : hint_range(0.0, 12.0) = 6.0;
// Emission energy multiplier on the BODY (post-front, the grown part).
uniform float body_energy : hint_range(0.0, 4.0) = 0.8;
// Set to true to invert the dissolve direction — tip-first instead of
// base-first. Useful if the mesh's UVs are flipped or for variation.
uniform bool invert_direction = false;
// Soft cut into the dissolve mask so the boundary isn't razor-sharp —
// gives the front a small antialiased gradient.
uniform float edge_softness : hint_range(0.0, 0.2) = 0.02;

void fragment() {
	// Pick the axis: UV.y = 0 is base, 1 is tip. invert flips it.
	float axis = invert_direction ? (1.0 - UV.y) : UV.y;

	// The dissolve front sweeps from 0 (nothing visible) to 1 (all visible)
	// as `growth` goes 0 → 1. front_pos is the threshold along the axis.
	float front_pos = growth;

	// Below the front = visible body. Above = invisible (alpha 0).
	// Use smoothstep for a soft antialiased edge instead of a hard cut.
	float body_mask = smoothstep(front_pos, front_pos - edge_softness, axis);

	// Edge band — a narrow strip around the front position that glows hot.
	// distance_to_front is 0 right at the front, growing on either side.
	float dist_to_front = abs(axis - front_pos);
	float edge_mask = 1.0 - smoothstep(0.0, edge_width, dist_to_front);
	// Edge only lights the BELOW-front side (the part that just materialized).
	edge_mask *= step(axis, front_pos);

	// Final color = body color in the grown part + edge color on the front.
	vec3 col = base_color.rgb * body_energy + edge_color.rgb * edge_mask * edge_energy;
	float alpha = body_mask;

	ALBEDO = col;
	EMISSION = col;
	ALPHA = alpha;
}
