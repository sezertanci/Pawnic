class_name FakeTransport
extends MatchTransport
## Test ve geliştirmede kullanılan sahte taşıyıcı: aynı süreçteki eşleri birbirine bağlar. Mesaj
## ağdaki gibi baytlara çevrilip geri okunur (nesne çözme kapalı), alıcıya bir kare sonra ulaşır.

var _peer_id: int
## Aynı ağdaki eşler (eş numarası → WeakRef); bütün bağlı taşıyıcılar aynı sözlüğü paylaşır.
## Zayıf başvuru, taşıyıcıların sözlük üzerinden birbirini canlı tutmasını önler.
var _network: Dictionary


func _init(peer_id: int, network: Dictionary) -> void:
	_peer_id = peer_id
	_network = network
	_network[peer_id] = weakref(self)


func own_peer() -> int:
	return _peer_id


## Bağlı olmayan eşe giden ya da ağdan çıkmış eşin gönderdiği mesaj, ağdaki gibi kaybolur.
func send(peer_id: int, message: Dictionary) -> void:
	var target := _linked(peer_id)
	if target == null or not _network.has(_peer_id):
		return
	var copy: Variant = bytes_to_var(var_to_bytes(message))
	target.message_received.emit.call_deferred(_peer_id, copy)


func kick(peer_id: int) -> void:
	var target := _linked(peer_id)
	if target != null:
		target.disconnect_peer()


## Eşi ağdan çıkarır (bağlantının kopması); iki uç da bir kare sonra peer_disconnected alır.
func disconnect_peer() -> void:
	if not _network.erase(_peer_id):
		return
	for peer_id: int in _network:
		var other := _linked(peer_id)
		if other != null:
			other.peer_disconnected.emit.call_deferred(_peer_id)
			peer_disconnected.emit.call_deferred(peer_id)


func _linked(peer_id: int) -> FakeTransport:
	var link: WeakRef = _network.get(peer_id)
	return null if link == null else link.get_ref()
