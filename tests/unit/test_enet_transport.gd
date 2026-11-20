extends GutTest
## ENet taşıyıcısı aynı cihazda (127.0.0.1) host ve istemciyle: mesaj gidiş-dönüşü, boyut ve
## sıklık sınırı, izinsiz adresin reddi ve en fazla istemci sayısı.

## Bağlantı ve mesaj için beklenen en fazla süre (saniye).
const TIMEOUT := 3.0
## Kabul edilmeyen bağlantının gerçekten kurulmadığını görmek için beklenen süre (saniye).
const SETTLE := 0.5
const PUBLIC_ADDRESS := "8.8.8.8"
const ANY_ADDRESS := "0.0.0.0"
const KEY_TEXT := "text"
const KEY_INDEX := "index"

var _settings: GameSettings
var _host: ENetTransport
var _clients: Array[ENetTransport] = []
var _host_inbox: Array[Dictionary] = []
var _client_inbox: Array[Dictionary] = []
## Hostun bağlandığını gördüğü istemciler.
var _host_peers: Array[int] = []


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_host_inbox.clear()
	_client_inbox.clear()
	_clients.clear()
	_host_peers.clear()
	_host = ENetTransport.new(_settings)
	_host.message_received.connect(
		func(_peer: int, message: Dictionary) -> void: _host_inbox.append(message)
	)
	_host.peer_connected.connect(func(peer: int) -> void: _host_peers.append(peer))
	assert_true(_host.host(LocalAddress.LOOPBACK))


func after_each() -> void:
	for client: ENetTransport in _clients:
		client.close()
	_host.close()


func test_messages_travel_both_ways() -> void:
	var client := await _connect()
	client.message_received.connect(
		func(_peer: int, message: Dictionary) -> void: _client_inbox.append(message)
	)
	var peer_id := client.own_peer()

	client.send(MatchTransport.HOST_PEER, {KEY_TEXT: "merhaba"})
	_host.send(peer_id, {KEY_TEXT: "hoş geldin"})
	await wait_until(func() -> bool: return _host_inbox.size() + _client_inbox.size() == 2, TIMEOUT)

	assert_eq(_host_inbox, [{KEY_TEXT: "merhaba"}])
	assert_eq(_client_inbox, [{KEY_TEXT: "hoş geldin"}])


func test_oversized_message_is_dropped() -> void:
	var client := await _connect()
	var big := "x".repeat(_settings.max_message_bytes)

	client.send(MatchTransport.HOST_PEER, {KEY_TEXT: big})
	client.send(MatchTransport.HOST_PEER, {KEY_TEXT: "küçük"})
	await wait_until(func() -> bool: return not _host_inbox.is_empty(), TIMEOUT)
	await wait_seconds(SETTLE)

	assert_eq(_host_inbox, [{KEY_TEXT: "küçük"}])


func test_messages_over_rate_are_dropped() -> void:
	var client := await _connect()

	for index: int in range(_settings.max_messages_per_sec + 5):
		client.send(MatchTransport.HOST_PEER, {KEY_INDEX: index})
	await wait_until(
		func() -> bool: return _host_inbox.size() == _settings.max_messages_per_sec, TIMEOUT
	)
	await wait_seconds(SETTLE)

	assert_eq(_host_inbox.size(), _settings.max_messages_per_sec)
	assert_eq(_host_inbox[0], {KEY_INDEX: 0})


func test_address_outside_local_network_is_refused() -> void:
	var client := ENetTransport.new(_settings)
	var server := ENetTransport.new(_settings)

	assert_false(client.join(PUBLIC_ADDRESS))
	assert_false(server.host(ANY_ADDRESS))
	assert_false(server.host(PUBLIC_ADDRESS))
	assert_eq(client.own_peer(), ENetTransport.NO_PEER)


func test_host_accepts_one_less_than_max_players() -> void:
	var allowed := _settings.max_players - 1
	for _index: int in range(allowed):
		await _connect()
	var extra := ENetTransport.new(_settings)
	_clients.append(extra)
	watch_signals(extra)

	extra.join(LocalAddress.LOOPBACK)
	await wait_seconds(SETTLE)

	assert_signal_not_emitted(extra, "peer_connected")
	assert_eq(_host_peers.size(), allowed)


func test_message_sent_before_kick_arrives() -> void:
	var client := await _connect()
	client.message_received.connect(
		func(_peer: int, message: Dictionary) -> void: _client_inbox.append(message)
	)

	_host.send(client.own_peer(), {KEY_TEXT: "güle güle"})
	_host.kick(client.own_peer())
	await wait_for_signal(client.peer_disconnected, TIMEOUT)

	assert_eq(_client_inbox, [{KEY_TEXT: "güle güle"}])
	assert_signal_emitted_with_parameters(client, "peer_disconnected", [MatchTransport.HOST_PEER])
	await wait_frames(2)
	assert_eq(client.own_peer(), ENetTransport.NO_PEER)


func test_message_sent_before_close_arrives() -> void:
	var client := await _connect()
	var peer_id := client.own_peer()
	watch_signals(_host)

	client.send(MatchTransport.HOST_PEER, {KEY_TEXT: "çıkıyorum"})
	client.close()
	await wait_for_signal(_host.peer_disconnected, TIMEOUT)

	assert_eq(_host_inbox, [{KEY_TEXT: "çıkıyorum"}])
	assert_signal_emitted_with_parameters(_host, "peer_disconnected", [peer_id])


func test_messages_from_kicked_peer_are_dropped() -> void:
	var client := await _connect()

	_host.kick(client.own_peer())
	client.send(MatchTransport.HOST_PEER, {KEY_TEXT: "hâlâ burada"})
	await wait_seconds(SETTLE)

	assert_eq(_host_inbox, [])


func test_new_peers_are_refused_after_lock() -> void:
	_host.refuse_new_peers()
	var late := ENetTransport.new(_settings)
	_clients.append(late)

	late.join(LocalAddress.LOOPBACK)
	late.send(MatchTransport.HOST_PEER, {KEY_TEXT: "geç kaldım"})
	await wait_seconds(SETTLE)

	assert_eq(_host_peers, [])
	assert_eq(_host_inbox, [])


## İstemciyi hosta bağlar; iki uç da bağlantıyı görene kadar bekler.
func _connect() -> ENetTransport:
	var client := ENetTransport.new(_settings)
	_clients.append(client)
	watch_signals(client)
	assert_true(client.join(LocalAddress.LOOPBACK))
	await wait_for_signal(client.peer_connected, TIMEOUT)
	assert_signal_emitted_with_parameters(client, "peer_connected", [MatchTransport.HOST_PEER])
	await wait_until(func() -> bool: return _host_peers.has(client.own_peer()), TIMEOUT)
	return client
