class_name WideButton
extends Button
## Menü düğmesi: en küçük boyutunu data/tuning.json içindeki ortak ayardan alır. Böylece bütün
## menü düğmeleri aynı boyutta olur ve boyut tek yerden değişir.


func _ready() -> void:
	custom_minimum_size = Tuning.settings.menu_button_size
