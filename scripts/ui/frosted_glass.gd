class_name FrostedGlass
extends ColorRect
## Arkasını bulanıklaştıran, renkli buzlu cam. Gölgelendirici köşeleri piksel boyuna göre
## yuvarladığı için boyutu değişince kendine bildirir. Her cam kendi malzemesini kurar, böylece
## renkleri birbirini etkilemez.

const SIZE_PARAM := &"rect_size"
const TINT_PARAM := &"tint"
## Camın rengi ne kadar baskın olsun (0: yalnızca bulanıklık, 1: düz renk).
const TINT_STRENGTH := 0.45
const SHADER := preload("res://themes/shaders/frosted_glass.gdshader")


func _init() -> void:
	var glass_material := ShaderMaterial.new()
	glass_material.shader = SHADER
	material = glass_material


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_on_resized()


## Camı verilen renge boyar.
func set_tint(color: Color) -> void:
	_material().set_shader_parameter(TINT_PARAM, Color(color, TINT_STRENGTH))


func _on_resized() -> void:
	_material().set_shader_parameter(SIZE_PARAM, size)


func _material() -> ShaderMaterial:
	return material as ShaderMaterial
