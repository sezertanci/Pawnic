class_name RewardDealer
extends RefCounted
## Ödüllü reklamı izleyen oyuncuya yerden (deste ve atılanlar) gösterilecek kartları seçer. Yerdeki
## her farklı kart, oyuncunun bu sırada onunla yapabileceği en iyi hamleye göre puanlanır; hamlesi
## olmayan kartlar en sona kalır. Eşit puanda önce destenin, sonra atılanların üstündeki gelir.

var _settings: GameSettings
var _evaluator: BotEvaluator


func _init(settings: GameSettings) -> void:
	_settings = settings
	_evaluator = BotEvaluator.new(settings)


## Sıradaki oyuncu için en işe yarar kartlar, en fazla reward_offer_count tane.
func offers(game: GameMatch) -> Array[Card]:
	var candidates := _distinct(game.reward_pool())
	var seat := game.current_seat()
	var scores: Dictionary[Card, float] = {}
	var order: Dictionary[Card, int] = {}
	for index: int in range(candidates.size()):
		scores[candidates[index]] = _best_score(game.board, seat, candidates[index])
		order[candidates[index]] = index
	candidates.sort_custom(
		func(a: Card, b: Card) -> bool:
			if scores[a] != scores[b]:
				return scores[a] > scores[b]
			return order[a] < order[b]
	)
	return candidates.slice(0, _settings.reward_offer_count)


## Yığındaki türü ve değeri farklı kartlar, yığının sonundan başlayarak.
func _distinct(pile: Array[Card]) -> Array[Card]:
	var result: Array[Card] = []
	for index: int in range(pile.size() - 1, -1, -1):
		var card := pile[index]
		if not result.any(func(other: Card) -> bool: return other.same_as(card)):
			result.append(card)
	return result


## Kartla yapılabilecek en iyi hamleden sonraki tahta puanı; hamle yoksa -INF.
func _best_score(board: BoardState, seat: int, card: Card) -> float:
	var best := -INF
	for move: Move in board.moves_for_card(seat, card, 0):
		var copy := board.clone()
		copy.apply(move)
		best = maxf(best, _evaluator.evaluate(copy, seat))
	return best
