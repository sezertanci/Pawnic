extends GutTest
## Oyun içi geçiş reklamı zamanlamasının ve reklam anının kayda yazılmasının birim testleri.

const SEED := 42
const PAWNS := 4
## Reklam aralığından küçük bir pay; sınırın hemen altını denemek için.
const MARGIN := 1.0
## Koltuk sırasıyla bot bayrakları: ilk sıra insanda ya da botta.
const HUMAN_FIRST: Array[bool] = [false, true]
const BOT_FIRST: Array[bool] = [true, false]

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_is_due_before_interval_returns_false() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.elapsed = _settings.interstitial_interval - MARGIN

	assert_false(AdSchedule.is_due(game))


func test_is_due_after_interval_on_human_turn_returns_true() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.elapsed = _settings.interstitial_interval

	assert_true(AdSchedule.is_due(game))


func test_is_due_on_bot_turn_returns_false() -> void:
	var game := _new_game(BOT_FIRST)
	game.elapsed = _settings.interstitial_interval

	assert_false(AdSchedule.is_due(game))


func test_is_due_counts_from_last_ad() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.last_ad_at = _settings.interstitial_interval
	game.elapsed = 2.0 * _settings.interstitial_interval - MARGIN

	assert_false(AdSchedule.is_due(game))


func test_skips_end_ad_without_mid_game_ad_returns_false() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.elapsed = _settings.interstitial_interval

	assert_false(AdSchedule.skips_end_ad(game))


func test_skips_end_ad_soon_after_mid_game_ad_returns_true() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.last_ad_at = _settings.interstitial_interval
	game.elapsed = game.last_ad_at + _settings.end_ad_cooldown - MARGIN

	assert_true(AdSchedule.skips_end_ad(game))


func test_skips_end_ad_long_after_mid_game_ad_returns_false() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.last_ad_at = _settings.interstitial_interval
	game.elapsed = game.last_ad_at + _settings.end_ad_cooldown

	assert_false(AdSchedule.skips_end_ad(game))


func test_saved_game_keeps_last_ad_time() -> void:
	var game := _new_game(HUMAN_FIRST)
	game.last_ad_at = _settings.interstitial_interval
	game.elapsed = game.last_ad_at

	var loaded := GameMatch.from_dict(_settings, game.to_dict(), RandomNumberGenerator.new())

	assert_eq(loaded.last_ad_at, game.last_ad_at)
	assert_false(AdSchedule.is_due(loaded))


func _new_game(bots: Array[bool]) -> GameMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return GameMatch.create(_settings, bots, PAWNS, rng)
