class_name Confetti
extends Control
## Ekranın üstünden dökülen konfeti: renkli küçük şeritler dönerek ve sağa sola salınarak
## düşer, alttan çıkınca kaybolur. Fizik motoru kullanılmaz; konum her karede hesaplanır.

const PIECE_COUNT := 90
## Parçaların boyu (piksel).
const PIECE_SIZE := Vector2(14.0, 8.0)
## Düşüş hızı aralığı (piksel/saniye).
const MIN_FALL_SPEED := 220.0
const MAX_FALL_SPEED := 420.0
## Parçalar ekranın üstünde, ekran boyuna oranla bu yüksekliğe kadar dağılmış başlar.
const START_SPREAD := 0.8
## Sağa sola salınma genişliği (piksel) ve hızı (radyan/saniye).
const SWAY := 30.0
const MAX_SWAY_SPEED := 4.0
## Dönme hızı sınırı (radyan/saniye).
const MAX_SPIN := 8.0

var _pieces: Array[ConfettiPiece] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)


## Verilen renklerden parçalar üretip dökmeye başlar.
func burst(colors: Array[Color]) -> void:
	_rng.randomize()
	_pieces.clear()
	for _index: int in range(PIECE_COUNT):
		_pieces.append(_new_piece(colors))
	set_process(true)


func stop() -> void:
	_pieces.clear()
	set_process(false)
	queue_redraw()


func _new_piece(colors: Array[Color]) -> ConfettiPiece:
	var piece := ConfettiPiece.new()
	piece.color = colors[_rng.randi_range(0, colors.size() - 1)]
	piece.origin_x = _rng.randf_range(0.0, size.x)
	piece.y = -_rng.randf_range(0.0, size.y * START_SPREAD)
	piece.speed = _rng.randf_range(MIN_FALL_SPEED, MAX_FALL_SPEED)
	piece.sway_phase = _rng.randf_range(0.0, TAU)
	piece.sway_speed = _rng.randf_range(-MAX_SWAY_SPEED, MAX_SWAY_SPEED)
	piece.angle = _rng.randf_range(0.0, TAU)
	piece.spin = _rng.randf_range(-MAX_SPIN, MAX_SPIN)
	return piece


func _process(delta: float) -> void:
	var falling := false
	for piece: ConfettiPiece in _pieces:
		piece.y += piece.speed * delta
		piece.sway_phase += piece.sway_speed * delta
		piece.angle += piece.spin * delta
		falling = falling or piece.y < size.y + PIECE_SIZE.x
	if not falling:
		stop()
	queue_redraw()


func _draw() -> void:
	for piece: ConfettiPiece in _pieces:
		var center := Vector2(piece.origin_x + sin(piece.sway_phase) * SWAY, piece.y)
		draw_set_transform(center, piece.angle)
		draw_rect(Rect2(-PIECE_SIZE / 2.0, PIECE_SIZE), piece.color)
	draw_set_transform(Vector2.ZERO)
