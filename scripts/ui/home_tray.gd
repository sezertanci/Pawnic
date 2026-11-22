class_name HomeTray
extends RefCounted
## Tahtanın ortasındaki bitiş alanı. Alanın dış çizgisi verilir (klasik tahtada kare, başka
## tahtalarda dosyadaki şekil). Her oyuncunun bölgesi, alanın kendi ev yönündeki dilimidir:
## komşu ev yönleriyle arasındaki açıortaylardan kesilir, ortadaki küçültülmüş şekil çıkarılır.
## Klasik tahtada bu, kenara oturan yamuktur. Bölgeler birlikte alanı doldurur, ortada uygulama
## simgesindeki P harfi durur. Evdeki taşlar bölgede iki sırada dizilir: ilk NEAR_COUNT taş P'ye
## yakın sırada, kalanlar dış kenara yakın sırada; her sıra kendi içinde ortalanır.
## Taş eve girince o oyuncunun bölgesi kendi renginin tam tonuna boyanır, çevresine aynı renkte
## bir ışık halesi yayılır ve ikisi birlikte söner.
## Uzunluklar kare boyuna, yerler alanın ortasından dış çizgiye uzaklığa oranlanır.

## Ortadaki şeklin boyu (dış çizgiye oranla).
const INNER_RATIO := 0.36
## Sıraların iç kenardan uzaklığı (bölgenin derinliğine oranla).
const NEAR_ROW := 0.3
const FAR_ROW := 0.72
## P'ye yakın sıradaki en fazla taş sayısı.
const NEAR_COUNT := 2
## Aynı sıradaki iki taşın merkezleri arası (kare boyuna oranla).
const SPACING := 0.55
## Bölge dolgusunda oyuncu renginin zemine karışma oranı ve kenar çizgisi kalınlığı.
const FILL_ALPHA := 0.3
const LINE_RATIO := 0.05
## Komşu bölgeler arasındaki boşluk (kare boyuna oranla); her bölge ayrı seçilsin diye.
const GAP_RATIO := 0.06
## Harf görselinin ortadaki şekli kaplama oranı.
const LETTER_RATIO := 0.9
## Hale: bölgenin çevresine yayılma uzaklığı (kare boyuna oranla), üst üste binen katman sayısı
## ve tam parlamada en içteki katmanların toplam saydamsızlığı.
const HALO_SPREAD := 0.9
const HALO_LAYERS := 8
const HALO_ALPHA := 0.7


## Bölgeleri ve ortadaki P harfini çizer. outline alanın dış çizgisi (piksel), sides her
## oyuncunun ev yönü (ortadan dışa birim yön), colors aynı sırayla renkleri, glows
## parlaklıklarıdır (0 normal, 1 dolgu tam renkte).
static func draw(
	canvas: Control,
	outline: PackedVector2Array,
	sides: Array[Vector2],
	colors: Array[Color],
	glows: Array[float],
	skin: BoardSkin,
	cell: float
) -> void:
	for index: int in range(sides.size()):
		var points := region(outline, sides, index, cell)
		var fill := skin.background_color.lerp(colors[index], FILL_ALPHA)
		fill = fill.lerp(colors[index], glows[index])
		SmoothDraw.outlined(canvas, points, fill, colors[index], cell * LINE_RATIO)
	if skin.home_letter_texture != null:
		_draw_letter(canvas, outline, sides, skin.home_letter_texture)


## index'inci bölgenin çevresine color renginde, dışa doğru incelen ışık halesi çizer; glow 0
## ise çizmez. Hale komşu karelerin üstüne taşsın diye tahta karelerinden sonra çizilir.
static func draw_halo(
	canvas: Control,
	outline: PackedVector2Array,
	sides: Array[Vector2],
	index: int,
	color: Color,
	glow: float,
	cell: float
) -> void:
	if glow <= 0.0:
		return
	var points := region(outline, sides, index, cell)
	var layer := Color(color, glow * HALO_ALPHA / HALO_LAYERS)
	for step: int in range(HALO_LAYERS, 0, -1):
		var spread := cell * HALO_SPREAD * step / HALO_LAYERS
		for ring: PackedVector2Array in Geometry2D.offset_polygon(
			points, spread, Geometry2D.JOIN_ROUND
		):
			canvas.draw_colored_polygon(ring, layer)


## Alanın ortası: dış çizgiyi kapsayan dikdörtgenin merkezi.
static func center_of(outline: PackedVector2Array) -> Vector2:
	var bounds := Rect2(outline[0], Vector2.ZERO)
	for point: Vector2 in outline:
		bounds = bounds.expand(point)
	return bounds.get_center()


## Ortadan side yönünde dış çizgiye uzaklık (piksel).
static func reach(outline: PackedVector2Array, side: Vector2) -> float:
	var center := center_of(outline)
	var far := center + side * _span(outline)
	var nearest := INF
	for index: int in range(outline.size()):
		var hit: Variant = Geometry2D.segment_intersects_segment(
			center, far, outline[index - 1], outline[index]
		)
		if hit != null:
			nearest = minf(nearest, center.distance_to(hit))
	return nearest


## Ortadan dış çizgiye en kısa ev yönü uzaklığı; dönen ok ve P harfi buna göre boyutlanır.
static func inner_reach(outline: PackedVector2Array, sides: Array[Vector2]) -> float:
	var shortest := INF
	for side: Vector2 in sides:
		shortest = minf(shortest, reach(outline, side))
	return shortest


## index'inci oyuncunun bölgesi (piksel); komşu bölgelerle arasında boşluk bırakılır.
static func region(
	outline: PackedVector2Array, sides: Array[Vector2], index: int, cell: float
) -> PackedVector2Array:
	var slices := Geometry2D.intersect_polygons(outline, _wedge(outline, sides, index))
	if slices.is_empty():
		return PackedVector2Array()
	var rest := Geometry2D.clip_polygons(slices[0], _inner(outline))
	if rest.is_empty():
		return PackedVector2Array()
	var shrunk := Geometry2D.offset_polygon(rest[0], -cell * GAP_RATIO / 2.0)
	return rest[0] if shrunk.is_empty() else shrunk[0]


## count taşlık evde index'inci taşın piksel merkezi; side bölgenin ev yönüdür.
static func place(
	outline: PackedVector2Array, side: Vector2, index: int, count: int, cell: float
) -> Vector2:
	var slot := slot(index, count)
	var outer := reach(outline, side)
	var inner := outer * INNER_RATIO
	var depth := inner + (outer - inner) * slot.y
	return center_of(outline) + side * depth + side.orthogonal() * slot.x * cell


## count taşlık evde index'inci taşın yeri: x sıra boyunca ortadan uzaklık (kare boyu
## cinsinden), y sıranın iç kenardan uzaklığı (bölge derinliğine oranla).
static func slot(index: int, count: int) -> Vector2:
	var near := mini(count, NEAR_COUNT)
	if index < near:
		return Vector2(_offset(index, near), NEAR_ROW)
	return Vector2(_offset(index - near, count - near), FAR_ROW)


## size taşlık ortalanmış sırada position'ıncı taşın ortadan uzaklığı (kare boyu cinsinden).
static func _offset(position: int, size: int) -> float:
	return (position - (size - 1) / 2.0) * SPACING


## Harf görselini, oranını bozmadan ortadaki şeklin ortasına sığdırır.
static func _draw_letter(
	canvas: Control, outline: PackedVector2Array, sides: Array[Vector2], texture: Texture2D
) -> void:
	var room := inner_reach(outline, sides) * 2.0 * INNER_RATIO * LETTER_RATIO
	var size := texture.get_size()
	size *= room / maxf(size.x, size.y)
	canvas.draw_texture_rect(texture, Rect2(center_of(outline) - size / 2.0, size), false)


## Ortadaki, dış çizginin INNER_RATIO oranında küçültülmüş şekli.
static func _inner(outline: PackedVector2Array) -> PackedVector2Array:
	var center := center_of(outline)
	var result := PackedVector2Array()
	for point: Vector2 in outline:
		result.append(center + (point - center) * INNER_RATIO)
	return result


## index'inci ev yönünün dilimi: ortadan, komşu ev yönleriyle arasındaki açıortaylara uzanan ve
## alanı aşacak kadar büyük bir çokgen.
static func _wedge(
	outline: PackedVector2Array, sides: Array[Vector2], index: int
) -> PackedVector2Array:
	var center := center_of(outline)
	var span := _span(outline)
	var angle := sides[index].angle()
	var before := angle - _gap_to_neighbor(sides, index, -1.0) / 2.0
	var after := angle + _gap_to_neighbor(sides, index, 1.0) / 2.0
	var result := PackedVector2Array([center])
	for edge: float in [before, angle, after]:
		result.append(center + Vector2.from_angle(edge) * span)
	return result


## index'inci ev yönünden direction (1 saat yönü, -1 ters) yönündeki en yakın ev yönüne açı
## (radyan); başka ev yönü yoksa tam tur.
static func _gap_to_neighbor(sides: Array[Vector2], index: int, direction: float) -> float:
	var gap := TAU
	for other: int in range(sides.size()):
		if other == index:
			continue
		var turn := fposmod(direction * sides[index].angle_to(sides[other]), TAU)
		if turn > 0.0:
			gap = minf(gap, turn)
	return gap


## Ortadan dış çizginin her noktasına ulaşmaya yetecek uzunluğun iki katı.
static func _span(outline: PackedVector2Array) -> float:
	var center := center_of(outline)
	var longest := 0.0
	for point: Vector2 in outline:
		longest = maxf(longest, center.distance_to(point))
	return longest * 2.0
