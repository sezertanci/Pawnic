extends GutTest
## Cihaz kaydının birim testleri. Gerçek kayıt dosyasına dokunmamak için ayrı bir yol kullanılır.

const SaveStoreScript := preload("res://scripts/autoload/save_store.gd")
const TEST_PATH := "user://test_save.json"

var _store: SaveStoreScript


func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	_store = SaveStoreScript.new()
	_store.path = TEST_PATH
	_store.reload()


func after_each() -> void:
	_store.free()
	DirAccess.remove_absolute(TEST_PATH)


func test_preference_survives_reload() -> void:
	_store.set_preference("locale", "de")

	_store.reload()

	assert_eq(_store.get_preference("locale", ""), "de")


func test_missing_preference_returns_default() -> void:
	assert_eq(_store.get_preference("theme", "classic"), "classic")


func test_stored_match_survives_reload_and_clears() -> void:
	_store.store_match({"version": 1})
	_store.reload()
	assert_true(_store.has_match())

	_store.clear_match()
	_store.reload()

	assert_false(_store.has_match())


func test_corrupt_file_starts_empty() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{bozuk")
	file.close()

	_store.reload()

	assert_false(_store.has_match())
