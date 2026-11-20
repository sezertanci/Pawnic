class_name GameScreen
extends Control
## Oyun ekranı: oyun kaynağının (MatchSource) olaylarını çizer ve oyuncunun dokunarak seçtiği
## hamleyi kaynağa niyet olarak iletir. Yerel oyunda kaynak ekranın kendi hakemidir; ağ oyununda
## hostta lobinin hakemi, istemcide hosttan gelen görünümdür. Sıra akışı, botlar, kayıt ve süre
## kaynaktadır; ekran oyunu yalnızca kaynağın görünümünden (MatchView) okur.

## Oyun bitip oyuncu kutlama ekranından çıkmak istediğinde ya da ağ oyunu bu cihazın dışında
## sona erdiğinde gelir.
signal finished
## Oyun bitip oyuncu aynı ayarlarla yeniden oynamak istediğinde gelir (yalnızca yerel oyun).
signal replay_requested(bot_flags: Array[bool], pawns: int, bot_level: Bot.Level)
## Oyuncu geri düğmesiyle oyundan çıktığında gelir; yerel oyun kayıtlı kalır.
signal left

const SECONDS_PER_MINUTE := 60
const SECONDS_PER_HOUR := 3600
## Joker sayı kartlarının eldeki kartlara göre boyu.
const JOKER_CARD_SCALE := 0.7
const LEAVE_MATCH_CONFIRM_KEY := "LEAVE_MATCH_CONFIRM"
const END_MATCH_CONFIRM_KEY := "END_MATCH_CONFIRM"
const GAME_ENDED_KEY := "GAME_ENDED"
const HOST_UNREACHABLE_KEY := "HOST_UNREACHABLE"
const RECONNECTING_KEY := "RECONNECTING"
const LEAVE_KEY := "LEAVE"
const CANCEL_KEY := "CANCEL"
const OK_KEY := "OK"
const ROOM_INFO_KEY := "ROOM_INFO"
const ROLE_HOST_KEY := "ROLE_HOST"
const ROLE_GUEST_KEY := "ROLE_GUEST"

## Yerel oyunun hakemi.
var _referee := MatchReferee.new()
## Yerel hakemin yönettiği oyun; oyun bırakılınca null (ekran görüntüsü aracı ve testler okur).
var _game: GameMatch:
	get:
		return _referee.game
var _source: MatchSource
## Kaynağın son görünümü; her olayın başında yenilenir.
var _view: MatchView
## Kaynak ya da görünüm baştan değişince artar; süren animasyon bayatladığını bununla anlar.
var _generation := 0
## Oyun sonu tablosu açıldıysa true.
var _match_over := false
## Onay katmanında onaylanınca yapılacak iş.
var _confirm_action := Callable()
## Saatte gösterilen saniye; değişince saat yeniden yazılır.
var _clock_second := -1
var _picker := MovePicker.new()
## Sıra devrinde oyuncunun çektiği kart; eli açılınca desteden uçarak gelir.
var _handoff_drew := false
## Oyuncunun dokunmasını bekleyen an; kart ya da taş uçarken false.
var _awaiting_human := false
## Taşlar, hamle uygulanmadan önceki yerlerinde (yürüme animasyonu buradan başlar).
var _pawns_before: Array[Vector2] = []
## Ağ oyununda hostla bağlantı koptu; yeniden bağlanılıyor katmanı açık.
var _reconnecting := false
## Sıra noktalarındaki taşların koltukları, noktalarla aynı sırada.
var _dot_seats: Array[int] = []

@onready var _clock: Label = %Clock
@onready var _level_slash: Label = %LevelSlash
@onready var _bot_level: Label = %BotLevel
@onready var _turn_dots: TurnDots = %TurnDots
@onready var _room_info: Label = %RoomInfo
@onready var _deck_pile: PileView = %DeckPile
@onready var _discard_pile: PileView = %DiscardPile
@onready var _cards: CardAnimator = %CardLayer
@onready var _board_view: BoardView = %BoardView
@onready var _joker_box: HBoxContainer = %JokerBox
@onready var _hand_view: HandView = %HandView
@onready var _turn_timer: TurnTimerBar = %TurnTimer
@onready var _win_overlay: WinOverlay = %WinOverlay
@onready var _starter_draw: StarterDraw = %StarterDraw
@onready var _confirm: ConfirmOverlay = %ConfirmOverlay
@onready var _handoff_button: Button = %HandoffButton
@onready var _handoff_glass: FrostedGlass = %Glass


func _ready() -> void:
	_referee.store = SaveStore
	add_child(_referee)
	_board_view.pawn_pressed.connect(_on_pawn_pressed)
	_board_view.square_pressed.connect(_on_square_pressed)
	_hand_view.card_pressed.connect(_on_card_pressed)
	_win_overlay.replay_pressed.connect(_on_replay_pressed)
	_win_overlay.home_pressed.connect(_on_home_pressed)
	_confirm.confirmed.connect(_on_confirmed)
	_handoff_button.pressed.connect(_on_handoff_pressed)
	(%BackButton as Button).pressed.connect(_on_back_pressed)
	_cards.deck_pile = _deck_pile
	_cards.discard_pile = _discard_pile
	_cards.discard_landed.connect(_on_discard_landed)


## Yerel oyunu başlatır; yeni oyunda (draw_starter) ilk turdan önce başlayan oyuncu kurayla
## gösterilir.
func start(game: GameMatch, draw_starter := false) -> void:
	_referee.start(game)
	start_source(RefereeSource.new(_referee), draw_starter)


## Oyunu kaynaktan çizer; kaynağın görünümü hazır olmalıdır.
func start_source(source: MatchSource, draw_starter := false) -> void:
	_release_source()
	_source = source
	_generation += 1
	_source.event_emitted.connect(_on_event)
	_source.intent_rejected.connect(_on_intent_rejected)
	_source.view_reset.connect(_on_view_reset)
	_source.ended.connect(_on_source_ended)
	_source.connection_changed.connect(_on_connection_changed)
	_match_over = false
	_reconnecting = false
	_awaiting_human = false
	_view = _source.view()
	_set_up_table()
	_hide_overlays()
	_show_clock()
	_refresh_table()
	# Ekran yeni göründüğünde kapların düzeni henüz kurulmamıştır; ilk tur bir kare sonra başlar,
	# yoksa kartlar sol üst köşeden (sıfır konum ve boyuttan) uçar.
	await get_tree().process_frame
	if _has_left(source):
		return
	if draw_starter:
		await _draw_starter()
		if _has_left(source):
			return
	_source.begin()


## Eski kaynak bırakılır; sinyalleri artık ekrana gelmez.
func _release_source() -> void:
	if _source == null:
		return
	_source.detach()
	_source.event_emitted.disconnect(_on_event)
	_source.intent_rejected.disconnect(_on_intent_rejected)
	_source.view_reset.disconnect(_on_view_reset)
	_source.ended.disconnect(_on_source_ended)
	_source.connection_changed.disconnect(_on_connection_changed)


## Kaynak değiştiyse ya da oyun bırakıldıysa true.
func _has_left(source: MatchSource) -> bool:
	return source != _source or not source.is_live()


## Animasyonun başladığı andan beri kaynak ya da görünüm değiştiyse true.
func _is_stale(generation: int) -> bool:
	return generation != _generation or not _source.is_live()


## Tahta ağ oyununda oyuncunun koltuğu alta gelecek biçimde döner; hız kaynaktan gelir (ağ
## oyununda hostunki).
func _set_up_table() -> void:
	_show_bot_level()
	_show_room_info()
	_board_view.bottom_seat = _view.viewer_seat if _source.is_networked() else BoardLayout.NO_SEAT
	_board_view.board = _view.board
	_board_view.seat_colors = _view.colors
	_cards.settings = _view.settings
	_cards.speed_scale = _source.speed_scale()
	_board_view.speed_scale = _source.speed_scale()
	_hand_view.slot_count = _view.settings.hand_size + 1
	_win_overlay.set_networked(_source.is_networked())


## Başlangıç kurası ayrı katmanda oynar; el o sırada boştur ve saat henüz başlamamıştır.
func _draw_starter() -> void:
	var colors: Array[int] = []
	for seat: int in _view.seats:
		colors.append(_view.colors[seat])
	_hand_view.clear()
	_starter_draw.play(colors, _view.starter, _view.settings, _source.speed_scale())
	await _starter_draw.closed


func _process(_delta: float) -> void:
	if _source == null:
		return
	if int(_source.elapsed()) != _clock_second:
		_show_clock()
	_show_turn_timer()
	if _source.is_networked() and not _match_over:
		_show_seat_waits()


## Sıradaki insan oyuncunun sıra süresi (ağ oyunu) elin üstündeki çubukta, oyuncunun renginde
## görünür. Süre bitince bu cihazdaki oyuncunun yarım kalan seçimi iptal olur; hamleyi bot oynar.
func _show_turn_timer() -> void:
	var left := _source.turn_time_left()
	if left != MatchReferee.NO_TURN_TIMER:
		var settings := _view.settings
		var color := _seat_color(_view.current_seat())
		var board := _board_view.grid_rect()
		_turn_timer.fit_between(board.position.x, board.end.x)
		_turn_timer.show_time(left, settings.turn_time_limit, settings.turn_warning_time, color)
	elif _turn_timer.visible:
		_turn_timer.stop()
		_cancel_selection()


func _cancel_selection() -> void:
	if _awaiting_human:
		_awaiting_human = false
		_clear_selection()
		_show_idle_hand()


func _show_clock() -> void:
	var seconds := _source.elapsed()
	_clock_second = int(seconds)
	_clock.text = format_clock(seconds)


## Botlu oyunda saatin yanında "/" ve seviyenin adı, seviyenin renginde görünür.
func _show_bot_level() -> void:
	var has_bots := _view.bots.has(true)
	var level := _source.bot_level()
	_level_slash.visible = has_bots
	_bot_level.visible = has_bots
	_bot_level.text = Difficulty.level_key(level)
	_bot_level.add_theme_color_override(ThemeKeys.FONT_COLOR, Skins.current.level_color(level))


## Geçen süreyi dakika:saniye (bir saati geçince saat:dakika:saniye) olarak yazar.
## Ağ oyununda başlığın altında oda kodu, kurucunun rengi ve bu cihazın rolü yazar.
func _show_room_info() -> void:
	_room_info.visible = _source.is_networked()
	if not _room_info.visible:
		return
	var host_color := _view.colors[_view.seats[HostLobby.HOST_INDEX]]
	var role := ROLE_HOST_KEY if _source.is_host() else ROLE_GUEST_KEY
	_room_info.text = (
		tr(ROOM_INFO_KEY) % [_source.room_code(), Skins.current.seat_name(host_color), tr(role)]
	)


static func format_clock(seconds: float) -> String:
	var minutes := floori(seconds / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	var rest := int(seconds) % SECONDS_PER_MINUTE
	if seconds < SECONDS_PER_HOUR:
		return "%02d:%02d" % [minutes, rest]
	return "%d:%02d:%02d" % [floori(seconds / SECONDS_PER_HOUR), minutes, rest]


## Ağ oyunu sürerken çıkmadan önce onay sorulur: hosta her zaman (oyun herkes için biter),
## katılan oyuncuya henüz bitirmediyse (koltuğunu bot alır).
func _on_back_pressed() -> void:
	if not _source.is_networked() or _match_over or not _source.is_live():
		_leave()
	elif _source.is_host():
		_ask(END_MATCH_CONFIRM_KEY, LEAVE_KEY, CANCEL_KEY, _leave)
	elif not _view.finishers.has(_view.viewer_seat):
		_ask(LEAVE_MATCH_CONFIRM_KEY, LEAVE_KEY, CANCEL_KEY, _leave)
	else:
		_leave()


## Oyunu bırakır (yerel oyunun kaydı hakemde güncellenir). Bekleyen animasyonlar kaynak
## bırakıldığı için kendiliğinden sonlanır.
func _leave() -> void:
	_source.leave()
	_awaiting_human = false
	_hide_overlays()
	_board_view.stop_animation()
	left.emit()


## Onay katmanını açar; onaylanınca action çağrılır.
func _ask(message_key: String, confirm_key: String, cancel_key: String, action: Callable) -> void:
	_confirm_action = action
	_confirm.ask(message_key, confirm_key, cancel_key)


func _on_confirmed() -> void:
	_confirm_action.call()


## Oyuncunun kart ya da taş seçmesi bekleniyorsa true (ekran görüntüsü aracı da kullanır).
func is_waiting_for_human() -> bool:
	return _awaiting_human


# --- Kaynağın olayları ---


## Olayı çizer, bitince kaynağı devam ettirir. Çizim sürerken kaynak ya da görünüm değiştiyse
## eski olay kaynağı ilerletmez.
func _on_event(event: MatchEvent) -> void:
	var generation := _generation
	_view = _source.view()
	_board_view.board = _view.board
	match event.kind:
		MatchEvent.Kind.RESHUFFLED:
			await _show_reshuffle()
		MatchEvent.Kind.AD_DUE:
			Ads.show_interstitial()
			await Ads.interstitial_closed
		MatchEvent.Kind.TURN_STARTED:
			await _on_turn_started(event)
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
	if generation == _generation:
		_source.acknowledge(event)


## Olay, oyuncunun eli hazır olunca (çekilen kart ele inince) bitmiş sayılır; ağ oyununda sıra
## süresi ancak o zaman başlar. Aynı cihazda sıra devri beklenmez.
func _on_turn_started(event: MatchEvent) -> void:
	_awaiting_human = false
	_clear_selection()
	_show_idle_hand()
	# Deste sayacı burada değil, kart desteden kalktığı an düşer.
	_show_turn(_view.current)
	if not _view.is_viewer_turn():
		return
	if _source.shares_device():
		_show_handoff(event.seat, event.drew)
	else:
		await _begin_human_turn(event.drew)


## Kaynak niyeti reddetti: seçim kalkar; oyuncunun niyeti hâlâ bekleniyorsa seçim yeniden açılır,
## yoksa ekran kaynağın sıradaki olayını bekler.
func _on_intent_rejected() -> void:
	_clear_selection()
	if _source.is_awaiting_intent():
		_show_human_turn()


## Görünümün tamamı yeniden geldi: süren animasyonlar bırakılır ve masa baştan çizilir.
func _on_view_reset() -> void:
	_generation += 1
	_awaiting_human = false
	_board_view.stop_animation()
	_clear_selection()
	_handoff_button.hide()
	_view = _source.view()
	_board_view.board = _view.board
	_refresh_table()
	_show_turn(_view.current)
	if _source.is_awaiting_intent():
		_show_human_turn()
	else:
		_show_idle_hand()


## Ağ oyunu bu cihazın dışında bitti (host oyunu kapattı ya da hosta artık ulaşılamıyor); oyun
## sonu tablosu açıksa oyuncu oradan çıkar.
func _on_source_ended(by_host: bool) -> void:
	if _match_over:
		return
	_generation += 1
	_reconnecting = false
	_awaiting_human = false
	_board_view.stop_animation()
	_clear_selection()
	_hide_overlays()
	_ask(GAME_ENDED_KEY if by_host else HOST_UNREACHABLE_KEY, OK_KEY, "", finished.emit)


## Hostla bağlantı koparken yeniden bağlanılıyor katmanı açılır, oyuncu oradan çıkabilir;
## bağlantı düzelince katman kapanır. Oyun bittiyse oyun sonu tablosu kalır.
func _on_connection_changed(lost: bool) -> void:
	if _match_over:
		return
	if lost:
		_reconnecting = true
		_ask(RECONNECTING_KEY, LEAVE_KEY, "", _leave)
	elif _reconnecting:
		_reconnecting = false
		_confirm.hide()


## Atılanlar karıştırılıp desteye döndü: atılanlar boşalır, kartlar desteye uçar ve deste
## sayacı kartlar inince yeni sayıyı gösterir.
func _show_reshuffle() -> void:
	_discard_pile.set_count(_view.discard_count)
	_discard_pile.set_top(null, _view.settings, Color.TRANSPARENT, Card.NO_VALUE)
	await _cards.shuffle_to_deck()
	_refresh_table()


## Deste ve atılanların sayısını, atılanların üstündeki kartı ve sıra noktalarını günceller.
func _refresh_table() -> void:
	_deck_pile.set_count(_view.draw_count)
	_discard_pile.set_count(_view.discard_count)
	_discard_pile.set_top(
		_view.top_discard, _view.settings, _discard_badge(), _view.top_discard_value
	)
	_show_turn_dots(_view.current)


## Sıra oku ve noktaları index sıradaki oyuncuyu gösterir.
func _show_turn(index: int) -> void:
	_show_turn_dots(index)
	_board_view.turn_seat = _view.seats[index]


## Sıra noktalarında yalnızca oynamaya devam eden oyuncular görünür.
func _show_turn_dots(index: int) -> void:
	var playing: Array[int] = []
	var current := 0
	_dot_seats.clear()
	for player: int in range(_view.seats.size()):
		var seat := _view.seats[player]
		if not _view.finishers.has(seat):
			if player == index:
				current = playing.size()
			playing.append(_view.colors[seat])
			_dot_seats.append(seat)
	_turn_dots.show_turn(playing, current)


## Ağ oyununda bağlantısı kopan oyuncuların taşları, koltuklarını bot alana kadar kalan süreyle
## soluk görünür.
func _show_seat_waits() -> void:
	var waits: Array[float] = []
	for seat: int in _dot_seats:
		waits.append(_source.seat_wait(seat))
	_turn_dots.show_waits(waits)


## Atılanlardaki son kartı atanın rengi; henüz kart atılmadıysa rozet görünmez.
func _discard_badge() -> Color:
	if _view.last_discard_seat == BoardLayout.NO_SEAT:
		return Color.TRANSPARENT
	return _seat_color(_view.last_discard_seat)


## Çekilen kart desteden ele uçar; kart inince oyuncu seçim yapabilir.
func _begin_human_turn(drew: bool) -> void:
	_refresh_table()
	if drew:
		var last := _view.hand.size() - 1
		_show_hand(func(_index: int) -> bool: return true)
		_hand_view.hold(last)
		var generation := _generation
		await _cards.draw_card(_hand_view.card_rect(last), _view.hand[last])
		if _is_stale(generation):
			return
	_show_human_turn()


func _show_human_turn() -> void:
	_picker.reset(_view.legal_moves())
	_show_hand(
		func(index: int) -> bool: return _picker.must_discard() or _picker.is_card_playable(index)
	)
	if _picker.must_discard():
		_hand_view.mark_discard()
	_awaiting_human = true


## Oyuncunun sırası değilken ya da taş yürürken el soluk ve basılamaz kalır. Aynı cihazda birden
## çok insan varsa el gizlenir (sıradaki oyuncu başkasının elini görmesin).
func _show_idle_hand() -> void:
	if _source.shares_device():
		_hand_view.clear()
		return
	var playable: Array[bool] = []
	playable.resize(_view.hand.size())
	playable.fill(false)
	_hand_view.show_cards(_view.hand, _view.settings, playable)


## Eli gösterir; is_playable kart sırasını alır, basılabilir olup olmadığını döner.
func _show_hand(is_playable: Callable) -> void:
	var playable: Array[bool] = []
	for index: int in range(_view.hand.size()):
		playable.append(is_playable.call(index))
	_hand_view.show_cards(_view.hand, _view.settings, playable)


## Kart atılanlara indiği an sayaç bir artar; hamle uygulanınca gerçek sayı yazılır.
func _on_discard_landed() -> void:
	_discard_pile.set_count(_view.discard_count + 1)


## Oyuncunun seçimi kaynağa niyet olarak gider; kaynak kartı açınca (CARD_REVEALED) kart uçar,
## reddederse intent_rejected gelir.
func _send_intent(intent: MatchIntent) -> void:
	_awaiting_human = false
	_source.submit(intent)


## Açılan kart atılanlara uçar: bu cihazdaki oyuncunun kartı elden kalkar, başkasının kartı
## açılır. Kartın değeri jokerde seçilen sayıdır. Kart inince atılanların üstünde o kart kalır;
## ağ oyununda hamle olayı hosttan biraz sonra gelebilir, o arada eski kart görünmemelidir.
## Ağ oyununda başka bir insanın kartı desteden bekletmesiz uçar: kartı oynayanın ekranıyla aynı
## sürede biter ve hamle her cihazda birlikte başlar.
func _reveal_card(event: MatchEvent) -> void:
	var color := _seat_color(event.seat)
	if event.seat != _view.viewer_seat:
		_refresh_table()
		if _is_remote_human(event.seat):
			await _cards.discard_card(_deck_pile.card_rect(), event.card, color, event.value)
		else:
			await _cards.reveal_card(event.card, color, event.value)
	else:
		var rect := _hand_view.card_rect(event.card_index)
		_clear_selection()
		_hand_view.hold(event.card_index)
		await _cards.discard_card(rect, event.card, color, event.value)
	_discard_pile.set_top(event.card, _view.settings, color, event.value)
	_pawns_before = _board_view.pawn_centers()


## Koltukta ağ üzerinden oynayan bir insan oyuncu varsa true (bot değil).
func _is_remote_human(seat: int) -> bool:
	return _source.is_networked() and not _view.bots[_view.seats.find(seat)]


## Hamle uygulandı: seçim ve vurgular kalkar, taşlar eski yerlerinden yürür. Animasyon sürerken
## dokunmayı hold ve _awaiting_human engeller.
func _show_move(event: MatchEvent) -> void:
	_clear_selection()
	_show_idle_hand()
	_refresh_table()
	await _board_view.animate_move(event.move, event.path, _pawns_before)


## Oyun bitti: sıralama tablosu açılır.
func _end_match() -> void:
	_match_over = true
	_clear_selection()
	_hand_view.clear()
	var ranking := MatchResult.order(_view.settings, _view.board, _view.seats, _view.finishers)
	var rounds: Array[int] = []
	var ranked_colors: Array[int] = []
	for seat: int in ranking:
		rounds.append(MatchResult.round_of(_view.finishers, _view.finish_rounds, seat))
		ranked_colors.append(_view.colors[seat])
	_win_overlay.open(ranked_colors, rounds, _seat_colors())


## Yeni bitiren oyuncu için kısa duyuru gösterilir; oyun beklemeden sürer.
func _announce_finisher(event: MatchEvent) -> void:
	var colors: Array[Color] = [_seat_color(event.seat)]
	_win_overlay.announce(_view.colors[event.seat], event.place, colors)


# --- Hamle seçimi ---


func _on_card_pressed(card_index: int) -> void:
	if _picker.must_discard():
		_send_intent(MatchIntent.discard(_view.current_seat(), card_index))
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
		_send_intent(MatchIntent.play(_view.current_seat(), move))
	elif _picker.stage == MovePicker.Stage.TARGET:
		_show_pawns()
	elif _picker.stage == MovePicker.Stage.DESTINATION:
		_set_selectable(_picker.selectable_pawns(), _picker.selectable_squares())


func _on_square_pressed(square: int) -> void:
	var move := _picker.pick_destination(square)
	if move != null:
		_send_intent(MatchIntent.play(_view.current_seat(), move))


func _set_selectable(pawns: Array[int], squares: Array[int] = []) -> void:
	_board_view.selectable = pawns
	_board_view.selectable_squares = squares
	_board_view.selected_pawn = _picker.selected_pawn()
	_board_view.preview_paths = _preview_paths()
	_board_view.preview_seat = _view.current_seat()
	_board_view.queue_redraw()


## Seçili kartla hâlâ yapılabilecek hamlelerin yolları; kart seçili değilse boş.
func _preview_paths() -> Array[PackedInt32Array]:
	var paths: Array[PackedInt32Array] = []
	for move: Move in _picker.candidates():
		paths.append(PackedInt32Array(_view.board.move_path(move)))
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


## Aynı cihazda birden çok insan varken sıradaki oyuncunun eli kapalı durur; oyuncu düğmeye
## basınca açılır.
func _show_handoff(seat: int, drew: bool) -> void:
	var hidden := _view.hand.size() - (1 if drew else 0)
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
	_confirm.hide()


## Oyundaki koltukların renkleri (konfeti için).
func _seat_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for seat: int in _view.seats:
		colors.append(_seat_color(seat))
	return colors


## Koltuğun bu oyundaki rengi.
func _seat_color(seat: int) -> Color:
	return Skins.current.seat_color(_view.colors[seat])


## Oyun sonu geçiş reklamı kazanma ekranından çıkarken gösterilir; oyun içi reklam az önce
## gösterildiyse atlanır. Yeniden oyna yalnızca yerel oyunda görünür.
func _on_replay_pressed() -> void:
	_win_overlay.close()
	_show_end_ad()
	replay_requested.emit(_game.bots.duplicate(), _game.pawns_per_player(), _game.bot_level)


func _on_home_pressed() -> void:
	_win_overlay.close()
	_show_end_ad()
	_source.leave()
	finished.emit()


func _show_end_ad() -> void:
	if not _source.skips_end_ad():
		Ads.show_interstitial()
