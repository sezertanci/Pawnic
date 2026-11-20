class_name ENetTransport
extends MatchTransport
## Yerel ağdaki gerçek taşıyıcı (ENet, UDP). Host yalnızca verilen özel ağ adresinde dinler ve en
## fazla oyuncu sayısının bir eksiği kadar istemci kabul eder. Gelen paket güvenilmezdir: sınırdan
## büyüğü çözülmeden, eş başına saniyedeki sınırı aşanlar okunmadan atılır (bağlantı kesilmez).
## Paket nesne çözme kapalıyken okunur; sözlük olmayan atılır. Paketler her karede okunur.

## Bağlantı yokken eş numarası.
const NO_PEER := 0
const MSEC_PER_SEC := 1000

var _settings: GameSettings
var _peer: ENetMultiplayerPeer
## Bağlı eşler; bağlı olmayan eşe mesaj gönderilmez.
var _peers: Array[int] = []
## Eş başına sıklık penceresi: pencerenin başladığı an (ms) ve penceredeki mesaj sayısı.
var _window_starts: Dictionary[int, int] = {}
var _window_counts: Dictionary[int, int] = {}


func _init(settings: GameSettings) -> void:
	_settings = settings
	Engine.get_main_loop().process_frame.connect(_poll)


## Hostu verilen adreste kurar; adres izinli değilse ya da port açılamazsa false.
func host(bind_address: String) -> bool:
	if _peer != null or not LocalAddress.is_allowed(bind_address):
		return false
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_address)
	if peer.create_server(_settings.network_port, _settings.max_players - 1) != OK:
		return false
	_attach(peer)
	return true


## Hosta bağlanmaya başlar; adres izinli değilse ya da bağlantı kurulamazsa false. Bağlantı
## kurulunca peer_connected(HOST_PEER) gelir.
func join(address: String) -> bool:
	if _peer != null or not LocalAddress.is_allowed(address):
		return false
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, _settings.network_port) != OK:
		return false
	_attach(peer)
	return true


## Bağlantıyı kapatır; taşıyıcı yeniden kurulabilir.
func close() -> void:
	if _peer == null:
		return
	_peer.close()
	_peer = null
	_peers.clear()
	_window_starts.clear()
	_window_counts.clear()


func own_peer() -> int:
	return NO_PEER if _peer == null else _peer.get_unique_id()


func send(peer_id: int, message: Dictionary) -> void:
	if not _peers.has(peer_id):
		return
	_peer.set_target_peer(peer_id)
	_peer.put_packet(var_to_bytes(message))


func _attach(peer: ENetMultiplayerPeer) -> void:
	_peer = peer
	_peer.peer_connected.connect(_on_peer_connected)
	_peer.peer_disconnected.connect(_on_peer_disconnected)


func _poll() -> void:
	if _peer == null:
		return
	_peer.poll()
	while _peer != null and _peer.get_available_packet_count() > 0:
		var peer_id := _peer.get_packet_peer()
		_receive(peer_id, _peer.get_packet())


func _receive(peer_id: int, bytes: PackedByteArray) -> void:
	if bytes.size() > _settings.max_message_bytes or not _within_rate(peer_id):
		return
	var message: Variant = bytes_to_var(bytes)
	if message is Dictionary:
		message_received.emit(peer_id, message)


## Eşin bu saniyedeki mesaj sayısını artırır; sınır aşıldıysa false.
func _within_rate(peer_id: int) -> bool:
	var now := Time.get_ticks_msec()
	if now - _window_starts.get(peer_id, now - MSEC_PER_SEC) >= MSEC_PER_SEC:
		_window_starts[peer_id] = now
		_window_counts[peer_id] = 0
	_window_counts[peer_id] += 1
	return _window_counts[peer_id] <= _settings.max_messages_per_sec


func _on_peer_connected(peer_id: int) -> void:
	_peers.append(peer_id)
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_peers.erase(peer_id)
	_window_starts.erase(peer_id)
	_window_counts.erase(peer_id)
	peer_disconnected.emit(peer_id)
