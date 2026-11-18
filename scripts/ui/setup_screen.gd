class_name SetupScreen
extends MarginContainer
## Yeni oyun ekranı: oyun modu, oyuncu ve taş sayısı seçimi; tek oyunculu modda bot zorluğu.

signal start_requested(bot_flags: Array[bool], pawns: int, bot_level: Bot.Level)
signal back_requested

enum Mode { SINGLE, MULTI }

const HINT_KEYS := {Mode.SINGLE: "MODE_SINGLE_HINT", Mode.MULTI: "MODE_MULTI_HINT"}
const COUNT_KEYS := {Mode.SINGLE: "SET_BOTS", Mode.MULTI: "SET_PLAYERS"}
## Tek oyunculu modda sayı seçici bot sayısını gösterir; insan oyuncu bir kişidir.
const HUMAN_SEATS := 1

var _mode := Mode.SINGLE
var _player_count := 0

@onready var _mode_hint: Label = %ModeHint
@onready var _count: Stepper = %CountStepper
@onready var _pawns: Stepper = %PawnStepper
@onready var _difficulty: Control = %DifficultyBox
@onready var _levels: HBoxContainer = %Levels


func _ready() -> void:
	var settings := Tuning.settings
	_player_count = settings.min_players
	_pawns.configure("SET_PAWNS", settings.min_pawns, settings.max_pawns, settings.default_pawns)
	(%BackButton as Button).pressed.connect(back_requested.emit)
	(%SingleTab as Button).pressed.connect(_set_mode.bind(Mode.SINGLE))
	(%MultiTab as Button).pressed.connect(_set_mode.bind(Mode.MULTI))
	_count.value_changed.connect(_on_count_changed)
	(%StartButton as Button).pressed.connect(_on_start_pressed)
	_build_level_buttons()
	_refresh_mode()


func _refresh_mode() -> void:
	var settings := Tuning.settings
	var offset := _count_offset()
	_mode_hint.text = HINT_KEYS[_mode]
	_difficulty.visible = _mode == Mode.SINGLE
	_count.configure(
		COUNT_KEYS[_mode],
		settings.min_players - offset,
		settings.max_players - offset,
		_player_count - offset,
		offset
	)


## Sayı seçicide gösterilen değer ile oyuncu sayısı arasındaki fark.
func _count_offset() -> int:
	return HUMAN_SEATS if _mode == Mode.SINGLE else 0


## Seçim oyuncu tercihi olarak hemen saklanır; sonraki yeni oyunda da seçili gelir.
func _build_level_buttons() -> void:
	var group := ButtonGroup.new()
	var current := Difficulty.current()
	for level: Bot.Level in Bot.Level.values():
		var button := ChoiceButtons.add(
			_levels, Difficulty.level_key(level), group, level == current
		)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(Difficulty.select.bind(level))


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_refresh_mode()


func _on_count_changed(value: int) -> void:
	_player_count = value + _count_offset()


func _on_start_pressed() -> void:
	var bot_flags: Array[bool] = []
	for index: int in range(_player_count):
		bot_flags.append(_mode == Mode.SINGLE and index >= HUMAN_SEATS)
	start_requested.emit(bot_flags, _pawns.value, Difficulty.current())
