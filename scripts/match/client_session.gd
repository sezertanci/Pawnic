class_name ClientSession
extends RefCounted
## Ağ oyununda istemcinin bağdaştırıcısı: hosta el sıkışır, niyet gönderir ve hosttan gelen görünüm
## ile olaylarla kopyasını (MatchView) güncel tutar. Yalnızca hosttan (HOST_PEER) gelen mesajlar
## okunur. Olay kopyayla uyuşmazsa görünümün tamamı yeniden istenir; o gelene kadar olaylar
## yok sayılır (yeni görünüm onları zaten içerir).

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

## İstemcinin kopyası; ilk görünüm gelene kadar null.
var view: MatchView
## Son görünümle gelen hostun oyun hızı seviyesi (GameSpeed.Level).
var speed_level: int = GameSpeed.Level.NORMAL
## Son görünüm geldiğinde host bu oyuncunun niyetini bekliyorsa true.
var host_awaiting := false
## Lobinin son hâli; ilk lobi mesajı gelene kadar null.
var lobby: LobbyInfo

var _transport: MatchTransport
var _settings: GameSettings
var _welcomed := false
## Görünümün tamamı istendi ve henüz gelmedi.
var _awaiting_snapshot := false


func _init(transport: MatchTransport, settings: GameSettings) -> void:
	_transport = transport
	_settings = settings
	_transport.message_received.connect(_on_message)


## Hosta oda koduyla el sıkışma mesajını gönderir.
func join(room_code: String = "") -> void:
	_transport.send(MatchTransport.HOST_PEER, MatchMessage.hello(_settings, room_code))


## Lobide seçilen rengi hosta gönderir; el sıkışma bitmemişse gönderilmez.
func choose_color(color: int) -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.color_choice(color))


## Niyeti hosta gönderir; el sıkışma bitmemişse gönderilmez.
func send_intent(intent: MatchIntent) -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.intent(intent))


## Hosta ekranın son olayı bitirdiğini bildirir; host bütün ekranları bekler.
func finish_event() -> void:
	if _welcomed:
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.event_done())


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
		_welcomed = true
		welcomed.emit()
	elif type == MatchMessage.Type.REFUSED:
		refused.emit(MessageData.read_int(data, MatchMessage.KEY_REASON))
	elif not _welcomed:
		return
	elif type == MatchMessage.Type.LOBBY:
		_update_lobby(data)
	elif type == MatchMessage.Type.SNAPSHOT:
		_reset(data)
	elif type == MatchMessage.Type.EVENT:
		_apply(data)
	elif type == MatchMessage.Type.REJECTED:
		var intent := MatchIntent.from_dict(data)
		if intent != null:
			intent_rejected.emit(intent)


## Bozuk lobi yok sayılır.
func _update_lobby(data: Dictionary) -> void:
	var received := LobbyInfo.from_dict(_settings, data)
	if received != null:
		lobby = received
		lobby_changed.emit(lobby)


## Bozuk görünüm (hız ve bekleme bayrağı dahil) yok sayılır; kopya değişmez.
func _reset(data: Dictionary) -> void:
	var received := MatchView.from_dict(_settings, data)
	var levels := _settings.speed_levels.size()
	var level := MessageData.read_index(data, MatchMessage.KEY_SPEED, 0, levels)
	var awaiting: Variant = data.get(MatchMessage.KEY_AWAITING)
	if received == null or level == MessageData.INVALID or not awaiting is bool:
		return
	view = received
	speed_level = level
	host_awaiting = awaiting
	_awaiting_snapshot = false
	view_reset.emit(view)


func _apply(data: Dictionary) -> void:
	if view == null or _awaiting_snapshot:
		return
	var event := MatchEvent.from_dict(data)
	if event == null or not view.apply(event):
		_awaiting_snapshot = true
		_transport.send(MatchTransport.HOST_PEER, MatchMessage.snapshot_request())
		return
	event_received.emit(event)
