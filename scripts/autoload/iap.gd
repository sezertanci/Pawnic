extends Node
## Oyunun satın alma kapısı. Oyun kodu sağlayıcıyı bilmez, yalnızca bu düğümü çağırır.

signal purchase_completed(product_id: String, success: bool)

var _backend: IapBackend


func _ready() -> void:
	use_backend(FakeIapBackend.new())


## Sağlayıcıyı değiştirir; testler kendi sahte sürümünü burada verir.
func use_backend(backend: IapBackend) -> void:
	_backend = backend
	_backend.purchase_completed.connect(purchase_completed.emit)


func purchase(product_id: String) -> void:
	_backend.purchase(product_id)


func is_owned(product_id: String) -> bool:
	return _backend.is_owned(product_id)


func restore() -> void:
	_backend.restore()
