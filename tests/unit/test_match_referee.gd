extends "res://tests/fixtures/referee_case.gd"
## Hakemin (MatchReferee) sıra akışı: olayların sırası, ekranın ve bekletmelerin beklenmesi,
## niyetlerin doğrulanması, kayıt, saat ve mola.


func test_begin_saves_and_starts_turn_with_draw() -> void:
	_start(_new_game(HUMANS))

	assert_eq(_kinds(), [MatchEvent.Kind.TURN_STARTED])
	assert_true(_events[0].drew)
	assert_true(_store.has_match())
	assert_true(_referee.is_awaiting_intent())


func test_flow_waits_until_event_is_acknowledged() -> void:
	_auto_ack = false
	_start(_new_game(HUMANS))
	assert_false(_referee.is_awaiting_intent())

	_referee.acknowledge()

	assert_true(_referee.is_awaiting_intent())


func test_flow_waits_until_every_hold_is_released() -> void:
	_referee.event_emitted.connect(func(_event: MatchEvent) -> void: _referee.hold())
	_start(_new_game(HUMANS))
	assert_false(_referee.is_awaiting_intent())

	_referee.release()

	assert_true(_referee.is_awaiting_intent())


func test_submit_plays_legal_move_and_passes_turn() -> void:
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)
	var move := game.legal_moves()[0]

	var accepted := _referee.submit(MatchIntent.play(game.current_seat(), move))

	assert_true(accepted)
	var expected := [
		MatchEvent.Kind.TURN_STARTED,
		MatchEvent.Kind.CARD_REVEALED,
		MatchEvent.Kind.MOVE_PLAYED,
		MatchEvent.Kind.TURN_STARTED,
	]
	assert_eq(_kinds(), expected)
	assert_eq(game.current, 1)


func test_submit_rejects_other_seat() -> void:
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)
	var move := game.legal_moves()[0]

	var accepted := _referee.submit(MatchIntent.play(game.seats[1], move))

	assert_false(accepted)
	assert_eq(_events.size(), 1)


func test_submit_rejects_move_that_is_not_legal() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	var move := Move.new(0, Move.Action.FORWARD, 0, 99)

	var accepted := _referee.submit(MatchIntent.play(game.current_seat(), move))

	assert_false(accepted)
	assert_true(_referee.is_awaiting_intent())


func test_submit_rejects_discard_while_move_exists() -> void:
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)

	var accepted := _referee.submit(MatchIntent.discard(game.current_seat(), 0))

	assert_false(accepted)


func test_submit_discards_when_no_move_exists() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	_fill_hand(game.current_hand(), Card.Type.BACK, BACK_VALUE)
	var before := game.discard_count()

	var accepted := _referee.submit(MatchIntent.discard(game.current_seat(), 0))

	assert_true(accepted)
	assert_eq(_kinds().slice(1, 3), [MatchEvent.Kind.CARD_REVEALED, MatchEvent.Kind.DISCARDED])
	assert_eq(game.discard_count(), before + 1)


func test_stop_releases_waiting_flow() -> void:
	_auto_ack = false
	_start(_new_game(HUMANS))

	_referee.stop()
	_referee.acknowledge()

	assert_null(_referee.game)
	assert_false(_referee.is_awaiting_intent())
	assert_eq(_events.size(), 1)


func test_leave_keeps_save_with_current_elapsed() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	game.elapsed = 42.0

	_referee.leave()

	assert_eq(float(_store.load_match()[GameMatch.KEY_ELAPSED]), 42.0)


func test_ad_due_is_saved_and_stops_clock() -> void:
	_auto_ack = false
	var game := _new_game(HUMANS)
	game.elapsed = game.settings.interstitial_interval
	_start(game)

	await wait_frames(FRAMES)

	assert_eq(_kinds(), [MatchEvent.Kind.AD_DUE])
	assert_eq(game.last_ad_at, game.settings.interstitial_interval)
	assert_eq(game.elapsed, game.settings.interstitial_interval)
	assert_eq(float(_store.load_match()[GameMatch.KEY_LAST_AD_AT]), game.last_ad_at)


func test_bot_plays_its_turn_by_itself() -> void:
	var game := _new_game(BOT_FIRST)
	_start(game)

	await wait_until(_referee.is_awaiting_intent, BOT_TIMEOUT)

	assert_true(_referee.is_awaiting_intent())
	assert_eq(game.current, 1)
	assert_true(_kinds().has(MatchEvent.Kind.CARD_REVEALED))


func test_turn_timer_starts_when_intent_is_awaited() -> void:
	_referee.turn_time_limit = TURN_TIME
	var started: Array = []
	_referee.turn_timer_started.connect(
		func(seat: int, seconds: float) -> void: started.append([seat, seconds])
	)
	var game := _new_game(HUMANS)

	_start(game)

	assert_eq(started, [[game.current_seat(), TURN_TIME]])
	assert_eq(_referee.turn_time_left(), TURN_TIME)


func test_expired_turn_is_played_by_bot_and_seat_stays_human() -> void:
	_referee.turn_time_limit = SHORT_TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)

	await wait_until(func() -> bool: return game.current == 1, BOT_TIMEOUT)

	assert_eq(game.current, 1)
	assert_true(_kinds().has(MatchEvent.Kind.CARD_REVEALED))
	assert_eq(game.bots, [false, false])


func test_submit_stops_turn_timer() -> void:
	_referee.turn_time_limit = TURN_TIME
	_auto_ack = false
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)
	_referee.acknowledge()

	_referee.submit(MatchIntent.play(game.current_seat(), game.legal_moves()[0]))

	assert_eq(_referee.turn_time_left(), MatchReferee.NO_TURN_TIMER)


func test_device_pause_does_not_use_turn_time() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)
	var started: Array = []
	_referee.turn_timer_started.connect(
		func(seat: int, seconds: float) -> void: started.append([seat, seconds])
	)
	var pause := game.settings.silence_limit_ms * 2.0 / ClientSource.MSEC_PER_SECOND

	_referee._process(pause)

	assert_true(_referee.is_awaiting_intent())
	assert_eq(started, [[game.current_seat(), _referee.turn_time_left()]])
	assert_gt(_referee.turn_time_left(), TURN_TIME - pause)


func test_pause_stops_clock_and_turn_time() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)
	var elapsed := game.elapsed

	_referee.pause()
	await wait_frames(FRAMES)

	assert_true(_referee.is_paused())
	assert_eq(game.elapsed, elapsed)
	assert_eq(_referee.turn_time_left(), TURN_TIME)
	assert_gt(_referee.pause_time(), 0.0)


func test_paused_flow_waits_for_resume() -> void:
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)
	_referee.pause()

	_referee.submit(MatchIntent.play(game.current_seat(), game.legal_moves()[0]))
	assert_eq(_kinds(), [MatchEvent.Kind.TURN_STARTED])
	_referee.resume()

	assert_false(_referee.is_paused())
	assert_eq(_referee.pause_time(), MatchReferee.NOT_PAUSED)
	assert_eq(game.current, 1)


func test_resume_restarts_turn_timer_with_time_left() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)
	var started: Array = []
	_referee.turn_timer_started.connect(
		func(seat: int, seconds: float) -> void: started.append([seat, seconds])
	)
	_referee.pause()

	_referee.resume()

	assert_eq(started, [[game.current_seat(), TURN_TIME]])


func test_stopped_referee_cannot_be_paused() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	_referee.stop()

	_referee.pause()

	assert_false(_referee.is_paused())


func test_local_match_has_no_turn_timer() -> void:
	_start(_new_game(HUMANS))

	assert_true(_referee.is_awaiting_intent())
	assert_eq(_referee.turn_time_left(), MatchReferee.NO_TURN_TIMER)
