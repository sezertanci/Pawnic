class_name HostSession
extends RefCounted
## Ağ oyununda hostun bağdaştırıcısı: taşıyıcıdan gelen mesajları hakeme (MatchReferee), hakemin
## olaylarını eşlere taşır. Eş ancak el sıkışmadan (HELLO → WELCOME) geçip bir koltuğa oturtulunca
## oyuna katılır. Niyetteki koltuk alanına güvenilmez; koltuk, eşin oturtulduğu koltuktur. Olaylar
## eşlere hemen gider ve hakem, hostun ekranıyla birlikte oturan her eşin olayı bitirmesini
## (EVENT_DONE) bekler; böylece animasyonlar her cihazda birlikte başlar. Görünümü yeniden istenen
## ya da çıkan eş beklenmez; eski olayın bitirme bildirimi sayılmaz. Reddedilen eşe REFUSED
## gönderilip bağlantısı kesilir, sessizlik sınırı içinde el sıkışmayan eşin de. Oyundan çıkan
## (LEAVE) eşin koltuğunu kalıcı olarak bot alır; eşe artık olay gitmez. Sıra süresi başlayınca
## oturan her eşe bildirilir; süreyi herkes görür.
##
## Bağlantı yoklaması: host ve eşler birbirine düzenli aralıkla HEARTBEAT gönderir. Bağlantısı
## kopan ya da bir süredir sesi gelmeyen eşin koltuğu uzakta sayılır ve diğer eşlere bildirilir;
## uzaktaki eşin olayı bitirmesi beklenmez, oyun sürer. Sıra o koltuğa gelirse oyun, bekleme süresi
## (rejoin_wait_sec) dolana kadar durur. Süre dolunca koltuğu, eş dönene kadar bot oynar. Eş aynı
## bağlantıdan sesini duyurunca ya da WELCOME'da aldığı yeniden katılma anahtarıyla yeniden
## bağlanınca koltuğuna döner.

## Eş el sıkışmadan geçti (yeniden katılan eş için gelmez).
signal peer_welcomed(peer_id: int)

## Yeniden katılma anahtarının bayt sayısı.
const TOKEN_BYTES := 16

## Sürümü uyan eşin kabul denetimi (ör. lobinin oda kodu): HELLO içeriğini alır, ret nedenini
## (MatchMessage.Refusal) ya da MatchMessage.NO_REFUSAL döndürür. Boşsa her uyumlu eş kabul edilir.
## Yeniden katılma anahtarıyla gelen eşe uygulanmaz.
var admission: Callable
## Görünümle eşlere giden oyun hızı seviyesi (GameSpeed.Level); hostun seçtiği hızdır.
var speed_level: int = GameSpeed.Level.NORMAL
## Şimdiki anı (ms) veren saat; testte sahte saatle değiştirilir.
var clock: Callable = Callable(Time, &"get_ticks_msec")

var _referee: MatchReferee
var _transport: MatchTransport
var _settings: GameSettings
## El sıkışmadan geçen eşler.
var _welcomed: Array[int] = []
## Oturtulan eşler: eş numarası → koltuk. Bağlantısı kopan eş, koltuğuna dönene ya da çıkana kadar
## burada kalır.
var _seats: Dictionary[int, int] = {}
## Eşlerin yeniden katılma anahtarları: eş numarası → anahtar.
var _tokens: Dictionary[int, String] = {}
## Son olayı henüz bitirmemiş eşler; her biri hakemde bir bekletmedir.
var _pending: Array[int] = []
## Son olayın sıra numarası; eşin bitirdiği olay bununla karşılaştırılır.
var _event_serial := 0
## Bağlanıp henüz el sıkışmayan eşler; sessizlik sınırı içinde HELLO göndermezse bağlantısı
## kesilir (yoksa bağlantı yerini boşuna tutar).
var _greeting: Array[int] = []
var _watch: PeerWatch
var _presence := SeatPresence.new()
## Bekleme süresi dolan, oyuncusu dönene kadar botun oynadığı koltuklar.
var _benched: Array[int] = []
var _crypto := Crypto.new()


func _init(referee: MatchReferee, transport: MatchTransport, settings: GameSettings) -> void:
	_referee = referee
	_transport = transport
	_settings = settings
	_watch = PeerWatch.new(settings)
	_transport.message_received.connect(_on_message)
	_transport.peer_connected.connect(_on_peer_connected)
	_transport.peer_disconnected.connect(_on_peer_disconnected)
	_referee.event_emitted.connect(_on_event)
	_referee.turn_timer_started.connect(_on_turn_timer_started)
	Engine.get_main_loop().process_frame.connect(_on_frame)


## Eşi koltuğa oturtur; eş el sıkışmadan geçmemişse ya da koltuk ya da eş zaten eşlenmişse false.
func seat_peer(peer_id: int, seat: int) -> bool:
	if not _welcomed.has(peer_id) or _seats.has(peer_id) or _seats.values().has(seat):
		return false
	_seats[peer_id] = seat
	return true


## Eşin koltuğu; oturtulmamışsa NO_SEAT.
func seat_of(peer_id: int) -> int:
	return _seats.get(peer_id, BoardLayout.NO_SEAT)


## Koltuğu bot alana kadar kalan saniye; süre dolduysa 0, oyuncu bağlıysa SeatPresence.PRESENT.
func seat_wait(seat: int) -> float:
	return _presence.wait_left(seat, clock.call())


## Hakemin oyununu her eşe kendi görünümüyle gönderir; oyun başında, hakemin start()'ından sonra
## çağrılır.
func share_match() -> void:
	for peer_id: int in _seats:
		_send_snapshot(peer_id)


## Eşlere odanın kapandığını bildirir; bağlantıyı taşıyıcının sahibi kapatır.
func close() -> void:
	for peer_id: int in _welcomed:
		_transport.send(peer_id, MatchMessage.closed())


func _on_message(peer_id: int, message: Dictionary) -> void:
	var type := MatchMessage.type_of(message)
	if type == MatchMessage.Type.LEAVE:
		_release_seat(peer_id)
		return
	if _welcomed.has(peer_id):
		_hear(peer_id)
	var data := MatchMessage.data_of(message)
	match type:
		MatchMessage.Type.HELLO:
			_greet(peer_id, data)
		MatchMessage.Type.INTENT:
			_take_intent(peer_id, data)
		MatchMessage.Type.SNAPSHOT_REQUEST:
			_send_snapshot(peer_id)
			_settle(peer_id)
		MatchMessage.Type.EVENT_DONE:
			if MessageData.read_int(data, MatchMessage.KEY_SERIAL) == _event_serial:
				_settle(peer_id)


## Eşin sesi geldi; koltuğu uzakta sayılıyorsa eş koltuğuna döner.
func _hear(peer_id: int) -> void:
	_watch.heard(peer_id, clock.call())
	var seat := seat_of(peer_id)
	if seat != BoardLayout.NO_SEAT and _presence.is_away(seat):
		_bring_back(seat)
		_send_turn_time(peer_id)


## Sesi kesilip dönen eşin saydığı süre durmuştu; hosttaki kalan süre gönderilir.
func _send_turn_time(peer_id: int) -> void:
	var left := _referee.turn_time_left()
	if _referee.game != null and left != MatchReferee.NO_TURN_TIMER:
		_transport.send(peer_id, MatchMessage.turn_timer(_referee.game.current_seat(), left))


func _greet(peer_id: int, data: Dictionary) -> void:
	if _welcomed.has(peer_id):
		return
	_greeting.erase(peer_id)
	var token := MatchMessage.token_of(data)
	var old := _peer_with_token(token)
	var reason := _refusal(data, token, old)
	if reason != MatchMessage.NO_REFUSAL:
		_transport.send(peer_id, MatchMessage.refused(reason))
		_transport.kick(peer_id)
	elif token.is_empty():
		_welcome(peer_id, _new_token())
		peer_welcomed.emit(peer_id)
	else:
		_rejoin(peer_id, old)


## Anahtarla gelen eş yalnızca anahtarın sahibi oyunda oturuyorsa kabul edilir.
func _refusal(data: Dictionary, token: String, old_peer: int) -> int:
	if not MatchMessage.is_compatible(data, _settings):
		return MatchMessage.Refusal.VERSION_MISMATCH
	if not token.is_empty():
		if old_peer == MatchTransport.NO_PEER:
			return MatchMessage.Refusal.NOT_IN_MATCH
		return MatchMessage.NO_REFUSAL
	return MatchMessage.NO_REFUSAL if admission.is_null() else admission.call(data)


## Anahtarın sahibi olan oturan eş; anahtar boşsa ya da sahibi yoksa NO_PEER.
func _peer_with_token(token: String) -> int:
	if token.is_empty():
		return MatchTransport.NO_PEER
	for peer_id: int in _tokens:
		if _tokens[peer_id] == token and _seats.has(peer_id):
			return peer_id
	return MatchTransport.NO_PEER


func _new_token() -> String:
	return _crypto.generate_random_bytes(TOKEN_BYTES).hex_encode()


func _welcome(peer_id: int, token: String) -> void:
	_welcomed.append(peer_id)
	_tokens[peer_id] = token
	_watch.heard(peer_id, clock.call())
	_transport.send(peer_id, MatchMessage.welcome(token))


## Eş yeni bağlantıyla koltuğuna döndü: eski bağlantı kesilir, eşe oyunun tamamı ve uzaktaki
## koltuklar gönderilir.
func _rejoin(peer_id: int, old_peer: int) -> void:
	var seat := _seats[old_peer]
	var token := _tokens[old_peer]
	_forget_peer(old_peer)
	_transport.kick(old_peer)
	_welcome(peer_id, token)
	_seats[peer_id] = seat
	_bring_back(seat)
	_send_snapshot(peer_id)
	for away: int in _presence.away_seats():
		_transport.send(peer_id, MatchMessage.seat_status(away, seat_wait(away)))


## Koltuğun oyuncusu döndü: botun oynadığı koltuk geri verilir, diğer eşlere bildirilir.
func _bring_back(seat: int) -> void:
	if _benched.has(seat):
		_benched.erase(seat)
		if _referee.game != null:
			_referee.take_back(seat)
	if _presence.mark_present(seat):
		_broadcast_status(seat, SeatPresence.PRESENT)


## Niyet, eşin oturduğu koltuk adına hakeme verilir; hakem reddederse eşe REJECTED gider.
func _take_intent(peer_id: int, data: Dictionary) -> void:
	var seat := seat_of(peer_id)
	var intent := MatchIntent.from_dict(data)
	if seat == BoardLayout.NO_SEAT or intent == null or _referee.game == null:
		return
	intent.seat = seat
	if not _referee.submit(intent):
		_transport.send(peer_id, MatchMessage.rejected(intent))


func _send_snapshot(peer_id: int) -> void:
	var seat := seat_of(peer_id)
	if seat == BoardLayout.NO_SEAT or _referee.game == null:
		return
	var view := MatchView.of(_referee.game, seat)
	var awaiting := _referee.is_awaiting_intent() and _referee.game.current_seat() == seat
	var turn_time := _referee.turn_time_left()
	_transport.send(peer_id, MatchMessage.snapshot(view, speed_level, awaiting, turn_time))


## Eş oyundan çıktı: koltuğu bota geçer, eş oyundan düşer.
func _release_seat(peer_id: int) -> void:
	var seat := seat_of(peer_id)
	if seat == BoardLayout.NO_SEAT:
		return
	_forget_peer(peer_id)
	_benched.erase(seat)
	if _presence.mark_present(seat):
		_broadcast_status(seat, SeatPresence.PRESENT)
	if _referee.game != null:
		_referee.hand_to_bot(seat)


## Eş oturumdan tamamen çıkar; bekletmesi bırakılır.
func _forget_peer(peer_id: int) -> void:
	_seats.erase(peer_id)
	_tokens.erase(peer_id)
	_welcomed.erase(peer_id)
	_watch.forget(peer_id)
	_settle(peer_id)


## Oyun sonu olayı ve uzaktaki koltuk beklenmez (hakem de oyun sonunu beklemez).
func _on_event(event: MatchEvent) -> void:
	_pending.clear()
	_event_serial += 1
	for peer_id: int in _seats:
		_transport.send(peer_id, MatchMessage.event(event, _seats[peer_id], _event_serial))
		if event.kind != MatchEvent.Kind.MATCH_OVER and not _presence.is_away(_seats[peer_id]):
			_pending.append(peer_id)
			_referee.hold()


func _on_turn_timer_started(seat: int, seconds: float) -> void:
	for peer_id: int in _seats:
		_transport.send(peer_id, MatchMessage.turn_timer(seat, seconds))


## Eş son olayı bitirdi ya da artık beklenmiyor; bekletmesi bırakılır.
func _settle(peer_id: int) -> void:
	if _pending.has(peer_id):
		_pending.erase(peer_id)
		_referee.release()


func _on_peer_connected(peer_id: int) -> void:
	_greeting.append(peer_id)
	_watch.heard(peer_id, clock.call())


## Oturan eşin koltuğu, eş dönene ya da çıkana kadar uzakta sayılır; oturmayan eş unutulur.
func _on_peer_disconnected(peer_id: int) -> void:
	_greeting.erase(peer_id)
	var seat := seat_of(peer_id)
	if seat == BoardLayout.NO_SEAT:
		_forget_peer(peer_id)
		return
	_watch.forget(peer_id)
	if not _presence.is_away(seat):
		_mark_away(peer_id, seat)


func _on_frame() -> void:
	var now: int = clock.call()
	if _watch.update(now):
		for peer_id: int in _welcomed:
			_transport.send(peer_id, MatchMessage.heartbeat())
	for peer_id: int in _seats.keys():
		_check_presence(peer_id, now)
	for peer_id: int in _greeting.duplicate():
		if _watch.is_silent(peer_id, now):
			_greeting.erase(peer_id)
			_watch.forget(peer_id)
			_transport.kick(peer_id)


## Sesi kesilen eşin koltuğu uzakta sayılır; bekleme süresi dolan koltuğu bot alır.
func _check_presence(peer_id: int, now: int) -> void:
	var seat := _seats[peer_id]
	if not _presence.is_away(seat):
		if _watch.is_silent(peer_id, now):
			_mark_away(peer_id, seat)
	elif not _benched.has(seat) and _presence.wait_left(seat, now) == 0.0:
		_bench(seat)


## Uzaktaki eşin olayı bitirmesi beklenmez; diğerleri oynamaya devam eder.
func _mark_away(peer_id: int, seat: int) -> void:
	_presence.mark_away(seat, _settings.rejoin_wait_time, clock.call())
	_settle(peer_id)
	_broadcast_status(seat, _settings.rejoin_wait_time)


## Koltuğu, oyuncusu dönene kadar bot oynar.
func _bench(seat: int) -> void:
	_benched.append(seat)
	if _referee.game != null:
		_referee.hand_to_bot(seat)


## Koltuğun durumunu diğer oturan eşlere bildirir.
func _broadcast_status(seat: int, seconds: float) -> void:
	for peer_id: int in _seats:
		if _seats[peer_id] != seat:
			_transport.send(peer_id, MatchMessage.seat_status(seat, seconds))
