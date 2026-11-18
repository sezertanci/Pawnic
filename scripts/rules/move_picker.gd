class_name MovePicker
extends RefCounted
## Oyuncunun hamleyi adım adım seçmesini yönetir: kart, (joker ise) değer, taş, (gerekirse) hedef
## taş ya da (yol ayrımında) varış karesi.
## Arayüzden bağımsızdır; her adımda hangi seçeneklerin açık olduğunu söyler.

enum Stage { CARD, VALUE, PAWN, TARGET, DESTINATION }

var stage := Stage.CARD

var _legal: Array[Move] = []
var _candidates: Array[Move] = []
## Kart (joker'de değer) seçildikten sonraki hamleler; taş seçimi değiştirilirken buradan başlanır.
var _pawn_moves: Array[Move] = []


## Yeni sıranın yasal hamleleriyle seçimi baştan başlatır.
func reset(legal: Array[Move]) -> void:
	_legal = legal
	cancel()


## Seçimi iptal edip kart seçimine döner.
func cancel() -> void:
	_candidates.clear()
	_pawn_moves.clear()
	stage = Stage.CARD


## Oynanabilir kart yoksa oyuncu bir kart atmak zorundadır.
func must_discard() -> bool:
	return _legal.is_empty()


func is_card_playable(card_index: int) -> bool:
	return _legal.any(func(move: Move) -> bool: return move.card_index == card_index)


func pick_card(card_index: int) -> void:
	_candidates.assign(
		_legal.filter(func(move: Move) -> bool: return move.card_index == card_index)
	)
	_pawn_moves.assign(_candidates)
	stage = Stage.VALUE if values().size() > 1 else Stage.PAWN


## Seçili kartın oynanabileceği sayı değerleri, küçükten büyüğe.
func values() -> Array[int]:
	var result: Array[int] = []
	for move: Move in _candidates:
		if not result.has(move.value):
			result.append(move.value)
	result.sort()
	return result


func pick_value(value: int) -> void:
	_candidates.assign(_candidates.filter(func(move: Move) -> bool: return move.value == value))
	_pawn_moves.assign(_candidates)
	stage = Stage.PAWN


## Seçili kartla (joker'de seçili değerle) hâlâ yapılabilecek hamleler; yol önizlemesi içindir.
## Kart ya da joker değeri seçilmeden boş döner.
func candidates() -> Array[Move]:
	var result: Array[Move] = []
	if stage != Stage.CARD and stage != Stage.VALUE:
		result.assign(_candidates)
	return result


## Bu adımda dokunulabilecek taşlar. Hedef ya da varış seçilirken seçimi değiştirmek için
## aynı kartla oynanabilecek diğer kendi taşları da dokunulabilir.
func selectable_pawns() -> Array[int]:
	var result: Array[int] = []
	if stage == Stage.TARGET:
		for move: Move in _candidates:
			_append_unique(result, move.target)
	if stage == Stage.TARGET or stage == Stage.DESTINATION:
		for pawn: int in _other_pawns():
			_append_unique(result, pawn)
		return result
	for move: Move in _candidates:
		_append_unique(result, move.pawn)
	return result


## Seçili taş dışında, seçili kartla oynanabilecek kendi taşları.
func _other_pawns() -> Array[int]:
	var result: Array[int] = []
	var selected := selected_pawn()
	for move: Move in _pawn_moves:
		if move.pawn != selected:
			_append_unique(result, move.pawn)
	return result


static func _append_unique(values: Array[int], value: int) -> void:
	if not values.has(value):
		values.append(value)


## Hedef taş ya da varış karesi seçilirken hamlesi yapılacak taş; başka aşamada NO_PAWN.
func selected_pawn() -> int:
	if stage != Stage.TARGET and stage != Stage.DESTINATION:
		return Move.NO_PAWN
	return _candidates[0].pawn


## Taşı seçer. Hamle tamamlandıysa onu, başka bir seçim gerekiyorsa null döner.
func pick_pawn(pawn: int) -> Move:
	if stage == Stage.TARGET:
		for move: Move in _candidates:
			if move.target == pawn:
				return move
	if _other_pawns().has(pawn):
		_candidates.assign(_pawn_moves)
	elif stage != Stage.PAWN:
		return null
	_candidates.assign(_candidates.filter(func(move: Move) -> bool: return move.pawn == pawn))
	if _candidates.is_empty():
		return null
	if _candidates[0].target != Move.NO_PAWN:
		stage = Stage.TARGET
		return null
	if _candidates.size() > 1:
		stage = Stage.DESTINATION
		return null
	return _candidates[0]


## Varış karesi seçiminde dokunulabilecek kareler.
func selectable_squares() -> Array[int]:
	var result: Array[int] = []
	if stage != Stage.DESTINATION:
		return result
	for move: Move in _candidates:
		result.append(move.destination)
	return result


## Varış karesini seçer; kare seçeneklerde yoksa null döner.
func pick_destination(square: int) -> Move:
	for move: Move in _candidates:
		if move.destination == square:
			return move
	return null
