extends GutTest
## Taş ışığı tercihinin saklanması, nabız durumunun tercihe uyması ve değişince haber verilmesi.
## Oyuncunun kayıtlı tercihleri her testten sonra eski haline döner.

var _was_enabled := true
var _old_mode := PawnGlow.Mode.PULSE


func before_each() -> void:
	_was_enabled = PawnGlow.is_enabled()
	_old_mode = PawnGlow.current()


func after_each() -> void:
	PawnGlow.set_enabled(_was_enabled)
	PawnGlow.select(_old_mode)


func test_select_steady_stops_pulsing() -> void:
	PawnGlow.set_enabled(true)

	PawnGlow.select(PawnGlow.Mode.STEADY)

	assert_eq(PawnGlow.current(), PawnGlow.Mode.STEADY)
	assert_false(PawnGlow.is_pulsing())


func test_set_enabled_off_stops_pulsing_and_keeps_mode() -> void:
	PawnGlow.select(PawnGlow.Mode.PULSE)

	PawnGlow.set_enabled(false)

	assert_false(PawnGlow.is_enabled())
	assert_false(PawnGlow.is_pulsing())
	assert_eq(PawnGlow.current(), PawnGlow.Mode.PULSE)


func test_set_enabled_on_with_pulse_pulses() -> void:
	PawnGlow.select(PawnGlow.Mode.PULSE)

	PawnGlow.set_enabled(true)

	assert_true(PawnGlow.is_pulsing())


func test_select_emits_changed() -> void:
	watch_signals(PawnGlow)

	PawnGlow.select(PawnGlow.Mode.STEADY)

	assert_signal_emitted(PawnGlow, "changed")


func test_mode_key_uses_prefix_and_mode_name() -> void:
	var key := PawnGlow.mode_key(PawnGlow.Mode.STEADY)

	assert_eq(key, "GLOW_STEADY")
