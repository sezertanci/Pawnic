extends GutTest
## Ağ odaları aynı cihazda (127.0.0.1) gerçek ENet ile: doğru kodla katılma ve lobinin gelmesi,
## yanlış kodun reddi, hostun kapanması, ulaşılamayan host ve yayındaki oyuncu sayısı.

## Bağlantı ve mesaj için beklenen en fazla süre (saniye).
const TIMEOUT := 3.0
## Ulaşılamayan hostta bağlantının düşmesi için beklenen en fazla süre (saniye); bağlanma zaman
## aşımı kısaltılır.
const UNREACHABLE_TIMEOUT := 3.0
const SHORT_CONNECT_TIMEOUT_MS := 1000
const WRONG_CODE := "x"

var _settings: GameSettings
var _referee: MatchReferee
var _host: HostRoom
var _guests: Array[GuestRoom] = []
var _finder: GameFinder


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_referee = MatchReferee.new()
	add_child_autofree(_referee)
	_host = HostRoom.new(_settings, _referee, RandomNumberGenerator.new())
	_guests.clear()
	_finder = GameFinder.new(_settings)


func after_each() -> void:
	for guest: GuestRoom in _guests:
		guest.close()
	_host.close()
	_finder.stop()


func test_guest_with_code_receives_lobby() -> void:
	assert_true(_host.open(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK))

	var guest := _new_guest()
	assert_true(guest.join(LocalAddress.LOOPBACK, _host.lobby.code))
	await wait_until(func() -> bool: return guest.session.lobby != null, TIMEOUT)

	assert_eq(guest.session.lobby.colors.size(), 2)
	assert_eq(guest.session.lobby.own, 1)
	assert_eq(_host.lobby.min_seat_count(), maxi(_settings.min_players, 2))


func test_wrong_code_is_refused() -> void:
	_host.open(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK)
	var guest := _new_guest()
	watch_signals(guest)

	guest.join(LocalAddress.LOOPBACK, WRONG_CODE)
	await wait_for_signal(guest.refused, TIMEOUT)

	assert_signal_emitted_with_parameters(guest, "refused", [MatchMessage.Refusal.WRONG_CODE])
	assert_signal_not_emitted(guest, "lost")


func test_closing_host_loses_welcomed_guest() -> void:
	_host.open(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK)
	var guest := _new_guest()
	watch_signals(guest)
	guest.join(LocalAddress.LOOPBACK, _host.lobby.code)
	await wait_until(func() -> bool: return guest.session.lobby != null, TIMEOUT)

	_host.close()
	await wait_for_signal(guest.lost, TIMEOUT)

	assert_signal_emitted_with_parameters(guest, "lost", [true])


func test_unreachable_host_is_lost_unwelcomed() -> void:
	_settings.connect_timeout_ms = SHORT_CONNECT_TIMEOUT_MS
	var guest := _new_guest()
	watch_signals(guest)

	guest.join(LocalAddress.LOOPBACK, WRONG_CODE)
	await wait_for_signal(guest.lost, UNREACHABLE_TIMEOUT)

	assert_signal_emitted_with_parameters(guest, "lost", [false])


func test_announced_player_count_follows_lobby() -> void:
	assert_true(_finder.start())
	_host.open(LocalAddress.LOOPBACK, LocalAddress.LOOPBACK)
	var guest := _new_guest()
	guest.join(LocalAddress.LOOPBACK, _host.lobby.code)

	await wait_until(
		func() -> bool: return _finder.games().size() == 1 and _finder.games()[0].players == 2,
		TIMEOUT
	)

	assert_eq(_finder.games()[0].players, 2)


func _new_guest() -> GuestRoom:
	var guest := GuestRoom.new(_settings)
	_guests.append(guest)
	return guest
