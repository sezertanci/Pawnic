extends GutTest
## Iap kapısının birim testleri: sahip olunan ürünlerin kaydı, iade ve fiyat. Gerçek kayıt
## dosyasına dokunmamak için ayrı bir yol kullanılır.

const IapScript := preload("res://scripts/autoload/iap.gd")
const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_iap_save.json"
const PRICE := "₺49,99"

var _store: SaveStoreScript
var _backend: FakeIapBackend
var _iap: IapScript


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()
	_backend = FakeIapBackend.new()
	_iap = _new_iap()


func after_each() -> void:
	_iap.free()
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func _new_iap() -> IapScript:
	var iap: IapScript = IapScript.new()
	iap.store = _store
	iap.load_owned()
	iap.use_backend(_backend)
	return iap


func test_successful_purchase_owns_product() -> void:
	_iap.purchase(IapScript.REMOVE_ADS)
	await wait_physics_frames(1)

	assert_true(_iap.is_owned(IapScript.REMOVE_ADS))


func test_failed_purchase_does_not_own_product() -> void:
	_backend.succeed = false

	_iap.purchase(IapScript.REMOVE_ADS)
	await wait_physics_frames(1)

	assert_false(_iap.is_owned(IapScript.REMOVE_ADS))


func test_owned_product_survives_restart() -> void:
	_iap.purchase(IapScript.REMOVE_ADS)
	await wait_physics_frames(1)
	_store.reload()

	var restarted := _new_iap()

	assert_true(restarted.is_owned(IapScript.REMOVE_ADS))
	restarted.free()


func test_refunded_product_is_no_longer_owned() -> void:
	_iap.purchase(IapScript.REMOVE_ADS)
	await wait_physics_frames(1)
	var none: Array[String] = []

	_backend.owned_products_loaded.emit(none)

	assert_false(_iap.is_owned(IapScript.REMOVE_ADS))


func test_store_reported_product_is_owned() -> void:
	var owned: Array[String] = [IapScript.REMOVE_ADS]
	watch_signals(_iap)

	_backend.owned_products_loaded.emit(owned)

	assert_true(_iap.is_owned(IapScript.REMOVE_ADS))
	assert_signal_emitted(_iap, "products_changed")


func test_loaded_price_is_returned() -> void:
	_backend.price_loaded.emit(IapScript.REMOVE_ADS, PRICE)

	var price := _iap.get_price(IapScript.REMOVE_ADS)

	assert_eq(price, PRICE)
