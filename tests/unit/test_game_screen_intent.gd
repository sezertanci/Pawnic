extends GutTest
## Oyun ekranının hakeme niyet göndermesi: kabul edilen niyette seçim kapanır, reddedilen niyette
## oyuncunun sırası yeniden açılır. Gerçek kayıt dosyasına dokunmamak için ayrı bir yol kullanılır.

const SCREEN_SCENE := preload("res://scenes/game_screen.tscn")
const TEST_PATH := "user://test_game_screen_save.json"
const SEED := 7
const PAWNS := 4
## İlk koltuk insan, ikincisi bot; tek insan olduğundan el devri katmanı açılmaz.
const HUMAN_FIRST: Array[bool] = [false, true]
## Oyuncunun sırasının açılması için beklenecek en uzun süre (saniye).
const TURN_TIMEOUT := 10.0
## Tahtada olmayan taş; bu taşla hamle hiçbir zaman yasal değildir.
const MISSING_PAWN := 99

var _saved_path: String
var _screen: Control
var _game: GameMatch


func before_each() -> void:
	_saved_path = SaveStore.path
	SaveStore.path = TEST_PATH
	SaveStore.reload()
	_screen = SCREEN_SCENE.instantiate()
	add_child_autofree(_screen)
	_game = _new_game()
	_screen.call("start", _game)
	await wait_until(_is_waiting, TURN_TIMEOUT)


func after_each() -> void:
	_screen.get("_referee").call("stop")
	DirAccess.remove_absolute(TEST_PATH)
	SaveStore.path = _saved_path
	SaveStore.reload()


func test_rejected_intent_reopens_human_turn() -> void:
	var move := Move.new(0, Move.Action.FORWARD, MISSING_PAWN, 1)
	var current := _game.current

	_screen.call("_send_intent", MatchIntent.play(_game.current_seat(), move))

	assert_true(_is_waiting())
	assert_eq(_game.current, current)


func test_accepted_intent_closes_selection_and_plays() -> void:
	var legal := _game.legal_moves()
	var intent := (
		MatchIntent.discard(_game.current_seat(), 0)
		if legal.is_empty()
		else MatchIntent.play(_game.current_seat(), legal[0])
	)

	_screen.call("_send_intent", intent)

	assert_false(_is_waiting())
	assert_false(_screen.get("_referee").call("is_awaiting_intent"))


func _new_game() -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, HUMAN_FIRST.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game


func _is_waiting() -> bool:
	return _screen.call("is_waiting_for_human")
