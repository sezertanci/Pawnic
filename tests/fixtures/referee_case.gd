extends GutTest
## Hakem (MatchReferee) testlerinin ortak kurulumu ve yardımcıları. Gerçek kayıt dosyasına
## dokunmamak için ayrı bir yol kullanılır.

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_referee_save.json"
const SEED := 7
const PAWNS := 4
const HUMANS: Array[bool] = [false, false]
const BOT_FIRST: Array[bool] = [true, false]
## Bot turunun bitmesi için beklenecek en uzun süre (saniye).
const BOT_TIMEOUT := 10.0
## Saatin durduğunu görmek için beklenen kare sayısı.
const FRAMES := 3
const EXIT_VALUE := 0
## Taşlar başlangıçtayken geri kartıyla oynanacak hamle yoktur.
const BACK_VALUE := 3
## Testlerdeki sıra süresi (saniye); kısa olanı testin içinde dolar.
const TURN_TIME := 20.0
const SHORT_TURN_TIME := 0.1

var _store: SaveStoreScript
var _referee: MatchReferee
var _events: Array[MatchEvent] = []
## true iken her olay hemen bitirilmiş sayılır (ekranın animasyonsuz hâli).
var _auto_ack := true


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()
	_events.clear()
	_auto_ack = true
	_referee = MatchReferee.new()
	_referee.store = _store
	_referee.event_emitted.connect(_on_event)
	add_child_autofree(_referee)


func after_each() -> void:
	_referee.stop()
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func _new_game(bot_flags: Array[bool]) -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, bot_flags.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game


func _start(game: GameMatch) -> void:
	_referee.start(game)
	_referee.begin()


## Sıradaki oyuncunun elini çıkış kartlarıyla doldurur; böylece yasal hamle kesin vardır.
func _give_exit_cards(game: GameMatch) -> void:
	_fill_hand(game.current_hand(), Card.Type.EXIT, EXIT_VALUE)


func _fill_hand(hand: Array[Card], type: Card.Type, value: int) -> void:
	for index: int in range(hand.size()):
		hand[index] = Card.new(type, value)


func _kinds() -> Array:
	return _events.map(func(event: MatchEvent) -> MatchEvent.Kind: return event.kind)


func _on_event(event: MatchEvent) -> void:
	_events.append(event)
	if _auto_ack:
		_referee.acknowledge()
