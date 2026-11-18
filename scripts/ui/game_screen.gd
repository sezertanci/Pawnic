class_name GameScreen
extends Control
## Oyun ekranı: sıra akışı, botların oynaması ve oyuncunun dokunarak hamle seçmesi.
## Her sıranın başında oyun kaydedilir; oyun bitince kayıt silinir.

## Oyun bitip oyuncu kutlama ekranından ana ekrana dönmek istediğinde gelir.
signal finished
## Oyun bitip oyuncu aynı ayarlarla yeniden oynamak istediğinde gelir.
signal replay_requested(bot_flags: Array[bool], pawns: int, bot_level: Bot.Level)
## Oyuncu geri düğmesiyle ana ekrana döndüğünde gelir; oyun kayıtlı kalır.
signal left

const SECONDS_PER_MINUTE := 60
const SECONDS_PER_HOUR := 3600
## Joker sayı kartlarının eldeki kartlara göre boyu.
const JOKER_CARD_SCALE := 0.7

var _game: GameMatch
## Bütün bot oyuncuların ortak botu; seviyesi oyunla birlikte kaydedilir.
var _bot: Bot
## Oyun sürerken true; geçen süre yalnızca bu sırada sayılır.
var _clock_running := false
var _picker := MovePicker.new()
## Sıra devrinde oyuncunun çektiği kart; eli açılınca desteden uçarak gelir.
var _handoff_drew := false
## Oyuncunun dokunmasını bekleyen an; kart ya da taş uçarken false.
var _awaiting_human := false

@onready var _clock: Label = %Clock
@onready var _bot_level: Label = %BotLevel
@onready var _turn_dots: TurnDots = %TurnDots
@onready var _deck_pile: PileView = %DeckPile
@onready var _discard_pile: PileView = %DiscardPile
@onready var _cards: CardAnimator = %CardLayer
@onready var _board_view: BoardView = %BoardView
@onready var _joker_box: HBoxContainer = %JokerBox
@onready var _hand_view: HandView = %HandView
@onready var _win_overlay: WinOverlay = %WinOverlay
@onready var _handoff_button: Button = %HandoffButton
@onready var _handoff_glass: FrostedGlass = %Glass


func _ready() -> void:
	_board_view.pawn_pressed.connect(_on_pawn_pressed)
	_board_view.square_pressed.connect(_on_square_pressed)
	_hand_view.card_pressed.connect(_on_card_pressed)
	_win_overlay.replay_pressed.connect(_on_replay_pressed)
	_win_overlay.home_pressed.connect(_on_home_pressed)
	_handoff_button.pressed.connect(_on_handoff_pressed)
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_cards.deck_pile = _deck_pile
	_cards.discard_pile = _discard_pile


func start(game: GameMatch) -> void:
	_game = game
	# Her oyunun botu kendi üretecini kullanır: önceki oyunun süren araması onunla çakışmaz.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_bot = Bot.new(game.settings.bot_profiles[game.bot_level], game.settings, rng)
	_bot_level.visible = game.bots.has(true)
	_bot_level.text = Difficulty.level_key(game.bot_level)
	_board_view.board = game.board
	_cards.settings = game.settings
	_cards.speed_scale = GameSpeed.speed_scale()
	_board_view.speed_scale = GameSpeed.speed_scale()
	_hand_view.slot_count = game.settings.hand_size + 1
	_hide_overlays()
	_clock_running = true
	_clock.text = format_clock(game.elapsed)
	# Ekran yeni göründüğünde kapların düzeni henüz kurulmamıştır; ilk tur bir kare sonra başlar,
	# yoksa kartlar sol üst köşeden (sıfır konum ve boyuttan) uçar.
	await get_tree().process_frame
	if game != _game:
		return
	_start_turn()


func _process(delta: float) -> void:
	if not _clock_running:
		return
	var shown := int(_game.elapsed)
	_game.elapsed += delta
	if int(_game.elapsed) != shown:
		_clock.text = format_clock(_game.elapsed)


## Geçen süreyi dakika:saniye (bir saati geçince saat:dakika:saniye) olarak yazar.
static func format_clock(seconds: float) -> String:
	var minutes := floori(seconds / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	var rest := int(seconds) % SECONDS_PER_MINUTE
	if seconds < SECONDS_PER_HOUR:
		return "%02d:%02d" % [minutes, rest]
	return "%d:%02d:%02d" % [floori(seconds / SECONDS_PER_HOUR), minutes, rest]


## Oyunu bırakır: sıra başındaki kayıt durur, yalnızca geçen süre güncellenir. Bekleyen
## animasyonlar ve bot adımları oyun değiştiği için kendiliğinden sonlanır.
func _on_back_pressed() -> void:
	if SaveStore.has_match():
		var saved := SaveStore.load_match()
		saved[GameMatch.KEY_ELAPSED] = _game.elapsed
		SaveStore.store_match(saved)
	_clock_running = false
	_awaiting_human = false
	_game = null
	_hide_overlays()
	_board_view.stop_animation()
	left.emit()


## Oyuncunun kart ya da taş seçmesi bekleniyorsa true (ekran görüntüsü aracı da kullanır).
func is_waiting_for_human() -> bool:
	return _awaiting_human


# --- Sıra akışı ---


func _start_turn() -> void:
	_awaiting_human = false
	SaveStore.store_match(_game.to_dict())
	var hand_before := _game.current_hand().size()
	_game.begin_turn()
	var drew := _game.current_hand().size() > hand_before
	_clear_selection()
	_show_idle_hand()
	_refresh_table()
	var seat := _game.current_seat()
	_board_view.turn_seat = seat
	if _game.is_bot_turn():
		_play_bot_turn()
	elif _game.human_count() > 1:
		_show_handoff(seat, drew)
	else:
		_begin_human_turn(drew)


## Deste sayısını, atılanların üstündeki kartı ve sıra noktalarını günceller.
func _refresh_table() -> void:
	_deck_pile.set_count(_game.draw_count())
	_discard_pile.set_top(
		_game.top_discard(), _game.settings, _discard_badge(), _game.top_discard_value
	)
	_turn_dots.show_turn(_game.seats, _game.current)


## Atılanlardaki son kartı atanın rengi; henüz kart atılmadıysa rozet görünmez.
func _discard_badge() -> Color:
	if _game.last_discard_seat == BoardLayout.NO_SEAT:
		return Color.TRANSPARENT
	return Skins.current.seat_color(_game.last_discard_seat)


## Bot hamlesini arka planda düşünür; ekran bu sırada akıcı kalır. Kart, en az bot_delay
## kadar beklendikten ve düşünme bittikten sonra açılır.
func _play_bot_turn() -> void:
	var game := _game
	var bot := _bot
	var result: Array[Move] = []
	var task := WorkerThreadPool.add_task(func() -> void: result.append(bot.choose_move(game)))
	await get_tree().create_timer(_game.settings.bot_delay).timeout
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	if game != _game:
		return
	var move := result[0]
	var card_index := _bot.choose_discard(_game.current_hand()) if move == null else move.card_index
	var color := Skins.current.seat_color(_game.current_seat())
	var chosen := Card.NO_VALUE if move == null else move.value
	await _cards.reveal_card(_hand_card(card_index), color, chosen)
	if game != _game:
		return
	if move == null:
		_discard(card_index)
	else:
		_play(move)


## Çekilen kart desteden ele uçar; kart inince oyuncu seçim yapabilir.
func _begin_human_turn(drew: bool) -> void:
	if drew:
		var hand := _game.current_hand()
		var last := hand.size() - 1
		_show_hand(func(_index: int) -> bool: return true)
		_hand_view.hold(last)
		var game := _game
		await _cards.draw_card(_hand_view.card_rect(last), _hand_card(last))
		if game != _game:
			return
	_show_human_turn()


func _show_human_turn() -> void:
	_picker.reset(_game.legal_moves())
	_show_hand(
		func(index: int) -> bool: return _picker.must_discard() or _picker.is_card_playable(index)
	)
	if _picker.must_discard():
		_hand_view.mark_discard()
	_awaiting_human = true


## Oyuncunun sırası değilken ya da taş yürürken: tek insanlı oyunda el soluk ve basılamaz kalır,
## birden çok insan varsa el gizlenir (sıradaki oyuncu başkasının elini görmesin).
func _show_idle_hand() -> void:
	if _game.human_count() != 1:
		_hand_view.clear()
		return
	var hand := _game.first_human_hand()
	var playable: Array[bool] = []
	playable.resize(hand.size())
	playable.fill(false)
	_hand_view.show_cards(hand, _game.settings, playable)


## Eli gösterir; is_playable kart sırasını alır, basılabilir olup olmadığını döner.
func _show_hand(is_playable: Callable) -> void:
	var hand := _game.current_hand()
	var playable: Array[bool] = []
	for index: int in range(hand.size()):
		playable.append(is_playable.call(index))
	_hand_view.show_cards(hand, _game.settings, playable)


func _hand_card(card_index: int) -> Card:
	return _game.current_hand()[card_index]


## Oyuncunun kartı elden kalkıp atılanlara iner; kart indikten sonra hamle ya da atma uygulanır.
## chosen jokerde seçilen sayıdır.
func _send_human_card(card_index: int, action: Callable, chosen: int) -> void:
	_awaiting_human = false
	var rect := _hand_view.card_rect(card_index)
	var card := _hand_card(card_index)
	_clear_selection()
	_hand_view.hold(card_index)
	var game := _game
	var color := Skins.current.seat_color(_game.current_seat())
	await _cards.discard_card(rect, card, color, chosen)
	if game == _game:
		action.call()


func _play(move: Move) -> void:
	# Oynanan hamlenin seçimi ve vurguları kalkar. Animasyon sürerken dokunmayı hold ve
	# _awaiting_human engeller.
	_clear_selection()
	var path := _game.board.move_path(move)
	var before := _board_view.pawn_centers()
	var game := _game
	_game.play(move)
	_show_idle_hand()
	_refresh_table()
	await _board_view.animate_move(move, path, before)
	if game == _game:
		_finish_turn()


func _discard(card_index: int) -> void:
	_game.discard(card_index)
	_refresh_table()
	_finish_turn()


func _finish_turn() -> void:
	_clear_selection()
	var winner := _game.winner()
	if winner == GameMatch.NO_WINNER:
		_game.next_turn()
		_start_turn()
		return
	_clock_running = false
	SaveStore.clear_match()
	_hand_view.clear()
	_win_overlay.open(winner, tr("WIN") % _seat_name(winner), _seat_colors())


func _seat_name(seat: int) -> String:
	return Skins.current.seat_name(seat)


# --- Hamle seçimi ---


func _on_card_pressed(card_index: int) -> void:
	if _picker.must_discard():
		_send_human_card(card_index, _discard.bind(card_index), Card.NO_VALUE)
		return
	_clear_selection()
	_hand_view.highlight(card_index)
	_picker.pick_card(card_index)
	if _picker.stage == MovePicker.Stage.VALUE:
		_show_values(card_index)
	else:
		_show_pawns()


## Joker için sayılar küçük kartlar olarak elin yerinde görünür; sayı seçilince el geri gelir.
func _show_values(card_index: int) -> void:
	var card_size := _hand_view.card_size() * JOKER_CARD_SCALE
	_hand_view.hide()
	_joker_box.show()
	for value: int in _picker.values():
		var button := _add_joker_button(_on_value_pressed.bind(card_index, value), card_size)
		button.theme_type_variation = HandView.CARD_VARIATION
		button.text = str(value)
	_add_joker_button(_on_values_back_pressed, card_size).add_child(BackArrow.new())


func _add_joker_button(action: Callable, button_size: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = button_size
	button.pressed.connect(action)
	_joker_box.add_child(button)
	return button


## Geri oku: kart seçimini bırakır, el yeniden seçilebilir olur.
func _on_values_back_pressed() -> void:
	_clear_selection()
	_show_human_turn()


func _on_value_pressed(card_index: int, value: int) -> void:
	_clear_values()
	_hand_view.show_chosen(card_index, value)
	_picker.pick_value(value)
	_show_pawns()


func _show_pawns() -> void:
	_set_selectable(_picker.selectable_pawns())


func _on_pawn_pressed(pawn: int) -> void:
	var move := _picker.pick_pawn(pawn)
	if move != null:
		_send_human_card(move.card_index, _play.bind(move), move.value)
	elif _picker.stage == MovePicker.Stage.TARGET:
		_show_pawns()
	elif _picker.stage == MovePicker.Stage.DESTINATION:
		_set_selectable(_picker.selectable_pawns(), _picker.selectable_squares())


func _on_square_pressed(square: int) -> void:
	var move := _picker.pick_destination(square)
	if move != null:
		_send_human_card(move.card_index, _play.bind(move), move.value)


func _set_selectable(pawns: Array[int], squares: Array[int] = []) -> void:
	_board_view.selectable = pawns
	_board_view.selectable_squares = squares
	_board_view.selected_pawn = _picker.selected_pawn()
	_board_view.preview_paths = _preview_paths()
	_board_view.preview_seat = _game.current_seat()
	_board_view.queue_redraw()


## Seçili kartla hâlâ yapılabilecek hamlelerin yolları; kart seçili değilse boş.
func _preview_paths() -> Array[PackedInt32Array]:
	var paths: Array[PackedInt32Array] = []
	for move: Move in _picker.candidates():
		paths.append(PackedInt32Array(_game.board.move_path(move)))
	return paths


func _clear_selection() -> void:
	_picker.cancel()
	_hand_view.clear_chosen()
	_set_selectable([])
	_clear_values()


func _clear_values() -> void:
	Nodes.free_children(_joker_box)
	_joker_box.hide()
	_hand_view.show()


# --- Sıra devri ve oyun sonu ---


## Birden çok insan varken sıradaki oyuncunun eli kapalı durur; oyuncu düğmeye basınca açılır.
func _show_handoff(seat: int, drew: bool) -> void:
	var hidden := _game.current_hand().size() - (1 if drew else 0)
	_hand_view.show_backs(hidden)
	_handoff_button.text = tr("HANDOFF")
	_handoff_glass.set_tint(Skins.current.seat_color(seat))
	_handoff_drew = drew
	_handoff_button.show()


func _on_handoff_pressed() -> void:
	_handoff_button.hide()
	_begin_human_turn(_handoff_drew)


func _hide_overlays() -> void:
	_handoff_button.hide()
	_win_overlay.close()


## Oyundaki koltukların renkleri (konfeti için).
func _seat_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for seat: int in _game.seats:
		colors.append(Skins.current.seat_color(seat))
	return colors


func _on_replay_pressed() -> void:
	_win_overlay.close()
	replay_requested.emit(_game.bots.duplicate(), _game.pawns_per_player(), _game.bot_level)


func _on_home_pressed() -> void:
	_win_overlay.close()
	finished.emit()
