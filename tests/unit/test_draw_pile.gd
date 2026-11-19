extends GutTest
## Deste boşalınca atılanların karıştırılıp yeni deste olmasının birim testleri.

const SEED := 42
const PAWNS := 4

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_reshuffle_if_empty_moves_discards_to_draw_pile() -> void:
	var game := _empty_draw_pile_game()
	var discarded := game.discard_count()

	var reshuffled := game.reshuffle_if_empty()

	assert_true(reshuffled)
	assert_eq(game.draw_count(), discarded)
	assert_eq(game.discard_count(), 0)


func test_reshuffle_if_empty_with_cards_in_draw_pile_does_nothing() -> void:
	var game := _new_game()
	var before := game.draw_count()

	var reshuffled := game.reshuffle_if_empty()

	assert_false(reshuffled)
	assert_eq(game.draw_count(), before)


func test_begin_turn_with_empty_draw_pile_reshuffles_before_drawing() -> void:
	var game := _empty_draw_pile_game()
	var discarded := game.discard_count()

	game.begin_turn()

	assert_eq(game.draw_count(), discarded - 1)
	assert_eq(game.discard_count(), 0)


## Deste son kartına kadar çekilip atılmış, atılanlarda kart olan oyun.
func _empty_draw_pile_game() -> GameMatch:
	var game := _new_game()
	while game.draw_count() > 0:
		game.begin_turn()
		game.discard(0)
	return game


func _new_game() -> GameMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return GameMatch.create(_settings, [false, true] as Array[bool], PAWNS, rng)
