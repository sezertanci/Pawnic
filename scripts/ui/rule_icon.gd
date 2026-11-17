class_name RuleIcon
extends Control
## "Nasıl oynanır" ekranında bir kuralın yanındaki küçük simge: açık renkli yuvarlak bir kutu ve
## içinde kurala özel çizim. Kartlardaki semboller (çıkış, geri yolla, ev, yıldız) ve atma işareti
## yeniden kullanılır; renkler arayüz temasından okunur.

enum Icon { CARDS, EXIT, CAPTURE, BOOST, HOME, DISCARD, WIN }

const STYLE := &"RuleIcon"
const PANEL := &"panel"
const SYMBOL_BY_ICON := {
	Icon.EXIT: CardSymbol.Kind.EXIT,
	Icon.CAPTURE: CardSymbol.Kind.SEND_BACK,
	Icon.HOME: CardSymbol.Kind.SHORTCUT,
	Icon.WIN: CardSymbol.Kind.STAR,
}
## Kart çifti: kartın genişliği (kutuya oranla), iki kartın merkezleri ve eğimleri.
const MINI_CARD_WIDTH := 0.34
const MINI_CARD_CENTERS: Array[Vector2] = [Vector2(0.38, 0.5), Vector2(0.62, 0.5)]
const MINI_CARD_ANGLES: Array[float] = [-0.25, 0.2]
const MINI_CARD_STYLES: Array[StringName] = [CardFace.BACK_STYLE, CardFace.FACE_STYLE]
## Küçük kartlarda büyük kartın köşe ve kenar ölçüleri bu oranda küçültülür.
const MINI_CARD_SCALE := 0.35
## Kutunun dört köşesi ve dört kenarı (Corner ve Side sabitleri 0–3).
const EDGE_COUNT := 4
## Hız karesi simgesi: yazının boyu ve taban çizgisi (kutuya oranla).
const BOOST_TEXT := "+3"
const BOOST_FONT_RATIO := 0.42
const BOOST_BASELINE := 0.64
## Atma işaretinin yarıçapı (kutuya oranla).
const DISCARD_RADIUS := 0.3

var _icon := Icon.CARDS
var _symbol := CardSymbol.new()
var _mini_cards: Array[StyleBox] = []


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_symbol)


func show_icon(icon: Icon) -> void:
	_icon = icon
	_symbol.show_symbol(SYMBOL_BY_ICON.get(icon, CardSymbol.Kind.NONE))
	queue_redraw()


func _draw() -> void:
	draw_style_box(get_theme_stylebox(PANEL, STYLE), Rect2(Vector2.ZERO, size))
	match _icon:
		Icon.CARDS:
			_draw_cards()
		Icon.BOOST:
			_draw_boost()
		Icon.DISCARD:
			DiscardMark.draw_mark(self, size / 2.0, size.x * DISCARD_RADIUS)


## Biri kapalı biri açık, birbirine yaslanmış iki küçük kart.
func _draw_cards() -> void:
	if _mini_cards.is_empty():
		_mini_cards = _shrink_card_styles()
	var card_size := Vector2(1.0, CardFace.ASPECT) * size.x * MINI_CARD_WIDTH
	for index: int in range(MINI_CARD_CENTERS.size()):
		draw_set_transform(MINI_CARD_CENTERS[index] * size, MINI_CARD_ANGLES[index])
		draw_style_box(_mini_cards[index], Rect2(-card_size / 2.0, card_size))
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Kart stillerinin kopyaları; köşe ve kenarlar küçük karta göre inceltilir, gölge kaldırılır.
func _shrink_card_styles() -> Array[StyleBox]:
	var styles: Array[StyleBox] = []
	for style_type: StringName in MINI_CARD_STYLES:
		var style := get_theme_stylebox(CardFace.STYLE_NAME, style_type).duplicate() as StyleBoxFlat
		style.shadow_size = 0
		for corner: int in range(EDGE_COUNT):
			var radius := style.get_corner_radius(corner)
			style.set_corner_radius(corner, roundi(radius * MINI_CARD_SCALE))
		for side: int in range(EDGE_COUNT):
			var width := style.get_border_width(side)
			style.set_border_width(side, roundi(width * MINI_CARD_SCALE))
		styles.append(style)
	return styles


func _draw_boost() -> void:
	var font := get_theme_font(CardSymbol.FONT_NAME, CardSymbol.LABEL_STYLE)
	var ink := get_theme_color(CardSymbol.INK_COLOR, CardSymbol.STYLE)
	var font_size := roundi(size.x * BOOST_FONT_RATIO)
	var baseline := Vector2(0.0, size.y * BOOST_BASELINE)
	draw_string(font, baseline, BOOST_TEXT, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, ink)
