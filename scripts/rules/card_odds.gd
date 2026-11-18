class_name CardOdds
extends RefCounted
## Bir oyuncunun göremediği kartların (deste ve rakiplerin elleri) dağılımı. Botun kartların
## sırasını değil yalnızca hangi kartların görünmediğini bilmesi, desteden, atılanlardan ve kendi
## elinden herkesin çıkarabileceği bilgidir.
## Rakibin sırasında elinde hand_size + 1 kart olduğu sayılır.

## Çeşit bulunamadığında _kind_index bunu döner.
const NOT_FOUND := -1

## Görünmeyen kart çeşitleri ve her birinin çekilme olasılığı.
var cards: Array[Card] = []
var chances: Array[float] = []
## Rakibin sırada elindeki kart sayısı.
var draws := 0
## Uzaklık → rakibin elinde taşını tam o kadar ileri götürecek kart bulunma olasılığı.
var _reach: Array[float] = []


func _init(settings: GameSettings, unseen: Array[Card]) -> void:
	draws = settings.hand_size + 1
	var counts: Array[int] = []
	for card: Card in unseen:
		var index := _kind_index(card)
		if index == NOT_FOUND:
			cards.append(card)
			counts.append(0)
			index = cards.size() - 1
		counts[index] += 1
	for count: int in counts:
		chances.append(float(count) / unseen.size())
	_build_reach(settings)


## Rakibin elinde taşını tam distance kare ileri götürecek bir kart bulunma olasılığı.
func reach_chance(distance: int) -> float:
	return _reach[distance] if distance < _reach.size() else 0.0


## İleri gidilebilecek en uzun mesafe.
func max_distance() -> int:
	return _reach.size() - 1


func _kind_index(card: Card) -> int:
	for index: int in range(cards.size()):
		if cards[index].type == card.type and cards[index].value == card.value:
			return index
	return NOT_FOUND


## İleri kartı kendi sayısı kadar, joker 1'den joker_max'a kadar her sayıda gider.
func _build_reach(settings: GameSettings) -> void:
	var single: Array[float] = [0.0]
	for index: int in range(cards.size()):
		var card := cards[index]
		var reach := 0
		if card.type == Card.Type.FORWARD:
			reach = card.value
		elif card.type == Card.Type.JOKER:
			reach = settings.joker_max
		if reach >= single.size():
			single.resize(reach + 1)
		for distance: int in range(1, reach + 1):
			if card.type == Card.Type.JOKER or distance == reach:
				single[distance] += chances[index]
	for distance: int in range(single.size()):
		_reach.append(1.0 - pow(1.0 - single[distance], draws))
