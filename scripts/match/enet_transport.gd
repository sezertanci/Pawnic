class_name ENetTransport
extends MatchTransport
## Yerel ağdaki gerçek taşıyıcı (ENet, UDP). Host yalnızca verilen özel ağ adresinde dinler ve
## oyuncu sayısının bir eksiğinin iki katı kadar bağlantı kabul eder: yeniden bağlanan oyuncunun
## eski bağlantısı düşmeden yenisi de sığar. Bağlanan eşten peer_timeout_ms boyunca yanıt
## alınamazsa bağlantı düşer. Gelen paket güvenilmezdir: sınırdan
## büyüğü çözülmeden, eş başına saniyedeki sınırı aşanlar okunmadan atılır (bağlantı kesilmez).
## Paket nesne çözme kapalıyken okunur; sözlük olmayan atılır. Paketler her karede okunur. Host
## bağlantıyı kesince istemci taşıyıcısı kendini kapatır.

## Bağlantı kendiliğinden kapandı: istemci hosta bağlanamadı ya da host bağlantıyı kesti. close()
## ile kapatınca gelmez.
signal closed

const MSEC_PER_SEC := 1000

var _settings: GameSettings
var _peer: ENetMultiplayerPeer
## Bağlı eşler; bağlı olmayan eşe mesaj gönderilmez.
var _peers: Array[int] = []
## Eş başına sıklık penceresi: pencerenin başladığı an (ms) ve penceredeki mesaj sayısı.
var _window_starts: Dictionary[int, int] = {}
var _window_counts: Dictionary[int, int] = {}
## Bu karede bağlantısı kopan eşler; kopmadan önce gelen paketleri okunduktan sonra bildirilir.
var _gone: Array[int] = []
## Kapatılan bağlantı: kuyruktaki mesajlar karşıya ulaşıp her eşin bağlantısı düzgünce kesilene
## kadar (en fazla connect_timeout_ms) yoklanır, sinyal yayılmaz. Anında kesmede ENet, aynı anda
## gelen son paketleri karşı tarafta siler (ör. oyundan çıkan istemcinin LEAVE mesajı, odayı kapatan
## hostun CLOSED mesajı).
var _draining: ENetMultiplayerPeer
var _drain_deadline := 0


func _init(settings: GameSettings) -> void:
	_settings = settings
	Engine.get_main_loop().process_frame.connect(_poll)


## Hostu verilen adreste kurar; adres izinli değilse ya da port açılamazsa false.
func host(bind_address: String) -> bool:
	if _peer != null or not LocalAddress.is_allowed(bind_address):
		return false
	_stop_draining()
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_address)
	if peer.create_server(_settings.network_port, (_settings.max_players - 1) * 2) != OK:
		return false
	_attach(peer)
	return true


## Hosta bağlanmaya başlar; adres izinli değilse ya da bağlantı kurulamazsa false. Bağlantı
## kurulunca peer_connected(HOST_PEER) gelir. connect_timeout_ms içinde bağlanılamazsa bağlantı
## düşer.
func join(address: String) -> bool:
	if _peer != null or not LocalAddress.is_allowed(address):
		return false
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, _settings.network_port) != OK:
		return false
	var timeout := _settings.connect_timeout_ms
	peer.get_peer(MatchTransport.HOST_PEER).set_timeout(timeout, timeout, timeout)
	_attach(peer)
	return true


## Bağlantıyı kapatır; kuyruktaki mesajlar önce gönderilir. Taşıyıcı yeniden kurulabilir. Yeniden
## kurulan host, önceki bağlantının boşalmasını beklemez.
func close() -> void:
	if _peer == null:
		return
	if _peers.is_empty():
		_peer.close()
	else:
		_drain()
	_release()


## Bağlantıları kuyruk boşaldıktan sonra kesilecek şekilde bırakır.
func _drain() -> void:
	_stop_draining()
	_peer.peer_connected.disconnect(_on_peer_connected)
	_peer.peer_disconnected.disconnect(_on_peer_disconnected)
	for peer: ENetPacketPeer in _peer.host.get_peers():
		peer.peer_disconnect_later()
	_draining = _peer
	_drain_deadline = Time.get_ticks_msec() + _settings.connect_timeout_ms


func _poll_draining() -> void:
	if _draining == null:
		return
	_draining.poll()
	if _is_drained(_draining) or Time.get_ticks_msec() >= _drain_deadline:
		_stop_draining()


## İstemci hostla bağlantısı kesilince, host her eşinin bağlantısı kesilince boşalmış sayılır.
static func _is_drained(peer: ENetMultiplayerPeer) -> bool:
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or peer.host == null:
		return true
	return peer.host.get_peers().all(_is_disconnected)


static func _is_disconnected(peer: ENetPacketPeer) -> bool:
	return peer.get_state() == ENetPacketPeer.STATE_DISCONNECTED


func _stop_draining() -> void:
	if _draining != null:
		_draining.close()
		_draining = null


## Bağlantı kapandı (kendimiz ya da host kesti); taşıyıcı yeniden kurulabilir.
func _release() -> void:
	_peer = null
	_peers.clear()
	_gone.clear()
	_window_starts.clear()
	_window_counts.clear()


## Bağlantı kuyruktaki paketler gönderildikten sonra kesilir; anında kesmede (disconnect_peer)
## kuyruk boşaltılır ve ret mesajı ulaşmaz.
func kick(peer_id: int) -> void:
	if not _peers.has(peer_id):
		return
	_forget(peer_id)
	_peer.get_peer(peer_id).peer_disconnect_later()


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
	_poll_draining()
	if _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_release()
		closed.emit()
	if _peer == null:
		return
	_peer.poll()
	while _peer != null and _peer.get_available_packet_count() > 0:
		var peer_id := _peer.get_packet_peer()
		_receive(peer_id, _peer.get_packet())
	_report_gone()


func _receive(peer_id: int, bytes: PackedByteArray) -> void:
	if not _peers.has(peer_id) or bytes.size() > _settings.max_message_bytes:
		return
	if not _within_rate(peer_id):
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
	var timeout := _settings.peer_timeout_ms
	_peer.get_peer(peer_id).set_timeout(timeout, timeout, timeout)
	_peers.append(peer_id)
	peer_connected.emit(peer_id)


## ENet kopmayı poll() içinde, eşin son paketleri okunmadan bildirir; kopma, paketler okunana
## kadar bekletilir (ör. oyundan çıkan istemcinin LEAVE mesajı kaybolmasın).
func _on_peer_disconnected(peer_id: int) -> void:
	_gone.append(peer_id)


func _report_gone() -> void:
	var gone := _gone.duplicate()
	_gone.clear()
	for peer_id: int in gone:
		_forget(peer_id)
		peer_disconnected.emit(peer_id)


func _forget(peer_id: int) -> void:
	_peers.erase(peer_id)
	_window_starts.erase(peer_id)
	_window_counts.erase(peer_id)
