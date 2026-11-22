class_name HomeScreen
extends Control
## Ana ekran: logo, yarım kalan oyuna devam, yeni oyun, "Nasıl oynanır" ve ayarlar katmanları,
## görünüm (tahta teması) ekranına geçiş.
## "Nasıl oynanır" katmanından demo açılabilir.

signal resume_requested
signal new_game_requested
signal demo_requested
signal appearance_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _rules: Button = %RulesOverlay
@onready var _rule_list: RuleList = %RuleList


func _ready() -> void:
	_resume_button.pressed.connect(resume_requested.emit)
	(%NewGameButton as Button).pressed.connect(new_game_requested.emit)
	(%HowToPlayButton as Button).pressed.connect(_on_how_to_play_pressed)
	(%AppearanceButton as Button).pressed.connect(appearance_requested.emit)
	_rules.pressed.connect(_rules.hide)
	(%OkButton as Button).pressed.connect(_rules.hide)
	(%DemoButton as Button).pressed.connect(_on_demo_pressed)
	_rules.hide()
	(%SettingsButton as Button).pressed.connect((%SettingsOverlay as Button).show)


## "Nasıl oynanır" her açılışta bütün grupları kapalı gösterir.
func _on_how_to_play_pressed() -> void:
	_rule_list.collapse_all()
	_rules.show()


## Demo kapanınca "Nasıl oynanır" katmanına açık grup korunarak dönülür.
func show_rules() -> void:
	_rules.show()


func _on_demo_pressed() -> void:
	_rules.hide()
	demo_requested.emit()


func set_resume_available(available: bool) -> void:
	_resume_button.visible = available
