class_name PileView
extends Control
## Deste ya da atılanlar yığını. İkisi de altında kart sayısını gösterir; deste kapalı
## kartları, atılanlar en üstteki kartı gösterir; yığın boşsa kesik çizgili bir yer belirir.

enum Kind { DECK, DISCARD }

## Destede alttaki kartın kayması; yığın gibi görünmesini sağlar.
const STACK_OFFSET := Vector2(3, -3)
const CAPTION_VARIATION := &"PileLabel"
const DASH := 6.0
const LINE_WIDTH := 1.5

@export var kind := Kind.DECK

var _under := CardFace.new()
var _top := CardFace.new()
var _caption := Label.new()


func _ready() -> void:
	add_child(_under)
	add_child(_top)
	_caption.theme_type_variation = CAPTION_VARIATION
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_caption)
	if kind == Kind.DISCARD:
		_under.hide()
		_top.hide()
	resized.connect(_arrange)
	_arrange()


## Yığındaki kart sayısını gösterir. Destede kapalı kartlar da sayıya göre belirir;
## atılanların üstteki kartı set_top ile gösterilir.
func set_count(count: int) -> void:
	_caption.text = tr("PILE_COUNT") % count
	if kind == Kind.DECK:
		_top.visible = count > 0
		_under.visible = count > 1
	queue_redraw()


## Atılanların en üstündeki kartı, köşesinde atanın renginde rozetle ve (jokerse) seçilen
## sayıyla gösterir; null yığını boşaltır.
func set_top(card: Card, settings: GameSettings, badge: Color, chosen: int) -> void:
	_top.visible = card != null
	if _top.visible:
		_top.show_card(card, settings)
		_top.show_chosen(chosen)
		_top.set_badge(badge)
	queue_redraw()


## Yığındaki kartın ekrandaki yeri; uçan kartlar buradan kalkar ya da buraya iner.
func card_rect() -> Rect2:
	var area := _card_area()
	return Rect2(global_position + area.position, area.size)


func _card_area() -> Rect2:
	var caption_height := _caption.get_combined_minimum_size().y
	var card := CardFace.fit_size(size.x, size.y - caption_height)
	var top := (size.y - caption_height - card.y) / 2.0
	return Rect2(Vector2((size.x - card.x) / 2.0, top), card)


func _arrange() -> void:
	var area := _card_area()
	_top.position = area.position
	_top.size = area.size
	_under.position = area.position + STACK_OFFSET
	_under.size = area.size
	_caption.position = Vector2(0.0, area.end.y)
	_caption.size = Vector2(size.x, _caption.get_combined_minimum_size().y)
	queue_redraw()


func _draw() -> void:
	if _top.visible:
		return
	var area := _card_area()
	var color := _caption.get_theme_color(ThemeKeys.FONT_COLOR)
	var corners: Array[Vector2] = [
		area.position,
		Vector2(area.end.x, area.position.y),
		area.end,
		Vector2(area.position.x, area.end.y),
	]
	for index: int in range(corners.size()):
		var next := corners[(index + 1) % corners.size()]
		draw_dashed_line(corners[index], next, color, LINE_WIDTH, DASH)
