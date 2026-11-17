extends Node
## Oyunun reklam kapısı. Oyun kodu sağlayıcıyı bilmez, yalnızca bu düğümü çağırır.
## Geçiş reklamı oyunun ortasında asla gösterilmez; çağıran yer yalnızca oyun bitince çağırır.

signal rewarded_completed(placement: String, granted: bool)

var _backend: AdsBackend


func _ready() -> void:
	use_backend(FakeAdsBackend.new())


## Sağlayıcıyı değiştirir; testler kendi sahte sürümünü burada verir.
func use_backend(backend: AdsBackend) -> void:
	_backend = backend
	_backend.rewarded_completed.connect(rewarded_completed.emit)


func is_rewarded_ready() -> bool:
	return _backend.is_rewarded_ready()


func show_rewarded(placement: String) -> void:
	_backend.show_rewarded(placement)


func show_interstitial() -> void:
	_backend.show_interstitial()
