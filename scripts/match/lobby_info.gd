class_name LobbyInfo
extends RefCounted
## Ağ oyununda lobinin bir oyuncuya görünen hâli: oyuncu sayısı, taş sayısı, lobideki
## oyuncuların renkleri (katılma sırasıyla, ilki host) ve alıcının bu sıradaki yeri. Ağdan gelen
## lobi güvenilmezdir; from_dict aralıkları ve renklerin tekilliğini denetler.

const KEY_SEAT_COUNT := "seat_count"
const KEY_PAWNS := "pawns"
const KEY_COLORS := "colors"
const KEY_OWN := "own"

## Oyundaki koltuk sayısı; lobide olmayan koltuklara oyun başlarken bot oturur.
var seat_count := 0
var pawns := 0
## Lobideki oyuncuların renkleri (SeatColors renk sırası), katılma sırasıyla; ilki host.
var colors: Array[int] = []
## Alıcının colors içindeki yeri.
var own := 0


func to_dict() -> Dictionary:
	return {KEY_SEAT_COUNT: seat_count, KEY_PAWNS: pawns, KEY_COLORS: colors, KEY_OWN: own}


## Sözlükten okur; alan eksik, aralık dışı ya da renkler tekil değilse null.
static func from_dict(settings: GameSettings, data: Dictionary) -> LobbyInfo:
	var info := LobbyInfo.new()
	info.seat_count = MessageData.read_index(
		data, KEY_SEAT_COUNT, settings.min_players, settings.max_players + 1
	)
	info.pawns = MessageData.read_index(data, KEY_PAWNS, settings.min_pawns, settings.max_pawns + 1)
	var colors: Variant = MessageData.read_ints(data, KEY_COLORS)
	if info.seat_count == MessageData.INVALID or info.pawns == MessageData.INVALID:
		return null
	if colors == null or not _are_valid(colors, info.seat_count, color_count(settings)):
		return null
	info.colors = colors
	info.own = MessageData.read_index(data, KEY_OWN, 0, info.colors.size())
	return null if info.own == MessageData.INVALID else info


## Seçilebilecek renk sayısı: tahtadaki ev sayısı.
static func color_count(settings: GameSettings) -> int:
	return settings.board_layout.homes.size()


static func _are_valid(colors: Array[int], seat_count: int, count: int) -> bool:
	if colors.is_empty() or colors.size() > seat_count:
		return false
	var seen: Array[int] = []
	for color: int in colors:
		if color < 0 or color >= count or seen.has(color):
			return false
		seen.append(color)
	return true
