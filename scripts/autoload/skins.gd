extends Node
## Seçili tahta temasını yükler ve değişince haber verir.

signal changed

const SKINS_DIR := "res://themes/skins/"
const SKIN_EXTENSION := ".tres"
const DEFAULT_ID := "classic"
const PREFERENCE_KEY := "theme"

var current: BoardSkin


func _ready() -> void:
	_load(SaveStore.get_preference(PREFERENCE_KEY, DEFAULT_ID))


func select(id: String) -> void:
	if _load(id):
		SaveStore.set_preference(PREFERENCE_KEY, id)


## Temayı yükler; bulunamazsa varsayılan temaya döner. Yüklenen tema istenen temaysa true döner.
func _load(id: String) -> bool:
	var path := SKINS_DIR + id + SKIN_EXTENSION
	var found := ResourceLoader.exists(path)
	if not found:
		path = SKINS_DIR + DEFAULT_ID + SKIN_EXTENSION
	current = load(path) as BoardSkin
	RenderingServer.set_default_clear_color(current.background_color)
	changed.emit()
	return found
