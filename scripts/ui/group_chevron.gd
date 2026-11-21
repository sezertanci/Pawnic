class_name GroupChevron
extends Control
## Açılır grup başlığının sağ kenarına çizilen ok: grup kapalıyken aşağı, açıkken yukarı bakar.
## Rengi düğmenin yazı renginden gelir; ok, düğmenin kabarık alt kenarı dışında kalan yüzün
## dikey ortasında durur ve basınca yüzle iner.

## Okun yarı genişliği ve çizgi kalınlığı (yüz yüksekliğine oranla), sağ kenardan uzaklığı.
const HALF_WIDTH := 0.16
const LINE_RATIO := 0.07
const RIGHT_INSET := 0.5

var open := false:
	set(value):
		open = value
		queue_redraw()

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
	var side := face.size.y
	var half := side * HALF_WIDTH
	var center := Vector2(face.end.x - side * RIGHT_INSET, face.get_center().y)
	# Kapalıyken uç aşağıda, açıkken yukarıda.
	var lift := half / 2.0 if open else -half / 2.0
	var tip := center + Vector2(0.0, -lift)
	var color := _button.get_theme_color(ThemeKeys.FONT_COLOR)
	var width := side * LINE_RATIO
	BackArrow.draw_round_line(self, tip + Vector2(-half, lift * 2.0), tip, color, width)
	BackArrow.draw_round_line(self, tip, tip + Vector2(half, lift * 2.0), color, width)
