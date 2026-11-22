extends SceneTree
## Arayüzü açıp birkaç hamle oynatır ve ekran görüntüleri kaydeder (görsel kontrol için).
## Seçim anı son hamlede kaydedilir; o sırada yolda taş olduğundan yoldaki vurgu da görünür.
## Çalıştırma: godot --path . --resolution 720x1280 -s tools/screenshot.gd -- <klasör> [kaplama]
## [tahta]
## Kaplama verilirse (ör. wood) kilidi açılır ve görüntüler o kaplamayla alınır. Tahta verilirse
## (ör. four_leaf) o da açılıp seçilir. Son görüntüdeki
## tahta ayrıca kırpılıp board_preview.png olarak kaydedilir; bu, görünüm ekranındaki kartın
## görselidir.

const FRAMES := 10
const HUMAN_MOVES := 15
const PAWNS := 4
const SAVE_PATH := "user://screenshot_save.json"
## Görünüm ekranı kartı için kırpılan tahta görselinin genişliği (piksel).
const PREVIEW_WIDTH := 640
const PREVIEW_FILE := "board_preview.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	_use_separate_save()
	if args.size() > 1:
		root.get_node("Skins").call("unlock", args[1])
		root.get_node("Skins").call("select", args[1])
	if args.size() > 2:
		root.get_node("Boards").call("unlock", args[2])
		root.get_node("Boards").call("select", args[2])
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	_save(out_dir.path_join("1a_home.png"))
	main.get_node("Column/HomeScreen").emit_signal("appearance_requested")
	await _frames()
	_save(out_dir.path_join("1e_appearance.png"))
	main.get_node("Column/SkinScreen").emit_signal("back_requested")
	main.get_node("Column/HomeScreen").emit_signal("new_game_requested")
	await _frames()
	_save(out_dir.path_join("1b_setup.png"))
	await _capture_network(main, out_dir)
	var bot_flags: Array[bool] = [false, true, true, true]
	main.get_node("Column/SetupScreen").emit_signal(
		"start_requested", bot_flags, PAWNS, Bot.Level.MEDIUM
	)
	var screen: Node = main.get_node("Column/GameScreen")
	for step: int in range(HUMAN_MOVES):
		await _wait_for_human(screen)
		await _play_like_bot(screen, out_dir if step == HUMAN_MOVES - 1 else "")
	await _wait_for_human(screen)
	_save(out_dir.path_join("3_board.png"))
	_save_board_preview(screen.get_node("%BoardView") as Control, out_dir.path_join(PREVIEW_FILE))
	DirAccess.remove_absolute(SAVE_PATH)
	quit()


## Kurulumun ağ sekmesini, host lobisini ve katılma ekranını kaydeder; sonra kuruluma döner.
func _capture_network(main: Control, out_dir: String) -> void:
	var setup := main.get_node("Column/SetupScreen")
	var tab: Button = setup.get_node("%NetworkTab")
	tab.button_pressed = true
	tab.emit_signal("pressed")
	await _frames()
	_save(out_dir.path_join("1c_setup_network.png"))
	for step: Array in [["host_requested", "HostLobbyScreen"], ["join_requested", "JoinScreen"]]:
		setup.emit_signal(step[0])
		await _frames()
		_save(out_dir.path_join("1d_%s.png" % (step[1] as String).to_snake_case()))
		var screen := main.get_node("Column").get_node(step[1] as String)
		(screen.get_node("%BackButton") as Button).emit_signal("pressed")
		await _frames()


## Gerçek kayıt dosyasını bozmamak için ayrı bir kayıt yolu kullanır.
func _use_separate_save() -> void:
	var store: Node = root.get_node("SaveStore")
	store.set("path", SAVE_PATH)
	store.call("clear_match")


## Botun seçeceği hamleyi arayüzdeki adımlarla oynar. out_dir verilirse seçim anını kaydeder.
func _play_like_bot(screen: Node, out_dir: String) -> void:
	var game: GameMatch = screen.get("_game")
	var referee: Node = screen.get("_referee")
	var bot: Bot = referee.get("_bot")
	var move := bot.choose_move(game)
	if move == null:
		screen.call("_on_card_pressed", 0)
		return
	screen.call("_on_card_pressed", move.card_index)
	var picker: MovePicker = screen.get("_picker")
	if picker.stage == MovePicker.Stage.VALUE:
		screen.call("_on_value_pressed", move.card_index, move.value)
	await _frames()
	if not out_dir.is_empty():
		_save(out_dir.path_join("2_pick.png"))
	screen.call("_on_pawn_pressed", move.pawn)
	if move.target != Move.NO_PAWN:
		screen.call("_on_pawn_pressed", move.target)
	if picker.stage == MovePicker.Stage.DESTINATION:
		screen.call("_on_square_pressed", move.destination)


func _wait_for_human(screen: Node) -> void:
	while not screen.call("is_waiting_for_human"):
		await process_frame
	await _frames()


func _frames() -> void:
	for _i: int in range(FRAMES):
		await process_frame


## Tahtanın ekrandaki alanını kırpıp PREVIEW_WIDTH genişliğe küçülterek kaydeder.
func _save_board_preview(board: Control, path: String) -> void:
	var image := root.get_texture().get_image()
	var scale := Vector2(image.get_size()) / root.get_visible_rect().size
	var rect := board.get_global_rect()
	var region := Rect2i(Vector2i(rect.position * scale), Vector2i(rect.size * scale))
	var preview := image.get_region(region)
	var height := roundi(PREVIEW_WIDTH * float(region.size.y) / region.size.x)
	preview.resize(PREVIEW_WIDTH, height, Image.INTERPOLATE_LANCZOS)
	preview.save_png(path)
	print("kaydedildi: ", path)


func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("kaydedildi: ", path)
