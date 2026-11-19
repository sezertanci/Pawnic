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
const SAVE_VERSION := 3
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
const KEY_LAST_AD_AT := "last_ad_at"
const KEY_TOP_DISCARD_VALUE := "top_discard_value"
const KEY_BOT_LEVEL := "bot_level"
const KEY_ROUND := "round"
const KEY_FINISHERS := "finishers"
const KEY_FINISH_ROUNDS := "finish_rounds"

var settings: GameSettings
var board: BoardState
var seats: Array[int] = []
var bots: Array[bool] = []
## Bütün botların zorluk seviyesi.
var bot_level := Bot.Level.MEDIUM
## Her oyuncunun eli (Array[Card]).
var hands: Array[Array] = []
var current := 0
## Atılanların en üstündeki kartı atan koltuk; henüz kart atılmadıysa BoardLayout.NO_SEAT.
var last_discard_seat := BoardLayout.NO_SEAT
## Atılanların en üstündeki joker oynandıysa seçilen sayı; değilse Card.NO_VALUE.
var top_discard_value := Card.NO_VALUE
## Oyunun başından beri geçen süre (saniye); kayıtla birlikte saklanır.
var elapsed := 0.0
## Son oyun içi reklamın gösterildiği oyun süresi; reklam gösterilmediyse AdSchedule.NO_AD.
var last_ad_at := AdSchedule.NO_AD
## Kaçıncı turda olunduğu; sıra ilk oyuncuya her döndüğünde artar.
var round_number := 1
## Bütün taşlarını eve getiren koltuklar, bitirme sırasıyla.
var finishers: Array[int] = []
## finishers ile aynı sırada, her oyuncunun bitirdiği tur.
var finish_rounds: Array[int] = []

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
	game.last_ad_at = float(data.get(KEY_LAST_AD_AT, AdSchedule.NO_AD))
	game.top_discard_value = int(data.get(KEY_TOP_DISCARD_VALUE, Card.NO_VALUE))
	var level := int(data.get(KEY_BOT_LEVEL, Bot.Level.MEDIUM))
	if not Bot.Level.values().has(level):
		return null
	game.bot_level = level as Bot.Level
	game.round_number = int(data.get(KEY_ROUND, 1))
	for seat: Variant in data.get(KEY_FINISHERS, []):
		game.finishers.append(int(seat))
	for finish_round: Variant in data.get(KEY_FINISH_ROUNDS, []):
		game.finish_rounds.append(int(finish_round))
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
		KEY_LAST_AD_AT: last_ad_at,
		KEY_TOP_DISCARD_VALUE: top_discard_value,
		KEY_BOT_LEVEL: bot_level,
		KEY_ROUND: round_number,
		KEY_FINISHERS: finishers,
		KEY_FINISH_ROUNDS: finish_rounds,
	}


func current_seat() -> int:
	return seats[current]


func current_hand() -> Array[Card]:
	return hands[current]


func is_bot_turn() -> bool:
	return bots[current]


## Henüz bitirmemiş insan oyuncu sayısı.
func playing_human_count() -> int:
	var count := 0
	for index: int in range(seats.size()):
		if not bots[index] and is_playing(index):
			count += 1
	return count


## Sıradaki index'teki oyuncu henüz bitirmediyse true.
func is_playing(index: int) -> bool:
	return not finishers.has(seats[index])


## Oyuncu başına taş sayısı (aynı ayarlarla yeni oyun kurmak için).
func pawns_per_player() -> int:
	return board.owners.count(seats[0])


## Henüz bitirmemiş ilk insan oyuncunun eli (tek insan kaldığında bot sırasında da gösterilir);
## böyle bir oyuncu yoksa boş el.
func first_playing_human_hand() -> Array[Card]:
	for index: int in range(seats.size()):
		if not bots[index] and is_playing(index):
			return hands[index]
	return _new_hand()


func begin_turn() -> void:
	_draw_into(current_hand())


## Deste boşsa ve atılanlarda kart varsa atılanları karıştırıp yeni deste yapar, atılanlar
## boşalır. Sıradaki oyuncu çekmeden önce çağrılır; karıştırma yapıldıysa true döner.
func reshuffle_if_empty() -> bool:
	if not _draw_pile.is_empty() or _discard_pile.is_empty():
		return false
	_draw_pile = _discard_pile
	_discard_pile = []
	_shuffle(_draw_pile)
	return true


## Destede kalan kart sayısı.
func draw_count() -> int:
	return _draw_pile.size()


## Atılanlardaki kart sayısı.
func discard_count() -> int:
	return _discard_pile.size()


## Atılanların en üstündeki kart; atılan kart yoksa null.
func top_discard() -> Card:
	return null if _discard_pile.is_empty() else _discard_pile.back()


## Sıradaki oyuncunun göremediği kartlar: deste ve diğer oyuncuların elleri. Bu, desteden
## atılanların ve kendi elinin çıkarılmasıyla herkesin bulabileceği bilgidir; sıra bilgisi içermez.
func unseen_cards() -> Array[Card]:
	var cards: Array[Card] = _draw_pile.duplicate()
	for index: int in range(hands.size()):
		if index != current:
			cards.append_array(hands[index])
	return cards


## Sıradaki oyuncunun gördüğü bilgiyle tutarlı bir olası oyun: tahta, atılanlar ve kendi eli
## aynı kalır; göremediği kartlar karıştırılıp diğer ellere (aynı sayıda) ve desteye dağıtılır.
## Bot aramasında kullanılır; botun gerçek kartları ya da destenin sırasını bilmesini önler.
func determinized(rng: RandomNumberGenerator) -> GameMatch:
	var copy := GameMatch.new(settings, rng)
	copy.board = board.clone()
	copy.seats = seats
	copy.bots = bots
	copy.bot_level = bot_level
	copy.current = current
	copy.last_discard_seat = last_discard_seat
	copy.top_discard_value = top_discard_value
	copy.round_number = round_number
	copy.finishers = finishers.duplicate()
	copy.finish_rounds = finish_rounds.duplicate()
	copy._discard_pile = _discard_pile.duplicate()
	var unseen := unseen_cards()
	copy._shuffle(unseen)
	for index: int in range(hands.size()):
		var hand: Array[Card] = []
		if index == current:
			hand.assign(hands[index])
		else:
			for _card: Card in hands[index]:
				hand.append(unseen.pop_back())
		copy.hands.append(hand)
	copy._draw_pile = unseen
	return copy


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
	_record_finishers()
	return captured


func discard(card_index: int) -> void:
	_discard_pile.append(current_hand().pop_at(card_index))
	last_discard_seat = current_seat()
	top_discard_value = Card.NO_VALUE


## İlk bitiren koltuk; henüz kimse bitirmediyse NO_WINNER.
func winner() -> int:
	return NO_WINNER if finishers.is_empty() else finishers[0]


## Sırayı bitirmemiş sıradaki oyuncuya verir; sıra ilk oyuncuya döndükçe tur artar.
func next_turn() -> void:
	for _step: int in range(seats.size()):
		current = (current + 1) % seats.size()
		if current == 0:
			round_number += 1
		if is_playing(current):
			return


## Yeni bitiren oyuncuları kaydeder; ellerindeki kartlar atılanların altına konur.
func _record_finishers() -> void:
	for index: int in range(seats.size()):
		var seat := seats[index]
		if finishers.has(seat) or not board.has_finished(seat):
			continue
		finishers.append(seat)
		finish_rounds.append(round_number)
		var hand: Array[Card] = hands[index]
		for card: Card in hand:
			_discard_pile.push_front(card)
		hand.clear()


func _new_hand() -> Array[Card]:
	var hand: Array[Card] = []
	return hand


func _build_deck() -> void:
	for entry: Dictionary in settings.deck:
		var type: Card.Type = Card.TYPE_BY_NAME[entry["type"]]
		for _i: int in range(int(entry[GameSettings.KEY_CARD_COUNT])):
			_draw_pile.append(Card.new(type, int(entry["value"])))
	_shuffle(_draw_pile)


## Desteden bir kart çeker. Arayüz karıştırmayı önceden göstermediyse (bot denemeleri, testler)
## boş deste burada yenilenir.
func _draw_into(hand: Array[Card]) -> void:
	reshuffle_if_empty()
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
	if finish_rounds.size() != finishers.size() or not is_playing(current):
		return false
	if not finishers.all(func(seat: int) -> bool: return board.has_finished(seat)):
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
