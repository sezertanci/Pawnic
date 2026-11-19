class_name RemoveAdsAction
extends Node
## Üstündeki düğmeyi "Reklamları kaldır" satın alma düğmesine çevirir: fiyat öğrenilince
## metne yazılır, düğmeye basınca satın alma başlar, ürün alınınca düğme gizlenir.
## Ana ekranda ve ayarlarda aynı davranış için düğmenin çocuğu olarak eklenir.

const TEXT_KEY := "REMOVE_ADS"
const PRICED_TEXT_KEY := "REMOVE_ADS_PRICE"

@onready var _button: Button = get_parent()


func _ready() -> void:
	_button.pressed.connect(Iap.purchase.bind(Iap.REMOVE_ADS))
	Iap.products_changed.connect(_refresh)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	_button.visible = not Iap.is_owned(Iap.REMOVE_ADS)
	var price := Iap.get_price(Iap.REMOVE_ADS)
	_button.text = tr(TEXT_KEY) if price.is_empty() else tr(PRICED_TEXT_KEY) % price
