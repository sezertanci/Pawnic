class_name Bot
extends RefCounted
## Basit bot: her yasal hamleyi tahtanın kopyasında dener, durumu en çok iyileştireni seçer.


static func choose_move(game: GameMatch) -> Move:
	var best: Move = null
	var best_score := -INF
	for move: Move in game.legal_moves():
		var board := game.board.clone()
		board.apply(move)
		var score := evaluate(board, game.current_seat())
		if score > best_score:
			best_score = score
			best = move
	return best


## Oynanabilir kart yoksa önce geri kartlarını atar, yoksa ilk kartı.
static func choose_discard(hand: Array[Card]) -> int:
	for index: int in range(hand.size()):
		if hand[index].type == Card.Type.BACK:
			return index
	return 0


## Kendi taşlarının değerinden en iyi rakibin değerini (ağırlıklı) çıkarır.
static func evaluate(board: BoardState, seat: int) -> float:
	var own := 0.0
	var rivals: Dictionary[int, float] = {}
	for pawn: int in range(board.positions.size()):
		var value := pawn_value(board, pawn)
		var owner := board.owners[pawn]
		if owner == seat:
			own += value
		else:
			rivals[owner] = rivals.get(owner, 0.0) + value
	var best_rival := 0.0
	for total: float in rivals.values():
		best_rival = maxf(best_rival, total)
	return own - board.settings.bot_rival_weight * best_rival


## Taşın değeri, çıkış karesinden bu yana evine ne kadar yaklaştığıdır.
static func pawn_value(board: BoardState, pawn: int) -> float:
	var settings := board.settings
	var square := board.positions[pawn]
	if square == BoardState.BASE:
		return 0.0
	if board.is_home(pawn):
		return settings.bot_home_value
	var seat := board.owners[pawn]
	var layout := board.layout
	var gained := (
		layout.home_distance(seat, layout.starts[seat]) - layout.home_distance(seat, square)
	)
	var score := settings.bot_track_base + gained
	if layout.is_private(square):
		score += settings.bot_lane_bonus
	return score
