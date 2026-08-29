shader_type canvas_item;

// ---------------------------------------------------------------------------
// UNDERWATER CAMERA POST-PROCESS SHADER (Godot 4) — ColorRect version
//
// SETUP:
// 1. Add a ColorRect as a direct child of a CanvasLayer (screen-space).
//    Layout > Anchors Preset > Full Rect, so it always covers the viewport.
// 2. Set the ColorRect's Mouse Filter to "Ignore".
// 3. New ShaderMaterial on the ColorRect -> load this file.
// 4. Assign a noise texture to the `noise_texture` uniform in the Inspector
//    (a tileable grayscale noise image works best — Perlin/simplex/value
//    noise, seamless if you plan to tile it).
// 5. Toggle `underwater_amount` (0 to 1) from GDScript to fade in/out when
//    the camera crosses the water line.
// ---------------------------------------------------------------------------

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;

// --- Tunable parameters ---------------------------------------------------
uniform vec4 water_tint : source_color = vec4(0.4, 0.75, 0.95, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.35;
uniform float brightness_lift : hint_range(0.0, 1.0) = 0.22; // raises shadows so tint isn't invisible on dark scenes

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.012;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.2;
uniform float distortion_scale : hint_range(1.0, 40.0) = 12.0;

uniform float vignette_strength : hint_range(0.0, 2.0) = 0.35;
uniform float vignette_softness : hint_range(0.1, 2.0) = 0.6;

uniform float caustic_strength : hint_range(0.0, 1.0) = 0.15;
uniform float caustic_scale : hint_range(1.0, 40.0) = 10.0;
uniform float caustic_speed : hint_range(0.0, 3.0) = 0.6;

uniform float chroma_aberration : hint_range(0.0, 0.01) = 0.0025;

uniform float underwater_amount : hint_range(0.0, 1.0) = 1.0; // drive this from GDScript to fade in/out

// --- Caustic pattern sampled from your assigned noise texture --------------
// Two scrolling samples of the same texture, offset and combined, give a
// shifting caustic-light look without any procedural noise function.
float caustic_pattern(vec2 uv, float t) {
	vec2 p1 = uv * caustic_scale * 0.1 + vec2(t * 0.06, t * 0.04);
	vec2 p2 = uv * caustic_scale * 0.17 - vec2(t * 0.03, t * 0.055);
	float n1 = texture(noise_texture, p1).r;
	float n2 = texture(noise_texture, p2).r;
	float c = pow(n1 * n2, 2.0) * 4.0;
	return clamp(c, 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * distortion_speed;

	// --- Screen-space wobble (refraction through moving water) ---
	vec2 offset = vec2(
		sin(uv.y * distortion_scale + t),
		cos(uv.x * distortion_scale + t * 1.3)
	) * distortion_strength * underwater_amount;

	vec2 distorted_uv = clamp(uv + offset, vec2(0.001), vec2(0.999));

	// --- Chromatic aberration (slight color channel split at edges) ---
	vec2 center_dir = normalize(distorted_uv - vec2(0.5) + 1e-5);
	float edge_dist = length(distorted_uv - vec2(0.5));
	vec2 ca_offset = center_dir * chroma_aberration * edge_dist * underwater_amount;

	float r = texture(screen_texture, distorted_uv - ca_offset).r;
	float g = texture(screen_texture, distorted_uv).g;
	float b = texture(screen_texture, distorted_uv + ca_offset).b;
	vec3 base_color = vec3(r, g, b);

	// --- Transparent blue tint: lift shadows first, then add blue light ---
	// mix() alone stays dark on a dark scene (mixing toward blue-black is
	// still black); lifting shadows + adding tint makes the water visible.
	vec3 lifted = base_color + vec3(brightness_lift) * underwater_amount;
	vec3 tinted = lifted + water_tint.rgb * tint_strength * underwater_amount;

	// --- Caustic light shimmer, from the assigned noise texture ---
	float caustics = caustic_pattern(uv, TIME * caustic_speed);
	vec3 with_caustics = tinted + vec3(caustics) * caustic_strength * underwater_amount;

	// --- Vignette (darker, murkier at edges) ---
	float vign = smoothstep(0.8, vignette_softness, edge_dist);
	vec3 final_color = mix(with_caustics, with_caustics * (1.0 - vign * vignette_strength), underwater_amount);

	COLOR = vec4(clamp(final_color, vec3(0.0), vec3(1.0)), 1.0);
}

// ---------------------------------------------------------------------------
// GDSCRIPT HOOK EXAMPLE (fade in/out when crossing the water line):
//   var tween = create_tween()
//   tween.tween_property(underwater_rect.material, "shader_parameter/underwater_amount", 1.0, 0.6)
// ---------------------------------------------------------------------------