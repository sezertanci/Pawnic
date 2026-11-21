class_name BackArrow
extends Control
## Düğmenin üstüne çizilen, uçları yuvarlak, sola dönük kalın geri oku.
## Yazı tipine bağlı kalmasın diye glif yerine çizilir. Rengi düğmenin yazı renginden gelir;
## ok, düğmenin kabarık alt kenarı dışında kalan yüzün ortasında durur, basınca yüzle iner.

const ARROW_HALF := 0.26
const HEAD_RATIO := 0.2
const LINE_RATIO := 0.1

var _button: Button


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _ready() -> void:
	_button = get_parent() as Button
	_button.button_down.connect(queue_redraw)
	_button.button_up.connect(queue_redraw)


func _draw() -> void:
	var face := ButtonFace.rect(_button)
	var side := minf(face.size.x, face.size.y)
	var center := face.get_center()
	var tip := center + Vector2.LEFT * side * ARROW_HALF
	var tail := center + Vector2.RIGHT * side * ARROW_HALF
	var head := side * HEAD_RATIO
	var color := _button.get_theme_color(ThemeKeys.FONT_COLOR)
	var width := side * LINE_RATIO
	draw_round_line(self, tail, tip, color, width)
	draw_round_line(self, tip, tip + Vector2(head, -head), color, width)
	draw_round_line(self, tip, tip + Vector2(head, head), color, width)


## Uçları yuvarlak kalın çizgi (grup başlığındaki ok da kullanır).
static func draw_round_line(
	canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float
) -> void:
	canvas.draw_line(from, to, color, width, true)
	canvas.draw_circle(from, width / 2.0, color)
	canvas.draw_circle(to, width / 2.0, color)
