shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// --- Tunables ---
uniform vec3 blob_color_hot : source_color = vec3(1.0, 0.25, 0.05);
uniform vec3 blob_color_cool : source_color = vec3(0.6, 0.05, 0.4);
uniform vec3 liquid_color : source_color = vec3(0.05, 0.02, 0.1);
uniform float blob_speed : hint_range(0.0, 3.0) = 0.6;
uniform float blob_scale : hint_range(0.1, 1.0) = 0.35;
uniform int blob_count : hint_range(1, 8) = 6;
uniform float glow_strength : hint_range(0.0, 5.0) = 1.5;
uniform float smoothness : hint_range(0.05, 1.0) = 0.3;
uniform float liquid_alpha : hint_range(0.0, 1.0) = 0.35;

varying vec3 v_object_cam_pos;
varying vec3 v_object_vertex;

void vertex() {
	v_object_vertex = VERTEX;
	v_object_cam_pos = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Polynomial smooth min, used to blend blobs into each other.
float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float blob_sdf(vec3 p, float time) {
	float d = 1e9;
	for (int i = 0; i < 8; i++) {
		if (i >= blob_count) {
			break;
		}
		float fi = float(i);
		float speed_var = 0.7 + hash13(vec3(fi, 1.0, 2.0)) * 0.6;
		float phase = hash13(vec3(fi, 5.0, 9.0)) * 6.2831;
		float x_off = (hash13(vec3(fi, 3.0, 7.0)) - 0.5) * 1.1;
		float z_off = (hash13(vec3(fi, 8.0, 4.0)) - 0.5) * 1.1;

		float y = sin(time * blob_speed * speed_var + phase) * 0.8;
		float wobble_x = sin(time * 0.3 + fi * 2.0) * 0.15;
		float wobble_z = cos(time * 0.25 + fi * 3.0) * 0.15;
		vec3 center = vec3(x_off + wobble_x, y, z_off + wobble_z);

		float r = blob_scale * (0.75 + 0.25 * sin(time * 0.5 + fi));
		float dist = length(p - center) - r;
		d = smin(d, dist, smoothness);
	}
	return d;
}

vec3 blob_normal(vec3 p, float time) {
	float e = 0.01;
	vec2 h = vec2(e, 0.0);
	return normalize(vec3(
		blob_sdf(p + h.xyy, time) - blob_sdf(p - h.xyy, time),
		blob_sdf(p + h.yxy, time) - blob_sdf(p - h.yxy, time),
		blob_sdf(p + h.yyx, time) - blob_sdf(p - h.yyx, time)
	));
}

void fragment() {
	vec3 ro = v_object_cam_pos;
	vec3 entry = v_object_vertex;
	vec3 rd = normalize(entry - ro);
	float t = length(entry - ro);
	float t_max = t + 4.0;
	float time = TIME;

	bool hit = false;
	vec3 p = entry;
	for (int i = 0; i < 64; i++) {
		p = ro + rd * t;
		float d = blob_sdf(p, time);
		if (d < 0.002) {
			hit = true;
			break;
		}
		t += d * 0.8;
		if (t > t_max) {
			break;
		}
	}

	if (!hit) {
		ALBEDO = liquid_color;
		EMISSION = liquid_color * 0.1;
		ALPHA = liquid_alpha;
	} else {
		vec3 n_obj = blob_normal(p, time);
		vec3 n_world = normalize((MODEL_MATRIX * vec4(n_obj, 0.0)).xyz);
		NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

		vec3 view_dir = normalize(-rd);
		float fresnel = pow(1.0 - clamp(dot(view_dir, n_obj), 0.0, 1.0), 3.0);
		float height_mix = clamp(p.y * 0.5 + 0.5, 0.0, 1.0);
		vec3 base_color = mix(blob_color_cool, blob_color_hot, height_mix);

		ALBEDO = base_color;
		EMISSION = base_color * glow_strength * (0.4 + fresnel);
		ALPHA = 0.95;
	}
}