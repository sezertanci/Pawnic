class_name MatchView
extends RefCounted
## Bir oyuncunun (izleyicinin) gördüğü oyun; ağ oyununda istemcinin kopyasıdır. Destenin sırası
## ve başkalarının elleri yoktur, yalnızca sayıları vardır. Host oyun başında ve yeniden
## bağlanmada görünümün tamamını gönderir; istemci sonra hakemin olaylarını apply() ile kendi
## kopyasına uygular. Olay kopyayla uyuşmazsa apply() false döner ve istemci görünümü yeniden ister.

## Mesaj sözlüğünün yalnızca görünümde geçen anahtarları; diğerleri kayıtla ortaktır.
const KEY_VIEWER := "viewer"
const KEY_TOP_DISCARD := "top_discard"
const KEY_DRAW_COUNT := "draw_count"
const KEY_DISCARD_COUNT := "discard_count"
const KEY_HAND_SIZES := "hand_sizes"
const KEY_HAND := "hand"

var settings: GameSettings
var board: BoardState
## Görünümün sahibi olan koltuk.
var viewer_seat := BoardLayout.NO_SEAT
var seats: Array[int] = []
var bots: Array[bool] = []
var colors: Array[int] = []
var current := 0
var starter := 0
var round_number := 1
## Hakemin saatindeki geçen süre; her sıranın başında güncellenir.
var elapsed := 0.0
var finishers: Array[int] = []
var finish_rounds: Array[int] = []
var last_discard_seat := BoardLayout.NO_SEAT
## Atılanların en üstündeki kart; atılan kart yoksa null.
var top_discard: Card
var top_discard_value := Card.NO_VALUE
var draw_count := 0
var discard_count := 0
## Her oyuncunun elindeki kart sayısı, sıra düzeninde.
var hand_sizes: Array[int] = []
## İzleyicinin eli; izleyici oyuncu değilse boş.
var hand: Array[Card] = []


func _init(game_settings: GameSettings) -> void:
	settings = game_settings
	board = BoardState.new(game_settings)


## Oyunun izleyiciye görünen hâli (host, istemciye göndereceği görünümü bununla kurar).
static func of(game: GameMatch, viewer: int) -> MatchView:
	var view := MatchView.new(game.settings)
	view.board = game.board.clone()
	view.viewer_seat = viewer
	view.seats = game.seats.duplicate()
	view.bots = game.bots.duplicate()
	view.colors = game.colors.duplicate()
	view.starter = game.starter
	view.current = game.current
	view.round_number = game.round_number
	view.elapsed = game.elapsed
	view.finishers = game.finishers.duplicate()
	view.finish_rounds = game.finish_rounds.duplicate()
	view.last_discard_seat = game.last_discard_seat
	view.top_discard = game.top_discard()
	view.top_discard_value = game.top_discard_value
	view.draw_count = game.draw_count()
	view.discard_count = game.discard_count()
	for player_hand: Array in game.hands:
		view.hand_sizes.append(player_hand.size())
	var index := game.seats.find(viewer)
	if index != GameMatch.NO_INDEX:
		view.hand.assign(game.hands[index])
	return view


func to_dict() -> Dictionary:
	return {
		GameMatch.KEY_BOARD: board.to_dict(),
		KEY_VIEWER: viewer_seat,
		GameMatch.KEY_SEATS: seats,
		GameMatch.KEY_BOTS: bots,
		GameMatch.KEY_COLORS: colors,
		GameMatch.KEY_STARTER: starter,
		GameMatch.KEY_CURRENT: current,
		GameMatch.KEY_ROUND: round_number,
		GameMatch.KEY_ELAPSED: elapsed,
		GameMatch.KEY_FINISHERS: finishers,
		GameMatch.KEY_FINISH_ROUNDS: finish_rounds,
		GameMatch.KEY_LAST_DISCARD_SEAT: last_discard_seat,
		KEY_TOP_DISCARD: {} if top_discard == null else top_discard.to_dict(),
		GameMatch.KEY_TOP_DISCARD_VALUE: top_discard_value,
		KEY_DRAW_COUNT: draw_count,
		KEY_DISCARD_COUNT: discard_count,
		KEY_HAND_SIZES: hand_sizes,
		KEY_HAND: Card.write_all(hand),
	}


## Mesajdan okur; bir alan bozuksa ya da görünüm kendi içinde tutarsızsa null döner.
static func from_dict(game_settings: GameSettings, data: Dictionary) -> MatchView:
	var view := MatchView.new(game_settings)
	if not view.board.load_dict(MessageData.read_dict(data, GameMatch.KEY_BOARD)):
		return null
	if not view._read_numbers(data) or not view._read_lists(data) or not view._read_cards(data):
		return null
	return view if view._is_consistent() else null


## Olayı kopyaya uygular; olay kopyayla uyuşmuyorsa (bilinmeyen koltuk, elde olmayan kart,
## yasal olmayan hamle) false döner. Uyuşmazlıkta kopya bozulmuş olabilir; yeniden istenmelidir.
func apply(event: MatchEvent) -> bool:
	match event.kind:
		MatchEvent.Kind.RESHUFFLED:
			draw_count += discard_count
			discard_count = 0
			top_discard = null
		MatchEvent.Kind.TURN_STARTED:
			return _start_turn(event)
		MatchEvent.Kind.MOVE_PLAYED:
			return _play(event)
		MatchEvent.Kind.DISCARDED:
			return _take_card(event)
		MatchEvent.Kind.REWARD_ENDED:
			return _take_reward(event)
	return true


func current_seat() -> int:
	return seats[current]


## Sıra izleyicideyse true.
func is_viewer_turn() -> bool:
	return viewer_seat != BoardLayout.NO_SEAT and current_seat() == viewer_seat


## İzleyicinin elindeki kartlarla sıradaki koltuğun yapabileceği hamleler; sıra izleyicide
## değilse anlamsızdır.
func legal_moves() -> Array[Move]:
	return board.moves_for_hand(current_seat(), hand)


func _start_turn(event: MatchEvent) -> bool:
	var index := seats.find(event.seat)
	if index == GameMatch.NO_INDEX:
		return false
	current = index
	round_number = event.round_number
	elapsed = event.elapsed
	if not event.drew:
		return true
	if draw_count == 0 or (event.seat == viewer_seat and event.card == null):
		return false
	draw_count -= 1
	hand_sizes[index] += 1
	if event.seat == viewer_seat:
		hand.append(event.card)
	return true


## Ödül kartı izleyicinin elindeki kartın yerine geçer; kartlar desteyle yer değiştirdiği için
## sayılar değişmez.
func _take_reward(event: MatchEvent) -> bool:
	if event.card_index == MatchEvent.NO_CARD or event.seat != viewer_seat:
		return seats.has(event.seat)
	if event.card == null or event.card_index < 0 or event.card_index >= hand.size():
		return false
	hand[event.card_index] = event.card
	return true


## Hamle, önce kopyanın tahtasında yasal olup olmadığına bakılarak uygulanır.
func _play(event: MatchEvent) -> bool:
	if not seats.has(event.seat) or event.card == null or event.move == null:
		return false
	var legal := board.moves_for_card(event.seat, event.card, event.card_index)
	if not legal.any(func(move: Move) -> bool: return move.equals(event.move)):
		return false
	if not _take_card(event):
		return false
	board.apply(event.move)
	if event.card.type == Card.Type.JOKER:
		top_discard_value = event.move.value
	_record_finishers()
	return true


## Oyuncunun elinden kartı alıp atılanların üstüne koyar.
func _take_card(event: MatchEvent) -> bool:
	var index := seats.find(event.seat)
	if index == GameMatch.NO_INDEX or event.card == null:
		return false
	if event.card_index < 0 or event.card_index >= hand_sizes[index]:
		return false
	if event.seat == viewer_seat:
		if hand[event.card_index].to_dict() != event.card.to_dict():
			return false
		hand.remove_at(event.card_index)
	hand_sizes[index] -= 1
	discard_count += 1
	top_discard = event.card
	last_discard_seat = event.seat
	top_discard_value = Card.NO_VALUE
	return true


## GameMatch ile aynı kural: yeni bitirenin eli atılanların altına gider.
func _record_finishers() -> void:
	for index: int in range(seats.size()):
		var seat := seats[index]
		if finishers.has(seat) or not board.has_finished(seat):
			continue
		finishers.append(seat)
		finish_rounds.append(round_number)
		discard_count += hand_sizes[index]
		hand_sizes[index] = 0
		if seat == viewer_seat:
			hand.clear()


func _read_numbers(data: Dictionary) -> bool:
	viewer_seat = MessageData.read_int(data, KEY_VIEWER)
	starter = MessageData.read_int(data, GameMatch.KEY_STARTER)
	current = MessageData.read_int(data, GameMatch.KEY_CURRENT)
	round_number = MessageData.read_int(data, GameMatch.KEY_ROUND)
	last_discard_seat = MessageData.read_int(data, GameMatch.KEY_LAST_DISCARD_SEAT)
	top_discard_value = MessageData.read_int(data, GameMatch.KEY_TOP_DISCARD_VALUE)
	draw_count = MessageData.read_int(data, KEY_DRAW_COUNT)
	discard_count = MessageData.read_int(data, KEY_DISCARD_COUNT)
	var numbers: Array[int] = [
		viewer_seat, starter, current, round_number, last_discard_seat, top_discard_value
	]
	var clock: Variant = data.get(GameMatch.KEY_ELAPSED)
	if numbers.has(MessageData.INVALID) or draw_count < 0 or discard_count < 0:
		return false
	if not MessageData.is_number(clock):
		return false
	elapsed = float(clock)
	return true


func _read_lists(data: Dictionary) -> bool:
	var lists: Array = []
	for key: String in [
		GameMatch.KEY_SEATS,
		GameMatch.KEY_COLORS,
		GameMatch.KEY_FINISHERS,
		GameMatch.KEY_FINISH_ROUNDS,
		KEY_HAND_SIZES,
	]:
		var list: Variant = MessageData.read_ints(data, key)
		if list == null:
			return false
		lists.append(list)
	seats = lists[0]
	colors = lists[1]
	finishers = lists[2]
	finish_rounds = lists[3]
	hand_sizes = lists[4]
	var flags: Variant = data.get(GameMatch.KEY_BOTS)
	if (
		not flags is Array
		or not (flags as Array).all(func(flag: Variant) -> bool: return flag is bool)
	):
		return false
	bots.assign(flags)
	return true


func _read_cards(data: Dictionary) -> bool:
	var top := MessageData.read_dict(data, KEY_TOP_DISCARD)
	if not top.is_empty():
		top_discard = Card.from_dict(top)
		if top_discard == null:
			return false
	return Card.read_all(data.get(KEY_HAND), hand)


## Koltuklar oyuncu sayısının sırasında, sayılar birbirini tutuyor ve izleyicinin eli el
## sayısıyla aynıysa true.
func _is_consistent() -> bool:
	var count := seats.size()
	if not GameMatch.SEAT_ORDER.has(count) or seats != _expected_seats(count):
		return false
	if bots.size() != count or hand_sizes.size() != count or hand_sizes.any(_is_negative):
		return false
	if current < 0 or current >= count or starter < 0 or starter >= count:
		return false
	return _are_seats_valid() and _is_hand_valid()


## Bitirenler ve son atan oyundaki koltuklar, renk eşlemesi geçerliyse true.
func _are_seats_valid() -> bool:
	if finish_rounds.size() != finishers.size() or not finishers.all(_is_seat):
		return false
	if last_discard_seat != BoardLayout.NO_SEAT and not _is_seat(last_discard_seat):
		return false
	return SeatColors.is_valid(colors, settings.board_layout.homes.size())


## İzleyicinin eli el sayısıyla aynıysa (izleyici oyuncu değilse boşsa) true.
func _is_hand_valid() -> bool:
	var index := seats.find(viewer_seat)
	return hand.size() == (0 if index == GameMatch.NO_INDEX else hand_sizes[index])


func _expected_seats(count: int) -> Array[int]:
	var expected: Array[int] = []
	expected.assign(GameMatch.SEAT_ORDER[count])
	return expected


func _is_seat(seat: int) -> bool:
	return seats.has(seat)


func _is_negative(value: int) -> bool:
	return value < 0
