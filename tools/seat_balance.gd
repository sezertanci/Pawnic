extends SceneTree
## Renkler arasında tahtadan (hız ve güvenli karelerin yerinden) gelen avantaj var mı diye ölçer.
## Her kurulumda çok sayıda bot oyunu oynatır; ilk oynayan oyuncu oyundan oyuna sırayla değişir ki
## ölçülen fark oynama sırasından değil, renkten gelsin. Her rengin kazanma oranı eşit payla
## karşılaştırılır; ayrıca ilk oynamanın avantajı da yazılır.
## Çalıştırma: godot --headless --path . -s tools/seat_balance.gd

const BotRunner := preload("res://tools/bot_runner.gd")
const GAMES_PER_SETUP := 2000
const TURN_LIMIT := 5000
const PAWNS := 4
const PLAYER_COUNTS: Array[int] = [2, 4]
## Eşit paydan bu kadar standart hatadan fazla sapan oran anlamlı fark sayılır (yaklaşık %95 güven).
const SIGNIFICANCE := 2.0
const COLOR_NAMES: Array[String] = ["Kırmızı", "Mavi", "Yeşil", "Sarı"]
const PERCENT := 100.0


func _initialize() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	for players: int in PLAYER_COUNTS:
		_run_setup(settings, players)
	quit()


func _run_setup(settings: GameSettings, players: int) -> void:
	var seat_wins: Dictionary[int, int] = {}
	var order_wins: Array[int] = []
	order_wins.resize(players)
	order_wins.fill(0)
	var finished := 0
	for game_index: int in range(GAMES_PER_SETUP):
		var game := BotRunner.new_game(settings, players, PAWNS, game_index)
		var starter := game_index % players
		game.starter = starter
		var bots := BotRunner.same_bots(settings, players, Bot.Level.MEDIUM, game_index)
		if BotRunner.play(game, bots, TURN_LIMIT) == BotRunner.UNFINISHED:
			continue
		finished += 1
		var winner := game.winner()
		seat_wins[winner] = seat_wins.get(winner, 0) + 1
		var order := posmod(game.seats.find(winner) - starter, players)
		order_wins[order] += 1
	print("\n%d oyuncu, %d taş, %d oyun (biten %d):" % [players, PAWNS, GAMES_PER_SETUP, finished])
	var seat_counts: Array[int] = []
	var seat_names: Array[String] = []
	for seat: int in GameMatch.SEAT_ORDER[players]:
		seat_counts.append(seat_wins.get(seat, 0))
		seat_names.append(COLOR_NAMES[seat])
	_print_rates("Renk", seat_names, seat_counts, finished)
	var order_names: Array[String] = []
	for order: int in range(players):
		order_names.append("%d. oynayan" % (order + 1))
	_print_rates("Sıra", order_names, order_wins, finished)


## Her satırın kazanma oranını, eşit paydan sapmasını ve sapmanın anlamlı olup olmadığını yazar.
func _print_rates(title: String, names: Array[String], counts: Array[int], total: int) -> void:
	var fair := 1.0 / names.size()
	var error := sqrt(fair * (1.0 - fair) / maxi(total, 1))
	print(
		(
			"  %s (eşit pay %%%.1f, anlamlı sapma ±%.1f puan):"
			% [title, fair * PERCENT, SIGNIFICANCE * error * PERCENT]
		)
	)
	for index: int in range(names.size()):
		var rate := float(counts[index]) / maxi(total, 1)
		var gap := rate - fair
		var mark := "  <-- anlamlı" if absf(gap) > SIGNIFICANCE * error else ""
		print("    %-12s %%%.1f (%+.1f)%s" % [names[index], rate * PERCENT, gap * PERCENT, mark])
