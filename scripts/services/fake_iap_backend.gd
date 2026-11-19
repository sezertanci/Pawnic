class_name FakeIapBackend
extends IapBackend
## Geliştirme ve testte kullanılan sahte satın alma: ödeme almaz, sonucu hemen bildirir.

var succeed := true


func purchase(product_id: String) -> void:
	purchase_completed.emit.call_deferred(product_id, succeed)
