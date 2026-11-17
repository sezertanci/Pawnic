extends Node
## Kural, deste ve bot ayarlarını açılışta bir kez okur ve oyunun geri kalanına verir.

var settings: GameSettings


func _init() -> void:
	settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)
