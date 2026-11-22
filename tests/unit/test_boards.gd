extends GutTest
## Ayar dosyasındaki tahta listesi, tahtaya göre okunan ayarlar ve ödüllü reklamla açılan tahta
## kilidi. Gerçek kayıt dosyasına dokunmamak için ayrı bir yol kullanılır.

const TEST_PATH := "user://test_boards_save.json"
const DEFAULT_ID := "classic"
const LOCKED_ID := "four_leaf"
const MISSING_ID := "no_such_board"
const NOT_A_LIST := "four_leaf"

var _saved_path: String
var _saved_id: String


func before_each() -> void:
	_saved_path = SaveStore.path
	_saved_id = Boards.current_id
	SaveStore.path = TEST_PATH
	SaveStore.reload()


## Kaydedilen tahta, gerçek kayda yazılmasın diye yol geri alınmadan önce test kaydında seçilir.
func after_each() -> void:
	Boards.unlock(_saved_id)
	Boards.select(_saved_id)
	DirAccess.remove_absolute(TEST_PATH)
	SaveStore.path = _saved_path
	SaveStore.reload()


func test_settings_list_boards_with_default_first() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH)

	var ids: Array[String] = []
	for entry: BoardEntry in settings.boards:
		ids.append(entry.id)

	assert_eq(ids, [DEFAULT_ID, LOCKED_ID] as Array[String])
	assert_eq(settings.board.id, DEFAULT_ID)


func test_settings_read_chosen_board_layout() -> void:
	var classic := GameSettings.load_from(GameSettings.DEFAULT_PATH)

	var leaf := GameSettings.load_from(GameSettings.DEFAULT_PATH, LOCKED_ID)

	assert_eq(leaf.board.id, LOCKED_ID)
	assert_ne(leaf.board_layout.cells, classic.board_layout.cells)
	assert_ne(leaf.digest, classic.digest)


func test_settings_with_missing_board_use_default() -> void:
	var settings := GameSettings.load_from(GameSettings.DEFAULT_PATH, MISSING_ID)

	assert_eq(settings.board.id, DEFAULT_ID)


func test_every_board_has_preview_and_layout_files() -> void:
	for entry: BoardEntry in Boards.entries():
		assert_true(ResourceLoader.exists(entry.preview_path), entry.id)
		assert_true(FileAccess.file_exists(entry.layout_path), entry.id)


func test_tuning_for_board_caches_and_falls_back() -> void:
	var leaf := Tuning.for_board(LOCKED_ID)

	assert_same(Tuning.for_board(LOCKED_ID), leaf)
	assert_eq(leaf.board.id, LOCKED_ID)
	assert_same(Tuning.for_board(MISSING_ID), Tuning.settings)


func test_new_boards_start_locked_and_default_is_open() -> void:
	assert_false(Boards.is_locked(DEFAULT_ID))
	assert_true(Boards.is_locked(LOCKED_ID))
	assert_false(Boards.is_locked(MISSING_ID))


func test_select_locked_board_keeps_default() -> void:
	Boards.select(DEFAULT_ID)

	Boards.select(LOCKED_ID)

	assert_eq(Boards.current_id, DEFAULT_ID)
	assert_eq(Boards.settings().board.id, DEFAULT_ID)


func test_unlocked_board_can_be_selected_permanently() -> void:
	Boards.unlock(LOCKED_ID)
	Boards.select(LOCKED_ID)

	SaveStore.reload()

	assert_false(Boards.is_locked(LOCKED_ID))
	assert_eq(SaveStore.get_text_preference(Boards.PREFERENCE_KEY, ""), LOCKED_ID)
	assert_eq(Boards.settings().board.id, LOCKED_ID)


func test_corrupt_unlock_record_keeps_board_locked() -> void:
	SaveStore.set_preference(Boards.UNLOCKED_KEY, NOT_A_LIST)

	assert_true(Boards.is_locked(LOCKED_ID))
