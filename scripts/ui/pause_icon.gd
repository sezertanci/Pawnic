class_name PauseIcon
extends Control
## Düğmenin üstüne çizilen, uçları yuvarlak iki dikey çubuktan oluşan duraklatma simgesi.
## Yazı tipine bağlı kalmasın diye glif yerine çizilir. Rengi düğmenin yazı renginden gelir;
## simge, düğmenin kabarık alt kenarı dışında kalan yüzün ortasında durur, basınca yüzle iner.

## Çubuğun yarı boyu, yüzün kısa kenarına oranla.
const BAR_HALF := 0.22
## Çubukların merkezden uzaklığı, yüzün kısa kenarına oranla.
const BAR_OFFSET := 0.12
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
	var half := Vector2.DOWN * side * BAR_HALF
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT]:
		var middle := center + direction * side * BAR_OFFSET
		var bar := PackedVector2Array([middle - half, middle + half])
		SmoothDraw.stroke(self, bar, color, side * LINE_RATIO)
