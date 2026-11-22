extends Node
## Kural, deste ve bot ayarlarını açılışta bir kez okur ve oyunun geri kalanına verir. settings
## varsayılan tahtanın ayarlarıdır; başka tahtanın ayarları ilk istendiğinde okunup saklanır.

var settings: GameSettings

var _by_board: Dictionary[String, GameSettings] = {}


func _init() -> void:
	settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
	_by_board[settings.board.id] = settings


## Kimliği verilen tahtanın ayarları; tahta listede yoksa varsayılan tahtanınkiler.
func for_board(id: String) -> GameSettings:
	if settings.find_board(id) == null:
		return settings
	if not _by_board.has(id):
		_by_board[id] = GameSettings.load_from(GameSettings.DEFAULT_PATH, id)
	return _by_board[id]
