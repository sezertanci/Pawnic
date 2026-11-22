class_name SkinCard
extends Button
## Görünüm ekranında bir temanın kartı: tahta görselini kartın genişliğine sığdırarak gösterir,
## seçiliyse sağ üst köşesine tik, kilitliyse sol üst köşesine kilit simgesi çizer. Kartın
## yüksekliği görselin en-boy oranından bulunur. Seçili kartın çerçevesi ve simge renkleri arayüz
## temasındaki SkinCard türünden gelir.

const THEME_TYPE := &"SkinCard"
const STYLE := &"normal"
const BADGE_COLOR := &"badge_color"
const BADGE_MARK_COLOR := &"badge_mark_color"
## Simge yuvarlağının yarıçapı ve merkezinin köşeye uzaklığı (kart genişliğine oranla).
const BADGE_RADIUS := 0.07
const BADGE_INSET := 0.1
## Tik işaretinin kalınlığı ve köşeleri (yarıçapa oranla, merkez sıfırda).
const TICK_LINE := 0.24
const TICK_POINTS: Array[Vector2] = [
	Vector2(-0.45, 0.02), Vector2(-0.12, 0.36), Vector2(0.45, -0.3)
]
## Kilidin halkası (yarıçapı, yayın merkezinin yüksekliği, bacaklarının bittiği yükseklik ve
## kalınlığı) ve gövdesi (dikdörtgeni ve köşe yuvarlaklığı); yarıçapa oranla, merkez sıfırda.
const SHACKLE_RADIUS := 0.35
const SHACKLE_TOP := -0.31
const SHACKLE_BOTTOM := -0.08
const SHACKLE_LINE := 0.19
const SHACKLE_POINTS := 24
const LOCK_BODY := Rect2(-0.5, -0.12, 1.0, 0.77)
const LOCK_CORNER := 0.15

var preview: Texture2D
var locked := false:
	set(value):
		locked = value
		queue_redraw()


func _init() -> void:
	theme_type_variation = THEME_TYPE
	toggle_mode = true
	size_flags_horizontal = SIZE_EXPAND_FILL
	resized.connect(_fit_height)


func _draw() -> void:
	if preview != null:
		draw_texture_rect(preview, _content_rect(), false)
	if button_pressed:
		_draw_tick(_draw_badge(size.x - size.x * BADGE_INSET))
	if locked:
		_draw_lock(_draw_badge(size.x * BADGE_INSET))


## Yükseklik, görsel kartın iç genişliğine sığacak boydadır.
func _fit_height() -> void:
	if preview == null:
		return
	var style := get_theme_stylebox(STYLE)
	var width := size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
	var margins := style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM)
	custom_minimum_size.y = width * BoardPainter.aspect(preview) + margins


func _content_rect() -> Rect2:
	var style := get_theme_stylebox(STYLE)
	var origin := Vector2(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP))
	return Rect2(
		origin, size - origin - Vector2(style.get_margin(SIDE_RIGHT), style.get_margin(SIDE_BOTTOM))
	)


## Üst kenara yakın, x'te ortalanmış simge yuvarlağını çizer ve merkezini döndürür.
func _draw_badge(x: float) -> Vector2:
	var center := Vector2(x, size.x * BADGE_INSET)
	draw_circle(center, _badge_radius(), get_theme_color(BADGE_COLOR), true, -1.0, true)
	return center


func _badge_radius() -> float:
	return size.x * BADGE_RADIUS


func _draw_tick(center: Vector2) -> void:
	var radius := _badge_radius()
	var color := get_theme_color(BADGE_MARK_COLOR)
	var width := radius * TICK_LINE
	for index: int in range(TICK_POINTS.size() - 1):
		var from := center + TICK_POINTS[index] * radius
		var to := center + TICK_POINTS[index + 1] * radius
		BackArrow.draw_round_line(self, from, to, color, width)


func _draw_lock(center: Vector2) -> void:
	var radius := _badge_radius()
	var color := get_theme_color(BADGE_MARK_COLOR)
	var width := radius * SHACKLE_LINE
	var arc_center := center + Vector2(0.0, SHACKLE_TOP * radius)
	var reach := SHACKLE_RADIUS * radius
	draw_arc(arc_center, reach, PI, TAU, SHACKLE_POINTS, color, width, true)
	for side: float in [-1.0, 1.0]:
		var top := arc_center + Vector2(side * reach, 0.0)
		var bottom := center + Vector2(side * reach, SHACKLE_BOTTOM * radius)
		BackArrow.draw_round_line(self, top, bottom, color, width)
	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.set_corner_radius_all(roundi(LOCK_CORNER * radius))
	body.anti_aliasing = true
	var rect := Rect2(center + LOCK_BODY.position * radius, LOCK_BODY.size * radius)
	draw_style_box(body, rect)
