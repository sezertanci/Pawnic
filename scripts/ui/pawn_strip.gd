class_name PawnStrip
extends Control
## Verilen koltukların taş görsellerini sağa yaslı, iki sıra halinde zikzak dizer: sırayla
## bir taş önde, bir taş arkada. Arka sıradaki taş, öndeki iki taşın arasına düştüğü için
## görünür kalır. Arka sıra yukarıda ve önce çizilir. Taşlar şeride sığmazsa küçülür.

const ROWS := 2
## Taşın sırası, dizideki yerinin ROWS ile bölümünden kalandır; arka sıra önce çizilir.
const FRONT_ROW := 0
const BACK_ROW := 1
## Taş yarıçapı, şerit yüksekliğine oranla.
const RADIUS_RATIO := 0.2
## Aynı sıradaki iki taş arasındaki boşluk, yarıçapa oranla.
const GAP_RATIO := 0.2
## Arka ve ön sıranın bastığı çizgi, şerit yüksekliğine oranla.
const BACK_FOOT_Y := 0.52
const FRONT_FOOT_Y := 0.85

var _seats: Array[int] = []


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func show_seats(seats: Array[int]) -> void:
	_seats = seats
	queue_redraw()


func _draw() -> void:
	if _seats.is_empty():
		return
	var slot_ratio := BoardPainter.PAWN_WIDTH_RATIO + GAP_RATIO
	# Zikzakta komşu taşlar yarım aralıkla dizilir; dizi (n-1) yarım aralık + bir taş genişliğidir.
	var span_ratio := (_seats.size() - 1) * slot_ratio / ROWS + slot_ratio
	var radius := minf(size.y * RADIUS_RATIO, size.x / span_ratio)
	var step := radius * slot_ratio / ROWS
	var left := size.x - radius * span_ratio + radius * slot_ratio / 2.0
	for row: int in [BACK_ROW, FRONT_ROW]:
		var foot_y := size.y * (BACK_FOOT_Y if row == BACK_ROW else FRONT_FOOT_Y)
		for index: int in range(row, _seats.size(), ROWS):
			var center := Vector2(left + step * index, foot_y)
			BoardPainter.draw_pawn(self, center, radius, _seats[index])
