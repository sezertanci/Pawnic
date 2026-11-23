class_name BoardCard
extends Button
## Yeni oyun ekranında bir tahtanın kartı: solda tahtanın küçük görseli, sağda adı ve durum satırı.
## Durum satırı seçili kartta "Seçili", kilitli kartta video simgesiyle "Aç" yazar. Çerçeve ve
## yazı renkleri arayüz temasındaki BoardCard türünden gelir.

const THEME_TYPE := &"BoardCard"
const STYLE := &"normal"
const SELECTED_COLOR := &"selected_color"
const UNLOCK_COLOR := &"unlock_color"
const FONT_COLOR := &"font_color"
const SEPARATION := &"separation"
const NAME_TYPE := &"PanelLabel"
const SELECTED_KEY := "SELECTED"
const UNLOCK_KEY := "UNLOCK"
const VIDEO_ICON := preload("res://assets/images/icon_video.svg")
const MIN_HEIGHT := 150.0
const THUMB_SIZE := Vector2(110.0, 110.0)
const ICON_SIZE := Vector2(30.0, 30.0)
const GAP := 12

var locked := false:
	set(value):
		locked = value
		_refresh()

var _row := HBoxContainer.new()
var _status := Label.new()
var _icon: TextureRect


func _init(entry: BoardEntry, group: ButtonGroup) -> void:
	theme_type_variation = THEME_TYPE
	toggle_mode = true
	button_group = group
	# Dokunuş üstteki kaydırma alanına da geçsin; yoksa parmak kartın üstündeyken liste kaymaz.
	mouse_filter = MOUSE_FILTER_PASS
	size_flags_horizontal = SIZE_EXPAND_FILL
	custom_minimum_size.y = MIN_HEIGHT
	_row.mouse_filter = MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(SEPARATION, GAP)
	_row.add_child(Nodes.picture(load(entry.preview_path) as Texture2D, THUMB_SIZE))
	_row.add_child(_texts(entry.name_key))
	add_child(_row)
	toggled.connect(_on_toggled)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		Nodes.fit_inside(_row, get_theme_stylebox(STYLE))
		_refresh()


## Tahtanın adı ve altında durum satırı (simge ve yazı).
func _texts(name_key: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.theme_type_variation = NAME_TYPE
	title.text = name_key
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var status_row := HBoxContainer.new()
	status_row.mouse_filter = MOUSE_FILTER_IGNORE
	_icon = Nodes.picture(VIDEO_ICON, ICON_SIZE)
	status_row.add_child(_icon)
	_status.theme_type_variation = NAME_TYPE
	status_row.add_child(_status)
	column.add_child(status_row)
	return column


func _on_toggled(_pressed: bool) -> void:
	_refresh()


## Kilitli kartta "Aç", seçili kartta "Seçili" yazar; ikisi de değilse durum satırı boştur.
func _refresh() -> void:
	_icon.visible = locked
	_status.text = UNLOCK_KEY if locked else (SELECTED_KEY if button_pressed else "")
	var color := get_theme_color(UNLOCK_COLOR if locked else SELECTED_COLOR)
	_status.add_theme_color_override(FONT_COLOR, color)
	_icon.modulate = color
