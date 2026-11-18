extends SceneTree
## Bot zorluk seviyelerinin kademeli olup olmadığını ölçer. Her seviye çifti iki oyunculu
## oyunlarda karşılaşır; koltuklar ve ilk oynayan oyundan oyuna değişir. Satırdaki seviyenin
## sütundakine karşı kazanma oranı yazılır. Ayrıca her seviyenin hamle başına ortalama düşünme
## süresi ölçülür (tabletteki takılma riskini görmek için).
## Çalıştırma: godot --headless --path . -s tools/level_ladder.gd

const BotRunner := preload("res://tools/bot_runner.gd")
const GAMES_PER_PAIR := 200
const TURN_LIMIT := 5000
const PAWNS := 4
const PLAYERS := 2
const LEVEL_NAMES: Array[String] = ["Kolay", "Orta", "Zor", "Çok zor"]
const PERCENT := 100.0
const USEC_PER_MSEC := 1000.0

var _think_usec: Array[int] = []
var _moves: Array[int] = []


func _initialize() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	var count := Bot.Level.size()
	_think_usec.resize(count)
	_think_usec.fill(0)
	_moves.resize(count)
	_moves.fill(0)
	print("Satır seviyesinin sütun seviyesine karşı kazanma oranı (%d oyun):" % GAMES_PER_PAIR)
	print(
		"%-10s %s" % ["", "  ".join(LEVEL_NAMES.map(func(n: String) -> String: return "%8s" % n))]
	)
	var rates := _rates(settings, count)
	for row: int in range(count):
		var cells: Array[String] = []
		for column: int in range(count):
			cells.append("%8s" % ("-" if row == column else "%%%.0f" % rates[row][column]))
		print("%-10s %s" % [LEVEL_NAMES[row], "  ".join(cells)])
	print("\nHamle başına düşünme süresi:")
	for level: int in range(count):
		var average := float(_think_usec[level]) / maxi(_moves[level], 1) / USEC_PER_MSEC
		print("  %-8s %.2f ms" % [LEVEL_NAMES[level], average])
	quit()


## Her çift bir kez oynatılır; karşı yönün oranı tümleyenidir.
func _rates(settings: GameSettings, count: int) -> Array[Array]:
	var rates: Array[Array] = []
	for row: int in range(count):
		var line: Array[float] = []
		line.resize(count)
		rates.append(line)
	for row: int in range(count):
		for column: int in range(row + 1, count):
			rates[row][column] = _rate(settings, row, column)
			rates[column][row] = PERCENT - rates[row][column]
	return rates


## Oynanan oyunlarda first seviyesinin second seviyesine karşı kazanma yüzdesi.
func _rate(settings: GameSettings, first: Bot.Level, second: Bot.Level) -> float:
	var wins := 0
	var finished := 0
	for game_index: int in range(GAMES_PER_PAIR):
		var game := BotRunner.new_game(settings, PLAYERS, PAWNS, game_index)
		game.current = game_index % PLAYERS
		var rng := RandomNumberGenerator.new()
		rng.seed = game_index
		var levels: Array[Bot.Level] = [first, second]
		if game_index % 4 >= 2:
			levels.reverse()
		if _play(game, settings, levels, rng) == BotRunner.UNFINISHED:
			continue
		finished += 1
		if levels[game.seats.find(game.winner())] == first:
			wins += 1
	return float(wins) / maxi(finished, 1) * PERCENT


## BotRunner.play gibi oynatır, ayrıca her seviyenin düşünme süresini toplar.
func _play(
	game: GameMatch, settings: GameSettings, levels: Array[Bot.Level], rng: RandomNumberGenerator
) -> int:
	var bots: Array[Bot] = []
	for level: Bot.Level in levels:
		bots.append(Bot.new(settings.bot_profiles[level], settings, rng))
	for turn: int in range(TURN_LIMIT):
		game.begin_turn()
		var started := Time.get_ticks_usec()
		var move := bots[game.current].choose_move(game)
		_think_usec[levels[game.current]] += Time.get_ticks_usec() - started
		_moves[levels[game.current]] += 1
		if move == null:
			game.discard(bots[game.current].choose_discard(game.current_hand()))
		else:
			game.play(move)
		if game.winner() != GameMatch.NO_WINNER:
			return turn + 1
		game.next_turn()
	return BotRunner.UNFINISHED
