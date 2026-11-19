extends SceneTree
## Arayüzü açıp birkaç hamle oynatır ve ekran görüntüleri kaydeder (görsel kontrol için).
## Seçim anı son hamlede kaydedilir; o sırada yolda taş olduğundan yoldaki vurgu da görünür.
## Çalıştırma: godot --path . --resolution 720x1280 -s tools/screenshot.gd -- <çıktı klasörü>

const FRAMES := 10
const HUMAN_MOVES := 15
const PAWNS := 4
const SAVE_PATH := "user://screenshot_save.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	_use_separate_save()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	_save(out_dir.path_join("1a_home.png"))
	main.get_node("Column/HomeScreen").emit_signal("new_game_requested")
	await _frames()
	_save(out_dir.path_join("1b_setup.png"))
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
	DirAccess.remove_absolute(SAVE_PATH)
	quit()


## Gerçek kayıt dosyasını bozmamak için ayrı bir kayıt yolu kullanır.
func _use_separate_save() -> void:
	var store: Node = root.get_node("SaveStore")
	store.set("path", SAVE_PATH)
	store.call("clear_match")


## Botun seçeceği hamleyi arayüzdeki adımlarla oynar. out_dir verilirse seçim anını kaydeder.
func _play_like_bot(screen: Node, out_dir: String) -> void:
	var game: GameMatch = screen.get("_game")
	var bot: Bot = screen.get("_bot")
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


func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("kaydedildi: ", path)
