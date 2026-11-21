extends GutTest
## Ağ mesajlarının sözlüğe çevrilip geri okunması: hamle, niyet, olay ve zarf. Bozuk girdi
## çökertmez, null ya da geçersiz tür olarak döner.

const SEAT := 2
const OTHER_SEAT := 0
const CARD_INDEX := 1
const STEPS := 5
const TARGET_SQUARE := 7
const PATH: Array[int] = [3, 4, 5]
const ROUND := 3
const ELAPSED := 12.5
const BAD_KIND := 99
const TURN_SECONDS := 12.5
const OFFER_INDEX := 2


func test_move_round_trip_keeps_fields() -> void:
	var move := _move()

	var read := Move.from_dict(move.to_dict())

	assert_true(move.equals(read))


func test_move_with_missing_field_returns_null() -> void:
	var data := _move().to_dict()
	data.erase(Move.KEY_PAWN)

	assert_null(Move.from_dict(data))


func test_move_with_unknown_action_returns_null() -> void:
	var data := _move().to_dict()
	data[Move.KEY_ACTION] = BAD_KIND

	assert_null(Move.from_dict(data))


func test_move_with_text_field_returns_null() -> void:
	var data := _move().to_dict()
	data[Move.KEY_DESTINATION] = "7"

	assert_null(Move.from_dict(data))


func test_play_intent_round_trip_keeps_move() -> void:
	var intent := MatchIntent.play(SEAT, _move())

	var read := MatchIntent.from_dict(intent.to_dict())

	assert_eq(read.kind, MatchIntent.Kind.PLAY)
	assert_eq(read.seat, SEAT)
	assert_true(read.move.equals(intent.move))


func test_discard_intent_round_trip_keeps_card() -> void:
	var read := MatchIntent.from_dict(MatchIntent.discard(SEAT, CARD_INDEX).to_dict())

	assert_eq(read.kind, MatchIntent.Kind.DISCARD)
	assert_eq(read.card_index, CARD_INDEX)
	assert_null(read.move)


func test_play_intent_without_move_returns_null() -> void:
	var data := MatchIntent.play(SEAT, _move()).to_dict()
	data.erase(MessageData.KEY_MOVE)

	assert_null(MatchIntent.from_dict(data))


func test_event_round_trip_keeps_fields() -> void:
	var event := _played_event()

	var read := MatchEvent.from_dict(event.to_dict(OTHER_SEAT))

	assert_eq(read.kind, MatchEvent.Kind.MOVE_PLAYED)
	assert_eq(read.seat, SEAT)
	assert_eq(read.card_index, CARD_INDEX)
	assert_eq(read.path, PATH)
	assert_true(read.move.equals(event.move))
	assert_eq(read.card.to_dict(), event.card.to_dict())


func test_drawn_card_is_hidden_from_other_seats() -> void:
	var event := _turn_event()

	var own := MatchEvent.from_dict(event.to_dict(SEAT))
	var other := MatchEvent.from_dict(event.to_dict(OTHER_SEAT))

	assert_eq(own.card.to_dict(), event.card.to_dict())
	assert_null(other.card)
	assert_true(other.drew)
	assert_eq(other.round_number, ROUND)
	assert_eq(other.elapsed, ELAPSED)


func test_event_with_unknown_kind_returns_null() -> void:
	var data := _turn_event().to_dict(SEAT)
	data[MessageData.KEY_KIND] = BAD_KIND

	assert_null(MatchEvent.from_dict(data))


func test_event_with_broken_card_returns_null() -> void:
	var data := _played_event().to_dict(SEAT)
	data[MatchEvent.KEY_CARD] = {Card.KEY_TYPE: "unknown"}

	assert_null(MatchEvent.from_dict(data))


func test_message_envelope_keeps_type_and_data() -> void:
	var intent := MatchIntent.discard(SEAT, CARD_INDEX)

	var message := MatchMessage.intent(intent)

	assert_eq(MatchMessage.type_of(message), MatchMessage.Type.INTENT)
	assert_eq(MatchMessage.data_of(message), intent.to_dict())


func test_turn_timer_message_keeps_seat_and_seconds() -> void:
	var message := MatchMessage.turn_timer(SEAT, TURN_SECONDS)

	var data := MatchMessage.data_of(message)

	assert_eq(MatchMessage.type_of(message), MatchMessage.Type.TURN_TIMER)
	assert_eq(data[MessageData.KEY_SEAT], SEAT)
	assert_eq(data[MatchMessage.KEY_SECONDS], TURN_SECONDS)


func test_broken_envelope_has_invalid_type() -> void:
	var unknown := MatchMessage.make(MatchMessage.Type.EVENT, {})
	unknown[MatchMessage.KEY_TYPE] = BAD_KIND
	var no_data := {MatchMessage.KEY_TYPE: MatchMessage.Type.EVENT}

	assert_eq(MatchMessage.type_of(unknown), MessageData.INVALID)
	assert_eq(MatchMessage.type_of(no_data), MessageData.INVALID)
	assert_eq(MatchMessage.type_of({}), MessageData.INVALID)


func test_reward_take_intent_round_trip_keeps_offer_and_card() -> void:
	var intent := MatchIntent.reward(MatchIntent.Kind.REWARD_TAKE, SEAT, OFFER_INDEX, CARD_INDEX)

	var read := MatchIntent.from_dict(intent.to_dict())

	assert_eq(read.kind, MatchIntent.Kind.REWARD_TAKE)
	assert_eq(read.offer_index, OFFER_INDEX)
	assert_eq(read.card_index, CARD_INDEX)
	assert_true(read.is_reward())


func test_reward_offers_are_hidden_from_other_seats() -> void:
	var event := MatchEvent.new(MatchEvent.Kind.REWARD_STARTED, SEAT)
	event.offers = [Card.new(Card.Type.FORWARD, STEPS), Card.new(Card.Type.BACK, STEPS)]

	var own := MatchEvent.from_dict(event.to_dict(SEAT))
	var other := MatchEvent.from_dict(event.to_dict(OTHER_SEAT))

	assert_eq(own.offers.size(), event.offers.size())
	assert_eq(own.offers[1].to_dict(), event.offers[1].to_dict())
	assert_eq(other.offers.size(), 0)


func test_reward_card_is_hidden_from_other_seats() -> void:
	var event := MatchEvent.new(MatchEvent.Kind.REWARD_ENDED, SEAT)
	event.card_index = CARD_INDEX
	event.card = Card.new(Card.Type.FORWARD, STEPS)

	var own := MatchEvent.from_dict(event.to_dict(SEAT))
	var other := MatchEvent.from_dict(event.to_dict(OTHER_SEAT))

	assert_eq(own.card.to_dict(), event.card.to_dict())
	assert_null(other.card)
	assert_eq(other.card_index, CARD_INDEX)


func _move() -> Move:
	return Move.new(CARD_INDEX, Move.Action.FORWARD, 0, STEPS, Move.NO_PAWN, TARGET_SQUARE)


func _played_event() -> MatchEvent:
	var event := MatchEvent.new(MatchEvent.Kind.MOVE_PLAYED, SEAT)
	event.card_index = CARD_INDEX
	event.card = Card.new(Card.Type.FORWARD, STEPS)
	event.move = _move()
	event.path = PATH
	return event


func _turn_event() -> MatchEvent:
	var event := MatchEvent.new(MatchEvent.Kind.TURN_STARTED, SEAT)
	event.drew = true
	event.card = Card.new(Card.Type.BACK, STEPS)
	event.round_number = ROUND
	event.elapsed = ELAPSED
	return event
