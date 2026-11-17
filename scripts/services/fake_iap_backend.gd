class_name FakeIapBackend
extends IapBackend
## Geliştirme ve testte kullanılan sahte satın alma: ödeme almaz, ürünü bellekte sahiplenir.

var succeed := true

var _owned: Array[String] = []


func purchase(product_id: String) -> void:
	if succeed and not _owned.has(product_id):
		_owned.append(product_id)
	purchase_completed.emit.call_deferred(product_id, succeed)


func is_owned(product_id: String) -> bool:
	return _owned.has(product_id)
