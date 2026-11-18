class_name RivalForecast
extends RefCounted
## Rakiplerin bir sonraki hamlesini tahmin eder. Rakibin eli bilinmediği için kartlar görünmeyen
## kartların oranlarıyla (CardOdds) dağılmış sayılır. Rakip sırasında elindeki kartlardan kendisi
## için en iyisini oynar; bunun bot için beklenen sonucu hesaplanır.

var _odds: CardOdds
var _evaluator: BotEvaluator


func _init(odds: CardOdds, evaluator: BotEvaluator) -> void:
	_odds = odds
	_evaluator = evaluator


## Verilen rakipler (her biri ayrı ayrı) karşılık verdikten sonra tahtanın seat için beklenen
## değeri. Her rakibin bota verdiği beklenen kayıp, tahtanın şimdiki değerinden düşülür.
func expected_score(board: BoardState, seat: int, rivals: Array[int]) -> float:
	var current := _evaluator.evaluate(board, seat)
	var score := current
	for rival: int in rivals:
		score -= current - _expected_after_reply(board, seat, rival)
	return score


## Rakip, çektiği kartlardan kendisi için en iyisini oynar. Kart çeşitleri rakip için iyiden
## kötüye dizilir; bir çeşidin en iyi kart olma olasılığı, elindeki kartlardan hiçbirinin daha
## iyi bir çeşit olmaması ile en az birinin bu çeşit olmasıdır.
func _expected_after_reply(board: BoardState, seat: int, rival: int) -> float:
	var rival_scores: Array[float] = []
	var own_scores: Array[float] = []
	for card: Card in _odds.cards:
		_add_best_reply(board, seat, rival, card, rival_scores, own_scores)
	var order: Array = range(_odds.cards.size())
	order.sort_custom(func(a: int, b: int) -> bool: return rival_scores[a] > rival_scores[b])
	var covered := 0.0
	var expected := 0.0
	for index: int in order:
		var before := pow(1.0 - covered, _odds.draws)
		covered = minf(covered + _odds.chances[index], 1.0)
		expected += (before - pow(1.0 - covered, _odds.draws)) * own_scores[index]
	return expected


## Rakibin bu kartla yapabileceği en iyi hamleden sonra tahtanın rakip ve bot için değeri.
## Kartla hamle yoksa tahta değişmez.
func _add_best_reply(
	board: BoardState,
	seat: int,
	rival: int,
	card: Card,
	rival_scores: Array[float],
	own_scores: Array[float]
) -> void:
	var best_board := board
	var best_score := _evaluator.evaluate(board, rival)
	var first := true
	for move: Move in board.moves_for_card(rival, card, 0):
		var after := board.clone()
		after.apply(move)
		var score := _evaluator.evaluate(after, rival)
		if first or score > best_score:
			first = false
			best_score = score
			best_board = after
	rival_scores.append(best_score)
	own_scores.append(_evaluator.evaluate(best_board, seat))
