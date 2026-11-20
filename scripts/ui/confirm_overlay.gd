class_name ConfirmOverlay
extends Button
## Onay katmanı: bir ileti ve bir ya da iki düğme. İptal düğmesi varsa katmanın dışına dokunmak da
## iptal sayılır; yoksa katman yalnızca onay düğmesiyle kapanır.

signal confirmed
signal cancelled

@onready var _message: Label = %Message
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	pressed.connect(_on_outside_pressed)
	_confirm_button.pressed.connect(_answer.bind(true))
	_cancel_button.pressed.connect(_answer.bind(false))
	hide()


## İletiyi ve düğmeleri çeviri anahtarlarıyla gösterir; cancel_key boşsa iptal düğmesi gizlenir.
func ask(message_key: String, confirm_key: String, cancel_key := "") -> void:
	_message.text = tr(message_key)
	_confirm_button.text = tr(confirm_key)
	_cancel_button.text = tr(cancel_key)
	_cancel_button.visible = not cancel_key.is_empty()
	show()


func _on_outside_pressed() -> void:
	if _cancel_button.visible:
		_answer(false)


func _answer(accepted: bool) -> void:
	hide()
	if accepted:
		confirmed.emit()
	else:
		cancelled.emit()
