class_name MovePicker
extends RefCounted
## Oyuncunun hamleyi adım adım seçmesini yönetir: kart, (joker ise) değer, taş, (gerekirse) hedef
## taş ya da (yol ayrımında) varış karesi.
## Arayüzden bağımsızdır; her adımda hangi seçeneklerin açık olduğunu söyler.

enum Stage { CARD, VALUE, PAWN, TARGET, DESTINATION }

var stage := Stage.CARD

var _legal: Array[Move] = []
var _candidates: Array[Move] = []


## Yeni sıranın yasal hamleleriyle seçimi baştan başlatır.
func reset(legal: Array[Move]) -> void:
	_legal = legal
	cancel()


## Seçimi iptal edip kart seçimine döner.
func cancel() -> void:
	_candidates.clear()
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
	stage = Stage.PAWN


## Bu adımda dokunulabilecek taşlar.
func selectable_pawns() -> Array[int]:
	var result: Array[int] = []
	for move: Move in _candidates:
		var pawn := move.target if stage == Stage.TARGET else move.pawn
		if not result.has(pawn):
			result.append(pawn)
	return result


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
