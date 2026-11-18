class_name GearIcon
extends Control
## Ayar düğmesinin üstüne çizilen dişli çark. Rengi düğmenin yazı renginden gelir, ortasındaki
## delik düğmenin o anki zemin rengiyle boyanır; geri oku gibi düğmenin yüzüyle birlikte iner.

const TEETH := 8
## Dişlerin dış ve iç yarıçapı, ortadaki deliğin yarıçapı (yüzün kısa kenarına oranla).
const OUTER_RATIO := 0.3
const INNER_RATIO := 0.23
const HOLE_RATIO := 0.1
## Bir dişin, diş aralığına oranla dış kenarda kapladığı pay ve dibinde ne kadar genişlediği.
const TOOTH_WIDTH := 0.45
const TOOTH_FLARE := 1.4

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
	draw_colored_polygon(_gear_points(center, side), color)
	var style := ButtonFace.style(_button)
	if style != null:
		draw_circle(center, side * HOLE_RATIO, style.bg_color)


## Dişlerin köşeleri: her diş iç çemberden çıkıp dış çemberde düz bir uçla biter.
func _gear_points(center: Vector2, side: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var step := TAU / TEETH
	var half_tooth := step * TOOTH_WIDTH / 2.0
	var inner := side * INNER_RATIO
	var outer := side * OUTER_RATIO
	for index: int in TEETH:
		var angle := index * step
		points.append(center + Vector2.from_angle(angle - half_tooth * TOOTH_FLARE) * inner)
		points.append(center + Vector2.from_angle(angle - half_tooth) * outer)
		points.append(center + Vector2.from_angle(angle + half_tooth) * outer)
		points.append(center + Vector2.from_angle(angle + half_tooth * TOOTH_FLARE) * inner)
	return points
