extends SceneTree
## Play mağazası için 8 ham ekran görüntüsü üretir (başlıksız); başlıkları
## tools/make_store_screenshots.py bindirir. Tahta ekranları elle kurulmuş oyun durumlarıyla
## çizilir: çeşitli kartlı bir el, vurulabilecek ve kalkanda duran rakipler, süreli ağ oyunu ve
## sonuç tablosu. Ağ ekranları için bilgisayarda yerel ağ adresi olmalıdır.
## Ekrandan büyük boyutlar için pencere kenarlıksız açılır (yoksa ekran yüksekliğiyle sınırlanır).
## Çalıştırma: godot --path . -s tools/store_screenshots.gd -- <klasör> <dil> <genişlik>x<yükseklik>

const FRAMES := 10
const SAVE_PATH := "user://screenshot_save.json"
const PAWNS := 4
## Ana ekranın, kurulumun ve oyun ekranının düğüm yolları.
const HOME := "Column/HomeScreen"
const SETUP := "Column/SetupScreen"
const GAME := "Column/GameScreen"
const HOST_LOBBY := "Column/HostLobbyScreen"
## Autoload kullanan sınıflar betik derlenirken tanınmadığı için çalışırken yüklenir.
const RULE_LIST_SCRIPT := "res://scripts/ui/rule_list.gd"
const REFEREE_SOURCE_SCRIPT := "res://scripts/match/referee_source.gd"
const HOST_LOBBY_SCRIPT := "res://scripts/match/host_lobby.gd"
## Bir şey takılırsa araç bu süreden sonra kapanır.
const TIME_LIMIT := 120.0
## İnsan oyuncu, oyun kurulurken ilk sıradaki (alttaki) koltuktur.
const HUMAN := 0
## Kartlar grubu Nasıl Oynanır listesinin üçüncü grubudur.
const CARDS_GROUP := 2
## Başlık şeridi ve geçişi (make_store_screenshots.py'deki BAND_HEIGHT + FADE_HEIGHT), ekran
## yüksekliğine oranla; kurallar paneli başlığı şeridin altında kalmasın diye bu kadar aşağı iner.
const CAPTION_SPACE := 0.135
## Lobiye katılmış gibi gösterilen eşlerin kimlikleri.
const FAKE_PEERS: Array[int] = [1001, 1002, 1003]
## Kurulumda varsayılan tek bota eklenen bot sayısı.
const EXTRA_BOTS := 2
## Oyunun ortasında atılanlar destesinde görünen kart sayısı.
const DISCARDED := 14
## Oyunun ortasında görünmesi için saat ve tur.
const ELAPSED := 372.0
const ROUND := 9
## Süreli ekranda süre çubuğunun bir kısmı azalmış görünsün diye beklenen süre.
const TIMER_WAIT := 6.0
## Sonuç tablosunda konfetinin ekrana yayılması için beklenen süre.
const CONFETTI_WAIT := 0.8
## Sonuç tablosu: bitirenler ve bitirdikleri turlar (koltuk sırasıyla değil, bitirme sırasıyla).
const FINISHERS: Array[int] = [2, 3, 0]
const FINISH_ROUNDS: Array[int] = [18, 19, 21]

## Taş konumları, taş sırasıyla (her koltuğun 4 taşı: koltuk 2, 3, 0, 1). Boş metin üstte
## bekleyen (başlangıçtaki) taştır.
const BOARD_PICK: Array[String] = [
	"ring:38",
	"ring:45",
	"",
	"lane2:2",
	"ring:52",
	"ring:55",
	"",
	"",
	"ring:15",
	"ring:3",
	"",
	"",
	"ring:29",
	"ring:33",
	"ring:25",
	"",
]
const BOARD_CAPTURE: Array[String] = [
	"ring:40",
	"ring:31",
	"",
	"lane2:1",
	"ring:47",
	"ring:43",
	"",
	"",
	"ring:15",
	"ring:10",
	"",
	"",
	"ring:29",
	"ring:24",
	"",
	"",
]

## Ellerdeki kartlar; son kart turun başında çekilen karttır.
const HAND_PICK: Array[Card.Type] = [
	Card.Type.JOKER, Card.Type.SWAP, Card.Type.SEND_BACK, Card.Type.FORWARD
]
const HAND_CAPTURE: Array[Card.Type] = [
	Card.Type.EXIT, Card.Type.SHORTCUT, Card.Type.BACK, Card.Type.FORWARD
]
## Çekilen ileri kartının değeri: seçimde ve vurmada taşı rakibin üstüne getirir.
const PICK_FORWARD := 5
const CAPTURE_FORWARD := 7

var _out_dir := ""


func _initialize() -> void:
	create_timer(TIME_LIMIT).timeout.connect(_give_up)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0]
	TranslationServer.set_locale(args[1])
	var size := args[2].split("x")
	root.borderless = true
	root.size = Vector2i(int(size[0]), int(size[1]))
	var store: Node = root.get_node("SaveStore")
	store.set("path", SAVE_PATH)
	store.call("clear_match")
	await _capture_home()
	await _capture_setup()
	await _capture_board("03-board.png", BOARD_PICK, HAND_PICK, PICK_FORWARD)
	await _capture_board("04-capture.png", BOARD_CAPTURE, HAND_CAPTURE, CAPTURE_FORWARD)
	await _capture_rules()
	await _capture_lobby()
	await _capture_timed()
	await _capture_result()
	DirAccess.remove_absolute(SAVE_PATH)
	quit()


func _capture_home() -> void:
	var main := await _open_main()
	_save("01-home.png")
	await _close_main(main)


func _capture_setup() -> void:
	var main := await _open_main()
	main.get_node(HOME).emit_signal("new_game_requested")
	await _frames()
	var setup := main.get_node(SETUP)
	var plus: Button = setup.get_node("%CountStepper").get_node("%Plus")
	for _i: int in range(EXTRA_BOTS):
		plus.emit_signal("pressed")
	# Seviye tercih olarak saklanmasın diye yalnızca düğme seçili gösterilir.
	for level: Button in setup.get_node("%Levels").get_children():
		level.set_pressed_no_signal(level.get_index() == Bot.Level.HARD)
	await _frames()
	_save("02-setup.png")
	await _close_main(main)


## Kurulmuş tahtada insanın sırası gelince çekilen ileri kartı seçilir; oynanabilecek taşlar
## ve gidecekleri yer vurgulanır.
func _capture_board(
	file_name: String, positions: Array[String], hand: Array[Card.Type], forward: int
) -> void:
	var main := await _open_main()
	var game := _make_game(positions, hand, forward)
	main.call("_begin", game)
	var screen := main.get_node(GAME)
	await _wait_for_human(screen)
	screen.call("_on_card_pressed", hand.size() - 1)
	await _frames()
	_save(file_name)
	await _close_main(main)


func _capture_rules() -> void:
	var main := await _open_main()
	var home := main.get_node(HOME)
	home.call("show_rules")
	var margin: MarginContainer = home.get_node("%RulesOverlay/Margin")
	margin.add_theme_constant_override("margin_top", int(root.size.y * CAPTION_SPACE))
	var rules: Node = home.get_node("%RuleList")
	rules.call("_on_toggle_requested", rules.get_child(CARDS_GROUP))
	await _frames()
	_save("05-rules.png")
	await _close_main(main)


func _capture_lobby() -> void:
	var main := await _open_lobby()
	_save("06-lobby.png")
	_close_lobby(main)
	await _close_main(main)


## Hostun oyunu kurulmuş tahtayla başlar; sıra hosttadır ve süre çubuğu azalmaya başlamıştır.
func _capture_timed() -> void:
	var main := await _open_lobby()
	var lobby_screen := main.get_node(HOST_LOBBY)
	var room: Object = lobby_screen.get("_room")
	var game: GameMatch = room.call("start_match")
	_arrange(game, BOARD_PICK, HAND_PICK, PICK_FORWARD)
	var referee: Node = lobby_screen.get("_referee")
	referee.call("start", game)
	var own_seat := game.seats[load(HOST_LOBBY_SCRIPT).get("HOST_INDEX")]
	var lobby: Object = room.get("lobby")
	var source: Object = load(REFEREE_SOURCE_SCRIPT).new(
		referee, own_seat, lobby.get("code"), room.get("session")
	)
	main.set("_network", true)
	main.call("_show_only", main.get_node(GAME))
	var screen := main.get_node(GAME)
	screen.call("start_source", source, false)
	await _wait_for_human(screen)
	await create_timer(TIMER_WAIT).timeout
	_save("07-timed.png")
	_close_lobby(main)
	await _close_main(main)


func _capture_result() -> void:
	var main := await _open_main()
	var game := _make_game(BOARD_PICK, HAND_PICK, PICK_FORWARD)
	main.call("_begin", game)
	var screen := main.get_node(GAME)
	await _wait_for_human(screen)
	var view: Object = screen.get("_view")
	(view.get("finishers") as Array).assign(FINISHERS)
	(view.get("finish_rounds") as Array).assign(FINISH_ROUNDS)
	screen.call("_end_match")
	await create_timer(CONFETTI_WAIT).timeout
	_save("08-result.png")
	await _close_main(main)


## Host lobisini açar ve sahte eşleri katılmış gibi ekler.
func _open_lobby() -> Control:
	var main := await _open_main()
	main.get_node(HOME).emit_signal("new_game_requested")
	await _frames()
	main.get_node(SETUP).emit_signal("host_requested")
	await _frames()
	var room: Object = main.get_node(HOST_LOBBY).get("_room")
	for peer: int in FAKE_PEERS:
		room.get("lobby").call("_on_welcomed", peer)
	await _frames()
	return main


func _close_lobby(main: Control) -> void:
	main.get_node(HOST_LOBBY).call("close_room")


## Bir insan ve üç botla oyun kurar ve durumunu verilen konumlara ve ele göre ayarlar.
func _make_game(positions: Array[String], hand: Array[Card.Type], forward: int) -> GameMatch:
	var bot_flags: Array[bool] = [false, true, true, true]
	var rng := RandomNumberGenerator.new()
	var game := GameMatch.create(_settings(), bot_flags, PAWNS, rng)
	_arrange(game, positions, hand, forward)
	return game


## Taşları yerleştirir, insanın elini ve çekeceği kartı koyar; sıra insandadır.
func _arrange(
	game: GameMatch, positions: Array[String], hand: Array[Card.Type], forward: int
) -> void:
	var layout := game.board.layout
	for pawn: int in range(positions.size()):
		var square := positions[pawn]
		game.board.positions[pawn] = (
			BoardState.BASE if square.is_empty() else layout.index_of(square)
		)
	var cards: Array[Card] = game.hands[HUMAN]
	cards.clear()
	for card_type: Card.Type in hand.slice(0, hand.size() - 1):
		cards.append(load(RULE_LIST_SCRIPT).call("sample_card", card_type, game.settings))
	var draw_pile: Array[Card] = game.get("_draw_pile")
	var discard_pile: Array[Card] = game.get("_discard_pile")
	for _i: int in range(DISCARDED):
		discard_pile.append(draw_pile.pop_back())
	draw_pile.append(Card.new(hand.back(), forward))
	game.starter = HUMAN
	game.elapsed = ELAPSED
	game.round_number = ROUND


func _open_main() -> Control:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	return main


func _close_main(main: Control) -> void:
	main.queue_free()
	await _frames()


func _wait_for_human(screen: Node) -> void:
	while not screen.call("is_waiting_for_human"):
		await process_frame
	await _frames()


func _frames() -> void:
	for _i: int in range(FRAMES):
		await process_frame


func _save(file_name: String) -> void:
	var path := _out_dir.path_join(file_name)
	root.get_texture().get_image().save_png(path)
	print("kaydedildi: ", path)


## Autoload'lar betik derlenirken tanınmadığı için ayarlar düğümden okunur.
func _settings() -> GameSettings:
	return root.get_node("Tuning").get("settings")


func _give_up() -> void:
	push_error("Süre doldu, araç kapanıyor.")
	quit(1)
