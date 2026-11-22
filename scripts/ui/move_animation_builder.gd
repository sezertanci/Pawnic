class_name MoveAnimationBuilder
extends RefCounted
## Bir hamlenin taş animasyonunu (PawnAnimation) kurar. Taşların hamleden önceki ve sonraki
## yerlerini, tahtanın son durumunu ve ayarlardaki süreleri kullanır; kendisi çizim yapmaz.

var _board: BoardState
## Hamleden sonraki taş merkezleri (piksel).
var _after: Array[Vector2]
var _cell_size: float
## Karenin piksel merkezini veren fonksiyon: func(square: int) -> Vector2.
var _square_center: Callable


func _init(
	board: BoardState, after: Array[Vector2], cell_size: float, square_center: Callable
) -> void:
	_board = board
	_after = after
	_cell_size = cell_size
	_square_center = square_center


## path, BoardState.move_path ile hamleden önce alınan karelerdir; before hamleden önceki
## taş merkezleridir.
func build(move: Move, path: Array[int], before: Array[Vector2]) -> PawnAnimation:
	var animation := PawnAnimation.new()
	var landed := _add_mover(animation, move, path, before)
	_add_followers(animation, before, landed, _board.owners[move.pawn])
	_add_home_arrival(animation, move.pawn, landed)
	return animation


## Taş eve girdiyse indiği anda başarı sesi çalar ve sahibinin bitiş yamuğu parlar.
func _add_home_arrival(animation: PawnAnimation, pawn: int, landed: float) -> void:
	if not _is_home(pawn):
		return
	animation.add_cue(landed, Sound.HOME)
	animation.add_flash(landed, _board.owners[pawn])


## Oynanan taşı kare kare zıplatır; her inişte adım sesi çalar, hız karesinde kısa durur,
## eve girerken küçük cama girip küçülür. Kısayolda ve yer değiştirmede taşlar kayar, ışınlanma
## sesi çalar. Taşın indiği anı döner.
func _add_mover(
	animation: PawnAnimation, move: Move, path: Array[int], before: Array[Vector2]
) -> float:
	var settings := _board.settings
	var pawn := move.pawn
	if move.action in [Move.Action.SHORTCUT, Move.Action.SWAP]:
		animation.add_cue(0.0, Sound.TELEPORT)
		if move.action == Move.Action.SWAP:
			var back := _board.swap_path(
				move.target, _board.positions[move.pawn], _board.positions[move.target]
			)
			_add_slide(animation, move.target, back, before[move.target])
		return _add_slide(animation, pawn, path, before[pawn])
	var height := settings.hop_height * _cell_size
	var from := before[pawn]
	var time := 0.0
	for index: int in range(path.size()):
		var last := index == path.size() - 1
		var to := _after[pawn] if last else _center_of(path[index])
		animation.add_segment(pawn, from, to, time, settings.hop_time, height)
		time += settings.hop_time
		animation.add_cue(time, Sound.STEP)
		if path[index] == move.destination and not last:
			time += settings.boost_pause
		from = to
	if _is_home(pawn):
		var large := 1.0 / settings.home_pawn_scale
		animation.add_resize(pawn, time - settings.hop_time, settings.home_shrink_time, large)
	return time


func _is_home(pawn: int) -> bool:
	return _board.positions[pawn] == _board.layout.homes[_board.owners[pawn]]


## Taş zıplamadan, yol üstündeki karelerden geçerek kayar ve arkasında ışık kuyruğu bırakır.
## Yol boşsa varışa düz kayar. Taşın indiği anı döner.
func _add_slide(animation: PawnAnimation, pawn: int, path: Array[int], start: Vector2) -> float:
	var slide_time := _board.settings.slide_time
	var count := maxi(path.size(), 1)
	var square_time := slide_time / count
	var from := start
	for index: int in range(count):
		var last := index == count - 1
		var to := _after[pawn] if last else _center_of(path[index])
		animation.add_segment(pawn, from, to, square_time * index, square_time, 0.0)
		from = to
	animation.add_trail(pawn, 0.0, slide_time)
	return slide_time


## Taş indikten sonra çarpılan taşlar başlangıca uçar ("ops" sesi bir kez çalar), aynı
## karedeki ve başlangıçtaki taşlar yeniden dizilir. Kırılan taş hep rakibindir (seat oynayan
## koltuk); oynayanın başlangıcındaki taşların kayması (taş çıkarınca) kırılma sayılmaz.
func _add_followers(
	animation: PawnAnimation, before: Array[Vector2], start: float, seat: int
) -> void:
	var settings := _board.settings
	var captured := false
	for pawn: int in range(_after.size()):
		if animation.has(pawn) or before[pawn].is_equal_approx(_after[pawn]):
			continue
		if _board.positions[pawn] == BoardState.BASE:
			captured = captured or _board.owners[pawn] != seat
			var height := settings.capture_height * _cell_size
			animation.add_segment(
				pawn, before[pawn], _after[pawn], start, settings.capture_time, height
			)
		else:
			animation.add_segment(
				pawn, before[pawn], _after[pawn], start, settings.settle_time, 0.0
			)
	if captured:
		animation.add_cue(start, Sound.CAPTURE)


func _center_of(square: int) -> Vector2:
	return _square_center.call(square)
