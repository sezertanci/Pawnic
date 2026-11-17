class_name BackArrow
extends Control
## Düğmenin üstüne çizilen, uçları yuvarlak, sola dönük kalın geri oku.
## Yazı tipine bağlı kalmasın diye glif yerine çizilir. Rengi düğmenin yazı renginden gelir;
## ok, düğmenin kabarık alt kenarı dışında kalan yüzün ortasında durur, basınca yüzle iner.

const ARROW_HALF := 0.26
const HEAD_RATIO := 0.2
const LINE_RATIO := 0.1
const FONT_COLOR := &"font_color"
const NORMAL_STYLE := &"normal"
const PRESSED_STYLE := &"pressed"

var _button: Button


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _ready() -> void:
	_button = get_parent() as Button
	_button.button_down.connect(queue_redraw)
	_button.button_up.connect(queue_redraw)


func _draw() -> void:
	var face := _face_rect()
	var side := minf(face.size.x, face.size.y)
	var center := face.get_center()
	var tip := center + Vector2.LEFT * side * ARROW_HALF
	var tail := center + Vector2.RIGHT * side * ARROW_HALF
	var head := side * HEAD_RATIO
	var color := _button.get_theme_color(FONT_COLOR)
	var width := side * LINE_RATIO
	_draw_round_line(tail, tip, color, width)
	_draw_round_line(tip, tip + Vector2(head, -head), color, width)
	_draw_round_line(tip, tip + Vector2(head, head), color, width)


## Düğmenin, alt kenar şeridi çıkarılmış yüzü; basılıyken şerit incelir ve yüz aşağı uzar.
func _face_rect() -> Rect2:
	var mode := _button.get_draw_mode()
	var pressed := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
	var style_name := PRESSED_STYLE if pressed else NORMAL_STYLE
	var style := _button.get_theme_stylebox(style_name) as StyleBoxFlat
	var rect := Rect2(Vector2.ZERO, size)
	if style != null:
		rect.size.y -= style.border_width_bottom
	return rect


func _draw_round_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width, true)
	draw_circle(from, width / 2.0, color)
	draw_circle(to, width / 2.0, color)
