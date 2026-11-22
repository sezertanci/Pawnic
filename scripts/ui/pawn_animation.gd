class_name PawnAnimation
extends RefCounted
## Bir hamledeki taş hareketlerinin zaman çizelgesi. Çizimden bağımsızdır; BoardView zamanı
## ilerletir ve her taşın o andaki yerini, yüksekliğini ve büyüklüğünü buradan okur.


## Taşın iki nokta arasındaki tek hareketi; height sıfırdan büyükse yay çizerek zıplar.
class Segment:
	var from: Vector2
	var to: Vector2
	var start: float
	var duration: float
	var height: float

	func end() -> float:
		return start + duration

	func progress(time: float) -> float:
		return clampf((time - start) / duration, 0.0, 1.0) if duration > 0.0 else 1.0


## Taşın boyunun from oranından kendi boyuna inmesi (ör. eve girip küçük cama girerken küçülme).
## Başlamadan önce taş from oranında durur.
class Resize:
	var start: float
	var duration: float
	var from: float


## Belli bir anda çalınacak ses.
class Cue:
	var time: float
	var sound: StringName


## Belli bir anda koltuğun bitiş yamuğunun parlaması (taş eve girdi).
class Flash:
	var time: float
	var seat: int


## Taş -> o taşın hareketleri (Array[Segment]), zaman sırasıyla.
var _segments: Dictionary[int, Array] = {}
var _resizes: Dictionary[int, Resize] = {}
## Arkasında ışık kuyruğu bırakan taşlar: taş -> (başlangıç, bitiş).
var _trails: Dictionary[int, Vector2] = {}
var _duration := 0.0
var _cues: Array[Cue] = []
var _flashes: Array[Flash] = []


func add_segment(
	pawn: int, from: Vector2, to: Vector2, start: float, duration: float, height: float
) -> void:
	var segment := Segment.new()
	segment.from = from
	segment.to = to
	segment.start = start
	segment.duration = duration
	segment.height = height
	if not _segments.has(pawn):
		var segments: Array[Segment] = []
		_segments[pawn] = segments
	_segments[pawn].append(segment)
	_duration = maxf(_duration, segment.end())


func add_resize(pawn: int, start: float, duration: float, from: float) -> void:
	var resize := Resize.new()
	resize.start = start
	resize.duration = duration
	resize.from = from
	_resizes[pawn] = resize
	_duration = maxf(_duration, start + duration)


## Taş start ile end arasında arkasında ışık kuyruğu bırakır.
func add_trail(pawn: int, start: float, end: float) -> void:
	_trails[pawn] = Vector2(start, end)


## Kuyruğun köşe noktaları, taştan başlayarak taşın geçtiği yol boyunca geriye doğru. Yol en
## fazla max_length uzunluğundadır. Kayma bitince kuyruk retract süresinde taşın içine çekilir.
func trail_points(pawn: int, time: float, max_length: float, retract: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if not _trails.has(pawn):
		return points
	var trail := _trails[pawn]
	var now := minf(time, trail.y)
	var length := max_length
	if time > trail.y:
		length *= 1.0 - (time - trail.y) / retract if retract > 0.0 else 0.0
	if time < trail.x or length <= 0.0:
		return points
	points.append(position_at(pawn, now, Vector2.ZERO))
	var segments: Array = _segments[pawn]
	for index: int in range(segments.size() - 1, -1, -1):
		var segment: Segment = segments[index]
		if segment.start < now and segment.start >= trail.x:
			points.append(segment.from)
	return _clipped(points, length)


## Kırık çizgiyi baştan itibaren length uzunluğunda keser; üst üste düşen noktaları atar.
static func _clipped(points: Array[Vector2], length: float) -> Array[Vector2]:
	var result: Array[Vector2] = [points[0]]
	var left := length
	for index: int in range(1, points.size()):
		var from := result[result.size() - 1]
		var step := from.distance_to(points[index])
		if is_zero_approx(step):
			continue
		if step >= left:
			result.append(from.move_toward(points[index], left))
			break
		left -= step
		result.append(points[index])
	return result


## time anında cue sesinin çalınmasını ister (ör. taşın her inişinde adım sesi).
func add_cue(time: float, cue: StringName) -> void:
	var entry := Cue.new()
	entry.time = time
	entry.sound = cue
	_cues.append(entry)


## from'dan sonra, to'ya kadar (to dahil) çalınacak sesler.
func cues_between(from: float, to: float) -> Array[StringName]:
	var result: Array[StringName] = []
	for cue: Cue in _cues:
		if cue.time > from and cue.time <= to:
			result.append(cue.sound)
	return result


## time anında seat koltuğunun bitiş yamuğunun parlamasını ister.
func add_flash(time: float, seat: int) -> void:
	var flash := Flash.new()
	flash.time = time
	flash.seat = seat
	_flashes.append(flash)


## from'dan sonra, to'ya kadar (to dahil) parlayacak koltuklar.
func flashes_between(from: float, to: float) -> Array[int]:
	var result: Array[int] = []
	for flash: Flash in _flashes:
		if flash.time > from and flash.time <= to:
			result.append(flash.seat)
	return result


func duration() -> float:
	return _duration


func has(pawn: int) -> bool:
	return _segments.has(pawn) or _resizes.has(pawn)


## Taşın o andaki yerdeki noktası; zıplama yüksekliği ayrıca height_at ile okunur.
func position_at(pawn: int, time: float, fallback: Vector2) -> Vector2:
	var segment := _segment_at(pawn, time)
	if segment == null:
		return fallback
	return segment.from.lerp(segment.to, segment.progress(time))


func height_at(pawn: int, time: float) -> float:
	var segment := _segment_at(pawn, time)
	if segment == null:
		return 0.0
	return sin(PI * segment.progress(time)) * segment.height


func scale_at(pawn: int, time: float) -> float:
	var resize: Resize = _resizes.get(pawn)
	if resize == null:
		return 1.0
	if resize.duration <= 0.0:
		return 1.0 if time >= resize.start else resize.from
	var progress := clampf((time - resize.start) / resize.duration, 0.0, 1.0)
	return lerpf(resize.from, 1.0, progress)


## Zamanı kapsayan hareket; aradaki duraklamada önceki, başlamadan önce ilk hareket döner.
func _segment_at(pawn: int, time: float) -> Segment:
	if not _segments.has(pawn):
		return null
	var segments: Array = _segments[pawn]
	var current: Segment = segments[0]
	for segment: Segment in segments:
		if segment.start <= time:
			current = segment
	return current
