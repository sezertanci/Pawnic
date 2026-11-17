class_name HomeBackdrop
extends Control
## Ana ekran arka planı: ekranın kenarında soluk kareli bir yol ve bu yolda kare kare
## zıplayarak dolaşan, her oyuncu renginden birer taş. Ortası düğmelere boş kalır.

## Ekran genişliğine sığan kare sayısı.
const COLUMNS := 8
## Kenardan içeri boşluk (kare boyuna oranla).
const INSET := 0.25
const TILE_GAP := 4.0
const TILE_ALPHA := 0.07
## Köşe kareleri oyuncu renginde boyanır.
const CORNER_ALPHA := 0.22
const PAWN_RATIO := 0.28
## Taşın bir kareden ötekine zıplama süresi (saniye) ve yüksekliği (kare boyuna oranla).
const HOP_SEC := 0.7
const HOP_HEIGHT := 0.35

var _time := 0.0
## Kenardaki yol karelerinin sol üst köşeleri, saat yönünde sıralı.
var _loop: Array[Vector2] = []
var _cell := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(_build_loop)
	_build_loop()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _build_loop() -> void:
	_loop.clear()
	_cell = size.x / (COLUMNS + INSET * 2.0)
	if _cell <= 0.0:
		return
	var rows := floori(size.y / _cell - INSET * 2.0)
	var origin := Vector2(_cell * INSET, (size.y - rows * _cell) / 2.0)
	for column: int in range(COLUMNS):
		_loop.append(origin + Vector2(column, 0) * _cell)
	for row: int in range(1, rows):
		_loop.append(origin + Vector2(COLUMNS - 1, row) * _cell)
	for column: int in range(COLUMNS - 2, -1, -1):
		_loop.append(origin + Vector2(column, rows - 1) * _cell)
	for row: int in range(rows - 2, 0, -1):
		_loop.append(origin + Vector2(0, row) * _cell)


func _draw() -> void:
	if _loop.is_empty():
		return
	var corners := _corner_indices()
	for index: int in range(_loop.size()):
		var color := Color(Skins.current.track_color, TILE_ALPHA)
		var seat := corners.find(index)
		if seat >= 0:
			color = Color(Skins.current.seat_color(seat), CORNER_ALPHA)
		var rect := Rect2(_loop[index], Vector2.ONE * _cell).grow(-TILE_GAP / 2.0)
		BoardPainter.draw_tile(self, rect, color)
	_draw_pawns()


## Dört köşenin yol içindeki sırası; her köşe bir oyuncu rengini alır.
func _corner_indices() -> Array[int]:
	var columns := COLUMNS - 1
	var rows := floori((_loop.size() - columns * 2) / 2.0)
	return [0, columns, columns + rows, columns * 2 + rows]


## Taşlar yola eşit aralıkla dağılır ve her HOP_SEC'te bir kare ilerler.
func _draw_pawns() -> void:
	var seats := Skins.current.seat_colors.size()
	var spacing := floori(float(_loop.size()) / seats)
	var steps := _time / HOP_SEC
	var progress := steps - floorf(steps)
	var lift := sin(progress * PI) * HOP_HEIGHT * _cell
	for seat: int in range(seats):
		var index := (floori(steps) + seat * spacing) % _loop.size()
		var from := _loop[index]
		var to := _loop[(index + 1) % _loop.size()]
		var center := from.lerp(to, progress) + Vector2.ONE * _cell / 2.0
		BoardPainter.draw_pawn(
			self, center + Vector2.UP * lift, _cell * PAWN_RATIO, Skins.current.seat_color(seat)
		)
