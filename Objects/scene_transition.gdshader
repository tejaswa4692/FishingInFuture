shader_type canvas_item;

// 0.0 = no water (empty), 1.0 = fully covers the screen
uniform float fill_level : hint_range(0.0, 1.0) = 0.0;

uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.025;
uniform float wave_frequency : hint_range(0.0, 30.0) = 8.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;

uniform float edge_softness : hint_range(0.0, 0.05) = 0.01;
uniform float foam_thickness : hint_range(0.0, 0.05) = 0.012;

uniform vec4 water_color : source_color = vec4(0.05, 0.45, 0.65, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);

void fragment() {
	float wave = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
	wave += sin(UV.x * wave_frequency * 2.3 + TIME * wave_speed * 1.7) * wave_amplitude * 0.4;

	// UV.y = 0 is top of screen, UV.y = 1 is bottom.
	// fill_level 0 -> surface sits at the bottom edge (no visible water)
	// fill_level 1 -> surface sits at the top edge (screen fully covered)
	float surface_y = (1.0 - fill_level) + wave;
	float dist_below_surface = UV.y - surface_y;

	float alpha = smoothstep(0.0, edge_softness, dist_below_surface);

	vec4 col = water_color;
	if (dist_below_surface >= 0.0 && dist_below_surface < foam_thickness) {
		col = foam_color;
	}

	COLOR = vec4(col.rgb, col.a * alpha);
}