class_name CircularArrow
extends RefCounted
## Ucunda dolu üçgen ok başı olan, saat yönünde ilerleyen yay. Yenile simgesi ve tahtanın
## ortasındaki dönen sıra oku bunu kullanır.

## Ok başının boyu (yarı genişliğine oranla).
const HEAD_LENGTH := 1.1
const ARC_POINTS := 24


## start açısından end açısına giden yayı, başını yuvarlak, sonunu ok başlı çizer. Çizilen ok
## başının köşelerini döner; kenar çizmek isteyen çağıran bunları kullanır.
static func draw(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	angles: Vector2,
	width: float,
	head_half: float,
	color: Color
) -> PackedVector2Array:
	canvas.draw_arc(center, radius, angles.x, angles.y, ARC_POINTS, color, width, true)
	canvas.draw_circle(center + Vector2.from_angle(angles.x) * radius, width / 2.0, color)
	var base := center + Vector2.from_angle(angles.y) * radius
	var head := _head_points(base, angles.y, head_half)
	canvas.draw_colored_polygon(head, color)
	return head


## Yayın ucunda, dönüş yönünü gösteren dolu üçgen ok başı.
static func _head_points(base: Vector2, angle: float, half: float) -> PackedVector2Array:
	var outward := Vector2.from_angle(angle)
	var forward := Vector2.from_angle(angle + PI / 2.0)
	return PackedVector2Array(
		[base + forward * half * HEAD_LENGTH, base + outward * half, base - outward * half]
	)


## Yayı ve ok başını tek parça, kenarları yumuşatılmış bir şekil olarak çizer; parçalar üst üste
## binmediği için yarı saydam çizimde koyu düğümler oluşmaz. Uzunluk başına
## points_per_radian kadar nokta kullanılır.
static func draw_smooth(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	angles: Vector2,
	width: float,
	head_half: float,
	color: Color,
	points_per_radian: float
) -> void:
	var count := maxi(ceili(absf(angles.y - angles.x) * points_per_radian), 1)
	var line := SmoothDraw.arc_points(center, radius, angles.x, angles.y, count)
	var head := _head_points(center + Vector2.from_angle(angles.y) * radius, angles.y, head_half)
	var shapes: Array[PackedVector2Array] = [head]
	for stroke: PackedVector2Array in Geometry2D.offset_polyline(
		line, width / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND
	):
		var merged: Array[PackedVector2Array] = []
		for shape: PackedVector2Array in shapes:
			merged.append_array(Geometry2D.merge_polygons(shape, stroke))
		shapes = merged
	for shape: PackedVector2Array in shapes:
		SmoothDraw.polygon(canvas, shape, color)


## Ok başının çevresine yuvarlak köşeli kenar çizer.
static func draw_rim(
	canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float
) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, color, width, true)
	for point: Vector2 in points:
		canvas.draw_circle(point, width / 2.0, color)
