// Buzlu cam: arkasındaki görüntüyü bulanıklaştırır, verilen renge boyar ve köşeleri yuvarlar.
// Kenarda ince, açık bir çizgi camın sınırını belli eder.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.45);
// Bulanıklığın yarıçapı (piksel) ve her yönde alınan örnek sayısı.
uniform float blur_radius = 14.0;
uniform int blur_steps = 5;
// Dikdörtgenin piksel boyu (betik verir), köşe yarıçapı ve kenar çizgisi.
uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float corner_radius = 36.0;
uniform float edge_width = 2.0;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);

float rounded_distance(vec2 point, vec2 half_size, float radius) {
	vec2 corner = abs(point) - half_size + radius;
	return length(max(corner, 0.0)) + min(max(corner.x, corner.y), 0.0) - radius;
}

void fragment() {
	vec2 step_uv = SCREEN_PIXEL_SIZE * blur_radius / float(blur_steps);
	vec3 sum = vec3(0.0);
	float count = 0.0;
	for (int x = -blur_steps; x <= blur_steps; x++) {
		for (int y = -blur_steps; y <= blur_steps; y++) {
			sum += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * step_uv).rgb;
			count += 1.0;
		}
	}
	vec3 blurred = mix(sum / count, tint.rgb, tint.a);
	float dist = rounded_distance(UV * rect_size - rect_size / 2.0, rect_size / 2.0, corner_radius);
	float inside = clamp(0.5 - dist, 0.0, 1.0);
	float edge = clamp(1.0 - abs(dist + edge_width / 2.0) / (edge_width / 2.0), 0.0, 1.0);
	COLOR = vec4(mix(blurred, edge_color.rgb, edge * edge_color.a), inside);
}
