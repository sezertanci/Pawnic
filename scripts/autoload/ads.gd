extends Node
## Oyunun reklam kapısı. Oyun kodu sağlayıcıyı bilmez, yalnızca bu düğümü çağırır.
## Geçiş reklamı oyun sonunda ve uzun oyunlarda belli aralıklarla, insan oyuncunun sırası
## başlamadan önce gösterilir (zamanlama AdSchedule'da); kart seçerken ya da taş yürürken
## gösterilmez.
## AdMob eklentisi yalnızca Gradle ile derlenen Android sürümünde vardır; yoksa sahte sağlayıcı
## kullanılır.

signal rewarded_completed(placement: String, granted: bool)
## Alt banner'ın tuval birimindeki yüksekliği değişince gelir; ekranlar bu kadar yukarı kayar.
signal banner_height_changed(height: float)
## Geçiş reklamı kapanınca ya da gösterilemeyince gelir.
signal interstitial_closed

const CONFIG_PATH := "res://data/ads_config.tres"

var banner_height := 0.0

var _backend: AdsBackend


func _ready() -> void:
	use_backend(_create_backend())
	_backend.start()


## Sağlayıcıyı değiştirir; testler kendi sahte sürümünü burada verir.
func use_backend(backend: AdsBackend) -> void:
	_backend = backend
	_backend.rewarded_completed.connect(rewarded_completed.emit)
	_backend.banner_height_changed.connect(_on_banner_height_changed)
	_backend.interstitial_closed.connect(interstitial_closed.emit)


func is_rewarded_ready() -> bool:
	return _backend.is_rewarded_ready()


func show_rewarded(placement: String) -> void:
	_backend.show_rewarded(placement)


func show_interstitial() -> void:
	_backend.show_interstitial()


func is_privacy_options_required() -> bool:
	return _backend.is_privacy_options_required()


func show_privacy_options() -> void:
	_backend.show_privacy_options()


func _create_backend() -> AdsBackend:
	if AdMobBackend.is_available():
		return AdMobBackend.new(load(CONFIG_PATH) as AdsConfig)
	return FakeAdsBackend.new()


## Ekran pikselini, ekranların yerleştiği tuval birimine çevirir.
func _on_banner_height_changed(height_px: int) -> void:
	var window_height := float(DisplayServer.window_get_size().y)
	var canvas_height := get_viewport().get_visible_rect().size.y
	banner_height = height_px * canvas_height / window_height
	banner_height_changed.emit(banner_height)
