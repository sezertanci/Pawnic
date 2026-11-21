extends Control
## Ana sahne: ana ekran, yeni oyun ekranı, ağ lobisi ekranları, oyun ekranı ve demo arasında
## geçişi yapar, yeni ya da kayıtlı oyunu başlatır. Arka plan ve geniş pencerede sütunun
## yanlarını dolduran düz renk yalnızca menü ekranlarında görünür; arka plan, düğmeler öne
## çıksın diye hafifçe bulanıklaştırılır.

const BLUR_PARAMETER := &"blur_radius"

var _rng := RandomNumberGenerator.new()
## Oyun ekranındaki oyun ağ oyunuysa true; bitince Ağ sekmesine dönülür.
var _network := false

@onready var _backdrop: TextureRect = $Column/Backdrop
@onready var _sides: ColorRect = $Sides
@onready var _column: AspectColumn = $Column
@onready var _home: HomeScreen = $Column/HomeScreen
@onready var _setup: SetupScreen = $Column/SetupScreen
@onready var _game_screen: GameScreen = $Column/GameScreen
@onready var _demo: DemoScreen = $Column/DemoScreen
@onready var _host_lobby: HostLobbyScreen = $Column/HostLobbyScreen
@onready var _join: JoinScreen = $Column/JoinScreen


func _ready() -> void:
	_rng.randomize()
	var blur := Tuning.settings.backdrop_blur
	(_backdrop.material as ShaderMaterial).set_shader_parameter(BLUR_PARAMETER, blur)
	_home.resume_requested.connect(_on_resume_requested)
	_home.new_game_requested.connect(_show_only.bind(_setup))
	_setup.back_requested.connect(_show_home)
	_setup.start_requested.connect(_on_start_requested)
	_setup.host_requested.connect(_on_host_requested)
	_setup.join_requested.connect(_on_join_requested)
	_host_lobby.closed.connect(_show_only.bind(_setup))
	_join.closed.connect(_show_only.bind(_setup))
	_host_lobby.started.connect(_on_network_started)
	_join.started.connect(_on_network_started)
	_game_screen.finished.connect(_on_game_closed)
	_game_screen.replay_requested.connect(_on_start_requested)
	_game_screen.rematch_requested.connect(_host_lobby.rematch)
	_game_screen.left.connect(_on_game_closed)
	_home.demo_requested.connect(_on_demo_requested)
	_demo.closed.connect(_on_demo_closed)
	_column.bottom_inset = Ads.banner_height
	Ads.banner_height_changed.connect(_on_banner_height_changed)
	_show_home()


func _show_home() -> void:
	_home.set_resume_available(SaveStore.has_match())
	_show_only(_home)


## Verilen ekranı gösterir, ötekileri gizler.
func _show_only(screen: Control) -> void:
	for other: Control in [_home, _setup, _game_screen, _demo, _host_lobby, _join]:
		other.visible = other == screen
	_backdrop.visible = screen != _game_screen and screen != _demo
	_sides.visible = _backdrop.visible


func _on_banner_height_changed(height: float) -> void:
	_column.bottom_inset = height


func _on_host_requested() -> void:
	_show_only(_host_lobby)
	_host_lobby.open()


func _on_join_requested() -> void:
	_show_only(_join)
	_join.open()


func _on_network_started(source: MatchSource) -> void:
	_network = true
	_show_only(_game_screen)
	_game_screen.start_source(source, true)


## Ağ oyunu bitince bağlantılar kapanır ve yeni oyun ekranının Ağ sekmesine dönülür.
func _on_game_closed() -> void:
	if not _network:
		_show_home()
		return
	_network = false
	_host_lobby.close_room()
	_join.close()
	_setup.show_network()
	_show_only(_setup)


func _on_demo_requested() -> void:
	_show_only(_demo)
	_demo.open()


func _on_demo_closed() -> void:
	_show_home()
	_home.show_rules()


func _on_start_requested(bot_flags: Array[bool], pawns: int, bot_level: Bot.Level) -> void:
	SaveStore.clear_match()
	var game := GameMatch.create(Tuning.settings, bot_flags, pawns, _rng)
	game.bot_level = bot_level
	_choose_colors(game)
	MatchStarter.choose(game, _rng)
	_begin(game, true)


## Tek oyunculu oyunda (botlu oyunda) insan oyuncu seçtiği renkte oynar; aynı telefonda çok
## oyunculu oyunda her koltuk kendi rengindedir.
func _choose_colors(game: GameMatch) -> void:
	var human := game.bots.find(false)
	if not game.bots.has(true) or human == GameMatch.NO_INDEX:
		return
	var count := game.colors.size()
	game.colors = SeatColors.with_choice(
		count, game.seats, game.seats[human], PlayerColor.current()
	)


func _on_resume_requested() -> void:
	var game := GameMatch.from_dict(Tuning.settings, SaveStore.load_match(), _rng)
	if game == null:
		push_warning("Kayıtlı oyun okunamadı, siliniyor.")
		SaveStore.clear_match()
		_show_home()
		return
	_begin(game)


## Yeni oyunda (is_new) başlayan oyuncu kurayla gösterilir.
func _begin(game: GameMatch, is_new := false) -> void:
	_show_only(_game_screen)
	_game_screen.start(game, is_new)
