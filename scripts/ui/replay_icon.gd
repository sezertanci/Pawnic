class_name ReplayIcon
extends Control
## Yuvarlak turuncu düğmenin üstüne çizilen "yeniden oynat" simgesi: saat yönünde dönen, her
## birinin ucunda dolu üçgen ok başı olan iki yarım yay. Rengi ve ince kenarının rengi düğmenin
## yazı renklerinden gelir; yazı tipine bağlı kalmasın diye glif yerine çizilir.

## Yayların merkezi (düğme boyuna oranla); turuncu yüz, alttaki kabarık kenarın üstünde kalır.
const CENTER_RATIO := Vector2(0.5, 0.41)
## Yay yarıçapı, çizgi kalınlığı ve ok başının yarı genişliği (düğmenin kısa kenarına oranla).
const RADIUS_RATIO := 0.2
const LINE_RATIO := 0.055
const HEAD_RATIO := 0.085
## Yayların başlangıç açıları (üstteki soldan, alttaki sağdan başlar), aralarındaki boşluk ve
## ok başına yer açmak için yayın ucundan kesilen açı (radyan).
const ARC_STARTS: Array[float] = [PI, 0.0]
const GAP_ANGLE := PI / 3.2
const HEAD_TRIM := 0.25
const OUTLINE_WIDTH := 2.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _draw() -> void:
	var button := get_parent() as Button
	_draw_symbol(button.get_theme_color(ThemeKeys.FONT_OUTLINE_COLOR), OUTLINE_WIDTH * 2.0)
	_draw_symbol(button.get_theme_color(ThemeKeys.FONT_COLOR), 0.0)


## İki yayı ve ok başlarını çizer; extra kadar kalın çizilen ilk geçiş kenarı oluşturur.
func _draw_symbol(color: Color, extra: float) -> void:
	var side := minf(size.x, size.y)
	var center := size * CENTER_RATIO
	var radius := side * RADIUS_RATIO
	var width := side * LINE_RATIO + extra
	for arc_start: float in ARC_STARTS:
		var angles := Vector2(
			arc_start + GAP_ANGLE / 2.0, arc_start + PI - GAP_ANGLE / 2.0 - HEAD_TRIM
		)
		var head := CircularArrow.draw(
			self, center, radius, angles, width, side * HEAD_RATIO, color
		)
		if extra > 0.0:
			CircularArrow.draw_rim(self, head, color, extra)
