class_name MatchResult
extends RefCounted
## Oyunun sonucu: oyunun bitip bitmediği, oyun sonu sıralaması ve bitirenlerin turu.

const NO_ROUND := GameMatch.NO_INDEX


## Tek oyuncu kaldığında ya da bütün insan oyuncular bitirdiğinde oyun biter.
static func is_over(game: GameMatch) -> bool:
	return game.finishers.size() >= game.seats.size() - 1 or game.playing_human_count() == 0


## Oyun sonu sıralaması: önce bitirenler bitirme sırasıyla, sonra kalanlar tahtadaki
## ilerlemelerine göre (botun taş değeri hesabıyla).
static func ranking(game: GameMatch) -> Array[int]:
	var progress: Dictionary[int, float] = {}
	for seat: int in game.seats:
		if not game.finishers.has(seat):
			progress[seat] = 0.0
	var evaluator := BotEvaluator.new(game.settings)
	var board := game.board
	for pawn: int in range(board.positions.size()):
		var owner := board.owners[pawn]
		if progress.has(owner):
			progress[owner] += evaluator.pawn_value(board, pawn)
	var rest: Array[int] = []
	rest.assign(progress.keys())
	rest.sort_custom(func(a: int, b: int) -> bool: return progress[a] > progress[b])
	var result := game.finishers.duplicate()
	result.append_array(rest)
	return result


## Koltuğun bitirdiği tur; bitirmediyse NO_ROUND.
static func finish_round(game: GameMatch, seat: int) -> int:
	var index := game.finishers.find(seat)
	return NO_ROUND if index == GameMatch.NO_INDEX else game.finish_rounds[index]
