extends Node
## Oyuncu tercihlerini ve yarım kalan oyunu cihazda tek bir JSON dosyasında saklar.
## Dosya önce geçici bir dosyaya yazılıp sonra yerine taşınır;
## yazma yarıda kalırsa eski kayıt bozulmaz.

const DEFAULT_PATH := "user://save.json"
const TEMP_SUFFIX := ".tmp"
const PREFERENCES_KEY := "preferences"
const MATCH_KEY := "match"

var path := DEFAULT_PATH

var _data := {}


func _ready() -> void:
	reload()


## Kaydı dosyadan yeniden okur. Dosya yoksa ya da bozuksa boş kayıtla başlar.
func reload() -> void:
	_data = {}
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		_data = json.data
	else:
		push_warning("Kayıt dosyası bozuk, boş kayıtla başlanıyor: %s" % path)


func get_preference(key: String, default_value: Variant) -> Variant:
	return _section(PREFERENCES_KEY).get(key, default_value)


## Metin tercihi; kayıtlı değer metin değilse default_value döner.
func get_text_preference(key: String, default_value: String) -> String:
	var value: Variant = get_preference(key, default_value)
	return value if value is String else default_value


## Enum tercihi; kayıtlı değer sayı değilse ya da values içinde yoksa default_value döner.
func get_enum_preference(key: String, values: Array, default_value: int) -> int:
	var value: Variant = get_preference(key, default_value)
	var number := int(value) if value is float or value is int else default_value
	return number if values.has(number) else default_value


func set_preference(key: String, value: Variant) -> void:
	_section(PREFERENCES_KEY)[key] = value
	_write()


## Liste tercihi (ör. açılan temalar); kayıtlı değer liste değilse boş liste. Dönen liste
## kopyadır.
func get_list_preference(key: String) -> Array:
	var value: Variant = get_preference(key, [])
	return (value as Array).duplicate() if value is Array else []


## Değeri liste tercihine ekler; listede zaten varsa bir şey yapmaz.
func add_to_list_preference(key: String, value: Variant) -> void:
	var list := get_list_preference(key)
	if not list.has(value):
		list.append(value)
		set_preference(key, list)


func has_match() -> bool:
	return not _section(MATCH_KEY).is_empty()


func load_match() -> Dictionary:
	return _section(MATCH_KEY)


func store_match(data: Dictionary) -> void:
	_data[MATCH_KEY] = data
	_write()


func clear_match() -> void:
	_data.erase(MATCH_KEY)
	_write()


func _section(key: String) -> Dictionary:
	if not _data.get(key) is Dictionary:
		_data[key] = {}
	return _data[key]


func _write() -> void:
	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Kayıt dosyası açılamadı: %s" % temp_path)
		return
	file.store_string(JSON.stringify(_data))
	file.close()
	var error := DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_error("Kayıt dosyası yerine taşınamadı: %s" % error_string(error))
