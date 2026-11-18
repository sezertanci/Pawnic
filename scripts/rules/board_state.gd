class_name BoardState
extends RefCounted
## Taşların konumunu tutar, bir kartla yapılabilecek hamleleri bulur ve hamleyi uygular.
## Konum, tahtadaki karenin BoardLayout indeksidir; başlangıç alanındaki taşın konumu BASE'tir.

const BASE := -1
const BASE_NAME := "base"
## Kayıt sözlüğünün anahtarları.
const KEY_OWNERS := "owners"
const KEY_POSITIONS := "positions"

var settings: GameSettings
var layout: BoardLayout
## Her taşın sahibinin koltuk numarası (0 üst, 1 sağ, 2 alt, 3 sol).
var owners: Array[int] = []
var positions: Array[int] = []


func _init(game_settings: GameSettings) -> void:
	settings = game_settings
	layout = game_settings.board_layout


func add_pawns(seat: int, count: int) -> void:
	for _i: int in range(count):
		owners.append(seat)
		positions.append(BASE)


func clone() -> BoardState:
	var copy := BoardState.new(settings)
	copy.owners = owners.duplicate()
	copy.positions = positions.duplicate()
	return copy


## Konumlar kare adlarıyla yazılır; tahtada kare eklenip çıkarılsa da kayıt bozulmaz.
func to_dict() -> Dictionary:
	var names: Array[String] = []
	for position: int in positions:
		names.append(BASE_NAME if position == BASE else layout.names[position])
	return {KEY_OWNERS: owners, KEY_POSITIONS: names}


## Kayıttaki taş konumlarını yükler; sayılar uyuşmazsa, kare bilinmiyorsa ya da sahip
## tahtadaki bir koltuk değilse false döner.
func load_dict(data: Dictionary) -> bool:
	var saved_owners: Variant = data.get(KEY_OWNERS)
	var saved_positions: Variant = data.get(KEY_POSITIONS)
	if not saved_owners is Array or not saved_positions is Array:
		return false
	if (saved_owners as Array).size() != (saved_positions as Array).size():
		return false
	if not (saved_owners as Array).all(_is_seat):
		return false
	var loaded: Array[int] = []
	for square_name: Variant in saved_positions:
		var position := BASE if square_name == BASE_NAME else layout.index_of(str(square_name))
		if position == BoardLayout.NO_SQUARE and square_name != BASE_NAME:
			return false
		loaded.append(position)
	owners.clear()
	for owner: Variant in saved_owners:
		owners.append(int(owner))
	positions = loaded
	return true


func _is_seat(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	return int(value) >= 0 and int(value) < layout.seat_count()


## Taş herkesin kullandığı bir karede mi (başlangıç alanında ya da ev yolunda değil).
func is_on_track(pawn: int) -> bool:
	return positions[pawn] != BASE and not layout.is_private(positions[pawn])


func is_home(pawn: int) -> bool:
	return positions[pawn] == layout.homes[owners[pawn]]


func pawns_on_square(square: int) -> Array[int]:
	var result: Array[int] = []
	for pawn: int in range(positions.size()):
		if positions[pawn] == square:
			result.append(pawn)
	return result


func has_finished(seat: int) -> bool:
	for pawn: int in _pawns_of(seat):
		if not is_home(pawn):
			return false
	return true


func moves_for_card(seat: int, card: Card, card_index: int) -> Array[Move]:
	var moves: Array[Move] = []
	match card.type:
		Card.Type.FORWARD:
			_add_forward_moves(moves, seat, card.value, card_index)
		Card.Type.JOKER:
			for value: int in range(1, settings.joker_max + 1):
				_add_forward_moves(moves, seat, value, card_index)
		Card.Type.EXIT:
			_add_exit_moves(moves, seat, 0, card_index)
		Card.Type.BACK:
			_add_back_moves(moves, seat, card.value, card_index)
		Card.Type.SEND_BACK:
			_add_send_back_moves(moves, seat, card.value, card_index)
		Card.Type.SWAP:
			_add_swap_moves(moves, seat, card_index)
		Card.Type.SHORTCUT:
			_add_shortcut_moves(moves, seat, card_index)
	return moves


## Hamlede taşın sırayla bastığı kareler (hız bonusu dahil, başladığı kare hariç).
## Çıkışta yalnızca varış karesi döner. Kısayolda taş yol üstünden kayacağı için varışa kadarki
## bütün kareler döner. Yer değiştirmede oynanan taşın hedef taşa giden yolu (swap_path) döner.
## apply'dan önce çağrılır.
func move_path(move: Move) -> Array[int]:
	var path: Array[int] = []
	match move.action:
		Move.Action.FORWARD:
			var seat := owners[move.pawn]
			_find_path(seat, positions[move.pawn], move.value, true, move.destination, path)
			path.append_array(_boost_path(move.pawn, move.destination))
		Move.Action.BACK, Move.Action.SEND_BACK:
			path = _trace(positions[move.pawn], move.destination, _prev_square)
		Move.Action.SWAP:
			path = swap_path(move.pawn, positions[move.pawn], positions[move.target])
		Move.Action.EXIT:
			path.append(move.destination)
		Move.Action.SHORTCUT:
			var step := layout.default_step.bind(owners[move.pawn])
			path = _trace(positions[move.pawn], move.destination, step)
	return path


## Yer değiştirmede pawn'ın from'dan to'ya gittiği kareler (from hariç). Taş kendi başlangıcına
## göre yön seçer: to kendi eve uzaklığına göre ilerideyse ileri, gerideyse geri gider; yolun
## uzun ya da kısa olmasına bakılmaz.
func swap_path(pawn: int, from: int, to: int) -> Array[int]:
	var seat := owners[pawn]
	var ahead := layout.home_distance(seat, to) < layout.home_distance(seat, from)
	return _trace(from, to, _next_square if ahead else _prev_square)


## square'den goal'e step ile (kareyi alıp gidilecek kareyi veren) gidilen kareler, square
## hariç. goal'e ulaşılamıyorsa boş döner.
func _trace(square: int, goal: int, step: Callable) -> Array[int]:
	var path: Array[int] = []
	# Döngü sınırı: tahtadaki kare sayısından uzun yol olamaz.
	for _step: int in range(layout.square_count()):
		if square == goal or square == BoardLayout.NO_SQUARE:
			break
		square = step.call(square)
		path.append(square)
	if square != goal:
		path.clear()
	return path


func _next_square(square: int) -> int:
	return layout.next_squares[square]


func _prev_square(square: int) -> int:
	return layout.prev_squares[square]


## Hamleyi uygular ve başlangıca dönen taş sayısını verir.
func apply(move: Move) -> int:
	match move.action:
		Move.Action.EXIT:
			positions[move.pawn] = move.destination
		Move.Action.FORWARD:
			return _advance(move.pawn, move.destination)
		Move.Action.BACK, Move.Action.SEND_BACK, Move.Action.SHORTCUT:
			return _place(move.pawn, move.destination)
		Move.Action.SWAP:
			_swap(move.pawn, move.target)
	return 0


func _pawns_of(seat: int) -> Array[int]:
	var result: Array[int] = []
	for pawn: int in range(owners.size()):
		if owners[pawn] == seat:
			result.append(pawn)
	return result


## Ortak ve güvenli olmayan karede kendi taşının üstüne gelinemez. mover, henüz yerinden
## kalkmamış hareket eden taştır; kendi eski karesine dönebilir.
func _can_land(seat: int, square: int, mover := Move.NO_PAWN) -> bool:
	if layout.is_private(square) or layout.safe[square]:
		return true
	for other: int in pawns_on_square(square):
		if owners[other] == seat and other != mover:
			return false
	return true


func _is_attackable(pawn: int) -> bool:
	return is_on_track(pawn) and not layout.safe[positions[pawn]]


## Taşın bu karttan sonra varabileceği kareler. Yol ayrımlarında her yol ayrı bir hedeftir.
func _forward_targets(seat: int, square: int, steps: int) -> Array[int]:
	var targets: Array[int] = []
	_walk(seat, square, steps, true, targets)
	return targets


func _walk(seat: int, square: int, steps: int, first_step: bool, targets: Array[int]) -> void:
	if steps == 0:
		if not targets.has(square):
			targets.append(square)
		return
	for next: int in layout.steps_from(square, seat, first_step):
		_walk(seat, next, steps - 1, false, targets)


## Kareden steps adımda hedefe giden ilk yolu path'e yazar; bulursa true döner.
func _find_path(
	seat: int, square: int, steps: int, first_step: bool, target: int, path: Array[int]
) -> bool:
	if steps == 0:
		return square == target
	for next: int in layout.steps_from(square, seat, first_step):
		path.append(next)
		if _find_path(seat, next, steps - 1, false, target, path):
			return true
		path.pop_back()
	return false


func _back_target(pawn: int, steps: int) -> int:
	return _back_path(owners[pawn], positions[pawn], steps).back()


## Kareden geriye sayarken basılan kareler (başlangıç karesi dahil, ilk eleman);
## sahibinin çıkış karesinde durur.
func _back_path(seat: int, square: int, steps: int) -> Array[int]:
	var path: Array[int] = [square]
	var start := layout.starts[seat]
	for _i: int in range(steps):
		var previous := layout.prev_squares[path.back()]
		if path.back() == start or previous == BoardLayout.NO_SQUARE:
			break
		path.append(previous)
	return path


func _add_exit_moves(moves: Array[Move], seat: int, value: int, card_index: int) -> void:
	var start := layout.starts[seat]
	for pawn: int in _pawns_of(seat):
		if positions[pawn] == BASE:
			moves.append(Move.new(card_index, Move.Action.EXIT, pawn, value, Move.NO_PAWN, start))


func _add_forward_moves(moves: Array[Move], seat: int, value: int, card_index: int) -> void:
	if value == settings.exit_value:
		_add_exit_moves(moves, seat, value, card_index)
	for pawn: int in _pawns_of(seat):
		if positions[pawn] == BASE:
			continue
		for target: int in _forward_targets(seat, positions[pawn], value):
			if _can_land(seat, target):
				moves.append(
					Move.new(card_index, Move.Action.FORWARD, pawn, value, Move.NO_PAWN, target)
				)


func _add_back_moves(moves: Array[Move], seat: int, value: int, card_index: int) -> void:
	for pawn: int in _pawns_of(seat):
		_add_backward_move(moves, Move.Action.BACK, pawn, value, card_index)


func _add_send_back_moves(moves: Array[Move], seat: int, value: int, card_index: int) -> void:
	for pawn: int in range(owners.size()):
		if owners[pawn] != seat and _is_attackable(pawn):
			_add_backward_move(moves, Move.Action.SEND_BACK, pawn, value, card_index)


## Geri giden taş çıkış karesinde değilse ve kendi renginden bir taşın üstüne düşmüyorsa hamle olur.
func _add_backward_move(
	moves: Array[Move], action: Move.Action, pawn: int, value: int, card_index: int
) -> void:
	if not is_on_track(pawn) or positions[pawn] == layout.starts[owners[pawn]]:
		return
	var target := _back_target(pawn, value)
	if _can_land(owners[pawn], target):
		moves.append(Move.new(card_index, action, pawn, value, Move.NO_PAWN, target))


## Kendi taşı güvenli karede de olabilir; rakip taş güvenli karedeyse korunur.
func _add_swap_moves(moves: Array[Move], seat: int, card_index: int) -> void:
	for own: int in _pawns_of(seat):
		if not is_on_track(own):
			continue
		for rival: int in range(owners.size()):
			if owners[rival] != seat and _is_attackable(rival):
				moves.append(Move.new(card_index, Move.Action.SWAP, own, 0, rival))


func _add_shortcut_moves(moves: Array[Move], seat: int, card_index: int) -> void:
	var shortcut := layout.shortcuts[seat]
	if shortcut == BoardLayout.NO_SQUARE or not _can_land(seat, shortcut):
		return
	for pawn: int in _pawns_of(seat):
		if is_on_track(pawn) and positions[pawn] != shortcut:
			moves.append(
				Move.new(card_index, Move.Action.SHORTCUT, pawn, 0, Move.NO_PAWN, shortcut)
			)


## Hız karesine konan taş, seçim sorulmadan hız bonusu kadar daha ilerler.
func _advance(pawn: int, target: int) -> int:
	var boost := _boost_path(pawn, target)
	var captured := _place(pawn, target)
	if not boost.is_empty():
		captured += _place(pawn, boost.back())
	return captured


## Hız karesinden sonra gidilecek kareler: artı değerde ileri, eksi değerde geri (çıkış karesinde
## durur). Bonus kullanılamıyorsa boş.
func _boost_path(pawn: int, square: int) -> Array[int]:
	var seat := owners[pawn]
	var path: Array[int] = []
	var value := layout.speed[square]
	if layout.is_private(square) or value == 0:
		return path
	if value < 0:
		path = _back_path(seat, square, -value)
		path.pop_front()
	else:
		var boosted := square
		for _i: int in range(value):
			boosted = layout.default_step(boosted, seat)
			if boosted == BoardLayout.NO_SQUARE:
				path.clear()
				return path
			path.append(boosted)
	if not path.is_empty() and not _can_land(seat, path.back(), pawn):
		path.clear()
	return path


func _place(pawn: int, square: int) -> int:
	positions[pawn] = square
	if not _is_attackable(pawn):
		return 0
	var captured := 0
	for other: int in pawns_on_square(square):
		if owners[other] != owners[pawn]:
			positions[other] = BASE
			captured += 1
	return captured


func _swap(own: int, rival: int) -> void:
	var own_square := positions[own]
	positions[own] = positions[rival]
	positions[rival] = own_square
