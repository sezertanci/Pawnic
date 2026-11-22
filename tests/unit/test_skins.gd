extends GutTest
## Görünüm ekranının kartlarını kuran tema listesi, her temanın kart görseli ve ödüllü reklamla
## açılan tema kilidi. Gerçek kayıt dosyasına dokunmamak için ayrı bir yol kullanılır.

const TEST_PATH := "user://test_skins_save.json"
const LOCKED_ID := "wood"
const LOCKED_IDS: Array[String] = ["neon", "wood"]
const NOT_A_LIST := "wood"

var _saved_path: String
var _saved_id: String


func before_each() -> void:
	_saved_path = SaveStore.path
	_saved_id = Skins.current_id
	SaveStore.path = TEST_PATH
	SaveStore.reload()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	SaveStore.path = _saved_path
	SaveStore.reload()
	Skins.select(_saved_id)


func test_ids_lists_default_first_then_others_by_name() -> void:
	var ids := Skins.ids()

	assert_eq(ids, PackedStringArray([Skins.DEFAULT_ID, "neon", "wood"]))


func test_every_skin_has_preview_texture() -> void:
	for id: String in Skins.ids():
		var skin := Skins.find(id)

		assert_not_null(skin, id)
		assert_not_null(skin.preview_texture, id)


func test_new_themes_start_locked_and_default_is_open() -> void:
	for id: String in Skins.ids():
		assert_eq(Skins.is_locked(id), LOCKED_IDS.has(id), id)


func test_unlock_opens_theme_permanently() -> void:
	Skins.unlock(LOCKED_ID)
	SaveStore.reload()

	assert_false(Skins.is_locked(LOCKED_ID))


func test_select_locked_theme_keeps_default() -> void:
	Skins.select(Skins.DEFAULT_ID)

	Skins.select(LOCKED_ID)

	assert_eq(Skins.current_id, Skins.DEFAULT_ID)


func test_select_unlocked_theme_applies_it() -> void:
	Skins.unlock(LOCKED_ID)

	Skins.select(LOCKED_ID)

	assert_eq(Skins.current_id, LOCKED_ID)


func test_corrupt_unlock_record_keeps_theme_locked() -> void:
	SaveStore.set_preference(Skins.UNLOCKED_KEY, NOT_A_LIST)

	assert_true(Skins.is_locked(LOCKED_ID))
