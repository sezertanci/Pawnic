extends GutTest
## Botun hamle seçiminin birim testleri.

const SEED := 7
const PAWNS := 2


func test_choose_move_returns_a_legal_move() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	var flags: Array[bool] = [true, true]
	var game := GameMatch.create(settings, flags, PAWNS, rng)
	game.begin_turn()

	var move := Bot.choose_move(game)

	var legal := game.legal_moves()
	if legal.is_empty():
		assert_null(move)
		return
	var keys: Array[String] = []
	for candidate: Move in legal:
		keys.append(_key(candidate))
	assert_has(keys, _key(move))


func _key(move: Move) -> String:
	return "%d/%d/%d/%d/%d" % [move.card_index, move.action, move.pawn, move.value, move.target]
