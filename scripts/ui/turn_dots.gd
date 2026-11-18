class_name TurnDots
extends Control
## Oyuncuları sıra düzeninde piyonlarıyla gösterir; sırası gelenin ayağının altında, tahtadaki
## gibi dalga yayılır. Dalga oynasın diye piyonlar her karede yeniden çizilir.

## Piyon yarıçapı (görsel genişliği bunun PAWN_WIDTH_RATIO katıdır) ve piyonlar arası boşluk.
const RADIUS := 12.0
const GAP := 8.0
const RING_WIDTH := 3.0

var _seats: Array[int] = []
var _current := 0


func _ready() -> void:
	Skins.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	if not _seats.is_empty():
		queue_redraw()


## seats sıra düzenindeki koltuklar, current sırası gelenin bu listedeki yeri.
func show_turn(seats: Array[int], current: int) -> void:
	_seats = seats.duplicate()
	_current = current
	custom_minimum_size = Vector2(_step() * (_seats.size() - 1) + _pawn_width(), _pawn_height())
	queue_redraw()


func _step() -> float:
	return _pawn_width() + GAP


func _pawn_width() -> float:
	return RADIUS * BoardPainter.PAWN_WIDTH_RATIO


func _pawn_height() -> float:
	var texture := Skins.current.pawn_textures[0]
	return _pawn_width() * texture.get_height() / texture.get_width()


func _draw() -> void:
	var skin := Skins.current
	# Piyonlar dikeyde ortalanır; ayak, görselin PAWN_FOOT oranındaki noktasıdır.
	var top := (size.y - _pawn_height()) / 2.0
	var foot_y := top + _pawn_height() * BoardPainter.PAWN_FOOT
	for index: int in range(_seats.size()):
		var foot := Vector2(_pawn_width() / 2.0 + _step() * index, foot_y)
		# Halkanın arka yarısı piyonun arkasında, ön yarısı önünde kalsın diye iki parça çizilir.
		if index == _current:
			_draw_ground_ring(foot, PulseWave.BACK_ARC)
		BoardPainter.draw_pawn(self, foot, RADIUS, _seats[index])
		if index == _current:
			_draw_ground_ring(foot, PulseWave.FRONT_ARC)


## Sırası gelenin ayağının altında, piyonun tabanını saran yatık (elips) dalga.
func _draw_ground_ring(foot: Vector2, arc: Vector2) -> void:
	var skin := Skins.current
	var radius := _pawn_width() / 2.0 + RING_WIDTH
	draw_set_transform(foot, 0.0, Vector2(1.0, PulseWave.RING_FLATTEN))
	PulseWave.draw_ring(
		self, Vector2.ZERO, radius, skin.highlight_color, skin.outline_color, RING_WIDTH, arc
	)
	draw_set_transform(Vector2.ZERO)
