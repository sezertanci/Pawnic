extends GutTest
## Sahte taşıyıcı: mesaj eşe bir kare sonra ve kopya olarak ulaşır; bağlı olmayan eşe gitmez.

const CLIENT_PEER := 2
const MISSING_PEER := 9
const FRAMES := 2

var _network: Dictionary
var _host: FakeTransport
var _client: FakeTransport
var _received: Array = []


func before_each() -> void:
	_network = {}
	_received.clear()
	_host = FakeTransport.new(MatchTransport.HOST_PEER, _network)
	_client = FakeTransport.new(CLIENT_PEER, _network)
	_host.message_received.connect(_on_message)
	_client.message_received.connect(_on_message)


func test_message_reaches_peer_on_next_frame() -> void:
	var message := MatchMessage.snapshot_request()

	_client.send(MatchTransport.HOST_PEER, message)
	assert_eq(_received.size(), 0)
	await wait_frames(FRAMES)

	assert_eq(_received, [[CLIENT_PEER, message]])


func test_message_is_delivered_as_copy() -> void:
	var message := MatchMessage.intent(MatchIntent.discard(0, 0))

	_client.send(MatchTransport.HOST_PEER, message)
	MatchMessage.data_of(message)[MessageData.KEY_SEAT] = MISSING_PEER
	await wait_frames(FRAMES)

	assert_eq(MatchMessage.data_of(_received[0][1])[MessageData.KEY_SEAT], 0)


func test_message_to_missing_peer_is_dropped() -> void:
	_client.disconnect_peer()

	_host.send(CLIENT_PEER, MatchMessage.snapshot_request())
	_host.send(MISSING_PEER, MatchMessage.snapshot_request())
	await wait_frames(FRAMES)

	assert_eq(_received.size(), 0)
	assert_false(_network.has(CLIENT_PEER))


func _on_message(peer_id: int, message: Dictionary) -> void:
	_received.append([peer_id, message])
