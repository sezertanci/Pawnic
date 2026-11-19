class_name BillingResponse
extends RefCounted
## Play Billing eklentisinin (GodotGooglePlayBilling) yanıt sözlüklerini okur. Yalnızca
## tamamlanmış (PURCHASED) satın almalar sayılır; bekleyen (PENDING) ödeme ürün vermez.

const KEY_RESPONSE_CODE := "response_code"
const KEY_DEBUG_MESSAGE := "debug_message"
const KEY_PURCHASES := "purchases"
const KEY_PRODUCT_IDS := "product_ids"
const KEY_PURCHASE_STATE := "purchase_state"
const KEY_ACKNOWLEDGED := "is_acknowledged"
const KEY_PURCHASE_TOKEN := "purchase_token"
const KEY_PRODUCT_DETAILS := "product_details"
const KEY_PRODUCT_ID := "product_id"
const KEY_ONE_TIME_OFFERS := "one_time_purchase_offer_details_list"
const KEY_FORMATTED_PRICE := "formatted_price"


static func code(response: Dictionary) -> int:
	return int(response.get(KEY_RESPONSE_CODE, BillingClient.BillingResponseCode.ERROR))


static func is_ok(response: Dictionary) -> bool:
	return code(response) == BillingClient.BillingResponseCode.OK


static func describe(response: Dictionary) -> String:
	return "%d %s" % [code(response), str(response.get(KEY_DEBUG_MESSAGE, ""))]


## Yanıttaki tamamlanmış satın almaların ürün kimlikleri.
static func owned_product_ids(response: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for purchase: Dictionary in _completed_purchases(response):
		for id: String in purchase.get(KEY_PRODUCT_IDS, []):
			if not ids.has(id):
				ids.append(id)
	return ids


## Henüz onaylanmamış tamamlanmış satın almaların belirteçleri. Onaylanmayan satın alma
## Play tarafından birkaç gün içinde iade edilir.
static func unacknowledged_tokens(response: Dictionary) -> Array[String]:
	var tokens: Array[String] = []
	for purchase: Dictionary in _completed_purchases(response):
		if not purchase.get(KEY_ACKNOWLEDGED, false):
			tokens.append(str(purchase.get(KEY_PURCHASE_TOKEN, "")))
	return tokens


## Ürün kimliğinden, tek seferlik satın alma teklifinin yerel fiyat metnine sözlük.
static func prices(response: Dictionary) -> Dictionary:
	var result := {}
	if not is_ok(response):
		return result
	for details: Dictionary in response.get(KEY_PRODUCT_DETAILS, []):
		var offers: Array = details.get(KEY_ONE_TIME_OFFERS, [])
		if not offers.is_empty():
			result[str(details.get(KEY_PRODUCT_ID, ""))] = str(
				(offers[0] as Dictionary).get(KEY_FORMATTED_PRICE, "")
			)
	return result


static func _completed_purchases(response: Dictionary) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	if not is_ok(response):
		return completed
	for purchase: Dictionary in response.get(KEY_PURCHASES, []):
		if int(purchase.get(KEY_PURCHASE_STATE, 0)) == BillingClient.PurchaseState.PURCHASED:
			completed.append(purchase)
	return completed
