class_name SettingsOverlay
extends Button
## Ayarlar katmanı: ses açma/kapama anahtarı, oyun hızı ve dil seçimi. Dışına ya da Tamam'a
## dokununca kapanır. Hız düğmeleri GameSpeed.Level, dil düğmeleri Localization.SUPPORTED
## sırasıyla kurulur; her dil kendi adıyla yazılır.

const LANGUAGE_KEY_PREFIX := "LANG_"
const CHOICE_BUTTON_TYPE := &"ChoiceButton"

@onready var _sound_switch: ToggleSwitch = %SoundSwitch
@onready var _speeds: HBoxContainer = %Speeds
@onready var _languages: GridContainer = %Languages


func _ready() -> void:
	pressed.connect(hide)
	(%SettingsOkButton as Button).pressed.connect(hide)
	_sound_switch.set_pressed_no_signal(Sound.is_enabled())
	_sound_switch.toggled.connect(Sound.set_enabled)
	_build_speed_buttons()
	_build_language_buttons()
	hide()


func _build_speed_buttons() -> void:
	var group := ButtonGroup.new()
	var current := GameSpeed.current()
	for level: GameSpeed.Level in GameSpeed.Level.values():
		var button := _add_choice(_speeds, GameSpeed.level_key(level), group, level == current)
		button.pressed.connect(GameSpeed.select.bind(level))


func _build_language_buttons() -> void:
	var group := ButtonGroup.new()
	var current := Localization.current()
	for locale: String in Localization.SUPPORTED:
		var text := LANGUAGE_KEY_PREFIX + locale.to_upper()
		var button := _add_choice(_languages, text, group, locale == current)
		button.pressed.connect(Localization.select.bind(locale))


## Gruptaki seçeneklerden biri olan, basılı kalan düğmeyi kapa ekler.
func _add_choice(box: Container, text: String, group: ButtonGroup, selected: bool) -> Button:
	var button := Button.new()
	button.theme_type_variation = CHOICE_BUTTON_TYPE
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.set_pressed_no_signal(selected)
	box.add_child(button)
	return button
