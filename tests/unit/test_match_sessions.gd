extends GutTest
## Host ve istemci oturumu sahte taşıyıcı üzerinden: el sıkışma, koltuğa oturtma, niyetin
## eşin koltuğu adına verilmesi, uyuşmayan olayda görünümün yeniden istenmesi, hostun istemcinin
## olayı bitirmesini beklemesi ve tam bir oyun.

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_match_sessions_save.json"
const SEED := 11
const PAWNS := 4
const TWO_HUMANS: Array[bool] = [false, false]
const CLIENT_PEER := 2
const STRANGER_PEER := 3
## Mesajın ulaşması için beklenen kare sayısı (gidiş ve dönüş).
const FRAMES := 4
## Tam oyunun bitmesi için beklenen en fazla kare; aşılırsa test başarısız olur.
const MAX_FRAMES := 20000
const MISSING_PAWN := 99

var _store: SaveStoreScript
var _referee: MatchReferee
var _game: GameMatch
var _network: Dictionary
var _host: HostSession
var _client: ClientSession
var _stranger: FakeTransport
var _host_seat := BoardLayout.NO_SEAT
var _client_seat := BoardLayout.NO_SEAT
var _refusals: Array[int] = []
var _rejected: Array[MatchIntent] = []
var _resets := 0
var _mismatches: Array[String] = []
var _over := false
var _intent_sent := false
## true iken istemcinin ekranı her olayı hemen bitirir.
var _client_finishes := true
## İstemcinin son aldığı olay.
var _last_event: MatchEvent


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()
	_refusals.clear()
	_rejected.clear()
	_mismatches.clear()
	_resets = 0
	_over = false
	_intent_sent = false
	_client_finishes = true
	_referee = MatchReferee.new()
	_referee.store = _store
	_referee.event_emitted.connect(_on_host_event)
	add_child_autofree(_referee)
	_game = _new_game()
	_host_seat = _game.current_seat()
	_client_seat = _game.seats[(_game.current + 1) % _game.seats.size()]
	_network = {}
	_host = HostSession.new(
		_referee, FakeTransport.new(MatchTransport.HOST_PEER, _network), _game.settings
	)
	_client = ClientSession.new(FakeTransport.new(CLIENT_PEER, _network), _game.settings)
	_client.refused.connect(func(reason: int) -> void: _refusals.append(reason))
	_client.intent_rejected.connect(func(intent: MatchIntent) -> void: _rejected.append(intent))
	_client.view_reset.connect(func(_view: MatchView) -> void: _resets += 1)
	_client.event_received.connect(_on_client_event)
	_stranger = FakeTransport.new(STRANGER_PEER, _network)


func after_each() -> void:
	_referee.stop()
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func test_hello_with_same_version_is_welcomed() -> void:
	watch_signals(_client)

	_client.join()
	await wait_frames(FRAMES)

	assert_signal_emitted(_client, "welcomed")
	assert_true(_host.seat_peer(CLIENT_PEER, _client_seat))


func test_hello_with_other_protocol_is_refused() -> void:
	var data := MatchMessage.data_of(MatchMessage.hello(_game.settings))
	data[MatchMessage.KEY_PROTOCOL] = MatchMessage.PROTOCOL_VERSION + 1

	await _say_hello(data)

	assert_eq(_refusals, [MatchMessage.Refusal.VERSION_MISMATCH])
	assert_false(_host.seat_peer(CLIENT_PEER, _client_seat))


func test_hello_with_other_digest_is_refused() -> void:
	var data := MatchMessage.data_of(MatchMessage.hello(_game.settings))
	data[MatchMessage.KEY_DIGEST] = ""

	await _say_hello(data)

	assert_eq(_refusals, [MatchMessage.Refusal.VERSION_MISMATCH])
	assert_false(_host.seat_peer(CLIENT_PEER, _client_seat))


func test_seat_cannot_be_given_twice() -> void:
	await _join()
	_stranger.send(MatchTransport.HOST_PEER, MatchMessage.hello(_game.settings))
	await wait_frames(FRAMES)

	assert_false(_host.seat_peer(STRANGER_PEER, _client_seat))
	assert_false(_host.seat_peer(CLIENT_PEER, _host_seat))
	assert_eq(_host.seat_of(CLIENT_PEER), _client_seat)


func test_closed_session_leaves_frame_loop() -> void:
	var frames: Signal = Engine.get_main_loop().process_frame

	_host.close()

	assert_false(frames.is_connected(_host._on_frame))


func test_shared_match_holds_client_view() -> void:
	await _join()
	_referee.start(_game)

	_host.share_match()
	await wait_frames(FRAMES)

	assert_eq(_resets, 1)
	assert_eq(_client.view.to_dict(), _host_view())


func test_intent_is_played_for_peer_seat() -> void:
	await _start_match()
	var hand_size := _game.current_hand().size()
	var move := _game.legal_moves()[0] if not _game.legal_moves().is_empty() else null
	var intent := (
		MatchIntent.discard(_host_seat, 0) if move == null else MatchIntent.play(_host_seat, move)
	)

	_client.send_intent(intent)
	await wait_frames(FRAMES)

	assert_eq(_rejected.size(), 1)
	assert_eq(_rejected[0].seat, _client_seat)
	assert_true(_referee.is_awaiting_intent())
	assert_eq(_game.current_hand().size(), hand_size)


func test_messages_from_other_peers_are_ignored() -> void:
	watch_signals(_client)

	_stranger.send(CLIENT_PEER, MatchMessage.welcome(""))
	var view := MatchView.of(_game, _client_seat)
	_stranger.send(CLIENT_PEER, MatchMessage.snapshot(view, GameSpeed.Level.NORMAL))
	await wait_frames(FRAMES)

	assert_signal_not_emitted(_client, "welcomed")
	assert_null(_client.view)


func test_mismatched_event_requests_view_again() -> void:
	await _start_match()
	var event := MatchEvent.new(MatchEvent.Kind.MOVE_PLAYED, _host_seat)
	event.card_index = 0
	event.card = _game.current_hand()[0]
	event.move = Move.new(0, Move.Action.FORWARD, MISSING_PAWN, 1)
	var host_transport: FakeTransport = _network[MatchTransport.HOST_PEER].get_ref()

	host_transport.send(CLIENT_PEER, MatchMessage.event(event, _client_seat, 1))
	await wait_frames(FRAMES * 2)

	assert_eq(_resets, 2)
	assert_eq(_client.view.to_dict(), _host_view())


func test_host_waits_until_client_finishes_event() -> void:
	_client_finishes = false
	await _start_match()
	assert_false(_referee.is_awaiting_intent())

	_client.finish_event(_last_event)
	await wait_frames(FRAMES)

	assert_true(_referee.is_awaiting_intent())


func test_finishing_old_event_does_not_end_wait() -> void:
	_client_finishes = false
	await _start_match()
	var client_transport: FakeTransport = _network[CLIENT_PEER].get_ref()

	var stale := MatchMessage.event_done(_last_event.serial - 1)
	client_transport.send(MatchTransport.HOST_PEER, stale)
	await wait_frames(FRAMES)

	assert_false(_referee.is_awaiting_intent())


func test_view_request_ends_wait_for_client() -> void:
	_client_finishes = false
	await _start_match()
	var client_transport: FakeTransport = _network[CLIENT_PEER].get_ref()

	client_transport.send(MatchTransport.HOST_PEER, MatchMessage.snapshot_request())
	await wait_frames(FRAMES)

	assert_true(_referee.is_awaiting_intent())


func test_turn_timer_reaches_client() -> void:
	var limit := _game.settings.turn_time_limit
	_referee.turn_time_limit = limit
	watch_signals(_client)

	await _start_match()

	assert_signal_emitted_with_parameters(_client, "turn_timer_started", [_host_seat, limit])


func test_view_request_carries_turn_time_left() -> void:
	var limit := _game.settings.turn_time_limit
	_referee.turn_time_limit = limit
	await _start_match()
	var client_transport: FakeTransport = _network[CLIENT_PEER].get_ref()

	client_transport.send(MatchTransport.HOST_PEER, MatchMessage.snapshot_request())
	await wait_frames(FRAMES)

	assert_gt(_client.host_turn_time, 0.0)
	assert_lte(_client.host_turn_time, limit)


func test_turn_timer_longer_than_limit_is_ignored() -> void:
	await _start_match()
	watch_signals(_client)
	var host_transport: FakeTransport = _network[MatchTransport.HOST_PEER].get_ref()
	var seconds := _game.settings.turn_time_limit + 1.0

	host_transport.send(CLIENT_PEER, MatchMessage.turn_timer(_host_seat, seconds))
	await wait_frames(FRAMES)

	assert_signal_not_emitted(_client, "turn_timer_started")


func test_client_view_follows_whole_match() -> void:
	await _join()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var bot := Bot.new(_game.settings.bot_profiles[Bot.Level.EASY], _game.settings, rng)
	_referee.start(_game)
	_host.share_match()
	_referee.begin()

	for _frame: int in range(MAX_FRAMES):
		if _over:
			break
		_take_turn(bot)
		await wait_frames(1)
	await wait_frames(FRAMES)

	assert_true(_over)
	assert_eq(_resets, 1)
	assert_eq(_mismatches, [])
	assert_eq(_client.view.to_dict(), _host_view())


## Hostun oyuncusu niyetini doğrudan hakeme verir; istemcinin oyuncusu mesajla gönderir.
func _take_turn(bot: Bot) -> void:
	if not _referee.is_awaiting_intent():
		return
	if _game.current_seat() == _host_seat:
		_referee.submit(_choose(bot))
	elif not _intent_sent:
		_intent_sent = true
		_client.send_intent(_choose(bot))


func _choose(bot: Bot) -> MatchIntent:
	var move := bot.choose_move(_game)
	if move != null:
		return MatchIntent.play(_game.current_seat(), move)
	return MatchIntent.discard(_game.current_seat(), bot.choose_discard(_game.current_hand()))


## Hostun ekranı her olayı hemen bitirir.
func _on_host_event(event: MatchEvent) -> void:
	_over = _over or event.kind == MatchEvent.Kind.MATCH_OVER
	if event.kind == MatchEvent.Kind.TURN_STARTED:
		_intent_sent = false
	_referee.acknowledge()


## İstemcinin ekranı olayı (istenirse) hemen bitirir. İstemcinin sırası başladığında host onun
## niyetini beklediği için oyun durur; kopya o an hosttaki oyunla karşılaştırılır.
func _on_client_event(event: MatchEvent) -> void:
	_last_event = event
	if _client_finishes:
		_client.finish_event(event)
	if event.kind != MatchEvent.Kind.TURN_STARTED or event.seat != _client_seat:
		return
	if _client.view.to_dict() != _host_view():
		_mismatches.append("kopya ayrıştı: tur %d" % _game.round_number)


## Hosttaki oyunun istemciye görünen hâli. Hostun saati mesajlar beklenirken işlemeye devam eder;
## istemci saati yalnızca sıra başında eşitlediği için geçen süre karşılaştırılmaz.
func _host_view() -> Dictionary:
	var expected := MatchView.of(_game, _client_seat).to_dict()
	expected[GameMatch.KEY_ELAPSED] = _client.view.elapsed
	return expected


func _say_hello(data: Dictionary) -> void:
	var client_transport: FakeTransport = _network[CLIENT_PEER].get_ref()
	client_transport.send(
		MatchTransport.HOST_PEER, MatchMessage.make(MatchMessage.Type.HELLO, data)
	)
	await wait_frames(FRAMES)


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


func _new_game() -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, TWO_HUMANS.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game
