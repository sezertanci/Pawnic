extends GutTest
## Bağlantı yoklaması (PeerWatch) ve kopan koltukların bekleme süresi (SeatPresence), moladaki
## donması dahil.

const PEER := 2
const SEAT := 1
const WAIT_SECONDS := 20.0

var _settings: GameSettings
var _watch: PeerWatch


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_watch = PeerWatch.new(_settings)


func test_first_update_asks_for_heartbeat() -> void:
	assert_true(_watch.update(0))


func test_heartbeat_waits_for_interval() -> void:
	_watch.update(0)

	assert_false(_watch.update(_settings.heartbeat_interval_ms - 1))
	assert_true(_watch.update(_settings.heartbeat_interval_ms))


func test_peer_is_silent_after_limit() -> void:
	_watch.heard(PEER, 0)
	var step := _settings.silence_limit_ms / 2
	_watch.update(step)
	_watch.update(step * 2)
	_watch.update(step * 2 + 1)

	assert_true(_watch.is_silent(PEER, step * 2 + 1))


func test_heard_peer_is_not_silent() -> void:
	_watch.heard(PEER, 0)

	assert_false(_watch.is_silent(PEER, _settings.silence_limit_ms))


func test_forgotten_peer_is_not_silent() -> void:
	_watch.heard(PEER, 0)

	_watch.forget(PEER)

	assert_false(_watch.is_silent(PEER, _settings.silence_limit_ms * 2))


func test_device_pause_is_not_counted_as_silence() -> void:
	_watch.update(0)
	_watch.heard(PEER, 0)
	var resumed := _settings.silence_limit_ms * 10

	_watch.update(resumed)

	assert_false(_watch.is_silent(PEER, resumed))


func test_present_seat_has_no_wait() -> void:
	var presence := SeatPresence.new()

	assert_false(presence.is_away(SEAT))
	assert_eq(presence.wait_left(SEAT, 0), SeatPresence.PRESENT)


func test_away_seat_counts_down_to_zero() -> void:
	var presence := SeatPresence.new()

	presence.mark_away(SEAT, WAIT_SECONDS, 0)

	assert_eq(presence.away_seats(), [SEAT])
	assert_almost_eq(presence.wait_left(SEAT, 5000), WAIT_SECONDS - 5.0, 0.001)
	assert_eq(presence.wait_left(SEAT, 30000), 0.0)


func test_marking_present_reports_change_once() -> void:
	var presence := SeatPresence.new()
	presence.mark_away(SEAT, WAIT_SECONDS, 0)

	assert_true(presence.mark_present(SEAT))
	assert_false(presence.mark_present(SEAT))
	assert_false(presence.is_away(SEAT))


func test_frozen_wait_resumes_where_it_stopped() -> void:
	var presence := SeatPresence.new()
	presence.mark_away(SEAT, WAIT_SECONDS, 0)

	presence.freeze(5000)
	assert_almost_eq(presence.wait_left(SEAT, 60000), WAIT_SECONDS - 5.0, 0.001)
	presence.thaw(60000)

	assert_almost_eq(presence.wait_left(SEAT, 61000), WAIT_SECONDS - 6.0, 0.001)


func test_seat_lost_while_frozen_waits_in_full_after_thaw() -> void:
	var presence := SeatPresence.new()
	presence.freeze(0)

	presence.mark_away(SEAT, WAIT_SECONDS, 30000)
	presence.thaw(50000)

	assert_almost_eq(presence.wait_left(SEAT, 50000), WAIT_SECONDS, 0.001)
