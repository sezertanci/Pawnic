class_name BoardLayout
extends RefCounted
## Tahtanın yapısı: kareler, kareler arasındaki bağlantılar ve koltuklar.
## data/boards/*.json dosyasından okunur; tahta tasarımı değişince yalnızca dosya değişir.
## Kare kimlikleri "yol:sıra" biçimindedir (ör. "ring:8"). Dosya biçimi README'de anlatılır.

## Bağlantının ne zaman kullanılacağı:
## FORCED: bağlantının koltukları bu kareden her zaman bağlantıya girer (ör. ev yolu girişi).
## CHOICE: taş kareden geçerken ya da kareden başlarken oyuncu yolu seçer.
## EXACT: bağlantıya yalnızca hamleye bu karede duran taş girebilir; oyuncu yolu seçer.
enum LinkMode { FORCED, CHOICE, EXACT }

const NO_SQUARE := -1
const NO_SEAT := -1
const MODE_BY_NAME := {
	"forced": LinkMode.FORCED,
	"choice": LinkMode.CHOICE,
	"exact": LinkMode.EXACT,
}
const KEY_PATHS := "paths"
const KEY_SEATS := "seats"


## İki kare arasındaki ek yol.
class Link:
	var from: int
	var to: int
	## Bağlantıyı kullanabilen koltuklar; boşsa herkes.
	var seats: Array[int] = []
	var mode: BoardLayout.LinkMode

	func allows(seat: int) -> bool:
		return seats.is_empty() or seats.has(seat)


var names: Array[String] = []
var cells: Array[Vector2i] = []
## Yalnızca bir koltuğa ait karelerde (ör. ev yolu) o koltuk, ortak karelerde NO_SEAT.
var owners: Array[int] = []
var safe: Array[bool] = []
## Hız karesinin değeri: artı ileri, eksi geri gidilecek kare sayısı; hız karesi değilse 0.
var speed: Array[int] = []
## Karenin kendi yolundaki sonraki ve önceki kare.
var next_squares: Array[int] = []
var prev_squares: Array[int] = []
var links: Array[Link] = []
var starts: Array[int] = []
var homes: Array[int] = []
var shortcuts: Array[int] = []
## Başlangıç alanlarının hücre cinsinden merkezleri.
var bases: Array[Vector2] = []
var grid_size := Vector2i.ZERO

var _index_by_name: Dictionary[String, int] = {}
## Koltuk başına, kareden eve en kısa adım sayısı.
var _home_distances: Array[Dictionary] = []
## Dosyada tanımsız bir kareye başvurulduysa ya da bir çıkış karesi güvenli değilse true olur;
## tahta yüklenmez.
var _failed := false


## Tahtayı dosyadan okur; dosya bozuksa ya da bir çıkış karesi güvenli değilse null döner.
static func load_from(path: String) -> BoardLayout:
	var required: Array[String] = [KEY_PATHS, KEY_SEATS]
	var root := JsonData.read(path, required)
	if root.is_empty():
		return null
	var layout := BoardLayout.new()
	for path_data: Dictionary in root[KEY_PATHS]:
		layout._add_path(path_data)
	for link_data: Dictionary in root.get("links", []):
		layout._add_link(link_data)
	layout._mark(root.get("safe", []), layout.safe)
	layout._set_speeds(root.get("speed", {}))
	for seat_data: Dictionary in root[KEY_SEATS]:
		layout._add_seat(seat_data)
	layout._check_safe_starts()
	if layout._failed:
		return null
	layout._finish()
	return layout


func index_of(square_name: String) -> int:
	return _index_by_name.get(square_name, NO_SQUARE)


func square_count() -> int:
	return names.size()


func seat_count() -> int:
	return starts.size()


func is_private(square: int) -> bool:
	return owners[square] != NO_SEAT


## Koltuğun bu kareden bir adımda gidebileceği kareler.
## first_step, adımın hamlenin ilk adımı olduğunu (taşın bu karede durduğunu) belirtir.
func steps_from(square: int, seat: int, first_step: bool) -> Array[int]:
	var result: Array[int] = []
	if next_squares[square] != NO_SQUARE:
		result.append(next_squares[square])
	for link: Link in links:
		if link.from != square or not link.allows(seat):
			continue
		if link.mode == LinkMode.FORCED:
			var forced: Array[int] = [link.to]
			return forced
		if link.mode == LinkMode.CHOICE or first_step:
			result.append(link.to)
	return result


## Seçim sorulmadan gidilen kare: zorunlu bağlantı varsa o, yoksa yolun sonraki karesi.
func default_step(square: int, seat: int) -> int:
	for link: Link in links:
		if link.from == square and link.mode == LinkMode.FORCED and link.allows(seat):
			return link.to
	return next_squares[square]


## Kareden eve en kısa adım sayısı; eve ulaşılamıyorsa NO_SQUARE.
func home_distance(seat: int, square: int) -> int:
	return _home_distances[seat].get(square, NO_SQUARE)


func _add_path(data: Dictionary) -> void:
	var loop := bool(data.get("loop", false))
	var points: Array = data["points"].duplicate()
	if loop:
		# Son noktadan ilk noktaya dönen kenar da açılır; ilk hücre iki kez yazılmaz.
		points.append(points[0])
	var path_cells := _expand(points)
	if loop:
		path_cells.pop_back()
	var owner := int(data.get("owner", NO_SEAT))
	var first := names.size()
	for index: int in range(path_cells.size()):
		_append_square("%s:%d" % [data["id"], index], path_cells[index], owner)
		if index > 0:
			next_squares[first + index - 1] = first + index
			prev_squares[first + index] = first + index - 1
	if loop:
		var last := names.size() - 1
		next_squares[last] = first
		prev_squares[first] = last


func _append_square(square_name: String, cell: Vector2i, owner: int) -> void:
	_index_by_name[square_name] = names.size()
	names.append(square_name)
	cells.append(cell)
	owners.append(owner)
	safe.append(false)
	speed.append(0)
	next_squares.append(NO_SQUARE)
	prev_squares.append(NO_SQUARE)


func _add_link(data: Dictionary) -> void:
	var link := Link.new()
	link.from = _require(data["from"])
	link.to = _require(data["to"])
	if link.from == NO_SQUARE or link.to == NO_SQUARE:
		return
	link.mode = MODE_BY_NAME[data.get("mode", "choice")]
	for seat: Variant in data.get("seats", []):
		link.seats.append(int(seat))
	links.append(link)
	# Geri giden taş, yolun ilk karesinden bağlantının geldiği kareye döner.
	if prev_squares[link.to] == NO_SQUARE:
		prev_squares[link.to] = link.from


func _mark(square_names: Array, flags: Array[bool]) -> void:
	for square_name: Variant in square_names:
		var square := _require(square_name)
		if square != NO_SQUARE:
			flags[square] = true


func _set_speeds(values: Dictionary) -> void:
	for square_name: Variant in values:
		var square := _require(square_name)
		if square != NO_SQUARE:
			speed[square] = int(values[square_name])


func _add_seat(data: Dictionary) -> void:
	starts.append(_require(data["start"]))
	homes.append(_require(data["home"]))
	shortcuts.append(_require(data["shortcut"]) if data.has("shortcut") else NO_SQUARE)
	var base: Array = data["base"]
	bases.append(Vector2(float(base[0]), float(base[1])))


func _require(square_name: Variant) -> int:
	var square := index_of(str(square_name))
	if square == NO_SQUARE:
		push_error("Tahta dosyasında tanımsız kare: %s" % square_name)
		_failed = true
	return square


## Kural motoru çıkış karesini güvenli sayar: çıkan taş denetimsiz konur, aynı renk taşlar üst
## üste durabilir ve orada duran rakip taş çarpılmaz. Bu yüzden her çıkış karesi güvenli olmalıdır.
func _check_safe_starts() -> void:
	for start: int in starts:
		if start != NO_SQUARE and not safe[start]:
			push_error("Tahta dosyasında çıkış karesi güvenli değil: %s" % names[start])
			_failed = true


func _finish() -> void:
	for cell: Vector2i in cells:
		grid_size = grid_size.max(cell + Vector2i.ONE)
	for seat: int in range(seat_count()):
		_home_distances.append(_distances_to(seat, homes[seat]))


## Eve doğru geriye genişleyerek her karenin eve uzaklığını bulur.
func _distances_to(seat: int, home: int) -> Dictionary[int, int]:
	# Kare -> o kareye bir adımda gelinebilen kareler (Array[int]).
	var incoming: Dictionary[int, Array] = {}
	for square: int in range(square_count()):
		for target: int in steps_from(square, seat, true):
			if not incoming.has(target):
				var sources: Array[int] = []
				incoming[target] = sources
			incoming[target].append(square)
	var distances: Dictionary[int, int] = {home: 0}
	var queue: Array[int] = [home]
	while not queue.is_empty():
		var square: int = queue.pop_front()
		for source: int in incoming.get(square, []):
			if not distances.has(source):
				distances[source] = distances[square] + 1
				queue.append(source)
	return distances


## Köşe noktalarını sırayla birleştirip yolun hücrelerini çıkarır.
## Ardışık noktalar yatay, dikey ya da tam çapraz hizada olmalıdır.
static func _expand(points: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for point: Array in points:
		var corner := Vector2i(int(point[0]), int(point[1]))
		if result.is_empty():
			result.append(corner)
			continue
		var delta: Vector2i = corner - result.back()
		if delta.x != 0 and delta.y != 0 and absi(delta.x) != absi(delta.y):
			push_error("Yol noktaları düz hizada değil: %s" % [points])
			return result
		while result.back() != corner:
			result.append(result.back() + delta.sign())
	return result
