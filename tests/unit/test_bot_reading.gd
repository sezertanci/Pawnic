extends GutTest
## Botun gördüğü bilgiyle yaptığı hesapların birim testleri: görünmeyen kartlar, kart olasılıkları,
## tehdit okuyan değerlendirme ve olası oyun kopyası (oyunla dizi paylaşmaz).

const SEED := 11
const PLAYERS := 3
const PAWNS := 2
const NEAR_DISTANCE := 2

var _settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_card_odds_chances_sum_to_one() -> void:
	var odds := CardOdds.new(_settings, _whole_deck())

	var total := 0.0
	for chance: float in odds.chances:
		total += chance

	assert_almost_eq(total, 1.0, 0.0001)


func test_card_odds_reach_is_zero_beyond_longest_move() -> void:
	var odds := CardOdds.new(_settings, _whole_deck())

	assert_gt(odds.reach_chance(NEAR_DISTANCE), 0.0)
	assert_eq(odds.reach_chance(odds.max_distance() + 1), 0.0)


func test_evaluate_lowers_pawn_value_when_rival_is_close_behind() -> void:
	var board := BoardFixture.classic()
	BoardFixture.put(board, 0, "ring:12")
	BoardFixture.put(board, 2, "ring:10")

	var plain := BotEvaluator.new(_settings).evaluate(board, 0)
	var reading := BotEvaluator.new(_settings, _odds()).evaluate(board, 0)

	assert_lt(reading, plain)


func test_evaluate_ignores_threat_on_safe_square() -> void:
	var board := BoardFixture.classic()
	BoardFixture.put(board, 0, "ring:15")
	BoardFixture.put(board, 2, "ring:13")

	var plain := BotEvaluator.new(_settings).evaluate(board, 0)
	var reading := BotEvaluator.new(_settings, _odds()).evaluate(board, 0)

	assert_almost_eq(reading, plain, 0.0001)


func test_unseen_cards_leave_out_current_hand() -> void:
	var game := _game()
	game.begin_turn()

	var unseen := game.unseen_cards()

	var total := 0
	for entry: Dictionary in _settings.deck:
		total += int(entry[GameSettings.KEY_CARD_COUNT])
	assert_eq(unseen.size(), total - game.current_hand().size())


func test_determinized_keeps_own_hand_and_hand_sizes() -> void:
	var game := _game()
	game.begin_turn()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var copy := game.determinized(rng)

	assert_eq(_names(copy.current_hand()), _names(game.current_hand()))
	for index: int in range(game.hands.size()):
		assert_eq(copy.hands[index].size(), game.hands[index].size())
	assert_eq(copy.draw_count(), game.draw_count())
	assert_eq(copy.board.positions, game.board.positions)


func test_determinized_copy_does_not_share_seat_lists() -> void:
	var game := _game()
	var colors := game.colors.duplicate()
	var copy := game.determinized(RandomNumberGenerator.new())

	copy.bots[0] = false
	copy.seats.clear()
	copy.colors.clear()

	assert_true(game.bots[0])
	assert_eq(game.seats.size(), PLAYERS)
	assert_eq(game.colors, colors)


func _game() -> GameMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var flags: Array[bool] = []
	flags.resize(PLAYERS)
	flags.fill(true)
	return GameMatch.create(_settings, flags, PAWNS, rng)


func _odds() -> CardOdds:
	return CardOdds.new(_settings, _whole_deck())


func _whole_deck() -> Array[Card]:
	var cards: Array[Card] = []
	for entry: Dictionary in _settings.deck:
		for _i: int in range(int(entry[GameSettings.KEY_CARD_COUNT])):
			cards.append(Card.new(Card.TYPE_BY_NAME[entry["type"]], int(entry["value"])))
	return cards


func _names(cards: Array) -> Array[String]:
	var names: Array[String] = []
	for card: Card in cards:
		names.append("%d/%d" % [card.type, card.value])
	return names
