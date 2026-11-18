class_name WideButton
extends Button
## Menü düğmesi: en küçük boyutunu data/tuning.json içindeki ortak ayardan alır. Böylece bütün
## menü düğmeleri aynı boyutta olur ve boyut tek yerden değişir.

## false ise yalnızca yükseklik alınır; genişliği kap belirler (yan yana duran düğmeler için).
@export var fixed_width := true


func _ready() -> void:
	var button_size := Tuning.settings.menu_button_size
	custom_minimum_size = button_size if fixed_width else Vector2(0.0, button_size.y)
