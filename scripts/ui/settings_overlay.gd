class_name SettingsOverlay
extends Button
## Ayarlar katmanı: ses efekti, müzik ve taş ışığı açma/kapama anahtarları, ışık biçimi, oyun
## hızı ve dil seçimi. Dışına ya da Tamam'a dokununca kapanır. Işık biçimi düğmeleri
## PawnGlow.Mode, hız düğmeleri GameSpeed.Level, dil düğmeleri Localization.SUPPORTED sırasıyla
## kurulur; her dil kendi adıyla yazılır. Işık kapalıyken biçim düğmeleri pasif kalır.
## Reklamları Kaldır düğmesi ürün alınınca gizlenir. Gizlilik Seçenekleri düğmesi yalnızca
## reklam rızasının gerektiği bölgelerde (ör. AB) görünür. Oyun ekranındaki örnekte (in_game)
## dil, reklam kaldırma ve gizlilik satırları yoktur. Ana ekran ve oyun ekranı birlikte yaşadığı
## için anahtarlar ve seçimler her açılışta kayıtlı tercihlerden yeniden okunur.

const LANGUAGE_KEY_PREFIX := "LANG_"

## Oyun ekranında açılan menü; yalnızca oyun sırasında değiştirilebilecek ayarlar görünür.
@export var in_game := false

## Seçim düğmeleri, sıraları enum değerleriyle aynı.
var _glow_buttons: Array[Button] = []
var _speed_buttons: Array[Button] = []

@onready var _sound_switch: ToggleSwitch = %SoundSwitch
@onready var _music_switch: ToggleSwitch = %MusicSwitch
@onready var _glow_switch: ToggleSwitch = %GlowSwitch
@onready var _speeds: HBoxContainer = %Speeds
@onready var _languages: GridContainer = %Languages
@onready var _privacy_button: Button = %PrivacyButton


func _ready() -> void:
	pressed.connect(hide)
	(%SettingsOkButton as Button).pressed.connect(hide)
	_privacy_button.pressed.connect(Ads.show_privacy_options)
	visibility_changed.connect(_on_visibility_changed)
	_sound_switch.toggled.connect(Sound.set_enabled)
	_music_switch.toggled.connect(Music.set_enabled)
	_glow_switch.toggled.connect(_on_glow_toggled)
	var glow_keys := PawnGlow.Mode.values().map(PawnGlow.mode_key)
	_build_choices(%GlowModes as Container, _glow_buttons, glow_keys, PawnGlow.select)
	var speed_keys := GameSpeed.Level.values().map(GameSpeed.level_key)
	_build_choices(_speeds, _speed_buttons, speed_keys, GameSpeed.select)
	if in_game:
		_remove_menu_only_rows()
	else:
		_build_language_buttons()
	hide()


## Ağ oyununda hız hostun lobide seçtiğidir; oyun içinde değiştirilemez, satır gizlenir.
func show_speed(shown: bool) -> void:
	(%SpeedLabel as Control).visible = shown
	_speeds.visible = shown


func _remove_menu_only_rows() -> void:
	for row: Node in [%LanguageLabel, _languages, %RemoveAdsButton, _privacy_button]:
		row.queue_free()


## Her enum değeri için (keys sırasıyla) bir seçim düğmesi kurar; basılınca select değerle
## çağrılır.
func _build_choices(box: Container, buttons: Array[Button], keys: Array, select: Callable) -> void:
	var group := ButtonGroup.new()
	for value: int in range(keys.size()):
		var button := ChoiceButtons.add(box, keys[value], group, false)
		button.pressed.connect(select.bind(value))
		buttons.append(button)


## Anahtarları ve seçimleri kayıtlı tercihlere göre gösterir.
func _sync() -> void:
	_sound_switch.set_pressed_no_signal(Sound.is_enabled())
	_music_switch.set_pressed_no_signal(Music.is_enabled())
	_glow_switch.set_pressed_no_signal(PawnGlow.is_enabled())
	_select(_glow_buttons, PawnGlow.current())
	_select(_speed_buttons, GameSpeed.current())
	_show_glow_buttons(PawnGlow.is_enabled())


static func _select(buttons: Array[Button], selected: int) -> void:
	for index: int in range(buttons.size()):
		buttons[index].set_pressed_no_signal(index == selected)


func _on_glow_toggled(enabled: bool) -> void:
	PawnGlow.set_enabled(enabled)
	_show_glow_buttons(enabled)


func _show_glow_buttons(enabled: bool) -> void:
	for button: Button in _glow_buttons:
		button.disabled = not enabled


func _build_language_buttons() -> void:
	var group := ButtonGroup.new()
	var current := Localization.current()
	for locale: String in Localization.SUPPORTED:
		var text := LANGUAGE_KEY_PREFIX + locale.to_upper()
		var button := ChoiceButtons.add(_languages, text, group, locale == current)
		button.pressed.connect(Localization.select.bind(locale))


func _on_visibility_changed() -> void:
	if not visible:
		return
	_sync()
	if not in_game:
		_privacy_button.visible = Ads.is_privacy_options_required()
