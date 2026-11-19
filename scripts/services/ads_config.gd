class_name AdsConfig
extends Resource
## AdMob reklam birimi kimlikleri ve istek ayarları. Şimdilik Google'ın test kimlikleri
## kullanılır; AdMob hesabında uygulama açılınca gerçek kimlikler data/ads_config.tres
## dosyasına yazılır.

@export var banner_unit_id := ""
@export var interstitial_unit_id := ""
@export var rewarded_unit_id := ""
## Gösterilebilecek en yüksek reklam içerik sınıfı (RequestConfiguration.MAX_AD_CONTENT_RATING_*).
@export var max_content_rating := ""
