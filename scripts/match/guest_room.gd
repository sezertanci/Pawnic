class_name GuestRoom
extends RefCounted
## Ağ oyununda katılan oyuncunun odası: hosta bağlanır, bağlantı kurulunca oda koduyla el sıkışır.
## Host reddederse bağlantı kapatılır ve nedeni bildirilir; bağlantı kendiliğinden koparsa
## (host kapandı ya da hosta ulaşılamadı) bu da bildirilir. Her oda bir kez bağlanır.

## Host el sıkışmayı reddetti (MatchMessage.Refusal); bağlantı kapatıldı.
signal refused(reason: int)
## Bağlantı koptu; was_welcomed, host el sıkışmayı kabul etmişse true.
signal lost(was_welcomed: bool)

var session: ClientSession

var _transport: ENetTransport
var _code := ""
var _welcomed := false


func _init(settings: GameSettings) -> void:
	_transport = ENetTransport.new(settings)
	session = ClientSession.new(_transport, settings)
	_transport.peer_connected.connect(_on_connected)
	_transport.closed.connect(_on_closed)
	session.welcomed.connect(_on_welcomed)
	session.refused.connect(_on_refused)


## Hosta bağlanmaya başlar; adres izinli değilse ya da bağlantı kurulamazsa false.
func join(address: String, room_code: String) -> bool:
	_code = room_code
	return _transport.join(address)


func close() -> void:
	_transport.close()


func _on_connected(peer_id: int) -> void:
	if peer_id == MatchTransport.HOST_PEER:
		session.join(_code)


func _on_welcomed() -> void:
	_welcomed = true


func _on_refused(reason: int) -> void:
	_transport.close()
	refused.emit(reason)


func _on_closed() -> void:
	lost.emit(_welcomed)
