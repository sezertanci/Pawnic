class_name BoardLayout
extends RefCounted
## Tahtanın yapısı: kareler, kareler arasındaki bağlantılar ve koltuklar.
## data/boards/*.json dosyasından okunur; tahta tasarımı değişince yalnızca dosya değişir.
## Kareler düz yollarla (points) ya da tek tek yazılmış ondalık yerlerle (squares) verilir.
## Kare kimlikleri "yol:sıra" biçimindedir (ör. "ring:8"). Dosya biçimi README'de anlatılır.

## Bağlantının ne zaman kullanılacağı:
## FORCED: bağlantının koltukları bu kareden her zaman bağlantıya girer (ör. ev yolu girişi).
## CHOICE: taş kareden geçerken ya da kareden başlarken oyuncu yolu seçer.
## EXACT: bağlantıya yalnızca hamleye bu karede duran taş girebilir; oyuncu yolu seçer.
enum LinkMode { FORCED, CHOICE, EXACT }
## Karelerin çizimdeki biçimi; kural motoru kullanmaz.
enum SquareShape { SQUARE, CIRCLE }

const NO_SQUARE := -1
const NO_SEAT := -1
const MODE_BY_NAME := {
	"forced": LinkMode.FORCED,
	"choice": LinkMode.CHOICE,
	"exact": LinkMode.EXACT,
}
const SHAPE_BY_NAME := {
	"square": SquareShape.SQUARE,
	"circle": SquareShape.CIRCLE,
}
const KEY_PATHS := "paths"
const KEY_SEATS := "seats"
const KEY_SQUARES := "squares"


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
## Karelerin hücre cinsinden sol üst köşeleri; her kare bir hücre boyundadır. Düz yollarda tam
## sayı, serbest yerleşimde (squares) ondalık olabilir.
var cells: Array[Vector2] = []
var square_shape := SquareShape.SQUARE
## Ortadaki bitiş alanının hücre cinsinden dış çizgisi; boşsa bitiş karelerini kapsayan kare alan.
var center_outline := PackedVector2Array()
## Dönen okun yarıçapının bitiş alanının yarı boyuna oranı; 0 ise arayüzün varsayılanı kullanılır.
var spinner_ratio := 0.0
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
## Patikanın çıkış karesine vardığı yön (hücre cinsinden birim yön, kareden dışarı bakar); dosyada
## approach verilmemişse Vector2.ZERO ve patika alandan kareye düz bir S çizer. Yalnızca çizim
## kullanır.
var base_approaches: Array[Vector2] = []
## Tahtanın hücre cinsinden boyu: dosyada size verilmişse o, yoksa kareleri kapsayan alan.
var grid_size := Vector2.ZERO

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
	layout._read_drawing(root)
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
	var path_cells := _path_cells(data, loop)
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


## Yolun hücreleri: squares verilmişse tek tek yazılmış yerler, yoksa points köşelerinin açılımı.
func _path_cells(data: Dictionary, loop: bool) -> Array[Vector2]:
	if data.has(KEY_SQUARES):
		var cells_list: Array[Vector2] = []
		for point: Array in data[KEY_SQUARES]:
			cells_list.append(_vector(point))
		return cells_list
	var points: Array = data["points"].duplicate()
	if loop:
		# Son noktadan ilk noktaya dönen kenar da açılır; ilk hücre iki kez yazılmaz.
		points.append(points[0])
	var expanded := _expand(points)
	if loop:
		expanded.pop_back()
	return expanded


func _append_square(square_name: String, cell: Vector2, owner: int) -> void:
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
	bases.append(_vector(data["base"]))
	base_approaches.append(_vector(data["approach"]) if data.has("approach") else Vector2.ZERO)


## Çizimle ilgili isteğe bağlı alanlar: kare biçimi, tahta boyu, bitiş alanının çizgisi ve dönen
## okun yarıçap oranı.
func _read_drawing(root: Dictionary) -> void:
	var shape_name: String = root.get("square_shape", "square")
	if not SHAPE_BY_NAME.has(shape_name):
		push_error("Tahta dosyasında tanımsız kare biçimi: %s" % shape_name)
		_failed = true
		return
	square_shape = SHAPE_BY_NAME[shape_name]
	if root.has("size"):
		grid_size = _vector(root["size"])
	for point: Array in root.get("center", []):
		center_outline.append(_vector(point))
	spinner_ratio = float(root.get("spinner_ratio", 0.0))


static func _vector(point: Array) -> Vector2:
	return Vector2(float(point[0]), float(point[1]))


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
	if grid_size == Vector2.ZERO:
		for cell: Vector2 in cells:
			grid_size = grid_size.max(cell + Vector2.ONE)
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
static func _expand(points: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var last := Vector2i.ZERO
	for point: Array in points:
		var corner := Vector2i(int(point[0]), int(point[1]))
		if result.is_empty():
			last = corner
			result.append(Vector2(corner))
			continue
		var delta: Vector2i = corner - last
		if delta.x != 0 and delta.y != 0 and absi(delta.x) != absi(delta.y):
			push_error("Yol noktaları düz hizada değil: %s" % [points])
			return result
		while last != corner:
			last += delta.sign()
			result.append(Vector2(last))
	return result
