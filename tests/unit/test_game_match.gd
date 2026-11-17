extends GutTest
## Oyun kurulumu ve kayıt gidiş-dönüşünün birim testleri.

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
	assert_eq(game.last_discard_seat, GameMatch.NO_SEAT)
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
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))

	var copy := GameMatch.from_dict(_settings, saved, _rng())

	assert_not_null(copy)
	assert_eq(JSON.stringify(copy.to_dict()), JSON.stringify(game.to_dict()))
	assert_eq(copy.elapsed, 333.5)


func test_from_dict_with_other_version_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	saved["version"] = GameMatch.SAVE_VERSION + 1

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_from_dict_with_unknown_card_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	(saved["draw"] as Array).append({"type": "teleport", "value": 0})

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_from_dict_with_missing_hand_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	(saved["hands"] as Array).pop_back()

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func _first_move_for_card(game: GameMatch, card_index: int) -> Move:
	for move: Move in game.legal_moves():
		if move.card_index == card_index:
			return move
	return null


func _new_game(bot_flags: Array[bool]) -> GameMatch:
	return GameMatch.create(_settings, bot_flags, PAWNS, _rng())


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng
