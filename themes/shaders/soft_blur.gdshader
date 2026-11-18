// Resmi yumuşakça bulanıklaştırır: her pikselde çevresindeki 3×3 noktanın ağırlıklı ortalaması.
// Örnek sayısı az tutulduğu için tam ekran resimde de ucuzdur; hafif bulanıklık için uygundur.
shader_type canvas_item;

// Örnekler arası uzaklık (resmin kendi pikseli cinsinden).
uniform float blur_radius = 2.0;

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * blur_radius;
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			// Merkez 4, kenar komşuları 2, köşeler 1 ağırlık alır (Gauss'a yakın).
			float weight = float((2 - abs(x)) * (2 - abs(y)));
			sum += texture(TEXTURE, UV + vec2(float(x), float(y)) * step_uv) * weight;
			total += weight;
		}
	}
	COLOR = sum / total;
}
