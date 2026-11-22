class_name LogoRing
extends Control
## Ana ekran logosu: logonun çevresini saran taş karelerden bir yol ve bu yolda kare kare
## zıplayarak dolaşan, her oyuncu renginden birer taş. Köşe kareleri oyuncu renklerine boyanır.
## Yükseklik, logonun genişliğe sığdığı boya göre kendiliğinden ayarlanır.

const LOGO := preload("res://assets/images/logo.png")
## Genişliğe sığan kare sayısı.
const COLUMNS := 9
const TILE_GAP := 2.0
const PAWN_RATIO := 0.3

var _time := 0.0
## Yol karelerinin sol üst köşeleri, saat yönünde sıralı.
var _loop: Array[Vector2] = []
var _cell := 0.0
var _rows := 0


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


## Kare boyunu genişlikten, satır sayısını logonun iç boşluğa sığacağı boydan hesaplar.
func _build_loop() -> void:
	_loop.clear()
	_cell = size.x / COLUMNS
	if _cell <= 0.0:
		return
	var logo_height := (COLUMNS - 2) * _cell * BoardPainter.aspect(LOGO)
	_rows = ceili(logo_height / _cell) + 2
	custom_minimum_size.y = _rows * _cell
	for column: int in range(COLUMNS):
		_loop.append(Vector2(column, 0) * _cell)
	for row: int in range(1, _rows):
		_loop.append(Vector2(COLUMNS - 1, row) * _cell)
	for column: int in range(COLUMNS - 2, -1, -1):
		_loop.append(Vector2(column, _rows - 1) * _cell)
	for row: int in range(_rows - 2, 0, -1):
		_loop.append(Vector2(0, row) * _cell)


func _draw() -> void:
	if _loop.is_empty():
		return
	_draw_tiles()
	var inner := Rect2(Vector2.ONE * _cell, Vector2(COLUMNS - 2, _rows - 2) * _cell)
	var logo_size := Vector2(inner.size.x, inner.size.x * BoardPainter.aspect(LOGO))
	draw_texture_rect(LOGO, Rect2(inner.get_center() - logo_size / 2.0, logo_size), false)
	_draw_pawns()


func _draw_tiles() -> void:
	var skin := Skins.current
	var corners := _corner_indices()
	for index: int in range(_loop.size()):
		var tint := skin.track_color
		var seat := corners.find(index)
		if seat >= 0:
			tint = skin.track_color.lerp(skin.seat_color(seat), skin.start_tint)
		var rect := Rect2(_loop[index], Vector2.ONE * _cell).grow(-TILE_GAP / 2.0)
		var face := BoardPainter.draw_tile(self, rect, skin.track_texture, tint)
		BoardPainter.draw_inlay(self, face)


## Dört köşenin yol içindeki sırası; her köşe bir oyuncu rengini alır.
func _corner_indices() -> Array[int]:
	var columns := COLUMNS - 1
	var rows := _rows - 1
	return [0, columns, columns + rows, columns * 2 + rows]


## Taşlar yola eşit aralıkla dağılır ve her zıplama süresinde bir kare ilerler.
func _draw_pawns() -> void:
	var seats := Skins.current.seat_colors.size()
	if seats == 0:
		return
	var spacing := floori(float(_loop.size()) / seats)
	var settings := Tuning.settings
	var steps := _time / settings.logo_hop_time
	var progress := steps - floorf(steps)
	var lift := sin(progress * PI) * settings.logo_hop_height * _cell
	var face_center := BoardPainter.face_rect(Rect2(Vector2.ZERO, Vector2.ONE * _cell)).get_center()
	for seat: int in range(seats):
		var index := (floori(steps) + seat * spacing) % _loop.size()
		var from := _loop[index]
		var to := _loop[(index + 1) % _loop.size()]
		var center := from.lerp(to, progress) + face_center
		BoardPainter.draw_pawn(self, center + Vector2.UP * lift, _cell * PAWN_RATIO, seat)
