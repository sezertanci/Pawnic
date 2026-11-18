extends RefCounted
## Simülasyon araçlarının ortak döngüsü: botları birbirine karşı oyun bitene kadar oynatır.

## Oyun tur sınırında bitmezse play() bunu döner.
const UNFINISHED := -1


## Bütün koltukları bot olan yeni bir oyun kurar; seed aynıysa oyun da aynı olur.
static func new_game(
	settings: GameSettings, players: int, pawns: int, seed_value: int
) -> GameMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var flags: Array[bool] = []
	for _i: int in range(players):
		flags.append(true)
	return GameMatch.create(settings, flags, pawns, rng)


## Her koltuğa (sıra sırasıyla) aynı seviyede bir bot verir.
static func same_bots(
	settings: GameSettings, players: int, level: Bot.Level, seed_value: int
) -> Array[Bot]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bots: Array[Bot] = []
	for _i: int in range(players):
		bots.append(Bot.new(settings.bot_profiles[level], settings, rng))
	return bots


## Oyunu kazanan çıkana kadar oynatır; hamle sayısını, sınır aşılırsa UNFINISHED döner.
## bots, sıra sırasıyla her oyuncunun botudur.
static func play(game: GameMatch, bots: Array[Bot], turn_limit: int) -> int:
	for turn: int in range(turn_limit):
		game.begin_turn()
		var bot := bots[game.current]
		var move := bot.choose_move(game)
		if move == null:
			game.discard(bot.choose_discard(game.current_hand()))
		else:
			game.play(move)
		if game.winner() != GameMatch.NO_WINNER:
			return turn + 1
		game.next_turn()
	return UNFINISHED
