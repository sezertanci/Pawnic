extends GutTest
## İstemcinin kopyası (MatchView): görünüm mesajla gidip gelir, başkalarının kartlarını içermez
## ve hakemin olaylarıyla güncellenince hosttaki oyunla aynı kalır.

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_match_view_save.json"
const SEED := 11
const PAWNS := 4
const TWO_HUMANS: Array[bool] = [false, false]
const FOUR_HUMANS: Array[bool] = [false, false, false, false]
## Bir oyunun bitmesi için verilen en fazla sıra; aşılırsa test başarısız olur.
const MAX_TURNS := 3000
const MISSING_PAWN := 99
## Tahtadaki başlangıç karelerinin dışında kalan koltuk.
const UNKNOWN_SEAT := 99

var _store: SaveStoreScript
var _referee: MatchReferee
var _game: GameMatch
var _views: Array[MatchView] = []
var _mismatches: Array[String] = []
var _over := false


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()
	_views.clear()
	_mismatches.clear()
	_over = false
	_referee = MatchReferee.new()
	_referee.store = _store
	_referee.event_emitted.connect(_on_event)
	add_child_autofree(_referee)


func after_each() -> void:
	_referee.stop()
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func test_snapshot_round_trip_is_equal() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])

	var read := MatchView.from_dict(game.settings, view.to_dict())

	assert_not_null(read)
	assert_eq(read.to_dict(), view.to_dict())


func test_snapshot_holds_only_viewer_hand() -> void:
	var game := _new_game(TWO_HUMANS)

	var view := MatchView.of(game, game.seats[1])

	assert_eq(Card.write_all(view.hand), Card.write_all(game.hands[1]))
	assert_eq(view.hand_sizes, [game.hands[0].size(), game.hands[1].size()])
	assert_eq(view.draw_count, game.draw_count())


func test_snapshot_with_wrong_hand_size_returns_null() -> void:
	var game := _new_game(TWO_HUMANS)
	var data := MatchView.of(game, game.seats[0]).to_dict()
	data[MatchView.KEY_HAND_SIZES] = [0, 0]

	assert_null(MatchView.from_dict(game.settings, data))


func test_snapshot_with_broken_board_returns_null() -> void:
	var game := _new_game(TWO_HUMANS)
	var data := MatchView.of(game, game.seats[0]).to_dict()
	data[GameMatch.KEY_BOARD] = {}

	assert_null(MatchView.from_dict(game.settings, data))


func test_illegal_move_event_is_refused() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])
	var event := MatchEvent.new(MatchEvent.Kind.MOVE_PLAYED, game.seats[0])
	event.card_index = 0
	event.card = game.hands[0][0]
	event.move = Move.new(0, Move.Action.FORWARD, MISSING_PAWN, 1)

	assert_false(view.apply(event))


func test_move_event_from_unknown_seat_is_refused() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])
	var event := MatchEvent.new(MatchEvent.Kind.MOVE_PLAYED, UNKNOWN_SEAT)
	event.card_index = 0
	event.card = Card.new(Card.Type.EXIT, 0)
	event.move = Move.new(0, Move.Action.EXIT, 0)

	assert_false(view.apply(event))


func test_reward_event_puts_new_card_into_viewer_hand() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])
	var event := MatchEvent.new(MatchEvent.Kind.REWARD_ENDED, game.seats[0])
	event.card_index = 0
	event.card = Card.new(Card.Type.EXIT, 0)

	assert_true(view.apply(event))

	assert_true(view.hand[0].same_as(event.card))


func test_reward_event_without_card_is_accepted() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])
	var event := MatchEvent.new(MatchEvent.Kind.REWARD_ENDED, game.seats[1])
	event.card_index = 0

	assert_true(view.apply(event))


func test_reward_event_with_top_discard_updates_discard_top() -> void:
	var game := _new_game(TWO_HUMANS)
	var view := MatchView.of(game, game.seats[0])
	var event := MatchEvent.new(MatchEvent.Kind.REWARD_ENDED, game.seats[1])
	event.card_index = 0
	event.top_discard = Card.new(Card.Type.EXIT, 0)

	assert_true(view.apply(event))

	assert_true(view.top_discard.same_as(event.top_discard))
	assert_eq(view.last_discard_seat, game.seats[1])
	assert_eq(view.top_discard_value, Card.NO_VALUE)


func test_views_follow_whole_two_player_match() -> void:
	_play_whole_match(TWO_HUMANS)

	assert_true(_over)
	assert_eq(_mismatches, [])


func test_views_follow_whole_four_player_match() -> void:
	_play_whole_match(FOUR_HUMANS)

	assert_true(_over)
	assert_eq(_mismatches, [])


## Her koltuk için bir kopya mesajla kurulur; oyuncuların niyetini bot seçer. Olaylar her kopyaya
## mesaj olarak gider; her sıranın başında kopyalar hosttaki oyunla karşılaştırılır.
func _play_whole_match(bot_flags: Array[bool]) -> void:
	_game = _new_game(bot_flags)
	for seat: int in _game.seats:
		var snapshot := MatchView.of(_game, seat).to_dict()
		_views.append(MatchView.from_dict(_game.settings, snapshot))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var bot := Bot.new(_game.settings.bot_profiles[Bot.Level.EASY], _game.settings, rng)
	_referee.start(_game)
	_referee.begin()
	for _turn: int in range(MAX_TURNS):
		if _over or not _referee.is_awaiting_intent():
			return
		_referee.submit(_choose(bot))


func _choose(bot: Bot) -> MatchIntent:
	var move := bot.choose_move(_game)
	if move != null:
		return MatchIntent.play(_game.current_seat(), move)
	return MatchIntent.discard(_game.current_seat(), bot.choose_discard(_game.current_hand()))


func _on_event(event: MatchEvent) -> void:
	_over = _over or event.kind == MatchEvent.Kind.MATCH_OVER
	for view: MatchView in _views:
		var received := MatchEvent.from_dict(event.to_dict(view.viewer_seat))
		if not view.apply(received):
			_mismatches.append("olay uygulanamadı: %d, koltuk %d" % [event.kind, view.viewer_seat])
		elif event.kind == MatchEvent.Kind.TURN_STARTED or _over:
			_check_view(view)
	_referee.acknowledge()


func _check_view(view: MatchView) -> void:
	var expected := MatchView.of(_game, view.viewer_seat).to_dict()
	if view.to_dict() != expected:
		_mismatches.append(
			"kopya ayrıştı: koltuk %d, tur %d" % [view.viewer_seat, _game.round_number]
		)


func _new_game(bot_flags: Array[bool]) -> GameMatch:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)
	settings.bot_delay = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var game := GameMatch.create(settings, bot_flags.duplicate(), PAWNS, rng)
	game.bot_level = Bot.Level.EASY
	return game
