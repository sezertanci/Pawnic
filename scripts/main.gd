extends Control
## Ana sahne: ana ekran, yeni oyun ekranı ve oyun ekranı arasında geçişi yapar,
## yeni ya da kayıtlı oyunu başlatır. Arka plan ve geniş pencerede sütunun yanlarını dolduran
## düz renk yalnızca menü ekranlarında görünür.

var _rng := RandomNumberGenerator.new()

@onready var _backdrop: TextureRect = $Column/Backdrop
@onready var _sides: ColorRect = $Sides
@onready var _home: HomeScreen = $Column/HomeScreen
@onready var _setup: SetupScreen = $Column/SetupScreen
@onready var _game_screen: GameScreen = $Column/GameScreen


func _ready() -> void:
	_rng.randomize()
	_home.resume_requested.connect(_on_resume_requested)
	_home.new_game_requested.connect(_show_only.bind(_setup))
	_setup.back_requested.connect(_show_home)
	_setup.start_requested.connect(_on_start_requested)
	_game_screen.finished.connect(_show_home)
	_game_screen.replay_requested.connect(_on_start_requested)
	_game_screen.left.connect(_show_home)
	_show_home()


func _show_home() -> void:
	_home.set_resume_available(SaveStore.has_match())
	_show_only(_home)


## Verilen ekranı gösterir, ötekileri gizler.
func _show_only(screen: Control) -> void:
	for other: Control in [_home, _setup, _game_screen]:
		other.visible = other == screen
	_backdrop.visible = screen != _game_screen
	_sides.visible = _backdrop.visible


func _on_start_requested(bot_flags: Array[bool], pawns: int) -> void:
	SaveStore.clear_match()
	_begin(GameMatch.create(Tuning.settings, bot_flags, pawns, _rng))


func _on_resume_requested() -> void:
	var game := GameMatch.from_dict(Tuning.settings, SaveStore.load_match(), _rng)
	if game == null:
		push_warning("Kayıtlı oyun okunamadı, siliniyor.")
		SaveStore.clear_match()
		_show_home()
		return
	_begin(game)


func _begin(game: GameMatch) -> void:
	_show_only(_game_screen)
	_game_screen.start(game)
