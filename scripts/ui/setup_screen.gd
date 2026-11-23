class_name SetupScreen
extends Control
## Yeni oyun ekranı: oyun modu, oyuncu ve taş sayısı seçimi; tek oyunculu modda oyuncunun rengi
## ve bot zorluğu. Ağ modunda seçenekler yerine oyun kurma ve katılma düğmeleri görünür; ağ
## oyununun ayarları lobide seçilir. Tahta seçimi her modda görünür; ağ modunda kurulan oyunun
## tahtasıdır. Kilitli tahta ödüllü reklamla açılır. Tahta kartları yatay kaydırılır; sonda
## "Yakında" kartı durur. Kartların üstünde, altında ve sağında (`BoardRoom`) Yakında kartının
## sallanırken taşan köşelerine yer bırakılır; yoksa kaydırma alanı onları keser.

signal start_requested(bot_flags: Array[bool], pawns: int, bot_level: Bot.Level)
signal back_requested
## Ağ modunda oyun kurulmak istendi.
signal host_requested
## Ağ modunda oyuna katılmak istendi.
signal join_requested

enum Mode { SINGLE, MULTI, NETWORK }

const HINT_KEYS := {
	Mode.SINGLE: "MODE_SINGLE_HINT",
	Mode.MULTI: "MODE_MULTI_HINT",
	Mode.NETWORK: "MODE_NETWORK_HINT",
}
const COUNT_KEYS := {Mode.SINGLE: "SET_BOTS", Mode.MULTI: "SET_PLAYERS"}
## Tek oyunculu modda sayı seçici bot sayısını gösterir; insan oyuncu bir kişidir.
const HUMAN_SEATS := 1
const UNLOCK_PLACEMENT := "unlock_board"
const UNLOCK_ASK_KEY := "BOARD_UNLOCK_ASK"
## Tahta listesinde aynı anda görünen kart sayısı; tam sayı olmadığından sondaki kart kenardan
## taşar ve listenin kaydığı anlaşılır.
const BOARD_CARDS_IN_VIEW := 2.2

var _mode := Mode.SINGLE
## Her modun seçili oyuncu sayısı (insan ve bot birlikte); modlar birbirini etkilemez.
var _player_counts: Dictionary[Mode, int] = {}
var _board_cards: Dictionary[String, BoardCard] = {}
var _unlock: RewardedUnlock
## Parmak tahta kartına değdiğindeki kaydırma konumu; bırakınca farklıysa dokunuş kaydırmadır.
var _board_scroll_at_down := 0

@onready var _mode_hint: Label = %ModeHint
@onready var _game_options: Control = %GameOptions
@onready var _start: Button = %StartButton
@onready var _network_buttons: Control = %NetworkButtons
@onready var _count: Stepper = %CountStepper
@onready var _pawns: Stepper = %PawnStepper
@onready var _difficulty: Control = %DifficultyBox
@onready var _color_box: Control = %ColorBox
@onready var _colors: HBoxContainer = %Colors
@onready var _levels: HBoxContainer = %Levels
@onready var _board_list: HBoxContainer = %BoardCards
@onready var _board_scroll: ScrollContainer = %BoardScroll


func _ready() -> void:
	var settings := Tuning.settings
	_player_counts = {
		Mode.SINGLE: settings.default_bots + HUMAN_SEATS, Mode.MULTI: settings.min_players
	}
	_pawns.configure("SET_PAWNS", settings.min_pawns, settings.max_pawns, settings.default_pawns)
	(%BackButton as Button).pressed.connect(back_requested.emit)
	(%SingleTab as Button).pressed.connect(_set_mode.bind(Mode.SINGLE))
	(%MultiTab as Button).pressed.connect(_set_mode.bind(Mode.MULTI))
	(%NetworkTab as Button).pressed.connect(_set_mode.bind(Mode.NETWORK))
	(%HostButton as Button).pressed.connect(host_requested.emit)
	(%JoinButton as Button).pressed.connect(join_requested.emit)
	_count.value_changed.connect(_on_count_changed)
	_start.pressed.connect(_on_start_pressed)
	_build_color_buttons()
	_build_level_buttons()
	_unlock = RewardedUnlock.new(
		%ConfirmOverlay as ConfirmOverlay, UNLOCK_PLACEMENT, UNLOCK_ASK_KEY
	)
	_build_board_cards()
	_refresh_mode()


func _refresh_mode() -> void:
	var on_network := _mode == Mode.NETWORK
	_mode_hint.text = HINT_KEYS[_mode]
	_game_options.visible = not on_network
	_start.visible = not on_network
	_network_buttons.visible = on_network
	if not on_network:
		_refresh_options()


func _refresh_options() -> void:
	var settings := Tuning.settings
	var offset := _count_offset()
	_difficulty.visible = _mode == Mode.SINGLE
	_color_box.visible = _mode == Mode.SINGLE
	_count.configure(
		COUNT_KEYS[_mode],
		settings.min_players - offset,
		settings.max_players - offset,
		_player_counts[_mode] - offset,
		offset
	)


## Sayı seçicide gösterilen değer ile oyuncu sayısı arasındaki fark.
func _count_offset() -> int:
	return HUMAN_SEATS if _mode == Mode.SINGLE else 0


## Her renk için adı ve taşı olan bir düğme. Seçim oyuncu tercihi olarak hemen saklanır.
func _build_color_buttons() -> void:
	var group := ButtonGroup.new()
	var current := PlayerColor.current()
	for color: int in PlayerColor.colors():
		var button := ChoiceButtons.add_color(_colors, color, group, color == current)
		button.pressed.connect(PlayerColor.select.bind(color))


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


func _build_board_cards() -> void:
	var group := ButtonGroup.new()
	for entry: BoardEntry in Boards.entries():
		var card := BoardCard.new(entry, group)
		card.button_down.connect(_on_board_down)
		card.pressed.connect(_on_board_pressed.bind(entry.id))
		_board_list.add_child(card)
		_board_cards[entry.id] = card
	_board_list.add_child(ComingSoonCard.new(false))
	_board_scroll.resized.connect(_fit_board_cards)
	_refresh_boards()


func _fit_board_cards() -> void:
	var width := _board_scroll.size.x / BOARD_CARDS_IN_VIEW
	for card: Control in _board_list.get_children():
		card.custom_minimum_size.x = width


func _refresh_boards() -> void:
	for id: String in _board_cards:
		var card := _board_cards[id]
		card.set_pressed_no_signal(id == Boards.current_id)
		card.locked = Boards.is_locked(id)


func _on_board_down() -> void:
	_board_scroll_at_down = _board_scroll.scroll_horizontal


## Açık tahta hemen seçilir. Kilitli tahtada seçim eski karta döner ve reklam önerilir.
## Dokunuş liste kaydırmasıysa seçim değişmez.
func _on_board_pressed(id: String) -> void:
	if _board_scroll.scroll_horizontal != _board_scroll_at_down:
		_refresh_boards()
		return
	var locked := Boards.is_locked(id)
	if not locked:
		Boards.select(id)
	_refresh_boards()
	if locked:
		_unlock.request(_on_board_unlocked.bind(id))


## Reklam ödülü verdi: tahta açılıp seçilir.
func _on_board_unlocked(id: String) -> void:
	Boards.unlock(id)
	Boards.select(id)
	_refresh_boards()


## Ağ sekmesini seçili gösterir (ağ oyunu bitince buraya dönülür).
func show_network() -> void:
	(%NetworkTab as Button).button_pressed = true
	_set_mode(Mode.NETWORK)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_refresh_mode()


func _on_count_changed(value: int) -> void:
	_player_counts[_mode] = value + _count_offset()


func _on_start_pressed() -> void:
	var bot_flags: Array[bool] = []
	for index: int in range(_player_counts[_mode]):
		bot_flags.append(_mode == Mode.SINGLE and index >= HUMAN_SEATS)
	start_requested.emit(bot_flags, _pawns.value, Difficulty.current())
