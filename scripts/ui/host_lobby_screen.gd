class_name HostLobbyScreen
extends MarginContainer
## Ağ oyununu kuran oyuncunun lobi ekranı: oda kodu, oyuncu ve taş sayısı, lobideki oyuncular ve
## hostun rengi. Oda ekran açılınca Wi-Fi adresinde kurulur, geri dönünce kapanır; kurulamazsa
## uyarı gösterilir. Lobi ve oyun sürdükçe ekran kapanmaz. Başla düğmesi en az bir oyuncu
## katılınca açılır; basınca boş koltuklara bot oturur ve oyun hostun kaynağıyla başlar. Oda oyun
## boyunca açık kalır, oyundan çıkınca close_room() ile kapanır.

## Oyuncu lobiden çıktı; oda kapatıldı.
signal closed
## Oyun başladı; oyun ekranı bu kaynaktan çizer.
signal started(source: MatchSource)

## Başla düğmesinin açılması için gereken en az oyuncu sayısı (host dahil).
const MIN_NETWORK_PLAYERS := 2

var _room: HostRoom
var _referee: MatchReferee
var _rng := RandomNumberGenerator.new()

@onready var _code: Label = %Code
@onready var _count: Stepper = %CountStepper
@onready var _pawns: Stepper = %PawnStepper
@onready var _lobby_panel: LobbyPanel = %LobbyPanel
@onready var _room_box: Control = %RoomBox
@onready var _failed: Label = %Failed
@onready var _start: Button = %StartButton


func _ready() -> void:
	_rng.randomize()
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_count.value_changed.connect(_on_count_changed)
	_pawns.value_changed.connect(_on_pawns_changed)
	_lobby_panel.color_chosen.connect(_on_color_chosen)
	_start.pressed.connect(_on_start_pressed)


## Odayı kurar ve yayını başlatır.
func open() -> void:
	close_room()
	_referee = MatchReferee.new()
	_referee.in_game_ads = false
	_referee.turn_time_limit = Tuning.settings.turn_time_limit
	add_child(_referee)
	_room = HostRoom.new(Tuning.settings, _referee, _rng)
	var opened := _room.open(LocalAddress.wifi_address())
	_room_box.visible = opened
	_failed.visible = not opened
	_start.disabled = true
	if not opened:
		return
	_room.lobby.changed.connect(_refresh)
	_room.lobby.code_changed.connect(_show_code)
	_show_code(_room.lobby.code)
	_refresh()
	DisplayServer.screen_set_keep_on(true)


## Odayı ve hakemi kapatır; açık oda yoksa bir şey yapmaz.
func close_room() -> void:
	if _room == null:
		return
	_room.close()
	_room = null
	_referee.stop()
	_referee.queue_free()
	DisplayServer.screen_set_keep_on(false)


func _refresh() -> void:
	var settings := Tuning.settings
	var lobby := _room.lobby
	var info := lobby.info()
	var own_color := info.colors[info.own]
	_count.configure("SET_PLAYERS", lobby.min_seat_count(), settings.max_players, lobby.seat_count)
	_pawns.configure("SET_PAWNS", settings.min_pawns, settings.max_pawns, lobby.pawns, own_color)
	_lobby_panel.show_lobby(info)
	_start.disabled = info.colors.size() < MIN_NETWORK_PLAYERS


## Ağ oyununda oyun kaydedilmez ve oyun içi reklam çıkmaz; hız hostunkidir.
func _on_start_pressed() -> void:
	var game := _room.start_match()
	if game == null:
		return
	_referee.start(game)
	_room.session.speed_level = GameSpeed.current()
	_room.session.share_match()
	var own_seat := game.seats[HostLobby.HOST_INDEX]
	started.emit(RefereeSource.new(_referee, own_seat, _room.lobby.code))


func _show_code(room_code: String) -> void:
	_code.text = room_code


func _on_count_changed(value: int) -> void:
	_room.lobby.set_seat_count(value)


func _on_pawns_changed(value: int) -> void:
	_room.lobby.set_pawns(value)


func _on_color_chosen(color: int) -> void:
	_room.lobby.choose_host_color(color)


func _on_back_pressed() -> void:
	close_room()
	closed.emit()
