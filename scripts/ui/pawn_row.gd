class_name PawnRow
extends Control
## Logonun altında her oyuncu renginden birer taşın yan yana durduğu süs satırı.

## Taş yarıçapı, satır yüksekliğine oranla.
const PAWN_RATIO := 0.4
## Taş merkezleri arasındaki uzaklık, yarıçapa oranla.
const SPACING_RATIO := 2.6


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var colors := Skins.current.seat_colors
	var radius := size.y * PAWN_RATIO
	var spacing := radius * SPACING_RATIO
	var first := size.x / 2.0 - spacing * (colors.size() - 1) / 2.0
	for index: int in range(colors.size()):
		var center := Vector2(first + spacing * index, size.y / 2.0)
		BoardPainter.draw_pawn(self, center, radius, colors[index])
