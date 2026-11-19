extends GutTest
## Oyunun başlayan oyuncusu (kura) ve koltuk renklerinin birim testleri.

const SEED := 42
const PAWNS := 4
const SEAT_COUNT := 4
const RED := 0
const GREEN := 2
const YELLOW := 3

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_next_turn_counts_rounds_from_starter() -> void:
	var game := _new_game([false, false, false])
	game.starter = 1

	game.next_turn()
	game.next_turn()
	var before_return := game.round_number
	game.next_turn()

	assert_eq(before_return, 1)
	assert_eq(game.current, 1)
	assert_eq(game.round_number, 2)


func test_from_dict_after_to_dict_keeps_colors_and_starter() -> void:
	var game := _new_game([false, true])
	game.colors = SeatColors.with_choice(SEAT_COUNT, game.seats, game.seats[0], RED)
	game.starter = 1
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))

	var copy := GameMatch.from_dict(_settings, saved, _rng())

	assert_not_null(copy)
	assert_eq(copy.colors, game.colors)
	assert_eq(copy.starter, 1)
	assert_eq(copy.current, 1)


func test_from_dict_with_repeated_color_returns_null() -> void:
	var saved := _new_game([false, true]).to_dict()
	saved[GameMatch.KEY_COLORS] = [RED, RED, GREEN, YELLOW]

	assert_null(GameMatch.from_dict(_settings, saved, _rng()))


func test_create_gives_every_seat_its_own_color() -> void:
	var game := _new_game([false, true])

	assert_eq(game.colors, SeatColors.identity(SEAT_COUNT))


func _new_game(bot_flags: Array[bool]) -> GameMatch:
	return GameMatch.create(_settings, bot_flags, PAWNS, _rng())


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng
