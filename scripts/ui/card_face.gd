class_name CardFace
extends Control
## Tek bir kartın görünümü: kapalıysa arka yüz, açıksa yazısı ya da sembolü.
## Uçan kartlarda ve yığınlarda kullanılır; renkler arayüz temasındaki stillerden gelir.

## Kartın yüksekliğinin genişliğine oranı.
const ASPECT := 1.4
const FACE_STYLE := &"CardFace"
const BACK_STYLE := &"CardBack"
const STYLE_NAME := &"panel"
const LABEL_VARIATION := &"CardLabel"
const LABEL_MARGIN := 6.0
## Bot kartının köşesindeki renkli rozet: kart genişliğine oranla yarıçapı ve
## köşeden içeri kayması (yarıçap oranı), kenar çizgisi.
const BADGE_RATIO := 0.12
const BADGE_INSET := 0.6
const BADGE_LINE := 2.0
const BADGE_POINTS := 24

var _label := Label.new()
var _symbol := CardSymbol.new()
var _badge := Color.TRANSPARENT
var _face_up := false


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_label.theme_type_variation = LABEL_VARIATION
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(PRESET_FULL_RECT)
	_label.offset_left = LABEL_MARGIN
	_label.offset_top = LABEL_MARGIN
	_label.offset_right = -LABEL_MARGIN
	_label.offset_bottom = -LABEL_MARGIN
	_label.hide()
	add_child(_label)
	add_child(_symbol)


## Kartın elde ve uçarken görünen yazısı; açıklaması olmayan kartta (ör. +5) yalnızca etiket.
static func text_for(card: Card, exit_value: int) -> String:
	var description := card.description(exit_value)
	return card.label() if description.is_empty() else card.label() + "\n" + description


## Kartı açar: sembolü olan kartta sembol, diğerlerinde yazı görünür.
func show_card(card: Card, settings: GameSettings) -> void:
	_face_up = true
	_symbol.show_card(card, settings)
	_label.visible = not _symbol.visible
	_label.text = text_for(card, settings.exit_value)
	queue_redraw()


## Jokerde seçilen sayıyı kartın üst bölümünde gösterir; Card.NO_VALUE verilirse kaldırır.
func show_chosen(value: int) -> void:
	_symbol.show_chosen(value)


## Verilen alana sığan en büyük kart boyu.
static func fit_size(max_width: float, max_height: float) -> Vector2:
	var width := minf(max_width, max_height / ASPECT)
	return Vector2(width, width * ASPECT)


## Kart köşesindeki rozet dairesi: fill renginde, mürekkep renginde kenar çizgili.
static func draw_badge(canvas: Control, center: Vector2, radius: float, fill: Color) -> void:
	var ink := canvas.get_theme_color(CardSymbol.INK_COLOR, CardSymbol.STYLE)
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius, 0.0, TAU, BADGE_POINTS, ink, BADGE_LINE)


## Kartın sağ üst köşesine kartı oynayanın renginde bir taş rozeti koyar.
func set_badge(color: Color) -> void:
	_badge = color
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var style := FACE_STYLE if _face_up else BACK_STYLE
	draw_style_box(get_theme_stylebox(STYLE_NAME, style), rect)
	if _badge.a > 0.0:
		var radius := size.x * BADGE_RATIO
		var center := Vector2(size.x - radius * BADGE_INSET, radius * BADGE_INSET)
		draw_badge(self, center, radius, _badge)
