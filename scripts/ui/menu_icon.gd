class_name MenuIcon
extends Control
## Düğmenin üstüne çizilen, uçları yuvarlak üç yatay çizgiden oluşan menü simgesi.
## Yazı tipine bağlı kalmasın diye glif yerine çizilir. Rengi düğmenin yazı renginden gelir;
## simge, düğmenin kabarık alt kenarı dışında kalan yüzün ortasında durur, basınca yüzle iner.

## Çizginin yarı uzunluğu, yüzün kısa kenarına oranla.
const LINE_HALF := 0.22
## Çizgiler arasındaki dikey uzaklık, yüzün kısa kenarına oranla.
const LINE_GAP := 0.18
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
	var color := _button.get_theme_color(ThemeKeys.FONT_COLOR)
	var half := Vector2.RIGHT * side * LINE_HALF
	for row: int in [-1, 0, 1]:
		var middle := center + Vector2.DOWN * side * LINE_GAP * row
		var line := PackedVector2Array([middle - half, middle + half])
		SmoothDraw.stroke(self, line, color, side * LINE_RATIO)
