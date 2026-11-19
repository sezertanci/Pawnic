extends Node
## Tek oyunculu modda oyuncunun yeni oyun ekranında en son seçtiği renk (kaplamadaki renk
## sırası); oyuncu tercihi olarak saklanır. İlk açılışta yeşil seçilidir.

const PREFERENCE_KEY := "player_color"
## Yeşil; renk seçimi gelmeden önce oyuncu hep bu renkte oynuyordu.
const DEFAULT_COLOR := 2


func current() -> int:
	return SaveStore.get_enum_preference(PREFERENCE_KEY, colors(), DEFAULT_COLOR)


func select(color: int) -> void:
	SaveStore.set_preference(PREFERENCE_KEY, color)


## Seçilebilecek renkler (kaplamadaki renk sırası).
func colors() -> Array[int]:
	return SeatColors.identity(Skins.current.seat_colors.size())
