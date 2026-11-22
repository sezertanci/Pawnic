extends GutTest
## Tahta dosyası okuma ve dallanan yollarda hareket testleri (tests/fixtures/branch_board.json).

const FIXTURE := "res://tests/fixtures/branch_board.json"
## Çıkış karesi güvenli kareler listesinde olmayan tahta.
const UNSAFE_START_FIXTURE := "res://tests/fixtures/unsafe_start_board.json"
## Kareleri tek tek ondalık yerlerle yazılmış, çember kareli tahta.
const FREE_FIXTURE := "res://tests/fixtures/free_board.json"
## Tanımsız kare biçimli tahta.
const BAD_SHAPE_FIXTURE := "res://tests/fixtures/bad_shape_board.json"
const FOUR_LEAF := "res://data/boards/four_leaf.json"
const FORWARD := Card.Type.FORWARD

var _board: BoardState


func before_each() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.board_layout = BoardLayout.load_from(FIXTURE)
	_board = BoardState.new(settings)
	_board.add_pawns(0, 1)
	_board.add_pawns(1, 1)


func test_load_from_expands_paths_into_squares() -> void:
	var layout := _board.layout

	assert_eq(layout.square_count(), 24 + 2 + 3 + 2)
	assert_eq(layout.cells[layout.index_of("ring:6")], Vector2(6, 0))
	assert_eq(layout.grid_size, Vector2(7, 7))


func test_load_from_rejects_unsafe_start() -> void:
	var layout := BoardLayout.load_from(UNSAFE_START_FIXTURE)

	assert_null(layout)
	assert_push_error("çıkış karesi güvenli değil")


func test_load_from_reads_free_squares() -> void:
	var layout := BoardLayout.load_from(FREE_FIXTURE)

	assert_eq(layout.square_count(), 6 + 2)
	assert_eq(layout.cells[layout.index_of("ring:1")], Vector2(1.2, 0.4))
	assert_eq(layout.next_squares[layout.index_of("ring:5")], layout.index_of("ring:0"))


func test_load_from_reads_drawing_fields() -> void:
	var layout := BoardLayout.load_from(FREE_FIXTURE)

	assert_eq(layout.square_shape, BoardLayout.SquareShape.CIRCLE)
	assert_eq(layout.grid_size, Vector2(5, 4))
	assert_eq(layout.center_outline.size(), 3)
	assert_almost_eq(layout.spinner_ratio, 1.2, 0.001)
	assert_eq(layout.base_approaches, [Vector2(0, -1)] as Array[Vector2])


func test_load_from_defaults_to_square_shape() -> void:
	assert_eq(_board.layout.square_shape, BoardLayout.SquareShape.SQUARE)
	assert_true(_board.layout.center_outline.is_empty())
	assert_eq(_board.layout.spinner_ratio, 0.0)
	assert_true(
		_board.layout.base_approaches.all(func(d: Vector2) -> bool: return d == Vector2.ZERO)
	)


func test_load_from_rejects_unknown_shape() -> void:
	var layout := BoardLayout.load_from(BAD_SHAPE_FIXTURE)

	assert_null(layout)
	assert_push_error("kare biçimi")


func test_four_leaf_board_loads_with_every_seat() -> void:
	var layout := BoardLayout.load_from(FOUR_LEAF)

	assert_not_null(layout)
	assert_eq(layout.seat_count(), 4)
	assert_eq(layout.square_count(), 56 + 4 * 6)


func test_home_distance_follows_forced_link() -> void:
	var layout := _board.layout

	assert_eq(layout.home_distance(0, layout.index_of("ring:23")), 4)
	assert_eq(layout.home_distance(0, layout.index_of("lane0:2")), 0)


func test_choice_link_gives_both_destinations() -> void:
	_put(0, "ring:2")

	assert_eq(_destinations(0, 2), ["cut:0", "ring:4"])


func test_choice_link_can_be_passed_through() -> void:
	_put(0, "ring:3")

	assert_eq(_destinations(0, 3), ["ring:10", "ring:6"])


func test_exact_link_only_from_standing_square() -> void:
	_put(0, "ring:5")
	assert_eq(_destinations(0, 1), ["ring:15", "ring:6"])

	_put(0, "ring:4")
	assert_eq(_destinations(0, 2), ["ring:6"])


func test_forced_link_applies_only_to_its_seats() -> void:
	_put(0, "ring:23")
	_put(1, "ring:23")

	assert_eq(_destinations(0, 2), ["lane0:0"])
	assert_eq(_destinations(1, 2), ["ring:1"])


func test_move_past_home_is_not_offered() -> void:
	_put(0, "lane0:1")

	assert_eq(_destinations(0, 2), [])
	assert_eq(_destinations(0, 1), ["lane0:2"])


func test_apply_moves_pawn_to_chosen_destination() -> void:
	_put(0, "ring:2")
	var moves := _board.moves_for_card(0, Card.new(FORWARD, 2), 0)
	var first := moves[0].destination
	var branch: Move = moves.filter(func(move: Move) -> bool: return move.destination != first)[0]

	_board.apply(branch)

	assert_eq(_board.positions[0], branch.destination)


func _put(pawn: int, square_name: String) -> void:
	_board.positions[pawn] = _board.layout.index_of(square_name)


## Taşın bu ileri kartıyla varabileceği karelerin adları, alfabetik.
func _destinations(seat: int, value: int) -> Array[String]:
	var names: Array[String] = []
	for move: Move in _board.moves_for_card(seat, Card.new(FORWARD, value), 0):
		names.append(_board.layout.names[move.destination])
	names.sort()
	return names
