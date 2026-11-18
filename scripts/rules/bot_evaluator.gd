class_name BotEvaluator
extends RefCounted
## Botun tahtayı puanlaması: bir oyuncunun taşlarının değerinden en iyi rakibinkini çıkarır.
## Tehdit okuyan seviyelerde (CardOdds verilirse) ortak yoldaki her taşın değeri, sıradaki turda
## çarpılma olasılığı kadar düşürülür: kendi taşları danger_weight, rakip taşları attack_weight
## ağırlığıyla. Tehdit okumayan seviyelerde puan yalnızca taşların ilerlemesidir.

var _settings: GameSettings
var _layout: BoardLayout
var _odds: CardOdds


## odds null ise tehdit hesaplanmaz.
func _init(settings: GameSettings, odds: CardOdds = null) -> void:
	_settings = settings
	_layout = settings.board_layout
	_odds = odds


## Kendi taşlarının değerinden en iyi rakibin değerini (ağırlıklı) çıkarır.
func evaluate(board: BoardState, seat: int) -> float:
	var safety := _survival_chances(board)
	var own := 0.0
	var rivals: Dictionary[int, float] = {}
	for pawn: int in range(board.positions.size()):
		var value := pawn_value(board, pawn)
		var owner := board.owners[pawn]
		if owner == seat:
			own += value * (1.0 - _settings.bot_danger_weight * _danger(board, pawn, safety))
		else:
			var kept := value * (1.0 - _settings.bot_attack_weight * _danger(board, pawn, safety))
			rivals[owner] = rivals.get(owner, 0.0) + kept
	var best_rival := 0.0
	for total: float in rivals.values():
		best_rival = maxf(best_rival, total)
	return own - _settings.bot_rival_weight * best_rival


## Taşın değeri, çıkış karesinden bu yana evine ne kadar yaklaştığıdır.
func pawn_value(board: BoardState, pawn: int) -> float:
	var square := board.positions[pawn]
	if square == BoardState.BASE:
		return 0.0
	if board.is_home(pawn):
		return _settings.bot_home_value
	var seat := board.owners[pawn]
	var gained := (
		_layout.home_distance(seat, _layout.starts[seat]) - _layout.home_distance(seat, square)
	)
	var score := _settings.bot_track_base + gained
	if _layout.is_private(square):
		score += _settings.bot_lane_bonus
	return score


## Taşın sıradaki turda başka renkten bir taşça çarpılma olasılığı.
func _danger(board: BoardState, pawn: int, safety: Dictionary[int, float]) -> float:
	if safety.is_empty() or not board.is_on_track(pawn):
		return 0.0
	var square := board.positions[pawn]
	if _layout.safe[square]:
		return 0.0
	var survival := 1.0
	for attacker: int in range(_layout.seat_count()):
		if attacker != board.owners[pawn]:
			survival *= safety.get(_key(square, attacker), 1.0)
	return 1.0 - survival


## (kare, saldıran renk) → o rengin hiçbir taşının sıradaki turda o kareye gelememe olasılığı.
## Taş, kartıyla tam o kareye ya da vardığı hız karesinden kayarak o kareye gelebilir.
func _survival_chances(board: BoardState) -> Dictionary[int, float]:
	var safety: Dictionary[int, float] = {}
	if _odds == null:
		return safety
	for pawn: int in range(board.positions.size()):
		if not board.is_on_track(pawn):
			continue
		var seat := board.owners[pawn]
		var square := board.positions[pawn]
		for distance: int in range(1, _odds.max_distance() + 1):
			square = _layout.default_step(square, seat)
			if square == BoardLayout.NO_SQUARE or _layout.is_private(square):
				break
			var miss := 1.0 - _odds.reach_chance(distance)
			_reduce(safety, _key(square, seat), miss)
			var boosted := _boosted(square, seat)
			if boosted != BoardLayout.NO_SQUARE:
				_reduce(safety, _key(boosted, seat), miss)
	return safety


## Hız karesinden ileri kayılan kare; geri kayma ve ev yoluna giriş hesaba katılmaz.
func _boosted(square: int, seat: int) -> int:
	var boost := _layout.speed[square]
	if boost <= 0:
		return BoardLayout.NO_SQUARE
	for _i: int in range(boost):
		square = _layout.default_step(square, seat)
		if square == BoardLayout.NO_SQUARE or _layout.is_private(square):
			return BoardLayout.NO_SQUARE
	return square


func _key(square: int, seat: int) -> int:
	return square * _layout.seat_count() + seat


static func _reduce(chances: Dictionary[int, float], key: int, factor: float) -> void:
	chances[key] = chances.get(key, 1.0) * factor
