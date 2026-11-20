extends GutTest
## Onay katmanı: iki düğmeli soruda dışarı dokunmak iptaldir; tek düğmeli soru yalnızca onayla
## kapanır.

const OVERLAY_SCENE := preload("res://scenes/components/confirm_overlay.tscn")

var _overlay: ConfirmOverlay


func before_each() -> void:
	_overlay = OVERLAY_SCENE.instantiate()
	add_child_autofree(_overlay)
	watch_signals(_overlay)


func test_confirm_button_confirms_and_hides() -> void:
	_overlay.ask("LEAVE_MATCH_CONFIRM", "LEAVE", "CANCEL")

	(_overlay.get_node("%ConfirmButton") as Button).pressed.emit()

	assert_signal_emitted(_overlay, "confirmed")
	assert_false(_overlay.visible)


func test_outside_press_cancels_two_button_question() -> void:
	_overlay.ask("LEAVE_MATCH_CONFIRM", "LEAVE", "CANCEL")

	_overlay.pressed.emit()

	assert_signal_emitted(_overlay, "cancelled")
	assert_false(_overlay.visible)


func test_single_button_question_ignores_outside_press() -> void:
	_overlay.ask("GAME_ENDED", "OK")

	_overlay.pressed.emit()

	assert_signal_not_emitted(_overlay, "cancelled")
	assert_false((_overlay.get_node("%CancelButton") as Button).visible)
	assert_true(_overlay.visible)
