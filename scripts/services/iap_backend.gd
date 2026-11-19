class_name IapBackend
extends RefCounted
## Uygulama içi satın alma sağlayıcısının arayüzü. Gerçek sağlayıcı (Play Billing) ve testteki
## sahte sürüm bundan türer.

## Satın alma akışı bitince gelir; success, ürünün oyuncuya geçip geçmediğidir.
signal purchase_completed(product_id: String, success: bool)
## Sağlayıcı sahip olunan ürünleri okuyunca gelir. Liste tamdır: içinde olmayan ürüne sahip
## olunmuyor demektir (ör. iade edilmiş).
signal owned_products_loaded(product_ids: Array[String])
## Ürünün mağazadaki yerel para birimiyle yazılmış fiyatı öğrenilince gelir.
signal price_loaded(product_id: String, price: String)


## Sağlayıcıya bağlanır; ardından ürünlerin fiyatlarını ve sahip olunan ürünleri okur.
func start(_product_ids: Array[String]) -> void:
	pass


func purchase(_product_id: String) -> void:
	pass
