extends Node
## Tahtadaki taşların çevresindeki ışık (hale): oyuncu açıp kapatabilir, düz ya da nabız gibi
## parlayıp sönen biçimini seçebilir. İkisi de oyuncu tercihi olarak saklanır; ilk açılışta ışık
## açık ve nabızlıdır. Tercih değişince changed yayılır, tahta yeniden çizilir.

signal changed

enum Mode { STEADY, PULSE }

const ENABLED_KEY := "pawn_glow"
const MODE_KEY := "pawn_glow_mode"
## Biçim düğmelerinin çeviri anahtarı öneki (GLOW_STEADY, GLOW_PULSE).
const MODE_KEY_PREFIX := "GLOW_"


func is_enabled() -> bool:
	var value: Variant = SaveStore.get_preference(ENABLED_KEY, true)
	return value if value is bool else true


func set_enabled(enabled: bool) -> void:
	SaveStore.set_preference(ENABLED_KEY, enabled)
	changed.emit()


func current() -> Mode:
	return SaveStore.get_enum_preference(MODE_KEY, Mode.values(), Mode.PULSE) as Mode


func select(mode: Mode) -> void:
	SaveStore.set_preference(MODE_KEY, mode)
	changed.emit()


## Işık açık ve nabızlıysa true; tahta bu durumda her karede yeniden çizilir.
func is_pulsing() -> bool:
	return is_enabled() and current() == Mode.PULSE


func mode_key(mode: Mode) -> String:
	return MODE_KEY_PREFIX + str(Mode.keys()[mode])
