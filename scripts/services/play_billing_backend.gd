class_name PlayBillingBackend
extends IapBackend
## Google Play Billing sağlayıcısı (Godot'un resmî GodotGooglePlayBilling eklentisi). Bağlanınca
## ürün fiyatlarını ve sahip olunan ürünleri sorar; tamamlanan satın almaları onaylar.
## Eklenti yalnızca Gradle ile derlenen Android sürümünde bulunur; başka yerde Iap sahte
## sağlayıcıyı seçer.

## Eklentinin Android tarafındaki singleton'ı; varlığı gerçek sağlayıcının seçilmesini sağlar.
const SINGLETON := "GodotGooglePlayBilling"
const NO_PURCHASE := ""

var _client: BillingClient
var _product_ids: Array[String] = []
var _purchasing := NO_PURCHASE


static func is_available() -> bool:
	return Engine.has_singleton(SINGLETON)


## Eklentinin istemcisi bir Node'dur; sağlayıcı bırakılınca o da bırakılır.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _client != null:
		_client.free()


func start(product_ids: Array[String]) -> void:
	_product_ids = product_ids
	_client = BillingClient.new()
	_client.connected.connect(_on_connected)
	_client.connect_error.connect(_on_connect_error)
	_client.query_product_details_response.connect(_on_product_details_response)
	_client.query_purchases_response.connect(_on_purchases_response)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.acknowledge_purchase_response.connect(_on_acknowledge_response)
	_client.start_connection()


## Bağlantı yoksa yeniden bağlanmayı dener ve satın almayı başarısız sayar.
func purchase(product_id: String) -> void:
	var result: Dictionary = _client.purchase(product_id) if _client.is_ready() else {}
	if BillingResponse.is_ok(result):
		_purchasing = product_id
		return
	if not _client.is_ready():
		_client.start_connection()
	purchase_completed.emit.call_deferred(product_id, false)


func _on_connected() -> void:
	_client.query_product_details(PackedStringArray(_product_ids), BillingClient.ProductType.INAPP)
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_connect_error(response_code: int, debug_message: String) -> void:
	push_warning("Play Billing bağlantı hatası (%d): %s" % [response_code, debug_message])


func _on_product_details_response(response: Dictionary) -> void:
	var prices := BillingResponse.prices(response)
	for product_id: String in prices:
		price_loaded.emit(product_id, prices[product_id])


func _on_purchases_response(response: Dictionary) -> void:
	if not BillingResponse.is_ok(response):
		push_warning("Satın almalar okunamadı: %s" % BillingResponse.describe(response))
		return
	_acknowledge(response)
	owned_products_loaded.emit(BillingResponse.owned_product_ids(response))


## Ürün zaten alınmışsa sahip olunanlar yeniden okunur; Iap kaydı onunla düzelir.
func _on_purchase_updated(response: Dictionary) -> void:
	var purchasing := _purchasing
	_purchasing = NO_PURCHASE
	if BillingResponse.code(response) == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
		_client.query_purchases(BillingClient.ProductType.INAPP)
		return
	if not BillingResponse.is_ok(response):
		if purchasing != NO_PURCHASE:
			purchase_completed.emit(purchasing, false)
		return
	_acknowledge(response)
	for product_id: String in BillingResponse.owned_product_ids(response):
		purchase_completed.emit(product_id, true)


func _acknowledge(response: Dictionary) -> void:
	for token: String in BillingResponse.unacknowledged_tokens(response):
		_client.acknowledge_purchase(token)


## Onay başarısızsa bir sonraki açılıştaki sorguda yeniden denenir.
func _on_acknowledge_response(response: Dictionary) -> void:
	if not BillingResponse.is_ok(response):
		push_warning("Satın alma onaylanamadı: %s" % BillingResponse.describe(response))
