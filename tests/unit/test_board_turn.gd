extends GutTest
## Tahtanın çeyrek turlarla döndürülmesi: istenen koltuğun başlangıç alanı alta gelir, noktalar
## ve alanlar tahtanın ortası çevresinde saat yönünde döner.

const CLASSIC := "res://data/boards/classic.json"
## İki koltuklu, dönünce kendisiyle örtüşmeyen test tahtası.
const BRANCH_BOARD := "res://tests/fixtures/branch_board.json"
## Karşılaştırmada yuvarlama adımı (Vector2 tek duyarlıklıdır).
const PRECISION := 0.001
const SEAT_TOP := 0
const SEAT_RIGHT := 1
const SEAT_BOTTOM := 2
const SEAT_LEFT := 3

var _layout: BoardLayout


func before_each() -> void:
	_layout = BoardLayout.load_from(CLASSIC)


func test_turns_to_bottom_keeps_bottom_seat() -> void:
	assert_eq(BoardTurn.turns_to_bottom(_layout, SEAT_BOTTOM), 0)


func test_turns_to_bottom_turns_other_seats_down() -> void:
	var turns: Array[int] = []
	for seat: int in [SEAT_TOP, SEAT_RIGHT, SEAT_LEFT]:
		turns.append(BoardTurn.turns_to_bottom(_layout, seat))

	assert_eq(turns, [2, 1, 3])


func test_point_puts_chosen_base_below_middle() -> void:
	var size := _layout.grid_size
	var below: Array[bool] = []

	for seat: int in [SEAT_TOP, SEAT_RIGHT, SEAT_BOTTOM, SEAT_LEFT]:
		var turns := BoardTurn.turns_to_bottom(_layout, seat)
		var away := BoardTurn.point(_layout.bases[seat], size, turns) - size / 2.0
		below.append(away.y > absf(away.x))

	assert_eq(below, [true, true, true, true])


func test_point_puts_top_base_where_bottom_base_was() -> void:
	var turns := BoardTurn.turns_to_bottom(_layout, SEAT_TOP)

	var turned := BoardTurn.point(_layout.bases[SEAT_TOP], _layout.grid_size, turns)

	assert_almost_eq(turned, _layout.bases[SEAT_BOTTOM], Vector2.ONE * PRECISION)


func test_point_turns_clockwise() -> void:
	var size := Vector2(4.0, 4.0)

	var turned := BoardTurn.point(Vector2(2.0, 0.0), size, 1)

	assert_almost_eq(turned, Vector2(4.0, 2.0), Vector2.ONE * PRECISION)


func test_point_without_turns_is_unchanged() -> void:
	var cell := Vector2(3.5, 1.25)

	assert_eq(BoardTurn.point(cell, Vector2(15.0, 15.0), 0), cell)


func test_grid_swaps_sides_on_odd_turns() -> void:
	var size := Vector2(10.0, 6.0)

	assert_eq([BoardTurn.grid(size, 1), BoardTurn.grid(size, 2)], [Vector2(6.0, 10.0), size])


func test_rect_keeps_cell_size_and_moves_it() -> void:
	var cell := Rect2(Vector2(0.0, 0.0), Vector2.ONE)

	var turned := BoardTurn.rect(cell, Vector2(4.0, 4.0), 1)

	assert_eq(turned, Rect2(Vector2(3.0, 0.0), Vector2.ONE))


func test_base_center_without_turns_is_file_base() -> void:
	var centers: Array[Vector2] = []

	for seat: int in range(_layout.seat_count()):
		centers.append(BoardTurn.base_center(_layout, seat, 0))

	assert_eq(centers, _layout.bases)


func test_base_center_takes_bottom_tray_place_when_turned_down() -> void:
	var centers: Array[Vector2] = []

	for seat: int in [SEAT_TOP, SEAT_RIGHT, SEAT_LEFT]:
		var turns := BoardTurn.turns_to_bottom(_layout, seat)
		centers.append(BoardTurn.base_center(_layout, seat, turns))

	var bottom := _layout.bases[SEAT_BOTTOM]
	assert_eq(centers, [bottom, bottom, bottom])


func test_base_center_turns_own_base_when_no_start_matches() -> void:
	var layout := BoardLayout.load_from(BRANCH_BOARD)
	var size := layout.grid_size

	var center := BoardTurn.base_center(layout, 0, 1)

	assert_eq(center, BoardTurn.point(layout.bases[0], size, 1))
