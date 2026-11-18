extends Node
## Oyunun dilini seçer: önce oyuncunun tercihi, yoksa cihaz dili, o da desteklenmiyorsa İngilizce.

const SUPPORTED: Array[String] = ["tr", "en", "de", "es", "fr", "it", "pt", "id"]
## Yedek dil project.godot içindeki ayardan okunur.
const FALLBACK_SETTING := "internationalization/locale/fallback"
const PREFERENCE_KEY := "locale"


func _ready() -> void:
	TranslationServer.set_locale(current())


func current() -> String:
	var preferred := SaveStore.get_text_preference(PREFERENCE_KEY, "")
	if SUPPORTED.has(preferred):
		return preferred
	var device := OS.get_locale_language()
	if SUPPORTED.has(device):
		return device
	return str(ProjectSettings.get_setting(FALLBACK_SETTING))


func select(locale: String) -> void:
	if not SUPPORTED.has(locale):
		return
	SaveStore.set_preference(PREFERENCE_KEY, locale)
	TranslationServer.set_locale(locale)
