extends GutTest
## Klasik tahtada kural testleri.

const SEND_BACK_VALUE := 3

var _board: BoardState


func before_each() -> void:
	_board = BoardState.new(GameSettings.load_from(GameSettings.DEFAULT_PATH))
	_board.add_pawns(0, 2)
	_board.add_pawns(2, 1)


func test_send_back_onto_own_pawn_is_not_offered() -> void:
	_put(0, "ring:13")
	_put(1, "ring:10")
	var card := Card.new(Card.Type.SEND_BACK, SEND_BACK_VALUE)

	var moves := _board.moves_for_card(2, card, 0)

	var pawns: Array[int] = []
	for move: Move in moves:
		pawns.append(move.pawn)
	assert_does_not_have(pawns, 0, "Kendi taşının üstüne düşecek taş seçilememeli")
	assert_has(pawns, 1)


func test_send_back_stops_at_start_square() -> void:
	_put(0, "ring:10")
	var card := Card.new(Card.Type.SEND_BACK, SEND_BACK_VALUE)

	var moves := _board.moves_for_card(2, card, 0)

	assert_eq(moves.size(), 1)
	assert_eq(_board.layout.names[moves[0].destination], "ring:8")


func test_forward_enters_home_lane_at_entry() -> void:
	_put(0, "ring:6")

	var moves := _board.moves_for_card(0, Card.new(Card.Type.FORWARD, 3), 0)

	assert_eq(moves.size(), 1)
	assert_eq(_board.layout.names[moves[0].destination], "lane0:1")


func test_speed_square_adds_bonus() -> void:
	_put(2, "ring:2")
	var moves := _board.moves_for_card(2, Card.new(Card.Type.FORWARD, 2), 0)

	_board.apply(moves[0])

	assert_eq(_board.layout.names[_board.positions[2]], "ring:8")


func test_move_path_lists_squares_with_speed_bonus() -> void:
	_put(2, "ring:2")
	var moves := _board.moves_for_card(2, Card.new(Card.Type.FORWARD, 2), 0)

	var path := _board.move_path(moves[0])

	assert_eq(_names(path), ["ring:3", "ring:4", "ring:5", "ring:6", "ring:7", "ring:8"])


func test_move_path_goes_back_on_negative_speed_square() -> void:
	_put(0, "ring:51")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.FORWARD, 2), 0)

	var path := _board.move_path(moves[0])
	_board.apply(moves[0])

	assert_eq(_names(path), ["ring:52", "ring:53", "ring:52", "ring:51"])
	assert_eq(_board.layout.names[_board.positions[0]], "ring:51")


func test_speed_square_never_leads_to_another_speed_square() -> void:
	var layout := _board.layout
	for square: int in range(layout.square_count()):
		if layout.speed[square] == 0:
			continue
		for pawn: int in range(_board.owners.size()):
			var path := _board._boost_path(pawn, square)
			if not path.is_empty():
				assert_eq(layout.speed[path.back()], 0, layout.names[square])


func test_move_path_follows_home_lane_entry() -> void:
	_put(0, "ring:6")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.FORWARD, 3), 0)

	assert_eq(_names(_board.move_path(moves[0])), ["ring:7", "lane0:0", "lane0:1"])


func test_move_path_goes_backwards_for_send_back() -> void:
	_put(0, "ring:10")
	var moves := _board.moves_for_card(2, Card.new(Card.Type.SEND_BACK, SEND_BACK_VALUE), 0)

	assert_eq(_names(_board.move_path(moves[0])), ["ring:9", "ring:8"])


func test_move_path_lists_squares_up_to_shortcut() -> void:
	_put(0, "ring:2")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SHORTCUT, 0), 0)

	var path := _board.move_path(moves[0])

	assert_eq(_names(path), ["ring:3", "ring:4", "ring:5", "ring:6", "ring:7"])


func test_move_path_for_swap_goes_forward_when_target_is_close_ahead() -> void:
	_put(0, "ring:10")
	_put(2, "ring:13")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(_names(_board.move_path(moves[0])), ["ring:11", "ring:12", "ring:13"])


func test_move_path_for_swap_goes_back_when_target_is_close_behind() -> void:
	_put(0, "ring:13")
	_put(2, "ring:10")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(_names(_board.move_path(moves[0])), ["ring:12", "ring:11", "ring:10"])


func test_swap_allows_own_pawn_on_safe_square() -> void:
	_put(0, "ring:8")
	_put(2, "ring:20")

	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(moves.size(), 1)
	assert_eq(moves[0].target, 2)


func test_swap_does_not_target_rival_on_safe_square() -> void:
	_put(0, "ring:10")
	_put(2, "ring:36")

	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(moves.size(), 0)


func test_home_distance_from_start_covers_whole_track() -> void:
	var layout := _board.layout

	assert_eq(layout.home_distance(0, layout.starts[0]), 61)


func test_load_dict_restores_saved_positions() -> void:
	_put(0, "ring:15")
	_put(2, "lane2:3")
	var copy := BoardState.new(_board.settings)

	var loaded := copy.load_dict(JSON.parse_string(JSON.stringify(_board.to_dict())))

	assert_true(loaded)
	assert_eq(copy.owners, _board.owners)
	assert_eq(copy.positions, _board.positions)


func test_load_dict_with_mismatched_arrays_fails() -> void:
	var loaded := _board.load_dict(
		{BoardState.KEY_OWNERS: [0, 0], BoardState.KEY_POSITIONS: ["base"]}
	)

	assert_false(loaded)


func test_load_dict_with_unknown_square_fails() -> void:
	var loaded := _board.load_dict(
		{BoardState.KEY_OWNERS: [0], BoardState.KEY_POSITIONS: ["nowhere:3"]}
	)

	assert_false(loaded)


func _put(pawn: int, square_name: String) -> void:
	_board.positions[pawn] = _board.layout.index_of(square_name)


func _names(path: Array[int]) -> Array[String]:
	var result: Array[String] = []
	for square: int in path:
		result.append(_board.layout.names[square])
	return result
