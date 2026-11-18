class_name GameMatch
extends RefCounted
## Bir oyunun bütün durumu: tahta, deste, oyuncuların elleri ve sıra.
## Yeni oyun create() ile, kayıttan dönen oyun from_dict() ile kurulur.

## Oyuncu sayısına göre koltuklar, sıra sırasıyla. İlk oyuncu alttaki koltukta oturur.
const SEAT_ORDER := {2: [2, 0], 3: [2, 3, 0], 4: [2, 3, 0, 1]}
const NO_WINNER := -1
## Array.find bulamadığında döner.
const NO_INDEX := -1
## Kayıt biçimi değişirse artırılır; eski biçimdeki kayıtlar yüklenmez.
const SAVE_VERSION := 2
## Kayıt sözlüğünün anahtarları.
const KEY_VERSION := "version"
const KEY_BOARD := "board"
const KEY_SEATS := "seats"
const KEY_BOTS := "bots"
const KEY_HANDS := "hands"
const KEY_DRAW := "draw"
const KEY_DISCARD := "discard"
const KEY_CURRENT := "current"
const KEY_LAST_DISCARD_SEAT := "last_discard_seat"
const KEY_ELAPSED := "elapsed"
const KEY_TOP_DISCARD_VALUE := "top_discard_value"

var settings: GameSettings
var board: BoardState
var seats: Array[int] = []
var bots: Array[bool] = []
## Her oyuncunun eli (Array[Card]).
var hands: Array[Array] = []
var current := 0
## Atılanların en üstündeki kartı atan koltuk; henüz kart atılmadıysa BoardLayout.NO_SEAT.
var last_discard_seat := BoardLayout.NO_SEAT
## Atılanların en üstündeki joker oynandıysa seçilen sayı; değilse Card.NO_VALUE.
var top_discard_value := Card.NO_VALUE
## Oyunun başından beri geçen süre (saniye); kayıtla birlikte saklanır.
var elapsed := 0.0

var _draw_pile: Array[Card] = []
var _discard_pile: Array[Card] = []
var _rng: RandomNumberGenerator


func _init(game_settings: GameSettings, rng: RandomNumberGenerator) -> void:
	settings = game_settings
	_rng = rng
	board = BoardState.new(settings)


## Yeni oyun kurar: taşları dizer, desteyi karıştırır ve elleri dağıtır.
static func create(
	game_settings: GameSettings,
	bot_flags: Array[bool],
	pawns_per_player: int,
	rng: RandomNumberGenerator
) -> GameMatch:
	var game := GameMatch.new(game_settings, rng)
	game.bots = bot_flags
	for seat: int in SEAT_ORDER[bot_flags.size()]:
		game.seats.append(seat)
		game.board.add_pawns(seat, pawns_per_player)
		game.hands.append(game._new_hand())
	game._build_deck()
	for _round: int in range(game_settings.hand_size):
		for hand: Array[Card] in game.hands:
			game._draw_into(hand)
	return game


## Kayıttan oyunu kurar; kayıt eski ya da bozuksa null döner.
static func from_dict(
	game_settings: GameSettings, data: Dictionary, rng: RandomNumberGenerator
) -> GameMatch:
	if int(data.get(KEY_VERSION, 0)) != SAVE_VERSION:
		return null
	var game := GameMatch.new(game_settings, rng)
	var board_data: Variant = data.get(KEY_BOARD)
	if not board_data is Dictionary or not game.board.load_dict(board_data):
		return null
	for seat: Variant in data.get(KEY_SEATS, []):
		game.seats.append(int(seat))
	for flag: Variant in data.get(KEY_BOTS, []):
		game.bots.append(bool(flag))
	for saved_hand: Variant in data.get(KEY_HANDS, []):
		var hand := game._new_hand()
		if not _read_cards(saved_hand, hand):
			return null
		game.hands.append(hand)
	if not _read_cards(data.get(KEY_DRAW, []), game._draw_pile):
		return null
	if not _read_cards(data.get(KEY_DISCARD, []), game._discard_pile):
		return null
	game.current = int(data.get(KEY_CURRENT, 0))
	game.last_discard_seat = int(data.get(KEY_LAST_DISCARD_SEAT, BoardLayout.NO_SEAT))
	game.elapsed = float(data.get(KEY_ELAPSED, 0.0))
	game.top_discard_value = int(data.get(KEY_TOP_DISCARD_VALUE, Card.NO_VALUE))
	return game if game._is_consistent() else null


func to_dict() -> Dictionary:
	var saved_hands: Array = []
	for hand: Array[Card] in hands:
		saved_hands.append(_write_cards(hand))
	return {
		KEY_VERSION: SAVE_VERSION,
		KEY_BOARD: board.to_dict(),
		KEY_SEATS: seats,
		KEY_BOTS: bots,
		KEY_HANDS: saved_hands,
		KEY_DRAW: _write_cards(_draw_pile),
		KEY_DISCARD: _write_cards(_discard_pile),
		KEY_CURRENT: current,
		KEY_LAST_DISCARD_SEAT: last_discard_seat,
		KEY_ELAPSED: elapsed,
		KEY_TOP_DISCARD_VALUE: top_discard_value,
	}


func current_seat() -> int:
	return seats[current]


func current_hand() -> Array[Card]:
	return hands[current]


func is_bot_turn() -> bool:
	return bots[current]


func human_count() -> int:
	return bots.count(false)


## Oyuncu başına taş sayısı (aynı ayarlarla yeni oyun kurmak için).
func pawns_per_player() -> int:
	return board.owners.count(seats[0])


## İlk insan oyuncunun eli (tek kişilik oyunda bot sırasında da gösterilir);
## insan oyuncu yoksa boş el.
func first_human_hand() -> Array[Card]:
	var index := bots.find(false)
	if index == NO_INDEX:
		return _new_hand()
	return hands[index]


func begin_turn() -> void:
	_draw_into(current_hand())


## Destede kalan kart sayısı.
func draw_count() -> int:
	return _draw_pile.size()


## Atılanların en üstündeki kart; atılan kart yoksa null.
func top_discard() -> Card:
	return null if _discard_pile.is_empty() else _discard_pile.back()


func legal_moves() -> Array[Move]:
	var moves: Array[Move] = []
	var hand := current_hand()
	for index: int in range(hand.size()):
		moves.append_array(board.moves_for_card(current_seat(), hand[index], index))
	return moves


## Hamleyi oynar, kartı atılanlara koyar ve başlangıca dönen taş sayısını verir.
func play(move: Move) -> int:
	var captured := board.apply(move)
	var joker := current_hand()[move.card_index].type == Card.Type.JOKER
	discard(move.card_index)
	if joker:
		top_discard_value = move.value
	return captured


func discard(card_index: int) -> void:
	_discard_pile.append(current_hand().pop_at(card_index))
	last_discard_seat = current_seat()
	top_discard_value = Card.NO_VALUE


func winner() -> int:
	for seat: int in seats:
		if board.has_finished(seat):
			return seat
	return NO_WINNER


func next_turn() -> void:
	current = (current + 1) % seats.size()


func _new_hand() -> Array[Card]:
	var hand: Array[Card] = []
	return hand


func _build_deck() -> void:
	for entry: Dictionary in settings.deck:
		var type: Card.Type = Card.TYPE_BY_NAME[entry["type"]]
		for _i: int in range(int(entry[GameSettings.KEY_CARD_COUNT])):
			_draw_pile.append(Card.new(type, int(entry["value"])))
	_shuffle(_draw_pile)


func _draw_into(hand: Array[Card]) -> void:
	if _draw_pile.is_empty():
		_draw_pile = _discard_pile
		_discard_pile = []
		_shuffle(_draw_pile)
	if not _draw_pile.is_empty():
		hand.append(_draw_pile.pop_back())


## Tohumlanabilir rastgele sayı üreteciyle karıştırır (Fisher–Yates).
func _shuffle(cards: Array[Card]) -> void:
	for i: int in range(cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := cards[i]
		cards[i] = cards[j]
		cards[j] = swap


func _is_consistent() -> bool:
	var count := seats.size()
	if not SEAT_ORDER.has(count) or bots.size() != count or hands.size() != count:
		return false
	var expected_seats: Array[int] = []
	expected_seats.assign(SEAT_ORDER[count])
	if seats != expected_seats or current < 0 or current >= count:
		return false
	if last_discard_seat != BoardLayout.NO_SEAT and not seats.has(last_discard_seat):
		return false
	return board.owners.all(func(owner: int) -> bool: return seats.has(owner))


static func _write_cards(cards: Array[Card]) -> Array:
	var result: Array = []
	for card: Card in cards:
		result.append(card.to_dict())
	return result


## Kayıttaki kartları hedef diziye ekler; tanınmayan kart varsa false döner.
static func _read_cards(saved: Variant, target: Array[Card]) -> bool:
	if not saved is Array:
		return false
	for entry: Variant in saved:
		var card := Card.from_dict(entry) if entry is Dictionary else null
		if card == null:
			return false
		target.append(card)
	return true
