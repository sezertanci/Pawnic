class_name HostSession
extends RefCounted
## Ağ oyununda hostun bağdaştırıcısı: taşıyıcıdan gelen mesajları hakeme (MatchReferee), hakemin
## olaylarını eşlere taşır. Eş ancak el sıkışmadan (HELLO → WELCOME) geçip bir koltuğa oturtulunca
## oyuna katılır. Niyetteki koltuk alanına güvenilmez; koltuk, eşin oturtulduğu koltuktur. Host
## yalnızca kendi ekranının bitirmesini bekler; olaylar eşlere beklemeden gider. Reddedilen eşe
## REFUSED gönderilip bağlantısı kesilir. Oyundan çıkan (LEAVE) eşin koltuğunu kalıcı olarak bot
## alır; eşe artık olay gitmez.

## Eş el sıkışmadan geçti.
signal peer_welcomed(peer_id: int)

## Sürümü uyan eşin kabul denetimi (ör. lobinin oda kodu): HELLO içeriğini alır, ret nedenini
## (MatchMessage.Refusal) ya da MatchMessage.NO_REFUSAL döndürür. Boşsa her uyumlu eş kabul edilir.
var admission: Callable
## Görünümle eşlere giden oyun hızı seviyesi (GameSpeed.Level); hostun seçtiği hızdır.
var speed_level: int = GameSpeed.Level.NORMAL

var _referee: MatchReferee
var _transport: MatchTransport
var _settings: GameSettings
## El sıkışmadan geçen eşler.
var _welcomed: Array[int] = []
## Oturtulan eşler: eş numarası → koltuk.
var _seats: Dictionary[int, int] = {}


func _init(referee: MatchReferee, transport: MatchTransport, settings: GameSettings) -> void:
	_referee = referee
	_transport = transport
	_settings = settings
	_transport.message_received.connect(_on_message)
	_referee.event_emitted.connect(_on_event)


## Eşi koltuğa oturtur; eş el sıkışmadan geçmemişse ya da koltuk ya da eş zaten eşlenmişse false.
func seat_peer(peer_id: int, seat: int) -> bool:
	if not _welcomed.has(peer_id) or _seats.has(peer_id) or _seats.values().has(seat):
		return false
	_seats[peer_id] = seat
	return true


## Eşin koltuğu; oturtulmamışsa NO_SEAT.
func seat_of(peer_id: int) -> int:
	return _seats.get(peer_id, BoardLayout.NO_SEAT)


## Hakemin oyununu her eşe kendi görünümüyle gönderir; oyun başında, hakemin start()'ından sonra
## çağrılır.
func share_match() -> void:
	for peer_id: int in _seats:
		_send_snapshot(peer_id)


func _on_message(peer_id: int, message: Dictionary) -> void:
	var data := MatchMessage.data_of(message)
	match MatchMessage.type_of(message):
		MatchMessage.Type.HELLO:
			_greet(peer_id, data)
		MatchMessage.Type.INTENT:
			_take_intent(peer_id, data)
		MatchMessage.Type.SNAPSHOT_REQUEST:
			_send_snapshot(peer_id)
		MatchMessage.Type.LEAVE:
			_release_seat(peer_id)


func _greet(peer_id: int, data: Dictionary) -> void:
	if _welcomed.has(peer_id):
		return
	var reason := _refusal(data)
	if reason != MatchMessage.NO_REFUSAL:
		_transport.send(peer_id, MatchMessage.refused(reason))
		_transport.kick(peer_id)
		return
	_welcomed.append(peer_id)
	_transport.send(peer_id, MatchMessage.welcome())
	peer_welcomed.emit(peer_id)


func _refusal(data: Dictionary) -> int:
	if not MatchMessage.is_compatible(data, _settings):
		return MatchMessage.Refusal.VERSION_MISMATCH
	return MatchMessage.NO_REFUSAL if admission.is_null() else admission.call(data)


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
	_transport.send(peer_id, MatchMessage.snapshot(view, speed_level, awaiting))


## Eş oyundan çıktı: koltuğu bota geçer, eş oyundan düşer.
func _release_seat(peer_id: int) -> void:
	var seat := seat_of(peer_id)
	if seat == BoardLayout.NO_SEAT:
		return
	_seats.erase(peer_id)
	if _referee.game != null:
		_referee.hand_to_bot(seat)


func _on_event(event: MatchEvent) -> void:
	for peer_id: int in _seats:
		_transport.send(peer_id, MatchMessage.event(event, _seats[peer_id]))
