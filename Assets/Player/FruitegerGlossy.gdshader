shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- Base color / glass tint ---
uniform vec4 base_color : source_color = vec4(0.55, 0.85, 0.95, 0.55);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.05;

// --- Glossiness ---
uniform float specular_amount : hint_range(0.0, 1.0) = 0.9;
uniform float roughness_amount : hint_range(0.0, 1.0) = 0.08;
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.0;

// --- Fresnel rim glow ---
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_power : hint_range(0.1, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 3.0) = 1.4;

// --- Iridescent sheen ---
uniform vec4 iridescence_color_a : source_color = vec4(0.6, 1.0, 0.9, 1.0);
uniform vec4 iridescence_color_b : source_color = vec4(0.8, 0.7, 1.0, 1.0);
uniform float iridescence_strength : hint_range(0.0, 1.0) = 0.25;

// --- Fake subsurface / translucency ---
uniform float translucency_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec4 translucency_color : source_color = vec4(0.7, 0.95, 1.0, 1.0);

// --- Top-down highlight streak ---
uniform float highlight_streak_strength : hint_range(0.0, 2.0) = 0.5;
uniform float highlight_streak_sharpness : hint_range(1.0, 64.0) = 24.0;

// --- Water interaction ---
uniform float water_level_y = 0.0;
uniform vec4 submerged_tint : source_color = vec4(0.1, 0.4, 0.55, 1.0);
uniform float submerged_blend : hint_range(0.0, 1.0) = 0.55;
uniform float submerge_fade_distance : hint_range(0.01, 2.0) = 0.3;

// --- Waterline foam ---
uniform vec4 waterline_foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float waterline_foam_width : hint_range(0.0, 1.0) = 0.08;
uniform float foam_noise_scale : hint_range(1.0, 50.0) = 12.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), rim_power);

	// --- Screen-space refraction ---
	vec2 refract_offset = NORMAL.xy * refraction_strength;
	vec3 refracted = textureLod(screen_texture, SCREEN_UV + refract_offset, 1.0).rgb;
	vec3 color = mix(refracted, base_color.rgb, base_color.a);

	// --- Iridescent sheen ---
	float iridescence_t = clamp(dot(NORMAL, view_dir), 0.0, 1.0);
	vec3 iridescence = mix(iridescence_color_a.rgb, iridescence_color_b.rgb, iridescence_t);
	color = mix(color, iridescence, fresnel * iridescence_strength);

	// --- Rim glow ---
	color += rim_color.rgb * fresnel * rim_strength;

	// --- Fake translucency ---
	float backlight = clamp(dot(-NORMAL, view_dir), 0.0, 1.0);
	color += translucency_color.rgb * backlight * translucency_strength * 0.3;

	// --- Top streak highlight ---
	float streak = pow(clamp(dot(NORMAL, vec3(0.0, 1.0, 0.0)), 0.0, 1.0), highlight_streak_sharpness);
	color += vec3(1.0) * streak * highlight_streak_strength;

	// --- Submersion tint ---
	float submerge_t = clamp((water_level_y - world_pos.y) / submerge_fade_distance, 0.0, 1.0);
	color = mix(color, submerged_tint.rgb, submerge_t * submerged_blend);

	// --- Waterline foam band ---
	float dist_from_surface = abs(world_pos.y - water_level_y);
	float foam_band = 1.0 - smoothstep(0.0, waterline_foam_width, dist_from_surface);
	float foam_noise = hash(floor(world_pos.xz * foam_noise_scale + TIME * 0.5));
	float foam_mask = foam_band * step(0.3, foam_noise);
	color = mix(color, waterline_foam_color.rgb, foam_mask);

	ALBEDO = color;
	SPECULAR = specular_amount;
	ROUGHNESS = mix(roughness_amount, 0.15, submerge_t);
	METALLIC = metallic_amount;
	ALPHA = clamp(base_alpha + fresnel * 0.3, 0.0, 1.0);
}