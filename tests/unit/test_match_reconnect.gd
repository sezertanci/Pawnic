extends GutTest
## Ağ oyununda kopma ve geri dönme, sahte taşıyıcı ve sahte saatle: kopan eş beklenmeden oyun
## sürer, sıra onun koltuğuna gelince beklenir, süre dolunca koltuk bota geçer, eş yeniden katılma
## anahtarıyla koltuğuna döner, sesi kesilip dönen eş kalan sıra süresini öğrenir, el sıkışmayan
## bağlantı kesilir; istemci kopan koltukları, hostun sesinin kesilmesini ve odanın kapandığını
## öğrenir.

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_match_reconnect_save.json"
const SEED := 11
const PAWNS := 4
const TWO_HUMANS: Array[bool] = [false, false]
const CLIENT_PEER := 2
const REJOIN_PEER := 4
const STRANGER_PEER := 5
## Mesajın ulaşması için beklenen kare sayısı (gidiş ve dönüş).
const FRAMES := 4
## Sahte saatin bir karede ilerlediği süre (ms); sessizlik sınırından kısa olmalı.
const CLOCK_STEP := 1000

var _store: SaveStoreScript
var _referee: MatchReferee
var _game: GameMatch
var _network: Dictionary
var _host: HostSession
var _client: ClientSession
var _host_seat := BoardLayout.NO_SEAT
var _client_seat := BoardLayout.NO_SEAT
## true iken istemcinin ekranı her olayı hemen bitirir.
var _client_finishes := true
## Sahte saatin şimdiki anı (ms).
var _now := 0


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()
	_client_finishes = true
	_now = 0
	_referee = MatchReferee.new()
	_referee.store = _store
	_referee.event_emitted.connect(func(_event: MatchEvent) -> void: _referee.acknowledge())
	add_child_autofree(_referee)
	_game = _new_game()
	_host_seat = _game.current_seat()
	_client_seat = _game.seats[(_game.current + 1) % _game.seats.size()]
	_network = {}
	_host = HostSession.new(
		_referee, FakeTransport.new(MatchTransport.HOST_PEER, _network), _game.settings
	)
	_host.clock = _fake_clock
	_client = ClientSession.new(FakeTransport.new(CLIENT_PEER, _network), _game.settings)
	_client.clock = _fake_clock
	_client.event_received.connect(_on_client_event)


func after_each() -> void:
	_referee.stop()
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func test_game_goes_on_without_disconnected_client() -> void:
	_client_finishes = false
	await _start_match()
	assert_false(_referee.is_awaiting_intent())

	_client_transport().disconnect_peer()
	await wait_frames(FRAMES)

	assert_true(_referee.is_awaiting_intent())
	assert_eq(_host.seat_wait(_client_seat), _game.settings.rejoin_wait_time)


func test_turn_of_away_seat_waits_for_player() -> void:
	await _start_match()
	_client_transport().disconnect_peer()
	await wait_frames(FRAMES)
	var seat_index := _game.seats.find(_client_seat)

	_referee.submit(_host_intent())
	await wait_frames(FRAMES)

	assert_eq(_game.current, seat_index)
	assert_true(_referee.is_awaiting_intent())
	assert_false(_game.bots[seat_index])


func test_bot_takes_seat_when_wait_runs_out() -> void:
	_client_finishes = false
	await _start_match()
	_client_transport().disconnect_peer()
	await wait_frames(FRAMES)

	await _advance_clock(int(_game.settings.rejoin_wait_time * ClientSource.MSEC_PER_SECOND))

	assert_eq(_host.seat_wait(_client_seat), 0.0)
	assert_true(_game.bots[_game.seats.find(_client_seat)])
	assert_true(_referee.is_awaiting_intent())


func test_benched_seat_stays_with_bot_in_rematch() -> void:
	_client_finishes = false
	await _start_match()
	_client_transport().disconnect_peer()
	await wait_frames(FRAMES)
	await _advance_clock(int(_game.settings.rejoin_wait_time * ClientSource.MSEC_PER_SECOND))
	var rematch := _new_game()

	_referee.start(rematch)
	_host.share_match()

	assert_true(rematch.bots[rematch.seats.find(_client_seat)])
	assert_eq(_host.seat_wait(_client_seat), 0.0)


func test_silent_client_is_marked_away() -> void:
	await _start_match()
	_network.erase(CLIENT_PEER)

	await _advance_clock(_game.settings.silence_limit_ms + CLOCK_STEP)

	assert_true(_host.seat_wait(_client_seat) > 0.0)


func test_returning_client_learns_turn_time_left() -> void:
	_referee.turn_time_limit = _game.settings.turn_time_limit
	await _start_match()
	var transport := _client_transport()
	_network.erase(CLIENT_PEER)
	await _advance_clock(_game.settings.silence_limit_ms + CLOCK_STEP)
	watch_signals(_client)

	_network[CLIENT_PEER] = weakref(transport)
	await _advance_clock(_game.settings.silence_limit_ms)

	assert_eq(_host.seat_wait(_client_seat), SeatPresence.PRESENT)
	assert_signal_emitted(_client, "turn_timer_started")


func test_client_rejoins_seat_with_token() -> void:
	_client_finishes = false
	await _start_match()
	_client_transport().disconnect_peer()
	await wait_frames(FRAMES)
	await _advance_clock(int(_game.settings.rejoin_wait_time * ClientSource.MSEC_PER_SECOND))
	var back := _rejoining_client(_client.token)
	watch_signals(back)

	back.join()
	await wait_frames(FRAMES)

	assert_signal_emitted(back, "view_reset")
	assert_eq(_host.seat_of(REJOIN_PEER), _client_seat)
	assert_eq(_host.seat_wait(_client_seat), SeatPresence.PRESENT)
	assert_false(_game.bots[_game.seats.find(_client_seat)])


func test_unknown_token_is_refused() -> void:
	await _start_match()
	var stranger := _rejoining_client("bilinmeyen")
	var refusals: Array[int] = []
	stranger.refused.connect(func(reason: int) -> void: refusals.append(reason))

	stranger.join()
	await wait_frames(FRAMES)

	assert_eq(refusals, [MatchMessage.Refusal.NOT_IN_MATCH])
	assert_eq(_host.seat_of(REJOIN_PEER), BoardLayout.NO_SEAT)


func test_welcomed_client_keeps_token() -> void:
	await _join()

	assert_ne(_client.token, "")


func test_connection_without_hello_is_kicked() -> void:
	var stranger := FakeTransport.new(STRANGER_PEER, _network)
	_host_transport().peer_connected.emit(STRANGER_PEER)

	await _advance_clock(_game.settings.silence_limit_ms + CLOCK_STEP)

	assert_false(_network.has(stranger.own_peer()))


func test_connection_with_hello_is_kept() -> void:
	_host_transport().peer_connected.emit(CLIENT_PEER)
	await _join()

	await _advance_clock(_game.settings.silence_limit_ms + CLOCK_STEP)

	assert_true(_network.has(CLIENT_PEER))


func test_closing_host_tells_client() -> void:
	await _start_match()
	watch_signals(_client)

	_host.close()
	await wait_frames(FRAMES)

	assert_signal_emitted(_client, "closed_by_host")


func test_client_learns_away_seat() -> void:
	await _start_match()
	_host_transport().send(CLIENT_PEER, MatchMessage.seat_status(_host_seat, 5.0))
	await wait_frames(FRAMES)

	assert_almost_eq(_client.seat_wait(_host_seat), 5.0, 0.001)


func test_client_notices_silent_host() -> void:
	await _start_match()
	watch_signals(_client)
	_network.erase(MatchTransport.HOST_PEER)

	await _advance_clock(_game.settings.silence_limit_ms + CLOCK_STEP)

	assert_true(_client.is_host_silent())
	assert_signal_emitted_with_parameters(_client, "host_silent_changed", [true])


## Hostun sırasında oynanabilecek ilk hamle; hamle yoksa ilk kart atılır.
func _host_intent() -> MatchIntent:
	var legal := _game.legal_moves()
	if legal.is_empty():
		return MatchIntent.discard(_host_seat, 0)
	return MatchIntent.play(_host_seat, legal[0])


func _on_client_event(event: MatchEvent) -> void:
	if _client_finishes:
		_client.finish_event(event)


func _join() -> void:
	_client.join()
	await wait_frames(FRAMES)
	_host.seat_peer(CLIENT_PEER, _client_seat)


func _start_match() -> void:
	await _join()
	_referee.start(_game)
	_host.share_match()
	_referee.begin()
	await wait_frames(FRAMES)


func _fake_clock() -> int:
	return _now


## Sahte saati her karede CLOCK_STEP ilerleterek verilen süre kadar ileri alır.
func _advance_clock(milliseconds: int) -> void:
	var target := _now + milliseconds
	while _now < target:
		_now = mini(_now + CLOCK_STEP, target)
		await wait_frames(1)
	await wait_frames(FRAMES)


func _host_transport() -> FakeTransport:
	return _network[MatchTransport.HOST_PEER].get_ref()


func _client_transport() -> FakeTransport:
	return _network[CLIENT_PEER].get_ref()


func _rejoining_client(token: String) -> ClientSession:
	var client := ClientSession.new(FakeTransport.new(REJOIN_PEER, _network), _game.settings)
	client.clock = _fake_clock
	client.token = token
	return client


func _new_game() -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, TWO_HUMANS.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game
