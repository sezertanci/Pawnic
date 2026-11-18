class_name Confetti
extends Control
## Ekranın üstünden dökülen konfeti: renkli küçük şeritler dönerek ve sağa sola salınarak
## düşer, alttan çıkınca kaybolur. Fizik motoru kullanılmaz; konum her karede hesaplanır.
## Sayı ve hızlar data/tuning.json dosyasından okunur.

## Parçaların boyu (piksel).
const PIECE_SIZE := Vector2(14.0, 8.0)
## Parçalar ekranın üstünde, ekran boyuna oranla bu yüksekliğe kadar dağılmış başlar.
const START_SPREAD := 0.8

var _pieces: Array[ConfettiPiece] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)


## Verilen renklerden parçalar üretip dökmeye başlar.
func burst(colors: Array[Color]) -> void:
	_rng.randomize()
	_pieces.clear()
	for _index: int in range(Tuning.settings.confetti_count):
		_pieces.append(_new_piece(colors))
	set_process(true)


func stop() -> void:
	_pieces.clear()
	set_process(false)
	queue_redraw()


func _new_piece(colors: Array[Color]) -> ConfettiPiece:
	var settings := Tuning.settings
	var piece := ConfettiPiece.new()
	piece.color = colors[_rng.randi_range(0, colors.size() - 1)]
	piece.origin_x = _rng.randf_range(0.0, size.x)
	piece.y = -_rng.randf_range(0.0, size.y * START_SPREAD)
	piece.speed = _rng.randf_range(
		settings.confetti_min_fall_speed, settings.confetti_max_fall_speed
	)
	piece.sway_phase = _rng.randf_range(0.0, TAU)
	piece.sway_speed = _rng.randf_range(
		-settings.confetti_max_sway_speed, settings.confetti_max_sway_speed
	)
	piece.angle = _rng.randf_range(0.0, TAU)
	piece.spin = _rng.randf_range(-settings.confetti_max_spin, settings.confetti_max_spin)
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
	var sway := Tuning.settings.confetti_sway
	for piece: ConfettiPiece in _pieces:
		var center := Vector2(piece.origin_x + sin(piece.sway_phase) * sway, piece.y)
		draw_set_transform(center, piece.angle)
		draw_rect(Rect2(-PIECE_SIZE / 2.0, PIECE_SIZE), piece.color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
