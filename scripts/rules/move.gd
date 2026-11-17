class_name Move
extends RefCounted
## Elde tutulan bir kartla yapılabilecek tek bir hamle.

enum Action { EXIT, FORWARD, BACK, SEND_BACK, SWAP, SHORTCUT }

const NO_PAWN := -1

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
