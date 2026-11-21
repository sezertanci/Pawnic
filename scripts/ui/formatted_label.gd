class_name FormattedLabel
extends Label
## İçinde sayı geçen çeviri metni (ör. "%d saniye"). Metin tr(key) % value ile yazılır ve dil
## değişince yeniden kurulur; Label'ın kendi çevirisi kapalıdır.

var _key: String
var _value: float


func _init(key: String, value: float) -> void:
	_key = key
	_value = value
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED


func _ready() -> void:
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	text = tr(_key) % _value
