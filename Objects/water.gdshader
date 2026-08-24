shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

// --- Color ---
uniform vec4 shallow_color : source_color = vec4(0.35, 0.75, 0.85, 0.55);
uniform vec4 deep_color : source_color = vec4(0.0, 0.15, 0.3, 0.95);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float depth_fade_distance : hint_range(0.1, 20.0) = 4.0;

// --- Waves (procedural, no texture needed) ---
uniform float wave_height : hint_range(0.0, 2.0) = 0.15;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.8;
uniform float wave_scale : hint_range(0.1, 5.0) = 1.0;
uniform int wave_count : hint_range(1, 6) = 4;

// --- Surface / realism ---
uniform float gloss_specular : hint_range(0.0, 1.0) = 0.7;
uniform float gloss_roughness : hint_range(0.0, 1.0) = 0.3;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.03;
uniform float foam_width : hint_range(0.0, 3.0) = 0.35;
uniform float foam_noise_scale : hint_range(1.0, 50.0) = 12.0;

varying vec3 world_pos;
varying vec3 wave_normal;

// Sum of sine waves — cheap Gerstner-ish approximation
float wave_height_at(vec2 pos, float t) {
	float h = 0.0;
	float amp = 1.0;
	float freq = wave_scale;
	vec2 dir = vec2(1.0, 0.4);
	for (int i = 0; i < 6; i++) {
		if (i >= wave_count) break;
		dir = normalize(vec2(sin(float(i) * 12.9898), cos(float(i) * 78.233)));
		h += sin(dot(pos, dir) * freq + t * wave_speed) * amp;
		amp *= 0.55;
		freq *= 1.8;
	}
	return h * wave_height;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	float eps = 0.1;

	float h_center = wave_height_at(wp.xz, t);
	float h_dx = wave_height_at(wp.xz + vec2(eps, 0.0), t);
	float h_dz = wave_height_at(wp.xz + vec2(0.0, eps), t);

	VERTEX.y += h_center;

	vec3 tangent_x = normalize(vec3(eps, h_dx - h_center, 0.0));
	vec3 tangent_z = normalize(vec3(0.0, h_dz - h_center, eps));
	wave_normal = normalize(cross(tangent_z, tangent_x));

	world_pos = wp + vec3(0.0, h_center, 0.0);
}

void fragment() {
	NORMAL = normalize((VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz);

	// --- Depth-based color ---
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float scene_depth = -view_pos.z;
	float water_depth = -VERTEX.z;
	float depth_diff = clamp((scene_depth - water_depth) / depth_fade_distance, 0.0, 1.0);

	vec4 water_color = mix(shallow_color, deep_color, depth_diff);

	// --- Refraction using wave normal ---
	vec2 refract_offset = wave_normal.xz * refraction_strength;
	vec3 refracted = textureLod(screen_texture, SCREEN_UV + refract_offset, 1.0).rgb;
	vec3 base_color = mix(refracted, water_color.rgb, water_color.a);

	// --- Foam at shoreline ---
	float foam_edge = clamp(1.0 - (scene_depth - water_depth) / max(foam_width, 0.001), 0.0, 1.0);
	float foam_noise = hash(floor(UV * foam_noise_scale + TIME * 0.5));
	float foam_mask = smoothstep(0.85, 1.0, foam_edge) * step(0.3, foam_noise);
	base_color = mix(base_color, foam_color.rgb, foam_mask);

	ALBEDO = base_color;
	SPECULAR = gloss_specular;
	ROUGHNESS = gloss_roughness;
	METALLIC = 0.0;
	ALPHA = mix(water_color.a, 1.0, foam_mask);
}