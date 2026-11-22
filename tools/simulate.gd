extends SceneTree
## Botları birbirine karşı oynatıp kural motorunun takılmadan bittiğini denetler.
## Çalıştırma: godot --headless --path . -s tools/simulate.gd [-- <tahta kimliği>]
## Tahta verilmezse ayar dosyasındaki ilk tahta kullanılır.

const BotRunner := preload("res://tools/bot_runner.gd")
const GAMES_PER_SETUP := 50
const TURN_LIMIT := 5000
const PLAYER_COUNTS: Array[int] = [2, 3, 4]
const PAWN_COUNTS: Array[int] = [2, 4, 5]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var board_id: String = args[0] if not args.is_empty() else ""
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH, board_id)
	print("Tahta: %s" % settings.board.id)
	var failed := false
	for players: int in PLAYER_COUNTS:
		for pawns: int in PAWN_COUNTS:
			failed = _run_setup(settings, players, pawns) or failed
	quit(1 if failed else 0)


## Bir kurulumu oynatır, ortalama tur sayısını yazar; tur sınırı aşılırsa true döner.
func _run_setup(settings: GameSettings, players: int, pawns: int) -> bool:
	var total_turns := 0
	var unfinished := 0
	for game_index: int in range(GAMES_PER_SETUP):
		var game := BotRunner.new_game(settings, players, pawns, game_index)
		var bots := BotRunner.same_bots(settings, players, Bot.Level.MEDIUM, game_index)
		var turns := BotRunner.play(game, bots, TURN_LIMIT)
		if turns == BotRunner.UNFINISHED:
			unfinished += 1
		else:
			total_turns += turns
	var finished := GAMES_PER_SETUP - unfinished
	var average := float(total_turns) / maxi(finished, 1)
	var rounds := average / players
	print(
		(
			"%d oyuncu, %d taş: ortalama %.0f hamle (oyuncu başına %.0f tur), bitmeyen %d"
			% [players, pawns, average, rounds, unfinished]
		)
	)
	return unfinished > 0
