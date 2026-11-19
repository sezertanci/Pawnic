class_name PawnIcon
extends Control
## Bir rengin taşını, görseli alanın yüksekliğini tam dolduracak boyda ve yatayda ortalı çizer.
## Kazanma ekranındaki büyük taş ve sonuç tablosundaki küçük taşlar bunu kullanır.

## Taşın rengi (kaplamadaki renk sırası).
var color := 0:
	set(value):
		color = value
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	Skins.changed.connect(queue_redraw)


func _draw() -> void:
	var texture := Skins.current.pawn_textures[color]
	var width := size.y / BoardPainter.aspect(texture)
	var radius := width / BoardPainter.PAWN_WIDTH_RATIO
	var foot := Vector2(size.x / 2.0, size.y * BoardPainter.PAWN_FOOT)
	BoardPainter.draw_pawn(self, foot, radius, color)
