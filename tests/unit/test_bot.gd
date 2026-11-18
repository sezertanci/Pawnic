extends GutTest
## Botun hamle ve atılacak kart seçiminin birim testleri.

const SEED := 7
const PAWNS := 2
const PLAYERS := 4
const TURNS := 30

var _settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_bot_profiles_cover_every_level() -> void:
	assert_eq(_settings.bot_profiles.size(), Bot.Level.size())


func test_choose_move_returns_legal_moves_on_every_level() -> void:
	for level: Bot.Level in Bot.Level.values():
		var rng := _rng()
		var flags: Array[bool] = []
		flags.resize(PLAYERS)
		flags.fill(true)
		var game := GameMatch.create(_settings, flags, PAWNS, rng)
		var bot := Bot.new(_settings.bot_profiles[level], _settings, rng)
		for turn: int in TURNS:
			if game.winner() != GameMatch.NO_WINNER:
				break
			game.begin_turn()
			var move := bot.choose_move(game)
			if move == null:
				assert_true(game.legal_moves().is_empty())
				game.discard(bot.choose_discard(game.current_hand()))
			else:
				assert_has(_keys(game.legal_moves()), _key(move))
				game.play(move)
			game.next_turn()


func test_choose_discard_returns_hand_index() -> void:
	var hand: Array[Card] = []
	for type: Card.Type in [Card.Type.EXIT, Card.Type.FORWARD, Card.Type.JOKER]:
		hand.append(Card.new(type, 1))
	for level: Bot.Level in Bot.Level.values():
		var index := Bot.new(_settings.bot_profiles[level], _settings, _rng()).choose_discard(hand)
		assert_between(index, 0, hand.size() - 1)


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng


func _keys(moves: Array[Move]) -> Array[String]:
	var keys: Array[String] = []
	for move: Move in moves:
		keys.append(_key(move))
	return keys


func _key(move: Move) -> String:
	return "%d/%d/%d/%d/%d" % [move.card_index, move.action, move.pawn, move.value, move.target]
