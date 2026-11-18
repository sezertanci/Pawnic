class_name SmoothDraw
extends RefCounted
## Sembolleri kesiksiz ve yumuşak kenarlı çizer. draw_polyline köşelerde ve kapanış
## noktasında çentik bırakır; burada kontur, şeklin dışa doğru genişletilmiş hali olarak
## tek parça doldurulur. Dolgu kenarlarına ince bir yumuşatılmış çizgi çekilerek
## merdiven görüntüsü giderilir.

## Kenar yumuşatma çizgisinin kalınlığı (piksel).
const FEATHER := 1.0
const ARC_POINTS := 32


## Kapalı şekli fill ile doldurur, çevresine line_width kalınlığında ink konturu çizer.
static func outlined(
	canvas: CanvasItem, points: PackedVector2Array, fill: Color, ink: Color, line_width: float
) -> void:
	var half := line_width / 2.0
	for outer: PackedVector2Array in Geometry2D.offset_polygon(points, half, Geometry2D.JOIN_ROUND):
		polygon(canvas, outer, ink)
	for inner: PackedVector2Array in Geometry2D.offset_polygon(points, -half):
		polygon(canvas, inner, fill)


## Açık bir çizgiyi yuvarlak uçlu ve yuvarlak köşeli olarak çizer.
static func stroke(
	canvas: CanvasItem, points: PackedVector2Array, color: Color, line_width: float
) -> void:
	for shape: PackedVector2Array in Geometry2D.offset_polyline(
		points, line_width / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND
	):
		polygon(canvas, shape, color)


## Kenarları yumuşatılmış dolu çokgen.
static func polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)
	var edge := points.duplicate()
	edge.append(points[0])
	canvas.draw_polyline(edge, color, FEATHER, true)


## Dolu ve konturlu daire.
static func circle(
	canvas: CanvasItem, center: Vector2, radius: float, fill: Color, ink: Color, width: float
) -> void:
	canvas.draw_circle(center, radius + width / 2.0, ink, true, -1.0, true)
	canvas.draw_circle(center, radius - width / 2.0, fill, true, -1.0, true)


## Yayın noktaları (from'dan to'ya, radyan); stroke ile çizilmek içindir.
static func arc_points(
	center: Vector2, radius: float, from: float, to: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(ARC_POINTS + 1):
		var angle := lerpf(from, to, float(index) / ARC_POINTS)
		points.append(center + Vector2.from_angle(angle) * radius)
	return points


## İki nokta sırası arasını köşe renkli dörtgenlerle doldurur; renkler şerit boyunca ve iki
## kenar arasında yumuşakça geçer. Sıraların ve renklerin boyu aynı olmalıdır.
static func ribbon(
	canvas: CanvasItem,
	side_a: PackedVector2Array,
	side_b: PackedVector2Array,
	colors_a: PackedColorArray,
	colors_b: PackedColorArray
) -> void:
	for index: int in range(side_a.size() - 1):
		var next := index + 1
		var quad := PackedVector2Array([side_a[index], side_a[next], side_b[next], side_b[index]])
		var colors := PackedColorArray(
			[colors_a[index], colors_a[next], colors_b[next], colors_b[index]]
		)
		canvas.draw_primitive(quad, colors, PackedVector2Array())


## Kırık çizginin her noktası için baştan yol boyunca uzaklığın toplam uzunluğa oranı (0..1).
static func path_progress(points: PackedVector2Array) -> PackedFloat32Array:
	var distances := PackedFloat32Array([0.0])
	for index: int in range(1, points.size()):
		distances.append(distances[index - 1] + points[index - 1].distance_to(points[index]))
	var total := distances[distances.size() - 1]
	for index: int in range(distances.size()):
		distances[index] = distances[index] / total if total > 0.0 else 0.0
	return distances
