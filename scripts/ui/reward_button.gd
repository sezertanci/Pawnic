class_name RewardButton
extends Button
## Ödüllü reklam düğmesi: üstte büyük reklam simgesi, hemen altında yazı. Godot Button'ı simge
## üstteyken yazıya sabit bir yükseklik ayırıp yazıyı ortaladığı için simge ve yazı ayrı
## düğümlerdir (`Content`). Düğme boyunu içeriğe uydurur; renkleri temadaki RewardButton
## renklerinden düğmenin durumuna göre alır.

@onready var _content: Control = $Content
@onready var _icon: TextureRect = $Content/Box/Icon
@onready var _label: Label = $Content/Box/Label


func _ready() -> void:
	_content.minimum_size_changed.connect(_fit)
	_fit()


## Düğme durumu (basılabilir, soluk) değişince yeniden çizilir; renkler o anda güncellenir.
func _draw() -> void:
	_icon.self_modulate = get_theme_color(
		"icon_disabled_color" if disabled else "icon_normal_color"
	)
	_label.self_modulate = get_theme_color("font_disabled_color" if disabled else "font_color")


func _fit() -> void:
	custom_minimum_size = _content.get_combined_minimum_size()
