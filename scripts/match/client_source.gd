class_name ClientSource
extends MatchSource
## Ağ oyununda istemcinin oyun kaynağı: hosttan gelen olayları sıraya alır ve ekran bir olayı
## bitirmeden sıradakini vermez. Ekranın gördüğü kopya oturumun kopyasından ayrıdır; olay ekrana
## verilmeden hemen önce ona uygulanır, böylece ekran olayı yerel oyundaki gibi uygulanmış
## görünümle çizer. Ekran olayı bitirince hosta bildirilir; host her olayda bütün ekranları
## bekler. Görünümün tamamı yeniden gelirse sıradaki olaylar atılır (yeni görünüm onları içerir).
## Olay ekranın kopyasına uymazsa (kopya kaymış) ekrana verilmez: görünümün tamamı hosttan
## istenir ve o gelene kadar ekrana olay verilmez.
## Saat, hostun sıra başlarında bildirdiği süreden ileri sayar. Sıra süresi hostun bildirdiği
## andan yerel saatle sayılır; süre dolunca oyuncunun niyeti artık beklenmez (host o hamleyi bota
## oynatır) ve gelen ret seçimi yeniden açmaz. Oyun bitince kaynak yeniden begin() bekler: host
## tekrar oynarsa yeni oyunun görünümü gelir, olaylar ekran yeni oyunu başlatana kadar sırada kalır.
## Ödül olaylarında oyuncunun niyeti beklenmeye devam eder; sıra süresi durur, ödül bitince host
## kalan süreyi bildirir. Host oyunu molaya alınca saat ve sıra süresi durur, devamda kaldıkları
## yerden sürer. Oyun içi
## reklamın anı saklanır; oyun sonu reklamı bu cihazın kuralıyla ona göre atlanır.

const MSEC_PER_SECOND := 1000.0
## Sıra süresi işlemiyorken bitiş anı yerine kullanılır.
const NO_DEADLINE := -1

var _room: GuestRoom
var _session: ClientSession
## Ekranın gördüğü kopya; ilk görünüm gelene kadar null.
var _display: MatchView
var _queue: Array[MatchEvent] = []
## Ekranın bitirmesi beklenen olay.
var _shown: MatchEvent
var _begun := false
var _pumping := false
var _awaiting := false
## Ekranın kopyası bir olaya uymadı; görünümün tamamı bekleniyor.
var _resyncing := false
## Niyet gönderildikten sonra gelen olay sayısı; sıfırsa gelen ret bu niyetindir.
var _events_since_submit := 0
## Oyuncu çıktıysa ya da bağlantı koptuysa true.
var _closed := false
var _clock_base := 0.0
var _clock_start := 0
var _clock_running := false
## Sıra süresinin bittiği an (Time.get_ticks_msec); süre işlemiyorsa NO_DEADLINE.
var _turn_deadline := NO_DEADLINE
## Bağlantı kopukken ya da molada donan kalan süre; donmuş süre yoksa MatchReferee.NO_TURN_TIMER.
var _frozen_time := MatchReferee.NO_TURN_TIMER
var _connection_lost := false
## Bu oyunda son oyun içi reklamın oyun süresi; reklam yoksa AdSchedule.NO_AD.
var _last_ad_at := AdSchedule.NO_AD


func _init(room: GuestRoom) -> void:
	_room = room
	_session = room.session
	_session.view_reset.connect(_on_view_reset)
	_session.event_received.connect(_on_event_received)
	_session.intent_rejected.connect(_on_intent_rejected)
	_session.turn_timer_started.connect(_on_turn_timer_started)
	_session.pause_changed.connect(_on_pause_changed)
	_session.speed_changed.connect(speed_changed.emit)
	_room.lost.connect(_on_lost)
	_room.connection_changed.connect(_on_connection_changed)


func view() -> MatchView:
	return _display


func elapsed() -> float:
	if not _clock_running:
		return _clock_base
	return _clock_base + (Time.get_ticks_msec() - _clock_start) / MSEC_PER_SECOND


## Yeni oyun başlar (tekrar oynamada da); önceki oyunun reklamı sayılmaz.
func begin() -> void:
	if not _begun:
		_last_ad_at = AdSchedule.NO_AD
	_begun = true
	_set_clock(_clock_base, _clock_may_run())
	_pump()


func acknowledge(event: MatchEvent) -> void:
	if event != _shown:
		return
	_shown = null
	_session.finish_event(event)
	_pump()


func submit(intent: MatchIntent) -> void:
	# Ödül niyetinden sonra sıra yine bu oyuncudadır; bekleme sürer.
	if not intent.is_reward():
		_awaiting = false
	_events_since_submit = 0
	_session.send_intent(intent)


func is_awaiting_intent() -> bool:
	return _awaiting and not _timer_expired()


func turn_time_left() -> float:
	if _frozen_time != MatchReferee.NO_TURN_TIMER:
		return _frozen_time
	if _turn_deadline == NO_DEADLINE or _timer_expired():
		return MatchReferee.NO_TURN_TIMER
	return (_turn_deadline - Time.get_ticks_msec()) / MSEC_PER_SECOND


## Hosta çıkış bildirilir (koltuğu bot alır) ve bağlantı kapanır.
func leave() -> void:
	if _closed:
		return
	_close()
	_session.leave()
	_room.close()


func detach() -> void:
	_session.view_reset.disconnect(_on_view_reset)
	_session.event_received.disconnect(_on_event_received)
	_session.intent_rejected.disconnect(_on_intent_rejected)
	_session.turn_timer_started.disconnect(_on_turn_timer_started)
	_session.pause_changed.disconnect(_on_pause_changed)
	_session.speed_changed.disconnect(speed_changed.emit)
	_room.lost.disconnect(_on_lost)
	_room.connection_changed.disconnect(_on_connection_changed)


func is_paused() -> bool:
	return _session.is_paused()


func pause_time() -> float:
	return _session.pause_time()


func skips_end_ad() -> bool:
	return AdSchedule.is_recent(_last_ad_at, elapsed(), _display.settings)


func seat_wait(seat: int) -> float:
	return _session.seat_wait(seat)


func is_live() -> bool:
	return not _closed


func is_networked() -> bool:
	return true


func room_code() -> String:
	return _room.code()


func bot_level() -> Bot.Level:
	return HostLobby.BOT_LEVEL


func speed_scale() -> float:
	return GameSpeed.scale_of(_session.speed_level)


func _on_view_reset(received: MatchView) -> void:
	_queue.clear()
	_shown = null
	_resyncing = false
	_display = MatchView.from_dict(received.settings, received.to_dict())
	_awaiting = _session.host_awaiting
	_set_deadline(_session.host_turn_time)
	_update_turn_freeze()
	_set_clock(_display.elapsed, _clock_may_run())
	view_reset.emit()


func _on_event_received(event: MatchEvent) -> void:
	_events_since_submit += 1
	_queue.append(event)
	_pump()


## Ekran olayı hemen bitirirse sıradaki aynı döngüde verilir (iç içe çağrı birikmez).
func _pump() -> void:
	if _pumping:
		return
	_pumping = true
	while _begun and not _closed and not _resyncing and _shown == null and not _queue.is_empty():
		_show(_queue.pop_front())
	_pumping = false


func _show(event: MatchEvent) -> void:
	if not _display.apply(event):
		push_warning("Olay ekrana uymadı, görünüm yeniden isteniyor: tür %d" % event.kind)
		_resyncing = true
		_session.request_view()
		return
	_shown = event
	_set_deadline(MatchReferee.NO_TURN_TIMER)
	if not MatchEvent.REWARD_KINDS.has(event.kind):
		_awaiting = (
			event.kind == MatchEvent.Kind.TURN_STARTED and event.seat == _display.viewer_seat
		)
	if event.kind == MatchEvent.Kind.AD_DUE:
		_last_ad_at = elapsed()
	elif event.kind == MatchEvent.Kind.TURN_STARTED:
		_set_clock(event.elapsed, _clock_may_run())
	elif event.kind == MatchEvent.Kind.REWARD_STARTED:
		_set_clock(elapsed(), false)
	elif event.kind == MatchEvent.Kind.REWARD_ENDED:
		_set_clock(elapsed(), _clock_may_run())
	elif event.kind == MatchEvent.Kind.MATCH_OVER:
		_set_clock(elapsed(), false)
		_begun = false
	event_emitted.emit(event)


## Host niyeti reddetti; arada olay gelmediyse oyuncu yeniden seçebilir.
func _on_intent_rejected(_intent: MatchIntent) -> void:
	if _closed or _events_since_submit > 0 or not _display.is_viewer_turn() or _timer_expired():
		return
	_awaiting = true
	intent_rejected.emit()


## Süre, sıradaki oyuncununsa (ekranın kopyası hostla aynı yerdeyse) işlemeye başlar.
func _on_turn_timer_started(seat: int, seconds: float) -> void:
	if not _closed and _display != null and seat == _display.current_seat():
		_set_deadline(seconds)
		_update_turn_freeze()


## seconds NO_TURN_TIMER ise süre durur.
func _set_deadline(seconds: float) -> void:
	_frozen_time = MatchReferee.NO_TURN_TIMER
	if seconds == MatchReferee.NO_TURN_TIMER:
		_turn_deadline = NO_DEADLINE
	else:
		_turn_deadline = Time.get_ticks_msec() + int(seconds * MSEC_PER_SECOND)


func _timer_expired() -> bool:
	return _turn_deadline != NO_DEADLINE and Time.get_ticks_msec() >= _turn_deadline


func _on_lost(loss: GuestRoom.Loss) -> void:
	if _closed:
		return
	_close()
	ended.emit(loss == GuestRoom.Loss.HOST_CLOSED)


## Bağlantı kopukken oyuncu hamle yapamaz; sıra süresi donar, düzelince kaldığı yerden sürer
## (host kendi kalan süresini ayrıca bildirir).
func _on_connection_changed(lost: bool) -> void:
	if _closed:
		return
	_connection_lost = lost
	_update_turn_freeze()
	connection_changed.emit(lost)


## Molada saat ve sıra süresi durur; devamda kaldıkları yerden sürer (host kalan sıra süresini
## ayrıca bildirir).
func _on_pause_changed(paused: bool) -> void:
	if _closed:
		return
	_set_clock(elapsed(), _clock_may_run())
	_update_turn_freeze()
	pause_changed.emit(paused)


## Bağlantı kopukken ya da molada sıra süresi donar; ikisi de bitince donan süre işlemeye başlar.
func _update_turn_freeze() -> void:
	var frozen := _frozen_time != MatchReferee.NO_TURN_TIMER
	if _connection_lost or _session.is_paused():
		if not frozen:
			var left := turn_time_left()
			_turn_deadline = NO_DEADLINE
			_frozen_time = left
	elif frozen:
		_set_deadline(_frozen_time)


## Saat oyun başlamışsa ve mola yoksa işler.
func _clock_may_run() -> bool:
	return _begun and not _session.is_paused()


func _close() -> void:
	_closed = true
	_awaiting = false
	_set_deadline(MatchReferee.NO_TURN_TIMER)
	_set_clock(elapsed(), false)


func _set_clock(seconds: float, running: bool) -> void:
	_clock_base = seconds
	_clock_start = Time.get_ticks_msec()
	_clock_running = running
