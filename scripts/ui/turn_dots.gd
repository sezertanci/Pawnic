class_name TurnDots
extends Control
## Oyuncuları sıra düzeninde taşlarıyla gösterir; sırası gelenin ayağının altında, tahtadaki
## gibi dalga yayılır. Dalga oynasın diye taşlar her karede yeniden çizilir. Ağ oyununda bağlantısı
## kopan oyuncunun taşı soluk görünür ve üstünde, koltuğunu bot alana kadar kalan saniye yazar.
## Yazının yazı tipi ve rengi temadaki Label, boyutu SmallLabel türünden gelir.

## Taş yarıçapı (görsel genişliği bunun PAWN_WIDTH_RATIO katıdır) ve taşlar arası boşluk.
const RADIUS := 12.0
const GAP := 8.0
const RING_WIDTH := 3.0
## Bağlantısı kopan oyuncunun taşının saydamlığı.
const AWAY_ALPHA := 0.4
const LABEL_TYPE := &"Label"
const SMALL_LABEL_TYPE := &"SmallLabel"
const OWN_TYPE := &"TurnDots"

var _colors: Array[int] = []
var _current := 0
## Taşların bekleme süreleri (saniye), taşlarla aynı sırada; SeatPresence.PRESENT ise oyuncu bağlı.
var _waits: Array[float] = []


func _ready() -> void:
	Skins.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	if not _colors.is_empty():
		queue_redraw()


## colors sıra düzenindeki oyuncuların renkleri, current sırası gelenin bu listedeki yeri.
func show_turn(colors: Array[int], current: int) -> void:
	_colors = colors.duplicate()
	_current = current
	_waits.clear()
	custom_minimum_size = Vector2(_step() * (_colors.size() - 1) + _pawn_width(), _pawn_height())
	queue_redraw()


## waits, show_turn'daki taşlarla aynı sırada bekleme süreleridir (SeatPresence.PRESENT: bağlı).
func show_waits(waits: Array[float]) -> void:
	_waits = waits.duplicate()


func _step() -> float:
	return _pawn_width() + GAP


func _pawn_width() -> float:
	return RADIUS * BoardPainter.PAWN_WIDTH_RATIO


func _pawn_height() -> float:
	var texture := Skins.current.pawn_textures[0]
	return _pawn_width() * BoardPainter.aspect(texture)


func _draw() -> void:
	var skin := Skins.current
	# Taşlar dikeyde ortalanır; ayak, görselin PAWN_FOOT oranındaki noktasıdır.
	var top := (size.y - _pawn_height()) / 2.0
	var foot_y := top + _pawn_height() * BoardPainter.PAWN_FOOT
	for index: int in range(_colors.size()):
		var foot := Vector2(_pawn_width() / 2.0 + _step() * index, foot_y)
		var wait := _wait_of(index)
		var tint := Color(Color.WHITE, AWAY_ALPHA) if wait != SeatPresence.PRESENT else Color.WHITE
		if index == _current:
			var ring := _draw_ground_ring.bind(foot)
			BoardPainter.draw_pawn_in_ring(self, foot, RADIUS, _colors[index], ring, tint)
		else:
			BoardPainter.draw_pawn(self, foot, RADIUS, _colors[index], tint)
		if wait > 0.0:
			_draw_seconds(foot, wait)


func _wait_of(index: int) -> float:
	return _waits[index] if index < _waits.size() else SeatPresence.PRESENT


## Kalan saniye, taşın görselinin ortasına yazılır.
func _draw_seconds(foot: Vector2, wait: float) -> void:
	var font := get_theme_font(&"font", LABEL_TYPE)
	var font_size := get_theme_font_size(&"font_size", SMALL_LABEL_TYPE)
	var text := str(ceili(wait))
	var rect := BoardPainter.pawn_rect(foot, RADIUS, Skins.current.pawn_textures[0])
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := (
		rect.get_center() + Vector2(-text_size.x / 2.0, font.get_ascent(font_size) / 2.0)
	)
	var outline := get_theme_constant(&"outline_size", OWN_TYPE)
	var outline_color := Skins.current.outline_color
	draw_string_outline(
		font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, outline_color
	)
	var color := get_theme_color(&"font_color", LABEL_TYPE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Sırası gelenin ayağının altında, taşın tabanını saran yatık (elips) dalga.
func _draw_ground_ring(arc: Vector2, foot: Vector2) -> void:
	var skin := Skins.current
	var radius := _pawn_width() / 2.0 + RING_WIDTH
	draw_set_transform(foot, 0.0, Vector2(1.0, PulseWave.RING_FLATTEN))
	PulseWave.draw_ring(
		self, Vector2.ZERO, radius, skin.highlight_color, skin.outline_color, RING_WIDTH, arc
	)
	draw_set_transform_matrix(Transform2D.IDENTITY)
