extends Node
## Yeni oyunda kullanılacak seçili tahtayı tutar. Tahtalar data/tuning.json içindeki tahta
## listesinden gelir; ilki varsayılandır. Kilitli tahtalar (needs_unlock) ödüllü reklamla açılır;
## açılan tahtaların kimlikleri kayıtta tutulur. Kilit yalnızca seçmeyi engeller: ağ oyununa
## katılan oyuncu, tahtayı açmamış olsa da hostun tahtasında oynar.

const PREFERENCE_KEY := "board"
const UNLOCKED_KEY := "unlocked_boards"

var current_id := ""


func _ready() -> void:
	_apply(SaveStore.get_text_preference(PREFERENCE_KEY, default_id()))


## Tahta açıksa seçer ve kaydeder.
func select(id: String) -> void:
	if _apply(id):
		SaveStore.set_preference(PREFERENCE_KEY, id)


## Bütün tahtalar, ayar dosyasındaki sırayla.
func entries() -> Array[BoardEntry]:
	return Tuning.settings.boards


func default_id() -> String:
	return entries()[0].id


## Tahta kilitliyse ve henüz açılmadıysa true döner; olmayan tahta kilitli sayılmaz.
func is_locked(id: String) -> bool:
	var entry := Tuning.settings.find_board(id)
	return (
		entry != null
		and entry.needs_unlock
		and not SaveStore.get_list_preference(UNLOCKED_KEY).has(id)
	)


## Tahtanın kilidini kalıcı olarak kaldırır.
func unlock(id: String) -> void:
	SaveStore.add_to_list_preference(UNLOCKED_KEY, id)


## Seçili tahtanın ayarları.
func settings() -> GameSettings:
	return Tuning.for_board(current_id)


## Tahtayı seçili yapar; bulunamazsa ya da kilitliyse varsayılan tahtaya döner. Seçilen tahta
## istenen tahtaysa true döner.
func _apply(id: String) -> bool:
	var found := Tuning.settings.find_board(id) != null and not is_locked(id)
	current_id = id if found else default_id()
	return found
