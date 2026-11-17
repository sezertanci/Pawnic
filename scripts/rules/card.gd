class_name Card
extends RefCounted
## Destedeki tek bir kart: türü ve (varsa) sayı değeri.

enum Type { FORWARD, BACK, EXIT, SWAP, SEND_BACK, SHORTCUT, JOKER }

## Jokerde henüz sayı seçilmediğini gösterir.
const NO_VALUE := 0

const TYPE_BY_NAME := {
	"forward": Type.FORWARD,
	"back": Type.BACK,
	"exit": Type.EXIT,
	"swap": Type.SWAP,
	"send_back": Type.SEND_BACK,
	"shortcut": Type.SHORTCUT,
	"joker": Type.JOKER,
}
const LABEL_KEYS := {
	Type.FORWARD: "CARD_FORWARD",
	Type.BACK: "CARD_BACK",
	Type.EXIT: "CARD_EXIT",
	Type.SWAP: "CARD_SWAP",
	Type.SEND_BACK: "CARD_SEND_BACK",
	Type.SHORTCUT: "CARD_SHORTCUT",
	Type.JOKER: "CARD_JOKER",
}
## İleri ve geri kartlarının etiketi (+5, -5) yeterli olduğu için açıklaması yoktur.
const DESC_KEYS := {
	Type.EXIT: "DESC_EXIT",
	Type.SWAP: "DESC_SWAP",
	Type.SEND_BACK: "DESC_SEND_BACK",
	Type.SHORTCUT: "DESC_SHORTCUT",
	Type.JOKER: "DESC_JOKER",
}
const EXIT_DESC_KEY := "DESC_FORWARD_EXIT"
## Etiketinde sayı gösterilen kart türleri.
const VALUED_TYPES: Array[Type] = [Type.FORWARD, Type.BACK, Type.SEND_BACK]

var type: Type
var value: int


func _init(card_type: Type, card_value: int) -> void:
	type = card_type
	value = card_value


## Kayıt için sözlüğe çevirir.
func to_dict() -> Dictionary:
	return {"type": TYPE_BY_NAME.find_key(type), "value": value}


## Kayıttan okur; tanınmayan bir tür varsa null döner.
static func from_dict(data: Dictionary) -> Card:
	var name: String = data.get("type", "")
	if not TYPE_BY_NAME.has(name):
		return null
	return Card.new(TYPE_BY_NAME[name], int(data.get("value", 0)))


func label() -> String:
	var text := tr(LABEL_KEYS[type])
	return text % value if VALUED_TYPES.has(type) else text


func description(exit_value: int) -> String:
	if type == Type.FORWARD and value == exit_value:
		return tr(EXIT_DESC_KEY)
	return tr(DESC_KEYS[type]) if DESC_KEYS.has(type) else ""
