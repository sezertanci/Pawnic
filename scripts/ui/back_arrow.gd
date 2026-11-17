class_name BackArrow
extends Control
## Düğmenin üstüne çizilen sola dönük geri oku; rengi düğmenin yazı renginden gelir.
## Yazı tipine bağlı kalmasın diye glif yerine çizilir.

const ARROW_HALF := 0.3
const HEAD_RATIO := 0.18
const LINE_RATIO := 0.07
const FONT_COLOR := &"font_color"
const BUTTON_STYLE := &"Button"


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _draw() -> void:
	var side := minf(size.x, size.y)
	var center := size / 2.0
	var tip := center + Vector2.LEFT * side * ARROW_HALF
	var tail := center + Vector2.RIGHT * side * ARROW_HALF
	var color := get_theme_color(FONT_COLOR, BUTTON_STYLE)
	var width := side * LINE_RATIO
	var head := side * HEAD_RATIO
	draw_line(tail, tip, color, width)
	draw_line(tip, tip + Vector2(head, -head), color, width)
	draw_line(tip, tip + Vector2(head, head), color, width)
