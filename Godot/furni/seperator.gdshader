shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D basecolor: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal;
uniform sampler2D roughness: hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform sampler2D pattern;
uniform float pattern_scale : hint_range(0, 200) = 1;
uniform float pattern_opacity : hint_range(0, 1) = 0.01;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;

void fragment() {
	vec4 i_basecolor = texture(basecolor, UV.xy) ;
	vec4 i_normal = texture(normal, UV.xy) ;
	vec4 i_roughness = texture(roughness, UV.xy) ;

	vec4 i_pattern = texture(pattern, ( UV * vec2(pattern_scale, pattern_scale) ).xy) ;
	vec3 averaged = ( color1.rgb + color2.rgb ) * 0.5 ;

	vec4 mixed_color = mix(color1, color2, i_pattern) ;

	i_basecolor.rgb = clamp( i_basecolor.rgb * ( mix( mixed_color.rgb, averaged.rgb, pattern_opacity) ), 0.0, 1.0 );

	ALBEDO = i_basecolor.rgb ;
	NORMAL = i_normal.rgb ;
	ROUGHNESS = i_roughness.r ;

	ALPHA = 1.0 ;
}

