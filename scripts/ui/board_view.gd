class_name BoardView
extends Control
## Tahtayı ve taşları çizer, seçilebilir bir taşa ya da kareye dokunulduğunu bildirir.
## Karelerin yeri tahta dosyasındaki (BoardLayout) hücrelerden gelir.
## Renkler seçili temadan (Skins) okunur.

signal pawn_pressed(pawn: int)
signal square_pressed(square: int)

const CELL_GAP := 2.0
const PAWN_RATIO := 0.34
const STACK_SPREAD := 0.22
const STACK_SHRINK := 0.65
const BASE_COLUMNS := 3
const BASE_SPREAD := 0.95
const HIT_RATIO := 0.6
const MARK_RATIO := 0.3
const FONT_RATIO := 0.42
## Hız sayısının koyu konturunun kalınlığı (yazı boyuna oranla).
const TEXT_OUTLINE_RATIO := 0.3
const LINE_WIDTH := BoardPainter.LINE_WIDTH
const HIGHLIGHT_WIDTH := 4.0
## Daire çizimindeki nokta sayısı.
const ARC_POINTS := BoardPainter.ARC_POINTS
const CENTER := Vector2(0.5, 0.5)
## Gölge elipsinin dikey basıklığı.
const SHADOW_FLATTEN := 0.45
## Kalkan sembolünün köşeleri (yarıçapa oranla, merkez sıfırda).
const SHIELD_POINTS: Array[Vector2] = [
	Vector2(-0.8, -0.8),
	Vector2(0.0, -1.0),
	Vector2(0.8, -0.8),
	Vector2(0.75, 0.15),
	Vector2(0.4, 0.65),
	Vector2(0.0, 1.0),
	Vector2(-0.4, 0.65),
	Vector2(-0.75, 0.15),
]
## Karedeki sembollerin (kalkan, ev) yarı genişliği ve yarı yüksekliği (yarıçapa oranla).
const MARK_HALF := Vector2(0.8, 1.0)
## Kısayol evinin yarı boyu: gövdesi kalkan kadar geniş görünsün diye kalkandan geniş tutulur.
const HOUSE_HALF := Vector2(1.05, 0.95)
## Işık kuyruğundaki daire sayısı, en parlak dairenin saydamlığı ve rengin beyaza yaklaşma oranı.
const TRAIL_SAMPLES := 12
const TRAIL_ALPHA := 0.6
const TRAIL_LIGHTEN := 0.5
## Kısayol karesindeki evin çizgi kalınlığı (kare boyuna oranla).
const HOUSE_LINE_RATIO := 0.03

var board: BoardState
var selectable: Array[int] = []
## Yol ayrımında varış karesi seçilirken dokunulabilecek kareler.
var selectable_squares: Array[int] = []
## Hamlesi seçilmekte olan taş; farklı renkte halkayla gösterilir.
var selected_pawn := Move.NO_PAWN

var _centers: Array[Vector2] = []
var _radii: Array[float] = []
## Oynanmakta olan hamlenin animasyonu; yoksa null.
var _animation: PawnAnimation
var _tween: Tween
var _time := 0.0


func _ready() -> void:
	Skins.changed.connect(queue_redraw)


## Seçilebilir bir şey varken dalga oynasın diye tahta her karede yeniden çizilir.
func _process(_delta: float) -> void:
	if not selectable.is_empty() or not selectable_squares.is_empty():
		queue_redraw()


func _draw() -> void:
	if board == null or minf(size.x, size.y) <= 0.0:
		return
	var active := _active_seats()
	_draw_links(active)
	for square: int in range(board.layout.square_count()):
		if _is_visible(square, active):
			_draw_square(square, active)
	for seat: int in active:
		_draw_base(seat)
	_layout_pawns()
	_draw_pawns()


func is_animating() -> bool:
	return _animation != null


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
	var animation := _build_animation(move, path, before)
	if animation.duration() <= 0.0:
		queue_redraw()
		return
	_animation = animation
	_time = 0.0
	# Başlangıç anındaki sesler (ör. ışınlanma) tween'in ilk adımını beklemez.
	for cue: StringName in animation.cues_between(-INF, _time):
		Sound.play(cue)
	_tween = create_tween()
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


func _cell_size() -> float:
	var grid := Vector2(board.layout.grid_size)
	return minf(size.x / grid.x, size.y / grid.y)


func _to_pixels(cell: Vector2) -> Vector2:
	var grid := Vector2(board.layout.grid_size) * _cell_size()
	return (size - grid) / 2.0 + cell * _cell_size()


func _cell_rect(cell: Vector2i) -> Rect2:
	var gap := Vector2.ONE * CELL_GAP
	return Rect2(_to_pixels(Vector2(cell)) + gap, Vector2.ONE * _cell_size() - gap * 2.0)


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
	var shortcut_seat := _shortcut_seat(square, active)
	if owner == BoardLayout.NO_SEAT:
		var color := skin.safe_color if layout.safe[square] else skin.track_color
		if shortcut_seat != BoardLayout.NO_SEAT:
			color = skin.seat_color(shortcut_seat).lightened(skin.shortcut_lighten)
		for seat: int in active:
			if layout.starts[seat] == square:
				color = skin.track_color.lerp(skin.seat_color(seat), skin.start_tint)
		rect = BoardPainter.draw_tile(self, rect, skin.track_texture, color)
	elif layout.homes[owner] == square:
		rect = BoardPainter.draw_tile(self, rect, skin.track_texture, skin.seat_color(owner))
	else:
		var tint := Color.WHITE.lerp(skin.seat_color(owner), skin.lane_tint)
		rect = BoardPainter.draw_tile(self, rect, skin.lane_texture, tint)
	_draw_mark(square, rect)
	if shortcut_seat != BoardLayout.NO_SEAT:
		var half := HOUSE_HALF * _cell_size() * MARK_RATIO
		var bounds := Rect2(rect.get_center() - half, half * 2.0)
		var line := rect.size.x * HOUSE_LINE_RATIO
		var fill := skin.seat_color(shortcut_seat)
		CardSymbol.draw_house(self, bounds, fill, skin.outline_color, line)
	if selectable_squares.has(square):
		_draw_wave_frame(rect)


## Kare oyundaki bir koltuğun kısayol karesiyse o koltuğu, değilse BoardLayout.NO_SEAT döner.
func _shortcut_seat(square: int, active: Array[int]) -> int:
	for seat: int in active:
		if board.layout.shortcuts[seat] == square:
			return seat
	return BoardLayout.NO_SEAT


func _draw_mark(square: int, rect: Rect2) -> void:
	var skin := Skins.current
	var font_size := roundi(_cell_size() * FONT_RATIO)
	var speed := board.layout.speed[square]
	if board.layout.safe[square]:
		_draw_shield(rect.get_center(), _cell_size() * MARK_RATIO)
	elif speed != 0 and font_size > 0:
		var text := "%+d" % speed
		var baseline := Vector2(rect.position.x, rect.get_center().y + font_size / 3.0)
		var font := ThemeDB.fallback_font
		var outline := roundi(font_size * TEXT_OUTLINE_RATIO)
		var align := HORIZONTAL_ALIGNMENT_CENTER
		draw_string_outline(
			font, baseline, text, align, rect.size.x, font_size, outline, skin.outline_color
		)
		draw_string(font, baseline, text, align, rect.size.x, font_size, skin.speed_text_color)


func _draw_shield(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in SHIELD_POINTS:
		points.append(center + point * radius)
	var skin := Skins.current
	SmoothDraw.outlined(self, points, skin.shield_color, skin.outline_color, LINE_WIDTH)


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


## Başlangıç alanı; içinden taş seçilebiliyorsa seçilebilir kare gibi çerçevelenir.
func _draw_base(seat: int) -> void:
	var skin := Skins.current
	var base := _base_rect(seat)
	draw_rect(base, Color(skin.seat_color(seat), skin.base_alpha))
	if _base_pawn(seat) != Move.NO_PAWN:
		_draw_wave_frame(base)


func _draw_wave_frame(rect: Rect2) -> void:
	var skin := Skins.current
	PulseWave.draw_frame(self, rect, skin.highlight_color, skin.outline_color, HIGHLIGHT_WIDTH)


func _base_rect(seat: int) -> Rect2:
	var half := Vector2(BASE_COLUMNS / 2.0, 1.0) * BASE_SPREAD
	return Rect2(_to_pixels(board.layout.bases[seat] - half), half * 2.0 * _cell_size())


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
	var groups := {}
	var base_slots := {}
	for pawn: int in range(count):
		_radii[pawn] = _cell_size() * PAWN_RATIO
		if board.positions[pawn] == BoardState.BASE:
			var seat := board.owners[pawn]
			var slot: int = base_slots.get(seat, 0)
			base_slots[seat] = slot + 1
			_centers[pawn] = _to_pixels(board.layout.bases[seat] + _base_offset(slot))
		else:
			var cell := board.layout.cells[board.positions[pawn]]
			if not groups.has(cell):
				groups[cell] = []
			(groups[cell] as Array).append(pawn)
	for cell: Vector2i in groups:
		_spread(cell, groups[cell])


func _base_offset(slot: int) -> Vector2:
	var column := slot % BASE_COLUMNS - (BASE_COLUMNS - 1) / 2.0
	var row := floori(float(slot) / BASE_COLUMNS) - 0.5
	return Vector2(column, row) * BASE_SPREAD


## Aynı hücredeki taşları hücre merkezinin çevresine dağıtır.
func _spread(cell: Vector2i, pawns: Array) -> void:
	var center := _to_pixels(Vector2(cell) + CENTER)
	for index: int in range(pawns.size()):
		var pawn: int = pawns[index]
		if pawns.size() == 1:
			_centers[pawn] = center
			continue
		var angle := TAU * index / pawns.size()
		_centers[pawn] = center + Vector2.from_angle(angle) * _cell_size() * STACK_SPREAD
		_radii[pawn] *= STACK_SHRINK


## Hareket eden taşlar diğerlerinin üstünde kalsın diye en son çizilir.
func _draw_pawns() -> void:
	var moving: Array[int] = []
	for pawn: int in range(_centers.size()):
		if _animation != null and _animation.has(pawn):
			moving.append(pawn)
		else:
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


## Kayan taşın arkasındaki ışık kuyruğu: taştan uzaklaştıkça küçülen ve solan daireler.
func _draw_trail(pawn: int) -> void:
	var span := board.settings.trail_time
	var points := _animation.trail_points(pawn, _time, span, TRAIL_SAMPLES)
	var color := Skins.current.seat_color(board.owners[pawn]).lightened(TRAIL_LIGHTEN)
	for index: int in range(points.size()):
		var fade := 1.0 - float(index + 1) / (TRAIL_SAMPLES + 1)
		draw_circle(points[index], _radii[pawn] * fade, Color(color, TRAIL_ALPHA * fade))


func _draw_shadow(center: Vector2, radius: float) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, SHADOW_FLATTEN))
	draw_circle(Vector2.ZERO, radius, Skins.current.shadow_color)
	draw_set_transform(Vector2.ZERO)


func _draw_pawn(pawn: int, center: Vector2, radius: float) -> void:
	# Halkanın arka yarısı taşın arkasında, ön yarısı önünde kalsın diye iki parça çizilir.
	_draw_pawn_ring(pawn, center, radius, PulseWave.BACK_ARC)
	BoardPainter.draw_pawn(self, center, radius, board.owners[pawn])
	_draw_pawn_ring(pawn, center, radius, PulseWave.FRONT_ARC)


## Taşın ayağında, tabanını saran yere yatık (elips) halka. Başlangıç alanındaki seçilebilir
## taşlara dalga çizilmez; orada alanın çerçevesi dalgalanır.
func _draw_pawn_ring(pawn: int, foot: Vector2, radius: float, arc: Vector2) -> void:
	var skin := Skins.current
	var ring_radius := radius * BoardPainter.PAWN_WIDTH_RATIO / 2.0 + HIGHLIGHT_WIDTH
	draw_set_transform(foot, 0.0, Vector2(1.0, PulseWave.RING_FLATTEN))
	if pawn == selected_pawn:
		_draw_highlight_ring(ring_radius, skin.selected_color, arc)
	elif selectable.has(pawn) and board.positions[pawn] != BoardState.BASE:
		PulseWave.draw_ring(
			self, Vector2.ZERO, ring_radius, skin.highlight_color, skin.outline_color,
			HIGHLIGHT_WIDTH, arc
		)
	draw_set_transform(Vector2.ZERO)


## Seçili taşın sabit halkası: dışındaki koyu çizgi halkayı açık renkli karede de görünür kılar.
func _draw_highlight_ring(ring_radius: float, color: Color, arc: Vector2) -> void:
	var skin := Skins.current
	var edge_radius := ring_radius + (HIGHLIGHT_WIDTH + LINE_WIDTH) / 2.0
	draw_arc(Vector2.ZERO, ring_radius, arc.x, arc.y, ARC_POINTS, color, HIGHLIGHT_WIDTH)
	draw_arc(Vector2.ZERO, edge_radius, arc.x, arc.y, ARC_POINTS, skin.outline_color, LINE_WIDTH)


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
	_time = time
	queue_redraw()


func _square_center(square: int) -> Vector2:
	return _to_pixels(Vector2(board.layout.cells[square]) + CENTER)


func _build_animation(move: Move, path: Array[int], before: Array[Vector2]) -> PawnAnimation:
	var animation := PawnAnimation.new()
	var landed := _add_mover(animation, move, path, before)
	_add_followers(animation, before, landed)
	return animation


## Oynanan taşı kare kare zıplatır; her inişte adım sesi çalar, hız karesinde kısa durur,
## eve varınca büyür. Kısayolda ve yer değiştirmede taşlar kayar, ışınlanma sesi çalar.
## Taşın indiği anı döner.
func _add_mover(
	animation: PawnAnimation, move: Move, path: Array[int], before: Array[Vector2]
) -> float:
	var settings := board.settings
	var pawn := move.pawn
	if move.action in [Move.Action.SHORTCUT, Move.Action.SWAP]:
		animation.add_cue(0.0, Sound.TELEPORT)
		if move.action == Move.Action.SWAP:
			_add_slide(
				animation, move.target, _reverse_path(path, move.target), before[move.target]
			)
		return _add_slide(animation, pawn, path, before[pawn])
	var height := settings.hop_height * _cell_size()
	var from := before[pawn]
	var time := 0.0
	for index: int in range(path.size()):
		var last := index == path.size() - 1
		var to := _centers[pawn] if last else _square_center(path[index])
		animation.add_segment(pawn, from, to, time, settings.hop_time, height)
		time += settings.hop_time
		animation.add_cue(time, Sound.STEP)
		if path[index] == move.destination and not last:
			time += settings.boost_pause
		from = to
	if board.positions[pawn] == board.layout.homes[board.owners[pawn]]:
		animation.add_pulse(pawn, time, settings.home_pulse_time, settings.home_pulse_scale)
	return time


## Taş zıplamadan, yol üstündeki karelerden geçerek kayar ve arkasında ışık kuyruğu bırakır.
## Yol boşsa varışa düz kayar. Taşın indiği anı döner.
func _add_slide(animation: PawnAnimation, pawn: int, path: Array[int], start: Vector2) -> float:
	var slide_time := board.settings.slide_time
	var count := maxi(path.size(), 1)
	var square_time := slide_time / count
	var from := start
	for index: int in range(count):
		var last := index == count - 1
		var to := _centers[pawn] if last else _square_center(path[index])
		animation.add_segment(pawn, from, to, square_time * index, square_time, 0.0)
		from = to
	animation.add_trail(pawn, 0.0, slide_time)
	return slide_time


## Yer değiştirmede hedef taşın yolu: oynanan taşın yolunun tersi, hedefin kendi karesi hariç,
## oynanan taşın eski karesi (artık hedefin karesi) dahil.
func _reverse_path(path: Array[int], target: int) -> Array[int]:
	var back: Array[int] = path.duplicate()
	back.reverse()
	if not back.is_empty():
		back.remove_at(0)
		back.append(board.positions[target])
	return back


## Taş indikten sonra çarpılan taşlar başlangıca uçar, aynı karedeki taşlar yeniden dizilir.
func _add_followers(animation: PawnAnimation, before: Array[Vector2], start: float) -> void:
	var settings := board.settings
	for pawn: int in range(_centers.size()):
		if animation.has(pawn) or before[pawn].is_equal_approx(_centers[pawn]):
			continue
		if board.positions[pawn] == BoardState.BASE:
			var height := settings.capture_height * _cell_size()
			animation.add_segment(
				pawn, before[pawn], _centers[pawn], start, settings.capture_time, height
			)
		else:
			animation.add_segment(
				pawn, before[pawn], _centers[pawn], start, settings.settle_time, 0.0
			)
