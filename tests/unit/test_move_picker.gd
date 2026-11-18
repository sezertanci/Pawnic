extends GutTest
## Adım adım hamle seçiminin birim testleri.

var _picker: MovePicker


func before_each() -> void:
	_picker = MovePicker.new()


func test_must_discard_without_legal_moves() -> void:
	_picker.reset(_moves([]))

	assert_true(_picker.must_discard())


func test_pick_card_with_single_value_goes_to_pawn_stage() -> void:
	_picker.reset(_moves([Move.new(0, Move.Action.FORWARD, 1, 3)]))

	_picker.pick_card(0)

	assert_eq(_picker.stage, MovePicker.Stage.PAWN)
	assert_eq(_picker.selectable_pawns(), _ints([1]))


func test_joker_with_many_values_asks_for_value() -> void:
	_picker.reset(
		_moves([Move.new(0, Move.Action.FORWARD, 1, 2), Move.new(0, Move.Action.FORWARD, 1, 5)])
	)

	_picker.pick_card(0)

	assert_eq(_picker.stage, MovePicker.Stage.VALUE)
	assert_eq(_picker.values(), _ints([2, 5]))


func test_pick_pawn_returns_move_without_target() -> void:
	var move := Move.new(0, Move.Action.FORWARD, 1, 3)
	_picker.reset(_moves([move]))
	_picker.pick_card(0)

	assert_eq(_picker.pick_pawn(1), move)


func test_swap_asks_for_target_then_returns_move() -> void:
	var move := Move.new(0, Move.Action.SWAP, 1, 0, 4)
	_picker.reset(_moves([move, Move.new(0, Move.Action.SWAP, 1, 0, 5)]))
	_picker.pick_card(0)

	assert_null(_picker.pick_pawn(1))
	assert_eq(_picker.stage, MovePicker.Stage.TARGET)
	assert_eq(_picker.selectable_pawns(), _ints([4, 5]))
	assert_eq(_picker.pick_pawn(4), move)


func test_selected_pawn_is_known_only_while_picking_target() -> void:
	_picker.reset(_moves([Move.new(0, Move.Action.SWAP, 1, 0, 4)]))
	_picker.pick_card(0)
	assert_eq(_picker.selected_pawn(), Move.NO_PAWN)

	_picker.pick_pawn(1)

	assert_eq(_picker.selected_pawn(), 1)


func test_is_card_playable_only_for_cards_with_moves() -> void:
	_picker.reset(_moves([Move.new(1, Move.Action.FORWARD, 0, 2)]))

	assert_false(_picker.is_card_playable(0))
	assert_true(_picker.is_card_playable(1))


func test_pawn_with_many_destinations_asks_for_square() -> void:
	var near := Move.new(0, Move.Action.FORWARD, 0, 2, Move.NO_PAWN, 5)
	var branch := Move.new(0, Move.Action.FORWARD, 0, 2, Move.NO_PAWN, 7)
	_picker.reset(_moves([near, branch]))
	_picker.pick_card(0)

	assert_null(_picker.pick_pawn(0))
	assert_eq(_picker.stage, MovePicker.Stage.DESTINATION)
	assert_eq(_picker.selectable_squares(), _ints([5, 7]))
	assert_eq(_picker.pick_destination(7), branch)


func test_candidates_list_every_move_of_picked_card() -> void:
	var first := Move.new(0, Move.Action.FORWARD, 1, 3)
	var second := Move.new(0, Move.Action.FORWARD, 2, 3)
	_picker.reset(_moves([first, second, Move.new(1, Move.Action.FORWARD, 1, 4)]))

	_picker.pick_card(0)

	assert_eq(_picker.candidates(), _moves([first, second]))


func test_candidates_are_empty_until_joker_value_is_picked() -> void:
	var five := Move.new(0, Move.Action.FORWARD, 1, 5)
	_picker.reset(_moves([Move.new(0, Move.Action.FORWARD, 1, 2), five]))
	_picker.pick_card(0)
	assert_true(_picker.candidates().is_empty())

	_picker.pick_value(5)

	assert_eq(_picker.candidates(), _moves([five]))


func _moves(list: Array) -> Array[Move]:
	var result: Array[Move] = []
	result.assign(list)
	return result


func _ints(list: Array) -> Array[int]:
	var result: Array[int] = []
	result.assign(list)
	return result
