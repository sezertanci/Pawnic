extends "res://tests/fixtures/referee_case.gd"
## Hakemde ödüllü reklam akışı: teklifler, kartın değişmesi, turda bir kez kuralı, bekleme süresi
## ve ödülün kapanış olayı bitene kadar sıra süresinin durması.


func test_reward_start_offers_cards_and_stops_turn_time() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)

	var accepted := _referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))

	assert_true(accepted)
	assert_eq(_events.back().kind, MatchEvent.Kind.REWARD_STARTED)
	assert_eq(_events.back().offers.size(), game.settings.reward_offer_count)
	assert_eq(_referee.reward_seat(), game.current_seat())
	assert_eq(_referee.turn_time_left(), MatchReferee.NO_TURN_TIMER)


func test_reward_take_swaps_card_and_restarts_turn_time() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)
	_referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))
	var offer: Card = _events.back().offers[0]

	var accepted := _referee.submit(
		MatchIntent.reward(MatchIntent.Kind.REWARD_TAKE, game.current_seat(), 0, 0)
	)

	assert_true(accepted)
	assert_eq(_events.back().kind, MatchEvent.Kind.REWARD_ENDED)
	assert_true(game.current_hand()[0].same_as(offer))
	assert_eq(_referee.reward_seat(), BoardLayout.NO_SEAT)
	assert_eq(_referee.turn_time_left(), TURN_TIME)


func test_turn_time_waits_until_reward_end_is_shown() -> void:
	_referee.turn_time_limit = TURN_TIME
	var game := _new_game(HUMANS)
	_start(game)
	_referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))
	_auto_ack = false
	_referee.submit(_reward(MatchIntent.Kind.REWARD_CANCEL, game))

	_referee._process(SHORT_TURN_TIME)
	var left_while_shown := _referee.turn_time_left()
	_referee.acknowledge()

	assert_eq(left_while_shown, MatchReferee.NO_TURN_TIMER)
	assert_eq(_referee.turn_time_left(), TURN_TIME)


func test_reward_can_start_once_per_turn() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	_referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))
	_referee.submit(_reward(MatchIntent.Kind.REWARD_CANCEL, game))

	var accepted := _referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))

	assert_false(accepted)


func test_reward_blocks_play_until_it_ends() -> void:
	var game := _new_game(HUMANS)
	_give_exit_cards(game)
	_start(game)
	_referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))

	var accepted := _referee.submit(MatchIntent.play(game.current_seat(), game.legal_moves()[0]))

	assert_false(accepted)
	assert_eq(game.current, 0)


func test_reward_cancel_without_reward_is_rejected() -> void:
	var game := _new_game(HUMANS)
	_start(game)

	var accepted := _referee.submit(_reward(MatchIntent.Kind.REWARD_CANCEL, game))

	assert_false(accepted)


func test_reward_ends_by_itself_after_wait_time() -> void:
	var game := _new_game(HUMANS)
	_start(game)
	_referee.submit(_reward(MatchIntent.Kind.REWARD_START, game))

	_referee._process(game.settings.reward_wait_time + 1.0)

	assert_eq(_events.back().kind, MatchEvent.Kind.REWARD_ENDED)
	assert_eq(_events.back().card_index, MatchEvent.NO_CARD)
	assert_eq(_referee.reward_seat(), BoardLayout.NO_SEAT)


func _reward(kind: MatchIntent.Kind, game: GameMatch) -> MatchIntent:
	return MatchIntent.reward(kind, game.current_seat())
