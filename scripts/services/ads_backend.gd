class_name AdsBackend
extends RefCounted
## Reklam sağlayıcısının arayüzü. Gerçek sağlayıcı (AdMob) ve testteki sahte sürüm bundan türer.

## Ödüllü reklam bittiğinde gelir; granted, oyuncunun ödülü hak edip etmediğidir.
signal rewarded_completed(placement: String, granted: bool)
## Alt banner'ın yüksekliği değişince gelir; değer ekran pikselidir, banner yoksa 0'dır.
signal banner_height_changed(height_px: int)
## Geçiş reklamı kapanınca, gösterilemediyse ya da hazır değilse gelir; oyun bununla sürer.
signal interstitial_closed


## Rızayı ister, sağlayıcıyı başlatır ve banner ile reklamları yüklemeye başlar.
func start() -> void:
	pass


## Alt banner'ı açar ya da kaldırır; kalkınca yüksekliği 0 olarak bildirilir.
func set_banner_enabled(_enabled: bool) -> void:
	pass


func is_rewarded_ready() -> bool:
	return false


func show_rewarded(_placement: String) -> void:
	pass


func show_interstitial() -> void:
	pass


## Oyuncunun rıza tercihini değiştirebileceği gizlilik seçenekleri gerekiyor mu (ör. AB'de).
func is_privacy_options_required() -> bool:
	return false


func show_privacy_options() -> void:
	pass
