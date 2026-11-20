class_name HostLobbyScreen
extends MarginContainer
## Ağ oyununu kuran oyuncunun lobi ekranı: oda kodu, oyuncu ve taş sayısı, lobideki oyuncular ve
## hostun rengi. Oda ekran açılınca Wi-Fi adresinde kurulur, geri dönünce kapanır; kurulamazsa
## uyarı gösterilir. Lobi açıkken ekran kapanmaz. Başlat düğmesi henüz kapalıdır.

## Oyuncu lobiden çıktı; oda kapatıldı.
signal closed

var _room: HostRoom
var _referee: MatchReferee
var _rng := RandomNumberGenerator.new()

@onready var _code: Label = %Code
@onready var _count: Stepper = %CountStepper
@onready var _pawns: Stepper = %PawnStepper
@onready var _lobby_panel: LobbyPanel = %LobbyPanel
@onready var _room_box: Control = %RoomBox
@onready var _failed: Label = %Failed


func _ready() -> void:
	_rng.randomize()
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_count.value_changed.connect(_on_count_changed)
	_pawns.value_changed.connect(_on_pawns_changed)
	_lobby_panel.color_chosen.connect(_on_color_chosen)


## Odayı kurar ve yayını başlatır.
func open() -> void:
	_close_room()
	_referee = MatchReferee.new()
	add_child(_referee)
	_room = HostRoom.new(Tuning.settings, _referee, _rng)
	var opened := _room.open(LocalAddress.wifi_address())
	_room_box.visible = opened
	_failed.visible = not opened
	if not opened:
		return
	_room.lobby.changed.connect(_refresh)
	_room.lobby.code_changed.connect(_show_code)
	_show_code(_room.lobby.code)
	_refresh()
	DisplayServer.screen_set_keep_on(true)


func _close_room() -> void:
	if _room == null:
		return
	_room.close()
	_room = null
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


func _show_code(room_code: String) -> void:
	_code.text = room_code


func _on_count_changed(value: int) -> void:
	_room.lobby.set_seat_count(value)


func _on_pawns_changed(value: int) -> void:
	_room.lobby.set_pawns(value)


func _on_color_chosen(color: int) -> void:
	_room.lobby.choose_host_color(color)


func _on_back_pressed() -> void:
	_close_room()
	closed.emit()
