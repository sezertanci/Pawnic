class_name AdMobBackend
extends AdsBackend
## Google AdMob sağlayıcısı (Poing Studios eklentisi). Açılışta UMP ile rıza ister, ardından
## reklam SDK'sını başlatır, alt banner'ı gösterir, geçiş ve ödüllü reklamı önceden yükler.
## Gösterilen reklam kapanınca yerine yenisi yüklenir. Eklenti yalnızca Gradle ile derlenen
## Android sürümünde bulunur; başka yerde Ads sahte sağlayıcıyı seçer.

## Eklentinin Android tarafındaki ana singleton'ı; varlığı gerçek sağlayıcının seçilmesini sağlar.
const SINGLETON := "PoingGodotAdMob"

var _config: AdsConfig
var _started := false
var _banner: AdView
var _interstitial: InterstitialAd
var _interstitial_loading := false
var _rewarded: RewardedAd
var _rewarded_loading := false
var _rewarded_placement := ""
var _reward_earned := false


static func is_available() -> bool:
	return Engine.has_singleton(SINGLETON)


func _init(config: AdsConfig) -> void:
	_config = config


func start() -> void:
	var parameters := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(
		parameters, _on_consent_info_updated, _on_consent_failed
	)


func is_rewarded_ready() -> bool:
	return _rewarded != null


func show_rewarded(placement: String) -> void:
	if _rewarded == null:
		_load_rewarded()
		rewarded_completed.emit.call_deferred(placement, false)
		return
	_rewarded_placement = placement
	_reward_earned = false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = _on_reward_earned
	_rewarded.show(listener)


func show_interstitial() -> void:
	if _interstitial == null:
		_load_interstitial()
		interstitial_closed.emit.call_deferred()
		return
	_interstitial.show()


func is_privacy_options_required() -> bool:
	var status := UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
	return status == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(_on_form_closed)


# --- Rıza ---


func _on_consent_info_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	var required := info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
	if required and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_failed)
	else:
		_start_ads()


func _on_consent_form_loaded(form: ConsentForm) -> void:
	form.show(_on_consent_form_dismissed)


func _on_consent_form_dismissed(error: FormError) -> void:
	_on_form_closed(error)
	_start_ads()


## Rıza alınamasa da SDK başlatılır; SDK önceki rızaya göre reklam ister.
func _on_consent_failed(error: FormError) -> void:
	_on_form_closed(error)
	_start_ads()


func _on_form_closed(error: FormError) -> void:
	if error != null:
		push_warning("Reklam rızası formu hatası: %s" % error.message)


# --- Başlatma ---


func _start_ads() -> void:
	if _started:
		return
	_started = true
	MobileAds.set_request_configuration(_request_configuration())
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_initialized
	MobileAds.initialize(listener)


func _request_configuration() -> RequestConfiguration:
	var configuration := RequestConfiguration.new()
	configuration.max_ad_content_rating = _config.max_content_rating
	configuration.tag_for_child_directed_treatment = (
		RequestConfiguration.TagForChildDirectedTreatment.FALSE
	)
	return configuration


func _on_initialized(_status: InitializationStatus) -> void:
	_load_banner()
	_load_interstitial()
	_load_rewarded()


# --- Banner ---


func _load_banner() -> void:
	var size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	_banner = AdView.new(_config.banner_unit_id, size, AdPosition.BOTTOM)
	_banner.ad_listener.on_ad_loaded = _on_banner_loaded
	_banner.ad_listener.on_ad_failed_to_load = _warn_ad_error
	_banner.load_ad(AdRequest.new())


func _on_banner_loaded() -> void:
	banner_height_changed.emit(_banner.get_height_in_pixels())


# --- Geçiş reklamı ---


func _load_interstitial() -> void:
	if not _started or _interstitial_loading:
		return
	_interstitial_loading = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = _on_interstitial_loaded
	callback.on_ad_failed_to_load = _on_interstitial_load_failed
	InterstitialAdLoader.new().load(_config.interstitial_unit_id, AdRequest.new(), callback)


func _on_interstitial_loaded(ad: InterstitialAd) -> void:
	_interstitial_loading = false
	_interstitial = ad
	var callbacks := ad.full_screen_content_callback
	callbacks.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed
	callbacks.on_ad_failed_to_show_full_screen_content = _on_interstitial_show_failed


## Yükleme başarısızsa hemen yeniden denenmez; sıradaki gösterme isteği yeniden yükler.
func _on_interstitial_load_failed(error: AdError) -> void:
	_interstitial_loading = false
	_warn_ad_error(error)


func _on_interstitial_dismissed() -> void:
	_replace_interstitial()
	interstitial_closed.emit()


func _on_interstitial_show_failed(error: AdError) -> void:
	_warn_ad_error(error)
	_replace_interstitial()
	interstitial_closed.emit()


## Gösterilen ya da gösterilemeyen reklamı bırakır ve sıradaki gösterim için yenisini yükler.
func _replace_interstitial() -> void:
	if _interstitial != null:
		_interstitial.destroy()
		_interstitial = null
	_load_interstitial()


# --- Ödüllü reklam ---


func _load_rewarded() -> void:
	if not _started or _rewarded_loading:
		return
	_rewarded_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = _on_rewarded_loaded
	callback.on_ad_failed_to_load = _on_rewarded_load_failed
	RewardedAdLoader.new().load(_config.rewarded_unit_id, AdRequest.new(), callback)


func _on_rewarded_loaded(ad: RewardedAd) -> void:
	_rewarded_loading = false
	_rewarded = ad
	var callbacks := ad.full_screen_content_callback
	callbacks.on_ad_dismissed_full_screen_content = _finish_rewarded
	callbacks.on_ad_failed_to_show_full_screen_content = _on_rewarded_show_failed


func _on_reward_earned(_item: RewardedItem) -> void:
	_reward_earned = true


## Yükleme başarısızsa hemen yeniden denenmez; sıradaki gösterme isteği yeniden yükler.
func _on_rewarded_load_failed(error: AdError) -> void:
	_rewarded_loading = false
	_warn_ad_error(error)


func _on_rewarded_show_failed(error: AdError) -> void:
	_warn_ad_error(error)
	_finish_rewarded()


## Reklam kapanınca sonucu bildirir, reklamı bırakır ve yenisini yükler.
func _finish_rewarded() -> void:
	if _rewarded != null:
		_rewarded.destroy()
		_rewarded = null
		rewarded_completed.emit(_rewarded_placement, _reward_earned)
	_load_rewarded()


func _warn_ad_error(error: AdError) -> void:
	if error != null:
		push_warning("Reklam hatası (%d): %s" % [error.code, error.message])
