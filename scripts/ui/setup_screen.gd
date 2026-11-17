class_name SetupScreen
extends MarginContainer
## Yeni oyun ekranı: oyun modu, oyuncu ve taş sayısı seçimi.

signal start_requested(bot_flags: Array[bool], pawns: int)
signal back_requested

enum Mode { SINGLE, MULTI }

const MODE_KEYS := {Mode.SINGLE: "MODE_SINGLE", Mode.MULTI: "MODE_MULTI"}
const COUNT_KEYS := {Mode.SINGLE: "SET_BOTS", Mode.MULTI: "SET_PLAYERS"}
## Tek oyunculu modda sayı seçici bot sayısını gösterir; insan oyuncu bir kişidir.
const HUMAN_SEATS := 1

var _mode := Mode.SINGLE
var _player_count := 0

@onready var _mode_button: Button = %ModeButton
@onready var _count: Stepper = %CountStepper
@onready var _pawns: Stepper = %PawnStepper


func _ready() -> void:
	var settings := Tuning.settings
	_player_count = settings.min_players
	_pawns.configure("SET_PAWNS", settings.min_pawns, settings.max_pawns, settings.default_pawns)
	(%BackButton as Button).pressed.connect(back_requested.emit)
	_mode_button.pressed.connect(_on_mode_pressed)
	_count.value_changed.connect(_on_count_changed)
	(%StartButton as Button).pressed.connect(_on_start_pressed)
	_refresh_mode()


func _refresh_mode() -> void:
	var settings := Tuning.settings
	var offset := _count_offset()
	_mode_button.text = MODE_KEYS[_mode]
	_count.configure(
		COUNT_KEYS[_mode],
		settings.min_players - offset,
		settings.max_players - offset,
		_player_count - offset
	)


## Sayı seçicide gösterilen değer ile oyuncu sayısı arasındaki fark.
func _count_offset() -> int:
	return HUMAN_SEATS if _mode == Mode.SINGLE else 0


func _on_mode_pressed() -> void:
	_mode = Mode.MULTI if _mode == Mode.SINGLE else Mode.SINGLE
	_refresh_mode()


func _on_count_changed(value: int) -> void:
	_player_count = value + _count_offset()


func _on_start_pressed() -> void:
	var bot_flags: Array[bool] = []
	for index: int in range(_player_count):
		bot_flags.append(_mode == Mode.SINGLE and index >= HUMAN_SEATS)
	start_requested.emit(bot_flags, _pawns.value)
