class_name SettingsOverlay
extends Button
## Ayarlar katmanı: ses açma/kapama anahtarı, oyun hızı ve dil seçimi. Dışına ya da Tamam'a
## dokununca kapanır. Hız düğmeleri GameSpeed.Level, dil düğmeleri Localization.SUPPORTED
## sırasıyla kurulur; her dil kendi adıyla yazılır. Reklamları Kaldır düğmesi ürün alınınca
## gizlenir. Gizlilik Seçenekleri düğmesi yalnızca reklam rızasının gerektiği bölgelerde (ör. AB)
## görünür.

const LANGUAGE_KEY_PREFIX := "LANG_"

@onready var _sound_switch: ToggleSwitch = %SoundSwitch
@onready var _speeds: HBoxContainer = %Speeds
@onready var _languages: GridContainer = %Languages
@onready var _privacy_button: Button = %PrivacyButton


func _ready() -> void:
	pressed.connect(hide)
	(%SettingsOkButton as Button).pressed.connect(hide)
	_privacy_button.pressed.connect(Ads.show_privacy_options)
	visibility_changed.connect(_on_visibility_changed)
	_sound_switch.set_pressed_no_signal(Sound.is_enabled())
	_sound_switch.toggled.connect(Sound.set_enabled)
	_build_speed_buttons()
	_build_language_buttons()
	hide()


func _build_speed_buttons() -> void:
	var group := ButtonGroup.new()
	var current := GameSpeed.current()
	for level: GameSpeed.Level in GameSpeed.Level.values():
		var button := ChoiceButtons.add(
			_speeds, GameSpeed.level_key(level), group, level == current
		)
		button.pressed.connect(GameSpeed.select.bind(level))


func _build_language_buttons() -> void:
	var group := ButtonGroup.new()
	var current := Localization.current()
	for locale: String in Localization.SUPPORTED:
		var text := LANGUAGE_KEY_PREFIX + locale.to_upper()
		var button := ChoiceButtons.add(_languages, text, group, locale == current)
		button.pressed.connect(Localization.select.bind(locale))


func _on_visibility_changed() -> void:
	if visible:
		_privacy_button.visible = Ads.is_privacy_options_required()
