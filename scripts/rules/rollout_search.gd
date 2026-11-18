class_name RolloutSearch
extends RefCounted
## Aday hamleleri olası oyunlarda ileri oynatarak karşılaştırır (Monte Carlo arama). Her denemede
## botun göremediği kartlar yeniden karıştırılıp dağıtılır (GameMatch.determinized); bot gerçek
## kartları ya da destenin sırasını bilmez. Aday oynandıktan sonra bütün oyuncular birer kez
## (bot da bir kez daha) policy botuyla oynar ve tahta değerlendirilir.
## Adaylar aynı deneme sırasında aynı tohumu kullanır; fark şanstan değil hamleden gelir.

var _policy: Bot
var _evaluator: BotEvaluator


func _init(policy: Bot, evaluator: BotEvaluator) -> void:
	_policy = policy
	_evaluator = evaluator


## Adaylardan ortalama sonucu en iyi olanı döner.
func best_move(game: GameMatch, candidates: Array[Move], rollouts: int, base_seed: int) -> Move:
	var best: Move = candidates[0]
	var best_total := -INF
	for move: Move in candidates:
		var total := 0.0
		for index: int in range(rollouts):
			total += _rollout(game, move, base_seed + index)
		if total > best_total:
			best_total = total
			best = move
	return best


## Hamleyi olası bir oyunda oynar, bir tur ileri gider ve sıradaki oyuncu için puanlar.
func _rollout(game: GameMatch, move: Move, seed_value: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sim := game.determinized(rng)
	var seat := sim.current_seat()
	sim.play(move)
	for _turn: int in range(sim.seats.size()):
		if sim.winner() != GameMatch.NO_WINNER:
			break
		sim.next_turn()
		sim.begin_turn()
		_play_turn(sim)
	return _evaluator.evaluate(sim.board, seat)


func _play_turn(sim: GameMatch) -> void:
	var move := _policy.choose_move(sim)
	if move == null:
		sim.discard(_policy.choose_discard(sim.current_hand()))
	else:
		sim.play(move)
