shader_type spatial;
render_mode unshaded, depth_draw_always;
//render_mode unshaded;

//inputs
uniform sampler2D tiling_texture : source_color;
uniform float tiling_texture_size : hint_range(1, 400) = 256;


uniform float RimContrast : hint_range(0, 10) = .5;
uniform vec4 rim_color : source_color;

uniform sampler2D main_texture;
uniform sampler2D gradient_texture;

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment() {
	//AO
	vec4 texture_main = texture(main_texture, UV.xy) ;

	//galaxy time
	vec2 galexyUV = FRAGCOORD.xy;
	vec2 galexySize = (galexyUV / tiling_texture_size) * -1.0;
	vec4 galaxy = texture(tiling_texture, galexySize);

	//vec4 output = (galaxy+fresnel)*texture_AO_color ;
	//vec4 output = (texture_main + fresnel) * galaxy ;

	vec4 output = clamp( overlay( ( texture_main ), galaxy), 0.1, 1);

	vec4 test = texture( gradient_texture, vec2(output.b, 0.0) ) ;

	ALBEDO = test.rgb;
	ALPHA = 1.0;
}