class_name LobbyPanel
extends VBoxContainer
## Ağ lobisindeki oyuncular ve renk seçimi (host ve katılan oyuncu ekranı). Oyuncu sayısı kadar
## koltuk satırı vardır: dolu satırda taşın rengi ve renk adı, kendi satırında "Sen", hostun
## satırında "Kurucu" yazar; boş satırda oyun başlayınca oturacak bot soluk yazılır. Altındaki
## renk düğmelerinden başkasının aldığı renkler kapalıdır.

## Oyuncu boş bir renk seçti.
signal color_chosen(color: int)

## Hostun lobideki sırası.
const HOST_INDEX := 0
## Koltuk satırındaki taş görselinin boyutu (piksel).
const PAWN_SIZE := Vector2(40, 48)
const NAME_TYPE := &"PanelLabel"
const TAG_TYPE := &"PanelHint"

var _color_buttons: Dictionary[int, Button] = {}

@onready var _seats: VBoxContainer = %Seats
@onready var _colors: HBoxContainer = %Colors


func _ready() -> void:
	var group := ButtonGroup.new()
	for color: int in PlayerColor.colors():
		var button := ChoiceButtons.add_color(_colors, color, group, false)
		button.pressed.connect(color_chosen.emit.bind(color))
		_color_buttons[color] = button


## Lobinin son hâlini gösterir.
func show_lobby(info: LobbyInfo) -> void:
	for child: Node in _seats.get_children():
		child.queue_free()
	for index: int in range(info.seat_count):
		_seats.add_child(_seat_row(info, index))
	for color: int in _color_buttons:
		var button := _color_buttons[color]
		var own := info.colors[info.own] == color
		button.set_pressed_no_signal(own)
		button.disabled = not own and info.colors.has(color)


func _seat_row(info: LobbyInfo, index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	if index >= info.colors.size():
		row.add_child(_label("SEAT_BOT", TAG_TYPE))
		return row
	var pawn := PawnIcon.new()
	pawn.color = info.colors[index]
	pawn.custom_minimum_size = PAWN_SIZE
	row.add_child(pawn)
	var name_label := _label(Skins.current.seat_name_keys[pawn.color], NAME_TYPE)
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(name_label)
	if index == info.own:
		row.add_child(_label("SEAT_YOU", TAG_TYPE))
	elif index == HOST_INDEX:
		row.add_child(_label("SEAT_HOST", TAG_TYPE))
	return row


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
