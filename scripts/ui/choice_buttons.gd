class_name ChoiceButtons
extends RefCounted
## Seçeneklerden yalnızca biri basılı kalan düğme grupları (ayarlar ve yeni oyun ekranı).

const BUTTON_TYPE := &"ChoiceButton"


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
