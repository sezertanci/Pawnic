class_name Move
extends RefCounted
## Elde tutulan bir kartla yapılabilecek tek bir hamle.

enum Action { EXIT, FORWARD, BACK, SEND_BACK, SWAP, SHORTCUT }

const NO_PAWN := -1
## Mesaj sözlüğünün anahtarları.
const KEY_ACTION := "action"
const KEY_PAWN := "pawn"
const KEY_TARGET := "target"
const KEY_DESTINATION := "destination"

var card_index: int
var action: Action
## Hareket eden taş. Geri yollamada rakip taştır.
var pawn: int
var value: int
## Yer değiştirmede karşı taraftaki rakip taş.
var target: int
## Taşın varacağı kare (BoardLayout indeksi); yer değiştirmede kullanılmaz.
var destination: int


func _init(
	move_card: int,
	move_action: Action,
	move_pawn: int,
	move_value := 0,
	move_target := NO_PAWN,
	move_destination := BoardLayout.NO_SQUARE
) -> void:
	card_index = move_card
	action = move_action
	pawn = move_pawn
	value = move_value
	target = move_target
	destination = move_destination


## Ağ mesajı için sözlüğe çevirir.
func to_dict() -> Dictionary:
	return {
		MessageData.KEY_CARD_INDEX: card_index,
		KEY_ACTION: action,
		KEY_PAWN: pawn,
		Card.KEY_VALUE: value,
		KEY_TARGET: target,
		KEY_DESTINATION: destination,
	}


## Mesajdan okur; alan eksikse ya da sayı değilse null döner. Hamlenin yasallığını okuyan taraf
## (hakem, legal_moves ile) ayrıca denetler.
static func from_dict(data: Dictionary) -> Move:
	var fields: Array[int] = []
	var keys: Array[String] = [
		MessageData.KEY_CARD_INDEX,
		KEY_ACTION,
		KEY_PAWN,
		Card.KEY_VALUE,
		KEY_TARGET,
		KEY_DESTINATION
	]
	for key: String in keys:
		var field := MessageData.read_int(data, key)
		if field == MessageData.INVALID:
			return null
		fields.append(field)
	if not MessageData.is_enum_value(fields[1], Action.values()):
		return null
	return Move.new(fields[0], fields[1] as Action, fields[2], fields[3], fields[4], fields[5])


## Bütün alanları aynıysa true (ağdan ya da arayüzden gelen hamle yasal hamlelerle karşılaştırılır).
func equals(other: Move) -> bool:
	if other == null:
		return false
	return (
		card_index == other.card_index
		and action == other.action
		and pawn == other.pawn
		and value == other.value
		and target == other.target
		and destination == other.destination
	)
