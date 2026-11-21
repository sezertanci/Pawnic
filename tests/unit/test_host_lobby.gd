extends GutTest
## Hostun lobisi sahte taşıyıcı üzerinden: oda kodu, yanlış denemede kodun yenilenmesi, dolu oda,
## renk seçimi, ayrılan oyuncu ve oyunun başlatılması.

const SEED := 5
const CLIENT_PEER := 2
const OTHER_PEER := 3
## Yanlış kod deneyen eşlerin numaraları bundan başlar.
const STRANGER_BASE := 10
const WRONG_CODE := "kod"
## Mesajın ulaşması için beklenen kare sayısı (gidiş ve dönüş).
const FRAMES := 4
const PAWNS := 3
const TWO_SEATS := 2
const FOUR_SEATS := 4
const RED := 0
const BLUE := 1
const GREEN := 2
const YELLOW := 3

var _settings: GameSettings
var _network: Dictionary
var _referee: MatchReferee
var _session: HostSession
var _lobby: HostLobby
var _clients: Dictionary[int, ClientSession] = {}
## Eş numarası → aldığı ret nedenleri.
var _refusals: Dictionary[int, Array] = {}


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_network = {}
	_clients.clear()
	_refusals.clear()
	_referee = MatchReferee.new()
	add_child_autofree(_referee)
	var transport := FakeTransport.new(MatchTransport.HOST_PEER, _network)
	_session = HostSession.new(_referee, transport, _settings)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_lobby = HostLobby.new(_settings, transport, _session, rng)


func test_code_has_configured_digits() -> void:
	assert_eq(_lobby.code.length(), _settings.room_code_digits)
	assert_true(_lobby.code.is_valid_int())


func test_right_code_joins_with_first_free_color() -> void:
	var client := await _join(CLIENT_PEER, _lobby.code)

	assert_eq(_lobby.info().colors, [RED, BLUE])
	assert_eq(client.lobby.colors, [RED, BLUE])
	assert_eq(client.lobby.own, 1)
	assert_eq(client.lobby.seat_count, _lobby.seat_count)


func test_wrong_code_is_refused_and_disconnected() -> void:
	await _join(CLIENT_PEER, WRONG_CODE)

	assert_eq(_refusals[CLIENT_PEER], [MatchMessage.Refusal.WRONG_CODE])
	assert_false(_network.has(CLIENT_PEER))
	assert_eq(_lobby.info().colors, [RED])


func test_code_is_renewed_after_max_wrong_codes() -> void:
	var old_code := _lobby.code
	watch_signals(_lobby)
	for index: int in range(_settings.max_wrong_codes - 1):
		await _join(STRANGER_BASE + index, WRONG_CODE)
	assert_eq(_lobby.code, old_code)

	await _join(STRANGER_BASE + _settings.max_wrong_codes, WRONG_CODE)
	await _join(CLIENT_PEER, old_code)

	assert_ne(_lobby.code, old_code)
	assert_signal_emitted_with_parameters(_lobby, "code_changed", [_lobby.code])
	assert_eq(_refusals[CLIENT_PEER], [MatchMessage.Refusal.WRONG_CODE])


func test_full_room_is_refused() -> void:
	_lobby.set_seat_count(TWO_SEATS)
	await _join(CLIENT_PEER, _lobby.code)

	await _join(OTHER_PEER, _lobby.code)

	assert_eq(_refusals[OTHER_PEER], [MatchMessage.Refusal.ROOM_FULL])
	assert_eq(_lobby.info().colors.size(), TWO_SEATS)


func test_member_cannot_take_used_color() -> void:
	var client := await _join(CLIENT_PEER, _lobby.code)

	client.choose_color(RED)
	await wait_frames(FRAMES)
	assert_eq(client.lobby.colors, [RED, BLUE])
	client.choose_color(YELLOW)
	await wait_frames(FRAMES)

	assert_eq(client.lobby.colors, [RED, YELLOW])
	assert_eq(_lobby.info().colors, [RED, YELLOW])


func test_host_color_change_reaches_members() -> void:
	var client := await _join(CLIENT_PEER, _lobby.code)

	assert_false(_lobby.choose_host_color(BLUE))
	assert_true(_lobby.choose_host_color(GREEN))
	await wait_frames(FRAMES)

	assert_eq(client.lobby.colors, [GREEN, BLUE])


func test_seat_count_cannot_drop_below_players() -> void:
	await _join(CLIENT_PEER, _lobby.code)
	await _join(OTHER_PEER, _lobby.code)

	assert_false(_lobby.set_seat_count(TWO_SEATS))
	assert_false(_lobby.set_pawns(_settings.max_pawns + 1))
	assert_true(_lobby.set_seat_count(_settings.max_players - 1))
	assert_eq(_lobby.seat_count, _settings.max_players - 1)


func test_leaving_member_frees_place_and_color() -> void:
	await _join(CLIENT_PEER, _lobby.code)
	var other := await _join(OTHER_PEER, _lobby.code)

	var transport: FakeTransport = _network[CLIENT_PEER].get_ref()
	transport.disconnect_peer()
	await wait_frames(FRAMES)

	assert_eq(_lobby.info().colors, [RED, GREEN])
	assert_eq(other.lobby.own, 1)


func test_start_seats_players_and_fills_bots() -> void:
	_lobby.set_seat_count(FOUR_SEATS)
	_lobby.set_pawns(PAWNS)
	var client := await _join(CLIENT_PEER, _lobby.code)
	client.choose_color(YELLOW)
	await wait_frames(FRAMES)

	var game := _lobby.start()

	assert_eq(game.bots, [false, false, true, true])
	assert_eq(game.bot_level, Bot.Level.MEDIUM)
	assert_eq(game.pawns_per_player(), PAWNS)
	assert_eq(game.colors[game.seats[0]], RED)
	assert_eq(game.colors[game.seats[1]], YELLOW)
	assert_true(SeatColors.is_valid(game.colors, game.colors.size()))
	assert_eq(_session.seat_of(CLIENT_PEER), game.seats[1])
	assert_null(_lobby.start())


func test_rematch_keeps_players_colors_and_pawns() -> void:
	_lobby.set_seat_count(FOUR_SEATS)
	_lobby.set_pawns(PAWNS)
	var client := await _join(CLIENT_PEER, _lobby.code)
	client.choose_color(YELLOW)
	await wait_frames(FRAMES)
	var first := _lobby.start()

	var game := _lobby.rematch(first)

	assert_ne(game, first)
	assert_eq(game.bots, first.bots)
	assert_eq(game.seats, first.seats)
	assert_eq(game.colors, first.colors)
	assert_eq(game.pawns_per_player(), PAWNS)
	assert_eq(game.bot_level, Bot.Level.MEDIUM)
	assert_eq(_session.seat_of(CLIENT_PEER), game.seats[1])
	assert_true(_session.has_guests())


func test_rematch_gives_left_player_seat_to_bot() -> void:
	var client := await _join(CLIENT_PEER, _lobby.code)
	var first := _lobby.start()
	client.leave()
	await wait_frames(FRAMES)

	var game := _lobby.rematch(first)

	assert_false(_session.has_guests())
	assert_eq(game.bots, [false, true, true, true])


func test_rematch_before_start_returns_null() -> void:
	var bot_flags: Array[bool] = [false, true]
	var first := GameMatch.create(_settings, bot_flags, PAWNS, RandomNumberGenerator.new())

	assert_null(_lobby.rematch(first))


func test_hello_after_start_is_refused() -> void:
	_lobby.start()

	await _join(CLIENT_PEER, _lobby.code)

	assert_eq(_refusals[CLIENT_PEER], [MatchMessage.Refusal.MATCH_STARTED])
	assert_false(_lobby.set_pawns(PAWNS))


## Eşi oda koduyla katılmaya çalıştırır ve cevabı bekler.
func _join(peer_id: int, room_code: String) -> ClientSession:
	var client := ClientSession.new(FakeTransport.new(peer_id, _network), _settings)
	_clients[peer_id] = client
	_refusals[peer_id] = []
	client.refused.connect(func(reason: int) -> void: _refusals[peer_id].append(reason))
	client.join(room_code)
	await wait_frames(FRAMES)
	return client
