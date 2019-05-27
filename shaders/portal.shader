shader_type spatial;

uniform vec4 center_color: hint_color;
uniform vec4 rim_color: hint_color;
uniform float uv_scale: hint_range(0, 0.3) = 0.024;
uniform vec2 uv_offset;
uniform float ripple_speed: hint_range(1, 40) = 10;
uniform float ripple_scale: hint_range(1, 20) = 2;
uniform float min_roughness: hint_range(-1, 1) = 0.1;
uniform float min_metallic: hint_range(-1, 1) = 0.5;

void fragment() {
	float x = 2.0 * ((UV.x * uv_scale) - 0.5) + uv_offset.x;
	float y = 2.0 * ((UV.y * uv_scale) - 0.5) + uv_offset.y;
	
	float center_distance = sqrt(x * x + y * y) / 2.0;
	float ripple_value = center_distance * ripple_scale - TIME * ripple_speed;
	
	float interpolation = clamp(pow(center_distance, 3), 0, 1);
	ALBEDO = mix(center_color.rgb, rim_color.rgb, interpolation);
	ALPHA = mix(center_color.a, rim_color.a, interpolation);
	NORMAL = normalize(vec3(sin(ripple_value), cos(ripple_value), 1));
	ROUGHNESS = 1.0 - interpolation + min_roughness;
	METALLIC = interpolation + min_metallic;
}