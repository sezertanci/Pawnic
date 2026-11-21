class_name SwapMark
extends Control
## Ödüllü reklamda seçilen teklif kartının ve yerine geçebilecek eldeki kartların sol üst
## köşesinde görünen değiştir (⇄) işareti: sarı daire içinde zıt yönlü iki ok.

const MARK_COLOR := &"star_color"
## İşaretin, karta basılabildiği fark edilsin diye oyuncu rozetinden büyük tutulan yarıçapı
## (kart genişliğine oranı) ve ok çizgisinin kalınlığı (yarıçapa oranı).
const RADIUS_RATIO := 0.2
const LINE_RATIO := 0.14
## Okların yarı uzunluğunun, iki ok arasındaki yarı aralığın ve ok başının daire yarıçapına oranı.
const ARROW_HALF_RATIO := 0.5
const ARROW_GAP_RATIO := 0.25
const HEAD_RATIO := 0.25


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)


func _draw() -> void:
	var radius := size.x * RADIUS_RATIO
	var center := Vector2.ONE * radius * CardFace.BADGE_INSET
	CardFace.draw_badge(self, center, radius, get_theme_color(MARK_COLOR, CardSymbol.STYLE))
	var ink := get_theme_color(CardSymbol.INK_COLOR, CardSymbol.STYLE)
	var half := Vector2(radius * ARROW_HALF_RATIO, 0.0)
	var gap := Vector2(0.0, radius * ARROW_GAP_RATIO)
	_draw_arrow(center - gap - half, center - gap + half, radius, ink)
	_draw_arrow(center + gap + half, center + gap - half, radius, ink)


## from'dan to'ya giden, ucunda iki kısa kanat olan ok çizer; ölçüleri dairenin yarıçapından gelir.
func _draw_arrow(from: Vector2, to: Vector2, radius: float, color: Color) -> void:
	var back := (from - to).normalized() * radius * HEAD_RATIO
	var side := back.orthogonal()
	var width := radius * LINE_RATIO
	BackArrow.draw_round_line(self, from, to, color, width)
	BackArrow.draw_round_line(self, to, to + back + side, color, width)
	BackArrow.draw_round_line(self, to, to + back - side, color, width)
