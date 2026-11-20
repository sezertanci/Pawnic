class_name ClientSession
extends RefCounted
## Ağ oyununda istemcinin bağdaştırıcısı: hosta el sıkışır, niyet gönderir ve hosttan gelen görünüm
## ile olaylarla kopyasını (MatchView) güncel tutar. Yalnızca hosttan (HOST_PEER) gelen mesajlar
## okunur. Olay kopyayla uyuşmazsa görünümün tamamı yeniden istenir; o gelene kadar olaylar
## yok sayılır (yeni görünüm onları zaten içerir). El sıkışınca hosta düzenli aralıkla HEARTBEAT
## gönderilir; oyun sürerken hosttan bir süredir ses gelmezse bu bildirilir. WELCOME'daki yeniden
## katılma anahtarı saklanır ve yeniden bağlanırken HELLO ile gönderilir.

## Host el sıkışmayı kabul etti.
signal welcomed
## Host el sıkışmayı reddetti (MatchMessage.Refusal).
signal refused(reason: int)
## Görünümün tamamı geldi (oyun başı ya da yeniden istenen görünüm); kopya bununla değişti.
signal view_reset(view: MatchView)
## Olay kopyaya uygulandı.
signal event_received(event: MatchEvent)
## Host niyeti reddetti.
signal intent_rejected(intent: MatchIntent)
## Lobinin hâli değişti (oyuncu, renk ya da ayar).
signal lobby_changed(info: LobbyInfo)
## Sıradaki insan oyuncunun sıra süresi başladı.
signal turn_timer_started(seat: int, seconds: float)
## Oyun sürerken hostun sesi kesildi (silent true) ya da yeniden geldi.
signal host_silent_changed(silent: bool)
## Host odayı kapattı.
signal closed_by_host

## İstemcinin kopyası; ilk görünüm gelene kadar null.
var view: MatchView
## Son görünümle gelen hostun oyun hızı seviyesi (GameSpeed.Level).
var speed_level: int = GameSpeed.Level.NORMAL
## Son görünüm geldiğinde host bu oyuncunun niyetini bekliyorsa true.
var host_awaiting := false
## Son görünüm geldiğinde sıradaki oyuncunun sıra süresinden kalan (saniye); süre işlemiyorsa
## MatchReferee.NO_TURN_TIMER.
var host_turn_time := MatchReferee.NO_TURN_TIMER
## Lobinin son hâli; ilk lobi mesajı gelene kadar null.
var lobby: LobbyInfo
## Hostun verdiği yeniden katılma anahtarı; el sıkışılmadıysa boş.
var token := ""
## Şimdiki anı (ms) veren saat; testte sahte saatle değiştirilir.
var clock: Callable = Callable(Time, &"get_ticks_msec")

var _transport: MatchTransport
var _settings: GameSettings
var _welcomed := false
## Görünümün tamamı istendi ve henüz gelmedi.
var _awaiting_snapshot := false
var _watch: PeerWatch
## Koltukların bağlantı durumu, hostun bildirdiği kadarıyla.
var _presence := SeatPresence.new()
var _host_silent := false


func _init(transport: MatchTransport, settings: GameSettings) -> void:
	_transport = transport
	_settings = settings
	_watch = PeerWatch.new(settings)
	_transport.message_received.connect(_on_message)
	Engine.get_main_loop().process_frame.connect(_on_frame)


## Hosta oda koduyla ve (yeniden bağlanırken) yeniden katılma anahtarıyla el sıkışma mesajını
## gönderir.
func join(room_code: String = "") -> void:
	var hello := MatchMessage.hello(_settings, room_code, token)
	_transport.send(MatchTransport.HOST_PEER, hello)


## Oyun sürerken hostun sesi kesildiyse true.
func is_host_silent() -> bool:
	return _host_silent


## Koltuğu bot alana kadar kalan saniye; süre dolduysa 0, oyuncu bağlıysa SeatPresence.PRESENT.
func seat_wait(seat: int) -> float:
	return _presence.wait_left(seat, clock.call())


## Hostla bağlantı koptu; yeniden el sıkışana kadar hosta mesaj gönderilmez. Kopya ve anahtar
## yeniden katılmak için saklanır.
func drop_connection() -> void:
	_welcomed = false
	_host_silent = false
	_watch.forget(MatchTransport.HOST_PEER)


## Lobide seçilen rengi hosta gönderir; el sıkışma bitmemişse gönderilmez.
func choose_color(color: int) -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.color_choice(color))


## Niyeti hosta gönderir; el sıkışma bitmemişse gönderilmez.
func send_intent(intent: MatchIntent) -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.intent(intent))


## Hosta ekranın olayı bitirdiğini bildirir; host bütün ekranları bekler.
func finish_event(event: MatchEvent) -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.event_done(event.serial))


## Hosta oyundan çıktığını bildirir; koltuğunu bot alır.
func leave() -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.leave())


func _on_message(peer_id: int, message: Dictionary) -> void:
	if peer_id != MatchTransport.HOST_PEER:
		return
	var type := MatchMessage.type_of(message)
	var data := MatchMessage.data_of(message)
	if type == MatchMessage.Type.WELCOME:
		_greet(data)
	elif type == MatchMessage.Type.REFUSED:
		refused.emit(MessageData.read_int(data, MatchMessage.KEY_REASON))
	elif _welcomed:
		_hear_host()
		_dispatch(type, data)


## Yeniden katılınca koltukların durumu baştan gelir.
func _greet(data: Dictionary) -> void:
	token = MatchMessage.token_of(data)
	_welcomed = true
	_presence = SeatPresence.new()
	_watch.heard(MatchTransport.HOST_PEER, clock.call())
	welcomed.emit()


func _dispatch(type: int, data: Dictionary) -> void:
	if type == MatchMessage.Type.LOBBY:
		_update_lobby(data)
	elif type == MatchMessage.Type.SNAPSHOT:
		_reset(data)
	elif type == MatchMessage.Type.EVENT:
		_apply(data)
	elif type == MatchMessage.Type.TURN_TIMER:
		_start_turn_timer(data)
	elif type == MatchMessage.Type.REJECTED:
		var intent := MatchIntent.from_dict(data)
		if intent != null:
			intent_rejected.emit(intent)
	elif type == MatchMessage.Type.SEAT_STATUS:
		_update_presence(data)
	elif type == MatchMessage.Type.CLOSED:
		closed_by_host.emit()


func _hear_host() -> void:
	_watch.heard(MatchTransport.HOST_PEER, clock.call())
	if _host_silent:
		_set_host_silent(false)


func _set_host_silent(silent: bool) -> void:
	_host_silent = silent
	host_silent_changed.emit(silent)


## Bozuk ya da ayarlardaki bekleme süresinden uzun durum yok sayılır.
func _update_presence(data: Dictionary) -> void:
	var seat := MessageData.read_int(data, MessageData.KEY_SEAT)
	var seconds: Variant = data.get(MatchMessage.KEY_SECONDS)
	if seat == MessageData.INVALID or not MessageData.is_number(seconds):
		return
	if seconds == SeatPresence.PRESENT:
		_presence.mark_present(seat)
	elif seconds >= 0.0 and seconds <= _settings.rejoin_wait_time:
		_presence.mark_away(seat, seconds, clock.call())


## Hosta yoklama gönderir; oyun sürerken hostun sesi kesildiyse bildirir.
func _on_frame() -> void:
	if not _welcomed:
		return
	var now: int = clock.call()
	if _watch.update(now):
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.heartbeat())
	var silent := _watch.is_silent(MatchTransport.HOST_PEER, now)
	if view != null and silent and not _host_silent:
		_set_host_silent(true)


## Bozuk lobi yok sayılır.
func _update_lobby(data: Dictionary) -> void:
	var received := LobbyInfo.from_dict(_settings, data)
	if received != null:
		lobby = received
		lobby_changed.emit(lobby)


## Bozuk görünüm (hız, bekleme bayrağı ve sıra süresi dahil) yok sayılır; kopya değişmez.
func _reset(data: Dictionary) -> void:
	var received := MatchView.from_dict(_settings, data)
	var levels := _settings.speed_levels.size()
	var level := MessageData.read_index(data, MatchMessage.KEY_SPEED, 0, levels)
	var awaiting: Variant = data.get(MatchMessage.KEY_AWAITING)
	var turn_time: Variant = data.get(MatchMessage.KEY_TURN_TIME)
	if received == null or level == MessageData.INVALID or not awaiting is bool:
		return
	if not _is_turn_time(turn_time) and not _is_no_turn_time(turn_time):
		return
	view = received
	speed_level = level
	host_awaiting = awaiting
	host_turn_time = turn_time
	_awaiting_snapshot = false
	view_reset.emit(view)


## Bozuk ya da ayarlardaki süreden uzun süre yok sayılır.
func _start_turn_timer(data: Dictionary) -> void:
	var seat := MessageData.read_int(data, MessageData.KEY_SEAT)
	var seconds: Variant = data.get(MatchMessage.KEY_SECONDS)
	if view == null or seat == MessageData.INVALID or not _is_turn_time(seconds):
		return
	turn_timer_started.emit(seat, seconds)


func _is_turn_time(value: Variant) -> bool:
	return MessageData.is_number(value) and value > 0.0 and value <= _settings.turn_time_limit


func _is_no_turn_time(value: Variant) -> bool:
	return MessageData.is_number(value) and value == MatchReferee.NO_TURN_TIMER


func _apply(data: Dictionary) -> void:
	if view == null or _awaiting_snapshot:
		return
	var event := MatchEvent.from_dict(data)
	var serial := MessageData.read_int(data, MatchMessage.KEY_SERIAL)
	if event == null or serial == MessageData.INVALID or not view.apply(event):
		_awaiting_snapshot = true
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.snapshot_request())
		return
	event.serial = serial
	event_received.emit(event)
