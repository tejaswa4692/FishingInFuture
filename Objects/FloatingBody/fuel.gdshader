shader_type canvas_item;

uniform float fV : hint_range(0.0, 1.0);
uniform float scale : hint_range(0.1, 5.0) = 1.0;

uniform vec4 liquid_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.05;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;

uniform float bob_amplitude : hint_range(0.0, 0.5) = 0.1;
uniform float bob_speed : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec2 uv = ((UV / (-0.10 * scale))) + vec2(1.25, 1.25);

    float
		sdf=length(uv),c=step(sdf,.85),

        vB=smoothstep(.1,.9,sin(uv.x+(PI*.5))-.3),
		vBA=vB*sin(TIME*wave_speed*2.)*(wave_amplitude*2.),

        fW=(sin(((TIME*wave_speed)+uv.x)*wave_frequency)*wave_amplitude)+vBA,
		bW=(sin(((TIME*-wave_speed)+uv.x)*wave_frequency+PI)*wave_amplitude)-vBA,

        fA=(sin(TIME*wave_speed*2.)*wave_amplitude)*vB,

        fP=fV * 2.3 +(sin((TIME)*bob_speed*PI)*bob_amplitude) - 1.1,

		fF=step(uv.y,(fA+fW)+fP)*c,
		bF=step(uv.y,(-fA+bW)+fP)*c;

    float rim = step(sdf,1.) - step(sdf,.9);
    float body = fF + (clamp(bF-fF,0.,1.) * .8);
    float highlight = clamp(pow((sdf+.01) * ((1.-(fF+bF))*c), 5.), 0., 1.);

    vec4 col = background_color;
    col = mix(col, liquid_color, clamp(body, 0., 1.));
    col = mix(col, highlight_color, highlight);
    col = mix(col, rim_color, rim);

    COLOR = col;
}