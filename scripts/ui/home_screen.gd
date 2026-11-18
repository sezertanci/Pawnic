class_name HomeScreen
extends Control
## Ana ekran: logo, yarım kalan oyuna devam, yeni oyun, "Nasıl oynanır" ve ayarlar katmanları.
## "Nasıl oynanır" katmanından demo açılabilir.

signal resume_requested
signal new_game_requested
signal demo_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _rules: Button = %RulesOverlay


func _ready() -> void:
	_resume_button.pressed.connect(resume_requested.emit)
	(%NewGameButton as Button).pressed.connect(new_game_requested.emit)
	(%HowToPlayButton as Button).pressed.connect(_rules.show)
	_rules.pressed.connect(_rules.hide)
	(%OkButton as Button).pressed.connect(_rules.hide)
	(%DemoButton as Button).pressed.connect(_on_demo_pressed)
	_rules.hide()
	(%SettingsButton as Button).pressed.connect((%SettingsOverlay as Button).show)


## Demo kapanınca "Nasıl oynanır" katmanına dönülür.
func show_rules() -> void:
	_rules.show()


func _on_demo_pressed() -> void:
	_rules.hide()
	demo_requested.emit()


func set_resume_available(available: bool) -> void:
	_resume_button.visible = available
