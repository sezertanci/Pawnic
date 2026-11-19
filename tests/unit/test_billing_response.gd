extends GutTest
## Play Billing yanıtlarını okuyan BillingResponse'un birim testleri. Sözlükler eklentinin
## gönderdiği biçimdedir.

const PRODUCT := "remove_ads"
const TOKEN := "token-1"
const PRICE := "₺49,99"
const OK := BillingClient.BillingResponseCode.OK
const PURCHASED := BillingClient.PurchaseState.PURCHASED
const PENDING := BillingClient.PurchaseState.PENDING


func _purchase(state: int, acknowledged: bool) -> Dictionary:
	return {
		"product_ids": PackedStringArray([PRODUCT]),
		"purchase_state": state,
		"is_acknowledged": acknowledged,
		"purchase_token": TOKEN,
	}


func _purchases(code: int, purchases: Array) -> Dictionary:
	return {"response_code": code, "debug_message": "", "purchases": purchases}


func test_completed_purchase_owns_product() -> void:
	var response := _purchases(OK, [_purchase(PURCHASED, true)])

	var owned := BillingResponse.owned_product_ids(response)

	assert_eq(owned, [PRODUCT] as Array[String])


func test_pending_purchase_does_not_own_product() -> void:
	var response := _purchases(OK, [_purchase(PENDING, false)])

	var owned := BillingResponse.owned_product_ids(response)

	assert_true(owned.is_empty())


func test_failed_response_owns_nothing() -> void:
	var response := _purchases(
		BillingClient.BillingResponseCode.ERROR, [_purchase(PURCHASED, true)]
	)

	var owned := BillingResponse.owned_product_ids(response)

	assert_true(owned.is_empty())


func test_unacknowledged_completed_purchase_needs_acknowledging() -> void:
	var response := _purchases(OK, [_purchase(PURCHASED, false), _purchase(PENDING, false)])

	var tokens := BillingResponse.unacknowledged_tokens(response)

	assert_eq(tokens, [TOKEN] as Array[String])


func test_acknowledged_purchase_needs_nothing() -> void:
	var response := _purchases(OK, [_purchase(PURCHASED, true)])

	var tokens := BillingResponse.unacknowledged_tokens(response)

	assert_true(tokens.is_empty())


func test_price_comes_from_one_time_offer() -> void:
	var details := {
		"product_id": PRODUCT,
		"one_time_purchase_offer_details_list": [{"formatted_price": PRICE}],
	}
	var response := {"response_code": OK, "product_details": [details]}

	var prices := BillingResponse.prices(response)

	assert_eq(prices, {PRODUCT: PRICE})


func test_missing_response_code_is_not_ok() -> void:
	var response := {}

	var ok := BillingResponse.is_ok(response)

	assert_false(ok)
