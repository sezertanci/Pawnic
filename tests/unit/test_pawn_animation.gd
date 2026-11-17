extends GutTest
## Taş animasyonu zaman çizelgesinin birim testleri.

const HOP := 0.1
const HEIGHT := 10.0

var _animation: PawnAnimation


func before_each() -> void:
	_animation = PawnAnimation.new()


func test_hop_peaks_in_the_middle() -> void:
	_animation.add_segment(0, Vector2.ZERO, Vector2(10, 0), 0.0, HOP, HEIGHT)

	assert_almost_eq(
		_animation.position_at(0, HOP / 2.0, Vector2.ZERO), Vector2(5, 0), Vector2.ONE * 0.01
	)
	assert_almost_eq(_animation.height_at(0, HOP / 2.0), HEIGHT, 0.01)
	assert_almost_eq(_animation.height_at(0, HOP), 0.0, 0.01)


func test_pawn_waits_at_start_before_its_segment() -> void:
	_animation.add_segment(1, Vector2(3, 3), Vector2(9, 9), 0.5, HOP, 0.0)

	assert_eq(_animation.position_at(1, 0.0, Vector2.ZERO), Vector2(3, 3))
	assert_eq(_animation.duration(), 0.5 + HOP)


func test_pawn_stays_on_square_during_pause() -> void:
	_animation.add_segment(0, Vector2.ZERO, Vector2(10, 0), 0.0, HOP, HEIGHT)
	_animation.add_segment(0, Vector2(10, 0), Vector2(20, 0), HOP * 3.0, HOP, HEIGHT)

	assert_eq(_animation.position_at(0, HOP * 2.0, Vector2.ZERO), Vector2(10, 0))
	assert_almost_eq(_animation.height_at(0, HOP * 2.0), 0.0, 0.01)


func test_pulse_grows_then_returns() -> void:
	_animation.add_pulse(2, 0.0, 1.0, 1.5)

	assert_almost_eq(_animation.scale_at(2, 0.5), 1.5, 0.01)
	assert_eq(_animation.scale_at(2, 2.0), 1.0)
	assert_true(_animation.has(2))
	assert_false(_animation.has(3))
