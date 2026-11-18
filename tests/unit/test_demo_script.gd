extends GutTest
## "Nasıl oynanır" demosunun senaryo testleri: her adımın dizilimi tahtaya konabilmeli ve
## gösterilen hamle kural motorunun yasal hamlelerinden biri olmalı.

var _demo: DemoScript
var _board: BoardState


func before_each() -> void:
	_demo = DemoScript.load_from(DemoScript.PATH)
	_board = _demo.new_board(GameSettings.load_from(GameSettings.DEFAULT_PATH))


func test_load_from_default_path_reads_all_steps() -> void:
	assert_not_null(_demo)
	assert_false(_demo.steps.is_empty())


func test_place_every_step_succeeds() -> void:
	for index: int in _demo.steps.size():
		var placed := _demo.steps[index].place(_board)

		assert_true(placed, "Adım %d dizilimi tahtaya konamadı" % (index + 1))


func test_find_move_every_played_step_finds_legal_move() -> void:
	for index: int in _demo.steps.size():
		var step := _demo.steps[index]
		if not step.uses_card() or step.discards:
			continue
		step.place(_board)

		var move := step.find_move(_board, _demo.player_seat())

		assert_not_null(move, "Adım %d için yasal hamle bulunamadı" % (index + 1))


func test_discard_step_has_no_playable_card() -> void:
	for step: DemoStep in _demo.steps:
		if not step.discards:
			continue
		step.place(_board)

		for card_index: int in step.hand.size():
			var card := step.hand[card_index]
			var moves := _board.moves_for_card(_demo.player_seat(), card, card_index)

			assert_true(moves.is_empty(), "Atma adımında %d. kart oynanabiliyor" % card_index)


func test_last_step_move_finishes_player() -> void:
	var step: DemoStep = _demo.steps.back()
	step.place(_board)

	_board.apply(step.find_move(_board, _demo.player_seat()))

	assert_true(_board.has_finished(_demo.player_seat()))


func test_load_from_default_path_demo_slower_than_normal() -> void:
	assert_lt(_demo.speed, Tuning.settings.speed_levels[GameSpeed.Level.NORMAL])
