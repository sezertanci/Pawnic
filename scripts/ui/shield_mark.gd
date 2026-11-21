class_name ShieldMark
extends RefCounted
## Kalkanlı karenin sembolü. Tahta ve "Nasıl oynanır" ekranı aynı çizimi kullanır; renkler
## seçili temadan (Skins) okunur.

## Kalkanın köşeleri (yarıçapa oranla, merkez sıfırda).
const POINTS: Array[Vector2] = [
	Vector2(-0.8, -0.8),
	Vector2(0.0, -1.0),
	Vector2(0.8, -0.8),
	Vector2(0.75, 0.15),
	Vector2(0.4, 0.65),
	Vector2(0.0, 1.0),
	Vector2(-0.4, 0.65),
	Vector2(-0.75, 0.15),
]


## Kalkanı center merkezli, radius yarıçaplı çizer.
static func draw_mark(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in POINTS:
		points.append(center + point * radius)
	var skin := Skins.current
	SmoothDraw.outlined(
		canvas, points, skin.shield_color, skin.outline_color, BoardPainter.LINE_WIDTH
	)
