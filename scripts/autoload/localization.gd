extends Node
## Oyunun dilini seçer: önce oyuncunun tercihi, yoksa cihaz dili, o da desteklenmiyorsa İngilizce.

const SUPPORTED: Array[String] = ["tr", "en", "de", "es", "fr", "it", "pt", "id"]
const FALLBACK := "en"
const PREFERENCE_KEY := "locale"


func _ready() -> void:
	TranslationServer.set_locale(current())


func current() -> String:
	var preferred: String = SaveStore.get_preference(PREFERENCE_KEY, "")
	if SUPPORTED.has(preferred):
		return preferred
	var device := OS.get_locale_language()
	return device if SUPPORTED.has(device) else FALLBACK


func select(locale: String) -> void:
	if not SUPPORTED.has(locale):
		return
	SaveStore.set_preference(PREFERENCE_KEY, locale)
	TranslationServer.set_locale(locale)
