class_name Stepper
extends HBoxContainer
## Başlık, "−" ve "+" düğmeleriyle sınırlar içinde bir sayı seçtiren satır.

signal value_changed(value: int)

var value := 0

var _min_value := 0
var _max_value := 0

@onready var _title: Label = %Title
@onready var _value_label: Label = %Value


func _ready() -> void:
	(%Minus as Button).pressed.connect(_step.bind(-1))
	(%Plus as Button).pressed.connect(_step.bind(1))


func configure(title_key: String, min_value: int, max_value: int, start_value: int) -> void:
	_title.text = title_key
	_min_value = min_value
	_max_value = max_value
	value = clampi(start_value, min_value, max_value)
	_value_label.text = str(value)


func _step(delta: int) -> void:
	value = clampi(value + delta, _min_value, _max_value)
	_value_label.text = str(value)
	value_changed.emit(value)
