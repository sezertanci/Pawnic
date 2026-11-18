extends GutTest
## Oyun kurulumu, bitiren oyuncular, oyun sonucu (MatchResult) ve kayıt gidiş-dönüşünün birim
## testleri.

const SEED := 42
const PAWNS := 4

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_create_deals_hand_to_every_player() -> void:
	var game := _new_game([false, true, true])

	assert_eq(game.seats.size(), 3)
	for hand: Array[Card] in game.hands:
		assert_eq(hand.size(), _settings.hand_size)


func test_begin_turn_takes_card_from_draw_pile() -> void:
	var game := _new_game([false, true])
	var before := game.draw_count()

	game.begin_turn()

	assert_eq(game.draw_count(), before - 1)


func test_top_discard_is_last_discarded_card() -> void:
	var game := _new_game([false, true])
	assert_null(game.top_discard())
	game.begin_turn()
	var card := game.current_hand()[0]

	game.discard(0)

	assert_eq(game.top_discard(), card)


func test_discard_records_discarding_seat() -> void:
	var game := _new_game([false, true])
	assert_eq(game.last_discard_seat, BoardLayout.NO_SEAT)
	game.begin_turn()

	game.discard(0)

	assert_eq(game.last_discard_seat, game.current_seat())


func test_play_with_joker_records_chosen_value() -> void:
	var game := _new_game([false, true])
	game.begin_turn()
	game.current_hand()[0] = Card.new(Card.Type.JOKER, 0)
	var move := _first_move_for_card(game, 0)

	game.play(move)

	assert_eq(game.top_discard_value, move.value)


func test_discard_after_joker_clears_chosen_value() -> void:
	var game := _new_game([false, true])
	game.begin_turn()
	game.current_hand()[0] = Card.new(Card.Type.JOKER, 0)
	game.play(_first_move_for_card(game, 0))
	game.next_turn()
	game.begin_turn()

	game.discard(0)

	assert_eq(game.top_discard_value, Card.NO_VALUE)


func test_from_dict_after_to_dict_restores_match() -> void:
	var game := _new_game([false, true])
	game.begin_turn()
	game.discard(0)
	game.next_turn()
	game.elapsed = 333.5
	game.bot_level = Bot.Level.EXPERT
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))

	var copy := GameMatch.from_dict(_settings, saved, _rng())

	assert_not_null(copy)
	assert_eq(JSON.stringify(copy.to_dict()), JSON.stringify(game.to_dict()))
	assert_eq(copy.elapsed, 333.5)
	assert_eq(copy.bot_level, Bot.Level.EXPERT)


func test_from_dict_with_other_version_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	saved[GameMatch.KEY_VERSION] = GameMatch.SAVE_VERSION + 1

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_from_dict_with_unknown_card_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	(saved[GameMatch.KEY_DRAW] as Array).append({"type": "teleport", "value": 0})

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_from_dict_with_missing_hand_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	(saved[GameMatch.KEY_HANDS] as Array).pop_back()

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_play_when_rival_finishes_moves_hand_to_discard_pile() -> void:
	var game := _new_game([false, false, false])
	game.begin_turn()
	var finisher := game.seats[1]
	_send_home(game, finisher, PAWNS)
	var expected := game.discard_count() + 1 + game.hands[1].size()

	game.play(_any_move(game))

	assert_eq(game.finishers, [finisher] as Array[int])
	assert_eq(MatchResult.finish_round(game, finisher), 1)
	assert_true(game.hands[1].is_empty())
	assert_eq(game.discard_count(), expected)


func test_next_turn_skips_finished_seat_and_counts_rounds() -> void:
	var game := _new_game([false, false, false])
	game.begin_turn()
	_send_home(game, game.seats[1], PAWNS)
	game.play(_any_move(game))

	game.next_turn()
	var after_first := game.current
	game.next_turn()

	assert_eq(after_first, 2)
	assert_eq(game.current, 0)
	assert_eq(game.round_number, 2)


func test_is_over_with_one_finisher_and_two_players_left_returns_false() -> void:
	var game := _new_game([false, false, false])
	game.begin_turn()
	_send_home(game, game.seats[1], PAWNS)

	game.play(_any_move(game))

	assert_false(MatchResult.is_over(game))


func test_is_over_when_one_player_left_returns_true() -> void:
	var game := _new_game([false, false, false])
	game.begin_turn()
	_send_home(game, game.seats[1], PAWNS)
	_send_home(game, game.seats[2], PAWNS)

	game.play(_any_move(game))

	assert_true(MatchResult.is_over(game))


func test_is_over_when_only_bots_left_returns_true() -> void:
	var game := _new_game([false, true, true])
	game.current = 1
	game.begin_turn()
	_send_home(game, game.seats[0], PAWNS)

	game.play(_any_move(game))

	assert_true(MatchResult.is_over(game))


func test_ranking_lists_finishers_then_others_by_progress() -> void:
	var game := _new_game([false, false, false, false])
	var seats := game.seats
	_send_home(game, seats[2], PAWNS)
	_send_home(game, seats[3], 2)
	_send_home(game, seats[1], 1)
	game.finishers.assign([seats[2]])
	game.finish_rounds.assign([3])

	var ranking := MatchResult.ranking(game)

	assert_eq(ranking, [seats[2], seats[3], seats[1], seats[0]] as Array[int])
	assert_eq(MatchResult.finish_round(game, seats[2]), 3)
	assert_eq(MatchResult.finish_round(game, seats[0]), MatchResult.NO_ROUND)


func test_from_dict_after_to_dict_keeps_finishers_and_round() -> void:
	var game := _new_game([false, false, false])
	_send_home(game, game.seats[1], PAWNS)
	game.finishers.assign([game.seats[1]])
	game.finish_rounds.assign([4])
	game.round_number = 5
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))

	var copy := GameMatch.from_dict(_settings, saved, _rng())

	assert_not_null(copy)
	assert_eq(copy.finishers, game.finishers)
	assert_eq(MatchResult.finish_round(copy, game.seats[1]), 4)
	assert_eq(copy.round_number, 5)


func _first_move_for_card(game: GameMatch, card_index: int) -> Move:
	for move: Move in game.legal_moves():
		if move.card_index == card_index:
			return move
	return null


## Sıradaki oyuncunun ilk yasal hamlesi.
func _any_move(game: GameMatch) -> Move:
	var moves := game.legal_moves()
	assert_false(moves.is_empty(), "Sıradaki oyuncunun yasal hamlesi olmalı")
	return moves[0]


## Koltuğun ilk count taşını evine koyar.
func _send_home(game: GameMatch, seat: int, count: int) -> void:
	var board := game.board
	for pawn: int in range(board.owners.size()):
		if count > 0 and board.owners[pawn] == seat:
			board.positions[pawn] = board.layout.homes[seat]
			count -= 1


func _new_game(bot_flags: Array[bool]) -> GameMatch:
	return GameMatch.create(_settings, bot_flags, PAWNS, _rng())


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng
