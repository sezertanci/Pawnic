extends GutTest
## Bitiş yamuğundaki taş dizilimi: ilk iki taş P'ye yakın sırada, kalanlar dış sırada, her sıra
## ortalanır.

## Karşılaştırmada yuvarlama adımı (Vector2 tek duyarlıklıdır).
const PRECISION := 0.001


func test_slot_single_pawn_sits_near_middle() -> void:
	assert_almost_eq(HomeTray.slot(0, 1), Vector2(0.0, HomeTray.NEAR_ROW), Vector2.ONE * PRECISION)


func test_slot_third_pawn_goes_to_far_middle() -> void:
	assert_almost_eq(HomeTray.slot(2, 3), Vector2(0.0, HomeTray.FAR_ROW), Vector2.ONE * PRECISION)


func test_slot_four_pawns_make_two_by_two() -> void:
	var half := HomeTray.SPACING / 2.0
	var row := [snappedf(-half, PRECISION), snappedf(half, PRECISION)]

	assert_eq(_rows(4), [row, row])


func test_slot_six_pawns_put_four_on_far_row() -> void:
	var expected: Array[float] = []
	for step: float in [-1.5, -0.5, 0.5, 1.5]:
		expected.append(snappedf(HomeTray.SPACING * step, PRECISION))

	assert_eq(_rows(6)[1], expected)


## count taşlık evde yakın ve uzak sıradaki taşların ortadan uzaklıkları.
func _rows(count: int) -> Array[Array]:
	var near: Array[float] = []
	var far: Array[float] = []
	for index: int in range(count):
		var slot := HomeTray.slot(index, count)
		var row := near if is_equal_approx(slot.y, HomeTray.NEAR_ROW) else far
		row.append(snappedf(slot.x, PRECISION))
	return [near, far]
