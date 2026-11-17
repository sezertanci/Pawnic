class_name Stepper
extends PanelContainer
## Solda başlık ve altında "−" / "+" düğmeleriyle seçilen sayı, sağda seçilen sayı
## kadar taş görseli (iki sıra) bulunan şerit. Sınıra gelince ilgili düğme kapanır.

signal value_changed(value: int)

## Açıksa her taş sıradaki koltuğun renginde, kapalıysa hepsi ilk koltuğun renginde çizilir.
@export var each_seat := false

var value := 0

var _min_value := 0
var _max_value := 0
var _first_seat := 0

@onready var _title: Label = %Title
@onready var _value_label: Label = %Value
@onready var _minus: Button = %Minus
@onready var _plus: Button = %Plus
@onready var _strip: PawnStrip = %Strip


func _ready() -> void:
	_minus.pressed.connect(_step.bind(-1))
	_plus.pressed.connect(_step.bind(1))


func configure(
	title_key: String, min_value: int, max_value: int, start_value: int, first_seat := 0
) -> void:
	_title.text = title_key
	_min_value = min_value
	_max_value = max_value
	_first_seat = first_seat
	_set_value(clampi(start_value, min_value, max_value))


func _step(delta: int) -> void:
	_set_value(clampi(value + delta, _min_value, _max_value))
	value_changed.emit(value)


func _set_value(new_value: int) -> void:
	value = new_value
	_value_label.text = str(value)
	_minus.disabled = value <= _min_value
	_plus.disabled = value >= _max_value
	_strip.show_seats(_strip_seats())


func _strip_seats() -> Array[int]:
	var seats: Array[int] = []
	for index: int in range(value):
		seats.append(_first_seat + index if each_seat else _first_seat)
	return seats
