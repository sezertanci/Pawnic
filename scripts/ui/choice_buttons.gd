class_name ChoiceButtons
extends RefCounted
## Seçeneklerden yalnızca biri basılı kalan düğme grupları (ayarlar, yeni oyun ekranı ve lobi).

const BUTTON_TYPE := &"ChoiceButton"
## Renk düğmelerindeki taş görselinin genişliği (piksel).
const COLOR_ICON_WIDTH := 28
const ICON_MAX_WIDTH := &"icon_max_width"


## Gruptaki seçeneklerden biri olan, basılı kalan düğmeyi kaba ekler.
static func add(box: Container, text: String, group: ButtonGroup, selected: bool) -> Button:
	var button := Button.new()
	button.theme_type_variation = BUTTON_TYPE
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_pressed_no_signal(selected)
	box.add_child(button)
	return button


## Rengin adı ve taşı olan seçenek düğmesini kaba ekler.
static func add_color(box: Container, color: int, group: ButtonGroup, selected: bool) -> Button:
	var skin := Skins.current
	var button := add(box, skin.seat_name_keys[color], group, selected)
	button.icon = skin.pawn_textures[color]
	button.add_theme_constant_override(ICON_MAX_WIDTH, COLOR_ICON_WIDTH)
	return button
