shader_type spatial;
render_mode cull_disabled, diffuse_toon;

uniform vec4 BaseColor : source_color = vec4(0.141176, 0.156863, 0.0745098, 1.0);
uniform vec4 WindColor : source_color = vec4(0.384314, 0.529412, 0.301961, 1.0);
uniform sampler2D WindNoise : hint_default_black;

uniform vec2 WindDirection = vec2(1.0, 0.0);
uniform float WindSpeed : hint_range(0.0, 5.0) = 1.0;
uniform float WindSwayMultiplyer : hint_range(0.0, 5.0) = 1.0;
// Now drives BOTH how much the blade physically sways AND how much its
// color dims where the wind noise is strongest -- one knob for overall
// wind intensity. 0 = fully still, no color effect. 1 = full sway + dim.
uniform float WindColorStrength : hint_range(0.0, 1.0) = 0.3;

varying float wind_dim;

void vertex() {
	// World-space XZ position, used so the wind pattern is anchored to the
	// world (blades near each other move together) rather than per-instance.
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 wind_dir = normalize(WindDirection);
	vec2 pan_source = world_pos.xz + wind_dir * TIME * WindSpeed;
	vec2 noise_uv = pan_source * 0.1;
	vec3 noise_sample = texture(WindNoise, noise_uv).rgb;

	// Carry the same noise sample to the fragment stage so the color
	// dimming moves in perfect sync with the sway -- same pan, same speed,
	// same direction, no separate sampling needed.
	wind_dim = noise_sample.r;

	// Blend factor along the blade's height so the base stays anchored
	// and the tip sways more. Flip to (1.0 - UV.y) if it looks inverted --
	// see note below.
	float height_mask = UV.y;

	VERTEX += (noise_sample * height_mask) * vec3(0.1, 0.1, 0.1) * (WindSwayMultiplyer);
}

void fragment() {
	// Vertical gradient: base color near the root, wind-tint color toward
	// the tip. Flip to UV.y (drop the 1.0 -) if the gradient looks reversed --
	// see note below.
	float gradient_t = 1.0 - UV.y;
	vec3 blade_color = mix(BaseColor, WindColor, gradient_t).rgb;

	// Darken the blade where the wind noise is strongest, moving with the
	// same pan as the sway above.
	blade_color *= mix(1.0, 1.0 - wind_dim, WindColorStrength);

	ALBEDO = blade_color;

	// Normals forced straight up so every blade shades consistently
	// regardless of its random per-instance tilt/rotation.
	NORMAL = vec3(0.0, 1.0, 0.0);
}