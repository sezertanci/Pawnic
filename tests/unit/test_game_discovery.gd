extends GutTest
## Oyun bulma aynı cihazda: hostun yayını bulunur, oyuncu sayısı güncellenir, yayını kesilen oyun
## listeden düşer; bozuk, yabancı ya da başka sürümdeki yayın atılır. Aynı portta ikinci bulucu
## dinleyemez.

## Yayının bulunması için beklenen en fazla süre (saniye).
const TIMEOUT := 3.0
## Atılması gereken yayının gerçekten atıldığını görmek için beklenen süre (saniye).
const SETTLE := 0.5
## Testte listeden düşme süresi kısaltılır (milisaniye).
const SHORT_EXPIRY_MS := 300
const PUBLIC_ADDRESS := "8.8.8.8"
const PLAYERS := 3

var _settings: GameSettings
var _announcer: GameAnnouncer
var _finder: GameFinder


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_announcer = GameAnnouncer.new(_settings)
	_finder = GameFinder.new(_settings)
	assert_true(_finder.start())


func after_each() -> void:
	_announcer.stop()
	_finder.stop()


func test_announced_game_is_found() -> void:
	assert_true(_announcer.start(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK))

	await wait_until(func() -> bool: return not _finder.games().is_empty(), TIMEOUT)

	assert_eq(_finder.games().size(), 1)
	var game := _finder.games()[0]
	assert_eq(game.address, LocalAddress.LOOPBACK)
	assert_eq(game.port, _settings.network_port)
	assert_eq(game.players, 1)


func test_player_count_change_updates_list() -> void:
	_announcer.start(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK)
	await wait_until(func() -> bool: return not _finder.games().is_empty(), TIMEOUT)

	_announcer.player_count = PLAYERS
	await wait_until(func() -> bool: return _finder.games()[0].players == PLAYERS, TIMEOUT)

	assert_eq(_finder.games()[0].players, PLAYERS)


func test_silent_game_drops_from_list() -> void:
	_settings.announce_expiry_ms = SHORT_EXPIRY_MS
	_announcer.start(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK)
	await wait_until(func() -> bool: return not _finder.games().is_empty(), TIMEOUT)
	watch_signals(_finder)

	_announcer.stop()
	await wait_until(func() -> bool: return _finder.games().is_empty(), TIMEOUT)

	assert_true(_finder.games().is_empty())
	assert_signal_emitted(_finder, "games_changed")


func test_bad_announcements_are_ignored() -> void:
	var other_protocol := MatchMessage.announce(_settings.network_port, 1)
	other_protocol[MatchMessage.KEY_DATA][MatchMessage.KEY_PROTOCOL] = (
		MatchMessage.PROTOCOL_VERSION + 1
	)
	var packets: Array[PackedByteArray] = [
		var_to_bytes(other_protocol),
		var_to_bytes(MatchMessage.announce(0, 1)),
		var_to_bytes(MatchMessage.announce(_settings.network_port, _settings.max_players + 1)),
		var_to_bytes(MatchMessage.announce(_settings.network_port, 0)),
		var_to_bytes(MatchMessage.welcome()),
		var_to_bytes([1, 2, 3]),
		var_to_bytes({"x": "y".repeat(_settings.max_message_bytes)}),
	]

	_send_raw(packets)
	await wait_seconds(SETTLE)

	assert_true(_finder.games().is_empty())


func test_announcer_refuses_public_address() -> void:
	assert_false(_announcer.start(PUBLIC_ADDRESS))


func test_second_finder_on_same_port_fails() -> void:
	# Arrange
	var second := GameFinder.new(_settings)

	# Act
	var started := second.start()

	# Assert
	assert_false(started)
	assert_false(second.is_listening())
	assert_true(_finder.is_listening())


func _send_raw(packets: Array[PackedByteArray]) -> void:
	var socket := PacketPeerUDP.new()
	socket.set_dest_address(LocalAddress.LOOPBACK, _settings.discovery_port)
	for packet: PackedByteArray in packets:
		socket.put_packet(packet)
	socket.close()
