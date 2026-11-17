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
	var center := Vector2.ONE * radius * CardFace.BADGE_INSET
	var ink := get_theme_color(CardSymbol.INK_COLOR, CardSymbol.STYLE)
	draw_circle(center, radius, get_theme_color(MARK_COLOR, CardSymbol.STYLE))
	draw_arc(center, radius, 0.0, TAU, CardFace.BADGE_POINTS, ink, CardFace.BADGE_LINE)
	var arm := radius * CROSS_RATIO
	var cross := get_theme_color(CROSS_COLOR, CardSymbol.STYLE)
	draw_line(center - Vector2(arm, arm), center + Vector2(arm, arm), cross, CardFace.BADGE_LINE)
	draw_line(center + Vector2(-arm, arm), center + Vector2(arm, -arm), cross, CardFace.BADGE_LINE)
