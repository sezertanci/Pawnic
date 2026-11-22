extends Node
## Seçili tahta temasını yükler ve değişince haber verir. Temalar themes/skins/ klasöründeki
## .tres dosyalarıdır; temanın kimliği dosya adıdır. Kilitli temalar (needs_unlock) ödüllü reklamla
## açılır; açılan temaların kimlikleri kayıtta tutulur.

signal changed

const SKINS_DIR := "res://themes/skins/"
const SKIN_EXTENSION := ".tres"
const DEFAULT_ID := "classic"
const PREFERENCE_KEY := "theme"
const UNLOCKED_KEY := "unlocked_themes"

var current: BoardSkin
var current_id := ""


func _ready() -> void:
	_load(SaveStore.get_text_preference(PREFERENCE_KEY, DEFAULT_ID))


func select(id: String) -> void:
	if _load(id):
		SaveStore.set_preference(PREFERENCE_KEY, id)


## Klasördeki temaların kimlikleri: önce varsayılan tema, sonra ötekiler ada göre sıralı.
func ids() -> PackedStringArray:
	var found: Array[String] = []
	for file: String in ResourceLoader.list_directory(SKINS_DIR):
		if file.ends_with(SKIN_EXTENSION) and file != DEFAULT_ID + SKIN_EXTENSION:
			found.append(file.trim_suffix(SKIN_EXTENSION))
	found.sort()
	found.push_front(DEFAULT_ID)
	return PackedStringArray(found)


## Tema kilitliyse ve henüz açılmadıysa true döner.
func is_locked(id: String) -> bool:
	return find(id).needs_unlock and not _unlocked().has(id)


## Temanın kilidini kalıcı olarak kaldırır.
func unlock(id: String) -> void:
	var unlocked := _unlocked()
	if not unlocked.has(id):
		unlocked.append(id)
		SaveStore.set_preference(UNLOCKED_KEY, unlocked)


## Kimliği verilen temayı seçmeden yükler (ör. önizleme görseli için).
func find(id: String) -> BoardSkin:
	return load(_path(id)) as BoardSkin


## Temayı yükler; bulunamazsa ya da kilitliyse varsayılan temaya döner. Yüklenen tema istenen
## temaysa true döner.
func _load(id: String) -> bool:
	var found := ResourceLoader.exists(_path(id)) and not is_locked(id)
	var loaded_id := id if found else DEFAULT_ID
	var skin := find(loaded_id)
	if skin == null:
		push_error("Tema yüklenemedi: %s" % _path(loaded_id))
		return false
	current = skin
	current_id = loaded_id
	RenderingServer.set_default_clear_color(current.background_color)
	changed.emit()
	return found


## Açılan temaların kimlikleri; kayıttaki değer liste değilse boş liste.
func _unlocked() -> Array:
	var value: Variant = SaveStore.get_preference(UNLOCKED_KEY, [])
	return (value as Array).duplicate() if value is Array else []


func _path(id: String) -> String:
	return SKINS_DIR + id + SKIN_EXTENSION
