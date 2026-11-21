extends GutTest
## Oyun kaynakları: hakemden beslenen kaynağın bayatlaması ve hostun görünümü; istemci kaynağının
## olayları ekran bitirene kadar tutması, kendi niyetinin reddini bildirmesi, bağlantı kopunca
## bitmesi ve oyuncu çıkınca koltuğun bota geçmesi; molada saatin ve sıra süresinin durması;
## kaynakların oda kodu; ekranın kopyasına uymayan olayda görünümün yeniden istenmesi. Ağ sahte
## taşıyıcıyla
## kurulur.

const SEED := 11
const PAWNS := 4
const TWO_HUMANS: Array[bool] = [false, false]
const CLIENT_PEER := 2
## Mesajın ulaşması için beklenen kare sayısı (gidiş ve dönüş).
const FRAMES := 4
## Tahtada olmayan taş; bu taşla hamle hiçbir zaman yasal değildir.
const MISSING_PAWN := 99
## Oyunda olmayan koltuk; ekranın kopyasını kaydırmak için kullanılır.
const MISSING_SEAT := 99
## İstemcinin sırasına kadar gelebilecek en fazla olay; aşılırsa döngü durur.
const MAX_EVENTS := 20
const ROOM_CODE := "4568"
## Yerel ağ dışındaki adres: katılma bağlantı kurmadan reddedilir, verilen kod yine de saklanır.
const OUTSIDE_ADDRESS := "8.8.8.8"
## İstemcide test içinde dolan sıra süresi (saniye).
const SHORT_TURN_TIME := 0.1

var _referee: MatchReferee
var _game: GameMatch
var _network: Dictionary
var _host: HostSession
var _room: GuestRoom
var _source: ClientSource
var _host_seat := BoardLayout.NO_SEAT
var _client_seat := BoardLayout.NO_SEAT
var _shown: Array[MatchEvent] = []


func before_each() -> void:
	_shown.clear()
	_referee = MatchReferee.new()
	_referee.in_game_ads = false
	_referee.event_emitted.connect(func(_event: MatchEvent) -> void: _referee.acknowledge())
	add_child_autofree(_referee)
	_game = _new_game()
	_host_seat = _game.current_seat()
	_client_seat = _game.seats[(_game.current + 1) % _game.seats.size()]
	_network = {}
	_host = HostSession.new(
		_referee, FakeTransport.new(MatchTransport.HOST_PEER, _network), _game.settings
	)
	_room = GuestRoom.new(_game.settings)
	_room.session = ClientSession.new(FakeTransport.new(CLIENT_PEER, _network), _game.settings)
	_source = ClientSource.new(_room)
	_source.event_emitted.connect(func(event: MatchEvent) -> void: _shown.append(event))


func after_each() -> void:
	_referee.stop()


func test_referee_source_goes_stale_when_referee_stops() -> void:
	_referee.start(_game)
	var source := RefereeSource.new(_referee)

	_referee.stop()

	assert_false(source.is_live())
	assert_false(source.is_awaiting_intent())


func test_host_source_views_own_seat() -> void:
	_referee.start(_game)

	var source := RefereeSource.new(_referee, _client_seat)

	assert_true(source.is_host())
	assert_eq(source.view().viewer_seat, _client_seat)


func test_sources_report_room_code() -> void:
	_referee.start(_game)
	var host_source := RefereeSource.new(_referee, _host_seat, ROOM_CODE)
	var local_source := RefereeSource.new(_referee)

	_room.join(OUTSIDE_ADDRESS, ROOM_CODE)

	assert_eq(host_source.room_code(), ROOM_CODE)
	assert_eq(_source.room_code(), ROOM_CODE)
	assert_eq(local_source.room_code(), "")


func test_referee_source_reports_rejected_intent() -> void:
	_referee.start(_game)
	var source := RefereeSource.new(_referee, _host_seat)
	_referee.begin()
	watch_signals(source)

	source.submit(_missing_move(_client_seat))

	assert_signal_emitted(source, "intent_rejected")
	assert_true(source.is_awaiting_intent())


func test_client_source_waits_for_view_before_events() -> void:
	await _start_match()

	assert_eq(_shown.size(), 0)
	assert_not_null(_source.view())
	assert_eq(_source.view().viewer_seat, _client_seat)


func test_client_source_requests_view_when_event_does_not_fit() -> void:
	await _start_match()
	var drifted: Array[int] = [MISSING_SEAT, MISSING_SEAT]
	_source.view().seats = drifted
	watch_signals(_source)

	_source.begin()
	await wait_frames(FRAMES)

	assert_eq(_shown.size(), 0)
	assert_signal_emitted(_source, "view_reset")
	assert_eq(_source.view().seats, _game.seats)


func test_client_source_holds_events_until_acknowledged() -> void:
	await _start_match()
	await _play_host_turn()
	assert_eq(_shown.size(), 2)

	await _acknowledge_until_client_turn()

	assert_eq(_shown.back().kind, MatchEvent.Kind.TURN_STARTED)
	assert_eq(_shown.back().seat, _client_seat)
	assert_true(_source.is_awaiting_intent())


func test_client_source_reports_rejection_of_its_intent() -> void:
	await _reach_client_turn()
	watch_signals(_source)

	_source.submit(_missing_move(_client_seat))
	assert_false(_source.is_awaiting_intent())
	await wait_frames(FRAMES)

	assert_signal_emitted(_source, "intent_rejected")
	assert_true(_source.is_awaiting_intent())


func test_client_source_counts_turn_time_from_host() -> void:
	var limit := _game.settings.turn_time_limit
	_referee.turn_time_limit = limit
	await _reach_client_turn()

	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)

	assert_gt(_source.turn_time_left(), 0.0)
	assert_lte(_source.turn_time_left(), limit)


func test_client_source_stops_awaiting_when_turn_time_ends() -> void:
	await _reach_client_turn()
	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)

	_room.session.turn_timer_started.emit(_client_seat, SHORT_TURN_TIME)
	assert_true(_source.is_awaiting_intent())
	await wait_seconds(SHORT_TURN_TIME * 2)

	assert_false(_source.is_awaiting_intent())
	assert_eq(_source.turn_time_left(), MatchReferee.NO_TURN_TIMER)


func test_client_source_freezes_turn_time_while_connection_lost() -> void:
	await _reach_client_turn()
	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)
	_room.session.turn_timer_started.emit(_client_seat, SHORT_TURN_TIME)

	_room.connection_changed.emit(true)
	await wait_seconds(SHORT_TURN_TIME * 2)

	assert_true(_source.is_awaiting_intent())
	assert_gt(_source.turn_time_left(), 0.0)
	_room.connection_changed.emit(false)
	await wait_seconds(SHORT_TURN_TIME * 2)
	assert_false(_source.is_awaiting_intent())


func test_client_source_freezes_turn_time_and_clock_while_paused() -> void:
	await _reach_client_turn()
	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)
	_room.session.turn_timer_started.emit(_client_seat, SHORT_TURN_TIME)
	watch_signals(_source)

	_referee.pause()
	await wait_frames(FRAMES)
	var elapsed := _source.elapsed()
	await wait_seconds(SHORT_TURN_TIME * 2)

	assert_true(_source.is_paused())
	assert_signal_emitted_with_parameters(_source, "pause_changed", [true])
	assert_true(_source.is_awaiting_intent())
	assert_eq(_source.elapsed(), elapsed)
	_referee.resume()
	await wait_seconds(SHORT_TURN_TIME * 2)
	assert_false(_source.is_awaiting_intent())


func test_only_host_source_pauses() -> void:
	await _start_match()
	var host_source := RefereeSource.new(_referee, _host_seat, ROOM_CODE, _host)
	var local_source := RefereeSource.new(_referee)

	local_source.pause()
	assert_false(_referee.is_paused())
	host_source.pause()

	assert_true(host_source.is_paused())


func test_client_source_skips_end_ad_soon_after_shared_ad() -> void:
	_referee.in_game_ads = true
	_game.elapsed = _game.settings.interstitial_interval
	await _start_match()
	assert_false(_source.skips_end_ad())

	_source.begin()

	assert_eq(_shown.back().kind, MatchEvent.Kind.AD_DUE)
	assert_true(_source.skips_end_ad())


func test_lost_room_ends_client_source() -> void:
	await _start_match()
	watch_signals(_source)

	_room.lost.emit(GuestRoom.Loss.HOST_CLOSED)

	assert_signal_emitted_with_parameters(_source, "ended", [true])
	assert_false(_source.is_live())


func test_leaving_client_hands_seat_to_bot() -> void:
	await _start_match()
	watch_signals(_source)

	_source.leave()
	await wait_frames(FRAMES)

	assert_signal_not_emitted(_source, "ended")
	assert_false(_source.is_live())
	assert_eq(_host.seat_of(CLIENT_PEER), BoardLayout.NO_SEAT)
	assert_true(_game.bots[_game.seats.find(_client_seat)])


func test_host_source_reports_leaving_guest() -> void:
	await _start_match()
	var host_source := RefereeSource.new(_referee, _host_seat, ROOM_CODE, _host)
	watch_signals(host_source)

	_source.leave()
	await wait_frames(FRAMES)

	assert_signal_emitted(host_source, "guests_changed")
	assert_false(host_source.has_guests())


func test_client_source_waits_for_begin_after_rematch() -> void:
	await _start_match()
	_source.begin()
	var over := MatchEvent.new(MatchEvent.Kind.MATCH_OVER)
	_host_transport().send(CLIENT_PEER, MatchMessage.event(over, _client_seat, MAX_EVENTS))
	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)
	assert_eq(_shown.back().kind, MatchEvent.Kind.MATCH_OVER)

	_referee.start(_new_game())
	_host.share_match()
	_referee.begin()
	await wait_frames(FRAMES)
	var count := _shown.size()
	_source.begin()

	assert_eq(count, _shown.size() - 1)
	assert_eq(_shown.back().kind, MatchEvent.Kind.TURN_STARTED)


func _host_transport() -> FakeTransport:
	return _network[MatchTransport.HOST_PEER].get_ref()


## İstemci oturur, hakem oyunu başlatır ve ilk görünüm istemciye ulaşır; sıra hosttadır.
func _start_match() -> void:
	_room.session.join()
	await wait_frames(FRAMES)
	_host.seat_peer(CLIENT_PEER, _client_seat)
	_referee.start(_game)
	_host.share_match()
	_referee.begin()
	await wait_frames(FRAMES)


## Host hamlesini oynar ve istemci gelen bütün olayları bitirir; sıra istemcidedir.
func _reach_client_turn() -> void:
	await _start_match()
	await _play_host_turn()
	await _acknowledge_until_client_turn()


## İstemci hostun sıra başını bitirir (host onu bekler), sonra host hamlesini oynar; istemci
## kartın açılmasını görür.
func _play_host_turn() -> void:
	_source.begin()
	_source.acknowledge(_shown.back())
	await wait_frames(FRAMES)
	_referee.submit(_host_turn())
	await wait_frames(FRAMES)


## Hostun sırasındaki ilk yasal hamle; yoksa ilk kartın atılması.
func _host_turn() -> MatchIntent:
	var legal := _game.legal_moves()
	if legal.is_empty():
		return MatchIntent.discard(_host_seat, 0)
	return MatchIntent.play(_host_seat, legal[0])


## Ekran gösterilen olayı bitirir; host bunu bekler ve her bitirmede sıradaki tek olay gelir.
func _acknowledge_until_client_turn() -> void:
	for _step: int in range(MAX_EVENTS):
		var last := _shown.back() as MatchEvent
		if last.kind == MatchEvent.Kind.TURN_STARTED and last.seat == _client_seat:
			return
		var count := _shown.size()
		_source.acknowledge(last)
		await wait_frames(FRAMES)
		assert_eq(_shown.size(), count + 1)


func _missing_move(seat: int) -> MatchIntent:
	return MatchIntent.play(seat, Move.new(0, Move.Action.FORWARD, MISSING_PAWN, 1))


func _new_game() -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, TWO_HUMANS.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game
