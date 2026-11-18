extends GutTest
## Klasik tahtada yer değiştirme kartı testleri.

var _board: BoardState


func before_each() -> void:
	_board = BoardFixture.classic()


func test_move_path_for_swap_goes_forward_when_target_is_close_ahead() -> void:
	BoardFixture.put(_board, 0, "ring:10")
	BoardFixture.put(_board, 2, "ring:13")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(
		BoardFixture.names(_board, _board.move_path(moves[0])), ["ring:11", "ring:12", "ring:13"]
	)


func test_move_path_for_swap_goes_back_when_target_is_close_behind() -> void:
	BoardFixture.put(_board, 0, "ring:13")
	BoardFixture.put(_board, 2, "ring:10")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(
		BoardFixture.names(_board, _board.move_path(moves[0])), ["ring:12", "ring:11", "ring:10"]
	)


func test_move_path_for_swap_goes_forward_long_way_when_target_is_ahead() -> void:
	BoardFixture.put(_board, 0, "ring:10")
	BoardFixture.put(_board, 2, "ring:5")
	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	var path := BoardFixture.names(_board, _board.move_path(moves[0]))

	assert_eq(path[0], "ring:11")
	assert_eq(path[path.size() - 1], "ring:5")


func test_swap_path_follows_target_owner_direction() -> void:
	var from := _board.layout.index_of("ring:40")
	var to := _board.layout.index_of("ring:30")

	var path := BoardFixture.names(_board, _board.swap_path(2, from, to))

	assert_eq(path[0], "ring:41")
	assert_eq(path[path.size() - 1], "ring:30")


func test_swap_allows_own_pawn_on_safe_square() -> void:
	BoardFixture.put(_board, 0, "ring:8")
	BoardFixture.put(_board, 2, "ring:20")

	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(moves.size(), 1)
	assert_eq(moves[0].target, 2)


func test_swap_does_not_target_rival_on_safe_square() -> void:
	BoardFixture.put(_board, 0, "ring:10")
	BoardFixture.put(_board, 2, "ring:36")

	var moves := _board.moves_for_card(0, Card.new(Card.Type.SWAP, 0), 0)

	assert_eq(moves.size(), 0)
