class_name GameMenuButton
extends Button
## Oyun ekranının menü tuşu: ayarlar katmanını açar. Yerel oyun menü açıkken durur (saat, sıra
## süresi, bot), menü kapanınca sürer. Ağ oyunu durmaz; hız hostun lobide seçtiği olduğu için
## ağ oyununda hız satırı gösterilmez.

@export var overlay: SettingsOverlay

## Oyunun kaynağı; değişince menü kapanır, eski kaynak moladaysa sürdürülür.
var source: MatchSource:
	set(value):
		overlay.hide()
		source = value

## Menü açılınca oyunu bu tuş molaya aldıysa true.
var _paused := false


func _ready() -> void:
	pressed.connect(_open)
	overlay.visibility_changed.connect(_on_overlay_visibility_changed)


func _open() -> void:
	overlay.show_speed(not source.is_networked())
	overlay.show()


func _on_overlay_visibility_changed() -> void:
	if overlay.visible:
		if not source.is_networked() and source.is_live() and not source.is_paused():
			_paused = true
			source.pause()
	elif _paused:
		_paused = false
		source.resume()
