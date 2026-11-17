class_name IapBackend
extends RefCounted
## Uygulama içi satın alma sağlayıcısının arayüzü. Gerçek sağlayıcı (Play Billing) ve testteki
## sahte sürüm bundan türer.

signal purchase_completed(product_id: String, success: bool)


func purchase(_product_id: String) -> void:
	pass


func is_owned(_product_id: String) -> bool:
	return false


## Daha önce yapılmış satın almaları sağlayıcıdan yeniden okur.
func restore() -> void:
	pass
