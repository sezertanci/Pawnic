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


func test_resize_shrinks_from_given_scale_to_own_size() -> void:
	_animation.add_resize(2, 1.0, 1.0, 2.0)

	assert_eq(_animation.scale_at(2, 0.5), 2.0)
	assert_almost_eq(_animation.scale_at(2, 1.5), 1.5, 0.01)
	assert_eq(_animation.scale_at(2, 3.0), 1.0)
	assert_true(_animation.has(2))
	assert_false(_animation.has(3))


func test_trail_follows_path_corners_up_to_max_length() -> void:
	_animation.add_segment(0, Vector2.ZERO, Vector2(10, 0), 0.0, 1.0, 0.0)
	_animation.add_segment(0, Vector2(10, 0), Vector2(10, 10), 1.0, 1.0, 0.0)
	_animation.add_trail(0, 0.0, 2.0)

	var points := _animation.trail_points(0, 1.5, 8.0, 1.0)

	assert_eq(points, [Vector2(10, 5), Vector2(10, 0), Vector2(7, 0)] as Array[Vector2])


func test_trail_shrinks_after_slide_ends() -> void:
	_animation.add_segment(0, Vector2.ZERO, Vector2(10, 0), 0.0, 1.0, 0.0)
	_animation.add_trail(0, 0.0, 1.0)

	assert_eq(
		_animation.trail_points(0, 1.5, 8.0, 1.0), [Vector2(10, 0), Vector2(6, 0)] as Array[Vector2]
	)
	assert_true(_animation.trail_points(0, 2.0, 8.0, 1.0).is_empty())
