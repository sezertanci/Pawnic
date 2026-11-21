extends GutTest
## Ödüllü reklamla desteden kart seçiminin (RewardDealer, GameMatch.take_reward) birim testleri.

const SEED := 42
const PAWNS := 4

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_offers_returns_distinct_cards_up_to_offer_count() -> void:
	var game := _new_game()

	var offers := RewardDealer.new(_settings).offers(game)

	assert_eq(offers.size(), _settings.reward_offer_count)
	for index: int in range(offers.size()):
		for other: int in range(index + 1, offers.size()):
			assert_false(offers[index].same_as(offers[other]))


func test_offers_puts_playable_cards_before_unplayable_ones() -> void:
	var game := _new_game()
	var seat := game.current_seat()

	var offers := RewardDealer.new(_settings).offers(game)

	assert_false(game.board.moves_for_card(seat, offers[0], 0).is_empty())


func test_offers_only_contains_cards_in_draw_pile() -> void:
	var game := _new_game()
	var pile := game.draw_cards()

	var offers := RewardDealer.new(_settings).offers(game)

	for card: Card in offers:
		assert_true(pile.any(func(other: Card) -> bool: return other.same_as(card)))


func test_take_reward_swaps_hand_card_with_draw_pile_card() -> void:
	var game := _new_game()
	var card: Card = RewardDealer.new(_settings).offers(game)[0]
	var hand_size := game.current_hand().size()
	var draw_count := game.draw_count()

	var taken := game.take_reward(0, card)

	assert_true(taken)
	assert_true(game.current_hand()[0].same_as(card))
	assert_eq(game.current_hand().size(), hand_size)
	assert_eq(game.draw_count(), draw_count)


func test_take_reward_with_card_not_in_draw_pile_fails() -> void:
	var game := _new_game()
	var missing := Card.new(Card.Type.FORWARD, 99)
	var before: Card = game.current_hand()[0]

	var taken := game.take_reward(0, missing)

	assert_false(taken)
	assert_eq(game.current_hand()[0], before)


func test_take_reward_with_invalid_hand_index_fails() -> void:
	var game := _new_game()
	var card: Card = game.draw_cards()[0]

	var taken := game.take_reward(game.current_hand().size(), card)

	assert_false(taken)


func _new_game() -> GameMatch:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return GameMatch.create(_settings, [false, true] as Array[bool], PAWNS, rng)
