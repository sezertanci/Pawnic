class_name JoinScreen
extends MarginContainer
## Ağ oyununa katılma ekranı. Önce yerel ağda bulunan oyunlar listelenir; seçilen oyun için oda
## kodu girilir, sonra hosta bağlanılır ve lobi gösterilir. Host reddederse nedeni yazılıp koda
## dönülür; bağlantı koparsa nedeni yazılıp listeye dönülür. Host oyunu başlatınca ilk görünüm
## gelir ve oyun kaynağı verilir. Ekran açıkken kapanmaz.

## Oyuncu ekrandan çıktı; arama ve bağlantı kapatıldı.
signal closed
## Host oyunu başlattı; ilk görünüm geldi.
signal started(source: MatchSource)

enum Stage { SEARCH, CODE, CONNECTING, LOBBY }

const REFUSAL_KEYS := {
	MatchMessage.Refusal.VERSION_MISMATCH: "REFUSED_VERSION",
	MatchMessage.Refusal.WRONG_CODE: "REFUSED_WRONG_CODE",
	MatchMessage.Refusal.ROOM_FULL: "REFUSED_ROOM_FULL",
	MatchMessage.Refusal.MATCH_STARTED: "REFUSED_MATCH_STARTED",
}
const CONNECTION_FAILED_KEY := "CONNECTION_FAILED"
## Oyun bulma portu açılamadı (ör. başka bir uygulama tutuyor).
const SEARCH_FAILED_KEY := "SEARCH_FAILED"

var _stage := Stage.SEARCH
var _finder: GameFinder
var _room: GuestRoom
## Odanın oyun kaynağı; oyun başlamadan önce kurulur ki ilk görünüm ve olaylar kaçmasın.
var _source: ClientSource
var _address := ""

@onready var _search_box: Control = %SearchBox
@onready var _games: VBoxContainer = %Games
@onready var _searching: Label = %Searching
@onready var _code_box: Control = %CodeBox
@onready var _code_field: LineEdit = %CodeField
@onready var _join: Button = %JoinButton
@onready var _status: Label = %Status
@onready var _lobby_panel: LobbyPanel = %LobbyPanel
@onready var _message: Label = %Message


func _ready() -> void:
	_code_field.max_length = Tuning.settings.room_code_digits
	_code_field.text_changed.connect(_on_code_changed)
	_join.pressed.connect(_on_join_pressed)
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_lobby_panel.color_chosen.connect(_on_color_chosen)


## Oyun aramaya başlar.
func open() -> void:
	close()
	_finder = GameFinder.new(Tuning.settings)
	_finder.games_changed.connect(_show_games)
	_show_message("" if _finder.start() else SEARCH_FAILED_KEY)
	_show_games()
	_set_stage(Stage.SEARCH)
	DisplayServer.screen_set_keep_on(true)


## Aramayı ve bağlantıyı kapatır; ağ oyunu bitince de çağrılır.
func close() -> void:
	_source = null
	var was_open := _room != null or _finder != null
	if _room != null:
		_room.close()
		_room = null
	_stop_search()
	if was_open:
		DisplayServer.screen_set_keep_on(false)


## Oyun bulma portu bırakılır; oyun başlayınca aranmaz, aynı cihazdaki başka pencere arayabilir.
func _stop_search() -> void:
	if _finder != null:
		_finder.stop()
		_finder = null


func _set_stage(stage: Stage) -> void:
	_stage = stage
	_search_box.visible = stage == Stage.SEARCH
	_code_box.visible = stage == Stage.CODE
	_lobby_panel.visible = stage == Stage.LOBBY
	_status.visible = stage == Stage.CONNECTING or stage == Stage.LOBBY
	_status.text = "CONNECTING" if stage == Stage.CONNECTING else "WAITING_FOR_HOST"


func _show_message(key: String) -> void:
	_message.text = key
	_message.visible = not key.is_empty()


## Bulunan oyunlar sırayla numaralanır; adres gösterilmez.
func _show_games() -> void:
	for child: Node in _games.get_children():
		child.queue_free()
	var found := _finder.games()
	_searching.visible = found.is_empty() and _finder.is_listening()
	for index: int in range(found.size()):
		var button := Button.new()
		button.theme_type_variation = ChoiceButtons.BUTTON_TYPE
		button.text = tr("FOUND_GAME") % [index + 1, found[index].players]
		button.pressed.connect(_on_game_chosen.bind(found[index].address))
		_games.add_child(button)


func _on_game_chosen(address: String) -> void:
	_address = address
	_code_field.clear()
	_join.disabled = true
	_show_message("")
	_set_stage(Stage.CODE)
	_code_field.grab_focus()


func _on_code_changed(text: String) -> void:
	_join.disabled = text.length() != Tuning.settings.room_code_digits or not text.is_valid_int()


## Eski oda yenisi kurulunca bırakılır; kendi sinyali içindeyken bırakılmaz.
func _on_join_pressed() -> void:
	_show_message("")
	_room = GuestRoom.new(Tuning.settings)
	_room.refused.connect(_on_refused)
	_room.lost.connect(_on_lost)
	_room.session.lobby_changed.connect(_on_lobby_changed)
	_source = ClientSource.new(_room)
	_source.view_reset.connect(_on_match_started.bind(_source), CONNECT_ONE_SHOT)
	if _room.join(_address, _code_field.text):
		_set_stage(Stage.CONNECTING)
	else:
		_show_message(CONNECTION_FAILED_KEY)


func _on_lobby_changed(info: LobbyInfo) -> void:
	_lobby_panel.show_lobby(info)
	_set_stage(Stage.LOBBY)


func _on_match_started(source: ClientSource) -> void:
	if source == _source:
		_stop_search()
		started.emit(source)


func _on_color_chosen(color: int) -> void:
	_room.session.choose_color(color)


func _on_refused(reason: int) -> void:
	_show_message(REFUSAL_KEYS.get(reason, CONNECTION_FAILED_KEY))
	_code_field.clear()
	_join.disabled = true
	_set_stage(Stage.CODE)


func _on_lost(was_welcomed: bool) -> void:
	_show_message("GAME_ENDED" if was_welcomed else CONNECTION_FAILED_KEY)
	_set_stage(Stage.SEARCH)


func _on_back_pressed() -> void:
	if _stage == Stage.CODE:
		_show_message("")
		_set_stage(Stage.SEARCH)
		return
	close()
	closed.emit()
