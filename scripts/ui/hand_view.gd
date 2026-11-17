class_name HandView
extends Control
## Oyuncunun elindeki kartları hafif yelpaze biçiminde düğme olarak dizer.

signal card_pressed(card_index: int)

const CARD_VARIATION := &"CardButton"
const DISABLED_FONT := &"font_disabled_color"
const DIM_ALPHA := 0.45
const CARD_GAP := 8.0
## Yelpazede yan yana kartların açı farkı (derece) ve kenara doğru kartların inişi (piksel).
const FAN_DEGREES := 3.0
const FAN_DROP := 4.0

## Elde aynı anda bulunabilecek en çok kart; kart boyu buna göre sabit kalır.
var slot_count := 1


func _ready() -> void:
	resized.connect(_arrange)


## Kartları gösterir; playable içinde false olan kartlar basılamaz.
func show_cards(hand: Array[Card], settings: GameSettings, playable: Array[bool]) -> void:
	clear()
	for index: int in range(hand.size()):
		var button := Button.new()
		button.theme_type_variation = CARD_VARIATION
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not playable[index]
		_add_face(button, hand[index], settings)
		button.pressed.connect(card_pressed.emit.bind(index))
		add_child(button)
	_arrange()


## Kartın yazısını ya da (varsa) sembolünü düğmeye koyar.
func _add_face(button: Button, card: Card, settings: GameSettings) -> void:
	var symbol := CardSymbol.new()
	symbol.show_card(card, settings)
	if button.disabled:
		symbol.modulate.a = button.get_theme_color(DISABLED_FONT).a
	button.add_child(symbol)
	if not symbol.visible:
		button.text = CardFace.text_for(card, settings.exit_value)


## Oynanabilir kart yokken bütün kartların köşesine atılacağını gösteren çarpı koyar.
func mark_discard() -> void:
	for button: Button in get_children():
		button.add_child(DiscardMark.new())


## Seçili kartı öne çıkarır, diğerlerini soluklaştırır.
func highlight(card_index: int) -> void:
	for button: Button in get_children():
		button.modulate.a = 1.0 if button.get_index() == card_index else DIM_ALPHA


## Joker kartında seçilen sayıyı gösterir; Card.NO_VALUE verilirse kaldırır.
func show_chosen(card_index: int, value: int) -> void:
	for child: Node in get_child(card_index).get_children():
		if child is CardSymbol:
			(child as CardSymbol).show_chosen(value)


## Bütün kartlardan seçilmiş joker sayısını kaldırır.
func clear_chosen() -> void:
	for button: Button in get_children():
		show_chosen(button.get_index(), Card.NO_VALUE)


## Kart uçarken: o kartı gizler ve eldeki kartlara dokunulmasını kapatır.
func hold(card_index: int) -> void:
	for button: Button in get_children():
		button.mouse_filter = MOUSE_FILTER_IGNORE
	(get_child(card_index) as Control).modulate.a = 0.0


func clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func card_size() -> Vector2:
	var slots := maxi(slot_count, 1)
	var width := (size.x - CARD_GAP * (slots - 1)) / slots
	width = minf(width, (size.y - FAN_DROP * slots) / CardFace.ASPECT)
	return Vector2(width, width * CardFace.ASPECT)


## Kartın döndürülmemiş haliyle ekrandaki yeri.
func card_rect(card_index: int) -> Rect2:
	var button := get_child(card_index) as Control
	return Rect2(global_position + button.position, button.size)


func _arrange() -> void:
	var count := get_child_count()
	var card := card_size()
	var left := (size.x - card.x * count - CARD_GAP * (count - 1)) / 2.0
	var middle := (count - 1) / 2.0
	for button: Button in get_children():
		var offset := button.get_index() - middle
		button.size = card
		button.position = Vector2(left + button.get_index() * (card.x + CARD_GAP), 0.0)
		button.position.y = absf(offset) * FAN_DROP
		button.pivot_offset = card / 2.0
		button.rotation = deg_to_rad(offset * FAN_DEGREES)
