class_name BaseLink
extends RefCounted
## Başlangıç alanından çıkış karesine uzanan kavisli patika; taşların nereden yola çıkacağını
## gösterir. Patika alanın çıkış karesine bakan kenarının ortasının biraz önünden dik çıkar,
## yumuşak bir S çizerek karenin biraz önüne dik varır; iki ucu da kenarlara değmez. İki yan
## çizgiden ve aralarındaki daha soluk dolgudan oluşur; başına, ortasına ve sonuna yakın üç ok
## işareti (>) yönü gösterir. Renkler zemine yumuşakça karışan, kenarsız tonlardır.
## Alandan taş seçilebiliyorsa dolgu boyunca çıkış karesine doğru > biçiminde bir ışık akar;
## ışık ok işaretlerinin üstünden geçerken onları da aydınlatır, böylece bölünmeden akar;
## bu sırada çizen düğüm her karede yeniden çizilmelidir. Uzunluklar kare boyuna oranlanır.

## İki yan çizgi arasındaki genişlik ve çizgi kalınlığı.
const WIDTH_RATIO := 0.4
const LINE_RATIO := 0.05
## Oyuncu renginin kenar çizgilerinde ve dolguda zemine karışma oranı; renkler opak çizilir.
const LINE_ALPHA := 0.5
const FILL_ALPHA := 0.2
## Ok işaretlerinin eğri üzerindeki yerleri (eğri noktalarının sırasına oranla), kollarının
## uzunluğu (patika genişliğine oranla) ve çizgi kalınlığı (kare boyuna oranla).
const ARROWS_AT: Array[float] = [0.2, 0.5, 0.8]
const ARROW_SIZE := 0.45
const ARROW_LINE_RATIO := 0.1
## Patika uçlarının alanın ve çıkış karesinin kenarından geride durduğu mesafe.
const END_GAP := 0.12
## Kavis kollarının uzunluğu, iki uç arasındaki dik mesafeye oranla.
const BEND := 0.6
const CURVE_POINTS := 64
## Akan ışığın bir turu (saniye), patika boyuna oranla genişliği, ön ucunun yumuşak açılma
## uzunluğu ve rengin beyaza yaklaşması.
const FLOW_PERIOD := 1.2
const FLOW_BAND := 0.35
const FLOW_HEAD := 0.08
const FLOW_LIGHTEN := 0.6
## Işığın kenarlarda ortaya göre ne kadar geride kaldığı (patika boyuna oranla); > ucunun sivriliği.
const FLOW_CHEVRON := 0.1


static func draw(
	canvas: CanvasItem,
	base: Rect2,
	start: Rect2,
	color: Color,
	skin: BoardSkin,
	cell: float,
	flowing: bool
) -> void:
	var normal := _facing(base, start.get_center())
	var gap := Vector2.ONE * cell * END_GAP
	var from := base.get_center() + normal * (base.size / 2.0 + gap)
	var to := start.get_center() - normal * (start.size / 2.0 + gap)
	var points := _curve(from, to, normal)
	var half := cell * WIDTH_RATIO / 2.0
	var rails: Array[PackedVector2Array] = [_offset(points, half), _offset(points, -half)]
	var line := cell * LINE_RATIO
	var ground := skin.background_color
	var fill := ground.lerp(color, FILL_ALPHA)
	var light := color.lightened(FLOW_LIGHTEN)
	var progress := SmoothDraw.path_progress(points)
	var middle := _flow_colors(progress, fill, light, flowing, 0.0)
	var edge := _flow_colors(progress, fill, light, flowing, FLOW_CHEVRON)
	SmoothDraw.ribbon(canvas, rails[0], points, edge, middle)
	SmoothDraw.ribbon(canvas, points, rails[1], middle, edge)
	var ink := ground.lerp(color, LINE_ALPHA)
	for rail: PackedVector2Array in rails:
		SmoothDraw.stroke(canvas, rail, ink, line)
	var arrow_colors := _flow_colors(progress, ink, light, flowing, 0.0)
	for at: float in ARROWS_AT:
		var index := _arrow_index(points, at)
		var arrow := _arrow(points, index, half * 2.0 * ARROW_SIZE)
		SmoothDraw.stroke(canvas, arrow, arrow_colors[index], cell * ARROW_LINE_RATIO)


## Eğrinin at oranına (nokta sırasına göre) denk gelen noktasının sırası.
static func _arrow_index(points: PackedVector2Array, at: float) -> int:
	return roundi(at * (points.size() - 1))


## Eğrinin index'inci noktasında, gidiş yönünü gösteren > biçimli işaretin üç noktası.
static func _arrow(points: PackedVector2Array, index: int, size: float) -> PackedVector2Array:
	var ahead := (points[index + 1] - points[index - 1]).normalized()
	var side := ahead.orthogonal() * size
	var tip := points[index] + ahead * size / 2.0
	var back := tip - ahead * size
	return PackedVector2Array([back + side, tip, back - side])


## Alanın, point'e bakan kenarının dışa dönük birim yönü; uzaklığın büyük olduğu eksen seçilir.
static func _facing(rect: Rect2, point: Vector2) -> Vector2:
	var gap_x := maxf(rect.position.x - point.x, point.x - rect.end.x)
	var gap_y := maxf(rect.position.y - point.y, point.y - rect.end.y)
	if gap_x > gap_y:
		return Vector2.LEFT if point.x < rect.position.x else Vector2.RIGHT
	return Vector2.UP if point.y < rect.position.y else Vector2.DOWN


## Uçlarda normal yönünde duran kollarıyla kübik Bézier eğrisinin noktaları.
static func _curve(from: Vector2, to: Vector2, normal: Vector2) -> PackedVector2Array:
	var arm := normal * (to - from).dot(normal) * BEND
	var points := PackedVector2Array()
	for index: int in range(CURVE_POINTS + 1):
		var t := float(index) / CURVE_POINTS
		points.append(from.bezier_interpolate(from + arm, to - arm, to, t))
	return points


## Eğriyi her noktada gidiş yönüne dik olarak distance kadar kaydırır (eksi değer öbür yana).
static func _offset(points: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var last := points.size() - 1
	for index: int in range(points.size()):
		var ahead := points[mini(index + 1, last)] - points[maxi(index - 1, 0)]
		result.append(points[index] + ahead.orthogonal().normalized() * distance)
	return result


## Eğri noktalarının (progress: yol boyunca oranları) renkleri; akış varsa base rengi üstünden
## light renginde bir ışık çıkış karesine doğru ilerler. lag, ışığın başının ne kadar geride
## olduğudur (dolgunun kenarları ortadan geride kalınca ışık > biçimini alır).
static func _flow_colors(
	progress: PackedFloat32Array, base: Color, light: Color, flowing: bool, lag: float
) -> PackedColorArray:
	var head := PulseWave.phase(FLOW_PERIOD) * (1.0 + FLOW_BAND + FLOW_HEAD + FLOW_CHEVRON) - lag
	var colors := PackedColorArray()
	for value: float in progress:
		colors.append(base.lerp(light, _glow(head, value)) if flowing else base)
	return colors


## Işığın başı head'de iken value noktasındaki parlaklık; başın önünde FLOW_HEAD boyunca
## yumuşakça açılır, arkasında FLOW_BAND boyunca solar.
static func _glow(head: float, value: float) -> float:
	var behind := head - value
	if behind < 0.0:
		return smoothstep(FLOW_HEAD, 0.0, -behind)
	return clampf(1.0 - behind / FLOW_BAND, 0.0, 1.0)
