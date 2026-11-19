class_name AspectColumn
extends Control
## Ekranları ortalanmış dikey bir sütunda tutar. Sütun en fazla max_aspect (genişlik/yükseklik)
## oranı kadar geniş olur; daha geniş pencerelerde iki yanda yalnızca arka plan görünür.
## Telefon ve tablet bu orandan dar olduğu için onlarda sütun bütün ekranı kaplar.
## bottom_inset, sütunun altında boş bırakılan yüksekliktir (ör. reklam banner'ı için).

@export var max_aspect := 0.75

var bottom_inset := 0.0:
	set(value):
		bottom_inset = value
		if is_inside_tree():
			_fit()


func _ready() -> void:
	get_parent_control().resized.connect(_fit)
	_fit()


func _fit() -> void:
	var area := get_parent_control().size
	var width := minf(area.x, area.y * max_aspect)
	set_anchors_preset(PRESET_CENTER_TOP)
	anchor_bottom = 1.0
	offset_left = -width / 2.0
	offset_right = width / 2.0
	offset_top = 0.0
	offset_bottom = -bottom_inset
