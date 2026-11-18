class_name Bot
extends RefCounted
## Bot oyuncu. Her yasal hamleyi tahtanın kopyasında dener ve seviyesine göre seçer: kolay
## seviyeler sık sık rastgele oynar, zor seviyeler rakiplerin karşılığını ve taşların çarpılma
## olasılığını da hesaplar, en zor seviye en iyi adayları olası oyunlarda ileri oynatır.
## Bot yalnızca herkesin görebildiği bilgiyi kullanır.
## Seviyelerin ayarları GameSettings.bot_profiles içindedir.

enum Level { EASY, MEDIUM, HARD, EXPERT }

var _settings: GameSettings
var _profile: BotProfile
var _rng: RandomNumberGenerator


func _init(profile: BotProfile, settings: GameSettings, rng: RandomNumberGenerator) -> void:
	_settings = settings
	_profile = profile
	_rng = rng


## Sıradaki oyuncunun hamlesini seçer; oynanabilir kart yoksa null döner.
func choose_move(game: GameMatch) -> Move:
	var legal := game.legal_moves()
	if legal.is_empty():
		return null
	if _rng.randf() < _profile.random_chance:
		return legal[_rng.randi_range(0, legal.size() - 1)]
	var odds := CardOdds.new(_settings, game.unseen_cards())
	var threat_odds := odds if _profile.read_threats else null
	var evaluator := BotEvaluator.new(_settings, threat_odds, game.finishers.duplicate())
	var ranked := _ranked(game, legal, odds, evaluator)
	if _profile.rollouts == 0 or ranked.size() == 1:
		return ranked[0]
	var policy := Bot.new(_settings.bot_rollout_policy, _settings, _rng)
	var search := RolloutSearch.new(policy, evaluator)
	var shortlist := ranked.slice(0, _profile.shortlist)
	return search.best_move(game, shortlist, _profile.rollouts, _rng.randi())


## Oynanabilir kart yoksa atılacak kart: önce geri kartları, yoksa ilk kart.
func choose_discard(hand: Array[Card]) -> int:
	for index: int in range(hand.size()):
		if hand[index].type == Card.Type.BACK:
			return index
	return 0


## Yasal hamleler, puanı yüksekten düşüğe.
func _ranked(
	game: GameMatch, legal: Array[Move], odds: CardOdds, evaluator: BotEvaluator
) -> Array[Move]:
	var forecast: RivalForecast = null
	if _profile.reply_rivals > 0:
		forecast = RivalForecast.new(odds, evaluator)
	var rivals := _rivals(game)
	var seat := game.current_seat()
	var scores: Dictionary[Move, float] = {}
	for move: Move in legal:
		var board := game.board.clone()
		board.apply(move)
		if forecast == null:
			scores[move] = evaluator.evaluate(board, seat)
		else:
			scores[move] = forecast.expected_score(board, seat, rivals)
	var ranked := legal.duplicate()
	ranked.sort_custom(func(a: Move, b: Move) -> bool: return scores[a] > scores[b])
	return ranked


## Karşılığı hesaplanacak rakipler, sıradakinden başlayarak; bitirmiş oyuncular atlanır.
func _rivals(game: GameMatch) -> Array[int]:
	var rivals: Array[int] = []
	for step: int in range(1, game.seats.size()):
		var index := (game.current + step) % game.seats.size()
		if rivals.size() < _profile.reply_rivals and game.is_playing(index):
			rivals.append(game.seats[index])
	return rivals
