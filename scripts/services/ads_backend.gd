class_name AdsBackend
extends RefCounted
## Reklam sağlayıcısının arayüzü. Gerçek sağlayıcı (AdMob) ve testteki sahte sürüm bundan türer.

## Ödüllü reklam bittiğinde gelir; granted, oyuncunun ödülü hak edip etmediğidir.
signal rewarded_completed(placement: String, granted: bool)


func is_rewarded_ready() -> bool:
	return false


func show_rewarded(_placement: String) -> void:
	pass


func show_interstitial() -> void:
	pass
