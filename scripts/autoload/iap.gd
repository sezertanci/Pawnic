extends Node
## Oyunun satın alma kapısı. Oyun kodu sağlayıcıyı bilmez, yalnızca bu düğümü çağırır.
## Sahip olunan ürünler cihazda da saklanır; böylece açılışta sağlayıcı bağlanmadan (ör.
## internet yokken) reklamlar gizli kalır. Sağlayıcı sahip olunanları okuyunca kayıt onunla
## değiştirilir; iade edilen ürün böyle düşer. Satın almalar her açılışta kendiliğinden geri gelir.

signal purchase_completed(product_id: String, success: bool)
## Sahip olunan ürünler ya da fiyatlar değişince gelir.
signal products_changed

## Reklamları kaldırma ürünü; Play Console'daki ürün kimliğiyle aynıdır.
const REMOVE_ADS := "remove_ads"
const PRODUCT_IDS: Array[String] = [REMOVE_ADS]
const OWNED_KEY := "owned_products"
const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")

## Sahip olunan ürünlerin saklandığı kayıt; testler kendi kaydını verir.
var store: SaveStoreScript

var _backend: IapBackend
var _owned: Array[String] = []
var _prices := {}


func _ready() -> void:
	store = SaveStore
	load_owned()
	use_backend(_create_backend())
	_backend.start(PRODUCT_IDS)


## Sağlayıcıyı değiştirir; testler kendi sahte sürümünü burada verir.
func use_backend(backend: IapBackend) -> void:
	_backend = backend
	_backend.purchase_completed.connect(_on_purchase_completed)
	_backend.owned_products_loaded.connect(_set_owned)
	_backend.price_loaded.connect(_on_price_loaded)


## Kayıttaki sahip olunan ürünleri okur.
func load_owned() -> void:
	_owned.clear()
	for id: Variant in store.get_preference(OWNED_KEY, []) as Array:
		if id is String:
			_owned.append(id)


func purchase(product_id: String) -> void:
	_backend.purchase(product_id)


func is_owned(product_id: String) -> bool:
	return _owned.has(product_id)


## Mağazadaki yerel fiyat metni; henüz öğrenilmediyse boştur.
func get_price(product_id: String) -> String:
	return _prices.get(product_id, "")


func _create_backend() -> IapBackend:
	if PlayBillingBackend.is_available():
		return PlayBillingBackend.new()
	return FakeIapBackend.new()


func _on_purchase_completed(product_id: String, success: bool) -> void:
	if success and not is_owned(product_id):
		var owned := _owned.duplicate()
		owned.append(product_id)
		_set_owned(owned)
	purchase_completed.emit(product_id, success)


func _set_owned(product_ids: Array[String]) -> void:
	if product_ids == _owned:
		return
	_owned = product_ids.duplicate()
	store.set_preference(OWNED_KEY, _owned)
	products_changed.emit()


func _on_price_loaded(product_id: String, price: String) -> void:
	_prices[product_id] = price
	products_changed.emit()
