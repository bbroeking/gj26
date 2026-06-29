shader_type canvas_item;

// Subtle radial vignette — darkens the screen edges to pull the eye to the
// player at frame center and reinforce the torchlit enclosure. Kept gentle so
// it reads as cozy enclosure, not dirt on the lens. Strength is driven
// per-biome from layout_loader (deeper/murkier biomes a touch stronger).

uniform float strength : hint_range(0.0, 1.0) = 0.28;
uniform float inner : hint_range(0.0, 1.0) = 0.42;
uniform float outer : hint_range(0.0, 1.5) = 0.95;
uniform vec3 tint : source_color = vec3(0.0, 0.0, 0.03);

void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(inner, outer, d) * strength;
	COLOR = vec4(tint, v);
}
