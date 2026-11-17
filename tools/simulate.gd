extends SceneTree
## Botları birbirine karşı oynatıp kural motorunun takılmadan bittiğini denetler.
## Çalıştırma: godot --headless --path . -s tools/simulate.gd

const GAMES_PER_SETUP := 50
const TURN_LIMIT := 5000
const PLAYER_COUNTS: Array[int] = [2, 3, 4]
const PAWN_COUNTS: Array[int] = [2, 4, 5]


func _initialize() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
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
		var turns := _play_game(settings, players, pawns, game_index)
		if turns < 0:
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


func _play_game(settings: GameSettings, players: int, pawns: int, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var flags: Array[bool] = []
	for _i: int in range(players):
		flags.append(true)
	var game := GameMatch.create(settings, flags, pawns, rng)
	for turn: int in range(TURN_LIMIT):
		game.begin_turn()
		var move := Bot.choose_move(game)
		if move == null:
			game.discard(Bot.choose_discard(game.current_hand()))
		else:
			game.play(move)
		if game.winner() != GameMatch.NO_WINNER:
			return turn + 1
		game.next_turn()
	return -1
