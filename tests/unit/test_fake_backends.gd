extends GutTest
## Sahte reklam ve satın alma sağlayıcılarının birim testleri.

const PRODUCT := "remove_ads"
const PLACEMENT := "extra_card"


func test_fake_purchase_reports_success() -> void:
	var iap := FakeIapBackend.new()
	watch_signals(iap)

	iap.purchase(PRODUCT)
	await wait_physics_frames(1)

	assert_signal_emitted_with_parameters(iap, "purchase_completed", [PRODUCT, true])


func test_failed_fake_purchase_reports_failure() -> void:
	var iap := FakeIapBackend.new()
	iap.succeed = false
	watch_signals(iap)

	iap.purchase(PRODUCT)
	await wait_physics_frames(1)

	assert_signal_emitted_with_parameters(iap, "purchase_completed", [PRODUCT, false])


func test_fake_rewarded_ad_grants_reward() -> void:
	var ads := FakeAdsBackend.new()
	watch_signals(ads)

	ads.show_rewarded(PLACEMENT)
	await wait_physics_frames(1)

	assert_signal_emitted_with_parameters(ads, "rewarded_completed", [PLACEMENT, true])


func test_fake_interstitial_reports_closed() -> void:
	var ads := FakeAdsBackend.new()
	watch_signals(ads)

	ads.show_interstitial()
	await wait_physics_frames(1)

	assert_signal_emitted(ads, "interstitial_closed")
