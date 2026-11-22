class_name BoardView
extends Control
## Tahtayı ve taşları çizer, seçilebilir bir taşa ya da kareye dokunulduğunu bildirir.
## Karelerin yeri tahta dosyasındaki (BoardLayout) hücrelerden gelir. Hamle animasyonunu
## MoveAnimationBuilder kurar, burada yalnızca oynatılır.
## Renkler seçili temadan (Skins) okunur.

signal pawn_pressed(pawn: int)
signal square_pressed(square: int)

const PAWN_RATIO := 0.34
const STACK_SPREAD := 0.22
const STACK_SHRINK := 0.65
const BASE_COLUMNS := 3
const BASE_SPREAD := 0.95
## Tepsideki yerlerin alt kenardan uzaklaşsın diye yukarı kaydırılması (kare boyuna oranla).
const BASE_LIFT := 0.2
## Başlangıç tepsisindeki altlığın taş tabanına oranla genişliği.
const SOCKET_SCALE := 0.9
const HIT_RATIO := 0.6
const MARK_RATIO := 0.4
## Hız karesindeki sayının çizildiği alanın kare yüzüne oranla genişliği.
const NUMBER_SCALE := 1.25
const LINE_WIDTH := BoardPainter.LINE_WIDTH
const HIGHLIGHT_WIDTH := 4.0
const CENTER := BoardTurn.CELL_CENTER
## Gölge elipsinin dikey basıklığı.
const SHADOW_FLATTEN := 0.45
## Karedeki sembollerin (kalkan, ev) yarı genişliği ve yarı yüksekliği (yarıçapa oranla).
const MARK_HALF := Vector2(0.8, 1.0)
## Kısayol evinin yarı boyu: gövdesi kalkan kadar geniş görünsün diye kalkandan geniş tutulur.
const HOUSE_HALF := Vector2(1.05, 0.95)
## Işık kuyruğunun taşın altındaki saydamlığı, rengin beyaza yaklaşma oranı ve solmanın üssü
## (1'den küçük üs, kuyruğun uca kadar daha uzun süre opak kalmasını sağlar).
const TRAIL_ALPHA := 1.0
const TRAIL_FADE_POWER := 0.5
const TRAIL_LIGHTEN := 0.5
## Kısayol karesindeki evin çizgi kalınlığı (kare boyuna oranla).
const HOUSE_LINE_RATIO := 0.03

var board: BoardState:
	set(value):
		board = value
		_update_turns()
## Ekranın altında görünecek koltuk; tahta bu koltuğun başlangıç alanı alta gelecek biçimde
## döndürülerek çizilir (BoardTurn). NO_SEAT iken tahta dosyadaki gibi çizilir.
var bottom_seat := BoardLayout.NO_SEAT:
	set(value):
		bottom_seat = value
		_update_turns()
## Koltukların renkleri, koltuk sırasıyla (SeatColors); boşsa her koltuk kendi sırasındaki rengi
## alır.
var seat_colors: Array[int] = []
var selectable: Array[int] = []
## Yol ayrımında varış karesi seçilirken dokunulabilecek kareler.
var selectable_squares: Array[int] = []
## Hamlesi seçilmekte olan taş; farklı renkte halkayla gösterilir.
var selected_pawn := Move.NO_PAWN
## Seçili kartla oynanabilecek hamlelerin yolları (kare sırasıyla, son kare varış) ve hamleyi
## yapacak oyuncu; yollar onun renginde önizlenir.
var preview_paths: Array[PackedInt32Array] = []
var preview_seat := BoardLayout.NO_SEAT
## Taş animasyonlarının hız çarpanı.
var speed_scale := 1.0
## Sırası gelen koltuk; ortadaki dönen ok bu renkte çizilir. NO_SEAT iken ok gösterilmez.
var turn_seat := BoardLayout.NO_SEAT:
	set(value):
		turn_seat = value
		_update_spinner()

var _centers: Array[Vector2] = []
## Evdeki taşlar, eve geliş sırasıyla; yamuktaki dizilim bu sıraya göredir.
var _home_order: Array[int] = []
var _radii: Array[float] = []
## Oynanmakta olan hamlenin animasyonu; yoksa null.
var _animation: PawnAnimation
## Ortadaki dönen sıra oku; turn_seat NO_SEAT iken gizlidir.
var _spinner := TurnSpinner.new()
## Tahtanın ekrandaki saat yönündeki çeyrek tur sayısı (bottom_seat'ten hesaplanır).
var _turns := 0
## Koltukların başlangıç tepsisi merkezleri, döndürülmüş tahtada hücre cinsinden (BoardTurn).
var _base_centers: Array[Vector2] = []
var _tween: Tween
var _time := 0.0
## Koltuk -> bitiş yamuğunun parlaklığı (1 tam parlak, 0 normal); taş eve girince 1'den söner.
var _glows: Dictionary[int, float] = {}


func _ready() -> void:
	Skins.changed.connect(queue_redraw)
	Skins.changed.connect(_update_spinner)
	add_child(_spinner)
	_update_spinner()


## Seçilebilir bir şey ya da yol önizlemesi varken dalga ve varış ışığı oynasın diye tahta her
## karede yeniden çizilir.
func _process(_delta: float) -> void:
	var waving := not selectable.is_empty() or not selectable_squares.is_empty()
	if waving or not preview_paths.is_empty():
		queue_redraw()


func _draw() -> void:
	if board == null or minf(size.x, size.y) <= 0.0:
		return
	var active := _active_seats()
	_draw_links(active)
	_draw_home_tray(active)
	var area := _home_area()
	_spinner.position = area.get_center()
	_spinner.half = area.size.x / 2.0
	for square: int in range(board.layout.square_count()):
		if _is_visible(square, active):
			_draw_square(square, active)
	_draw_home_halos()
	for seat: int in active:
		_draw_base_link(seat)
		_draw_base(seat)
	_draw_previews()
	_layout_pawns()
	_draw_pawns()


## Koltuğun rengi (kaplamadaki renk sırası).
func color_of(seat: int) -> int:
	return seat if seat_colors.is_empty() else seat_colors[seat]


func _seat_color(seat: int) -> Color:
	return Skins.current.seat_color(color_of(seat))


## Hamleden önceki taş merkezleri; hamle uygulanmadan alınıp animate_move'a verilir.
func pawn_centers() -> Array[Vector2]:
	return _centers.duplicate()


## Hamle uygulandıktan sonra çağrılır; taşları eski yerlerinden yeni yerlerine canlandırır.
## path, BoardState.move_path ile hamleden önce alınan karelerdir.
func animate_move(move: Move, path: Array[int], before: Array[Vector2]) -> void:
	if before.size() != board.positions.size():
		queue_redraw()
		return
	_layout_pawns()
	var builder := MoveAnimationBuilder.new(board, _centers, _cell_size(), _square_center)
	var animation := builder.build(move, path, before)
	if animation.duration() <= 0.0:
		queue_redraw()
		return
	_animation = animation
	_time = 0.0
	# Başlangıç anındaki sesler (ör. ışınlanma) tween'in ilk adımını beklemez.
	for cue: StringName in animation.cues_between(-INF, _time):
		Sound.play(cue)
	_tween = create_tween().set_speed_scale(speed_scale)
	_tween.tween_method(_set_time, 0.0, animation.duration(), animation.duration())
	await _tween.finished
	_animation = null
	queue_redraw()


## Süren animasyonu yarıda keser (oyundan ana ekrana dönülünce); bekleyen animate_move dönmez.
func stop_animation() -> void:
	if _tween != null:
		_tween.kill()
	_animation = null
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press == null or not press.pressed or press.button_index != MOUSE_BUTTON_LEFT:
		return
	var pawn := _selectable_at(press.position)
	if pawn == Move.NO_PAWN:
		pawn = _selectable_base_pawn_at(press.position)
	if pawn != Move.NO_PAWN:
		accept_event()
		Sound.play(Sound.TAP)
		pawn_pressed.emit(pawn)
		return
	for square: int in selectable_squares:
		if _cell_rect(board.layout.cells[square]).has_point(press.position):
			accept_event()
			Sound.play(Sound.TAP)
			square_pressed.emit(square)
			return


func _update_turns() -> void:
	var facing := board != null and bottom_seat != BoardLayout.NO_SEAT
	_turns = BoardTurn.turns_to_bottom(board.layout, bottom_seat) if facing else 0
	_base_centers.clear()
	if board != null:
		for seat: int in range(board.layout.bases.size()):
			_base_centers.append(BoardTurn.base_center(board.layout, seat, _turns))
	queue_redraw()


func _cell_size() -> float:
	var grid := BoardTurn.grid(Vector2(board.layout.grid_size), _turns)
	return minf(size.x / grid.x, size.y / grid.y)


## Çizilen tahtanın bu düğüm içindeki yeri ve boyutu (piksel); tahta yoksa boş dikdörtgen.
func grid_rect() -> Rect2:
	if board == null:
		return Rect2()
	return Rect2(_grid_origin(), _grid_pixels())


## Döndürülmüş tahtanın sol üst köşesi (piksel); tahta alanın ortasına yerleşir.
func _grid_origin() -> Vector2:
	return (size - _grid_pixels()) / 2.0


## Döndürülmüş tahtanın piksel boyutu.
func _grid_pixels() -> Vector2:
	return BoardTurn.grid(Vector2(board.layout.grid_size), _turns) * _cell_size()


## Hücre cinsinden bir noktanın ekrandaki yeri (döndürme dahil).
func _to_pixels(cell: Vector2) -> Vector2:
	var turned := BoardTurn.point(cell, Vector2(board.layout.grid_size), _turns)
	return _grid_origin() + turned * _cell_size()


## Hücre cinsinden bir alanın ekrandaki karşılığı (döndürme dahil).
func _area_to_pixels(area: Rect2) -> Rect2:
	var turned := BoardTurn.rect(area, Vector2(board.layout.grid_size), _turns)
	return Rect2(_grid_origin() + turned.position * _cell_size(), turned.size * _cell_size())


func _cell_rect(cell: Vector2i) -> Rect2:
	return _area_to_pixels(Rect2(Vector2(cell), Vector2.ONE))


func _active_seats() -> Array[int]:
	var seats: Array[int] = []
	for owner: int in board.owners:
		if not seats.has(owner):
			seats.append(owner)
	return seats


## Bir koltuğa ait kareler (ev yolu) yalnızca o koltuk oyundaysa çizilir.
func _is_visible(square: int, active: Array[int]) -> bool:
	var layout := board.layout
	return not layout.is_private(square) or active.has(layout.owners[square])


func _draw_square(square: int, active: Array[int]) -> void:
	var layout := board.layout
	var skin := Skins.current
	var rect := _cell_rect(layout.cells[square])
	var owner := layout.owners[square]
	if owner != BoardLayout.NO_SEAT and layout.homes[owner] == square:
		if selectable_squares.has(square):
			_draw_wave_frame(rect)
		return
	var shortcut_seat := _shortcut_seat(square, active)
	if owner == BoardLayout.NO_SEAT:
		var color := skin.safe_color if layout.safe[square] else skin.track_color
		if shortcut_seat != BoardLayout.NO_SEAT:
			color = _seat_color(shortcut_seat).lightened(skin.shortcut_lighten)
		for seat: int in active:
			if layout.starts[seat] == square:
				color = skin.track_color.lerp(_seat_color(seat), skin.start_tint)
		rect = BoardPainter.draw_tile(self, rect, skin.track_texture, color)
	else:
		var tint := skin.track_color.lerp(_seat_color(owner), skin.lane_tint)
		rect = BoardPainter.draw_tile(self, rect, skin.track_texture, tint)
	if shortcut_seat == BoardLayout.NO_SEAT and not _has_mark(square):
		BoardPainter.draw_inlay(self, rect)
	_draw_mark(square, rect)
	if shortcut_seat != BoardLayout.NO_SEAT:
		var half := HOUSE_HALF * _cell_size() * MARK_RATIO
		var bounds := Rect2(rect.get_center() - half, half * 2.0)
		var line := rect.size.x * HOUSE_LINE_RATIO
		var fill := _seat_color(shortcut_seat)
		CardSymbol.draw_house(self, bounds, fill, skin.outline_color, line)
	if selectable_squares.has(square):
		_draw_wave_frame(rect)


## Ortadaki bitiş alanı (HomeTray); bitiş kareleri kendi kare olarak çizilmez. Oyunda olmayan
## koltukların yamukları işaret rengindedir.
func _draw_home_tray(active: Array[int]) -> void:
	var skin := Skins.current
	var sides: Array[Vector2] = []
	var colors: Array[Color] = []
	var glows: Array[float] = []
	for seat: int in range(board.layout.homes.size()):
		sides.append(_home_side(seat))
		colors.append(_seat_color(seat) if active.has(seat) else skin.mark_color)
		glows.append(_glows.get(seat, 0.0))
	HomeTray.draw(self, _home_area(), sides, colors, glows, skin, _cell_size())


func _draw_home_halos() -> void:
	for seat: int in _glows:
		var color := _seat_color(seat)
		HomeTray.draw_halo(self, _home_area(), _home_side(seat), color, _glows[seat], _cell_size())


## Koltuğun bitiş yamuğu bir anda parlar ve ayardaki sürede söner; animasyondan bağımsızdır,
## taş durduktan sonra da sönmeyi sürdürür.
func _flash_home(seat: int) -> void:
	var tween := create_tween().set_speed_scale(speed_scale)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_glow.bind(seat), 1.0, 0.0, board.settings.home_glow_time)


func _set_glow(glow: float, seat: int) -> void:
	_glows[seat] = glow
	queue_redraw()


## Dönen oku sıradaki oyuncunun rengine boyar; sıra kimsede değilse gizler.
func _update_spinner() -> void:
	_spinner.visible = turn_seat != BoardLayout.NO_SEAT
	_spinner.set_process(_spinner.visible)
	if _spinner.visible:
		_spinner.color = _seat_color(turn_seat)


## Bitiş karelerinin hücrelerini kapsayan alan (piksel).
func _home_area() -> Rect2:
	var homes := board.layout.homes
	var area := Rect2i(board.layout.cells[homes[0]], Vector2i.ONE)
	for home: int in homes:
		area = area.merge(Rect2i(board.layout.cells[home], Vector2i.ONE))
	return _area_to_pixels(Rect2(area))


## Koltuğun bitiş yamuğunun dışa bakan birim yönü: bitiş hücresinin alan merkezine göre yönü.
func _home_side(seat: int) -> Vector2:
	var cell := _square_center(board.layout.homes[seat])
	var away := cell - _home_area().get_center()
	if absf(away.x) > absf(away.y):
		return Vector2.RIGHT if away.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if away.y > 0.0 else Vector2.UP


## Kare oyundaki bir koltuğun kısayol karesiyse o koltuğu, değilse BoardLayout.NO_SEAT döner.
func _shortcut_seat(square: int, active: Array[int]) -> int:
	for seat: int in active:
		if board.layout.shortcuts[seat] == square:
			return seat
	return BoardLayout.NO_SEAT


## Kalkanlı ve hız sayılı karelerin işareti vardır; bunlara süs çizilmez.
func _has_mark(square: int) -> bool:
	return board.layout.safe[square] or board.layout.speed[square] != 0


func _draw_mark(square: int, rect: Rect2) -> void:
	var speed := board.layout.speed[square]
	if board.layout.safe[square]:
		ShieldMark.draw_mark(self, rect.get_center(), _cell_size() * MARK_RATIO)
	elif speed != 0:
		var grow := rect.size.x * (NUMBER_SCALE - 1.0) / 2.0
		BigNumber.draw_speed(self, rect.grow_individual(grow, 0.0, grow, 0.0), speed)


## Yan yana olmayan kareleri birleştiren bağlantılar çizgiyle gösterilir.
func _draw_links(active: Array[int]) -> void:
	var layout := board.layout
	for link: BoardLayout.Link in layout.links:
		var from := layout.cells[link.from]
		var to := layout.cells[link.to]
		var gap := (to - from).abs()
		if maxi(gap.x, gap.y) <= 1 or not active.any(link.allows):
			continue
		var start := _to_pixels(Vector2(from) + CENTER)
		var end := _to_pixels(Vector2(to) + CENTER)
		draw_line(start, end, Skins.current.mark_color, LINE_WIDTH)


## Yol önizlemeleri: yol üstündeki karelerde nokta, varış karesinde nabız gibi parlayan ışık.
func _draw_previews() -> void:
	if preview_paths.is_empty():
		return
	var color := _seat_color(preview_seat)
	var cell := _cell_size()
	for path: PackedInt32Array in preview_paths:
		if path.is_empty():
			continue
		var target := path[path.size() - 1]
		PathPreview.draw_target(self, _cell_rect(board.layout.cells[target]), color, cell)
		var centers: Array[Vector2] = []
		for index: int in range(path.size() - 1):
			centers.append(_square_center(path[index]))
		var ink := Skins.current.outline_color
		PathPreview.draw_dots(self, centers, color, ink, cell, LINE_WIDTH)


## Başlangıç alanı; içinden taş seçilebiliyorsa seçilebilir kare gibi çerçevelenir.
func _draw_base(seat: int) -> void:
	var base := _base_rect(seat)
	BasePainter.draw_base(self, base, _seat_color(seat), _cell_size())
	_draw_sockets(seat)
	if _base_pawn(seat) != Move.NO_PAWN:
		_draw_wave_frame(base, _cell_size() * BasePainter.CORNER_RATIO)


## Oyuncunun her taşı için tepsideki yerinde bir altlık; taş çıkınca yeri boş görünür.
func _draw_sockets(seat: int) -> void:
	var radius := _cell_size() * PAWN_RATIO
	for slot: int in range(board.owners.count(seat)):
		var center := _base_slot_center(seat, slot)
		var points := BoardPainter.base_ellipse(center, radius, SOCKET_SCALE)
		SmoothDraw.polygon(self, points, Skins.current.socket_color)


## Başlangıç alanından çıkış karesine uzanan patika; alandan taş seçilebiliyorsa üstünde ışık akar.
func _draw_base_link(seat: int) -> void:
	var start := _cell_rect(board.layout.cells[board.layout.starts[seat]])
	var skin := Skins.current
	var flowing := _base_pawn(seat) != Move.NO_PAWN
	var color := _seat_color(seat)
	BaseLink.draw(self, _base_rect(seat), start, color, skin, _cell_size(), flowing)


## radius verilirse çerçevenin köşeleri yuvarlatılır (başlangıç tepsisinin şekli için).
func _draw_wave_frame(rect: Rect2, radius := 0.0) -> void:
	var skin := Skins.current
	var color := skin.highlight_color
	PulseWave.draw_frame(self, rect, color, skin.outline_color, HIGHLIGHT_WIDTH, radius)


func _base_rect(seat: int) -> Rect2:
	var extent := Vector2(BASE_COLUMNS, 2.0) * BASE_SPREAD * _cell_size()
	return Rect2(_base_pixels(seat) - extent / 2.0, extent)


## Başlangıç alanındaki seçilebilir ilk taş; yoksa NO_PAWN.
func _base_pawn(seat: int) -> int:
	for pawn: int in selectable:
		if board.owners[pawn] == seat and board.positions[pawn] == BoardState.BASE:
			return pawn
	return Move.NO_PAWN


## Başlangıç alanına dokunulduysa oradaki seçilebilir ilk taş; böylece taşı tam tutturmak gerekmez.
func _selectable_base_pawn_at(point: Vector2) -> int:
	for seat: int in _active_seats():
		if _base_rect(seat).has_point(point):
			return _base_pawn(seat)
	return Move.NO_PAWN


func _layout_pawns() -> void:
	var count := board.positions.size()
	_centers.resize(count)
	_radii.resize(count)
	# Hücre -> o hücredeki taşlar (Array[int]).
	var groups: Dictionary[Vector2i, Array] = {}
	var base_slots: Dictionary[int, int] = {}
	_update_home_order()
	for pawn: int in range(count):
		_radii[pawn] = _cell_size() * PAWN_RATIO
		if board.positions[pawn] == BoardState.BASE:
			var seat := board.owners[pawn]
			var slot: int = base_slots.get(seat, 0)
			base_slots[seat] = slot + 1
			_centers[pawn] = _base_slot_center(seat, slot)
		else:
			var cell := board.layout.cells[board.positions[pawn]]
			if not groups.has(cell):
				var pawns: Array[int] = []
				groups[cell] = pawns
			groups[cell].append(pawn)
	for cell: Vector2i in groups:
		_spread(cell, groups[cell])


## Başlangıç tepsisindeki yerin merkezi (piksel). Tepsi tahtayla dönmez, hep yatay dizilir.
func _base_slot_center(seat: int, slot: int) -> Vector2:
	return _base_pixels(seat) + _base_offset(slot) * _cell_size()


func _base_pixels(seat: int) -> Vector2:
	return _grid_origin() + _base_centers[seat] * _cell_size()


func _base_offset(slot: int) -> Vector2:
	var column := slot % BASE_COLUMNS - (BASE_COLUMNS - 1) / 2.0
	var row := floori(float(slot) / BASE_COLUMNS) - 0.5
	return Vector2(column, row) * BASE_SPREAD + Vector2.UP * BASE_LIFT


## Aynı hücredeki taşları hücre merkezinin çevresine dağıtır; evdeki taşlar küçülüp
## eve geliş sırasıyla bitiş yamuğuna dizilir.
func _spread(cell: Vector2i, pawns: Array[int]) -> void:
	if _is_home(pawns[0]):
		_spread_at_home(pawns)
		return
	var center := _to_pixels(Vector2(cell) + CENTER)
	for index: int in range(pawns.size()):
		var pawn := pawns[index]
		if pawns.size() == 1:
			_centers[pawn] = center
			continue
		var angle := TAU * index / pawns.size()
		_centers[pawn] = center + Vector2.from_angle(angle) * _cell_size() * STACK_SPREAD
		_radii[pawn] *= STACK_SHRINK


func _spread_at_home(pawns: Array[int]) -> void:
	var side := _home_side(board.owners[pawns[0]])
	var ordered := _home_order.filter(func(pawn: int) -> bool: return pawns.has(pawn))
	for index: int in range(ordered.size()):
		var pawn: int = ordered[index]
		var place := HomeTray.place(_home_area(), side, index, ordered.size(), _cell_size())
		_centers[pawn] = place
		_radii[pawn] *= board.settings.home_pawn_scale


## Eve geliş sırasını günceller: evden çıkmış (yeni oyun) taşlar silinir, yeni gelenler
## sona eklenir.
func _update_home_order() -> void:
	_home_order = _home_order.filter(func(pawn: int) -> bool: return _is_at_home(pawn))
	for pawn: int in range(board.positions.size()):
		if _is_at_home(pawn) and not _home_order.has(pawn):
			_home_order.append(pawn)


func _is_at_home(pawn: int) -> bool:
	return pawn < board.positions.size() and _is_home(pawn)


func _is_home(pawn: int) -> bool:
	return board.positions[pawn] == board.layout.homes[board.owners[pawn]]


## Duran taşlar arkadakiler önce çizilsin diye yukarıdan aşağı sıralanır; hareket eden taşlar
## diğerlerinin üstünde kalsın diye en son çizilir.
func _draw_pawns() -> void:
	var moving: Array[int] = []
	var still: Array[int] = []
	for pawn: int in range(_centers.size()):
		if _animation != null and _animation.has(pawn):
			moving.append(pawn)
		else:
			still.append(pawn)
	still.sort_custom(func(a: int, b: int) -> bool: return _centers[a].y < _centers[b].y)
	for pawn: int in still:
		_draw_pawn(pawn, _centers[pawn], _radii[pawn])
	for pawn: int in moving:
		_draw_trail(pawn)
	for pawn: int in moving:
		var ground := _animation.position_at(pawn, _time, _centers[pawn])
		var radius := _radii[pawn] * _animation.scale_at(pawn, _time)
		var height := _animation.height_at(pawn, _time)
		if height > 0.0:
			_draw_shadow(ground, radius)
		_draw_pawn(pawn, ground + Vector2.UP * height, radius)


## Kayan taşın arkasındaki ışık kuyruğu: taştan uzaklaştıkça incelen ve solan kesintisiz şerit.
## Her köşede genişlik ve renk, yol boyunca taştan uzaklığa göre azalır.
func _draw_trail(pawn: int) -> void:
	var settings := board.settings
	var length := settings.trail_squares * _cell_size()
	var points := _animation.trail_points(pawn, _time, length, settings.trail_time)
	if points.size() < 2:
		return
	var color := _seat_color(board.owners[pawn]).lightened(TRAIL_LIGHTEN)
	var fades := _trail_fades(points)
	var colors := PackedColorArray()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index: int in range(points.size()):
		colors.append(Color(color, TRAIL_ALPHA * pow(fades[index], TRAIL_FADE_POWER)))
		var edge := _trail_normal(points, index) * _radii[pawn] * fades[index]
		left.append(points[index] + edge)
		right.append(points[index] - edge)
	SmoothDraw.ribbon(self, left, right, colors, colors)


## Her köşenin taştan yol boyunca uzaklığına göre 1'den (taş) 0'a (uç) inen oranı.
static func _trail_fades(points: Array[Vector2]) -> Array[float]:
	var fades: Array[float] = []
	for progress: float in SmoothDraw.path_progress(PackedVector2Array(points)):
		fades.append(1.0 - progress)
	return fades


## Köşedeki şeridin dik yönü: komşu parçaların yönlerinin ortalamasına dik birim vektör.
static func _trail_normal(points: Array[Vector2], index: int) -> Vector2:
	var before := points[maxi(index - 1, 0)]
	var after := points[mini(index + 1, points.size() - 1)]
	var direction := (after - points[index]).normalized() + (points[index] - before).normalized()
	return direction.normalized().orthogonal()


func _draw_shadow(center: Vector2, radius: float) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, SHADOW_FLATTEN))
	draw_circle(Vector2.ZERO, radius, Skins.current.shadow_color)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_pawn(pawn: int, center: Vector2, radius: float) -> void:
	var ring := _draw_pawn_ring.bind(pawn, center, radius)
	BoardPainter.draw_pawn_in_ring(self, center, radius, color_of(board.owners[pawn]), ring)


## Taşın ayağında, tabanını saran yere yatık (elips) halka. Başlangıç alanındaki seçilebilir
## taşlara dalga çizilmez; orada alanın çerçevesi dalgalanır.
func _draw_pawn_ring(arc: Vector2, pawn: int, foot: Vector2, radius: float) -> void:
	var skin := Skins.current
	var ring_radius := radius * BoardPainter.PAWN_WIDTH_RATIO / 2.0 + HIGHLIGHT_WIDTH
	draw_set_transform(foot, 0.0, Vector2(1.0, PulseWave.RING_FLATTEN))
	if pawn == selected_pawn:
		PulseWave.draw_outlined_arc(
			self,
			Vector2.ZERO,
			ring_radius,
			skin.selected_color,
			skin.outline_color,
			HIGHLIGHT_WIDTH,
			arc
		)
	elif selectable.has(pawn) and board.positions[pawn] != BoardState.BASE:
		PulseWave.draw_ring(
			self,
			Vector2.ZERO,
			ring_radius,
			skin.highlight_color,
			skin.outline_color,
			HIGHLIGHT_WIDTH,
			arc
		)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _selectable_at(point: Vector2) -> int:
	var best := Move.NO_PAWN
	var best_distance := _cell_size() * HIT_RATIO
	for pawn: int in selectable:
		if pawn >= _centers.size():
			continue
		var distance := point.distance_to(_centers[pawn])
		if distance <= best_distance:
			best_distance = distance
			best = pawn
	return best


func _set_time(time: float) -> void:
	for cue: StringName in _animation.cues_between(_time, time):
		Sound.play(cue)
	for seat: int in _animation.flashes_between(_time, time):
		_flash_home(seat)
	_time = time
	queue_redraw()


func _square_center(square: int) -> Vector2:
	return _to_pixels(Vector2(board.layout.cells[square]) + CENTER)
