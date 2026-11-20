class_name GameScreen
extends Control
## Oyun ekranı: hakemin (MatchReferee) olaylarını çizer ve oyuncunun dokunarak seçtiği hamleyi
## hakeme niyet olarak iletir. Sıra akışı, botlar, kayıt ve süre hakemdedir.

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

var _referee := MatchReferee.new()
## Hakemin yönettiği oyun; oyun bırakılınca null.
var _game: GameMatch:
	get:
		return _referee.game
## Saatte gösterilen saniye; değişince saat yeniden yazılır.
var _clock_second := -1
var _picker := MovePicker.new()
## Sıra devrinde oyuncunun çektiği kart; eli açılınca desteden uçarak gelir.
var _handoff_drew := false
## Oyuncunun dokunmasını bekleyen an; kart ya da taş uçarken false.
var _awaiting_human := false
## Taşlar, hamle uygulanmadan önceki yerlerinde (yürüme animasyonu buradan başlar).
var _pawns_before: Array[Vector2] = []

@onready var _clock: Label = %Clock
@onready var _level_slash: Label = %LevelSlash
@onready var _bot_level: Label = %BotLevel
@onready var _turn_dots: TurnDots = %TurnDots
@onready var _deck_pile: PileView = %DeckPile
@onready var _discard_pile: PileView = %DiscardPile
@onready var _cards: CardAnimator = %CardLayer
@onready var _board_view: BoardView = %BoardView
@onready var _joker_box: HBoxContainer = %JokerBox
@onready var _hand_view: HandView = %HandView
@onready var _win_overlay: WinOverlay = %WinOverlay
@onready var _starter_draw: StarterDraw = %StarterDraw
@onready var _handoff_button: Button = %HandoffButton
@onready var _handoff_glass: FrostedGlass = %Glass


func _ready() -> void:
	_referee.store = SaveStore
	_referee.event_emitted.connect(_on_event)
	add_child(_referee)
	_board_view.pawn_pressed.connect(_on_pawn_pressed)
	_board_view.square_pressed.connect(_on_square_pressed)
	_hand_view.card_pressed.connect(_on_card_pressed)
	_win_overlay.replay_pressed.connect(_on_replay_pressed)
	_win_overlay.home_pressed.connect(_on_home_pressed)
	_handoff_button.pressed.connect(_on_handoff_pressed)
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_cards.deck_pile = _deck_pile
	_cards.discard_pile = _discard_pile
	_cards.discard_landed.connect(_on_discard_landed)


## Yeni oyunda (draw_starter) ilk turdan önce başlayan oyuncu kurayla gösterilir.
func start(game: GameMatch, draw_starter := false) -> void:
	_referee.start(game)
	_show_bot_level(game)
	_board_view.board = game.board
	_board_view.seat_colors = game.colors
	_cards.settings = game.settings
	_cards.speed_scale = GameSpeed.speed_scale()
	_board_view.speed_scale = GameSpeed.speed_scale()
	_hand_view.slot_count = game.settings.hand_size + 1
	_hide_overlays()
	_show_clock()
	_refresh_table()
	# Ekran yeni göründüğünde kapların düzeni henüz kurulmamıştır; ilk tur bir kare sonra başlar,
	# yoksa kartlar sol üst köşeden (sıfır konum ve boyuttan) uçar.
	await get_tree().process_frame
	if game != _game:
		return
	if draw_starter:
		await _draw_starter()
		if game != _game:
			return
	_referee.begin()


## Başlangıç kurası ayrı katmanda oynar; el o sırada boştur ve saat henüz başlamamıştır.
func _draw_starter() -> void:
	var game := _game
	var colors: Array[int] = []
	for seat: int in game.seats:
		colors.append(game.colors[seat])
	_hand_view.clear()
	_starter_draw.play(colors, game.starter, game.settings, GameSpeed.speed_scale())
	await _starter_draw.closed


func _process(_delta: float) -> void:
	if _game != null and int(_game.elapsed) != _clock_second:
		_show_clock()


func _show_clock() -> void:
	_clock_second = int(_game.elapsed)
	_clock.text = format_clock(_game.elapsed)


## Botlu oyunda saatin yanında "/" ve seviyenin adı, seviyenin renginde görünür.
func _show_bot_level(game: GameMatch) -> void:
	var has_bots := game.bots.has(true)
	_level_slash.visible = has_bots
	_bot_level.visible = has_bots
	_bot_level.text = Difficulty.level_key(game.bot_level)
	var color := Skins.current.level_color(game.bot_level)
	_bot_level.add_theme_color_override(ThemeKeys.FONT_COLOR, color)


## Geçen süreyi dakika:saniye (bir saati geçince saat:dakika:saniye) olarak yazar.
static func format_clock(seconds: float) -> String:
	var minutes := floori(seconds / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	var rest := int(seconds) % SECONDS_PER_MINUTE
	if seconds < SECONDS_PER_HOUR:
		return "%02d:%02d" % [minutes, rest]
	return "%d:%02d:%02d" % [floori(seconds / SECONDS_PER_HOUR), minutes, rest]


## Oyunu bırakır (kayıt hakemde güncellenir). Bekleyen animasyonlar oyun değiştiği için
## kendiliğinden sonlanır.
func _on_back_pressed() -> void:
	_referee.leave()
	_awaiting_human = false
	_hide_overlays()
	_board_view.stop_animation()
	left.emit()


## Oyuncunun kart ya da taş seçmesi bekleniyorsa true (ekran görüntüsü aracı da kullanır).
func is_waiting_for_human() -> bool:
	return _awaiting_human


# --- Hakemin olayları ---


## Olayı çizer, bitince hakemi devam ettirir. Çizim sürerken oyun bırakıldıysa (ya da yenisi
## başladıysa) eski olay hakemi ilerletmez.
func _on_event(event: MatchEvent) -> void:
	var game := _game
	match event.kind:
		MatchEvent.Kind.RESHUFFLED:
			await _show_reshuffle()
		MatchEvent.Kind.AD_DUE:
			Ads.show_interstitial()
			await Ads.interstitial_closed
		MatchEvent.Kind.TURN_STARTED:
			_on_turn_started(event)
		MatchEvent.Kind.CARD_REVEALED:
			await _reveal_card(event)
		MatchEvent.Kind.MOVE_PLAYED:
			await _show_move(event)
		MatchEvent.Kind.DISCARDED:
			_clear_selection()
			_refresh_table()
		MatchEvent.Kind.PLAYER_FINISHED:
			_announce_finisher(event)
		MatchEvent.Kind.MATCH_OVER:
			_end_match()
	if game == _game:
		_referee.acknowledge()


func _on_turn_started(event: MatchEvent) -> void:
	_awaiting_human = false
	_clear_selection()
	_show_idle_hand()
	# Deste sayacı burada değil, kart desteden kalktığı an düşer.
	_show_turn(_game.current)
	if _game.is_bot_turn():
		return
	if _game.playing_human_count() > 1:
		_show_handoff(event.seat, event.drew)
	else:
		_begin_human_turn(event.drew)


## Atılanlar karıştırılıp desteye döndü: atılanlar boşalır, kartlar desteye uçar ve deste
## sayacı kartlar inince yeni sayıyı gösterir.
func _show_reshuffle() -> void:
	_discard_pile.set_count(_game.discard_count())
	_discard_pile.set_top(null, _game.settings, Color.TRANSPARENT, Card.NO_VALUE)
	await _cards.shuffle_to_deck()
	_refresh_table()


## Deste ve atılanların sayısını, atılanların üstündeki kartı ve sıra noktalarını günceller.
func _refresh_table() -> void:
	_deck_pile.set_count(_game.draw_count())
	_discard_pile.set_count(_game.discard_count())
	_discard_pile.set_top(
		_game.top_discard(), _game.settings, _discard_badge(), _game.top_discard_value
	)
	_refresh_turn_dots()


## Sıra noktalarında yalnızca oynamaya devam eden oyuncular görünür.
func _refresh_turn_dots() -> void:
	_show_turn_dots(_game.current)


## Sıra oku ve noktaları index sıradaki oyuncuyu gösterir.
func _show_turn(index: int) -> void:
	_show_turn_dots(index)
	_board_view.turn_seat = _game.seats[index]


func _show_turn_dots(index: int) -> void:
	var playing: Array[int] = []
	var current := 0
	for player: int in range(_game.seats.size()):
		if _game.is_playing(player):
			if player == index:
				current = playing.size()
			playing.append(_game.colors[_game.seats[player]])
	_turn_dots.show_turn(playing, current)


## Atılanlardaki son kartı atanın rengi; henüz kart atılmadıysa rozet görünmez.
func _discard_badge() -> Color:
	if _game.last_discard_seat == BoardLayout.NO_SEAT:
		return Color.TRANSPARENT
	return _seat_color(_game.last_discard_seat)


## Çekilen kart desteden ele uçar; kart inince oyuncu seçim yapabilir.
func _begin_human_turn(drew: bool) -> void:
	_refresh_table()
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
	if _game.playing_human_count() != 1:
		_hand_view.clear()
		return
	var hand := _game.first_playing_human_hand()
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


## Kart atılanlara indiği an sayaç bir artar; hamle uygulanınca gerçek sayı yazılır.
func _on_discard_landed() -> void:
	_discard_pile.set_count(_game.discard_count() + 1)


func _hand_card(card_index: int) -> Card:
	return _game.current_hand()[card_index]


## Oyuncunun seçimi hakeme niyet olarak gider; hakem kartı açınca (CARD_REVEALED) kart uçar.
## Hakem niyeti reddederse durum değişmemiştir: hakem hâlâ bu oyuncuyu bekliyorsa seçim yeniden
## açılır, yoksa ekran hakemin sıradaki olayını bekler.
func _send_intent(intent: MatchIntent) -> void:
	_awaiting_human = false
	if _referee.submit(intent):
		return
	push_warning("Hakem niyeti reddetti: koltuk %d, tür %d" % [intent.seat, intent.kind])
	_clear_selection()
	if _referee.is_awaiting_intent():
		_show_human_turn()


## Açılan kart atılanlara uçar: insan oyuncunun kartı elden kalkar, botun kartı açılır. Kartın
## değeri jokerde seçilen sayıdır.
func _reveal_card(event: MatchEvent) -> void:
	var card := _hand_card(event.card_index)
	var color := _seat_color(event.seat)
	if _game.is_bot_turn():
		_refresh_table()
		await _cards.reveal_card(card, color, event.value)
	else:
		var rect := _hand_view.card_rect(event.card_index)
		_clear_selection()
		_hand_view.hold(event.card_index)
		await _cards.discard_card(rect, card, color, event.value)
	_pawns_before = _board_view.pawn_centers()


## Hamle uygulandı: seçim ve vurgular kalkar, taşlar eski yerlerinden yürür. Animasyon sürerken
## dokunmayı hold ve _awaiting_human engeller.
func _show_move(event: MatchEvent) -> void:
	_clear_selection()
	_show_idle_hand()
	_refresh_table()
	await _board_view.animate_move(event.move, event.path, _pawns_before)


## Oyun bitti: sıralama tablosu açılır.
func _end_match() -> void:
	_clear_selection()
	_hand_view.clear()
	var ranking := MatchResult.ranking(_game)
	var rounds: Array[int] = []
	var ranked_colors: Array[int] = []
	for seat: int in ranking:
		rounds.append(MatchResult.finish_round(_game, seat))
		ranked_colors.append(_game.colors[seat])
	_win_overlay.open(ranked_colors, rounds, _seat_colors())


## Yeni bitiren oyuncu için kısa duyuru gösterilir; oyun beklemeden sürer.
func _announce_finisher(event: MatchEvent) -> void:
	var colors: Array[Color] = [_seat_color(event.seat)]
	_win_overlay.announce(_game.colors[event.seat], event.place, colors)


# --- Hamle seçimi ---


func _on_card_pressed(card_index: int) -> void:
	if _picker.must_discard():
		_send_intent(MatchIntent.discard(_game.current_seat(), card_index))
		return
	_clear_selection()
	_hand_view.highlight(card_index)
	_picker.pick_card(card_index)
	if _picker.stage == MovePicker.Stage.VALUE:
		_show_values(card_index)
	else:
		_show_pawns()


## Joker için sayılar, ileri kartları gibi iri ve işaretli sayılı küçük kartlar olarak elin yerinde
## görünür; sayı seçilince el geri gelir.
func _show_values(card_index: int) -> void:
	var card_size := _hand_view.card_size() * JOKER_CARD_SCALE
	_hand_view.hide()
	_joker_box.show()
	for value: int in _picker.values():
		var button := _add_joker_button(_on_value_pressed.bind(card_index, value), card_size)
		button.theme_type_variation = HandView.CARD_VARIATION
		var symbol := CardSymbol.new()
		symbol.show_symbol(CardSymbol.Kind.FORWARD, value)
		button.add_child(symbol)
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
		_send_intent(MatchIntent.play(_game.current_seat(), move))
	elif _picker.stage == MovePicker.Stage.TARGET:
		_show_pawns()
	elif _picker.stage == MovePicker.Stage.DESTINATION:
		_set_selectable(_picker.selectable_pawns(), _picker.selectable_squares())


func _on_square_pressed(square: int) -> void:
	var move := _picker.pick_destination(square)
	if move != null:
		_send_intent(MatchIntent.play(_game.current_seat(), move))


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
	_handoff_glass.set_tint(_seat_color(seat))
	_handoff_drew = drew
	_handoff_button.show()


func _on_handoff_pressed() -> void:
	_handoff_button.hide()
	_begin_human_turn(_handoff_drew)


func _hide_overlays() -> void:
	_handoff_button.hide()
	_win_overlay.close()
	_starter_draw.close()


## Oyundaki koltukların renkleri (konfeti için).
func _seat_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for seat: int in _game.seats:
		colors.append(_seat_color(seat))
	return colors


## Koltuğun bu oyundaki rengi.
func _seat_color(seat: int) -> Color:
	return Skins.current.seat_color(_game.colors[seat])


## Oyun sonu geçiş reklamı kazanma ekranından çıkarken gösterilir; oyun içi reklam az önce
## gösterildiyse atlanır.
func _on_replay_pressed() -> void:
	_win_overlay.close()
	_show_end_ad()
	replay_requested.emit(_game.bots.duplicate(), _game.pawns_per_player(), _game.bot_level)


func _on_home_pressed() -> void:
	_win_overlay.close()
	_show_end_ad()
	finished.emit()


func _show_end_ad() -> void:
	if not AdSchedule.skips_end_ad(_game):
		Ads.show_interstitial()
