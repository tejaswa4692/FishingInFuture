shader_type spatial;
render_mode cull_disabled, diffuse_toon;

uniform vec4 BaseColor : source_color = vec4(0.141176, 0.156863, 0.0745098, 1.0);
uniform vec4 WindColor : source_color = vec4(0.384314, 0.529412, 0.301961, 1.0);
uniform sampler2D WindNoise : hint_default_black;

uniform vec2 WindDirection = vec2(1.0, 0.0);
uniform float WindSpeed : hint_range(0.0, 5.0) = 1.0;
uniform float WindSwayMultiplyer : hint_range(0.0, 5.0) = 1.0;
uniform float WindColorStrength : hint_range(0.0, 1.0) = 0.3;

uniform float HideRadius : hint_range(0.0, 5.0) = 0.6;
uniform float FadeWidth : hint_range(0.01, 5.0) = 0.5;

varying float wind_dim;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 wind_dir = normalize(WindDirection);
	vec2 pan_source = world_pos.xz + wind_dir * TIME * WindSpeed;
	vec2 noise_uv = pan_source * 0.1;
	vec3 noise_sample = texture(WindNoise, noise_uv).rgb;

	wind_dim = noise_sample.r;

	float height_mask = UV.y;

	VERTEX += (noise_sample * height_mask) * vec3(0.1, 0.1, 0.1) * (WindSwayMultiplyer);
	// end of vertex()
	vec3 blade_origin = MODEL_MATRIX[3].xyz;
	float d = distance(blade_origin, CAMERA_POSITION_WORLD);
	float near_fade = smoothstep(HideRadius, HideRadius + FadeWidth, d);
	VERTEX *= near_fade;
}

void fragment() {
	float gradient_t = 1.0 - UV.y;
	vec3 blade_color = mix(BaseColor, WindColor, gradient_t).rgb;

	blade_color *= mix(1.0, 1.0 - wind_dim, WindColorStrength);

	ALBEDO = blade_color;
	NORMAL = vec3(0.0, 1.0, 0.0);
}