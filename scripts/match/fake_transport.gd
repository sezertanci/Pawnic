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


## Bağlı olmayan eşe giden mesaj, ağdaki gibi kaybolur.
func send(peer_id: int, message: Dictionary) -> void:
	var link: WeakRef = _network.get(peer_id)
	var target: FakeTransport = null if link == null else link.get_ref()
	if target == null:
		return
	var copy: Variant = bytes_to_var(var_to_bytes(message))
	target.message_received.emit.call_deferred(_peer_id, copy)


## Eşi ağdan çıkarır (bağlantının kopması).
func disconnect_peer() -> void:
	_network.erase(_peer_id)
