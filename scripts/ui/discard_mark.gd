class_name DiscardMark
extends Control
## Oynanabilir kart yokken atılacak kartların sol üst köşesinde görünen işaret:
## kırmızı daire içinde beyaz çarpı. Oyuncu rozetiyle (sağ üst) çakışmaz.

const MARK_COLOR := &"discard_color"
const CROSS_COLOR := &"discard_cross_color"
## Çarpının kollarının daire yarıçapına oranı.
const CROSS_RATIO := 0.45


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _draw() -> void:
	var radius := size.x * CardFace.BADGE_RATIO
	draw_mark(self, Vector2.ONE * radius * CardFace.BADGE_INSET, radius)


## İşareti center merkezli, radius yarıçaplı çizer (kural ekranı da kullanır).
static func draw_mark(canvas: Control, center: Vector2, radius: float) -> void:
	var fill := canvas.get_theme_color(MARK_COLOR, CardSymbol.STYLE)
	CardFace.draw_badge(canvas, center, radius, fill)
	var arm := radius * CROSS_RATIO
	var cross := canvas.get_theme_color(CROSS_COLOR, CardSymbol.STYLE)
	var line := CardFace.BADGE_LINE
	canvas.draw_line(center - Vector2(arm, arm), center + Vector2(arm, arm), cross, line)
	canvas.draw_line(center + Vector2(-arm, arm), center + Vector2(arm, -arm), cross, line)
